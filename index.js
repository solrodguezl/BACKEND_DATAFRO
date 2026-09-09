require('dotenv').config();

const app = require('./app');

const PORT = Number(
    process.env.PORT || 3000
);

const server = app.listen(
    PORT,
    () => {
        console.log(
            `Servidor escuchando en el puerto ${PORT}`
        );
    }
);

const shutdown = async (signal) => {
    console.log(
        `${signal} recibido. Cerrando servidor...`
    );

    server.close(() => {
        console.log(
            'Servidor HTTP cerrado.'
        );

        process.exit(0);
    });
};

process.on(
    'SIGTERM',
    () => shutdown('SIGTERM')
);

process.on(
    'SIGINT',
    () => shutdown('SIGINT')
);