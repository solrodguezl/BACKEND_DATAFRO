-- ASISTIR / DATAFRO: catálogo de caracterización NARP (HU-02). Idempotente: se puede
-- correr muchas veces. Agrega orden a categoria_dss/opcion_respuesta (no existía) y
-- siembra categorías, preguntas y opciones a partir del Formulario_Caracterizacion_NARP
-- (14 secciones; la sección 1 "Datos de identificación" ya vive en la tabla persona y
-- se reutiliza desde el módulo de asistencia, por eso no se repite aquí).

ALTER TABLE public.categoria_dss ADD COLUMN IF NOT EXISTS orden integer NOT NULL DEFAULT 0;
ALTER TABLE public.opcion_respuesta ADD COLUMN IF NOT EXISTS orden integer NOT NULL DEFAULT 0;

CREATE UNIQUE INDEX IF NOT EXISTS categoria_dss_nombre_uidx ON public.categoria_dss (nombre);
CREATE UNIQUE INDEX IF NOT EXISTS pregunta_dss_categoria_texto_uidx ON public.pregunta_dss (id_categoria, texto_pregunta);
CREATE UNIQUE INDEX IF NOT EXISTS opcion_respuesta_pregunta_texto_uidx ON public.opcion_respuesta (id_pregunta, texto_opcion);

-- ============ 2. Datos del acudiente (solo menores de edad) ============
INSERT INTO public.categoria_dss (nombre, orden) VALUES ('Datos del acudiente (menores de edad)', 2)
ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;

INSERT INTO public.pregunta_dss (id_categoria, texto_pregunta, tipo_respuesta, orden)
SELECT c.id_categoria, v.texto, v.tipo, v.orden
FROM public.categoria_dss c
CROSS JOIN (VALUES
  ('Nombre completo del acudiente', 'texto', 1),
  ('Tipo de documento de identidad del acudiente', 'seleccion_unica', 2),
  ('Número de documento de identidad del acudiente', 'texto', 3),
  ('Parentesco o relación con el menor', 'texto', 4),
  ('Autorización del acudiente', 'seleccion_unica', 5)
) AS v(texto, tipo, orden)
WHERE c.nombre = 'Datos del acudiente (menores de edad)'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden;

INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, v.valor, v.orden
FROM public.pregunta_dss p JOIN public.categoria_dss c ON c.id_categoria = p.id_categoria
CROSS JOIN (VALUES ('CC', 'CC', 1), ('PP', 'PP', 2), ('CE', 'CE', 3), ('PPT', 'PPT', 4), ('Otro', 'OTRO', 5)) AS v(texto, valor, orden)
WHERE c.nombre = 'Datos del acudiente (menores de edad)' AND p.texto_pregunta = 'Tipo de documento de identidad del acudiente'
ON CONFLICT (id_pregunta, texto_opcion) DO UPDATE SET valor = EXCLUDED.valor, orden = EXCLUDED.orden;

INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, NULL, v.orden
FROM public.pregunta_dss p JOIN public.categoria_dss c ON c.id_categoria = p.id_categoria
CROSS JOIN (VALUES ('Autorizo', 1), ('No autorizo', 2)) AS v(texto, orden)
WHERE c.nombre = 'Datos del acudiente (menores de edad)' AND p.texto_pregunta = 'Autorización del acudiente'
ON CONFLICT (id_pregunta, texto_opcion) DO UPDATE SET orden = EXCLUDED.orden;

-- ============ 3. Reconocimiento étnico ============
INSERT INTO public.categoria_dss (nombre, orden) VALUES ('Reconocimiento étnico', 3)
ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;

INSERT INTO public.pregunta_dss (id_categoria, texto_pregunta, tipo_respuesta, orden)
SELECT c.id_categoria, 'De acuerdo con su cultura, pueblo o rasgos físicos, ¿usted se reconoce como...?', 'seleccion_unica', 1
FROM public.categoria_dss c WHERE c.nombre = 'Reconocimiento étnico'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden;

INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, NULL, v.orden
FROM public.pregunta_dss p JOIN public.categoria_dss c ON c.id_categoria = p.id_categoria
CROSS JOIN (VALUES
  ('Negro(a) / Afrocolombiano(a)', 1),
  ('Raizal del Archipiélago de San Andrés, Providencia y Santa Catalina', 2),
  ('Palenquero(a) de San Basilio', 3)
) AS v(texto, orden)
WHERE c.nombre = 'Reconocimiento étnico' AND p.texto_pregunta = 'De acuerdo con su cultura, pueblo o rasgos físicos, ¿usted se reconoce como...?'
ON CONFLICT (id_pregunta, texto_opcion) DO UPDATE SET orden = EXCLUDED.orden;

-- ============ 4. Identidad de sexo, género y orientación ============
INSERT INTO public.categoria_dss (nombre, orden) VALUES ('Identidad de sexo, género y orientación', 4)
ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;

INSERT INTO public.pregunta_dss (id_categoria, texto_pregunta, tipo_respuesta, orden)
SELECT c.id_categoria, v.texto, v.tipo, v.orden
FROM public.categoria_dss c
CROSS JOIN (VALUES
  ('Sexo', 'seleccion_unica', 1),
  ('Género con el que se identifica', 'seleccion_unica', 2),
  ('Orientación sexual', 'seleccion_unica', 3)
) AS v(texto, tipo, orden)
WHERE c.nombre = 'Identidad de sexo, género y orientación'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden;

INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, NULL, v.orden
FROM public.pregunta_dss p JOIN public.categoria_dss c ON c.id_categoria = p.id_categoria
CROSS JOIN (VALUES ('Hombre', 1), ('Mujer', 2), ('Intersexual', 3), ('Prefiero no responder', 4)) AS v(texto, orden)
WHERE c.nombre = 'Identidad de sexo, género y orientación' AND p.texto_pregunta = 'Sexo'
ON CONFLICT (id_pregunta, texto_opcion) DO UPDATE SET orden = EXCLUDED.orden;

INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, NULL, v.orden
FROM public.pregunta_dss p JOIN public.categoria_dss c ON c.id_categoria = p.id_categoria
CROSS JOIN (VALUES
  ('Mujer', 1), ('Mujer trans', 2), ('Hombre', 3), ('Hombre trans', 4),
  ('No binario', 5), ('Disidente / Otro', 6), ('Prefiero no responder', 7)
) AS v(texto, orden)
WHERE c.nombre = 'Identidad de sexo, género y orientación' AND p.texto_pregunta = 'Género con el que se identifica'
ON CONFLICT (id_pregunta, texto_opcion) DO UPDATE SET orden = EXCLUDED.orden;

INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, NULL, v.orden
FROM public.pregunta_dss p JOIN public.categoria_dss c ON c.id_categoria = p.id_categoria
CROSS JOIN (VALUES
  ('Heterosexual', 1), ('Homosexual', 2), ('Bisexual', 3), ('Asexual', 4),
  ('Demisexual', 5), ('Otra', 6), ('Prefiero no responder', 7)
) AS v(texto, orden)
WHERE c.nombre = 'Identidad de sexo, género y orientación' AND p.texto_pregunta = 'Orientación sexual'
ON CONFLICT (id_pregunta, texto_opcion) DO UPDATE SET orden = EXCLUDED.orden;

-- ============ 5. Condiciones de protección especial ============
INSERT INTO public.categoria_dss (nombre, orden) VALUES ('Condiciones de protección especial', 5)
ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;

INSERT INTO public.pregunta_dss (id_categoria, texto_pregunta, tipo_respuesta, orden)
SELECT c.id_categoria, v.texto, v.tipo, v.orden
FROM public.categoria_dss c
CROSS JOIN (VALUES
  ('¿Es víctima del conflicto armado?', 'si_no', 1),
  ('¿Presenta algún tipo de discapacidad?', 'si_no', 2),
  ('¿Qué tipo de discapacidad?', 'seleccion_multiple', 3)
) AS v(texto, tipo, orden)
WHERE c.nombre = 'Condiciones de protección especial'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden;

INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, NULL, v.orden
FROM public.pregunta_dss p JOIN public.categoria_dss c ON c.id_categoria = p.id_categoria
CROSS JOIN (VALUES
  ('Física', 1), ('Sensorial visual', 2), ('Sensorial auditiva', 3),
  ('Intelectual', 4), ('Psicosocial (psíquica)', 5)
) AS v(texto, orden)
WHERE c.nombre = 'Condiciones de protección especial' AND p.texto_pregunta = '¿Qué tipo de discapacidad?'
ON CONFLICT (id_pregunta, texto_opcion) DO UPDATE SET orden = EXCLUDED.orden;

-- ============ 6. Contacto y ubicación ============
INSERT INTO public.categoria_dss (nombre, orden) VALUES ('Contacto y ubicación', 6)
ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;

INSERT INTO public.pregunta_dss (id_categoria, texto_pregunta, tipo_respuesta, orden)
SELECT c.id_categoria, v.texto, v.tipo, v.orden
FROM public.categoria_dss c
CROSS JOIN (VALUES
  ('Número de teléfono', 'numero', 1),
  ('Correo electrónico', 'texto', 2),
  ('Dirección', 'texto', 3),
  ('Barrio', 'seleccion_unica', 4)
) AS v(texto, tipo, orden)
WHERE c.nombre = 'Contacto y ubicación'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden;

INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, NULL, v.orden
FROM public.pregunta_dss p JOIN public.categoria_dss c ON c.id_categoria = p.id_categoria
CROSS JOIN (VALUES
  ('El Pesebre', 1), ('Blanquizal', 2), ('Santa Rosa de Lima', 3), ('Los Alcázares', 4),
  ('Metropolitano', 5), ('La Pradera', 6), ('Juan XXIII La Quiebra', 7),
  ('San Javier N.° 1', 8), ('San Javier N.° 2', 9), ('Veinte de Julio', 10),
  ('Belencito', 11), ('Betania', 12), ('El Corazón', 13), ('Las Independencias', 14),
  ('Nuevos Conquistadores', 15), ('El Salado', 16), ('Eduardo Santos', 17),
  ('Antonio Nariño', 18), ('El Socorro', 19), ('Otro', 20)
) AS v(texto, orden)
WHERE c.nombre = 'Contacto y ubicación' AND p.texto_pregunta = 'Barrio'
ON CONFLICT (id_pregunta, texto_opcion) DO UPDATE SET orden = EXCLUDED.orden;

-- ============ 7. Vivienda ============
INSERT INTO public.categoria_dss (nombre, orden) VALUES ('Vivienda', 7)
ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;

INSERT INTO public.pregunta_dss (id_categoria, texto_pregunta, tipo_respuesta, orden)
SELECT c.id_categoria, v.texto, v.tipo, v.orden
FROM public.categoria_dss c
CROSS JOIN (VALUES
  ('Tipo de vivienda', 'seleccion_unica', 1),
  ('La vivienda que habita es...', 'seleccion_unica', 2),
  ('Estrato socioeconómico de la vivienda', 'seleccion_unica', 3),
  ('¿Cuántas personas viven en su hogar, incluyéndose usted?', 'numero', 4),
  ('¿Cuántos cuartos se usan para dormir?', 'numero', 5),
  ('¿Usted es cabeza de hogar?', 'si_no', 6),
  ('Material predominante de las paredes', 'seleccion_unica', 7),
  ('¿La vivienda está ubicada en zona de riesgo (deslizamiento, inundación)?', 'seleccion_unica', 8)
) AS v(texto, tipo, orden)
WHERE c.nombre = 'Vivienda'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden;

INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, NULL, v.orden
FROM public.pregunta_dss p JOIN public.categoria_dss c ON c.id_categoria = p.id_categoria
CROSS JOIN (VALUES
  ('Casa', 1), ('Apartamento', 2), ('Cuarto o habitación', 3), ('Inquilinato', 4),
  ('Vivienda improvisada (rancho, cambuche)', 5), ('Otro', 6)
) AS v(texto, orden)
WHERE c.nombre = 'Vivienda' AND p.texto_pregunta = 'Tipo de vivienda'
ON CONFLICT (id_pregunta, texto_opcion) DO UPDATE SET orden = EXCLUDED.orden;

INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, NULL, v.orden
FROM public.pregunta_dss p JOIN public.categoria_dss c ON c.id_categoria = p.id_categoria
CROSS JOIN (VALUES
  ('Propia, totalmente pagada', 1), ('Propia, la están pagando', 2),
  ('En arriendo o subarriendo', 3), ('Familiar, sin pagar arriendo', 4),
  ('Posesión sin título (ocupante de hecho)', 5), ('Otra', 6)
) AS v(texto, orden)
WHERE c.nombre = 'Vivienda' AND p.texto_pregunta = 'La vivienda que habita es...'
ON CONFLICT (id_pregunta, texto_opcion) DO UPDATE SET orden = EXCLUDED.orden;

INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, NULL, v.orden
FROM public.pregunta_dss p JOIN public.categoria_dss c ON c.id_categoria = p.id_categoria
CROSS JOIN (VALUES ('1', 1), ('2', 2), ('3', 3), ('4 o más', 4), ('No sabe', 5)) AS v(texto, orden)
WHERE c.nombre = 'Vivienda' AND p.texto_pregunta = 'Estrato socioeconómico de la vivienda'
ON CONFLICT (id_pregunta, texto_opcion) DO UPDATE SET orden = EXCLUDED.orden;

INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, NULL, v.orden
FROM public.pregunta_dss p JOIN public.categoria_dss c ON c.id_categoria = p.id_categoria
CROSS JOIN (VALUES
  ('Ladrillo, bloque o concreto', 1), ('Madera', 2), ('Tapia pisada o bahareque', 3),
  ('Materiales de desecho (zinc, tela, cartón, plástico)', 4), ('Otro', 5)
) AS v(texto, orden)
WHERE c.nombre = 'Vivienda' AND p.texto_pregunta = 'Material predominante de las paredes'
ON CONFLICT (id_pregunta, texto_opcion) DO UPDATE SET orden = EXCLUDED.orden;

INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, NULL, v.orden
FROM public.pregunta_dss p JOIN public.categoria_dss c ON c.id_categoria = p.id_categoria
CROSS JOIN (VALUES ('Sí', 1), ('No', 2), ('No sabe', 3)) AS v(texto, orden)
WHERE c.nombre = 'Vivienda' AND p.texto_pregunta = '¿La vivienda está ubicada en zona de riesgo (deslizamiento, inundación)?'
ON CONFLICT (id_pregunta, texto_opcion) DO UPDATE SET orden = EXCLUDED.orden;

-- ============ 8. Servicios públicos ============
INSERT INTO public.categoria_dss (nombre, orden) VALUES ('Servicios públicos', 8)
ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;

INSERT INTO public.pregunta_dss (id_categoria, texto_pregunta, tipo_respuesta, orden)
SELECT c.id_categoria, v.texto, v.tipo, v.orden
FROM public.categoria_dss c
CROSS JOIN (VALUES
  ('¿Con cuáles servicios cuenta la vivienda?', 'seleccion_multiple', 1),
  ('¿Los servicios son legales (con medidor y factura) o de conexión informal?', 'seleccion_unica', 2),
  ('¿Ha tenido suspensión o corte de algún servicio por falta de pago en el último año?', 'si_no', 3),
  ('¿Con qué energía o combustible cocinan principalmente?', 'seleccion_unica', 4),
  ('¿Cuenta con acceso a internet en el celular o en casa para estudiar o trabajar?', 'si_no', 5)
) AS v(texto, tipo, orden)
WHERE c.nombre = 'Servicios públicos'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden;

INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, NULL, v.orden
FROM public.pregunta_dss p JOIN public.categoria_dss c ON c.id_categoria = p.id_categoria
CROSS JOIN (VALUES
  ('Energía eléctrica', 1), ('Acueducto (agua potable)', 2), ('Alcantarillado', 3),
  ('Gas natural domiciliario', 4), ('Recolección de basuras', 5), ('Internet', 6),
  ('Telefonía fija', 7), ('Ninguno', 8)
) AS v(texto, orden)
WHERE c.nombre = 'Servicios públicos' AND p.texto_pregunta = '¿Con cuáles servicios cuenta la vivienda?'
ON CONFLICT (id_pregunta, texto_opcion) DO UPDATE SET orden = EXCLUDED.orden;

INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, NULL, v.orden
FROM public.pregunta_dss p JOIN public.categoria_dss c ON c.id_categoria = p.id_categoria
CROSS JOIN (VALUES ('Todos legales', 1), ('Algunos informales', 2), ('Todos informales', 3), ('No sabe', 4)) AS v(texto, orden)
WHERE c.nombre = 'Servicios públicos' AND p.texto_pregunta = '¿Los servicios son legales (con medidor y factura) o de conexión informal?'
ON CONFLICT (id_pregunta, texto_opcion) DO UPDATE SET orden = EXCLUDED.orden;

INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, NULL, v.orden
FROM public.pregunta_dss p JOIN public.categoria_dss c ON c.id_categoria = p.id_categoria
CROSS JOIN (VALUES ('Gas natural', 1), ('Gas en cilindro (pipeta)', 2), ('Electricidad', 3), ('Leña o carbón', 4), ('Otro', 5)) AS v(texto, orden)
WHERE c.nombre = 'Servicios públicos' AND p.texto_pregunta = '¿Con qué energía o combustible cocinan principalmente?'
ON CONFLICT (id_pregunta, texto_opcion) DO UPDATE SET orden = EXCLUDED.orden;

-- ============ 9. Alimentación ============
INSERT INTO public.categoria_dss (nombre, orden) VALUES ('Alimentación', 9)
ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;

INSERT INTO public.pregunta_dss (id_categoria, texto_pregunta, tipo_respuesta, orden)
SELECT c.id_categoria, v.texto, v.tipo, v.orden
FROM public.categoria_dss c
CROSS JOIN (VALUES
  ('¿Cuántas comidas consume al día normalmente?', 'seleccion_unica', 1),
  ('En los últimos 30 días, ¿usted o alguien de su hogar dejó de comer alguna comida por falta de dinero?', 'seleccion_unica', 2),
  ('En los últimos 30 días, ¿algún niño, niña o adolescente del hogar dejó de comer por falta de dinero?', 'seleccion_unica', 3),
  ('¿Recibe algún apoyo alimentario?', 'seleccion_multiple', 4)
) AS v(texto, tipo, orden)
WHERE c.nombre = 'Alimentación'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden;

INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, NULL, v.orden
FROM public.pregunta_dss p JOIN public.categoria_dss c ON c.id_categoria = p.id_categoria
CROSS JOIN (VALUES ('Una', 1), ('Dos', 2), ('Tres', 3), ('Más de tres', 4)) AS v(texto, orden)
WHERE c.nombre = 'Alimentación' AND p.texto_pregunta = '¿Cuántas comidas consume al día normalmente?'
ON CONFLICT (id_pregunta, texto_opcion) DO UPDATE SET orden = EXCLUDED.orden;

INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, NULL, v.orden
FROM public.pregunta_dss p JOIN public.categoria_dss c ON c.id_categoria = p.id_categoria
CROSS JOIN (VALUES ('Nunca', 1), ('Algunas veces', 2), ('Muchas veces', 3), ('Todos los días', 4)) AS v(texto, orden)
WHERE c.nombre = 'Alimentación' AND p.texto_pregunta = 'En los últimos 30 días, ¿usted o alguien de su hogar dejó de comer alguna comida por falta de dinero?'
ON CONFLICT (id_pregunta, texto_opcion) DO UPDATE SET orden = EXCLUDED.orden;

INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, NULL, v.orden
FROM public.pregunta_dss p JOIN public.categoria_dss c ON c.id_categoria = p.id_categoria
CROSS JOIN (VALUES ('No hay menores en el hogar', 1), ('Nunca', 2), ('Algunas veces', 3), ('Muchas veces', 4)) AS v(texto, orden)
WHERE c.nombre = 'Alimentación' AND p.texto_pregunta = 'En los últimos 30 días, ¿algún niño, niña o adolescente del hogar dejó de comer por falta de dinero?'
ON CONFLICT (id_pregunta, texto_opcion) DO UPDATE SET orden = EXCLUDED.orden;

INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, NULL, v.orden
FROM public.pregunta_dss p JOIN public.categoria_dss c ON c.id_categoria = p.id_categoria
CROSS JOIN (VALUES
  ('PAE (restaurante escolar)', 1), ('Comedor comunitario', 2),
  ('Bono o mercado (ICBF, Alcaldía u otra entidad)', 3), ('Olla comunitaria', 4),
  ('Ninguno', 5), ('Otro', 6)
) AS v(texto, orden)
WHERE c.nombre = 'Alimentación' AND p.texto_pregunta = '¿Recibe algún apoyo alimentario?'
ON CONFLICT (id_pregunta, texto_opcion) DO UPDATE SET orden = EXCLUDED.orden;

-- ============ 10. Educación ============
INSERT INTO public.categoria_dss (nombre, orden) VALUES ('Educación', 10)
ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;

INSERT INTO public.pregunta_dss (id_categoria, texto_pregunta, tipo_respuesta, orden)
SELECT c.id_categoria, v.texto, v.tipo, v.orden
FROM public.categoria_dss c
CROSS JOIN (VALUES
  ('¿Sabe leer y escribir?', 'si_no', 1),
  ('¿Cuál es su último grado de escolaridad alcanzado?', 'seleccion_unica', 2),
  ('¿Estudia actualmente?', 'si_no', 3),
  ('Nombre de la institución donde estudia', 'texto', 4),
  ('¿Qué está estudiando?', 'texto', 5),
  ('Si no estudia, ¿cuál es la razón principal?', 'seleccion_unica', 6),
  ('¿Recibe o ha recibido alguna beca o apoyo educativo?', 'si_no', 7),
  ('¿Qué le gustaría estudiar en un futuro próximo?', 'texto', 8)
) AS v(texto, tipo, orden)
WHERE c.nombre = 'Educación'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden;

INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, NULL, v.orden
FROM public.pregunta_dss p JOIN public.categoria_dss c ON c.id_categoria = p.id_categoria
CROSS JOIN (VALUES
  ('Ninguno', 1), ('Primaria (1.° a 5.°)', 2), ('Secundaria (6.° a 9.°)', 3),
  ('Media (10.° a 11.°)', 4), ('Técnica / Tecnológica', 5), ('Profesional', 6), ('Posgrado', 7)
) AS v(texto, orden)
WHERE c.nombre = 'Educación' AND p.texto_pregunta = '¿Cuál es su último grado de escolaridad alcanzado?'
ON CONFLICT (id_pregunta, texto_opcion) DO UPDATE SET orden = EXCLUDED.orden;

INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, NULL, v.orden
FROM public.pregunta_dss p JOIN public.categoria_dss c ON c.id_categoria = p.id_categoria
CROSS JOIN (VALUES
  ('Ya terminó sus estudios', 1), ('Falta de dinero o costos', 2), ('Necesita trabajar', 3),
  ('Responsabilidades de cuidado (hijos, familiares)', 4), ('Embarazo', 5),
  ('No hay cupo o la institución queda lejos', 6), ('No le interesa', 7), ('Otra', 8)
) AS v(texto, orden)
WHERE c.nombre = 'Educación' AND p.texto_pregunta = 'Si no estudia, ¿cuál es la razón principal?'
ON CONFLICT (id_pregunta, texto_opcion) DO UPDATE SET orden = EXCLUDED.orden;

-- ============ 11. Ocupación ============
INSERT INTO public.categoria_dss (nombre, orden) VALUES ('Ocupación', 11)
ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;

INSERT INTO public.pregunta_dss (id_categoria, texto_pregunta, tipo_respuesta, orden)
SELECT c.id_categoria, 'Ocupación', 'seleccion_unica', 1
FROM public.categoria_dss c WHERE c.nombre = 'Ocupación'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden;

INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, NULL, v.orden
FROM public.pregunta_dss p JOIN public.categoria_dss c ON c.id_categoria = p.id_categoria
CROSS JOIN (VALUES
  ('Empleado(a)', 1), ('Desempleado(a)', 2), ('Estudiante', 3),
  ('Independiente / trabajo informal', 4), ('Labores del hogar o de cuidado', 5), ('Otro', 6)
) AS v(texto, orden)
WHERE c.nombre = 'Ocupación' AND p.texto_pregunta = 'Ocupación'
ON CONFLICT (id_pregunta, texto_opcion) DO UPDATE SET orden = EXCLUDED.orden;

-- ============ 12. Participación en la Mesa Afro ============
INSERT INTO public.categoria_dss (nombre, orden) VALUES ('Participación en la Mesa Afro', 12)
ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;

INSERT INTO public.pregunta_dss (id_categoria, texto_pregunta, tipo_respuesta, orden)
SELECT c.id_categoria, v.texto, v.tipo, v.orden
FROM public.categoria_dss c
CROSS JOIN (VALUES
  ('¿De qué centro de interés hace parte?', 'seleccion_multiple', 1),
  ('¿Qué destaca del centro de interés del que hace parte?', 'texto', 2),
  ('¿Por qué razón integra la Mesa Afro?', 'seleccion_unica', 3)
) AS v(texto, tipo, orden)
WHERE c.nombre = 'Participación en la Mesa Afro'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden;

INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, NULL, v.orden
FROM public.pregunta_dss p JOIN public.categoria_dss c ON c.id_categoria = p.id_categoria
CROSS JOIN (VALUES
  ('Mediadores de Memoria', 1), ('Investigación de Lugares', 2),
  ('Biblioteca, Literatura y Obras Artísticas de Memoria', 3), ('Manualidades', 4),
  ('Huertas Urbanas', 5), ('Recorridos y Cartografía', 6)
) AS v(texto, orden)
WHERE c.nombre = 'Participación en la Mesa Afro' AND p.texto_pregunta = '¿De qué centro de interés hace parte?'
ON CONFLICT (id_pregunta, texto_opcion) DO UPDATE SET orden = EXCLUDED.orden;

INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, NULL, v.orden
FROM public.pregunta_dss p JOIN public.categoria_dss c ON c.id_categoria = p.id_categoria
CROSS JOIN (VALUES ('Labor social universitaria', 1), ('Alfabetización escolar', 2), ('Voluntad propia', 3)) AS v(texto, orden)
WHERE c.nombre = 'Participación en la Mesa Afro' AND p.texto_pregunta = '¿Por qué razón integra la Mesa Afro?'
ON CONFLICT (id_pregunta, texto_opcion) DO UPDATE SET orden = EXCLUDED.orden;

-- ============ 13. Expectativas y comentarios ============
INSERT INTO public.categoria_dss (nombre, orden) VALUES ('Expectativas y comentarios', 13)
ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;

INSERT INTO public.pregunta_dss (id_categoria, texto_pregunta, tipo_respuesta, orden)
SELECT c.id_categoria, v.texto, 'texto', v.orden
FROM public.categoria_dss c
CROSS JOIN (VALUES
  ('¿Qué espera de su participación en la Mesa Afro?', 1),
  ('¿Qué ideas se le ocurren para mejorar el espacio?', 2),
  ('Comentarios adicionales', 3)
) AS v(texto, orden)
WHERE c.nombre = 'Expectativas y comentarios'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden;

-- ============ 14. Consentimiento informado ============
INSERT INTO public.categoria_dss (nombre, orden) VALUES ('Consentimiento informado', 14)
ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;

INSERT INTO public.pregunta_dss (id_categoria, texto_pregunta, tipo_respuesta, orden)
SELECT c.id_categoria, '¿Acepta el tratamiento de sus datos?', 'seleccion_unica', 1
FROM public.categoria_dss c WHERE c.nombre = 'Consentimiento informado'
ON CONFLICT (id_categoria, texto_pregunta) DO UPDATE SET tipo_respuesta = EXCLUDED.tipo_respuesta, orden = EXCLUDED.orden;

INSERT INTO public.opcion_respuesta (id_pregunta, texto_opcion, valor, orden)
SELECT p.id_pregunta, v.texto, NULL, v.orden
FROM public.pregunta_dss p JOIN public.categoria_dss c ON c.id_categoria = p.id_categoria
CROSS JOIN (VALUES ('Acepto', 1), ('No acepto', 2)) AS v(texto, orden)
WHERE c.nombre = 'Consentimiento informado' AND p.texto_pregunta = '¿Acepta el tratamiento de sus datos?'
ON CONFLICT (id_pregunta, texto_opcion) DO UPDATE SET orden = EXCLUDED.orden;
