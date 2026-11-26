const pool = require('../config/db');

/** Historial de organizaciones registradas, con el total de miembros activos de cada una. */
const listarTodas = async () => {
    const result = await pool.query(`
        SELECT
            o.id_organizacion,
            o.nombre,
            o.tipo,
            o.nit,
            o.fecha_creacion,
            COUNT(ou.id_usuario) FILTER (WHERE ou.activo)::int AS total_miembros
        FROM organizacion o
        LEFT JOIN organizaciones_usuarios ou ON ou.id_organizacion = o.id_organizacion
        GROUP BY o.id_organizacion
        ORDER BY o.fecha_creacion DESC
    `);

    return result.rows;
};

const obtenerPorId = async (id) => {
    const result = await pool.query(
        `
        SELECT id_organizacion, nombre, tipo, nit, fecha_creacion
        FROM organizacion
        WHERE id_organizacion = $1
        `,
        [id]
    );

    return result.rows[0];
};

module.exports = { listarTodas, obtenerPorId };
