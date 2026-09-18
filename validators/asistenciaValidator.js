const { z } = require('zod');
const { ETNIAS, GENEROS } = require('../utils/catalogos');

// Acepta "1.033.456.789" o "1 033 456 789" y lo guarda solo con dígitos/letras.
const documentoNormalizado = z
    .string()
    .trim()
    .transform((valor) => valor.replace(/[.\s,-]/g, ''))
    .pipe(
        z
            .string()
            .min(5, 'El documento debe tener al menos 5 caracteres')
            .max(20, 'El documento no puede tener más de 20 caracteres')
    );

const idParams = z.object({ id: z.uuid('Identificador inválido') });

const buscarPersonaSchema = z.object({
    body: z.object({}).optional(),
    params: z.object({ documento: documentoNormalizado }),
    query: z.object({}),
});

const crearActividadSchema = z.object({
    body: z.object({
        nombre: z.string().trim().min(3, 'El nombre debe tener al menos 3 caracteres').max(150),
        fecha: z
            .string()
            .regex(/^\d{4}-\d{2}-\d{2}$/, 'La fecha debe tener el formato AAAA-MM-DD')
            .optional(),
        barrio: z.string().trim().max(100).nullable().optional(),
    }),
    params: z.object({}),
    query: z.object({}),
});

const obtenerActividadSchema = z.object({
    body: z.object({}).optional(),
    params: idParams,
    query: z.object({}),
});

const registrarAsistenciaSchema = z.object({
    body: z.object({
        documento: documentoNormalizado,
        nombres: z.string().trim().min(1, 'Los nombres son obligatorios').max(150),
        etnia: z.enum(ETNIAS, { message: 'Etnia inválida' }),
        edad: z
            .number({ message: 'La edad debe ser un número' })
            .int('La edad debe ser un número entero')
            .min(0, 'La edad no es válida')
            .max(120, 'La edad no es válida'),
        genero: z.enum(GENEROS, { message: 'Género inválido' }),
        barrio: z.string().trim().min(1, 'El barrio es obligatorio').max(100),
    }),
    params: idParams,
    query: z.object({}),
});

module.exports = {
    buscarPersonaSchema,
    crearActividadSchema,
    obtenerActividadSchema,
    registrarAsistenciaSchema,
};
