const express = require('express');
const cors = require('cors');

const errorMiddleware =
    require('./middleware/errorMiddleware');

const authRoutes =
    require('./routes/authRoutes');

    const perfilesRoutes =
    require('./routes/perfilesRoutes');
const usuariosRoutes =
    require('./routes/usuariosRoutes');
const miembrosRoutes =
    require('./routes/miembrosRoutes');
const catalogosRoutes =
    require('./routes/catalogosRoutes');
const {
    personasRouter,
    actividadesRouter,
} = require('./routes/asistenciaRoutes');

const app = express();

// Detrás del proxy de Render/Neon-hosting, req.ip debe ser la IP real del cliente.
app.set('trust proxy', 1);

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
    '/api/perfiles',
    perfilesRoutes
);

app.use(
    '/api/usuarios',
    usuariosRoutes
);

app.use('/api/miembros', miembrosRoutes);
app.use('/api/catalogos', catalogosRoutes);
app.use('/api/personas', personasRouter);
app.use('/api/actividades', actividadesRouter);

// Error handler
app.use(errorMiddleware);

module.exports = app;