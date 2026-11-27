const pool = require('../config/db');
const AppError = require('../utils/AppError');

const UUID_REGEX =
    /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/**
 * Hace idempotentes las escrituras que la app reenvía desde su cola offline.
 *
 * Si la petición trae `Idempotency-Key: <uuid>` y ese usuario ya la ejecutó con
 * éxito, se responde lo mismo que la primera vez sin volver a ejecutarla. Si es
 * nueva, se ejecuta normalmente y, si termina en 2xx, se guarda su respuesta.
 * Sin el header la ruta se comporta igual que antes (la web y los clientes
 * viejos no se ven afectados).
 *
 * Debe ir después de `authenticate` (usa req.user.sub).
 */
const idempotente = async (req, res, next) => {
    const clave = req.get('Idempotency-Key');

    if (!clave) {
        return next();
    }

    if (!UUID_REGEX.test(clave)) {
        return next(new AppError('Idempotency-Key debe ser un UUID', 400));
    }

    const idUsuario = req.user?.sub;

    if (!idUsuario) {
        return next(new AppError('Token de autenticación requerido', 401));
    }

    try {
        const previa = await pool.query(
            `SELECT estado_http, respuesta
             FROM operacion_idempotente
             WHERE clave = $1 AND id_usuario = $2`,
            [clave, idUsuario]
        );

        if (previa.rows[0]) {
            res.set('Idempotent-Replay', 'true');
            return res
                .status(previa.rows[0].estado_http)
                .json(previa.rows[0].respuesta);
        }
    } catch (error) {
        return next(error);
    }

    const jsonOriginal = res.json.bind(res);

    res.json = (cuerpo) => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
            pool
                .query(
                    `INSERT INTO operacion_idempotente
                        (clave, id_usuario, metodo, ruta, estado_http, respuesta)
                     VALUES ($1, $2, $3, $4, $5, $6)
                     ON CONFLICT (clave, id_usuario) DO NOTHING`,
                    [
                        clave,
                        idUsuario,
                        req.method,
                        req.originalUrl,
                        res.statusCode,
                        JSON.stringify(cuerpo ?? null),
                    ]
                )
                .catch((error) => {
                    // No debe tumbar la respuesta: en el peor caso un reintento
                    // vuelve a ejecutar una operación que ya es un upsert.
                    console.error('No se pudo guardar la clave de idempotencia:', error.message);
                });
        }

        return jsonOriginal(cuerpo);
    };

    return next();
};

module.exports = { idempotente };
