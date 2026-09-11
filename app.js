const express = require('express');
const cors = require('cors');

const errorMiddleware =
    require('./middleware/errorMiddleware');

const authRoutes =
    require('./routes/authRoutes');
const usuariosRoutes =
    require('./routes/usuariosRoutes');

const app = express();

app.use(
    cors()
);

app.use(
    express.json({
        limit: '1mb',
    })
);

// Health check
app.get('/health', (req, res) => {
    res.json({
        status: 'ok',
    });
});

// API
app.use(
    '/api/auth',
    authRoutes
);

app.use(
    '/api/usuarios',
    usuariosRoutes
);

// Error handler
app.use(errorMiddleware);

module.exports = app;