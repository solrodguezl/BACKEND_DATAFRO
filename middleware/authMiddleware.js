const AppError = require('../utils/AppError');
const { verificarAccessToken } = require('../utils/jwt');

/**
 * Middleware que verifica el JWT enviado por el cliente.
 */
const authenticate = (req, res, next) => {
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

        req.user = payload;

        next();
    } catch (error) {
        return next(
            new AppError('Token inválido o expirado', 401)
        );
    }
};

module.exports = {
    authenticate,
};