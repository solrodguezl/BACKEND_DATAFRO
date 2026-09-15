const { z } = require('zod');

const loginSchema = z.object({
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

const refreshSchema = z.object({
    body: z.object({
        refreshToken: z
            .string()
            .min(1, 'El refresh token es obligatorio'),
    }),

    params: z.object({}),

    query: z.object({}),
});

module.exports = {
    loginSchema,
    refreshSchema,
};