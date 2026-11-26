const express = require('express');

const router = express.Router();

const controller = require('../controllers/organizacionesController');
const { authenticate } = require('../middleware/authMiddleware');
const {
    cargarSesion,
    requerirNivel,
} = require('../middleware/membresiaMiddleware');
const { NIVEL_ADMIN } = require('../utils/catalogos');
const validate = require('../middleware/validateMiddleware');
const {
    idParamSchema,
    crearMiembroAdminSchema,
    actualizarMiembroAdminSchema,
    resumenMiembroAdminSchema,
} = require('../validators/organizacionesValidator');

// Panel exclusivo del Administrador investigativo: historial de todas las
// organizaciones registradas y, por cada una, sus miembros — con permiso
// para activar/desactivar, cambiar rol, restablecer contraseña y crear
// perfiles nuevos en cualquier organización (HU-03), sujeto a la misma
// jerarquía de roles que usan DIRECTOR/COORDINADOR en su propia organización.
router.use(authenticate, cargarSesion, requerirNivel(NIVEL_ADMIN));

router.get('/', controller.listar);
router.get('/:id/miembros', validate(idParamSchema), controller.miembros);

router.post(
    '/:id/miembros',
    validate(crearMiembroAdminSchema),
    controller.crearMiembro
);

router.put(
    '/:id/miembros/:idUsuario',
    validate(actualizarMiembroAdminSchema),
    controller.actualizarMiembro
);

router.get(
    '/:id/miembros/:idUsuario/resumen',
    validate(resumenMiembroAdminSchema),
    controller.resumenMiembro
);

module.exports = router;
