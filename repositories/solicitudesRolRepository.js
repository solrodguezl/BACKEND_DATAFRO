const pool = require('../config/db');
const AppError = require('../utils/AppError');

const COLUMNAS = `
    id_solicitud,
    id_usuario,
    rol_solicitado,
    organizacion_nombre,
    nit,
    celular,
    cargo,
    motivo,
    estado,
    fecha_solicitud,
    fecha_resolucion,
    resuelto_por,
    comentario_resolucion
`;

const crear = async ({
    usuarioId,
    rolSolicitado,
    organizacionNombre,
    nit,
    celular,
    cargo,
    motivo,
}) => {
    const result = await pool.query(
        `
        INSERT INTO solicitud_rol (
            id_usuario, rol_solicitado, organizacion_nombre, nit, celular, cargo, motivo
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7)
        RETURNING ${COLUMNAS}
        `,
        [
            usuarioId,
            rolSolicitado,
            organizacionNombre,
            nit ?? null,
            celular ?? null,
            cargo ?? null,
            motivo ?? null,
        ]
    );

    return result.rows[0];
};

const listarPorUsuario = async (usuarioId) => {
    const result = await pool.query(
        `SELECT ${COLUMNAS} FROM solicitud_rol WHERE id_usuario = $1 ORDER BY fecha_solicitud DESC`,
        [usuarioId]
    );

    return result.rows;
};

const listarAdmin = async (estado) => {
    const result = await pool.query(
        `
        SELECT
            s.id_solicitud, s.rol_solicitado, s.organizacion_nombre, s.nit, s.celular,
            s.cargo, s.motivo, s.estado, s.fecha_solicitud, s.fecha_resolucion,
            s.resuelto_por, s.comentario_resolucion,
            u.id_usuario, u.documento,
            COALESCE(p.nombres, u.nombre) AS nombres,
            p.apellidos
        FROM solicitud_rol s
        JOIN usuario u ON u.id_usuario = s.id_usuario
        LEFT JOIN perfiles p ON p.usuario_id = u.id_usuario
        WHERE $1::varchar IS NULL OR s.estado = $1
        ORDER BY (s.estado = 'pendiente') DESC, s.fecha_solicitud ASC
        `,
        [estado ?? null]
    );

    return result.rows;
};

const obtenerIdRol = async (client, rolNombre) => {
    const result = await client.query(
        'SELECT id_rol FROM rol WHERE UPPER(nombre) = $1 LIMIT 1',
        [rolNombre]
    );

    if (!result.rows[0]) {
        throw new AppError(
            `El rol ${rolNombre} no existe en la base de datos`,
            400
        );
    }

    return result.rows[0].id_rol;
};

/** Busca la organización por NIT (si lo dieron) o por nombre; si no existe, la crea. */
const buscarOCrearOrganizacion = async (client, { nombre, nit }) => {
    if (nit) {
        const porNit = await client.query(
            'SELECT id_organizacion FROM organizacion WHERE nit = $1 LIMIT 1',
            [nit]
        );

        if (porNit.rows[0]) {
            return porNit.rows[0].id_organizacion;
        }
    }

    const porNombre = await client.query(
        'SELECT id_organizacion FROM organizacion WHERE LOWER(nombre) = LOWER($1) LIMIT 1',
        [nombre]
    );

    if (porNombre.rows[0]) {
        return porNombre.rows[0].id_organizacion;
    }

    const nueva = await client.query(
        'INSERT INTO organizacion (nombre, nit) VALUES ($1, $2) RETURNING id_organizacion',
        [nombre, nit ?? null]
    );

    return nueva.rows[0].id_organizacion;
};

const resolver = async ({ id, resueltoPor, comentario, estadoFinal, aplicarCambios }) => {
    const client = await pool.connect();

    try {
        await client.query('BEGIN');

        const actual = await client.query(
            `SELECT ${COLUMNAS} FROM solicitud_rol WHERE id_solicitud = $1 FOR UPDATE`,
            [id]
        );

        const solicitud = actual.rows[0];

        if (!solicitud) {
            throw new AppError('Solicitud no encontrada', 404);
        }

        if (solicitud.estado !== 'pendiente') {
            throw new AppError('Esta solicitud ya fue resuelta', 409);
        }

        if (aplicarCambios) {
            await aplicarCambios(client, solicitud);
        }

        const actualizada = await client.query(
            `
            UPDATE solicitud_rol SET
                estado = $1,
                fecha_resolucion = CURRENT_TIMESTAMP,
                resuelto_por = $2,
                comentario_resolucion = $3
            WHERE id_solicitud = $4
            RETURNING ${COLUMNAS}
            `,
            [estadoFinal, resueltoPor, comentario ?? null, id]
        );

        await client.query('COMMIT');

        return actualizada.rows[0];
    } catch (error) {
        await client.query('ROLLBACK');
        throw error;
    } finally {
        client.release();
    }
};

const aprobar = ({ id, resueltoPor, comentario }) =>
    resolver({
        id,
        resueltoPor,
        comentario,
        estadoFinal: 'aprobada',
        aplicarCambios: async (client, solicitud) => {
            const idOrganizacion = await buscarOCrearOrganizacion(client, {
                nombre: solicitud.organizacion_nombre,
                nit: solicitud.nit,
            });

            const idRol = await obtenerIdRol(client, solicitud.rol_solicitado);

            await client.query(
                'UPDATE usuario SET id_organizacion = $1, id_rol = $2 WHERE id_usuario = $3',
                [idOrganizacion, idRol, solicitud.id_usuario]
            );

            await client.query(
                `
                INSERT INTO organizaciones_usuarios (id_usuario, id_organizacion, activo)
                VALUES ($1, $2, true)
                ON CONFLICT (id_usuario, id_organizacion) DO UPDATE SET activo = true
                `,
                [solicitud.id_usuario, idOrganizacion]
            );
        },
    });

const rechazar = ({ id, resueltoPor, comentario }) =>
    resolver({ id, resueltoPor, comentario, estadoFinal: 'rechazada' });

module.exports = {
    crear,
    listarPorUsuario,
    listarAdmin,
    aprobar,
    rechazar,
};
