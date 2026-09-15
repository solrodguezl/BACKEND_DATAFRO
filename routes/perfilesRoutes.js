const express = require('express');

const router = express.Router();

const {
    obtenerMiPerfil,
    actualizarMiPerfil,
} = require('../controllers/perfilesController');

const {
    authenticate,
} = require('../middleware/authMiddleware');

const validate =
    require('../middleware/validateMiddleware');

const {
    actualizarPerfilSchema,
} = require('../validators/perfilesValidator');

router.get(
    '/me',
    authenticate,
    obtenerMiPerfil
);

router.put(
    '/me',
    authenticate,
    validate(actualizarPerfilSchema),
    actualizarMiPerfil
);

module.exports = router;