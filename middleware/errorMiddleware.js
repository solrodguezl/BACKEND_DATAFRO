const AppError = require('../utils/AppError');

/**
 * Middleware para manejar errores de la aplicación.
 */
const errorMiddleware = (error, req, res, next) => {
    console.error(error);

    if (error instanceof AppError) {
        return res.status(error.statusCode).json({
            error: error.message,
            ...(error.details && {
                details: error.details,
            }),
        });
    }

    // PostgreSQL: unique violation
    if (error.code === '23505') {
        return res.status(409).json({
            error: 'El recurso ya existe',
        });
    }

    // PostgreSQL: foreign key violation
    if (error.code === '23503') {
        return res.status(409).json({
            error: 'No se puede realizar la operación debido a relaciones existentes',
        });
    }

    return res.status(500).json({
        error: 'Error interno del servidor',
    });
};

module.exports = errorMiddleware;