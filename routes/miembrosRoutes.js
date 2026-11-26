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

// Ver los miembros de la organización: DIRECTOR o COORDINADOR (HU-03).
router.get('/', requerirRol('DIRECTOR', 'COORDINADOR'), controller.listar);

// DIRECTOR y COORDINADOR administran perfiles de su organización (HU-03),
// pero solo con un rol de nivel menor al propio (lo valida el servicio):
// DIRECTOR crea/edita COORDINADOR o GESTOR; COORDINADOR solo GESTOR.
router.post(
    '/',
    requerirRol('DIRECTOR', 'COORDINADOR'),
    validate(crearMiembroSchema),
    controller.crear
);

router.put(
    '/:id',
    requerirRol('DIRECTOR', 'COORDINADOR'),
    validate(actualizarMiembroSchema),
    controller.actualizar
);

// Resumen de actividad de un miembro (asistencias registradas, actividades
// creadas, promedio de asistentes, última actividad) para el panel de perfil.
router.get(
    '/:id/resumen',
    requerirRol('DIRECTOR', 'COORDINADOR'),
    controller.resumen
);

module.exports = router;
