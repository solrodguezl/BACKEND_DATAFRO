const express = require('express');

const router = express.Router();

const pool = require('../config/db');
const { authenticate } = require('../middleware/authMiddleware');
const { ROLES, ETNIAS, GENEROS } = require('../utils/catalogos');

router.get('/', authenticate, async (req, res, next) => {
    try {
        const barrios = await pool.query(
            'SELECT nombre FROM barrio ORDER BY nombre'
        );

        res.json({
            roles: ROLES,
            etnias: ETNIAS,
            generos: GENEROS,
            barrios: barrios.rows.map((b) => b.nombre),
        });
    } catch (error) {
        next(error);
    }
});

module.exports = router;
