const asistenciaService = require('../services/asistenciaService');

const wrap = (fn) => async (req, res, next) => {
    try {
        await fn(req, res);
    } catch (error) {
        next(error);
    }
};

const buscarPersona = wrap(async (req, res) => {
    res.json(
        await asistenciaService.buscarPersona(req.membresia, req.params.documento)
    );
});

const crearActividad = wrap(async (req, res) => {
    res
        .status(201)
        .json(await asistenciaService.crearActividad(req.membresia, req.body));
});

const listarActividades = wrap(async (req, res) => {
    res.json(await asistenciaService.listarActividades(req.membresia));
});

const obtenerActividad = wrap(async (req, res) => {
    res.json(
        await asistenciaService.obtenerActividad(req.membresia, req.params.id)
    );
});

const registrarAsistencia = wrap(async (req, res) => {
    res
        .status(201)
        .json(
            await asistenciaService.registrarAsistencia(
                req.membresia,
                req.params.id,
                req.body
            )
        );
});

module.exports = {
    buscarPersona,
    crearActividad,
    listarActividades,
    obtenerActividad,
    registrarAsistencia,
};
