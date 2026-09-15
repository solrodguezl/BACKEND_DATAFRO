const AppError = require('../utils/AppError');

/**
 * Crea un middleware de validación usando Zod.
 *
 * @param {import('zod').ZodType} schema
 * @returns {Function}
 */
const validate = (schema) => {
    return (req, res, next) => {
        const safeBody = req.body ?? {};
        const safeParams = req.params ?? {};
        const safeQuery = req.query ?? {};

        const result = schema.safeParse({
            body: safeBody,
            params: safeParams,
            query: safeQuery,
        });

        if (!result.success) {
            const errors = result.error.issues.map((issue) => ({
                campo: issue.path.at(-1),
                mensaje: issue.message,
            }));

            return next(
                new AppError(
                    'Hay errores en los datos enviados',
                    400,
                    errors
                )
            );
        }

        req.body = result.data.body ?? {};
        req.params = result.data.params ?? {};
        req.query = result.data.query ?? {};

        next();
    };
};

module.exports = validate;