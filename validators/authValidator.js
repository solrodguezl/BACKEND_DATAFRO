const { z } = require('zod');

const loginSchema = z.object({
    body: z.object({
        correo: z
            .string()
            .trim()
            .email('El correo no es válido'),

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