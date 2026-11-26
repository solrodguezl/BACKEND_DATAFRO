const { z } = require('zod');
const {
    crearMiembroSchema,
    actualizarMiembroSchema,
} = require('./miembrosValidator');

const idParamSchema = z.object({
    body: z.object({}).passthrough().optional(),
    params: z.object({
        id: z.string().uuid('Identificador de organización inválido'),
    }),
    query: z.object({}).passthrough().optional(),
});

// Mismo cuerpo que crear/actualizar miembro (reutiliza las reglas de
// validators/miembrosValidator.js), pero con la organización en la URL en
// vez de tomarla de la membresía de quien llama (acá siempre es el admin).
const crearMiembroAdminSchema = z.object({
    body: crearMiembroSchema.shape.body,
    params: z.object({
        id: z.string().uuid('Identificador de organización inválido'),
    }),
    query: z.object({}),
});

const actualizarMiembroAdminSchema = z.object({
    body: actualizarMiembroSchema.shape.body,
    params: z.object({
        id: z.string().uuid('Identificador de organización inválido'),
        idUsuario: z.string().uuid('Identificador de usuario inválido'),
    }),
    query: z.object({}),
});

const resumenMiembroAdminSchema = z.object({
    body: z.object({}).optional(),
    params: z.object({
        id: z.string().uuid('Identificador de organización inválido'),
        idUsuario: z.string().uuid('Identificador de usuario inválido'),
    }),
    query: z.object({}),
});

module.exports = {
    idParamSchema,
    crearMiembroAdminSchema,
    actualizarMiembroAdminSchema,
    resumenMiembroAdminSchema,
};
