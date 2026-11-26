const express = require('express');

const controller = require('../controllers/solicitudesRolController');
const { authenticate } = require('../middleware/authMiddleware');
const {
    cargarSesion,
    requerirPermiso,
} = require('../middleware/membresiaMiddleware');
const validate = require('../middleware/validateMiddleware');
const {
    crearSolicitudSchema,
    listarAdminSchema,
    revisarSolicitudSchema,
} = require('../validators/solicitudesRolValidator');

// /api/solicitudes-rol — cualquier usuario autenticado (con o sin organización).
const solicitudesRouter = express.Router();

solicitudesRouter.use(authenticate, cargarSesion);

solicitudesRouter.post(
    '/',
    requerirPermiso('solicitud_rol.crear'),
    validate(crearSolicitudSchema),
    controller.crear
);

solicitudesRouter.get('/mias', controller.misSolicitudes);

// /api/admin/solicitudes-rol — solo ADMIN (Administrador investigativo).
const adminRouter = express.Router();

adminRouter.use(authenticate, cargarSesion, requerirPermiso('solicitud_rol.revisar'));

adminRouter.get('/', validate(listarAdminSchema), controller.listarAdmin);
adminRouter.post(
    '/:id/aprobar',
    validate(revisarSolicitudSchema),
    controller.aprobar
);
adminRouter.post(
    '/:id/rechazar',
    validate(revisarSolicitudSchema),
    controller.rechazar
);

module.exports = { solicitudesRouter, adminRouter };
