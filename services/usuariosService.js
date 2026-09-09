const bcrypt = require('bcrypt');

const usuariosRepository = require('../repositories/usuariosRepository');
const AppError = require('../utils/AppError');

const SALT_ROUNDS = Number(process.env.BCRYPT_SALT_ROUNDS || 12);

/**
 * Crea un usuario.
 *
 * @param {string} documento
 * @param {string} clave
 * @returns {Promise<object>}
 */
const crearUsuario = async (documento, clave) => {
    const usuarioExistente =
        await usuariosRepository.buscarPorDocumento(documento);

    if (usuarioExistente) {
        throw new AppError(
            'El documento ya está registrado',
            409
        );
    }

    const claveHash = await bcrypt.hash(
        clave,
        SALT_ROUNDS
    );

    return usuariosRepository.crear(
        documento,
        claveHash
    );
};

/**
 * Obtiene todos los usuarios.
 *
 * @returns {Promise<object[]>}
 */
const obtenerUsuarios = async () => {
    return usuariosRepository.obtenerTodos();
};

/**
 * Obtiene un usuario.
 *
 * @param {number} id
 * @returns {Promise<object>}
 */
const obtenerUsuario = async (id) => {
    const usuario = await usuariosRepository.buscarPorId(id);

    if (!usuario) {
        throw new AppError(
            'Usuario no encontrado',
            404
        );
    }

    return usuario;
};

/**
 * Actualiza el estado activo del usuario.
 *
 * @param {number} id
 * @param {boolean} activo
 * @returns {Promise<object>}
 */
const actualizarUsuario = async (id, activo) => {
    const usuario =
        await usuariosRepository.actualizarActivo(
            id,
            activo
        );

    if (!usuario) {
        throw new AppError(
            'Usuario no encontrado',
            404
        );
    }

    return usuario;
};

/**
 * Elimina un usuario.
 *
 * @param {number} id
 */
const eliminarUsuario = async (id) => {
    const usuario =
        await usuariosRepository.eliminar(id);

    if (!usuario) {
        throw new AppError(
            'Usuario no encontrado',
            404
        );
    }
};

module.exports = {
    crearUsuario,
    obtenerUsuarios,
    obtenerUsuario,
    actualizarUsuario,
    eliminarUsuario,
};