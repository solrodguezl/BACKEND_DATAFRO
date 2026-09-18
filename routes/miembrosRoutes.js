const express = require('express');

const router = express.Router();

const controller = require('../controllers/miembrosController');
const { authenticate } = require('../middleware/authMiddleware');
const {
    cargarMembresia,
    requerirRol,
} = require('../middleware/membresiaMiddleware');
const validate = require('../middleware/validateMiddleware');
const {
    crearMiembroSchema,
    actualizarMiembroSchema,
} = require('../validators/miembrosValidator');

router.use(authenticate, cargarMembresia);

router.get('/yo', controller.yo);
router.get('/', controller.listar);

// Solo el Director administra los miembros de su organización (HU-03).
router.post(
    '/',
    requerirRol('DIRECTOR'),
    validate(crearMiembroSchema),
    controller.crear
);

router.put(
    '/:id',
    requerirRol('DIRECTOR'),
    validate(actualizarMiembroSchema),
    controller.actualizar
);

module.exports = router;
