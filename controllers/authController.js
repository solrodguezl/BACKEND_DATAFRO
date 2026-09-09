const authService =
    require('../services/authService');

/**
 * POST /api/auth/login
 */
const login = async (req, res, next) => {
    try {
        const { correo, clave } = req.body;

        const infoDispositivo =
            req.headers['user-agent'] || null;

        const direccionIp =
            req.ip || null;

        const resultado =
            await authService.login({
                correo,
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

        return res.status(204).send();
    } catch (error) {
        next(error);
    }
};

module.exports = {
    login,
    refresh,
    logout,
};