const pool = require('../config/db');

// La persona se devuelve igual que en asistenciaRepository, más los campos
// propios de identificación que usa la caracterización NARP (tipo de
// documento, fecha de nacimiento).
const SELECT_PERSONA = `
    SELECT
        p.id_persona,
        p.documento,
        p.tipo_documento,
        TRIM(p.nombres || ' ' || COALESCE(p.apellidos, '')) AS nombres,
        p.etnia,
        to_char(p.fecha_nacimiento, 'YYYY-MM-DD') AS fecha_nacimiento,
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

/**
 * Catálogo completo (categorías → preguntas → opciones), ordenado para
 * pintar el formulario dinámico en el front. Las preguntas inactivas no se
 * incluyen (permite retirar una pregunta sin borrar las respuestas ya
 * guardadas, RNF-15).
 */
const obtenerCatalogo = async () => {
    const categorias = await pool.query(
        `SELECT id_categoria, nombre, orden, capitulo, orden_capitulo, nivel, objetivo,
                responde, tiempo_estimado_min, elegibilidad_edad_min, elegibilidad_edad_max,
                elegibilidad_genero, elegibilidad_jefe_hogar
         FROM categoria_dss ORDER BY orden, nombre`
    );

    const preguntas = await pool.query(
        `SELECT id_pregunta, id_categoria, texto_pregunta, tipo_respuesta, orden,
                numero_pregunta, nota, unidad, escala_min, escala_max,
                condicion_pregunta_id, condicion_operador, condicion_valor,
                condicion_edad_operador, condicion_edad_valor
         FROM pregunta_dss
         WHERE activa = true
         ORDER BY orden, texto_pregunta`
    );

    const opciones = await pool.query(
        `SELECT id_opcion, id_pregunta, texto_opcion, valor, orden
         FROM opcion_respuesta
         ORDER BY orden, texto_opcion`
    );

    const opcionesPorPregunta = new Map();

    for (const opcion of opciones.rows) {
        const lista = opcionesPorPregunta.get(opcion.id_pregunta) ?? [];
        lista.push(opcion);
        opcionesPorPregunta.set(opcion.id_pregunta, lista);
    }

    const preguntasPorCategoria = new Map();

    for (const pregunta of preguntas.rows) {
        const lista = preguntasPorCategoria.get(pregunta.id_categoria) ?? [];
        lista.push({
            ...pregunta,
            opciones: opcionesPorPregunta.get(pregunta.id_pregunta) ?? [],
        });
        preguntasPorCategoria.set(pregunta.id_categoria, lista);
    }

    return categorias.rows.map((categoria) => ({
        ...categoria,
        preguntas: preguntasPorCategoria.get(categoria.id_categoria) ?? [],
    }));
};

const buscarPersonaPorDocumento = async (organizacionId, documento) => {
    const result = await pool.query(
        `${SELECT_PERSONA}
         WHERE p.id_organizacion = $1 AND p.documento = $2
         LIMIT 1`,
        [organizacionId, documento]
    );

    return result.rows[0];
};

/**
 * Para el botón "ya hay alguien de mi hogar registrado" en el capítulo B/C
 * del nuevo instrumento: busca si ese documento ya tiene hogar asignado,
 * antes de guardar, para mostrarle a la usuaria a quién va a vincular.
 */
const buscarHogarPorDocumento = async (organizacionId, documento) => {
    const result = await pool.query(
        `SELECT p.id_persona, TRIM(p.nombres || ' ' || COALESCE(p.apellidos, '')) AS nombres,
                p.id_hogar, h.id_vivienda
         FROM persona p
         LEFT JOIN hogar h ON h.id_hogar = p.id_hogar
         WHERE p.id_organizacion = $1 AND p.documento = $2
         LIMIT 1`,
        [organizacionId, documento]
    );

    return result.rows[0] ?? null;
};

/**
 * Último formulario_dss de una persona (el más reciente), con sus respuestas
 * ya guardadas. Permite reabrir un borrador o consultar la caracterización
 * completa.
 */
const obtenerUltimoFormulario = async (idPersona) => {
    const formulario = await pool.query(
        `SELECT id_formulario, estado, to_char(fecha_diligenciamiento, 'YYYY-MM-DD') AS fecha_diligenciamiento,
                fecha_ultima_actualizacion
         FROM formulario_dss
         WHERE id_persona = $1
         ORDER BY fecha_ultima_actualizacion DESC
         LIMIT 1`,
        [idPersona]
    );

    const encontrado = formulario.rows[0];

    if (!encontrado) {
        return null;
    }

    const respuestas = await pool.query(
        `SELECT id_pregunta, id_opcion, valor_respuesta
         FROM respuesta_dss
         WHERE id_formulario = $1`,
        [encontrado.id_formulario]
    );

    return { ...encontrado, respuestas: respuestas.rows };
};

const buscarOCrearBarrio = async (client, nombreBarrio) => {
    const encontrado = await client.query(
        'SELECT id_barrio FROM barrio WHERE LOWER(nombre) = LOWER($1) LIMIT 1',
        [nombreBarrio]
    );

    if (encontrado.rows[0]) {
        return encontrado.rows[0].id_barrio;
    }

    const nuevo = await client.query(
        `INSERT INTO barrio (nombre, comuna) VALUES ($1, 'Comuna 13') RETURNING id_barrio`,
        [nombreBarrio]
    );

    return nuevo.rows[0].id_barrio;
};

/**
 * Resuelve a qué vivienda/hogar queda ligada esta persona, para el nuevo
 * instrumento de 342 preguntas (capítulos B/C: vivienda y hogar se
 * diligencian una sola vez y se comparten entre las personas que conviven).
 * Orden de prioridad:
 *   1) Si la persona ya tenía un hogar asignado (de un guardado anterior de
 *      este mismo formulario), se reutiliza tal cual — nunca se crea uno
 *      nuevo en cada autoguardado.
 *   2) Si en este guardado se indicó el documento de alguien de la misma
 *      vivienda ya registrado, se reutiliza su hogar.
 *   3) Si no hay nada que reutilizar, se crea una vivienda y un hogar nuevos.
 */
const resolverViviendaHogar = async (
    client,
    { organizacionId, idBarrio, direccion, documentoHogar, idHogarExistente }
) => {
    if (idHogarExistente) {
        const hogar = await client.query(
            'SELECT id_hogar, id_vivienda FROM hogar WHERE id_hogar = $1',
            [idHogarExistente]
        );

        if (hogar.rows[0]) {
            return {
                idVivienda: hogar.rows[0].id_vivienda,
                idHogar: hogar.rows[0].id_hogar,
                hogarReutilizado: true,
            };
        }
    }

    if (documentoHogar) {
        const miembro = await client.query(
            `SELECT p.id_hogar, h.id_vivienda
             FROM persona p
             JOIN hogar h ON h.id_hogar = p.id_hogar
             WHERE p.id_organizacion = $1 AND p.documento = $2 AND p.id_hogar IS NOT NULL
             LIMIT 1`,
            [organizacionId, documentoHogar]
        );

        if (miembro.rows[0]) {
            return {
                idVivienda: miembro.rows[0].id_vivienda,
                idHogar: miembro.rows[0].id_hogar,
                hogarReutilizado: true,
            };
        }
    }

    const vivienda = await client.query(
        `INSERT INTO vivienda (id_organizacion, id_barrio, direccion)
         VALUES ($1, $2, $3) RETURNING id_vivienda`,
        [organizacionId, idBarrio, direccion ?? null]
    );

    const hogar = await client.query(
        'INSERT INTO hogar (id_vivienda) VALUES ($1) RETURNING id_hogar',
        [vivienda.rows[0].id_vivienda]
    );

    return {
        idVivienda: vivienda.rows[0].id_vivienda,
        idHogar: hogar.rows[0].id_hogar,
        hogarReutilizado: false,
    };
};

/**
 * Crea o actualiza la persona (por documento dentro de la organización, la
 * misma llave natural que usa el módulo de asistencia) y guarda su
 * formulario de caracterización con las respuestas, en una sola transacción.
 * Si ya existe un formulario en borrador para esa persona, lo continúa en
 * vez de crear uno nuevo.
 */
const guardarCaracterizacion = async ({
    organizacionId,
    usuarioId,
    persona,
    estado,
    respuestas,
    vivienda,
}) => {
    const client = await pool.connect();

    try {
        await client.query('BEGIN');

        const idBarrio = await buscarOCrearBarrio(client, persona.barrio);

        const existente = await client.query(
            `SELECT id_persona FROM persona
             WHERE id_organizacion = $1 AND documento = $2
             FOR UPDATE`,
            [organizacionId, persona.documento]
        );

        let idPersona;
        let idHogarPrevio = null;

        if (existente.rows[0]) {
            idPersona = existente.rows[0].id_persona;

            const previa = await client.query(
                'SELECT id_hogar FROM persona WHERE id_persona = $1',
                [idPersona]
            );
            idHogarPrevio = previa.rows[0]?.id_hogar ?? null;

            await client.query(
                `
                UPDATE persona SET
                    nombres = $1,
                    apellidos = NULL,
                    tipo_documento = COALESCE($2, tipo_documento),
                    fecha_nacimiento = COALESCE($3::date, fecha_nacimiento),
                    etnia = COALESCE($4, etnia),
                    edad = COALESCE($5, edad),
                    genero = COALESCE($6, genero),
                    id_barrio = $7,
                    sincronizado = true,
                    fecha_sincronizacion = CURRENT_TIMESTAMP
                WHERE id_persona = $8
                `,
                [
                    persona.nombres,
                    persona.tipoDocumento ?? null,
                    persona.fechaNacimiento ?? null,
                    persona.etnia ?? null,
                    persona.edad ?? null,
                    persona.genero ?? null,
                    idBarrio,
                    idPersona,
                ]
            );
        } else {
            const nueva = await client.query(
                `
                INSERT INTO persona (
                    id_organizacion, id_barrio, nombres, documento, tipo_documento,
                    fecha_nacimiento, etnia, edad, genero, sincronizado, fecha_sincronizacion
                )
                VALUES ($1, $2, $3, $4, $5, $6::date, $7, $8, $9, true, CURRENT_TIMESTAMP)
                RETURNING id_persona
                `,
                [
                    organizacionId,
                    idBarrio,
                    persona.nombres,
                    persona.documento,
                    persona.tipoDocumento ?? null,
                    persona.fechaNacimiento ?? null,
                    persona.etnia ?? null,
                    persona.edad ?? null,
                    persona.genero ?? null,
                ]
            );

            idPersona = nueva.rows[0].id_persona;
        }

        // Resuelve vivienda/hogar (capítulos B/C del nuevo instrumento). Si la
        // persona ya tenía hogar de un guardado anterior se reutiliza tal cual;
        // si no, se intenta por el documento de un conviviente ya registrado, o
        // se crea una vivienda/hogar nuevos. Para formularios que no mandan
        // `vivienda` (p. ej. el formulario corto de 49 preguntas) esto solo
        // reutiliza lo que ya hubiera, sin crear nada nuevo.
        let idVivienda = null;
        let idHogar = idHogarPrevio;
        let hogarReutilizado = Boolean(idHogarPrevio);

        if (vivienda || idHogarPrevio) {
            const resuelto = await resolverViviendaHogar(client, {
                organizacionId,
                idBarrio,
                direccion: vivienda?.direccion ?? null,
                documentoHogar: vivienda?.documentoHogar ?? null,
                idHogarExistente: idHogarPrevio,
            });

            idVivienda = resuelto.idVivienda;
            idHogar = resuelto.idHogar;
            hogarReutilizado = resuelto.hogarReutilizado;

            if (idHogar !== idHogarPrevio) {
                await client.query('UPDATE persona SET id_hogar = $1 WHERE id_persona = $2', [
                    idHogar,
                    idPersona,
                ]);
            }
        }

        // Continúa el borrador más reciente de esta persona si existe; si no, crea uno nuevo.
        const borrador = await client.query(
            `SELECT id_formulario FROM formulario_dss
             WHERE id_persona = $1 AND estado = 'borrador'
             ORDER BY fecha_ultima_actualizacion DESC
             LIMIT 1
             FOR UPDATE`,
            [idPersona]
        );

        let idFormulario;

        if (borrador.rows[0]) {
            idFormulario = borrador.rows[0].id_formulario;

            await client.query(
                `
                UPDATE formulario_dss SET
                    id_usuario = $1,
                    estado = $2,
                    fecha_diligenciamiento = CASE WHEN $2 = 'completo' THEN CURRENT_DATE ELSE fecha_diligenciamiento END,
                    fecha_ultima_actualizacion = CURRENT_TIMESTAMP,
                    sincronizado = true,
                    fecha_sincronizacion = CURRENT_TIMESTAMP,
                    id_vivienda = COALESCE($4, id_vivienda),
                    id_hogar = COALESCE($5, id_hogar)
                WHERE id_formulario = $3
                `,
                [usuarioId, estado, idFormulario, idVivienda, idHogar]
            );
        } else {
            const nuevo = await client.query(
                `
                INSERT INTO formulario_dss (
                    id_persona, id_usuario, estado, fecha_diligenciamiento,
                    sincronizado, fecha_sincronizacion, id_vivienda, id_hogar
                )
                VALUES (
                    $1, $2, $3,
                    CASE WHEN $3 = 'completo' THEN CURRENT_DATE ELSE NULL END,
                    true, CURRENT_TIMESTAMP, $4, $5
                )
                RETURNING id_formulario
                `,
                [idPersona, usuarioId, estado, idVivienda, idHogar]
            );

            idFormulario = nuevo.rows[0].id_formulario;
        }

        for (const respuesta of respuestas) {
            await client.query(
                `
                INSERT INTO respuesta_dss (id_formulario, id_pregunta, id_opcion, valor_respuesta)
                VALUES ($1, $2, $3, $4)
                ON CONFLICT (id_formulario, id_pregunta) DO UPDATE SET
                    id_opcion = EXCLUDED.id_opcion,
                    valor_respuesta = EXCLUDED.valor_respuesta
                `,
                [
                    idFormulario,
                    respuesta.idPregunta,
                    respuesta.idOpcion ?? null,
                    respuesta.valorRespuesta ?? null,
                ]
            );
        }

        const personaGuardada = await client.query(
            `${SELECT_PERSONA} WHERE p.id_persona = $1`,
            [idPersona]
        );

        const formularioGuardado = await client.query(
            `SELECT id_formulario, estado, to_char(fecha_diligenciamiento, 'YYYY-MM-DD') AS fecha_diligenciamiento,
                    fecha_ultima_actualizacion
             FROM formulario_dss WHERE id_formulario = $1`,
            [idFormulario]
        );

        await client.query('COMMIT');

        return {
            persona: personaGuardada.rows[0],
            formulario: formularioGuardado.rows[0],
            respuestasGuardadas: respuestas.length,
            hogar: idHogar ? { idVivienda, idHogar, reutilizado: hogarReutilizado } : null,
        };
    } catch (error) {
        await client.query('ROLLBACK');
        throw error;
    } finally {
        client.release();
    }
};

module.exports = {
    obtenerCatalogo,
    buscarPersonaPorDocumento,
    buscarHogarPorDocumento,
    obtenerUltimoFormulario,
    guardarCaracterizacion,
};
