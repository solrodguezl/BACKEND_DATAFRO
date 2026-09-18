const pool = require('../config/db');
const AppError = require('../utils/AppError');
const { ROLES } = require('../utils/catalogos');

const COLUMNAS = `
    u.id_usuario AS id,
    u.documento,
    u.activo,
    UPPER(r.nombre) AS rol,
    COALESCE(p.nombres, u.nombre) AS nombres,
    p.apellidos,
    COALESCE(p.telefono, u.telefono) AS telefono,
    p.foto_perfil
`;

const DESDE = `
    FROM usuario u
    JOIN rol r ON r.id_rol = u.id_rol
    LEFT JOIN perfiles p ON p.usuario_id = u.id_usuario
`;

const SOLO_ROLES_ORG = `UPPER(r.nombre) = ANY($2::text[])`;

const listarPorOrganizacion = async (organizacionId) => {
    const result = await pool.query(
        `
        SELECT ${COLUMNAS}
        ${DESDE}
        WHERE u.id_organizacion = $1 AND ${SOLO_ROLES_ORG}
        ORDER BY
            CASE UPPER(r.nombre) WHEN 'DIRECTOR' THEN 1 WHEN 'COORDINADOR' THEN 2 ELSE 3 END,
            COALESCE(p.nombres, u.nombre) NULLS LAST,
            u.documento
        `,
        [organizacionId, ROLES]
    );

    return result.rows;
};

const obtener = async (organizacionId, usuarioId) => {
    const result = await pool.query(
        `
        SELECT ${COLUMNAS}
        ${DESDE}
        WHERE u.id_organizacion = $1 AND u.id_usuario = $2
        LIMIT 1
        `,
        [organizacionId, usuarioId]
    );

    return result.rows[0];
};

const obtenerIdRol = async (client, rol) => {
    const result = await client.query(
        'SELECT id_rol FROM rol WHERE UPPER(nombre) = $1 LIMIT 1',
        [rol]
    );

    if (!result.rows[0]) {
        throw new AppError(
            'El rol seleccionado no existe en la base de datos. Ejecuta npm run migrate.',
            400
        );
    }

    return result.rows[0].id_rol;
};

const upsertPerfil = (client, usuarioId, { nombres, apellidos, telefono }) =>
    client.query(
        `
        INSERT INTO perfiles (usuario_id, nombres, apellidos, telefono)
        VALUES ($1, $2, $3, $4)
        ON CONFLICT (usuario_id) DO UPDATE SET
            nombres = EXCLUDED.nombres,
            apellidos = EXCLUDED.apellidos,
            telefono = EXCLUDED.telefono,
            fecha_actualizacion = CURRENT_TIMESTAMP
        `,
        [usuarioId, nombres, apellidos, telefono ?? null]
    );

/**
 * Crea usuario + perfil en una sola transacción.
 */
const crear = async ({
    organizacionId,
    documento,
    claveHash,
    nombres,
    apellidos,
    telefono,
    rol,
}) => {
    const client = await pool.connect();

    try {
        await client.query('BEGIN');

        const idRol = await obtenerIdRol(client, rol);

        const usuario = await client.query(
            `
            INSERT INTO usuario (
                id_organizacion, id_rol, nombre, documento, telefono, clave_hash
            )
            VALUES ($1, $2, $3, $4, $5, $6)
            RETURNING id_usuario
            `,
            [
                organizacionId,
                idRol,
                `${nombres} ${apellidos}`.trim(),
                documento,
                telefono ?? null,
                claveHash,
            ]
        );

        const usuarioId = usuario.rows[0].id_usuario;

        await upsertPerfil(client, usuarioId, { nombres, apellidos, telefono });

        await client.query('COMMIT');

        return usuarioId;
    } catch (error) {
        await client.query('ROLLBACK');
        throw error;
    } finally {
        client.release();
    }
};

const actualizar = async (
    organizacionId,
    usuarioId,
    { nombres, apellidos, telefono, rol, activo, claveHash }
) => {
    const client = await pool.connect();

    try {
        await client.query('BEGIN');

        const idRol = await obtenerIdRol(client, rol);

        await client.query(
            `
            UPDATE usuario
            SET id_rol = $1, nombre = $2, telefono = $3
            WHERE id_usuario = $4 AND id_organizacion = $5
            `,
            [
                idRol,
                `${nombres} ${apellidos}`.trim(),
                telefono ?? null,
                usuarioId,
                organizacionId,
            ]
        );

        await upsertPerfil(client, usuarioId, { nombres, apellidos, telefono });

        if (typeof activo === 'boolean') {
            await client.query(
                'UPDATE usuario SET activo = $1 WHERE id_usuario = $2',
                [activo, usuarioId]
            );
        }

        if (claveHash) {
            await client.query(
                'UPDATE usuario SET clave_hash = $1 WHERE id_usuario = $2',
                [claveHash, usuarioId]
            );

            // Cierra las sesiones abiertas para que use la nueva contraseña.
            await client.query(
                'UPDATE sesiones SET revocado = true WHERE usuario_id = $1 AND revocado = false',
                [usuarioId]
            );
        }

        await client.query('COMMIT');
    } catch (error) {
        await client.query('ROLLBACK');
        throw error;
    } finally {
        client.release();
    }
};

module.exports = { listarPorOrganizacion, obtener, crear, actualizar };
