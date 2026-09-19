/**
 * Crea un usuario con su perfil y rol.
 *
 * Uso:
 *   node scripts/crear-usuario.js <documento> <clave> <nombres> <apellidos> <rol> [organizacion]
 *
 * Ejemplo:
 *   node scripts/crear-usuario.js 1234567890 MiClave123 "Sol" "Rodriguez" Director
 *
 * rol: Director | Coordinador | Gestor | "Administrador investigativo"
 * organizacion (opcional): por defecto "Mesa Afro de la Comuna 13"
 */
require('dotenv').config();

const bcrypt = require('bcrypt');
const pool = require('../config/db');

const [documento, clave, nombres, apellidos, rol, organizacion] =
    process.argv.slice(2);

const run = async () => {
    if (!documento || !clave || !nombres || !apellidos || !rol) {
        throw new Error(
            'Uso: node scripts/crear-usuario.js <documento> <clave> <nombres> <apellidos> <rol> [organizacion]'
        );
    }

    if (clave.length < 8) {
        throw new Error('La contraseña debe tener al menos 8 caracteres');
    }

    const rolResult = await pool.query(
        'SELECT id_rol FROM rol WHERE UPPER(nombre) = UPPER($1) LIMIT 1',
        [rol]
    );

    if (!rolResult.rows[0]) {
        throw new Error(`No existe el rol "${rol}"`);
    }

    const orgResult = await pool.query(
        'SELECT id_organizacion FROM organizacion WHERE nombre = $1 LIMIT 1',
        [organizacion || 'Mesa Afro de la Comuna 13']
    );

    if (!orgResult.rows[0]) {
        throw new Error('No existe la organización indicada');
    }

    const existe = await pool.query(
        'SELECT 1 FROM usuario WHERE documento = $1',
        [documento]
    );

    if (existe.rowCount > 0) {
        throw new Error(`Ya existe un usuario con el documento ${documento}`);
    }

    const claveHash = await bcrypt.hash(
        clave,
        Number(process.env.BCRYPT_SALT_ROUNDS || 12)
    );

    const client = await pool.connect();

    try {
        await client.query('BEGIN');

        const usuario = await client.query(
            `INSERT INTO usuario (id_organizacion, id_rol, nombre, documento, clave_hash)
             VALUES ($1, $2, $3, $4, $5)
             RETURNING id_usuario`,
            [
                orgResult.rows[0].id_organizacion,
                rolResult.rows[0].id_rol,
                `${nombres} ${apellidos}`,
                documento,
                claveHash,
            ]
        );

        await client.query(
            `INSERT INTO perfiles (usuario_id, nombres, apellidos)
             VALUES ($1, $2, $3)`,
            [usuario.rows[0].id_usuario, nombres, apellidos]
        );

        await client.query('COMMIT');
    } catch (error) {
        await client.query('ROLLBACK');
        throw error;
    } finally {
        client.release();
    }

    console.log(`Usuario ${documento} creado como ${rol}.`);
};

run()
    .catch((error) => {
        console.error('Error:', error.message);
        process.exitCode = 1;
    })
    .finally(() => pool.end());
