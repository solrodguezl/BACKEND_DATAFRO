const perfilesService =
    require('../services/perfilesService');

/**
 * GET /api/perfiles/me
 */
const obtenerMiPerfil = async (
    req,
    res,
    next
) => {
    try {
        const usuarioId = req.user.sub;

        const perfil =
            await perfilesService.obtenerMiPerfil(
                usuarioId
            );

        return res.json(perfil);
    } catch (error) {
        next(error);
    }
};

/**
 * PUT /api/perfiles/me
 */
const actualizarMiPerfil = async (
    req,
    res,
    next
) => {
    try {
        const usuarioId = req.user.sub;

        const perfil =
            await perfilesService.actualizarMiPerfil(
                usuarioId,
                req.body
            );

        return res.json(perfil);
    } catch (error) {
        next(error);
    }
};

module.exports = {
    obtenerMiPerfil,
    actualizarMiPerfil,
};