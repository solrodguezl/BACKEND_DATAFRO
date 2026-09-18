const pool = require('../config/db');

// La persona se devuelve con el nombre completo y el barrio como texto.
const SELECT_PERSONA = `
    SELECT
        p.id_persona,
        p.documento,
        TRIM(p.nombres || ' ' || COALESCE(p.apellidos, '')) AS nombres,
        p.etnia,
        COALESCE(
            p.edad::int,
            CASE WHEN p.fecha_nacimiento IS NOT NULL
                THEN EXTRACT(YEAR FROM age(p.fecha_nacimiento))::int
            END
        ) AS edad,
        p.genero,
        b.nombre AS barrio
    FROM persona p
    LEFT JOIN barrio b ON b.id_barrio = p.id_barrio
`;

const buscarPersonaPorDocumento = async (organizacionId, documento) => {
    const result = await pool.query(
        `${SELECT_PERSONA}
         WHERE p.id_organizacion = $1 AND p.documento = $2
         LIMIT 1`,
        [organizacionId, documento]
    );

    return result.rows[0];
};

// actividad.lugar guarda el barrio donde ocurre la actividad.
const COLUMNAS_ACTIVIDAD = `
    a.id_actividad,
    a.nombre,
    to_char(a.fecha, 'YYYY-MM-DD') AS fecha,
    a.lugar AS barrio,
    COUNT(s.id_asistencia)::int AS total_asistentes
`;

const crearActividad = async ({ organizacionId, nombre, fecha, barrio, creadoPor }) => {
    const result = await pool.query(
        `
        INSERT INTO actividad (id_organizacion, id_usuario_responsable, nombre, fecha, lugar)
        VALUES ($1, $2, $3, COALESCE($4::date, CURRENT_DATE), $5)
        RETURNING
            id_actividad,
            nombre,
            to_char(fecha, 'YYYY-MM-DD') AS fecha,
            lugar AS barrio,
            0 AS total_asistentes
        `,
        [organizacionId, creadoPor, nombre, fecha ?? null, barrio ?? null]
    );

    return result.rows[0];
};

const listarActividades = async (organizacionId) => {
    const result = await pool.query(
        `
        SELECT ${COLUMNAS_ACTIVIDAD}
        FROM actividad a
        LEFT JOIN asistencia s ON s.id_actividad = a.id_actividad
        WHERE a.id_organizacion = $1
        GROUP BY a.id_actividad
        ORDER BY a.fecha DESC, a.nombre
        LIMIT 100
        `,
        [organizacionId]
    );

    return result.rows;
};

const obtenerActividad = async (organizacionId, actividadId) => {
    const result = await pool.query(
        `
        SELECT ${COLUMNAS_ACTIVIDAD}
        FROM actividad a
        LEFT JOIN asistencia s ON s.id_actividad = a.id_actividad
        WHERE a.id_organizacion = $1 AND a.id_actividad = $2
        GROUP BY a.id_actividad
        `,
        [organizacionId, actividadId]
    );

    return result.rows[0];
};

/**
 * Crea o actualiza a la persona (por documento dentro de la organización) y
 * registra su asistencia, todo en una transacción. Devuelve null si la persona
 * ya estaba registrada en esa actividad.
 */
const registrarAsistencia = async ({
    organizacionId,
    actividadId,
    registradoPor,
    persona,
}) => {
    const client = await pool.connect();

    try {
        await client.query('BEGIN');

        // Barrio: se busca por nombre; si no existe se crea.
        const barrioBuscado = await client.query(
            'SELECT id_barrio FROM barrio WHERE LOWER(nombre) = LOWER($1) LIMIT 1',
            [persona.barrio]
        );

        let idBarrio = barrioBuscado.rows[0]?.id_barrio;

        if (!idBarrio) {
            const nuevo = await client.query(
                `INSERT INTO barrio (nombre, comuna) VALUES ($1, 'Comuna 13') RETURNING id_barrio`,
                [persona.barrio]
            );

            idBarrio = nuevo.rows[0].id_barrio;
        }

        // Persona: el nombre completo se guarda en nombres (apellidos queda vacío).
        const existente = await client.query(
            `SELECT id_persona FROM persona
             WHERE id_organizacion = $1 AND documento = $2
             FOR UPDATE`,
            [organizacionId, persona.documento]
        );

        let idPersona;

        if (existente.rows[0]) {
            idPersona = existente.rows[0].id_persona;

            await client.query(
                `
                UPDATE persona SET
                    nombres = $1,
                    apellidos = NULL,
                    etnia = $2,
                    edad = $3,
                    genero = $4,
                    id_barrio = $5,
                    sincronizado = true,
                    fecha_sincronizacion = CURRENT_TIMESTAMP
                WHERE id_persona = $6
                `,
                [
                    persona.nombres,
                    persona.etnia,
                    persona.edad,
                    persona.genero,
                    idBarrio,
                    idPersona,
                ]
            );
        } else {
            const nueva = await client.query(
                `
                INSERT INTO persona (
                    id_organizacion, id_barrio, nombres, documento,
                    etnia, edad, genero, sincronizado, fecha_sincronizacion
                )
                VALUES ($1, $2, $3, $4, $5, $6, $7, true, CURRENT_TIMESTAMP)
                RETURNING id_persona
                `,
                [
                    organizacionId,
                    idBarrio,
                    persona.nombres,
                    persona.documento,
                    persona.etnia,
                    persona.edad,
                    persona.genero,
                ]
            );

            idPersona = nueva.rows[0].id_persona;
        }

        const yaRegistrada = await client.query(
            'SELECT 1 FROM asistencia WHERE id_persona = $1 AND id_actividad = $2',
            [idPersona, actividadId]
        );

        if (yaRegistrada.rowCount > 0) {
            await client.query('ROLLBACK');
            return null;
        }

        const asistencia = await client.query(
            `
            INSERT INTO asistencia (
                id_persona, id_actividad, id_usuario, sincronizado, fecha_sincronizacion
            )
            VALUES ($1, $2, $3, true, CURRENT_TIMESTAMP)
            RETURNING id_asistencia, fecha_hora_registro AS fecha_registro
            `,
            [idPersona, actividadId, registradoPor]
        );

        const personaGuardada = await client.query(
            `${SELECT_PERSONA} WHERE p.id_persona = $1`,
            [idPersona]
        );

        await client.query('COMMIT');

        return {
            persona: personaGuardada.rows[0],
            asistencia: asistencia.rows[0],
        };
    } catch (error) {
        await client.query('ROLLBACK');
        throw error;
    } finally {
        client.release();
    }
};

const listarAsistentes = async (actividadId) => {
    const result = await pool.query(
        `
        SELECT
            s.id_asistencia,
            s.fecha_hora_registro AS fecha_registro,
            p.documento,
            TRIM(p.nombres || ' ' || COALESCE(p.apellidos, '')) AS nombres
        FROM asistencia s
        JOIN persona p ON p.id_persona = s.id_persona
        WHERE s.id_actividad = $1
        ORDER BY s.fecha_hora_registro DESC
        `,
        [actividadId]
    );

    return result.rows;
};

module.exports = {
    buscarPersonaPorDocumento,
    crearActividad,
    listarActividades,
    obtenerActividad,
    registrarAsistencia,
    listarAsistentes,
};
