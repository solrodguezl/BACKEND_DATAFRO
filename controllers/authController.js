const authService =
    require('../services/authService');

/**
 * POST /api/auth/login
 */
const login = async (req, res, next) => {
    try {
        const { documento, clave } = req.body;

        const infoDispositivo =
            req.headers['user-agent'] || null;

        const direccionIp =
            req.ip || null;

        const resultado =
            await authService.login({
                documento,
                clave,
                infoDispositivo,
                direccionIp,
            });

        return res.json(resultado);
    } catch (error) {
        next(error);
    }
};

/**
 * POST /api/auth/refresh
 */
const refresh = async (req, res, next) => {
    try {
        const { refreshToken } = req.body;

        const resultado =
            await authService.refresh(
                refreshToken
            );

        return res.json(resultado);
    } catch (error) {
        next(error);
    }
};

/**
 * POST /api/auth/logout
 */
const logout = async (req, res, next) => {
    try {
        const { refreshToken } = req.body;

        await authService.logout(refreshToken);

        return res.status(200).json({
            mensaje: 'Sesión cerrada correctamente',
        });
    } catch (error) {
        next(error);
    }
};

/**
 * GET /api/auth/me
 * Sesión del usuario autenticado: rol, nivel, organización (si tiene) y permisos.
 * No exige organización (a diferencia de /miembros/yo): la usa alguien recién
 * registrado, sin organización todavía, para saber qué puede hacer.
 */
const me = (req, res) => {
    res.json(req.sesion);
};

module.exports = {
    login,
    refresh,
    logout,
    me,
};