const crypto = require('crypto');

/**
 * Genera un refresh token aleatorio.
 *
 * @returns {string}
 */
const generarRefreshToken = () => {
    return crypto.randomBytes(64).toString('hex');
};

/**
 * Genera un SHA-256 del token.
 *
 * @param {string} token
 * @returns {string}
 */
const hashToken = (token) => {
    return crypto
        .createHash('sha256')
        .update(token)
        .digest('hex');
};

module.exports = {
    generarRefreshToken,
    hashToken,
};