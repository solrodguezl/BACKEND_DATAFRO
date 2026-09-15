const bcrypt = require('bcrypt');

const usuariosRepository = require('../repositories/usuariosRepository');
const sesionesRepository = require('../repositories/sesionesRepository');

const AppError = require('../utils/AppError');

const {
    generarAccessToken,
} = require('../utils/jwt');

const {
    generarRefreshToken,
    hashToken,
} = require('../utils/token');

const REFRESH_TOKEN_DAYS = 30;

/**
 * Realiza login.
 *
 * @param {object} data
 * @param {string} data.correo
 * @param {string} data.clave
 * @param {string|null} data.infoDispositivo
 * @param {string|null} data.direccionIp
 * @returns {Promise<object>}
 */
const login = async ({
    documento,
    clave,
    infoDispositivo,
    direccionIp,
}) => {
    const usuario =
        await usuariosRepository.buscarPorDocumento(documento);

    if (!usuario) {
        throw new AppError(
            'Documento o contraseña incorrectos',
            401
        );
    }

    const claveCorrecta = await bcrypt.compare(
        clave,
        usuario.clave_hash
    );

    if (!claveCorrecta) {
        throw new AppError(
            'Documento o contraseña incorrectos',
            401
        );
    }

    if (!usuario.activo) {
        throw new AppError(
            'El usuario está inactivo',
            403
        );
    }

    const accessToken = generarAccessToken({
        sub: String(usuario.id_usuario ?? usuario.id),
        documento: usuario.documento,
    });

    const refreshToken = generarRefreshToken();

    const refreshTokenHash = hashToken(
        refreshToken
    );

    const fechaExpiracion = new Date();

    fechaExpiracion.setDate(
        fechaExpiracion.getDate() + REFRESH_TOKEN_DAYS
    );

    await sesionesRepository.crear({
        usuarioId: usuario.id_usuario ?? usuario.id,
        tokenRenovacion: refreshTokenHash,
        infoDispositivo,
        direccionIp,
        fechaExpiracion,
    });

    return {
        accessToken,
        refreshToken,
        usuario: {
            id: usuario.id_usuario ?? usuario.id,
            documento: usuario.documento,
            activo: usuario.activo,
        },
    };
};

/**
 * Renueva el access token.
 *
 * @param {string} refreshToken
 * @returns {Promise<object>}
 */
const refresh = async (refreshToken) => {
    const tokenHash = hashToken(refreshToken);

    const sesion =
        await sesionesRepository.buscarActivaPorToken(
            tokenHash
        );

    if (!sesion) {
        throw new AppError(
            'Refresh token inválido o expirado',
            401
        );
    }

    const usuario =
        await usuariosRepository.buscarPorId(
            sesion.usuario_id
        );

    if (!usuario || !usuario.activo) {
        throw new AppError(
            'Usuario no disponible',
            401
        );
    }

    const accessToken = generarAccessToken({
        sub: String(usuario.id_usuario ?? usuario.id),
        documento: usuario.documento,
    });

    return {
        accessToken,
    };
};

/**
 * Cierra una sesión.
 *
 * @param {string} refreshToken
 */
const logout = async (refreshToken) => {
    const tokenHash = hashToken(refreshToken);

    const sesion =
        await sesionesRepository.buscarActivaPorToken(
            tokenHash
        );

    if (!sesion) {
        return;
    }

    await sesionesRepository.revocarTodasPorUsuarioId(
        sesion.usuario_id
    );
};

module.exports = {
    login,
    refresh,
    logout,
};