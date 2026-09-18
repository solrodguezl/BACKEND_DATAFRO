const miembrosService = require('../services/miembrosService');

const yo = async (req, res, next) => {
    try {
        res.json(await miembrosService.yo(req.membresia));
    } catch (error) {
        next(error);
    }
};

const listar = async (req, res, next) => {
    try {
        res.json(await miembrosService.listar(req.membresia));
    } catch (error) {
        next(error);
    }
};

const crear = async (req, res, next) => {
    try {
        res.status(201).json(
            await miembrosService.crear(req.membresia, req.body)
        );
    } catch (error) {
        next(error);
    }
};

const actualizar = async (req, res, next) => {
    try {
        res.json(
            await miembrosService.actualizar(
                req.membresia,
                req.params.id,
                req.body
            )
        );
    } catch (error) {
        next(error);
    }
};

module.exports = { yo, listar, crear, actualizar };
