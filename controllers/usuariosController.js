const usuariosService =
    require('../services/usuariosService');

/**
 * POST /api/usuarios
 */
const crearUsuario = async (req, res, next) => {
    try {
        const { documento, clave } = req.body;

        const usuario =
            await usuariosService.crearUsuario(
                documento,
                clave
            );

        return res.status(201).json(usuario);
    } catch (error) {
        next(error);
    }
};

/**
 * GET /api/usuarios
 */
const obtenerUsuarios = async (req, res, next) => {
    try {
        const usuarios =
            await usuariosService.obtenerUsuarios();

        return res.json(usuarios);
    } catch (error) {
        next(error);
    }
};

/**
 * GET /api/usuarios/:id
 */
const obtenerUsuario = async (req, res, next) => {
    try {
        const usuario =
            await usuariosService.obtenerUsuario(
                req.params.id
            );

        return res.json(usuario);
    } catch (error) {
        next(error);
    }
};

/**
 * PUT /api/usuarios/:id
 */
const actualizarUsuario = async (
    req,
    res,
    next
) => {
    try {
        const { activo } = req.body;

        const usuario =
            await usuariosService.actualizarUsuario(
                req.params.id,
                activo
            );

        return res.json(usuario);
    } catch (error) {
        next(error);
    }
};

/**
 * DELETE /api/usuarios/:id
 */
const eliminarUsuario = async (
    req,
    res,
    next
) => {
    try {
        await usuariosService.eliminarUsuario(
            req.params.id
        );

        return res.status(204).send();
    } catch (error) {
        next(error);
    }
};

module.exports = {
    crearUsuario,
    obtenerUsuarios,
    obtenerUsuario,
    actualizarUsuario,
    eliminarUsuario,
};