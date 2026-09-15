const perfilesRepository =
    require('../repositories/perfilesRepository');

const AppError =
    require('../utils/AppError');

/**
 * Obtiene el perfil del usuario autenticado.
 *
 * @param {string} usuarioId UUID del usuario.
 * @returns {Promise<object>}
 */
const obtenerMiPerfil = async (usuarioId) => {
    const perfil =
        await perfilesRepository.buscarPorUsuarioId(
            usuarioId
        );

    if (!perfil) {
        throw new AppError(
            'Perfil no encontrado',
            404
        );
    }

    return perfil;
};

/**
 * Crea o actualiza el perfil del usuario autenticado.
 *
 * Si el usuario todavía no tiene perfil, se crea.
 * Si ya tiene perfil, se actualiza.
 *
 * @param {string} usuarioId UUID del usuario.
 * @param {object} data Datos del perfil.
 * @returns {Promise<object>}
 */
const actualizarMiPerfil = async (
    usuarioId,
    data
) => {
    const datosPerfil = {
        nombres: data.nombres,
        apellidos: data.apellidos,
        telefono: data.telefono ?? null,
        fotoPerfil: data.foto_perfil ?? null,
    };

    const perfilExistente =
        await perfilesRepository.buscarPorUsuarioId(
            usuarioId
        );

    if (!perfilExistente) {
        return perfilesRepository.crear({
            usuarioId,
            ...datosPerfil,
        });
    }

    return perfilesRepository.actualizar(
        usuarioId,
        datosPerfil
    );
};

module.exports = {
    obtenerMiPerfil,
    actualizarMiPerfil,
};