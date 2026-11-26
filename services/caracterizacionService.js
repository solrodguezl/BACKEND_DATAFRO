const caracterizacionRepository = require('../repositories/caracterizacionRepository');
const AppError = require('../utils/AppError');

const obtenerCatalogo = () => caracterizacionRepository.obtenerCatalogo();

/**
 * Busca a la persona por documento (autorrelleno, igual que en asistencia) y,
 * si existe, el último formulario de caracterización que haya diligenciado
 * (borrador o completo) para poder continuarlo o mostrarlo.
 */
const buscarPersonaConFormulario = async (membresia, documento) => {
    const persona = await caracterizacionRepository.buscarPersonaPorDocumento(
        membresia.organizacion_id,
        documento
    );

    if (!persona) {
        throw new AppError('Persona no registrada', 404);
    }

    const formulario = await caracterizacionRepository.obtenerUltimoFormulario(
        persona.id_persona
    );

    return { persona, formulario };
};

const guardarCaracterizacion = (membresia, data) =>
    caracterizacionRepository.guardarCaracterizacion({
        organizacionId: membresia.organizacion_id,
        usuarioId: membresia.usuario_id,
        persona: {
            documento: data.documento,
            nombres: data.nombres,
            tipoDocumento: data.tipoDocumento ?? null,
            fechaNacimiento: data.fechaNacimiento ?? null,
            etnia: data.etnia ?? null,
            edad: data.edad ?? null,
            genero: data.genero ?? null,
            barrio: data.barrio,
        },
        estado: data.estado,
        respuestas: data.respuestas ?? [],
        vivienda: data.vivienda
            ? {
                  direccion: data.vivienda.direccion ?? null,
                  documentoHogar: data.vivienda.documentoHogar ?? null,
              }
            : null,
    });

/**
 * Para el botón "ya hay alguien de mi hogar registrado" (capítulo B/C del
 * nuevo instrumento): resuelve, antes de guardar, a quién se vincularía.
 */
const buscarHogarPorDocumento = async (membresia, documento) => {
    const encontrado = await caracterizacionRepository.buscarHogarPorDocumento(
        membresia.organizacion_id,
        documento
    );

    if (!encontrado) {
        throw new AppError('Persona no registrada', 404);
    }

    return encontrado;
};

module.exports = {
    obtenerCatalogo,
    buscarPersonaConFormulario,
    buscarHogarPorDocumento,
    guardarCaracterizacion,
};
