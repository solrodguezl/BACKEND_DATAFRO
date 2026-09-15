const pool = require('../config/db');

/**
 * Obtiene el perfil de un usuario.
 *
 * @param {string} usuarioId UUID del usuario.
 * @returns {Promise<object|undefined>}
 */
const buscarPorUsuarioId = async (usuarioId) => {
    const query = `
        SELECT
            usuario_id,
            nombres,
            apellidos,
            telefono,
            foto_perfil,
            fecha_actualizacion
        FROM perfiles
        WHERE usuario_id = $1
        LIMIT 1
    `;

    const result = await pool.query(
        query,
        [usuarioId]
    );

    return result.rows[0];
};

/**
 * Crea un perfil.
 *
 * @param {object} data
 * @param {string} data.usuarioId UUID del usuario.
 * @param {string} data.nombres
 * @param {string} data.apellidos
 * @param {string|null} data.telefono
 * @param {string|null} data.fotoPerfil
 * @returns {Promise<object>}
 */
const crear = async ({
    usuarioId,
    nombres,
    apellidos,
    telefono,
    fotoPerfil,
}) => {
    const query = `
        INSERT INTO perfiles (
            usuario_id,
            nombres,
            apellidos,
            telefono,
            foto_perfil
        )
        VALUES ($1, $2, $3, $4, $5)
        RETURNING
            usuario_id,
            nombres,
            apellidos,
            telefono,
            foto_perfil,
            fecha_actualizacion
    `;

    const result = await pool.query(
        query,
        [
            usuarioId,
            nombres,
            apellidos,
            telefono,
            fotoPerfil,
        ]
    );

    return result.rows[0];
};

/**
 * Actualiza un perfil.
 *
 * @param {string} usuarioId UUID del usuario.
 * @param {object} data Datos del perfil.
 * @returns {Promise<object|undefined>}
 */
const actualizar = async (
    usuarioId,
    {
        nombres,
        apellidos,
        telefono,
        fotoPerfil,
    }
) => {
    const query = `
        UPDATE perfiles
        SET
            nombres = $1,
            apellidos = $2,
            telefono = $3,
            foto_perfil = $4,
            fecha_actualizacion = CURRENT_TIMESTAMP
        WHERE usuario_id = $5
        RETURNING
            usuario_id,
            nombres,
            apellidos,
            telefono,
            foto_perfil,
            fecha_actualizacion
    `;

    const result = await pool.query(
        query,
        [
            nombres,
            apellidos,
            telefono,
            fotoPerfil,
            usuarioId,
        ]
    );

    return result.rows[0];
};

module.exports = {
    buscarPorUsuarioId,
    crear,
    actualizar,
};