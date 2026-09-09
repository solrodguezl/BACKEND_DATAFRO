const express = require('express');

const router = express.Router();

const {
    login,
    refresh,
    logout,
} = require('../controllers/authController');

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

module.exports = router;