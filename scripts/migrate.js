require('dotenv').config();

const fs = require('fs');
const path = require('path');
const pool = require('../config/db');

// Se ejecutan en orden y todos son idempotentes: en una base que ya existe no rompen nada.
const ARCHIVOS = ['esquema_base.sql', 'base_inicial.sql', 'asistir_schema.sql'];

const run = async () => {
    for (const archivo of ARCHIVOS) {
        const sql = fs.readFileSync(
            path.join(__dirname, '..', 'database', archivo),
            'utf8'
        );

        await pool.query(sql);
        console.log(`OK: ${archivo}`);
    }
};

run()
    .catch((error) => {
        console.error('Error en la migración:', error.message);
        process.exitCode = 1;
    })
    .finally(() => pool.end());
