const pool = require('../config/db');
const AppError = require('../utils/AppError');
const { ROLES, NIVEL_ROL } = require('../utils/catalogos');

/**
 * Carga la organización y el rol del usuario autenticado en req.membresia
 * (usuario.id_organizacion + usuario.id_rol). Todo acceso a datos se segmenta
 * por organización (RNF-03). Debe usarse después de authenticate.
 *
 * Exige organización activa: NO sirve para rutas que un usuario sin
 * organización todavía deba poder usar (por ejemplo, pedir un rol). Para eso
 * existe cargarSesion.
 *
 * NOTA (cambio pedido explícitamente por el usuario, 25-nov): el
 * ADMINISTRADOR INVESTIGATIVO deja de estar excluido de los datos de
 * organización. Mientras tenga una organización activa asignada (ASISTIR),
 * navega todas las pestañas igual que un DIRECTOR. Esto reemplaza la regla
 * original de "el admin solo ve datos anonimizados" para esta cuenta.
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
                r.nivel,
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

        // El administrador investigativo tiene acceso total (ver nota arriba),
        // siempre que ya tenga una organización activa asignada.
        if (
            membresia.rol !== 'ADMINISTRADOR INVESTIGATIVO' &&
            !ROLES.includes(membresia.rol)
        ) {
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
 * Restringe una ruta a ciertos roles (por nombre). Requiere cargarMembresia antes.
 */
const requerirRol = (...roles) => (req, res, next) => {
    if (!req.membresia) {
        return next(
            new AppError('No tienes permiso para realizar esta acción', 403)
        );
    }

    // El administrador investigativo tiene acceso total (ver nota en cargarMembresia).
    if (req.membresia.rol === 'ADMINISTRADOR INVESTIGATIVO') {
        return next();
    }

    if (!roles.includes(req.membresia.rol)) {
        return next(
            new AppError('No tienes permiso para realizar esta acción', 403)
        );
    }

    return next();
};

/**
 * Carga la sesión del usuario autenticado SIN exigir organización: rol,
 * nivel, organización (si tiene) y los permisos de su rol. Sirve para rutas
 * que un usuario recién registrado (sin organización todavía) debe poder
 * usar, como pedir un rol o consultar sus propias solicitudes.
 */
const cargarSesion = async (req, res, next) => {
    try {
        const result = await pool.query(
            `
            SELECT
                u.id_usuario AS usuario_id,
                u.documento,
                u.activo,
                u.id_organizacion AS organizacion_id,
                o.nombre AS organizacion_nombre,
                UPPER(r.nombre) AS rol,
                r.nivel
            FROM usuario u
            LEFT JOIN rol r ON r.id_rol = u.id_rol
            LEFT JOIN organizacion o ON o.id_organizacion = u.id_organizacion
            WHERE u.id_usuario = $1
            LIMIT 1
            `,
            [req.user.sub]
        );

        const sesion = result.rows[0];

        if (!sesion || !sesion.activo) {
            return next(new AppError('Usuario no disponible', 403));
        }

        const permisos = await pool.query(
            `
            SELECT p.nombre
            FROM rol_permiso rp
            JOIN permiso p ON p.id_permiso = rp.id_permiso
            JOIN usuario u ON u.id_rol = rp.id_rol
            WHERE u.id_usuario = $1
            `,
            [req.user.sub]
        );

        req.sesion = {
            ...sesion,
            nivel: sesion.nivel ?? (sesion.rol ? NIVEL_ROL[sesion.rol] ?? null : null),
            permisos: permisos.rows.map((p) => p.nombre),
        };

        return next();
    } catch (error) {
        return next(error);
    }
};

/**
 * Restringe una ruta a un nivel de rol mínimo. Requiere cargarSesion antes.
 */
const requerirNivel = (nivelMinimo) => (req, res, next) => {
    if (!req.sesion || !req.sesion.nivel || req.sesion.nivel < nivelMinimo) {
        return next(
            new AppError('No tienes permiso para realizar esta acción', 403)
        );
    }

    return next();
};

/**
 * Restringe una ruta a quien tenga un permiso puntual. Requiere cargarSesion antes.
 */
const requerirPermiso = (nombrePermiso) => (req, res, next) => {
    if (!req.sesion || !req.sesion.permisos.includes(nombrePermiso)) {
        return next(
            new AppError('No tienes permiso para realizar esta acción', 403)
        );
    }

    return next();
};

module.exports = {
    cargarMembresia,
    requerirRol,
    cargarSesion,
    requerirNivel,
    requerirPermiso,
};
