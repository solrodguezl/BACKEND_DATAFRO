const { z } = require('zod');

const idParamSchema = z.object({
    id: z.coerce.number().int().positive(),
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
        activo: z.boolean(),
    }),

    params: idParamSchema,

    query: z.object({}),
});

const obtenerUsuarioSchema = z.object({
    body: z.object({}),

    params: idParamSchema,

    query: z.object({}),
});

const eliminarUsuarioSchema = z.object({
    body: z.object({}),

    params: idParamSchema,

    query: z.object({}),
});

module.exports = {
    crearUsuarioSchema,
    actualizarUsuarioSchema,
    obtenerUsuarioSchema,
    eliminarUsuarioSchema,
};