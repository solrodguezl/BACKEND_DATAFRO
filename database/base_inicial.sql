-- Datos mínimos para que la app funcione: roles y organizaciones piloto.
-- Solo inserta lo que no exista (se puede ejecutar varias veces).

INSERT INTO public.rol (nombre, descripcion)
SELECT v.nombre, v.descripcion
FROM (VALUES
	('Director', 'Líder de la organización: administra los miembros y sus datos'),
	('Gestor', 'Registra asistencia y caracterización en las actividades'),
	('Administrador investigativo', 'Accede solo a datos anonimizados con fines investigativos')
) AS v(nombre, descripcion)
WHERE NOT EXISTS (
	SELECT 1 FROM public.rol r WHERE UPPER(r.nombre) = UPPER(v.nombre)
);

INSERT INTO public.organizacion (nombre)
SELECT v.nombre
FROM (VALUES
	('Corporación Sal y Luz'),
	('Mesa Afro de la Comuna 13')
) AS v(nombre)
WHERE NOT EXISTS (
	SELECT 1 FROM public.organizacion o WHERE o.nombre = v.nombre
);
