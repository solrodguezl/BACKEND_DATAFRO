const pool = require('../config/db');

/**
 * Busca un usuario por documento.
 *
 * @param {string} documento
 * @returns {Promise<object|undefined>}
 */
const buscarPorDocumento = async (documento) => {
    const query = `
        SELECT
            id_usuario,
            documento,
            clave_hash,
            activo,
            fecha_creacion,
            fecha_actualizacion
        FROM usuario
        WHERE documento = $1
        LIMIT 1
    `;

    const result = await pool.query(query, [documento]);
    const usuario = result.rows[0];

    if (!usuario) {
        return undefined;
    }

    return {
        ...usuario,
        id: usuario.id_usuario,
    };
};

/**
 * Busca un usuario por ID.
 *
 * @param {string} id_usuario
 * @returns {Promise<object|undefined>}
 */
const buscarPorId = async (id) => {
    const query = `
        SELECT
            id_usuario,
            documento,
            activo,
            fecha_creacion,
            fecha_actualizacion
        FROM usuario
        WHERE id_usuario = $1
        LIMIT 1
    `;

    const result = await pool.query(query, [id]);
    const usuario = result.rows[0];

    if (!usuario) {
        return undefined;
    }

    return {
        ...usuario,
        id: usuario.id_usuario,
    };
};

/**
 * Obtiene todos los usuarios.
 *
 * @returns {Promise<object[]>}
 */
const obtenerTodos = async () => {
    const query = `
        SELECT
            id_usuario,
            documento,
            activo,
            fecha_creacion,
            fecha_actualizacion
        FROM usuario
        ORDER BY id_usuario ASC
    `;

    const result = await pool.query(query);

    return result.rows;
};

/**
 * Crea un usuario.
 *
 * @param {string} documento
 * @param {string} claveHash
 * @returns {Promise<object>}
 */
const crear = async (documento, claveHash) => {
    const query = `
        INSERT INTO usuario (
            documento,
            clave_hash
        )
        VALUES ($1, $2)
        RETURNING
            id_usuario,
            documento,
            activo,
            fecha_creacion,
            fecha_actualizacion
    `;

    const result = await pool.query(query, [
        documento,
        claveHash,
    ]);

    const usuario = result.rows[0];

    if (!usuario) {
        return undefined;
    }

    return {
        ...usuario,
        id: usuario.id_usuario,
    };
};

/**
 * Actualiza el estado de un usuario.
 *
 * @param {number} id
 * @param {boolean} activo
 * @returns {Promise<object|undefined>}
 */
const actualizarActivo = async (id, activo) => {
    const query = `
        UPDATE usuario
        SET
            activo = $1,
            fecha_actualizacion = CURRENT_TIMESTAMP
        WHERE id_usuario = $2
        RETURNING
            id_usuario,
            documento,
            activo,
            fecha_actualizacion
    `;

    const result = await pool.query(query, [
        activo,
        id,
    ]);

    const usuario = result.rows[0];

    if (!usuario) {
        return undefined;
    }

    return {
        ...usuario,
        id: usuario.id_usuario,
    };
};

/**
 * Elimina físicamente un usuario.
 *
 * @param {number} id_usuario
 * @returns {Promise<object|undefined>}
 */
const eliminar = async (id_usuario) => {
    const query = `
        DELETE FROM usuario
        WHERE id_usuario = $1
        RETURNING id_usuario
    `;

    const result = await pool.query(query, [id_usuario]);

    return result.rows[0];
};

module.exports = {
    buscarPorDocumento,
    buscarPorId,
    obtenerTodos,
    crear,
    actualizarActivo,
    eliminar,
};