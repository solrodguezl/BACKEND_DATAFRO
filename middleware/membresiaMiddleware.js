const pool = require('../config/db');
const AppError = require('../utils/AppError');
const { ROLES } = require('../utils/catalogos');

/**
 * Carga la organización y el rol del usuario autenticado en req.membresia
 * (usuario.id_organizacion + usuario.id_rol). Todo acceso a datos se segmenta
 * por organización (RNF-03). Debe usarse después de authenticate.
 */
const cargarMembresia = async (req, res, next) => {
    try {
        const result = await pool.query(
            `
            SELECT
                u.id_usuario AS usuario_id,
                u.id_organizacion AS organizacion_id,
                u.activo,
                UPPER(r.nombre) AS rol,
                o.nombre AS organizacion_nombre
            FROM usuario u
            LEFT JOIN rol r ON r.id_rol = u.id_rol
            LEFT JOIN organizacion o ON o.id_organizacion = u.id_organizacion
            WHERE u.id_usuario = $1
            LIMIT 1
            `,
            [req.user.sub]
        );

        const membresia = result.rows[0];

        if (!membresia || !membresia.organizacion_id || !membresia.activo) {
            return next(
                new AppError(
                    'Tu usuario no pertenece a ninguna organización activa',
                    403
                )
            );
        }

        // El administrador investigativo solo ve datos anonimizados, no los de la organización.
        if (!ROLES.includes(membresia.rol)) {
            return next(
                new AppError(
                    'Tu rol no tiene acceso a los datos de la organización',
                    403
                )
            );
        }

        req.membresia = membresia;
        return next();
    } catch (error) {
        return next(error);
    }
};

/**
 * Restringe una ruta a ciertos roles.
 */
const requerirRol = (...roles) => (req, res, next) => {
    if (!req.membresia || !roles.includes(req.membresia.rol)) {
        return next(
            new AppError('No tienes permiso para realizar esta acción', 403)
        );
    }

    return next();
};

module.exports = { cargarMembresia, requerirRol };
