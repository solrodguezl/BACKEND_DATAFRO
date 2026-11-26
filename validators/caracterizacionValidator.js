const { z } = require('zod');
const { ETNIAS, GENEROS } = require('../utils/catalogos');

// Acepta "1.033.456.789" o "1 033 456 789" y lo guarda solo con dígitos/letras
// (igual que en el módulo de asistencia, para que ambos formularios compartan
// la misma llave natural de persona — HU-05/RNF-20).
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

const idParams = z.object({ documento: documentoNormalizado });

const buscarPersonaSchema = z.object({
    body: z.object({}).optional(),
    params: idParams,
    query: z.object({}),
});

const respuestaSchema = z.object({
    idPregunta: z.uuid('Identificador de pregunta inválido'),
    idOpcion: z.uuid('Identificador de opción inválido').nullable().optional(),
    valorRespuesta: z.string().trim().max(2000).nullable().optional(),
});

// Capítulos B/C del instrumento de 342 preguntas: vivienda y hogar se
// diligencian una sola vez y se comparten entre las personas que conviven.
// `documentoHogar` es opcional: el documento de alguien del mismo hogar que
// ya se haya registrado, para vincularse a su vivienda/hogar en vez de crear
// uno nuevo.
const viviendaSchema = z.object({
    direccion: z.string().trim().max(200).nullable().optional(),
    documentoHogar: documentoNormalizado.nullable().optional(),
});

const guardarCaracterizacionSchema = z.object({
    body: z.object({
        documento: documentoNormalizado,
        nombres: z.string().trim().min(1, 'Los nombres son obligatorios').max(150),
        tipoDocumento: z.string().trim().max(20).nullable().optional(),
        fechaNacimiento: z
            .string()
            .regex(/^\d{4}-\d{2}-\d{2}$/, 'La fecha debe tener el formato AAAA-MM-DD')
            .nullable()
            .optional(),
        edad: z
            .number({ message: 'La edad debe ser un número' })
            .int('La edad debe ser un número entero')
            .min(0, 'La edad no es válida')
            .max(120, 'La edad no es válida')
            .nullable()
            .optional(),
        genero: z.enum(GENEROS, { message: 'Género inválido' }).nullable().optional(),
        etnia: z.enum(ETNIAS, { message: 'Etnia inválida' }).nullable().optional(),
        barrio: z.string().trim().min(1, 'El barrio es obligatorio').max(100),
        estado: z.enum(['borrador', 'completo'], { message: 'Estado inválido' }),
        // El instrumento de 342 preguntas se guarda por capítulo (nunca se
        // manda todo junto), pero se deja margen amplio sobre el máximo de
        // ~42 preguntas del capítulo más largo.
        respuestas: z.array(respuestaSchema).max(200),
        vivienda: viviendaSchema.nullable().optional(),
    }),
    params: z.object({}),
    query: z.object({}),
});

module.exports = {
    buscarPersonaSchema,
    guardarCaracterizacionSchema,
};
