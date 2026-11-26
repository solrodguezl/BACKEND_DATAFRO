const caracterizacionService = require('../services/caracterizacionService');

const wrap = (fn) => async (req, res, next) => {
    try {
        await fn(req, res);
    } catch (error) {
        next(error);
    }
};

const obtenerCatalogo = wrap(async (req, res) => {
    res.json(await caracterizacionService.obtenerCatalogo());
});

const buscarPersona = wrap(async (req, res) => {
    res.json(
        await caracterizacionService.buscarPersonaConFormulario(
            req.membresia,
            req.params.documento
        )
    );
});

const buscarHogar = wrap(async (req, res) => {
    res.json(
        await caracterizacionService.buscarHogarPorDocumento(
            req.membresia,
            req.params.documento
        )
    );
});

const guardarCaracterizacion = wrap(async (req, res) => {
    res
        .status(201)
        .json(
            await caracterizacionService.guardarCaracterizacion(req.membresia, req.body)
        );
});

module.exports = {
    obtenerCatalogo,
    buscarPersona,
    buscarHogar,
    guardarCaracterizacion,
};
