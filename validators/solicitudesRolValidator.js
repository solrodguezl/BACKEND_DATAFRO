const { z } = require('zod');

const idParams = z.object({ id: z.uuid('Identificador inválido') });

const crearSolicitudSchema = z.object({
    body: z.object({
        rolSolicitado: z.enum(['COORDINADOR', 'DIRECTOR'], {
            message: 'El rol solicitado debe ser COORDINADOR o DIRECTOR',
        }),
        organizacionNombre: z
            .string()
            .trim()
            .min(2, 'El nombre de la organización es obligatorio')
            .max(150),
        nit: z.string().trim().max(20).nullable().optional(),
        celular: z.string().trim().max(20).nullable().optional(),
        cargo: z.string().trim().max(100).nullable().optional(),
        motivo: z.string().trim().max(1000).nullable().optional(),
    }),
    params: z.object({}),
    query: z.object({}),
});

const listarAdminSchema = z.object({
    body: z.object({}).optional(),
    params: z.object({}),
    query: z.object({
        estado: z.enum(['pendiente', 'aprobada', 'rechazada']).optional(),
    }),
});

const revisarSolicitudSchema = z.object({
    body: z.object({
        comentario: z.string().trim().max(500).nullable().optional(),
    }),
    params: idParams,
    query: z.object({}),
});

module.exports = {
    crearSolicitudSchema,
    listarAdminSchema,
    revisarSolicitudSchema,
};
