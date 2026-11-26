const bcrypt = require('bcrypt');

const miembrosRepository = require('../repositories/miembrosRepository');
const usuariosRepository = require('../repositories/usuariosRepository');
const AppError = require('../utils/AppError');
const { NIVEL_ROL } = require('../utils/catalogos');

// Nivel de quien hace la operación: viene de membresia.nivel (columna real
// rol.nivel) si está disponible, y si no de NIVEL_ROL por nombre de rol —
// cubre tanto cargarMembresia (own-org) como la membresía simulada que arma
// el panel del administrador para gestionar cualquier organización.

const SALT_ROUNDS = Number(process.env.BCRYPT_SALT_ROUNDS || 12);

const nivelDe = (membresia) => membresia.nivel ?? NIVEL_ROL[membresia.rol] ?? null;

const yo = async (membresia) => {
    const miembro = await miembrosRepository.obtener(
        membresia.organizacion_id,
        membresia.usuario_id
    );

    return {
        ...miembro,
        organizacion: {
            id: membresia.organizacion_id,
            nombre: membresia.organizacion_nombre,
        },
    };
};

const listar = async (membresia) => {
    const miembros = await miembrosRepository.listarPorOrganizacion(
        membresia.organizacion_id
    );

    return {
        organizacion: {
            id: membresia.organizacion_id,
            nombre: membresia.organizacion_nombre,
        },
        miembros,
    };
};

const crear = async (membresia, data) => {
    const nivelCreador = nivelDe(membresia);

    // Jerarquía (HU-03): solo se puede crear un perfil con un rol de nivel
    // estrictamente menor al propio — un DIRECTOR no puede crear otro
    // DIRECTOR, un COORDINADOR no puede crear otro COORDINADOR ni un DIRECTOR.
    if (!nivelCreador || NIVEL_ROL[data.rol] >= nivelCreador) {
        throw new AppError(
            'No puedes crear un perfil con un rol igual o superior al tuyo',
            403
        );
    }

    const existente = await usuariosRepository.buscarPorDocumento(data.documento);

    if (existente) {
        throw new AppError('Ya existe un usuario con ese documento', 409);
    }

    const claveHash = await bcrypt.hash(data.clave, SALT_ROUNDS);

    const id = await miembrosRepository.crear({
        organizacionId: membresia.organizacion_id,
        documento: data.documento,
        claveHash,
        nombres: data.nombres,
        apellidos: data.apellidos,
        telefono: data.telefono,
        rol: data.rol,
    });

    return miembrosRepository.obtener(membresia.organizacion_id, id);
};

const actualizar = async (membresia, id, data) => {
    const miembro = await miembrosRepository.obtener(
        membresia.organizacion_id,
        id
    );

    if (!miembro) {
        throw new AppError('Miembro no encontrado', 404);
    }

    if (id === membresia.usuario_id) {
        if (data.rol !== miembro.rol) {
            throw new AppError('No puedes cambiar tu propio rol', 400);
        }

        if (data.activo === false) {
            throw new AppError('No puedes desactivar tu propio usuario', 400);
        }
    } else {
        const nivelCreador = nivelDe(membresia);

        // Jerarquía (HU-03): no se puede tocar a alguien de tu mismo nivel o
        // superior, ni asignarle un rol igual o superior al tuyo.
        if (!nivelCreador || NIVEL_ROL[miembro.rol] >= nivelCreador) {
            throw new AppError('No tienes permiso para modificar a este miembro', 403);
        }

        if (NIVEL_ROL[data.rol] >= nivelCreador) {
            throw new AppError('No puedes asignar un rol igual o superior al tuyo', 403);
        }
    }

    const claveHash = data.clave
        ? await bcrypt.hash(data.clave, SALT_ROUNDS)
        : null;

    await miembrosRepository.actualizar(membresia.organizacion_id, id, {
        nombres: data.nombres,
        apellidos: data.apellidos,
        telefono: data.telefono ?? null,
        rol: data.rol,
        activo: data.activo,
        claveHash,
    });

    return miembrosRepository.obtener(membresia.organizacion_id, id);
};

/**
 * Resumen de actividad de un miembro (para el panel de perfil): cuántas
 * asistencias ha registrado, cuántas actividades ha creado, promedio de
 * asistentes y la más reciente.
 */
const resumenActividad = async (membresia, id) => {
    const miembro = await miembrosRepository.obtener(membresia.organizacion_id, id);

    if (!miembro) {
        throw new AppError('Miembro no encontrado', 404);
    }

    const resumen = await miembrosRepository.obtenerResumenActividad(
        membresia.organizacion_id,
        id
    );

    return { miembro, resumen };
};

module.exports = { yo, listar, crear, actualizar, resumenActividad };
