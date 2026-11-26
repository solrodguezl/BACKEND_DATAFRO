-- =========================================================================
-- FASE: Instrumento completo de caracterización NARP/DSS (342 preguntas, 14
-- capítulos + consentimiento, alineado a la metodología de la ECV del DANE).
-- Generado automáticamente a partir de Formulario_Caracterizacion_NARP_DSS.docx
-- Para que la usuaria lo corra en pgAdmin. Idempotente: no borra datos ni el
-- catálogo anterior de 49 preguntas (queda intacto, solo deja de usarse desde
-- la nueva pantalla). BEGIN/COMMIT, ADD COLUMN IF NOT EXISTS, ON CONFLICT.
-- =========================================================================

BEGIN;
ALTER TABLE public.categoria_dss ALTER COLUMN nombre TYPE varchar(150);
ALTER TABLE public.opcion_respuesta ALTER COLUMN valor TYPE varchar(150);

-- 1) Metadatos de capítulo en categoria_dss ---------------------------------
ALTER TABLE public.categoria_dss ADD COLUMN IF NOT EXISTS capitulo varchar(4);
ALTER TABLE public.categoria_dss ADD COLUMN IF NOT EXISTS orden_capitulo integer;
ALTER TABLE public.categoria_dss ADD COLUMN IF NOT EXISTS nivel varchar(10);
ALTER TABLE public.categoria_dss ADD COLUMN IF NOT EXISTS objetivo text;
ALTER TABLE public.categoria_dss ADD COLUMN IF NOT EXISTS responde text;
ALTER TABLE public.categoria_dss ADD COLUMN IF NOT EXISTS tiempo_estimado_min integer;
ALTER TABLE public.categoria_dss ADD COLUMN IF NOT EXISTS elegibilidad_edad_min smallint;
ALTER TABLE public.categoria_dss ADD COLUMN IF NOT EXISTS elegibilidad_edad_max smallint;
ALTER TABLE public.categoria_dss ADD COLUMN IF NOT EXISTS elegibilidad_genero varchar(30);
ALTER TABLE public.categoria_dss ADD COLUMN IF NOT EXISTS elegibilidad_jefe_hogar boolean NOT NULL DEFAULT false;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'categoria_dss_nivel_check') THEN
        ALTER TABLE public.categoria_dss ADD CONSTRAINT categoria_dss_nivel_check
            CHECK (nivel IS NULL OR nivel IN ('VIVIENDA','HOGAR','PERSONA'));
    END IF;
END $$;

-- 2) Metadatos de pregunta y condicionales en pregunta_dss ------------------
ALTER TABLE public.pregunta_dss ADD COLUMN IF NOT EXISTS numero_pregunta integer;
ALTER TABLE public.pregunta_dss ADD COLUMN IF NOT EXISTS nota text;
ALTER TABLE public.pregunta_dss ADD COLUMN IF NOT EXISTS unidad varchar(20);
ALTER TABLE public.pregunta_dss ADD COLUMN IF NOT EXISTS escala_min smallint;
ALTER TABLE public.pregunta_dss ADD COLUMN IF NOT EXISTS escala_max smallint;
ALTER TABLE public.pregunta_dss ADD COLUMN IF NOT EXISTS condicion_pregunta_id uuid;
ALTER TABLE public.pregunta_dss ADD COLUMN IF NOT EXISTS condicion_operador varchar(10);
ALTER TABLE public.pregunta_dss ADD COLUMN IF NOT EXISTS condicion_valor text;
ALTER TABLE public.pregunta_dss ADD COLUMN IF NOT EXISTS condicion_edad_operador varchar(10);
ALTER TABLE public.pregunta_dss ADD COLUMN IF NOT EXISTS condicion_edad_valor smallint;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'pregunta_dss_numero_uidx') THEN
        ALTER TABLE public.pregunta_dss ADD CONSTRAINT pregunta_dss_numero_uidx UNIQUE (numero_pregunta);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'pregunta_dss_condicion_fkey') THEN
        ALTER TABLE public.pregunta_dss ADD CONSTRAINT pregunta_dss_condicion_fkey
            FOREIGN KEY (condicion_pregunta_id) REFERENCES public.pregunta_dss (id_pregunta);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'pregunta_dss_condicion_operador_check') THEN
        ALTER TABLE public.pregunta_dss ADD CONSTRAINT pregunta_dss_condicion_operador_check
            CHECK (condicion_operador IS NULL OR condicion_operador IN ('EQ','NEQ','GT0','IN'));
    END IF;
END $$;

-- 3) Vivienda y hogar como entidades propias (se diligencian una sola vez y
--    se reutilizan entre las personas que comparten vivienda/hogar) ---------
CREATE TABLE IF NOT EXISTS public.vivienda (
    id_vivienda uuid NOT NULL DEFAULT uuid_generate_v4(),
    id_organizacion uuid NOT NULL,
    id_barrio uuid,
    direccion text,
    fecha_registro timestamp NOT NULL DEFAULT now(),
    CONSTRAINT vivienda_pkey PRIMARY KEY (id_vivienda),
    CONSTRAINT vivienda_id_organizacion_fkey FOREIGN KEY (id_organizacion) REFERENCES public.organizacion (id_organizacion),
    CONSTRAINT vivienda_id_barrio_fkey FOREIGN KEY (id_barrio) REFERENCES public.barrio (id_barrio)
);
CREATE TABLE IF NOT EXISTS public.hogar (
    id_hogar uuid NOT NULL DEFAULT uuid_generate_v4(),
    id_vivienda uuid NOT NULL,
    fecha_registro timestamp NOT NULL DEFAULT now(),
    CONSTRAINT hogar_pkey PRIMARY KEY (id_hogar),
    CONSTRAINT hogar_id_vivienda_fkey FOREIGN KEY (id_vivienda) REFERENCES public.vivienda (id_vivienda)
);
ALTER TABLE public.persona ADD COLUMN IF NOT EXISTS id_hogar uuid NULL;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'persona_id_hogar_fkey') THEN
        ALTER TABLE public.persona ADD CONSTRAINT persona_id_hogar_fkey FOREIGN KEY (id_hogar) REFERENCES public.hogar (id_hogar);
    END IF;
END $$;
ALTER TABLE public.formulario_dss ADD COLUMN IF NOT EXISTS id_vivienda uuid NULL;
ALTER TABLE public.formulario_dss ADD COLUMN IF NOT EXISTS id_hogar uuid NULL;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'formulario_dss_id_vivienda_fkey') THEN
        ALTER TABLE public.formulario_dss ADD CONSTRAINT formulario_dss_id_vivienda_fkey FOREIGN KEY (id_vivienda) REFERENCES public.vivienda (id_vivienda);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'formulario_dss_id_hogar_fkey') THEN
        ALTER TABLE public.formulario_dss ADD CONSTRAINT formulario_dss_id_hogar_fkey FOREIGN KEY (id_hogar) REFERENCES public.hogar (id_hogar);
    END IF;
END $$;

-- 4) Catálogo completo: 14 capítulos, 342 preguntas -------------------------

-- ---- Capítulo A: Identificación y control ----
INSERT INTO public.categoria_dss (
    nombre, orden, capitulo, orden_capitulo, nivel, objetivo, responde,
    tiempo_estimado_min, elegibilidad_edad_min, elegibilidad_edad_max,
    elegibilidad_genero, elegibilidad_jefe_hogar
) VALUES (
    'NARP-342 · A. Identificación y control', 101, 'A', 1,
    'PERSONA', 'Identificar con claridad a la persona, la ubicación de su vivienda y hogar, y controlar la calidad del registro.', 'Todas las personas',
    8, NULL, NULL,
    NULL, FALSE
) ON CONFLICT (nombre) DO UPDATE SET
    orden = EXCLUDED.orden, capitulo = EXCLUDED.capitulo,
    orden_capitulo = EXCLUDED.orden_capitulo, nivel = EXCLUDED.nivel,
    objetivo = EXCLUDED.objetivo, responde = EXCLUDED.responde,
    tiempo_estimado_min = EXCLUDED.tiempo_estimado_min,
    elegibilidad_edad_min = EXCLUDED.elegibilidad_edad_min,
    elegibilidad_edad_max = EXCLUDED.elegibilidad_edad_max,
    elegibilidad_genero = EXCLUDED.elegibilidad_genero,
    elegibilidad_jefe_hogar = EXCLUDED.elegibilidad_jefe_hogar;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Nombre completo', 'texto', 1, 1,
    'Escríbalo tal como aparece en su documento de identidad.', NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · A. Identificación y control'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Tipo de documento de identidad', 'seleccion_unica', 2, 2,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · A. Identificación y control'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('RC – Registro civil', 'RC – Registro civil', 1), ('TI – Tarjeta de identidad', 'TI – Tarjeta de identidad', 2), ('CC – Cédula de ciudadanía', 'CC – Cédula de ciudadanía', 3), ('PP – Pasaporte', 'PP – Pasaporte', 4), ('CE – Cédula de extranjería', 'CE – Cédula de extranjería', 5), ('PPT – Permiso de Protección Temporal', 'PPT – Permiso de Protección Temporal', 6), ('Otro. ¿Cuál? ________', 'Otro. ¿Cuál? ________', 7)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 2
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Número de documento de identidad', 'texto', 3, 3,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · A. Identificación y control'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Fecha de nacimiento', 'fecha', 4, 4,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · A. Identificación y control'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Edad en años cumplidos', 'numero', 5, 5,
    'La aplicación puede calcularla a partir de la fecha de nacimiento.', NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · A. Identificación y control'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Municipio y departamento de nacimiento', 'texto', 6, 6,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · A. Identificación y control'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'País de nacimiento', 'seleccion_unica', 7, 7,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · A. Identificación y control'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Colombia', 'Colombia', 1), ('Venezuela', 'Venezuela', 2), ('Otro. ¿Cuál? ________', 'Otro. ¿Cuál? ________', 3)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 7
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Número de teléfono celular', 'numero', 8, 8,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · A. Identificación y control'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Número de teléfono alternativo (familiar o vecino)', 'numero', 9, 9,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · A. Identificación y control'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Correo electrónico', 'texto', 10, 10,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · A. Identificación y control'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Dirección de la vivienda', 'texto', 11, 11,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · A. Identificación y control'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Barrio', 'seleccion_unica', 12, 12,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · A. Identificación y control'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('El Pesebre', 'El Pesebre', 1), ('Blanquizal', 'Blanquizal', 2), ('Santa Rosa de Lima', 'Santa Rosa de Lima', 3), ('Los Alcázares', 'Los Alcázares', 4), ('Metropolitano', 'Metropolitano', 5), ('La Pradera', 'La Pradera', 6), ('Juan XXIII La Quiebra', 'Juan XXIII La Quiebra', 7), ('San Javier N.° 1', 'San Javier N.° 1', 8), ('San Javier N.° 2', 'San Javier N.° 2', 9), ('Veinte de Julio', 'Veinte de Julio', 10), ('Belencito', 'Belencito', 11), ('Betania', 'Betania', 12), ('El Corazón', 'El Corazón', 13), ('Las Independencias', 'Las Independencias', 14), ('Nuevos Conquistadores', 'Nuevos Conquistadores', 15), ('El Salado', 'El Salado', 16), ('Eduardo Santos', 'Eduardo Santos', 17), ('Antonio Nariño', 'Antonio Nariño', 18), ('El Socorro', 'El Socorro', 19), ('Otro. ¿Cuál? ________', 'Otro. ¿Cuál? ________', 20)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 12
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Comuna', 'seleccion_unica', 13, 13,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · A. Identificación y control'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Comuna 13 – San Javier', 'Comuna 13 – San Javier', 1), ('Otra. ¿Cuál? ________', 'Otra. ¿Cuál? ________', 2)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 13
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Hace cuántos años vive en este barrio?', 'numero', 14, 14,
    'Si es menos de un año, escriba 0.', NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · A. Identificación y control'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Fecha de diligenciamiento', 'fecha', 15, 15,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · A. Identificación y control'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Nombre de quien diligencia o acompaña el registro', 'texto', 16, 16,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · A. Identificación y control'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Modalidad del registro', 'seleccion_unica', 17, 17,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · A. Identificación y control'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Presencial, con acompañamiento', 'Presencial, con acompañamiento', 1), ('Autodiligenciado en la aplicación', 'Autodiligenciado en la aplicación', 2), ('Telefónico', 'Telefónico', 3)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 17
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Quién responde la información del hogar?', 'seleccion_unica', 18, 18,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · A. Identificación y control'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('La misma persona registrada', 'La misma persona registrada', 1), ('Jefe(a) del hogar o cónyuge', 'Jefe(a) del hogar o cónyuge', 2), ('Otro miembro del hogar mayor de edad', 'Otro miembro del hogar mayor de edad', 3)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 18
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Estado del registro', 'seleccion_unica', 19, 19,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · A. Identificación y control'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Completo', 'Completo', 1), ('Incompleto – continuar luego', 'Incompleto – continuar luego', 2), ('Rechazado', 'Rechazado', 3)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 19
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Nombre completo del acudiente', 'texto', 20, 20,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · A. Identificación y control'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Tipo de documento del acudiente', 'seleccion_unica', 21, 21,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · A. Identificación y control'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('CC – Cédula de ciudadanía', 'CC – Cédula de ciudadanía', 1), ('PP – Pasaporte', 'PP – Pasaporte', 2), ('CE – Cédula de extranjería', 'CE – Cédula de extranjería', 3), ('PPT – Permiso de Protección Temporal', 'PPT – Permiso de Protección Temporal', 4), ('Otro. ¿Cuál? ________', 'Otro. ¿Cuál? ________', 5)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 21
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Número de documento del acudiente', 'texto', 22, 22,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · A. Identificación y control'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Parentesco o relación con el menor', 'seleccion_unica', 23, 23,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · A. Identificación y control'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Madre', 'Madre', 1), ('Padre', 'Padre', 2), ('Abuelo(a)', 'Abuelo(a)', 3), ('Tío(a)', 'Tío(a)', 4), ('Hermano(a) mayor', 'Hermano(a) mayor', 5), ('Otro. ¿Cuál? ________', 'Otro. ¿Cuál? ________', 6)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 23
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Autorización del acudiente', 'seleccion_unica', 24, 24,
    'Con el diligenciamiento de este formulario autorizo de forma voluntaria y expresa que la Mesa Afro registre mi información y la del menor del cual soy responsable, para que sea almacenada en su base de datos, y a su vez tome o capte imágenes, grabaciones y/o audios, consintiendo su difusión y su incorporación posterior en páginas web, folletos o informes, sin que por ello exista derecho a contraprestación alguna y sin plazo limitado para su utilización, todo ello sin perjuicio de mi derecho a revocar este consentimiento en cualquier momento.', NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · A. Identificación y control'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Autorizo', 'Autorizo', 1), ('No autorizo', 'No autorizo', 2)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 24
ON CONFLICT DO NOTHING;

-- ---- Capítulo B: Datos de la vivienda ----
INSERT INTO public.categoria_dss (
    nombre, orden, capitulo, orden_capitulo, nivel, objetivo, responde,
    tiempo_estimado_min, elegibilidad_edad_min, elegibilidad_edad_max,
    elegibilidad_genero, elegibilidad_jefe_hogar
) VALUES (
    'NARP-342 · B. Datos de la vivienda', 102, 'B', 2,
    'VIVIENDA', 'Captar las características físicas de la vivienda y los problemas por ubicación o afectación que haya sufrido en los últimos 2 años.', 'Una sola vez por vivienda (lo responde el jefe/a del hogar o una persona adulta)',
    5, NULL, NULL,
    NULL, FALSE
) ON CONFLICT (nombre) DO UPDATE SET
    orden = EXCLUDED.orden, capitulo = EXCLUDED.capitulo,
    orden_capitulo = EXCLUDED.orden_capitulo, nivel = EXCLUDED.nivel,
    objetivo = EXCLUDED.objetivo, responde = EXCLUDED.responde,
    tiempo_estimado_min = EXCLUDED.tiempo_estimado_min,
    elegibilidad_edad_min = EXCLUDED.elegibilidad_edad_min,
    elegibilidad_edad_max = EXCLUDED.elegibilidad_edad_max,
    elegibilidad_genero = EXCLUDED.elegibilidad_genero,
    elegibilidad_jefe_hogar = EXCLUDED.elegibilidad_jefe_hogar;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Tipo de vivienda', 'seleccion_unica', 1, 25,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · B. Datos de la vivienda'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Casa', 'Casa', 1), ('Apartamento', 'Apartamento', 2), ('Cuarto(s) en inquilinato', 'Cuarto(s) en inquilinato', 3), ('Cuarto(s) en otro tipo de estructura', 'Cuarto(s) en otro tipo de estructura', 4), ('Vivienda indígena o tradicional', 'Vivienda indígena o tradicional', 5), ('Otro (carpa, contenedor, vagón, refugio natural)', 'Otro (carpa, contenedor, vagón, refugio natural)', 6)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 25
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Material predominante de las paredes exteriores', 'seleccion_unica', 2, 26,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · B. Datos de la vivienda'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Bloque, ladrillo, piedra, madera pulida', 'Bloque, ladrillo, piedra, madera pulida', 1), ('Concreto vaciado', 'Concreto vaciado', 2), ('Material prefabricado', 'Material prefabricado', 3), ('Tapia pisada, bahareque, adobe', 'Tapia pisada, bahareque, adobe', 4), ('Madera burda, tabla, tablón', 'Madera burda, tabla, tablón', 5), ('Guadua, caña, esterilla u otro vegetal', 'Guadua, caña, esterilla u otro vegetal', 6), ('Zinc, tela, cartón, latas, desechos, plástico', 'Zinc, tela, cartón, latas, desechos, plástico', 7), ('Sin paredes', 'Sin paredes', 8)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 26
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Material predominante de los pisos', 'seleccion_unica', 3, 27,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · B. Datos de la vivienda'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Alfombra, mármol, parqué, madera pulida y lacada', 'Alfombra, mármol, parqué, madera pulida y lacada', 1), ('Baldosa, vinilo, tableta, ladrillo, laminado', 'Baldosa, vinilo, tableta, ladrillo, laminado', 2), ('Cemento, gravilla', 'Cemento, gravilla', 3), ('Madera burda, tabla, tablón, otro vegetal', 'Madera burda, tabla, tablón, otro vegetal', 4), ('Tierra, arena, barro', 'Tierra, arena, barro', 5)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 27
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Material predominante del techo o cubierta', 'seleccion_unica', 4, 28,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · B. Datos de la vivienda'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Plancha de concreto, cemento u hormigón', 'Plancha de concreto, cemento u hormigón', 1), ('Teja de barro, zinc o asbesto-cemento con cielo raso', 'Teja de barro, zinc o asbesto-cemento con cielo raso', 2), ('Teja de barro, zinc o asbesto-cemento sin cielo raso', 'Teja de barro, zinc o asbesto-cemento sin cielo raso', 3), ('Teja plástica', 'Teja plástica', 4), ('Paja, palma u otros vegetales', 'Paja, palma u otros vegetales', 5), ('Materiales de desecho (cartón, lata, plástico)', 'Materiales de desecho (cartón, lata, plástico)', 6)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 28
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Estrato socioeconómico (según la factura de energía)', 'seleccion_unica', 5, 29,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · B. Datos de la vivienda'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('1', '1', 1), ('2', '2', 2), ('3', '3', 3), ('4', '4', 4), ('5', '5', 5), ('6', '6', 6), ('Conexión pirata / sin estrato', 'Conexión pirata / sin estrato', 7), ('No sabe', 'No sabe', 8)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 29
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿La vivienda cuenta con servicio de energía eléctrica?', 'si_no', 6, 30,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · B. Datos de la vivienda'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'En el último mes, ¿con qué frecuencia se fue la energía?', 'seleccion_unica', 7, 31,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · B. Datos de la vivienda'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Nunca', 'Nunca', 1), ('Una o dos veces', 'Una o dos veces', 2), ('Varias veces', 'Varias veces', 3), ('Todos los días', 'Todos los días', 4)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 31
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿La vivienda cuenta con servicio de acueducto?', 'si_no', 8, 32,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · B. Datos de la vivienda'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿El agua del acueducto llega los 7 días de la semana?', 'si_no', 9, 33,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · B. Datos de la vivienda'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuántas horas al día llega el agua?', 'numero', 10, 34,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · B. Datos de la vivienda'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿La vivienda cuenta con servicio de alcantarillado?', 'si_no', 11, 35,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · B. Datos de la vivienda'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿La vivienda cuenta con gas natural conectado a red pública?', 'si_no', 12, 36,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · B. Datos de la vivienda'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿La vivienda cuenta con servicio de recolección de basuras?', 'si_no', 13, 37,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · B. Datos de la vivienda'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuántas veces a la semana recogen las basuras?', 'numero', 14, 38,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · B. Datos de la vivienda'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿La vivienda tiene conexión a internet fijo?', 'si_no', 15, 39,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · B. Datos de la vivienda'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Los servicios están conectados de forma legal (con medidor y factura)?', 'seleccion_unica', 16, 40,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · B. Datos de la vivienda'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Todos legales', 'Todos legales', 1), ('Algunos informales (contrabando)', 'Algunos informales (contrabando)', 2), ('Todos informales', 'Todos informales', 3), ('No sabe', 'No sabe', 4)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 40
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'En los últimos 2 años, ¿la vivienda ha sido afectada por inundaciones, crecientes o arroyos?', 'si_no', 17, 41,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · B. Datos de la vivienda'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'En los últimos 2 años, ¿la vivienda ha sido afectada por deslizamientos o avalanchas?', 'si_no', 18, 42,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · B. Datos de la vivienda'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'En los últimos 2 años, ¿la vivienda ha sido afectada por hundimientos del terreno o agrietamientos?', 'si_no', 19, 43,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · B. Datos de la vivienda'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'En los últimos 2 años, ¿la vivienda ha sido afectada por vendavales o vientos fuertes?', 'si_no', 20, 44,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · B. Datos de la vivienda'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'En los últimos 2 años, ¿la vivienda ha sido afectada por incendios?', 'si_no', 21, 45,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · B. Datos de la vivienda'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿La vivienda está en una zona declarada de alto riesgo por la Alcaldía?', 'seleccion_unica', 22, 46,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · B. Datos de la vivienda'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Sí', 'Sí', 1), ('No', 'No', 2), ('No sabe', 'No sabe', 3)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 46
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cerca de la vivienda hay problemas de ruido excesivo?', 'si_no', 23, 47,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · B. Datos de la vivienda'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cerca de la vivienda hay malos olores o aguas estancadas?', 'si_no', 24, 48,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · B. Datos de la vivienda'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cerca de la vivienda hay acumulación de basuras o escombros?', 'si_no', 25, 49,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · B. Datos de la vivienda'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cerca de la vivienda hay presencia de plagas (ratas, cucarachas, zancudos)?', 'si_no', 26, 50,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · B. Datos de la vivienda'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cerca de la vivienda hay contaminación del aire (humo, polvo)?', 'si_no', 27, 51,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · B. Datos de la vivienda'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿El acceso a la vivienda es por escalas, caminos sin pavimentar o pendientes peligrosas?', 'si_no', 28, 52,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · B. Datos de la vivienda'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;

-- ---- Capítulo C: Datos del hogar (hacinamiento y servicios) ----
INSERT INTO public.categoria_dss (
    nombre, orden, capitulo, orden_capitulo, nivel, objetivo, responde,
    tiempo_estimado_min, elegibilidad_edad_min, elegibilidad_edad_max,
    elegibilidad_genero, elegibilidad_jefe_hogar
) VALUES (
    'NARP-342 · C. Datos del hogar (hacinamiento y servicios)', 103, 'C', 3,
    'HOGAR', 'Identificar hacinamiento crítico, el pago y la calidad de los servicios con que cuenta el hogar.', 'Todos los hogares de la vivienda',
    9, NULL, NULL,
    NULL, FALSE
) ON CONFLICT (nombre) DO UPDATE SET
    orden = EXCLUDED.orden, capitulo = EXCLUDED.capitulo,
    orden_capitulo = EXCLUDED.orden_capitulo, nivel = EXCLUDED.nivel,
    objetivo = EXCLUDED.objetivo, responde = EXCLUDED.responde,
    tiempo_estimado_min = EXCLUDED.tiempo_estimado_min,
    elegibilidad_edad_min = EXCLUDED.elegibilidad_edad_min,
    elegibilidad_edad_max = EXCLUDED.elegibilidad_edad_max,
    elegibilidad_genero = EXCLUDED.elegibilidad_genero,
    elegibilidad_jefe_hogar = EXCLUDED.elegibilidad_jefe_hogar;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuántos hogares viven en esta vivienda (grupos que cocinan por separado)?', 'numero', 1, 53,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · C. Datos del hogar (hacinamiento y servicios)'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuántas personas conforman su hogar, incluyéndose usted?', 'numero', 2, 54,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · C. Datos del hogar (hacinamiento y servicios)'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuántos cuartos o piezas tiene en total el hogar (sin contar cocina, baño ni garaje)?', 'numero', 3, 55,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · C. Datos del hogar (hacinamiento y servicios)'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿En cuántos de esos cuartos duermen las personas del hogar?', 'numero', 4, 56,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · C. Datos del hogar (hacinamiento y servicios)'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Dónde preparan los alimentos?', 'seleccion_unica', 5, 57,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · C. Datos del hogar (hacinamiento y servicios)'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('En un cuarto usado solo para cocinar', 'En un cuarto usado solo para cocinar', 1), ('En un cuarto usado también para dormir', 'En un cuarto usado también para dormir', 2), ('En sala-comedor con lavaplatos', 'En sala-comedor con lavaplatos', 3), ('En sala-comedor sin lavaplatos', 'En sala-comedor sin lavaplatos', 4), ('En un patio, corredor o enramada', 'En un patio, corredor o enramada', 5), ('No preparan alimentos', 'No preparan alimentos', 6)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 57
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Con qué energía o combustible cocinan principalmente?', 'seleccion_unica', 6, 58,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · C. Datos del hogar (hacinamiento y servicios)'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Gas natural de red', 'Gas natural de red', 1), ('Gas en cilindro (pipeta)', 'Gas en cilindro (pipeta)', 2), ('Electricidad', 'Electricidad', 3), ('Leña, madera o carbón de leña', 'Leña, madera o carbón de leña', 4), ('Carbón mineral', 'Carbón mineral', 5), ('Material de desecho', 'Material de desecho', 6), ('No cocinan', 'No cocinan', 7)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 58
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿El lugar donde cocinan tiene ventilación (ventana, extractor o chimenea)?', 'si_no', 7, 59,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · C. Datos del hogar (hacinamiento y servicios)'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿De dónde obtienen principalmente el agua para beber?', 'seleccion_unica', 8, 60,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · C. Datos del hogar (hacinamiento y servicios)'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Acueducto público', 'Acueducto público', 1), ('Acueducto comunal o veredal', 'Acueducto comunal o veredal', 2), ('Pozo, aljibe o nacimiento', 'Pozo, aljibe o nacimiento', 3), ('Agua lluvia', 'Agua lluvia', 4), ('Pila pública o carrotanque', 'Pila pública o carrotanque', 5), ('Agua embotellada o en bolsa', 'Agua embotellada o en bolsa', 6), ('Río, quebrada o manantial', 'Río, quebrada o manantial', 7)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 60
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Antes de beber el agua la hierven, filtran o tratan?', 'seleccion_unica', 9, 61,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · C. Datos del hogar (hacinamiento y servicios)'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('La hierven', 'La hierven', 1), ('Usan filtro', 'Usan filtro', 2), ('Le echan cloro u otro químico', 'Le echan cloro u otro químico', 3), ('Compran agua tratada', 'Compran agua tratada', 4), ('No la tratan', 'No la tratan', 5)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 61
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Qué tipo de servicio sanitario tiene el hogar?', 'seleccion_unica', 10, 62,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · C. Datos del hogar (hacinamiento y servicios)'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Inodoro conectado al alcantarillado', 'Inodoro conectado al alcantarillado', 1), ('Inodoro conectado a pozo séptico', 'Inodoro conectado a pozo séptico', 2), ('Inodoro sin conexión', 'Inodoro sin conexión', 3), ('Letrina', 'Letrina', 4), ('Bajamar / descarga directa a fuente de agua', 'Bajamar / descarga directa a fuente de agua', 5), ('No tiene servicio sanitario', 'No tiene servicio sanitario', 6)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 62
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿El servicio sanitario es de uso exclusivo del hogar?', 'si_no', 11, 63,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · C. Datos del hogar (hacinamiento y servicios)'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuántos baños tiene el hogar?', 'numero', 12, 64,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · C. Datos del hogar (hacinamiento y servicios)'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Dónde lavan la ropa?', 'seleccion_unica', 13, 65,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · C. Datos del hogar (hacinamiento y servicios)'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Lavadero dentro de la vivienda', 'Lavadero dentro de la vivienda', 1), ('Lavadora', 'Lavadora', 2), ('Lavadero compartido', 'Lavadero compartido', 3), ('Fuente de agua (río, quebrada)', 'Fuente de agua (río, quebrada)', 4), ('Otro', 'Otro', 5)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 65
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cómo eliminan principalmente la basura?', 'seleccion_unica', 14, 66,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · C. Datos del hogar (hacinamiento y servicios)'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('La recoge el servicio de aseo', 'La recoge el servicio de aseo', 1), ('La entierran', 'La entierran', 2), ('La queman', 'La queman', 3), ('La tiran a un lote, patio, zanja o quebrada', 'La tiran a un lote, patio, zanja o quebrada', 4), ('La llevan a un contenedor o sitio de acopio', 'La llevan a un contenedor o sitio de acopio', 5)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 66
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Separan los residuos para reciclar?', 'si_no', 15, 67,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · C. Datos del hogar (hacinamiento y servicios)'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Valor del último pago mensual de energía', 'numero', 16, 68,
    'Escriba 0 si no paga.', 'pesos', NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · C. Datos del hogar (hacinamiento y servicios)'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Valor del último pago mensual de acueducto y alcantarillado', 'numero', 17, 69,
    NULL, 'pesos', NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · C. Datos del hogar (hacinamiento y servicios)'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Valor del último pago mensual de gas', 'numero', 18, 70,
    NULL, 'pesos', NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · C. Datos del hogar (hacinamiento y servicios)'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Valor del último pago mensual de internet, telefonía y televisión', 'numero', 19, 71,
    NULL, 'pesos', NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · C. Datos del hogar (hacinamiento y servicios)'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿El hogar tiene servicios prepago (energía o agua prepagada)?', 'seleccion_multiple', 20, 72,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · C. Datos del hogar (hacinamiento y servicios)'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Energía prepago', 'Energía prepago', 1), ('Agua prepago', 'Agua prepago', 2), ('Ninguno', 'Ninguno', 3)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 72
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'En el último año, ¿les han suspendido algún servicio por falta de pago?', 'si_no', 21, 73,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · C. Datos del hogar (hacinamiento y servicios)'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuáles servicios les suspendieron?', 'seleccion_multiple', 22, 74,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · C. Datos del hogar (hacinamiento y servicios)'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Energía', 'Energía', 1), ('Agua', 'Agua', 2), ('Gas', 'Gas', 3), ('Internet', 'Internet', 4)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 74
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cómo califica la calidad del servicio de energía?', 'seleccion_unica', 23, 75,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · C. Datos del hogar (hacinamiento y servicios)'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Muy buena', 'Muy buena', 1), ('Buena', 'Buena', 2), ('Regular', 'Regular', 3), ('Mala', 'Mala', 4), ('Muy mala', 'Muy mala', 5), ('No tiene el servicio', 'No tiene el servicio', 6)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 75
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cómo califica la calidad del servicio de acueducto?', 'seleccion_unica', 24, 76,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · C. Datos del hogar (hacinamiento y servicios)'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Muy buena', 'Muy buena', 1), ('Buena', 'Buena', 2), ('Regular', 'Regular', 3), ('Mala', 'Mala', 4), ('Muy mala', 'Muy mala', 5), ('No tiene el servicio', 'No tiene el servicio', 6)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 76
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cómo califica la calidad del servicio de alcantarillado?', 'seleccion_unica', 25, 77,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · C. Datos del hogar (hacinamiento y servicios)'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Muy buena', 'Muy buena', 1), ('Buena', 'Buena', 2), ('Regular', 'Regular', 3), ('Mala', 'Mala', 4), ('Muy mala', 'Muy mala', 5), ('No tiene el servicio', 'No tiene el servicio', 6)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 77
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cómo califica la calidad del servicio de gas?', 'seleccion_unica', 26, 78,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · C. Datos del hogar (hacinamiento y servicios)'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Muy buena', 'Muy buena', 1), ('Buena', 'Buena', 2), ('Regular', 'Regular', 3), ('Mala', 'Mala', 4), ('Muy mala', 'Muy mala', 5), ('No tiene el servicio', 'No tiene el servicio', 6)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 78
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cómo califica la calidad del servicio de recolección de basuras?', 'seleccion_unica', 27, 79,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · C. Datos del hogar (hacinamiento y servicios)'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Muy buena', 'Muy buena', 1), ('Buena', 'Buena', 2), ('Regular', 'Regular', 3), ('Mala', 'Mala', 4), ('Muy mala', 'Muy mala', 5), ('No tiene el servicio', 'No tiene el servicio', 6)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 79
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cómo califica la calidad del servicio de internet?', 'seleccion_unica', 28, 80,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · C. Datos del hogar (hacinamiento y servicios)'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Muy buena', 'Muy buena', 1), ('Buena', 'Buena', 2), ('Regular', 'Regular', 3), ('Mala', 'Mala', 4), ('Muy mala', 'Muy mala', 5), ('No tiene el servicio', 'No tiene el servicio', 6)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 80
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿El hogar recibe algún subsidio o descuento en servicios públicos (mínimo vital de agua, energía)?', 'seleccion_unica', 29, 81,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · C. Datos del hogar (hacinamiento y servicios)'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Sí', 'Sí', 1), ('No', 'No', 2), ('No sabe', 'No sabe', 3)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 81
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuántos teléfonos celulares hay en el hogar?', 'numero', 30, 82,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · C. Datos del hogar (hacinamiento y servicios)'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;

-- ---- Capítulo D: Características y composición del hogar ----
INSERT INTO public.categoria_dss (
    nombre, orden, capitulo, orden_capitulo, nivel, objetivo, responde,
    tiempo_estimado_min, elegibilidad_edad_min, elegibilidad_edad_max,
    elegibilidad_genero, elegibilidad_jefe_hogar
) VALUES (
    'NARP-342 · D. Características y composición del hogar', 104, 'D', 4,
    'PERSONA', 'Identificar a las personas que conforman el hogar, su parentesco con el jefe/a, su identidad, trayectoria migratoria y bienestar subjetivo.', 'Todas las personas; las preguntas de bienestar subjetivo, para personas de 15 años o más',
    11, NULL, NULL,
    NULL, FALSE
) ON CONFLICT (nombre) DO UPDATE SET
    orden = EXCLUDED.orden, capitulo = EXCLUDED.capitulo,
    orden_capitulo = EXCLUDED.orden_capitulo, nivel = EXCLUDED.nivel,
    objetivo = EXCLUDED.objetivo, responde = EXCLUDED.responde,
    tiempo_estimado_min = EXCLUDED.tiempo_estimado_min,
    elegibilidad_edad_min = EXCLUDED.elegibilidad_edad_min,
    elegibilidad_edad_max = EXCLUDED.elegibilidad_edad_max,
    elegibilidad_genero = EXCLUDED.elegibilidad_genero,
    elegibilidad_jefe_hogar = EXCLUDED.elegibilidad_jefe_hogar;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Sexo al nacer', 'seleccion_unica', 1, 83,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · D. Características y composición del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Hombre', 'Hombre', 1), ('Mujer', 'Mujer', 2), ('Intersexual', 'Intersexual', 3)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 83
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Género con el que se identifica', 'seleccion_unica', 2, 84,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · D. Características y composición del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Mujer', 'Mujer', 1), ('Mujer trans', 'Mujer trans', 2), ('Hombre', 'Hombre', 3), ('Hombre trans', 'Hombre trans', 4), ('No binario', 'No binario', 5), ('Disidente / Otro', 'Disidente / Otro', 6), ('Prefiero no responder', 'Prefiero no responder', 7)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 84
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Orientación sexual', 'seleccion_unica', 3, 85,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · D. Características y composición del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Heterosexual', 'Heterosexual', 1), ('Homosexual (gay o lesbiana)', 'Homosexual (gay o lesbiana)', 2), ('Bisexual', 'Bisexual', 3), ('Asexual', 'Asexual', 4), ('Demisexual', 'Demisexual', 5), ('Otra', 'Otra', 6), ('Prefiero no responder', 'Prefiero no responder', 7)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 85
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'De acuerdo con su cultura, pueblo o rasgos físicos, ¿usted se reconoce como…?', 'seleccion_unica', 4, 86,
    'Reconocimiento étnico según la Sentencia T-276 de 2022 de la Corte Constitucional: el criterio preferente es el autorreconocimiento, no la apariencia.', NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · D. Características y composición del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Negro(a) / Afrocolombiano(a)', 'Negro(a) / Afrocolombiano(a)', 1), ('Raizal del Archipiélago de San Andrés, Providencia y Santa Catalina', 'Raizal del Archipiélago de San Andrés, Providencia y Santa Catalina', 2), ('Palenquero(a) de San Basilio', 'Palenquero(a) de San Basilio', 3)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 86
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Habla alguna lengua propia de su pueblo?', 'seleccion_unica', 5, 87,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · D. Características y composición del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Lengua palenquera', 'Lengua palenquera', 1), ('Creole (kriol) de San Andrés', 'Creole (kriol) de San Andrés', 2), ('Ninguna', 'Ninguna', 3), ('Otra. ¿Cuál? ________', 'Otra. ¿Cuál? ________', 4)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 87
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Pertenece a un consejo comunitario, organización de base u organización afrocolombiana?', 'si_no', 6, 88,
    'Si responde sí, ¿cuál? ________', NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · D. Características y composición del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Estado civil actual', 'seleccion_unica', 7, 89,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · D. Características y composición del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Unión libre (menos de 2 años)', 'Unión libre (menos de 2 años)', 1), ('Unión libre (2 años o más)', 'Unión libre (2 años o más)', 2), ('Casado(a)', 'Casado(a)', 3), ('Separado(a) o divorciado(a)', 'Separado(a) o divorciado(a)', 4), ('Viudo(a)', 'Viudo(a)', 5), ('Soltero(a)', 'Soltero(a)', 6)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 89
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuál es su parentesco con el jefe(a) del hogar?', 'seleccion_unica', 8, 90,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · D. Características y composición del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Es el jefe(a) del hogar', 'Es el jefe(a) del hogar', 1), ('Pareja, esposo(a), cónyuge', 'Pareja, esposo(a), cónyuge', 2), ('Hijo(a), hijastro(a)', 'Hijo(a), hijastro(a)', 3), ('Nieto(a)', 'Nieto(a)', 4), ('Padre o madre', 'Padre o madre', 5), ('Hermano(a)', 'Hermano(a)', 6), ('Otro pariente', 'Otro pariente', 7), ('Persona no pariente', 'Persona no pariente', 8)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 90
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Sexo del jefe(a) del hogar', 'seleccion_unica', 9, 91,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · D. Características y composición del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Hombre', 'Hombre', 1), ('Mujer', 'Mujer', 2)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 91
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿El jefe(a) del hogar es madre o padre cabeza de familia sin pareja?', 'si_no', 10, 92,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · D. Características y composición del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuántos menores de 5 años viven en el hogar?', 'numero', 11, 93,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · D. Características y composición del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuántas personas de 5 a 17 años viven en el hogar?', 'numero', 12, 94,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · D. Características y composición del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuántas personas de 60 años o más viven en el hogar?', 'numero', 13, 95,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · D. Características y composición del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuántas personas con discapacidad viven en el hogar?', 'numero', 14, 96,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · D. Características y composición del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Su padre vive en este hogar?', 'seleccion_unica', 15, 97,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · D. Características y composición del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Sí', 'Sí', 1), ('No', 'No', 2), ('Falleció', 'Falleció', 3)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 97
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuál es el nivel educativo más alto que alcanzó su padre?', 'seleccion_unica', 16, 98,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · D. Características y composición del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Ninguno', 'Ninguno', 1), ('Preescolar', 'Preescolar', 2), ('Básica primaria (1.° a 5.°)', 'Básica primaria (1.° a 5.°)', 3), ('Básica secundaria (6.° a 9.°)', 'Básica secundaria (6.° a 9.°)', 4), ('Media (10.° a 11.°)', 'Media (10.° a 11.°)', 5), ('Técnica profesional', 'Técnica profesional', 6), ('Tecnológica', 'Tecnológica', 7), ('Universitaria', 'Universitaria', 8), ('Especialización', 'Especialización', 9), ('Maestría o doctorado', 'Maestría o doctorado', 10), ('No sabe', 'No sabe', 11)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 98
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Su madre vive en este hogar?', 'seleccion_unica', 17, 99,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · D. Características y composición del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Sí', 'Sí', 1), ('No', 'No', 2), ('Falleció', 'Falleció', 3)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 99
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuál es el nivel educativo más alto que alcanzó su madre?', 'seleccion_unica', 18, 100,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · D. Características y composición del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Ninguno', 'Ninguno', 1), ('Preescolar', 'Preescolar', 2), ('Básica primaria (1.° a 5.°)', 'Básica primaria (1.° a 5.°)', 3), ('Básica secundaria (6.° a 9.°)', 'Básica secundaria (6.° a 9.°)', 4), ('Media (10.° a 11.°)', 'Media (10.° a 11.°)', 5), ('Técnica profesional', 'Técnica profesional', 6), ('Tecnológica', 'Tecnológica', 7), ('Universitaria', 'Universitaria', 8), ('Especialización', 'Especialización', 9), ('Maestría o doctorado', 'Maestría o doctorado', 10), ('No sabe', 'No sabe', 11)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 100
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Dónde vivía hace 5 años?', 'seleccion_unica', 19, 101,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · D. Características y composición del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('En este mismo barrio', 'En este mismo barrio', 1), ('En otro barrio de Medellín', 'En otro barrio de Medellín', 2), ('En otro municipio de Antioquia', 'En otro municipio de Antioquia', 3), ('En el Chocó', 'En el Chocó', 4), ('En otro departamento del Pacífico (Valle, Cauca, Nariño)', 'En otro departamento del Pacífico (Valle, Cauca, Nariño)', 5), ('En otro departamento de Colombia', 'En otro departamento de Colombia', 6), ('En otro país', 'En otro país', 7), ('No había nacido', 'No había nacido', 8)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 101
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuál fue la razón principal por la que llegó a Medellín?', 'seleccion_unica', 20, 102,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · D. Características y composición del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Nació en Medellín', 'Nació en Medellín', 1), ('Buscar trabajo o mejores ingresos', 'Buscar trabajo o mejores ingresos', 2), ('Estudiar', 'Estudiar', 3), ('Por amenaza o riesgo para su vida (desplazamiento forzado)', 'Por amenaza o riesgo para su vida (desplazamiento forzado)', 4), ('Acompañar a la familia', 'Acompañar a la familia', 5), ('Por un desastre natural', 'Por un desastre natural', 6), ('Por razones de salud', 'Por razones de salud', 7), ('Otra. ¿Cuál? ________', 'Otra. ¿Cuál? ________', 8)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 102
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Es víctima del conflicto armado?', 'si_no', 21, 103,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · D. Características y composición del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Está inscrito(a) en el Registro Único de Víctimas (RUV)?', 'seleccion_unica', 22, 104,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · D. Características y composición del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Sí', 'Sí', 1), ('No', 'No', 2), ('No sabe', 'No sabe', 3)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 104
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Qué hechos victimizantes ha sufrido?', 'seleccion_multiple', 23, 105,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · D. Características y composición del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Desplazamiento forzado', 'Desplazamiento forzado', 1), ('Homicidio o desaparición de un familiar', 'Homicidio o desaparición de un familiar', 2), ('Amenaza', 'Amenaza', 3), ('Despojo o abandono de tierras', 'Despojo o abandono de tierras', 4), ('Reclutamiento forzado', 'Reclutamiento forzado', 5), ('Violencia sexual', 'Violencia sexual', 6), ('Confinamiento', 'Confinamiento', 7), ('Otro', 'Otro', 8)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 105
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuál es su religión o creencia espiritual?', 'seleccion_unica', 24, 106,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · D. Características y composición del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Católica', 'Católica', 1), ('Cristiana evangélica', 'Cristiana evangélica', 2), ('Testigo de Jehová', 'Testigo de Jehová', 3), ('Espiritualidad ancestral afro', 'Espiritualidad ancestral afro', 4), ('Ninguna', 'Ninguna', 5), ('Otra. ¿Cuál? ________', 'Otra. ¿Cuál? ________', 6)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 106
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'En los últimos 12 meses, ¿se ha sentido discriminado(a) por su color de piel o pertenencia étnica?', 'si_no', 25, 107,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · D. Características y composición del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿En qué lugares se ha sentido discriminado(a)?', 'seleccion_multiple', 26, 108,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · D. Características y composición del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Lugar de estudio', 'Lugar de estudio', 1), ('Trabajo o búsqueda de empleo', 'Trabajo o búsqueda de empleo', 2), ('Servicios de salud', 'Servicios de salud', 3), ('Espacio público o transporte', 'Espacio público o transporte', 4), ('Comercio', 'Comercio', 5), ('Por parte de la fuerza pública', 'Por parte de la fuerza pública', 6), ('Al buscar vivienda en arriendo', 'Al buscar vivienda en arriendo', 7), ('Otro', 'Otro', 8)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 108
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'En general, ¿qué tan satisfecho(a) está con su vida?', 'escala', 27, 109,
    NULL, NULL, 0, 10
FROM public.categoria_dss WHERE nombre = 'NARP-342 · D. Características y composición del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Qué tan satisfecho(a) está con su salud?', 'escala', 28, 110,
    NULL, NULL, 0, 10
FROM public.categoria_dss WHERE nombre = 'NARP-342 · D. Características y composición del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Qué tan satisfecho(a) está con su seguridad?', 'escala', 29, 111,
    NULL, NULL, 0, 10
FROM public.categoria_dss WHERE nombre = 'NARP-342 · D. Características y composición del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Qué tan satisfecho(a) está con su trabajo o actividad principal?', 'escala', 30, 112,
    NULL, NULL, 0, 10
FROM public.categoria_dss WHERE nombre = 'NARP-342 · D. Características y composición del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Qué tan satisfecho(a) está con su nivel de ingreso?', 'escala', 31, 113,
    NULL, NULL, 0, 10
FROM public.categoria_dss WHERE nombre = 'NARP-342 · D. Características y composición del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Qué tan satisfecho(a) está con su vivienda?', 'escala', 32, 114,
    NULL, NULL, 0, 10
FROM public.categoria_dss WHERE nombre = 'NARP-342 · D. Características y composición del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Ayer, ¿qué tan feliz se sintió?', 'escala', 33, 115,
    NULL, NULL, 0, 10
FROM public.categoria_dss WHERE nombre = 'NARP-342 · D. Características y composición del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Ayer, ¿qué tan preocupado(a) o ansioso(a) se sintió?', 'escala', 34, 116,
    NULL, NULL, 0, 10
FROM public.categoria_dss WHERE nombre = 'NARP-342 · D. Características y composición del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Ayer, ¿qué tan triste o deprimido(a) se sintió?', 'escala', 35, 117,
    NULL, NULL, 0, 10
FROM public.categoria_dss WHERE nombre = 'NARP-342 · D. Características y composición del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Siente que las cosas que hace en su vida valen la pena?', 'escala', 36, 118,
    NULL, NULL, 0, 10
FROM public.categoria_dss WHERE nombre = 'NARP-342 · D. Características y composición del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;

-- ---- Capítulo E: Salud ----
INSERT INTO public.categoria_dss (
    nombre, orden, capitulo, orden_capitulo, nivel, objetivo, responde,
    tiempo_estimado_min, elegibilidad_edad_min, elegibilidad_edad_max,
    elegibilidad_genero, elegibilidad_jefe_hogar
) VALUES (
    'NARP-342 · E. Salud', 105, 'E', 5,
    'PERSONA', 'Conocer la afiliación al Sistema General de Seguridad Social en Salud (Ley 100 de 1993), el acceso y la calidad de los servicios, la presencia de enfermedades crónicas, la discapacidad y los gastos en salud.', 'Todas las personas',
    10, NULL, NULL,
    NULL, FALSE
) ON CONFLICT (nombre) DO UPDATE SET
    orden = EXCLUDED.orden, capitulo = EXCLUDED.capitulo,
    orden_capitulo = EXCLUDED.orden_capitulo, nivel = EXCLUDED.nivel,
    objetivo = EXCLUDED.objetivo, responde = EXCLUDED.responde,
    tiempo_estimado_min = EXCLUDED.tiempo_estimado_min,
    elegibilidad_edad_min = EXCLUDED.elegibilidad_edad_min,
    elegibilidad_edad_max = EXCLUDED.elegibilidad_edad_max,
    elegibilidad_genero = EXCLUDED.elegibilidad_genero,
    elegibilidad_jefe_hogar = EXCLUDED.elegibilidad_jefe_hogar;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Está afiliado(a) a una entidad de seguridad social en salud (EPS)?', 'seleccion_unica', 1, 119,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · E. Salud'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Sí', 'Sí', 1), ('No', 'No', 2), ('No sabe', 'No sabe', 3)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 119
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿A cuál régimen está afiliado(a)?', 'seleccion_unica', 2, 120,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · E. Salud'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Contributivo', 'Contributivo', 1), ('Subsidiado', 'Subsidiado', 2), ('Especial o de excepción (Fuerzas Militares, Magisterio, Ecopetrol)', 'Especial o de excepción (Fuerzas Militares, Magisterio, Ecopetrol)', 3), ('No sabe', 'No sabe', 4)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 120
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Nombre de la EPS', 'texto', 3, 121,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · E. Salud'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'En el régimen contributivo, ¿usted es…?', 'seleccion_unica', 4, 122,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · E. Salud'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Cotizante', 'Cotizante', 1), ('Beneficiario(a)', 'Beneficiario(a)', 2)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 122
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Por qué no está afiliado(a)?', 'seleccion_unica', 5, 123,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · E. Salud'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Falta de dinero', 'Falta de dinero', 1), ('Está en trámite', 'Está en trámite', 2), ('No lo considera necesario', 'No lo considera necesario', 3), ('No tiene documento de identidad', 'No tiene documento de identidad', 4), ('Muchos trámites', 'Muchos trámites', 5), ('No sabe cómo afiliarse', 'No sabe cómo afiliarse', 6), ('Otra', 'Otra', 7)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 123
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'En general, ¿cómo considera que es su estado de salud?', 'seleccion_unica', 6, 124,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · E. Salud'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Muy bueno', 'Muy bueno', 1), ('Bueno', 'Bueno', 2), ('Regular', 'Regular', 3), ('Malo', 'Malo', 4)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 124
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Un médico le ha diagnosticado alguna enfermedad crónica?', 'si_no', 7, 125,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · E. Salud'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuál(es) enfermedad(es) crónica(s)?', 'seleccion_multiple', 8, 126,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · E. Salud'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Hipertensión arterial', 'Hipertensión arterial', 1), ('Diabetes', 'Diabetes', 2), ('Enfermedad cardiovascular', 'Enfermedad cardiovascular', 3), ('Enfermedad respiratoria crónica (asma, EPOC)', 'Enfermedad respiratoria crónica (asma, EPOC)', 4), ('Cáncer', 'Cáncer', 5), ('Enfermedad renal', 'Enfermedad renal', 6), ('Anemia falciforme', 'Anemia falciforme', 7), ('VIH', 'VIH', 8), ('Otra. ¿Cuál? ________', 'Otra. ¿Cuál? ________', 9)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 126
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Recibe tratamiento regular para esa enfermedad?', 'si_no', 9, 127,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · E. Salud'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'En los últimos 30 días, ¿tuvo alguna enfermedad, accidente o problema de salud que no requirió hospitalización?', 'si_no', 10, 128,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · E. Salud'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Para tratar ese problema, ¿qué hizo principalmente?', 'seleccion_unica', 11, 129,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · E. Salud'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Acudió a la EPS, hospital o centro de salud', 'Acudió a la EPS, hospital o centro de salud', 1), ('Acudió a un médico particular', 'Acudió a un médico particular', 2), ('Acudió a un médico tradicional, yerbatero o curandero', 'Acudió a un médico tradicional, yerbatero o curandero', 3), ('Se automedicó o fue a la farmacia', 'Se automedicó o fue a la farmacia', 4), ('Usó remedios caseros', 'Usó remedios caseros', 5), ('No hizo nada', 'No hizo nada', 6)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 129
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Por qué no acudió a un servicio médico?', 'seleccion_unica', 12, 130,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · E. Salud'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('El caso era leve', 'El caso era leve', 1), ('No tenía tiempo', 'No tenía tiempo', 2), ('El centro de atención queda lejos', 'El centro de atención queda lejos', 3), ('Falta de dinero', 'Falta de dinero', 4), ('Mal servicio o citas distanciadas', 'Mal servicio o citas distanciadas', 5), ('No lo atendieron', 'No lo atendieron', 6), ('Muchos trámites', 'Muchos trámites', 7), ('Desconfianza en los médicos', 'Desconfianza en los médicos', 8), ('Otra', 'Otra', 9)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 130
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuántos días pasaron entre la solicitud de la cita y la atención?', 'numero', 13, 131,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · E. Salud'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cómo califica la calidad del servicio de salud recibido?', 'seleccion_unica', 14, 132,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · E. Salud'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Muy buena', 'Muy buena', 1), ('Buena', 'Buena', 2), ('Mala', 'Mala', 3), ('Muy mala', 'Muy mala', 4)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 132
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'En el último mes, ¿cuánto gastó de su bolsillo en consultas médicas?', 'numero', 15, 133,
    NULL, 'pesos', NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · E. Salud'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'En el último mes, ¿cuánto gastó de su bolsillo en medicamentos?', 'numero', 16, 134,
    NULL, 'pesos', NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · E. Salud'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Le entregaron completos los medicamentos formulados la última vez?', 'seleccion_unica', 17, 135,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · E. Salud'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Sí, todos', 'Sí, todos', 1), ('Solo algunos', 'Solo algunos', 2), ('Ninguno', 'Ninguno', 3), ('No le han formulado', 'No le han formulado', 4)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 135
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'En los últimos 12 meses, ¿estuvo hospitalizado(a)?', 'si_no', 18, 136,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · E. Salud'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'En los últimos 12 meses, ¿fue a consulta médica de control o prevención, sin estar enfermo(a)?', 'si_no', 19, 137,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · E. Salud'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'En los últimos 12 meses, ¿fue a consulta con el odontólogo?', 'si_no', 20, 138,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · E. Salud'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Tiene el esquema de vacunación completo para su edad?', 'seleccion_unica', 21, 139,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · E. Salud'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Sí', 'Sí', 1), ('No', 'No', 2), ('No sabe', 'No sabe', 3)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 139
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Tiene dificultad para ver, aun si usa gafas o lentes?', 'seleccion_unica', 22, 140,
    'Preguntas del Grupo de Washington, usadas por el DANE para medir discapacidad.', NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · E. Salud'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Sin dificultad', 'Sin dificultad', 1), ('Con alguna dificultad', 'Con alguna dificultad', 2), ('Con mucha dificultad', 'Con mucha dificultad', 3), ('No puede hacerlo', 'No puede hacerlo', 4)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 140
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Tiene dificultad para oír, aun si usa audífonos?', 'seleccion_unica', 23, 141,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · E. Salud'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Sin dificultad', 'Sin dificultad', 1), ('Con alguna dificultad', 'Con alguna dificultad', 2), ('Con mucha dificultad', 'Con mucha dificultad', 3), ('No puede hacerlo', 'No puede hacerlo', 4)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 141
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Tiene dificultad para caminar o subir escaleras?', 'seleccion_unica', 24, 142,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · E. Salud'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Sin dificultad', 'Sin dificultad', 1), ('Con alguna dificultad', 'Con alguna dificultad', 2), ('Con mucha dificultad', 'Con mucha dificultad', 3), ('No puede hacerlo', 'No puede hacerlo', 4)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 142
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Tiene dificultad para recordar o concentrarse?', 'seleccion_unica', 25, 143,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · E. Salud'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Sin dificultad', 'Sin dificultad', 1), ('Con alguna dificultad', 'Con alguna dificultad', 2), ('Con mucha dificultad', 'Con mucha dificultad', 3), ('No puede hacerlo', 'No puede hacerlo', 4)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 143
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Tiene dificultad para bañarse o vestirse por sí mismo(a)?', 'seleccion_unica', 26, 144,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · E. Salud'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Sin dificultad', 'Sin dificultad', 1), ('Con alguna dificultad', 'Con alguna dificultad', 2), ('Con mucha dificultad', 'Con mucha dificultad', 3), ('No puede hacerlo', 'No puede hacerlo', 4)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 144
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Tiene dificultad para comunicarse (entender o ser entendido) en su lenguaje habitual?', 'seleccion_unica', 27, 145,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · E. Salud'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Sin dificultad', 'Sin dificultad', 1), ('Con alguna dificultad', 'Con alguna dificultad', 2), ('Con mucha dificultad', 'Con mucha dificultad', 3), ('No puede hacerlo', 'No puede hacerlo', 4)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 145
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Tiene dificultad para relacionarse con los demás por problemas emocionales o mentales?', 'seleccion_unica', 28, 146,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · E. Salud'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Sin dificultad', 'Sin dificultad', 1), ('Con alguna dificultad', 'Con alguna dificultad', 2), ('Con mucha dificultad', 'Con mucha dificultad', 3), ('No puede hacerlo', 'No puede hacerlo', 4)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 146
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Presenta algún tipo de discapacidad?', 'si_no', 29, 147,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · E. Salud'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Qué tipo de discapacidad?', 'seleccion_multiple', 30, 148,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · E. Salud'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Física (motora u orgánica)', 'Física (motora u orgánica)', 1), ('Sensorial visual', 'Sensorial visual', 2), ('Sensorial auditiva', 'Sensorial auditiva', 3), ('Intelectual', 'Intelectual', 4), ('Psicosocial', 'Psicosocial', 5), ('Múltiple', 'Múltiple', 6)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 148
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuenta con el certificado de discapacidad?', 'seleccion_unica', 31, 149,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · E. Salud'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Sí', 'Sí', 1), ('No', 'No', 2), ('No sabe', 'No sabe', 3)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 149
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Necesita ayuda de otra persona para sus actividades diarias?', 'si_no', 32, 150,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · E. Salud'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Usa algún producto de apoyo (silla de ruedas, bastón, audífono, prótesis)?', 'si_no', 33, 151,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · E. Salud'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'En las últimas 2 semanas, ¿con qué frecuencia se ha sentido desanimado(a), deprimido(a) o sin esperanza?', 'seleccion_unica', 34, 152,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · E. Salud'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Nunca', 'Nunca', 1), ('Varios días', 'Varios días', 2), ('Más de la mitad de los días', 'Más de la mitad de los días', 3), ('Casi todos los días', 'Casi todos los días', 4)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 152
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'En las últimas 2 semanas, ¿con qué frecuencia se ha sentido nervioso(a), ansioso(a) o con los nervios de punta?', 'seleccion_unica', 35, 153,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · E. Salud'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Nunca', 'Nunca', 1), ('Varios días', 'Varios días', 2), ('Más de la mitad de los días', 'Más de la mitad de los días', 3), ('Casi todos los días', 'Casi todos los días', 4)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 153
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'En los últimos 12 meses, ¿recibió atención psicológica o psiquiátrica?', 'si_no', 36, 154,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · E. Salud'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Fuma cigarrillo, tabaco o vapeador?', 'seleccion_unica', 37, 155,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · E. Salud'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Todos los días', 'Todos los días', 1), ('Algunos días', 'Algunos días', 2), ('No fuma', 'No fuma', 3)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 155
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Con qué frecuencia consume bebidas alcohólicas?', 'seleccion_unica', 38, 156,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · E. Salud'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Nunca', 'Nunca', 1), ('Una vez al mes o menos', 'Una vez al mes o menos', 2), ('2 a 4 veces al mes', '2 a 4 veces al mes', 3), ('2 a 3 veces por semana', '2 a 3 veces por semana', 4), ('4 o más veces por semana', '4 o más veces por semana', 5)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 156
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Realiza actividad física de al menos 30 minutos tres veces por semana?', 'si_no', 39, 157,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · E. Salud'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Usa plantas medicinales o medicina tradicional afro para cuidar su salud?', 'seleccion_unica', 40, 158,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · E. Salud'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Con frecuencia', 'Con frecuencia', 1), ('A veces', 'A veces', 2), ('Nunca', 'Nunca', 3)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 158
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Ha acudido a sabedores, parteras o médicos tradicionales de su comunidad?', 'si_no', 41, 159,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · E. Salud'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Considera que en el servicio de salud respetan sus prácticas culturales?', 'seleccion_unica', 42, 160,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · E. Salud'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Siempre', 'Siempre', 1), ('Algunas veces', 'Algunas veces', 2), ('Nunca', 'Nunca', 3), ('No ha usado el servicio', 'No ha usado el servicio', 4)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 160
ON CONFLICT DO NOTHING;

-- ---- Capítulo F: Cuidado de niños y niñas menores de 5 años ----
INSERT INTO public.categoria_dss (
    nombre, orden, capitulo, orden_capitulo, nivel, objetivo, responde,
    tiempo_estimado_min, elegibilidad_edad_min, elegibilidad_edad_max,
    elegibilidad_genero, elegibilidad_jefe_hogar
) VALUES (
    'NARP-342 · F. Cuidado de niños y niñas menores de 5 años', 106, 'F', 6,
    'PERSONA', 'Identificar quién cuida a los menores de 5 años, la cobertura de establecimientos públicos y privados para su protección y aprendizaje, el desplazamiento y los gastos del hogar en su cuidado.', 'Se despliega si en el hogar hay menores de 5 años (responde la madre, el padre o el cuidador principal)',
    1, NULL, NULL,
    NULL, FALSE
) ON CONFLICT (nombre) DO UPDATE SET
    orden = EXCLUDED.orden, capitulo = EXCLUDED.capitulo,
    orden_capitulo = EXCLUDED.orden_capitulo, nivel = EXCLUDED.nivel,
    objetivo = EXCLUDED.objetivo, responde = EXCLUDED.responde,
    tiempo_estimado_min = EXCLUDED.tiempo_estimado_min,
    elegibilidad_edad_min = EXCLUDED.elegibilidad_edad_min,
    elegibilidad_edad_max = EXCLUDED.elegibilidad_edad_max,
    elegibilidad_genero = EXCLUDED.elegibilidad_genero,
    elegibilidad_jefe_hogar = EXCLUDED.elegibilidad_jefe_hogar;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuántos niños o niñas menores de 5 años tiene a su cargo?', 'numero', 1, 161,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · F. Cuidado de niños y niñas menores de 5 años'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Dónde o con quién permanece el niño(a) la mayor parte del tiempo entre semana?', 'seleccion_unica', 2, 162,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · F. Cuidado de niños y niñas menores de 5 años'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Asiste a un hogar comunitario, jardín, CDI o preescolar', 'Asiste a un hogar comunitario, jardín, CDI o preescolar', 1), ('Con su padre o madre en la casa', 'Con su padre o madre en la casa', 2), ('Con su padre o madre en el trabajo', 'Con su padre o madre en el trabajo', 3), ('Con un pariente de 18 años o más', 'Con un pariente de 18 años o más', 4), ('Con un pariente menor de 18 años', 'Con un pariente menor de 18 años', 5), ('En casa solo(a)', 'En casa solo(a)', 6), ('Con una empleada o niñera', 'Con una empleada o niñera', 7), ('Otro', 'Otro', 8)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 162
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿A qué tipo de institución asiste?', 'seleccion_unica', 3, 163,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · F. Cuidado de niños y niñas menores de 5 años'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Hogar comunitario de Bienestar Familiar', 'Hogar comunitario de Bienestar Familiar', 1), ('CDI o Buen Comienzo', 'CDI o Buen Comienzo', 2), ('Jardín o preescolar público', 'Jardín o preescolar público', 3), ('Jardín o preescolar privado', 'Jardín o preescolar privado', 4), ('Otro', 'Otro', 5)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 163
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Recibe alimentación en esa institución?', 'si_no', 4, 164,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · F. Cuidado de niños y niñas menores de 5 años'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuánto tiempo tarda en llegar del hogar a la institución?', 'numero', 5, 165,
    NULL, 'minutos', NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · F. Cuidado de niños y niñas menores de 5 años'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Quién lo lleva normalmente?', 'seleccion_unica', 6, 166,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · F. Cuidado de niños y niñas menores de 5 años'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Madre', 'Madre', 1), ('Padre', 'Padre', 2), ('Otro pariente', 'Otro pariente', 3), ('Transporte escolar', 'Transporte escolar', 4), ('Otro', 'Otro', 5)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 166
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuánto pagan al mes por la institución (pensión, matrícula, transporte)?', 'numero', 7, 167,
    NULL, 'pesos', NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · F. Cuidado de niños y niñas menores de 5 años'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Por qué el niño(a) no asiste a una institución?', 'seleccion_unica', 8, 168,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · F. Cuidado de niños y niñas menores de 5 años'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Prefieren cuidarlo en casa', 'Prefieren cuidarlo en casa', 1), ('No hay institución cerca', 'No hay institución cerca', 2), ('No hay cupo', 'No hay cupo', 3), ('Falta de dinero', 'Falta de dinero', 4), ('Lo considera muy pequeño', 'Lo considera muy pequeño', 5), ('Desconfianza', 'Desconfianza', 6), ('Otra', 'Otra', 7)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 168
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿El niño(a) tiene registro civil de nacimiento?', 'si_no', 9, 169,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · F. Cuidado de niños y niñas menores de 5 años'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿El niño(a) asiste a los controles de crecimiento y desarrollo?', 'seleccion_unica', 10, 170,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · F. Cuidado de niños y niñas menores de 5 años'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Sí, a todos', 'Sí, a todos', 1), ('A algunos', 'A algunos', 2), ('No', 'No', 3)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 170
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿El niño(a) tiene el carné de vacunación al día?', 'seleccion_unica', 11, 171,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · F. Cuidado de niños y niñas menores de 5 años'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Sí', 'Sí', 1), ('No', 'No', 2), ('No sabe', 'No sabe', 3)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 171
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿El niño(a) recibió leche materna?', 'si_no', 12, 172,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · F. Cuidado de niños y niñas menores de 5 años'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Hasta qué edad recibió solo leche materna (sin otros alimentos)?', 'numero', 13, 173,
    NULL, 'meses', NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · F. Cuidado de niños y niñas menores de 5 años'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'En la última semana, ¿alguien del hogar le leyó cuentos o miró libros con él o ella?', 'si_no', 14, 174,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · F. Cuidado de niños y niñas menores de 5 años'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'En la última semana, ¿alguien del hogar le contó historias, cantó o enseñó juegos tradicionales?', 'si_no', 15, 175,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · F. Cuidado de niños y niñas menores de 5 años'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'En la última semana, ¿alguien del hogar jugó con él o ella?', 'si_no', 16, 176,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · F. Cuidado de niños y niñas menores de 5 años'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿El niño(a) está afiliado a salud?', 'si_no', 17, 177,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · F. Cuidado de niños y niñas menores de 5 años'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿El niño(a) recibe algún complemento nutricional o apoyo (Bienestarina, paquete alimentario)?', 'si_no', 18, 178,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · F. Cuidado de niños y niñas menores de 5 años'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;

-- ---- Capítulo G: Fecundidad y salud reproductiva ----
INSERT INTO public.categoria_dss (
    nombre, orden, capitulo, orden_capitulo, nivel, objetivo, responde,
    tiempo_estimado_min, elegibilidad_edad_min, elegibilidad_edad_max,
    elegibilidad_genero, elegibilidad_jefe_hogar
) VALUES (
    'NARP-342 · G. Fecundidad y salud reproductiva', 107, 'G', 7,
    'PERSONA', 'Conocer el número de hijos nacidos vivos y sobrevivientes, la atención del embarazo y el parto, y el acceso a la planificación familiar, con atención al embarazo adolescente.', 'Mujeres de 12 a 49 años',
    1, 12, 49,
    'Mujer', FALSE
) ON CONFLICT (nombre) DO UPDATE SET
    orden = EXCLUDED.orden, capitulo = EXCLUDED.capitulo,
    orden_capitulo = EXCLUDED.orden_capitulo, nivel = EXCLUDED.nivel,
    objetivo = EXCLUDED.objetivo, responde = EXCLUDED.responde,
    tiempo_estimado_min = EXCLUDED.tiempo_estimado_min,
    elegibilidad_edad_min = EXCLUDED.elegibilidad_edad_min,
    elegibilidad_edad_max = EXCLUDED.elegibilidad_edad_max,
    elegibilidad_genero = EXCLUDED.elegibilidad_genero,
    elegibilidad_jefe_hogar = EXCLUDED.elegibilidad_jefe_hogar;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Ha tenido hijos o hijas nacidos vivos?', 'si_no', 1, 179,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · G. Fecundidad y salud reproductiva'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuántos hijos e hijas nacidos vivos ha tenido en total?', 'numero', 2, 180,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · G. Fecundidad y salud reproductiva'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuántos de ellos están vivos actualmente?', 'numero', 3, 181,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · G. Fecundidad y salud reproductiva'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Qué edad tenía cuando nació su primer hijo(a)?', 'numero', 4, 182,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · G. Fecundidad y salud reproductiva'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Fecha de nacimiento del último hijo(a)', 'fecha', 5, 183,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · G. Fecundidad y salud reproductiva'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Sexo del último hijo(a)', 'seleccion_unica', 6, 184,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · G. Fecundidad y salud reproductiva'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Hombre', 'Hombre', 1), ('Mujer', 'Mujer', 2)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 184
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'En su último embarazo, ¿asistió a controles prenatales?', 'seleccion_unica', 7, 185,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · G. Fecundidad y salud reproductiva'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Sí, 4 o más', 'Sí, 4 o más', 1), ('Sí, menos de 4', 'Sí, menos de 4', 2), ('No', 'No', 3)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 185
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Dónde fue atendido el último parto?', 'seleccion_unica', 8, 186,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · G. Fecundidad y salud reproductiva'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Hospital o clínica', 'Hospital o clínica', 1), ('En la casa, con partera', 'En la casa, con partera', 2), ('En la casa, sin partera', 'En la casa, sin partera', 3), ('Otro', 'Otro', 4)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 186
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Está embarazada actualmente?', 'seleccion_unica', 9, 187,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · G. Fecundidad y salud reproductiva'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Sí', 'Sí', 1), ('No', 'No', 2), ('No sabe', 'No sabe', 3)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 187
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Usa actualmente algún método para evitar embarazos?', 'si_no', 10, 188,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · G. Fecundidad y salud reproductiva'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuál método usa?', 'seleccion_unica', 11, 189,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · G. Fecundidad y salud reproductiva'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Píldora', 'Píldora', 1), ('Inyección', 'Inyección', 2), ('Implante subdérmico', 'Implante subdérmico', 3), ('DIU', 'DIU', 4), ('Condón', 'Condón', 5), ('Ligadura / vasectomía de la pareja', 'Ligadura / vasectomía de la pareja', 6), ('Método natural', 'Método natural', 7), ('Otro', 'Otro', 8)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 189
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Ha tenido dificultades para acceder a métodos de planificación en su EPS?', 'si_no', 12, 190,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · G. Fecundidad y salud reproductiva'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;

-- ---- Capítulo H: Educación y uso de tecnologías ----
INSERT INTO public.categoria_dss (
    nombre, orden, capitulo, orden_capitulo, nivel, objetivo, responde,
    tiempo_estimado_min, elegibilidad_edad_min, elegibilidad_edad_max,
    elegibilidad_genero, elegibilidad_jefe_hogar
) VALUES (
    'NARP-342 · H. Educación y uso de tecnologías', 108, 'H', 8,
    'PERSONA', 'Identificar alfabetismo, asistencia escolar, niveles alcanzados, facilidades de acceso, razones de inasistencia, subsidios y créditos educativos, y el gasto de los hogares en educación.', 'Personas de 5 años o más',
    8, 5, NULL,
    NULL, FALSE
) ON CONFLICT (nombre) DO UPDATE SET
    orden = EXCLUDED.orden, capitulo = EXCLUDED.capitulo,
    orden_capitulo = EXCLUDED.orden_capitulo, nivel = EXCLUDED.nivel,
    objetivo = EXCLUDED.objetivo, responde = EXCLUDED.responde,
    tiempo_estimado_min = EXCLUDED.tiempo_estimado_min,
    elegibilidad_edad_min = EXCLUDED.elegibilidad_edad_min,
    elegibilidad_edad_max = EXCLUDED.elegibilidad_edad_max,
    elegibilidad_genero = EXCLUDED.elegibilidad_genero,
    elegibilidad_jefe_hogar = EXCLUDED.elegibilidad_jefe_hogar;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Sabe leer y escribir?', 'si_no', 1, 191,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · H. Educación y uso de tecnologías'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Actualmente estudia (asiste a preescolar, escuela, colegio, universidad u otro)?', 'si_no', 2, 192,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · H. Educación y uso de tecnologías'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Qué nivel cursa actualmente?', 'seleccion_unica', 3, 193,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · H. Educación y uso de tecnologías'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Preescolar', 'Preescolar', 1), ('Básica primaria (1.° a 5.°)', 'Básica primaria (1.° a 5.°)', 2), ('Básica secundaria (6.° a 9.°)', 'Básica secundaria (6.° a 9.°)', 3), ('Media (10.° a 11.°)', 'Media (10.° a 11.°)', 4), ('Técnica profesional', 'Técnica profesional', 5), ('Tecnológica', 'Tecnológica', 6), ('Universitaria', 'Universitaria', 7), ('Especialización', 'Especialización', 8), ('Maestría o doctorado', 'Maestría o doctorado', 9)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 193
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Qué grado o semestre cursa?', 'numero', 4, 194,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · H. Educación y uso de tecnologías'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Nombre de la institución donde estudia', 'texto', 5, 195,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · H. Educación y uso de tecnologías'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿La institución es pública o privada?', 'seleccion_unica', 6, 196,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · H. Educación y uso de tecnologías'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Pública', 'Pública', 1), ('Privada', 'Privada', 2), ('De régimen especial', 'De régimen especial', 3)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 196
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿En qué jornada estudia?', 'seleccion_unica', 7, 197,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · H. Educación y uso de tecnologías'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Mañana', 'Mañana', 1), ('Tarde', 'Tarde', 2), ('Noche', 'Noche', 3), ('Única o completa', 'Única o completa', 4), ('Fin de semana', 'Fin de semana', 5), ('Virtual', 'Virtual', 6)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 197
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Qué está estudiando (carrera o programa)?', 'texto', 8, 198,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · H. Educación y uso de tecnologías'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuál es el principal medio de transporte para ir a estudiar?', 'seleccion_unica', 9, 199,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · H. Educación y uso de tecnologías'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('A pie', 'A pie', 1), ('Bicicleta', 'Bicicleta', 2), ('Metro, metrocable o bus', 'Metro, metrocable o bus', 3), ('Transporte escolar', 'Transporte escolar', 4), ('Moto', 'Moto', 5), ('Carro particular', 'Carro particular', 6), ('Otro', 'Otro', 7)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 199
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuánto tiempo tarda en llegar al lugar de estudio?', 'numero', 10, 200,
    NULL, 'minutos', NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · H. Educación y uso de tecnologías'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Recibe alimentación escolar (PAE) en la institución?', 'si_no', 11, 201,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · H. Educación y uso de tecnologías'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Recibe beca, subsidio o crédito educativo?', 'si_no', 12, 202,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · H. Educación y uso de tecnologías'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Qué entidad se lo otorga?', 'seleccion_unica', 13, 203,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · H. Educación y uso de tecnologías'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('ICETEX', 'ICETEX', 1), ('Alcaldía / Sapiencia', 'Alcaldía / Sapiencia', 2), ('Gobierno nacional (Generación E, Matrícula Cero)', 'Gobierno nacional (Generación E, Matrícula Cero)', 3), ('Fondo de comunidades negras (ICETEX)', 'Fondo de comunidades negras (ICETEX)', 4), ('La misma institución', 'La misma institución', 5), ('Empresa u ONG', 'Empresa u ONG', 6), ('Otra', 'Otra', 7)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 203
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'En el último año, ¿cuánto pagó por matrícula o pensión?', 'numero', 14, 204,
    NULL, 'pesos', NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · H. Educación y uso de tecnologías'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'En el último año, ¿cuánto pagó por uniformes, útiles y textos?', 'numero', 15, 205,
    NULL, 'pesos', NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · H. Educación y uso de tecnologías'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuál es la principal razón por la que no estudia?', 'seleccion_unica', 16, 206,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · H. Educación y uso de tecnologías'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Ya terminó o considera que no está en edad', 'Ya terminó o considera que no está en edad', 1), ('Falta de dinero o costos', 'Falta de dinero o costos', 2), ('Necesita trabajar', 'Necesita trabajar', 3), ('Responsabilidades de cuidado o labores del hogar', 'Responsabilidades de cuidado o labores del hogar', 4), ('Embarazo', 'Embarazo', 5), ('No hay cupo o la institución queda lejos', 'No hay cupo o la institución queda lejos', 6), ('No le gusta o no le interesa', 'No le gusta o no le interesa', 7), ('Por discapacidad o enfermedad', 'Por discapacidad o enfermedad', 8), ('Inseguridad o fronteras invisibles', 'Inseguridad o fronteras invisibles', 9), ('Otra', 'Otra', 10)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 206
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuál es el nivel educativo más alto que alcanzó?', 'seleccion_unica', 17, 207,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · H. Educación y uso de tecnologías'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Ninguno', 'Ninguno', 1), ('Preescolar', 'Preescolar', 2), ('Básica primaria (1.° a 5.°)', 'Básica primaria (1.° a 5.°)', 3), ('Básica secundaria (6.° a 9.°)', 'Básica secundaria (6.° a 9.°)', 4), ('Media (10.° a 11.°)', 'Media (10.° a 11.°)', 5), ('Técnica profesional', 'Técnica profesional', 6), ('Tecnológica', 'Tecnológica', 7), ('Universitaria', 'Universitaria', 8), ('Especialización', 'Especialización', 9), ('Maestría o doctorado', 'Maestría o doctorado', 10)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 207
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuál fue el último grado o año aprobado en ese nivel?', 'numero', 18, 208,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · H. Educación y uso de tecnologías'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuál es el título o diploma de mayor nivel que ha obtenido?', 'seleccion_unica', 19, 209,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · H. Educación y uso de tecnologías'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Ninguno', 'Ninguno', 1), ('Bachiller', 'Bachiller', 2), ('Técnico', 'Técnico', 3), ('Tecnólogo', 'Tecnólogo', 4), ('Profesional', 'Profesional', 5), ('Posgrado', 'Posgrado', 6)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 209
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿En su institución educativa enseñan la Cátedra de Estudios Afrocolombianos o etnoeducación?', 'seleccion_unica', 20, 210,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · H. Educación y uso de tecnologías'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Sí', 'Sí', 1), ('No', 'No', 2), ('No sabe', 'No sabe', 3), ('No estudia', 'No estudia', 4)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 210
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Ha sufrido discriminación o acoso por su color de piel en el lugar de estudio?', 'seleccion_unica', 21, 211,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · H. Educación y uso de tecnologías'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Sí', 'Sí', 1), ('No', 'No', 2), ('No estudia', 'No estudia', 3)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 211
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Qué le gustaría estudiar en un futuro próximo?', 'texto', 22, 212,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · H. Educación y uso de tecnologías'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Fuera de la jornada escolar, ¿dónde permanece la mayor parte del tiempo?', 'seleccion_unica', 23, 213,
    'Para estudiantes menores de 18 años.', NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · H. Educación y uso de tecnologías'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('En casa con un adulto', 'En casa con un adulto', 1), ('En casa solo(a) o con otros menores', 'En casa solo(a) o con otros menores', 2), ('En actividades deportivas o culturales', 'En actividades deportivas o culturales', 3), ('Trabajando', 'Trabajando', 4), ('En la calle', 'En la calle', 5), ('Otro', 'Otro', 6)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 213
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Usa teléfono celular?', 'seleccion_unica', 24, 214,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · H. Educación y uso de tecnologías'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Sí, con internet (smartphone)', 'Sí, con internet (smartphone)', 1), ('Sí, sin internet', 'Sí, sin internet', 2), ('No', 'No', 3)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 214
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Usa computador (de escritorio o portátil)?', 'si_no', 25, 215,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · H. Educación y uso de tecnologías'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Usa internet?', 'si_no', 26, 216,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · H. Educación y uso de tecnologías'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Con qué frecuencia usa internet?', 'seleccion_unica', 27, 217,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · H. Educación y uso de tecnologías'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Todos los días', 'Todos los días', 1), ('Al menos una vez a la semana', 'Al menos una vez a la semana', 2), ('Al menos una vez al mes', 'Al menos una vez al mes', 3), ('Menos de una vez al mes', 'Menos de una vez al mes', 4)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 217
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Dónde usa internet principalmente?', 'seleccion_unica', 28, 218,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · H. Educación y uso de tecnologías'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('En la vivienda', 'En la vivienda', 1), ('En el trabajo', 'En el trabajo', 2), ('En la institución educativa', 'En la institución educativa', 3), ('En centros de acceso público (biblioteca, Parque Biblioteca)', 'En centros de acceso público (biblioteca, Parque Biblioteca)', 4), ('En la calle con datos móviles', 'En la calle con datos móviles', 5), ('En casa de otra persona', 'En casa de otra persona', 6)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 218
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Para qué usa internet?', 'seleccion_multiple', 29, 219,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · H. Educación y uso de tecnologías'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Redes sociales y mensajería', 'Redes sociales y mensajería', 1), ('Educación y aprendizaje', 'Educación y aprendizaje', 2), ('Trabajo', 'Trabajo', 3), ('Trámites con el gobierno', 'Trámites con el gobierno', 4), ('Banca o pagos', 'Banca o pagos', 5), ('Buscar empleo', 'Buscar empleo', 6), ('Entretenimiento', 'Entretenimiento', 7)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 219
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Sabe enviar correos electrónicos con archivos adjuntos?', 'si_no', 30, 220,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · H. Educación y uso de tecnologías'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Sabe hacer trámites o pagos en línea?', 'si_no', 31, 221,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · H. Educación y uso de tecnologías'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;

-- ---- Capítulo I: Fuerza de trabajo e ingresos ----
INSERT INTO public.categoria_dss (
    nombre, orden, capitulo, orden_capitulo, nivel, objetivo, responde,
    tiempo_estimado_min, elegibilidad_edad_min, elegibilidad_edad_max,
    elegibilidad_genero, elegibilidad_jefe_hogar
) VALUES (
    'NARP-342 · I. Fuerza de trabajo e ingresos', 109, 'I', 9,
    'PERSONA', 'Clasificar a la población de 12 años y más en ocupada, desocupada o inactiva, y caracterizar a los ocupados: ingresos, posición ocupacional, horas trabajadas, sitio de trabajo y acceso a la seguridad social.', 'Personas de 12 años o más',
    10, 12, NULL,
    NULL, FALSE
) ON CONFLICT (nombre) DO UPDATE SET
    orden = EXCLUDED.orden, capitulo = EXCLUDED.capitulo,
    orden_capitulo = EXCLUDED.orden_capitulo, nivel = EXCLUDED.nivel,
    objetivo = EXCLUDED.objetivo, responde = EXCLUDED.responde,
    tiempo_estimado_min = EXCLUDED.tiempo_estimado_min,
    elegibilidad_edad_min = EXCLUDED.elegibilidad_edad_min,
    elegibilidad_edad_max = EXCLUDED.elegibilidad_edad_max,
    elegibilidad_genero = EXCLUDED.elegibilidad_genero,
    elegibilidad_jefe_hogar = EXCLUDED.elegibilidad_jefe_hogar;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿En qué actividad ocupó la mayor parte del tiempo la semana pasada?', 'seleccion_unica', 1, 222,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · I. Fuerza de trabajo e ingresos'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Trabajando', 'Trabajando', 1), ('Buscando trabajo', 'Buscando trabajo', 2), ('Estudiando', 'Estudiando', 3), ('Oficios del hogar', 'Oficios del hogar', 4), ('Incapacitado(a) permanente para trabajar', 'Incapacitado(a) permanente para trabajar', 5), ('Otra actividad', 'Otra actividad', 6)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 222
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Además de lo anterior, ¿la semana pasada realizó alguna actividad paga por una hora o más (venta, oficio, rebusque)?', 'si_no', 2, 223,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · I. Fuerza de trabajo e ingresos'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Aunque no trabajó la semana pasada, ¿tenía un trabajo o negocio por el que recibe ingresos?', 'si_no', 3, 224,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · I. Fuerza de trabajo e ingresos'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'En las últimas 4 semanas, ¿hizo alguna diligencia para conseguir trabajo o montar un negocio?', 'si_no', 4, 225,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · I. Fuerza de trabajo e ingresos'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Por qué no buscó trabajo?', 'seleccion_unica', 5, 226,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · I. Fuerza de trabajo e ingresos'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Ya encontró trabajo', 'Ya encontró trabajo', 1), ('No hay trabajo disponible', 'No hay trabajo disponible', 2), ('Está cansado(a) de buscar', 'Está cansado(a) de buscar', 3), ('No sabe cómo buscar', 'No sabe cómo buscar', 4), ('Por discriminación', 'Por discriminación', 5), ('Responsabilidades familiares o de cuidado', 'Responsabilidades familiares o de cuidado', 6), ('Estudia', 'Estudia', 7), ('Enfermedad o discapacidad', 'Enfermedad o discapacidad', 8), ('No necesita trabajar', 'No necesita trabajar', 9)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 226
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Si le hubiera resultado algún trabajo, ¿estaba disponible para empezar?', 'si_no', 6, 227,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · I. Fuerza de trabajo e ingresos'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuántas semanas lleva buscando trabajo?', 'numero', 7, 228,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · I. Fuerza de trabajo e ingresos'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuál es el oficio o cargo que realiza en su trabajo principal?', 'texto', 8, 229,
    'Para personas ocupadas.', NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · I. Fuerza de trabajo e ingresos'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿A qué actividad se dedica principalmente la empresa o negocio donde trabaja?', 'texto', 9, 230,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · I. Fuerza de trabajo e ingresos'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'En su trabajo principal, usted es…', 'seleccion_unica', 10, 231,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · I. Fuerza de trabajo e ingresos'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Obrero(a) o empleado(a) de empresa particular', 'Obrero(a) o empleado(a) de empresa particular', 1), ('Obrero(a) o empleado(a) del gobierno', 'Obrero(a) o empleado(a) del gobierno', 2), ('Empleado(a) doméstico(a)', 'Empleado(a) doméstico(a)', 3), ('Trabajador(a) por cuenta propia', 'Trabajador(a) por cuenta propia', 4), ('Patrón(a) o empleador(a)', 'Patrón(a) o empleador(a)', 5), ('Trabajador(a) familiar sin remuneración', 'Trabajador(a) familiar sin remuneración', 6), ('Jornalero(a) o peón', 'Jornalero(a) o peón', 7)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 231
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Tiene contrato de trabajo?', 'seleccion_unica', 11, 232,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · I. Fuerza de trabajo e ingresos'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Sí, escrito', 'Sí, escrito', 1), ('Sí, verbal', 'Sí, verbal', 2), ('No', 'No', 3)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 232
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿El contrato es a término indefinido o fijo?', 'seleccion_unica', 12, 233,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · I. Fuerza de trabajo e ingresos'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Indefinido', 'Indefinido', 1), ('Fijo', 'Fijo', 2), ('Prestación de servicios', 'Prestación de servicios', 3), ('No sabe', 'No sabe', 4)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 233
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuánto tiempo lleva trabajando en ese trabajo?', 'numero', 13, 234,
    NULL, 'meses', NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · I. Fuerza de trabajo e ingresos'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuántas horas trabaja normalmente a la semana?', 'numero', 14, 235,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · I. Fuerza de trabajo e ingresos'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Quisiera trabajar más horas?', 'si_no', 15, 236,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · I. Fuerza de trabajo e ingresos'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuántas personas tiene la empresa o negocio donde trabaja?', 'seleccion_unica', 16, 237,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · I. Fuerza de trabajo e ingresos'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Trabaja solo(a)', 'Trabaja solo(a)', 1), ('2 a 5', '2 a 5', 2), ('6 a 10', '6 a 10', 3), ('11 a 50', '11 a 50', 4), ('Más de 50', 'Más de 50', 5)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 237
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Dónde realiza principalmente su trabajo?', 'seleccion_unica', 17, 238,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · I. Fuerza de trabajo e ingresos'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('En su vivienda', 'En su vivienda', 1), ('En otras viviendas', 'En otras viviendas', 2), ('En local fijo, oficina o fábrica', 'En local fijo, oficina o fábrica', 3), ('En la calle (ambulante o estacionario)', 'En la calle (ambulante o estacionario)', 4), ('En un vehículo', 'En un vehículo', 5), ('En una obra de construcción', 'En una obra de construcción', 6), ('Puerta a puerta', 'Puerta a puerta', 7), ('Otro', 'Otro', 8)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 238
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuánto ganó el mes pasado en ese trabajo (salario o ganancia neta)?', 'numero', 18, 239,
    NULL, 'pesos', NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · I. Fuerza de trabajo e ingresos'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Está cotizando a un fondo de pensiones?', 'seleccion_unica', 19, 240,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · I. Fuerza de trabajo e ingresos'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Sí', 'Sí', 1), ('No', 'No', 2), ('Ya está pensionado(a)', 'Ya está pensionado(a)', 3)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 240
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Está afiliado(a) a una ARL (riesgos laborales)?', 'si_no', 20, 241,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · I. Fuerza de trabajo e ingresos'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Está afiliado(a) a una caja de compensación familiar?', 'si_no', 21, 242,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · I. Fuerza de trabajo e ingresos'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuál es el principal medio de transporte para ir al trabajo?', 'seleccion_unica', 22, 243,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · I. Fuerza de trabajo e ingresos'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('A pie', 'A pie', 1), ('Bicicleta', 'Bicicleta', 2), ('Metro, metrocable o bus', 'Metro, metrocable o bus', 3), ('Moto', 'Moto', 4), ('Carro particular', 'Carro particular', 5), ('Taxi o plataforma', 'Taxi o plataforma', 6), ('Trabaja en la vivienda', 'Trabaja en la vivienda', 7)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 243
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuánto tiempo tarda en llegar al trabajo?', 'numero', 23, 244,
    NULL, 'minutos', NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · I. Fuerza de trabajo e ingresos'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Además de su trabajo principal, ¿tiene otro trabajo o negocio?', 'si_no', 24, 245,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · I. Fuerza de trabajo e ingresos'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuánto ganó el mes pasado en ese segundo trabajo?', 'numero', 25, 246,
    NULL, 'pesos', NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · I. Fuerza de trabajo e ingresos'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Ha sentido discriminación en el trabajo o al buscar empleo por su color de piel?', 'si_no', 26, 247,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · I. Fuerza de trabajo e ingresos'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuántas horas a la semana dedica a oficios del hogar sin pago (cocinar, limpiar, lavar)?', 'numero', 27, 248,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · I. Fuerza de trabajo e ingresos'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuántas horas a la semana dedica a cuidar niños, adultos mayores o personas enfermas sin pago?', 'numero', 28, 249,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · I. Fuerza de trabajo e ingresos'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Recibió pensión de jubilación, vejez, invalidez o sobrevivencia?', 'si_no', 29, 250,
    'Otros ingresos (últimos 12 meses).', NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · I. Fuerza de trabajo e ingresos'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Recibió dinero por arriendos de casas, apartamentos o lotes?', 'si_no', 30, 251,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · I. Fuerza de trabajo e ingresos'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Recibió ayudas en dinero de otros hogares en Colombia?', 'si_no', 31, 252,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · I. Fuerza de trabajo e ingresos'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Recibió remesas o dinero de familiares en el exterior?', 'si_no', 32, 253,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · I. Fuerza de trabajo e ingresos'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Recibió algún subsidio o transferencia del Estado?', 'si_no', 33, 254,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · I. Fuerza de trabajo e ingresos'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuál(es) subsidio(s) recibió?', 'seleccion_multiple', 34, 255,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · I. Fuerza de trabajo e ingresos'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Renta Ciudadana / Familias en Acción', 'Renta Ciudadana / Familias en Acción', 1), ('Renta Joven / Jóvenes en Acción', 'Renta Joven / Jóvenes en Acción', 2), ('Colombia Mayor', 'Colombia Mayor', 3), ('Ayuda humanitaria a víctimas', 'Ayuda humanitaria a víctimas', 4), ('Subsidios de la Alcaldía de Medellín', 'Subsidios de la Alcaldía de Medellín', 5), ('Otro. ¿Cuál? ________', 'Otro. ¿Cuál? ________', 6)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 255
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuánto recibió en total por subsidios en los últimos 12 meses?', 'numero', 35, 256,
    NULL, 'pesos', NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · I. Fuerza de trabajo e ingresos'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Algún niño, niña o adolescente de 5 a 17 años del hogar trabajó la semana pasada (en un negocio, vendiendo, en oficios por pago)?', 'seleccion_unica', 36, 257,
    'Trabajo infantil.', NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · I. Fuerza de trabajo e ingresos'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Sí', 'Sí', 1), ('No', 'No', 2), ('No hay menores en el hogar', 'No hay menores en el hogar', 3)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 257
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Algún menor de 5 a 17 años del hogar dedica más de 15 horas a la semana a oficios del hogar?', 'seleccion_unica', 37, 258,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · I. Fuerza de trabajo e ingresos'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Sí', 'Sí', 1), ('No', 'No', 2), ('No hay menores en el hogar', 'No hay menores en el hogar', 3)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 258
ON CONFLICT DO NOTHING;

-- ---- Capítulo J: Seguridad alimentaria ----
INSERT INTO public.categoria_dss (
    nombre, orden, capitulo, orden_capitulo, nivel, objetivo, responde,
    tiempo_estimado_min, elegibilidad_edad_min, elegibilidad_edad_max,
    elegibilidad_genero, elegibilidad_jefe_hogar
) VALUES (
    'NARP-342 · J. Seguridad alimentaria', 110, 'J', 10,
    'HOGAR', 'Determinar la prevalencia de inseguridad alimentaria del hogar con la Escala Latinoamericana y Caribeña de Seguridad Alimentaria (ELCSA), y conocer los apoyos y prácticas alimentarias.', 'Jefe/a del hogar o cónyuge, o la persona responsable de la alimentación del hogar',
    4, NULL, NULL,
    NULL, TRUE
) ON CONFLICT (nombre) DO UPDATE SET
    orden = EXCLUDED.orden, capitulo = EXCLUDED.capitulo,
    orden_capitulo = EXCLUDED.orden_capitulo, nivel = EXCLUDED.nivel,
    objetivo = EXCLUDED.objetivo, responde = EXCLUDED.responde,
    tiempo_estimado_min = EXCLUDED.tiempo_estimado_min,
    elegibilidad_edad_min = EXCLUDED.elegibilidad_edad_min,
    elegibilidad_edad_max = EXCLUDED.elegibilidad_edad_max,
    elegibilidad_genero = EXCLUDED.elegibilidad_genero,
    elegibilidad_jefe_hogar = EXCLUDED.elegibilidad_jefe_hogar;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Alguna vez usted se preocupó porque los alimentos se acabaran en su hogar?', 'si_no', 1, 259,
    'En los últimos 30 días, por falta de dinero u otros recursos…', NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · J. Seguridad alimentaria'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Alguna vez en su hogar se quedaron sin alimentos?', 'si_no', 2, 260,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · J. Seguridad alimentaria'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Alguna vez en su hogar dejaron de tener una alimentación saludable y balanceada?', 'si_no', 3, 261,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · J. Seguridad alimentaria'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Alguna vez usted o algún adulto del hogar tuvo una alimentación basada en poca variedad de alimentos?', 'si_no', 4, 262,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · J. Seguridad alimentaria'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Alguna vez usted o algún adulto del hogar dejó de desayunar, almorzar o cenar?', 'si_no', 5, 263,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · J. Seguridad alimentaria'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Alguna vez usted o algún adulto del hogar comió menos de lo que debía comer?', 'si_no', 6, 264,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · J. Seguridad alimentaria'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Alguna vez usted o algún adulto del hogar sintió hambre pero no comió?', 'si_no', 7, 265,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · J. Seguridad alimentaria'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Alguna vez usted o algún adulto del hogar solo comió una vez al día o dejó de comer durante todo un día?', 'si_no', 8, 266,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · J. Seguridad alimentaria'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Alguna vez algún menor de 18 años del hogar dejó de tener una alimentación saludable y balanceada?', 'si_no', 9, 267,
    'Si en el hogar viven menores de 18 años.', NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · J. Seguridad alimentaria'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Alguna vez algún menor de 18 años del hogar tuvo una alimentación basada en poca variedad de alimentos?', 'si_no', 10, 268,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · J. Seguridad alimentaria'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Alguna vez algún menor de 18 años del hogar dejó de desayunar, almorzar o cenar?', 'si_no', 11, 269,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · J. Seguridad alimentaria'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Alguna vez algún menor de 18 años del hogar comió menos de lo que debía?', 'si_no', 12, 270,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · J. Seguridad alimentaria'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Alguna vez tuvieron que disminuir la cantidad servida en las comidas a algún menor de 18 años del hogar?', 'si_no', 13, 271,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · J. Seguridad alimentaria'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Alguna vez algún menor de 18 años del hogar sintió hambre pero no comió?', 'si_no', 14, 272,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · J. Seguridad alimentaria'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Alguna vez algún menor de 18 años del hogar solo comió una vez al día o dejó de comer durante todo un día?', 'si_no', 15, 273,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · J. Seguridad alimentaria'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuántas comidas consume al día normalmente?', 'seleccion_unica', 16, 274,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · J. Seguridad alimentaria'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Una', 'Una', 1), ('Dos', 'Dos', 2), ('Tres', 'Tres', 3), ('Más de tres', 'Más de tres', 4)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 274
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Recibe algún apoyo alimentario?', 'seleccion_multiple', 17, 275,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · J. Seguridad alimentaria'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('PAE (restaurante escolar)', 'PAE (restaurante escolar)', 1), ('Comedor comunitario', 'Comedor comunitario', 2), ('Bono o mercado (ICBF, Alcaldía u otra entidad)', 'Bono o mercado (ICBF, Alcaldía u otra entidad)', 3), ('Olla comunitaria', 'Olla comunitaria', 4), ('Ninguno', 'Ninguno', 5), ('Otro. ¿Cuál? ________', 'Otro. ¿Cuál? ________', 6)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 275
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿En el hogar siembran alimentos o tienen huerta (en la casa o comunitaria)?', 'si_no', 18, 276,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · J. Seguridad alimentaria'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Con qué frecuencia preparan comidas tradicionales de su región o cultura?', 'seleccion_unica', 19, 277,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · J. Seguridad alimentaria'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Todos los días', 'Todos los días', 1), ('Varias veces por semana', 'Varias veces por semana', 2), ('Ocasionalmente', 'Ocasionalmente', 3), ('Nunca', 'Nunca', 4)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 277
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Dónde compran principalmente los alimentos?', 'seleccion_unica', 20, 278,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · J. Seguridad alimentaria'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Tienda de barrio', 'Tienda de barrio', 1), ('Supermercado o hipermercado', 'Supermercado o hipermercado', 2), ('Plaza de mercado', 'Plaza de mercado', 3), ('Venta ambulante', 'Venta ambulante', 4), ('Los traen del territorio de origen', 'Los traen del territorio de origen', 5), ('Otro', 'Otro', 6)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 278
ON CONFLICT DO NOTHING;

-- ---- Capítulo K: Tenencia y financiación de la vivienda ----
INSERT INTO public.categoria_dss (
    nombre, orden, capitulo, orden_capitulo, nivel, objetivo, responde,
    tiempo_estimado_min, elegibilidad_edad_min, elegibilidad_edad_max,
    elegibilidad_genero, elegibilidad_jefe_hogar
) VALUES (
    'NARP-342 · K. Tenencia y financiación de la vivienda', 111, 'K', 11,
    'HOGAR', 'Establecer la condición de ocupación de la vivienda, las fuentes de financiación para su compra, los subsidios de vivienda y los gastos del hogar por la vivienda que ocupa.', 'Jefe/a del hogar o cónyuge',
    3, NULL, NULL,
    NULL, TRUE
) ON CONFLICT (nombre) DO UPDATE SET
    orden = EXCLUDED.orden, capitulo = EXCLUDED.capitulo,
    orden_capitulo = EXCLUDED.orden_capitulo, nivel = EXCLUDED.nivel,
    objetivo = EXCLUDED.objetivo, responde = EXCLUDED.responde,
    tiempo_estimado_min = EXCLUDED.tiempo_estimado_min,
    elegibilidad_edad_min = EXCLUDED.elegibilidad_edad_min,
    elegibilidad_edad_max = EXCLUDED.elegibilidad_edad_max,
    elegibilidad_genero = EXCLUDED.elegibilidad_genero,
    elegibilidad_jefe_hogar = EXCLUDED.elegibilidad_jefe_hogar;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'La vivienda que ocupa este hogar es…', 'seleccion_unica', 1, 279,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · K. Tenencia y financiación de la vivienda'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Propia, totalmente pagada', 'Propia, totalmente pagada', 1), ('Propia, la están pagando', 'Propia, la están pagando', 2), ('En arriendo o subarriendo', 'En arriendo o subarriendo', 3), ('En usufructo (prestada por un familiar u otra persona, sin pagar)', 'En usufructo (prestada por un familiar u otra persona, sin pagar)', 4), ('Posesión sin título (ocupante de hecho)', 'Posesión sin título (ocupante de hecho)', 5), ('Propiedad colectiva', 'Propiedad colectiva', 6), ('Otra', 'Otra', 7)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 279
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuánto pagan mensualmente de arriendo?', 'numero', 2, 280,
    NULL, 'pesos', NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · K. Tenencia y financiación de la vivienda'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿El arriendo incluye los servicios públicos?', 'si_no', 3, 281,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · K. Tenencia y financiación de la vivienda'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuánto pagan mensualmente de cuota de amortización?', 'numero', 4, 282,
    NULL, 'pesos', NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · K. Tenencia y financiación de la vivienda'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Si tuviera que pagar arriendo por esta vivienda, ¿cuánto estima que pagaría al mes?', 'numero', 5, 283,
    NULL, 'pesos', NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · K. Tenencia y financiación de la vivienda'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cómo adquirieron la vivienda principalmente?', 'seleccion_unica', 6, 284,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · K. Tenencia y financiación de la vivienda'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Con ahorros propios', 'Con ahorros propios', 1), ('Con crédito hipotecario', 'Con crédito hipotecario', 2), ('Con subsidio de vivienda', 'Con subsidio de vivienda', 3), ('Por herencia o donación', 'Por herencia o donación', 4), ('La construyeron por etapas (autoconstrucción)', 'La construyeron por etapas (autoconstrucción)', 5), ('Otra', 'Otra', 6)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 284
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Tienen escritura registrada o título de la vivienda?', 'seleccion_unica', 7, 285,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · K. Tenencia y financiación de la vivienda'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Sí', 'Sí', 1), ('No', 'No', 2), ('No sabe', 'No sabe', 3)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 285
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Algún miembro del hogar ha recibido subsidio de vivienda del gobierno?', 'si_no', 8, 286,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · K. Tenencia y financiación de la vivienda'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Qué entidad otorgó el subsidio?', 'seleccion_unica', 9, 287,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · K. Tenencia y financiación de la vivienda'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Caja de compensación', 'Caja de compensación', 1), ('Gobierno nacional (Mi Casa Ya, Fonvivienda)', 'Gobierno nacional (Mi Casa Ya, Fonvivienda)', 2), ('ISVIMED / Alcaldía', 'ISVIMED / Alcaldía', 3), ('Otra', 'Otra', 4)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 287
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Algún miembro del hogar está postulado actualmente a un subsidio de vivienda?', 'si_no', 10, 288,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · K. Tenencia y financiación de la vivienda'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'En los últimos 5 años, ¿el hogar ha sido desalojado o ha tenido que dejar la vivienda contra su voluntad?', 'si_no', 11, 289,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · K. Tenencia y financiación de la vivienda'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuánto pagaron el año pasado de impuesto predial?', 'numero', 12, 290,
    NULL, 'pesos', NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · K. Tenencia y financiación de la vivienda'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿La vivienda necesita mejoras urgentes (techo, pisos, baño, cocina, estructura)?', 'seleccion_multiple', 13, 291,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · K. Tenencia y financiación de la vivienda'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Techo', 'Techo', 1), ('Pisos', 'Pisos', 2), ('Baño', 'Baño', 3), ('Cocina', 'Cocina', 4), ('Estructura o muros', 'Estructura o muros', 5), ('No necesita', 'No necesita', 6)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 291
ON CONFLICT DO NOTHING;

-- ---- Capítulo L: Condiciones de vida del hogar y tenencia de bienes ----
INSERT INTO public.categoria_dss (
    nombre, orden, capitulo, orden_capitulo, nivel, objetivo, responde,
    tiempo_estimado_min, elegibilidad_edad_min, elegibilidad_edad_max,
    elegibilidad_genero, elegibilidad_jefe_hogar
) VALUES (
    'NARP-342 · L. Condiciones de vida del hogar y tenencia de bienes', 112, 'L', 12,
    'HOGAR', 'Conocer la percepción de pobreza e inseguridad, los eventos que producen tensión o preocupación, la capacidad de los ingresos para cubrir los gastos mínimos y los bienes que posee el hogar.', 'Jefe/a del hogar o cónyuge',
    6, NULL, NULL,
    NULL, TRUE
) ON CONFLICT (nombre) DO UPDATE SET
    orden = EXCLUDED.orden, capitulo = EXCLUDED.capitulo,
    orden_capitulo = EXCLUDED.orden_capitulo, nivel = EXCLUDED.nivel,
    objetivo = EXCLUDED.objetivo, responde = EXCLUDED.responde,
    tiempo_estimado_min = EXCLUDED.tiempo_estimado_min,
    elegibilidad_edad_min = EXCLUDED.elegibilidad_edad_min,
    elegibilidad_edad_max = EXCLUDED.elegibilidad_edad_max,
    elegibilidad_genero = EXCLUDED.elegibilidad_genero,
    elegibilidad_jefe_hogar = EXCLUDED.elegibilidad_jefe_hogar;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Usted se considera pobre?', 'si_no', 1, 292,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · L. Condiciones de vida del hogar y tenencia de bienes'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Los ingresos de su hogar…', 'seleccion_unica', 2, 293,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · L. Condiciones de vida del hogar y tenencia de bienes'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('No alcanzan para cubrir los gastos mínimos', 'No alcanzan para cubrir los gastos mínimos', 1), ('Solo alcanzan para cubrir los gastos mínimos', 'Solo alcanzan para cubrir los gastos mínimos', 2), ('Cubren más que los gastos mínimos', 'Cubren más que los gastos mínimos', 3)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 293
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Las condiciones de vida de su hogar, comparadas con las de hace 5 años, son…', 'seleccion_unica', 3, 294,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · L. Condiciones de vida del hogar y tenencia de bienes'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Mejores', 'Mejores', 1), ('Iguales', 'Iguales', 2), ('Peores', 'Peores', 3)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 294
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'La situación económica de su hogar, comparada con la de hace 12 meses, es…', 'seleccion_unica', 4, 295,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · L. Condiciones de vida del hogar y tenencia de bienes'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Mucho mejor', 'Mucho mejor', 1), ('Mejor', 'Mejor', 2), ('Igual', 'Igual', 3), ('Peor', 'Peor', 4), ('Mucho peor', 'Mucho peor', 5)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 295
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cómo cree que será la situación económica de su hogar dentro de 12 meses?', 'seleccion_unica', 5, 296,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · L. Condiciones de vida del hogar y tenencia de bienes'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Mucho mejor', 'Mucho mejor', 1), ('Mejor', 'Mejor', 2), ('Igual', 'Igual', 3), ('Peor', 'Peor', 4), ('Mucho peor', 'Mucho peor', 5)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 296
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Qué tan seguro(a) se siente en su barrio?', 'seleccion_unica', 6, 297,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · L. Condiciones de vida del hogar y tenencia de bienes'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Muy seguro', 'Muy seguro', 1), ('Seguro', 'Seguro', 2), ('Inseguro', 'Inseguro', 3), ('Muy inseguro', 'Muy inseguro', 4)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 297
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuáles de estos problemas de seguridad se presentan en su barrio?', 'seleccion_multiple', 7, 298,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · L. Condiciones de vida del hogar y tenencia de bienes'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Hurtos o atracos', 'Hurtos o atracos', 1), ('Extorsión o cobro de "vacunas"', 'Extorsión o cobro de "vacunas"', 2), ('Fronteras invisibles', 'Fronteras invisibles', 3), ('Presencia de grupos armados o combos', 'Presencia de grupos armados o combos', 4), ('Reclutamiento de jóvenes', 'Reclutamiento de jóvenes', 5), ('Venta o consumo de drogas', 'Venta o consumo de drogas', 6), ('Riñas o violencia', 'Riñas o violencia', 7), ('Abuso policial', 'Abuso policial', 8), ('Ninguno', 'Ninguno', 9)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 298
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'En los últimos 12 meses, ¿usted o alguien del hogar fue víctima de algún delito?', 'si_no', 8, 299,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · L. Condiciones de vida del hogar y tenencia de bienes'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Denunciaron el hecho ante las autoridades?', 'si_no', 9, 300,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · L. Condiciones de vida del hogar y tenencia de bienes'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'En los últimos 12 meses, ¿cuáles de estos eventos afectaron al hogar?', 'seleccion_multiple', 10, 301,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · L. Condiciones de vida del hogar y tenencia de bienes'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Pérdida del empleo de algún miembro', 'Pérdida del empleo de algún miembro', 1), ('Quiebra o cierre de negocio', 'Quiebra o cierre de negocio', 2), ('Enfermedad grave o accidente', 'Enfermedad grave o accidente', 3), ('Muerte de un miembro del hogar', 'Muerte de un miembro del hogar', 4), ('Desplazamiento forzado o amenaza', 'Desplazamiento forzado o amenaza', 5), ('Desastre natural', 'Desastre natural', 6), ('Separación de la pareja', 'Separación de la pareja', 7), ('Embarazo no planeado', 'Embarazo no planeado', 8), ('Endeudamiento grave', 'Endeudamiento grave', 9), ('Ninguno', 'Ninguno', 10)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 301
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Qué hizo el hogar para enfrentar esas dificultades?', 'seleccion_multiple', 11, 302,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · L. Condiciones de vida del hogar y tenencia de bienes'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Pidió prestado a familiares o amigos', 'Pidió prestado a familiares o amigos', 1), ('Pidió préstamo "gota a gota"', 'Pidió préstamo "gota a gota"', 2), ('Vendió o empeñó bienes', 'Vendió o empeñó bienes', 3), ('Redujo gastos en alimentación', 'Redujo gastos en alimentación', 4), ('Sacó a algún miembro del estudio', 'Sacó a algún miembro del estudio', 5), ('Otro miembro se puso a trabajar', 'Otro miembro se puso a trabajar', 6), ('Pidió ayuda al Estado o una ONG', 'Pidió ayuda al Estado o una ONG', 7), ('Nada', 'Nada', 8)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 302
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Qué bienes tiene el hogar?', 'seleccion_multiple', 12, 303,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · L. Condiciones de vida del hogar y tenencia de bienes'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Nevera', 'Nevera', 1), ('Lavadora', 'Lavadora', 2), ('Estufa eléctrica o de gas', 'Estufa eléctrica o de gas', 3), ('Horno microondas', 'Horno microondas', 4), ('Televisor', 'Televisor', 5), ('Equipo de sonido', 'Equipo de sonido', 6), ('Computador de escritorio', 'Computador de escritorio', 7), ('Computador portátil', 'Computador portátil', 8), ('Tableta', 'Tableta', 9), ('Motocicleta', 'Motocicleta', 10), ('Carro particular', 'Carro particular', 11), ('Bicicleta', 'Bicicleta', 12), ('Ventilador', 'Ventilador', 13), ('Ninguno', 'Ninguno', 14)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 303
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Algún miembro del hogar tiene cuenta de ahorros, cuenta bancaria o billetera digital (Nequi, Daviplata)?', 'si_no', 13, 304,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · L. Condiciones de vida del hogar y tenencia de bienes'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿El hogar tiene ahorros para enfrentar una emergencia?', 'si_no', 14, 305,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · L. Condiciones de vida del hogar y tenencia de bienes'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿El hogar tiene deudas actualmente?', 'si_no', 15, 306,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · L. Condiciones de vida del hogar y tenencia de bienes'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Con quién tiene esas deudas?', 'seleccion_multiple', 16, 307,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · L. Condiciones de vida del hogar y tenencia de bienes'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Banco o cooperativa', 'Banco o cooperativa', 1), ('Tienda del barrio (fiado)', 'Tienda del barrio (fiado)', 2), ('Prestamista "gota a gota"', 'Prestamista "gota a gota"', 3), ('Familiares o amigos', 'Familiares o amigos', 4), ('Almacenes o tarjetas de crédito', 'Almacenes o tarjetas de crédito', 5), ('Otro', 'Otro', 6)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 307
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'En los últimos 12 meses, ¿solicitó un crédito a una entidad financiera?', 'si_no', 17, 308,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · L. Condiciones de vida del hogar y tenencia de bienes'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Le aprobaron el crédito?', 'si_no', 18, 309,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · L. Condiciones de vida del hogar y tenencia de bienes'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Qué tanta confianza tiene en las personas de su barrio?', 'seleccion_unica', 19, 310,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · L. Condiciones de vida del hogar y tenencia de bienes'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Mucha', 'Mucha', 1), ('Alguna', 'Alguna', 2), ('Poca', 'Poca', 3), ('Ninguna', 'Ninguna', 4)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 310
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Participa en alguna organización comunitaria, Junta de Acción Comunal, grupo cultural o religioso?', 'si_no', 20, 311,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · L. Condiciones de vida del hogar y tenencia de bienes'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Qué tan satisfecho(a) está con los espacios públicos, parques y zonas verdes del barrio?', 'escala', 21, 312,
    NULL, NULL, 0, 10
FROM public.categoria_dss WHERE nombre = 'NARP-342 · L. Condiciones de vida del hogar y tenencia de bienes'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Qué tan satisfecho(a) está con el transporte público de su sector?', 'escala', 22, 313,
    NULL, NULL, 0, 10
FROM public.categoria_dss WHERE nombre = 'NARP-342 · L. Condiciones de vida del hogar y tenencia de bienes'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;

-- ---- Capítulo M: Gastos e ingresos del hogar ----
INSERT INTO public.categoria_dss (
    nombre, orden, capitulo, orden_capitulo, nivel, objetivo, responde,
    tiempo_estimado_min, elegibilidad_edad_min, elegibilidad_edad_max,
    elegibilidad_genero, elegibilidad_jefe_hogar
) VALUES (
    'NARP-342 · M. Gastos e ingresos del hogar', 113, 'M', 13,
    'HOGAR', 'Captar el nivel y la estructura del gasto del hogar por grupos de bienes y servicios, y su capacidad de ingreso, para analizar el bienestar.', 'Jefe/a del hogar o cónyuge. Valores aproximados en pesos, por mes',
    8, NULL, NULL,
    NULL, TRUE
) ON CONFLICT (nombre) DO UPDATE SET
    orden = EXCLUDED.orden, capitulo = EXCLUDED.capitulo,
    orden_capitulo = EXCLUDED.orden_capitulo, nivel = EXCLUDED.nivel,
    objetivo = EXCLUDED.objetivo, responde = EXCLUDED.responde,
    tiempo_estimado_min = EXCLUDED.tiempo_estimado_min,
    elegibilidad_edad_min = EXCLUDED.elegibilidad_edad_min,
    elegibilidad_edad_max = EXCLUDED.elegibilidad_edad_max,
    elegibilidad_genero = EXCLUDED.elegibilidad_genero,
    elegibilidad_jefe_hogar = EXCLUDED.elegibilidad_jefe_hogar;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Gasto mensual del hogar en alimentos y bebidas', 'numero', 1, 314,
    NULL, 'pesos', NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · M. Gastos e ingresos del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Gasto mensual en comidas fuera del hogar', 'numero', 2, 315,
    NULL, 'pesos', NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · M. Gastos e ingresos del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Gasto mensual en transporte', 'numero', 3, 316,
    NULL, 'pesos', NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · M. Gastos e ingresos del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Gasto mensual en arriendo o cuota de vivienda', 'numero', 4, 317,
    NULL, 'pesos', NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · M. Gastos e ingresos del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Gasto mensual en servicios públicos', 'numero', 5, 318,
    NULL, 'pesos', NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · M. Gastos e ingresos del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Gasto mensual en celular e internet', 'numero', 6, 319,
    NULL, 'pesos', NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · M. Gastos e ingresos del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Gasto mensual en educación', 'numero', 7, 320,
    NULL, 'pesos', NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · M. Gastos e ingresos del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Gasto mensual en salud y medicamentos', 'numero', 8, 321,
    NULL, 'pesos', NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · M. Gastos e ingresos del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Gasto mensual en artículos de aseo personal y del hogar', 'numero', 9, 322,
    NULL, 'pesos', NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · M. Gastos e ingresos del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Gasto mensual en vestuario y calzado', 'numero', 10, 323,
    NULL, 'pesos', NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · M. Gastos e ingresos del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Gasto mensual en recreación y cultura', 'numero', 11, 324,
    NULL, 'pesos', NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · M. Gastos e ingresos del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Gasto mensual en pago de deudas', 'numero', 12, 325,
    NULL, 'pesos', NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · M. Gastos e ingresos del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Dinero que el hogar envía al mes a familiares en otros lugares', 'numero', 13, 326,
    NULL, 'pesos', NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · M. Gastos e ingresos del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuántas personas del hogar aportan dinero para los gastos?', 'numero', 14, 327,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · M. Gastos e ingresos del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, 'Ingreso total mensual aproximado del hogar', 'seleccion_unica', 15, 328,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · M. Gastos e ingresos del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Menos de medio salario mínimo', 'Menos de medio salario mínimo', 1), ('Entre medio y 1 salario mínimo', 'Entre medio y 1 salario mínimo', 2), ('Entre 1 y 2 salarios mínimos', 'Entre 1 y 2 salarios mínimos', 3), ('Entre 2 y 3 salarios mínimos', 'Entre 2 y 3 salarios mínimos', 4), ('Más de 3 salarios mínimos', 'Más de 3 salarios mínimos', 5), ('No sabe / no responde', 'No sabe / no responde', 6)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 328
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuál es la principal fuente de ingreso del hogar?', 'seleccion_unica', 16, 329,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · M. Gastos e ingresos del hogar'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Salario de empleo formal', 'Salario de empleo formal', 1), ('Trabajo independiente o informal', 'Trabajo independiente o informal', 2), ('Pensión', 'Pensión', 3), ('Subsidios del Estado', 'Subsidios del Estado', 4), ('Ayudas de familiares', 'Ayudas de familiares', 5), ('Arriendos', 'Arriendos', 6), ('Otra', 'Otra', 7)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 329
ON CONFLICT DO NOTHING;

-- ---- Capítulo N: Territorio de origen y vida comunitaria ----
INSERT INTO public.categoria_dss (
    nombre, orden, capitulo, orden_capitulo, nivel, objetivo, responde,
    tiempo_estimado_min, elegibilidad_edad_min, elegibilidad_edad_max,
    elegibilidad_genero, elegibilidad_jefe_hogar
) VALUES (
    'NARP-342 · N. Territorio de origen y vida comunitaria', 114, 'N', 14,
    'HOGAR', 'Adaptación del componente rural de la ECV a la población NARP urbana: indagar la relación del hogar con la tierra y el territorio de origen, las actividades productivas tradicionales y la pervivencia cultural.', 'Jefe/a del hogar o cónyuge',
    3, NULL, NULL,
    NULL, TRUE
) ON CONFLICT (nombre) DO UPDATE SET
    orden = EXCLUDED.orden, capitulo = EXCLUDED.capitulo,
    orden_capitulo = EXCLUDED.orden_capitulo, nivel = EXCLUDED.nivel,
    objetivo = EXCLUDED.objetivo, responde = EXCLUDED.responde,
    tiempo_estimado_min = EXCLUDED.tiempo_estimado_min,
    elegibilidad_edad_min = EXCLUDED.elegibilidad_edad_min,
    elegibilidad_edad_max = EXCLUDED.elegibilidad_edad_max,
    elegibilidad_genero = EXCLUDED.elegibilidad_genero,
    elegibilidad_jefe_hogar = EXCLUDED.elegibilidad_jefe_hogar;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Su familia tiene tierras en su territorio de origen?', 'seleccion_unica', 1, 330,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · N. Territorio de origen y vida comunitaria'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Sí', 'Sí', 1), ('No', 'No', 2), ('No sabe', 'No sabe', 3)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 330
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuál es la forma de tenencia de esas tierras?', 'seleccion_unica', 2, 331,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · N. Territorio de origen y vida comunitaria'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Título colectivo de consejo comunitario', 'Título colectivo de consejo comunitario', 1), ('Título individual (escritura)', 'Título individual (escritura)', 2), ('Posesión sin título', 'Posesión sin título', 3), ('Tierras abandonadas o despojadas', 'Tierras abandonadas o despojadas', 4), ('No sabe', 'No sabe', 5)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 331
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Alguien del hogar realiza actividades agrícolas, pesqueras o de minería artesanal (aquí o en el territorio)?', 'si_no', 3, 332,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · N. Territorio de origen y vida comunitaria'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿El hogar cría animales (gallinas, cerdos u otros)?', 'si_no', 4, 333,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · N. Territorio de origen y vida comunitaria'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿El hogar recibe productos (alimentos, pescado, frutas) enviados desde el territorio de origen?', 'si_no', 5, 334,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · N. Territorio de origen y vida comunitaria'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Le gustaría retornar a su territorio de origen?', 'seleccion_unica', 6, 335,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · N. Territorio de origen y vida comunitaria'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Sí', 'Sí', 1), ('No', 'No', 2), ('No sabe', 'No sabe', 3), ('Nació en Medellín', 'Nació en Medellín', 4)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 335
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuál es la principal razón por la que no ha retornado?', 'seleccion_unica', 7, 336,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · N. Territorio de origen y vida comunitaria'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Inseguridad o conflicto armado', 'Inseguridad o conflicto armado', 1), ('Falta de oportunidades económicas', 'Falta de oportunidades económicas', 2), ('Estudio o trabajo de los hijos', 'Estudio o trabajo de los hijos', 3), ('Falta de servicios (salud, educación)', 'Falta de servicios (salud, educación)', 4), ('Ya hizo su vida en Medellín', 'Ya hizo su vida en Medellín', 5), ('Otra', 'Otra', 6)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 336
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Alguien del hogar practica expresiones culturales afro (música, danza, peinados, gastronomía, oralidad)?', 'si_no', 8, 337,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · N. Territorio de origen y vida comunitaria'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Cuáles prácticas se mantienen en el hogar?', 'seleccion_multiple', 9, 338,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · N. Territorio de origen y vida comunitaria'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Música y danza tradicional', 'Música y danza tradicional', 1), ('Peinados y estética afro', 'Peinados y estética afro', 2), ('Cocina tradicional', 'Cocina tradicional', 3), ('Alabaos, gualíes o ritos fúnebres', 'Alabaos, gualíes o ritos fúnebres', 4), ('Medicina tradicional y partería', 'Medicina tradicional y partería', 5), ('Lengua propia', 'Lengua propia', 6), ('Fiestas patronales y celebraciones', 'Fiestas patronales y celebraciones', 7), ('Ninguna', 'Ninguna', 8)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 338
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Se transmiten estos saberes a los niños y jóvenes del hogar?', 'seleccion_unica', 10, 339,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · N. Territorio de origen y vida comunitaria'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Sí, con frecuencia', 'Sí, con frecuencia', 1), ('A veces', 'A veces', 2), ('No', 'No', 3)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 339
ON CONFLICT DO NOTHING;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Participa en espacios de la población afro en Medellín (Mesa Afro, Consultiva, organizaciones)?', 'si_no', 11, 340,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · N. Territorio de origen y vida comunitaria'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Qué necesidades prioritarias tiene su hogar que la Mesa Afro debería conocer?', 'texto', 12, 341,
    NULL, NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · N. Territorio de origen y vida comunitaria'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;

-- ---- Capítulo CONS: Consentimiento informado ----
INSERT INTO public.categoria_dss (
    nombre, orden, capitulo, orden_capitulo, nivel, objetivo, responde,
    tiempo_estimado_min, elegibilidad_edad_min, elegibilidad_edad_max,
    elegibilidad_genero, elegibilidad_jefe_hogar
) VALUES (
    'NARP-342 · Consentimiento informado', 115, 'CONS', 15,
    'PERSONA', 'Tratamiento de datos e imagen.', 'Todas las personas (o su acudiente, si es menor de edad)',
    2, NULL, NULL,
    NULL, FALSE
) ON CONFLICT (nombre) DO UPDATE SET
    orden = EXCLUDED.orden, capitulo = EXCLUDED.capitulo,
    orden_capitulo = EXCLUDED.orden_capitulo, nivel = EXCLUDED.nivel,
    objetivo = EXCLUDED.objetivo, responde = EXCLUDED.responde,
    tiempo_estimado_min = EXCLUDED.tiempo_estimado_min,
    elegibilidad_edad_min = EXCLUDED.elegibilidad_edad_min,
    elegibilidad_edad_max = EXCLUDED.elegibilidad_edad_max,
    elegibilidad_genero = EXCLUDED.elegibilidad_genero,
    elegibilidad_jefe_hogar = EXCLUDED.elegibilidad_jefe_hogar;
INSERT INTO public.pregunta_dss (
    id_categoria, texto_pregunta, tipo_respuesta, orden, numero_pregunta,
    nota, unidad, escala_min, escala_max
) SELECT id_categoria, '¿Acepta el tratamiento de sus datos?', 'seleccion_unica', 1, 342,
    'Con el diligenciamiento de este formulario autorizo de forma voluntaria y expresa que la Mesa Afro registre mi información y la almacene en su base de datos, y a su vez tome o capte imágenes, grabaciones y/o audios, consintiendo su difusión y su incorporación posterior en páginas web, folletos o informes, sin que por ello tenga derecho a recibir contraprestación alguna y sin que exista un plazo limitado para su utilización, todo ello sin perjuicio de mi derecho a revocar este consentimiento en cualquier momento. En caso de ser menor de edad, expreso que cuento con la autorización de una persona adulta responsable para mi participación en la instancia de participación y sus actividades, teniendo en cuenta que se recolectará material audiovisual con fines divulgativos. Por lo anterior, declaro que he sido informada/o/e y consiento expresamente que los datos de carácter personal que de forma voluntaria aporto a la Mesa Afro pasen a formar parte de su archivo.', NULL, NULL, NULL
FROM public.categoria_dss WHERE nombre = 'NARP-342 · Consentimiento informado'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET
    tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden,
    numero_pregunta = EXCLUDED.numero_pregunta, nota = EXCLUDED.nota,
    unidad = EXCLUDED.unidad, escala_min = EXCLUDED.escala_min,
    escala_max = EXCLUDED.escala_max;
INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p
CROSS JOIN (VALUES ('Acepto', 'Acepto', 1), ('No acepto', 'No acepto', 2)) AS v(texto, valor, orden)
WHERE p.numero_pregunta = 342
ON CONFLICT DO NOTHING;

-- 5) Condicionales entre preguntas (se despliega si…) -----------------------
-- EQ/NEQ/IN comparan contra la respuesta de otra pregunta (por número);
-- GT0 exige que la respuesta numérica de esa pregunta sea mayor que 0.
UPDATE public.pregunta_dss SET condicion_edad_operador = 'LT', condicion_edad_valor = 18 WHERE numero_pregunta = 20;
UPDATE public.pregunta_dss SET condicion_edad_operador = 'LT', condicion_edad_valor = 18 WHERE numero_pregunta = 21;
UPDATE public.pregunta_dss SET condicion_edad_operador = 'LT', condicion_edad_valor = 18 WHERE numero_pregunta = 22;
UPDATE public.pregunta_dss SET condicion_edad_operador = 'LT', condicion_edad_valor = 18 WHERE numero_pregunta = 23;
UPDATE public.pregunta_dss SET condicion_edad_operador = 'LT', condicion_edad_valor = 18 WHERE numero_pregunta = 24;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 31 AND dep.numero_pregunta = 30;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 33 AND dep.numero_pregunta = 32;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 34 AND dep.numero_pregunta = 32;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 38 AND dep.numero_pregunta = 37;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 74 AND dep.numero_pregunta = 73;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'NEQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 98 AND dep.numero_pregunta = 97;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'NEQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 100 AND dep.numero_pregunta = 99;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 104 AND dep.numero_pregunta = 103;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 105 AND dep.numero_pregunta = 103;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 108 AND dep.numero_pregunta = 107;
UPDATE public.pregunta_dss SET condicion_edad_operador = 'GTE', condicion_edad_valor = 15 WHERE numero_pregunta = 109;
UPDATE public.pregunta_dss SET condicion_edad_operador = 'GTE', condicion_edad_valor = 15 WHERE numero_pregunta = 110;
UPDATE public.pregunta_dss SET condicion_edad_operador = 'GTE', condicion_edad_valor = 15 WHERE numero_pregunta = 111;
UPDATE public.pregunta_dss SET condicion_edad_operador = 'GTE', condicion_edad_valor = 15 WHERE numero_pregunta = 112;
UPDATE public.pregunta_dss SET condicion_edad_operador = 'GTE', condicion_edad_valor = 15 WHERE numero_pregunta = 113;
UPDATE public.pregunta_dss SET condicion_edad_operador = 'GTE', condicion_edad_valor = 15 WHERE numero_pregunta = 114;
UPDATE public.pregunta_dss SET condicion_edad_operador = 'GTE', condicion_edad_valor = 15 WHERE numero_pregunta = 115;
UPDATE public.pregunta_dss SET condicion_edad_operador = 'GTE', condicion_edad_valor = 15 WHERE numero_pregunta = 116;
UPDATE public.pregunta_dss SET condicion_edad_operador = 'GTE', condicion_edad_valor = 15 WHERE numero_pregunta = 117;
UPDATE public.pregunta_dss SET condicion_edad_operador = 'GTE', condicion_edad_valor = 15 WHERE numero_pregunta = 118;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 120 AND dep.numero_pregunta = 119;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 121 AND dep.numero_pregunta = 119;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Contributivo' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 122 AND dep.numero_pregunta = 120;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'No' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 123 AND dep.numero_pregunta = 119;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 126 AND dep.numero_pregunta = 125;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 127 AND dep.numero_pregunta = 125;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 129 AND dep.numero_pregunta = 128;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'No hizo nada' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 130 AND dep.numero_pregunta = 129;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 148 AND dep.numero_pregunta = 147;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 149 AND dep.numero_pregunta = 147;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'GT0', condicion_valor = '' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 162 AND dep.numero_pregunta = 161;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Asiste a un hogar comunitario, jardín, CDI o preescolar' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 163 AND dep.numero_pregunta = 162;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Asiste a un hogar comunitario, jardín, CDI o preescolar' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 164 AND dep.numero_pregunta = 162;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Asiste a un hogar comunitario, jardín, CDI o preescolar' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 165 AND dep.numero_pregunta = 162;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Asiste a un hogar comunitario, jardín, CDI o preescolar' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 166 AND dep.numero_pregunta = 162;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Asiste a un hogar comunitario, jardín, CDI o preescolar' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 167 AND dep.numero_pregunta = 162;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'NEQ', condicion_valor = 'Asiste a un hogar comunitario, jardín, CDI o preescolar' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 168 AND dep.numero_pregunta = 162;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'GT0', condicion_valor = '' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 169 AND dep.numero_pregunta = 161;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'GT0', condicion_valor = '' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 170 AND dep.numero_pregunta = 161;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'GT0', condicion_valor = '' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 171 AND dep.numero_pregunta = 161;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'GT0', condicion_valor = '' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 172 AND dep.numero_pregunta = 161;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'GT0', condicion_valor = '' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 173 AND dep.numero_pregunta = 161;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'GT0', condicion_valor = '' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 174 AND dep.numero_pregunta = 161;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'GT0', condicion_valor = '' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 175 AND dep.numero_pregunta = 161;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'GT0', condicion_valor = '' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 176 AND dep.numero_pregunta = 161;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'GT0', condicion_valor = '' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 177 AND dep.numero_pregunta = 161;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'GT0', condicion_valor = '' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 178 AND dep.numero_pregunta = 161;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 180 AND dep.numero_pregunta = 179;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 181 AND dep.numero_pregunta = 179;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 182 AND dep.numero_pregunta = 179;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 183 AND dep.numero_pregunta = 179;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 184 AND dep.numero_pregunta = 179;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 185 AND dep.numero_pregunta = 179;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 186 AND dep.numero_pregunta = 179;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 189 AND dep.numero_pregunta = 188;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 193 AND dep.numero_pregunta = 192;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 194 AND dep.numero_pregunta = 192;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 195 AND dep.numero_pregunta = 192;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 196 AND dep.numero_pregunta = 192;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 197 AND dep.numero_pregunta = 192;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'IN', condicion_valor = 'Técnica profesional|Tecnológica|Universitaria|Especialización|Maestría o doctorado' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 198 AND dep.numero_pregunta = 193;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 199 AND dep.numero_pregunta = 192;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 200 AND dep.numero_pregunta = 192;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'IN', condicion_valor = 'Preescolar|Básica primaria (1.° a 5.°)|Básica secundaria (6.° a 9.°)|Media (10.° a 11.°)' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 201 AND dep.numero_pregunta = 193;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 203 AND dep.numero_pregunta = 202;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'No' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 206 AND dep.numero_pregunta = 192;
UPDATE public.pregunta_dss SET condicion_edad_operador = 'LT', condicion_edad_valor = 18 WHERE numero_pregunta = 213;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 217 AND dep.numero_pregunta = 216;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 218 AND dep.numero_pregunta = 216;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 219 AND dep.numero_pregunta = 216;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'No' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 226 AND dep.numero_pregunta = 225;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 229 AND dep.numero_pregunta = 223;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 230 AND dep.numero_pregunta = 223;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 231 AND dep.numero_pregunta = 223;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 232 AND dep.numero_pregunta = 223;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'IN', condicion_valor = 'Sí, escrito|Sí, verbal' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 233 AND dep.numero_pregunta = 232;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 234 AND dep.numero_pregunta = 223;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 235 AND dep.numero_pregunta = 223;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 236 AND dep.numero_pregunta = 223;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 237 AND dep.numero_pregunta = 223;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 238 AND dep.numero_pregunta = 223;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 239 AND dep.numero_pregunta = 223;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 240 AND dep.numero_pregunta = 223;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 241 AND dep.numero_pregunta = 223;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 242 AND dep.numero_pregunta = 223;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 243 AND dep.numero_pregunta = 223;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 244 AND dep.numero_pregunta = 223;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 245 AND dep.numero_pregunta = 223;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 246 AND dep.numero_pregunta = 245;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 255 AND dep.numero_pregunta = 254;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'GT0', condicion_valor = '' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 267 AND dep.numero_pregunta = 94;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'GT0', condicion_valor = '' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 268 AND dep.numero_pregunta = 94;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'GT0', condicion_valor = '' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 269 AND dep.numero_pregunta = 94;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'GT0', condicion_valor = '' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 270 AND dep.numero_pregunta = 94;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'GT0', condicion_valor = '' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 271 AND dep.numero_pregunta = 94;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'GT0', condicion_valor = '' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 272 AND dep.numero_pregunta = 94;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'GT0', condicion_valor = '' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 273 AND dep.numero_pregunta = 94;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'En arriendo o subarriendo' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 280 AND dep.numero_pregunta = 279;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'En arriendo o subarriendo' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 281 AND dep.numero_pregunta = 279;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Propia, la están pagando' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 282 AND dep.numero_pregunta = 279;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'IN', condicion_valor = 'Propia, totalmente pagada|Propia, la están pagando|En usufructo (prestada por un familiar u otra persona, sin pagar)' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 283 AND dep.numero_pregunta = 279;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'IN', condicion_valor = 'Propia, totalmente pagada|Propia, la están pagando' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 284 AND dep.numero_pregunta = 279;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'IN', condicion_valor = 'Propia, totalmente pagada|Propia, la están pagando' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 285 AND dep.numero_pregunta = 279;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 287 AND dep.numero_pregunta = 286;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'IN', condicion_valor = 'Propia, totalmente pagada|Propia, la están pagando' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 290 AND dep.numero_pregunta = 279;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 300 AND dep.numero_pregunta = 299;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'NEQ', condicion_valor = 'Ninguno' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 302 AND dep.numero_pregunta = 301;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 307 AND dep.numero_pregunta = 306;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 309 AND dep.numero_pregunta = 308;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 331 AND dep.numero_pregunta = 330;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'IN', condicion_valor = 'Sí|No sabe' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 336 AND dep.numero_pregunta = 335;
UPDATE public.pregunta_dss p SET condicion_pregunta_id = dep.id_pregunta, condicion_operador = 'EQ', condicion_valor = 'Sí' FROM public.pregunta_dss dep WHERE p.numero_pregunta = 338 AND dep.numero_pregunta = 337;

COMMIT;

-- Verificación (ejecútala después del COMMIT):
-- SELECT capitulo, count(*) FROM pregunta_dss p JOIN categoria_dss c ON c.id_categoria = p.id_categoria
--   WHERE c.capitulo IS NOT NULL GROUP BY capitulo ORDER BY capitulo;
-- SELECT count(*) FROM pregunta_dss WHERE numero_pregunta IS NOT NULL;  -- debe dar 342
