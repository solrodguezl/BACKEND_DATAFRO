const AppError = require('../utils/AppError');

/**
 * Crea un middleware de validación usando Zod.
 *
 * @param {import('zod').ZodType} schema
 * @returns {Function}
 */
const validate = (schema) => {
    return (req, res, next) => {
        const result = schema.safeParse({
            body: req.body,
            params: req.params,
            query: req.query,
        });

        if (!result.success) {
            const errors = result.error.issues.map((issue) => ({
                campo: issue.path.join('.'),
                mensaje: issue.message,
            }));

            return next(
                new AppError('Datos de entrada inválidos', 400)
            );
        }

        req.body = result.data.body;
        req.params = result.data.params;
        req.query = result.data.query;

        next();
    };
};

module.exports = validate;