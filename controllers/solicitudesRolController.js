const solicitudesRolService = require('../services/solicitudesRolService');

const wrap = (fn) => async (req, res, next) => {
    try {
        await fn(req, res);
    } catch (error) {
        next(error);
    }
};

const crear = wrap(async (req, res) => {
    res.status(201).json(await solicitudesRolService.crear(req.sesion, req.body));
});

const misSolicitudes = wrap(async (req, res) => {
    res.json(await solicitudesRolService.misSolicitudes(req.sesion));
});

const listarAdmin = wrap(async (req, res) => {
    res.json(await solicitudesRolService.listarAdmin(req.query.estado));
});

const aprobar = wrap(async (req, res) => {
    res.json(
        await solicitudesRolService.aprobar(req.sesion, req.params.id, req.body.comentario)
    );
});

const rechazar = wrap(async (req, res) => {
    res.json(
        await solicitudesRolService.rechazar(req.sesion, req.params.id, req.body.comentario)
    );
});

module.exports = { crear, misSolicitudes, listarAdmin, aprobar, rechazar };
