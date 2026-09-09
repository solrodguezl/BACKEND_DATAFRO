const jwt = require('jsonwebtoken');

const ACCESS_TOKEN_SECRET = process.env.JWT_ACCESS_SECRET;
const ACCESS_TOKEN_EXPIRES_IN = process.env.JWT_ACCESS_EXPIRES_IN || '15m';

if (!ACCESS_TOKEN_SECRET) {
    throw new Error('JWT_ACCESS_SECRET no está configurado');
}

/**
 * Genera un access token JWT.
 *
 * @param {object} payload
 * @returns {string}
 */
const generarAccessToken = (payload) => {
    return jwt.sign(
        payload,
        ACCESS_TOKEN_SECRET,
        {
            expiresIn: ACCESS_TOKEN_EXPIRES_IN,
        }
    );
};

/**
 * Verifica un access token.
 *
 * @param {string} token
 * @returns {object}
 */
const verificarAccessToken = (token) => {
    return jwt.verify(token, ACCESS_TOKEN_SECRET);
};

module.exports = {
    generarAccessToken,
    verificarAccessToken,
};