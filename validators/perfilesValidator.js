const { z } = require('zod');

const actualizarPerfilSchema = z.object({
    body: z.object({
        nombres: z.string().trim().min(1).max(100),
        apellidos: z.string().trim().min(1).max(100),
        telefono: z.string().trim().max(20).nullable().optional(),
        foto_perfil: z.string().trim().max(500).nullable().optional(),
    }),

    params: z.object({}),

    query: z.object({}),
});

module.exports = {
    actualizarPerfilSchema,
};