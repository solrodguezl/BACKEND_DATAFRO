const asistenciaRepository = require('../repositories/asistenciaRepository');
const AppError = require('../utils/AppError');

const buscarPersona = async (membresia, documento) => {
    const persona = await asistenciaRepository.buscarPersonaPorDocumento(
        membresia.organizacion_id,
        documento
    );

    if (!persona) {
        throw new AppError('Persona no registrada', 404);
    }

    return persona;
};

const crearActividad = async (membresia, data) => {
    const actividad = await asistenciaRepository.crearActividad({
        id: data.id ?? null,
        organizacionId: membresia.organizacion_id,
        nombre: data.nombre,
        fecha: data.fecha,
        barrio: data.barrio,
        creadoPor: membresia.usuario_id,
    });

    if (!actividad) {
        // El UUID enviado ya existe pero pertenece a otra organización.
        throw new AppError('El identificador de la actividad ya está en uso', 409);
    }

    return actividad;
};

const listarActividades = (membresia) =>
    asistenciaRepository.listarActividades(membresia.organizacion_id);

const obtenerActividad = async (membresia, id) => {
    const actividad = await asistenciaRepository.obtenerActividad(
        membresia.organizacion_id,
        id
    );

    if (!actividad) {
        throw new AppError('Actividad no encontrada', 404);
    }

    const asistentes = await asistenciaRepository.listarAsistentes(id);

    return { ...actividad, asistentes };
};

const registrarAsistencia = async (membresia, actividadId, data) => {
    // Garantiza que la actividad pertenece a la organización del usuario.
    const actividad = await asistenciaRepository.obtenerActividad(
        membresia.organizacion_id,
        actividadId
    );

    if (!actividad) {
        throw new AppError('Actividad no encontrada', 404);
    }

    const resultado = await asistenciaRepository.registrarAsistencia({
        organizacionId: membresia.organizacion_id,
        actividadId,
        registradoPor: membresia.usuario_id,
        persona: data,
    });

    if (!resultado) {
        throw new AppError(
            'Esta persona ya está registrada en la actividad',
            409
        );
    }

    return resultado;
};

module.exports = {
    buscarPersona,
    crearActividad,
    listarActividades,
    obtenerActividad,
    registrarAsistencia,
};
