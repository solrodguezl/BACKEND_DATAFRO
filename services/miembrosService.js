const bcrypt = require('bcrypt');

const miembrosRepository = require('../repositories/miembrosRepository');
const usuariosRepository = require('../repositories/usuariosRepository');
const AppError = require('../utils/AppError');

const SALT_ROUNDS = Number(process.env.BCRYPT_SALT_ROUNDS || 12);

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

module.exports = { yo, listar, crear, actualizar };
