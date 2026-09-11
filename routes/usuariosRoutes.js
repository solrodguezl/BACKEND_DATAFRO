const express = require('express');

const router = express.Router();

const {
    crearUsuario,
    obtenerUsuarios,
    obtenerUsuario,
    actualizarUsuario,
    eliminarUsuario,
} = require('../controllers/usuariosController');

const validate =
    require('../middleware/validateMiddleware');

const {
    authenticate,
} = require('../middleware/authMiddleware');

const {
    crearUsuarioSchema,
    actualizarUsuarioSchema,
    obtenerUsuarioSchema,
    eliminarUsuarioSchema,
} = require('../validators/usuariosValidator');

router.post(
    '/',
    validate(crearUsuarioSchema),
    
    crearUsuario
);

router.get(
    '/',
    authenticate,
    obtenerUsuarios
);

router.get(
    '/:id',
    authenticate,
    validate(obtenerUsuarioSchema),
    obtenerUsuario
);

router.put(
    '/:id',
    authenticate,
    validate(actualizarUsuarioSchema),
    actualizarUsuario
);

router.delete(
    '/:id',
    authenticate,
    validate(eliminarUsuarioSchema),
    eliminarUsuario
);

module.exports = router;