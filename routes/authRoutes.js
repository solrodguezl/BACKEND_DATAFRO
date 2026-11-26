const express = require('express');

const router = express.Router();

const {
    login,
    refresh,
    logout,
    me,
} = require('../controllers/authController');

const { authenticate } = require('../middleware/authMiddleware');
const { cargarSesion } = require('../middleware/membresiaMiddleware');

const validate =
    require('../middleware/validateMiddleware');

const {
    loginSchema,
    refreshSchema,
} = require('../validators/authValidator');

router.post(
    '/login',
    validate(loginSchema),
    login
);

router.post(
    '/refresh',
    validate(refreshSchema),
    refresh
);

router.post(
    '/logout',
    validate(refreshSchema),
    logout
);

router.get(
    '/me',
    authenticate,
    cargarSesion,
    me
);

module.exports = router;