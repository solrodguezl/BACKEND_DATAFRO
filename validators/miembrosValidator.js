const { z } = require('zod');
const { ROLES } = require('../utils/catalogos');

const idParams = z.object({ id: z.uuid('Identificador inválido') });

const crearMiembroSchema = z.object({
    body: z.object({
        documento: z
            .string()
            .trim()
            .min(8, 'El documento debe tener al menos 8 caracteres')
            .max(20, 'El documento no puede tener más de 20 caracteres'),
        clave: z
            .string()
            .min(8, 'La contraseña debe tener al menos 8 caracteres')
            .max(72),
        nombres: z.string().trim().min(1, 'Los nombres son obligatorios').max(100),
        apellidos: z.string().trim().min(1, 'Los apellidos son obligatorios').max(100),
        telefono: z.string().trim().max(20).nullable().optional(),
        rol: z.enum(ROLES, { message: 'Rol inválido' }),
    }),
    params: z.object({}),
    query: z.object({}),
});

const actualizarMiembroSchema = z.object({
    body: z.object({
        nombres: z.string().trim().min(1).max(100),
        apellidos: z.string().trim().min(1).max(100),
        telefono: z.string().trim().max(20).nullable().optional(),
        rol: z.enum(ROLES, { message: 'Rol inválido' }),
        activo: z.boolean().optional(),
        // Si el Director la envía, restablece la contraseña del miembro.
        clave: z.string().min(8, 'La contraseña debe tener al menos 8 caracteres').max(72).optional(),
    }),
    params: idParams,
    query: z.object({}),
});

module.exports = { crearMiembroSchema, actualizarMiembroSchema };
