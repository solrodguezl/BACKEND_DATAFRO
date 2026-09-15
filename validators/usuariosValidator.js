const { z } = require('zod');

const uuidSchema = z.string().uuid();

const idParamSchema = z.object({
    id: uuidSchema,
});

const crearUsuarioSchema = z.object({
    
    body: z.object({
        documento: z
            .string()
            .trim()
            .min(8, 'El documento debe tener al menos 8 caracteres'),

        clave: z
            .string()
            .min(8, 'La contraseña debe tener al menos 8 caracteres'),
    }),

    params: z.object({}),

    query: z.object({}),
});

const actualizarUsuarioSchema = z.object({
    body: z.object({
        id: uuidSchema.optional(),
        activo: z.boolean(),
    }).passthrough(),

    params: z.object({
        id: uuidSchema.optional(),
    }).passthrough(),

    query: z.object({}),
});

const obtenerUsuarioSchema = z.object({
    body: z.object({}).passthrough().optional(),

    params: idParamSchema,

    query: z.object({}).passthrough().optional(),
});

const eliminarUsuarioSchema = z.object({
    body: z.object({}).passthrough().optional(),

    params: idParamSchema,

    query: z.object({}).passthrough().optional(),
});

module.exports = {
    crearUsuarioSchema,
    actualizarUsuarioSchema,
    obtenerUsuarioSchema,
    eliminarUsuarioSchema,
};