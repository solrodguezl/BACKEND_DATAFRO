const express = require('express');

const controller = require('../controllers/asistenciaController');
const { authenticate } = require('../middleware/authMiddleware');
const { cargarMembresia } = require('../middleware/membresiaMiddleware');
const validate = require('../middleware/validateMiddleware');
const {
    buscarPersonaSchema,
    crearActividadSchema,
    obtenerActividadSchema,
    registrarAsistenciaSchema,
} = require('../validators/asistenciaValidator');

// GET /api/personas/:documento  (autorrelleno, HU-05)
const personasRouter = express.Router();

personasRouter.use(authenticate, cargarMembresia);
personasRouter.get(
    '/:documento',
    validate(buscarPersonaSchema),
    controller.buscarPersona
);

// /api/actividades  (HU-01)
const actividadesRouter = express.Router();

actividadesRouter.use(authenticate, cargarMembresia);
actividadesRouter.get('/', controller.listarActividades);
actividadesRouter.post('/', validate(crearActividadSchema), controller.crearActividad);
actividadesRouter.get('/:id', validate(obtenerActividadSchema), controller.obtenerActividad);
actividadesRouter.post(
    '/:id/asistencias',
    validate(registrarAsistenciaSchema),
    controller.registrarAsistencia
);

module.exports = { personasRouter, actividadesRouter };
