const express = require('express');

const router = express.Router();

const controller = require('../controllers/caracterizacionController');
const { authenticate } = require('../middleware/authMiddleware');
const { cargarMembresia } = require('../middleware/membresiaMiddleware');
const validate = require('../middleware/validateMiddleware');
const {
    buscarPersonaSchema,
    guardarCaracterizacionSchema,
} = require('../validators/caracterizacionValidator');

router.use(authenticate, cargarMembresia);

// GET /api/caracterizacion/catalogo  (categorías, preguntas y opciones del formulario NARP — HU-02)
router.get('/catalogo', controller.obtenerCatalogo);

// GET /api/caracterizacion/personas/:documento  (autorrelleno + borrador existente, HU-02/HU-05)
router.get(
    '/personas/:documento',
    validate(buscarPersonaSchema),
    controller.buscarPersona
);

// GET /api/caracterizacion/hogares/:documento  (a quién se vincularía por "ya hay alguien de mi hogar registrado", capítulo B/C del instrumento de 342 preguntas)
router.get(
    '/hogares/:documento',
    validate(buscarPersonaSchema),
    controller.buscarHogar
);

// POST /api/caracterizacion  (guarda persona + respuestas; borrador o completo)
router.post(
    '/',
    validate(guardarCaracterizacionSchema),
    controller.guardarCaracterizacion
);

module.exports = router;
