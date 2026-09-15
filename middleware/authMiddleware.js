const AppError = require('../utils/AppError');
const { verificarAccessToken } = require('../utils/jwt');
const sesionesRepository = require('../repositories/sesionesRepository');

/**
 * Middleware que verifica el JWT enviado por el cliente.
 */
const authenticate = async (req, res, next) => {
    const authorization = req.headers.authorization;

    if (!authorization) {
        return next(
            new AppError('Token de autenticación requerido', 401)
        );
    }

    const [scheme, token] = authorization.split(' ');

    if (scheme !== 'Bearer' || !token) {
        return next(
            new AppError('Formato de token inválido', 401)
        );
    }

    try {
        const payload = verificarAccessToken(token);

        if (!payload || !payload.sub) {
            return next(
                new AppError('Token inválido o expirado', 401)
            );
        }

        const sesionActiva = await sesionesRepository.buscarActivaPorUsuarioId(
            payload.sub
        );

        if (!sesionActiva) {
            return next(
                new AppError('Token inválido o expirado', 401)
            );
        }

        req.user = payload;
        return next();
    } catch (error) {
        return next(
            new AppError('Token inválido o expirado', 401)
        );
    }
};

module.exports = {
    authenticate,
};