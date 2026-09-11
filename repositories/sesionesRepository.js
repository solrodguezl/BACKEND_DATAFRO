const pool = require('../config/db');

/**
 * Crea una sesión.
 *
 * @param {object} data
 * @param {number} data.usuarioId
 * @param {string} data.tokenRenovacion
 * @param {string|null} data.infoDispositivo
 * @param {string|null} data.direccionIp
 * @param {Date} data.fechaExpiracion
 * @returns {Promise<object>}
 */
const crear = async ({
    usuarioId,
    tokenRenovacion,
    infoDispositivo,
    direccionIp,
    fechaExpiracion,
}) => {
    const query = `
        INSERT INTO sesiones (
            usuario_id,
            token_renovacion,
            info_dispositivo,
            direccion_ip,
            revocado,
            fecha_expiracion
        )
        VALUES ($1, $2, $3, $4, false, $5)
        RETURNING
            id,
            usuario_id,
            fecha_expiracion,
            fecha_creacion
    `;

    const result = await pool.query(query, [
        usuarioId,
        tokenRenovacion,
        infoDispositivo,
        direccionIp,
        fechaExpiracion,
    ]);

    return result.rows[0];
};

/**
 * Busca una sesión activa mediante el hash del refresh token.
 *
 * @param {string} tokenHash
 * @returns {Promise<object|undefined>}
 */
const buscarActivaPorToken = async (tokenHash) => {
    const query = `
        SELECT
            id,
            usuario_id,
            token_renovacion,
            fecha_expiracion,
            revocado
        FROM sesiones
        WHERE token_renovacion = $1
          AND revocado = false
          AND fecha_expiracion > CURRENT_TIMESTAMP
        LIMIT 1
    `;

    const result = await pool.query(query, [tokenHash]);

    return result.rows[0];
};

/**
 * Busca si existe una sesión activa para un usuario.
 *
 * @param {string|number} usuarioId
 * @returns {Promise<object|undefined>}
 */
const buscarActivaPorUsuarioId = async (usuarioId) => {
    const query = `
        SELECT
            id,
            usuario_id,
            fecha_expiracion,
            revocado
        FROM sesiones
        WHERE usuario_id = $1
          AND revocado = false
          AND fecha_expiracion > CURRENT_TIMESTAMP
        LIMIT 1
    `;

    const result = await pool.query(query, [usuarioId]);

    return result.rows[0];
};

/**
 * Revoca una sesión.
 *
 * @param {number} id
 * @returns {Promise<void>}
 */
const revocar = async (id) => {
    await pool.query(
        `
            UPDATE sesiones
            SET revocado = true
            WHERE id = $1
        `,
        [id]
    );
};

/**
 * Revoca todas las sesiones activas de un usuario.
 *
 * @param {string|number} usuarioId
 * @returns {Promise<void>}
 */
const revocarTodasPorUsuarioId = async (usuarioId) => {
    await pool.query(
        `
            UPDATE sesiones
            SET revocado = true
            WHERE usuario_id = $1
              AND revocado = false
        `,
        [usuarioId]
    );
};

module.exports = {
    crear,
    buscarActivaPorToken,
    buscarActivaPorUsuarioId,
    revocar,
    revocarTodasPorUsuarioId,
};