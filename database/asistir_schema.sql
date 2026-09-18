-- ASISTIR / DATAFRO: ajustes sobre el modelo existente (organizacion, rol, usuario, persona,
-- actividad, asistencia, barrio). Solo AGREGA lo que falta; es idempotente.

-- 1) perfiles: la usa la pantalla "Mi perfil" y no existía en la base.
CREATE TABLE IF NOT EXISTS public.perfiles (
	usuario_id uuid NOT NULL,
	nombres varchar(100) NULL,
	apellidos varchar(100) NULL,
	telefono varchar(20) NULL,
	foto_perfil text NULL,
	fecha_actualizacion timestamptz DEFAULT CURRENT_TIMESTAMP NULL,
	CONSTRAINT perfiles_pkey PRIMARY KEY (usuario_id),
	CONSTRAINT perfiles_usuario_id_fkey FOREIGN KEY (usuario_id)
		REFERENCES public.usuario (id_usuario) ON DELETE CASCADE
);

-- 2) usuario.fecha_actualizacion está creada como ARRAY; si está vacía se corrige a fecha.
DO $$
BEGIN
	IF EXISTS (
		SELECT 1 FROM information_schema.columns
		WHERE table_schema = 'public' AND table_name = 'usuario'
		  AND column_name = 'fecha_actualizacion' AND data_type = 'ARRAY'
	) AND NOT EXISTS (
		SELECT 1 FROM public.usuario WHERE fecha_actualizacion IS NOT NULL
	) THEN
		ALTER TABLE public.usuario
			ALTER COLUMN fecha_actualizacion TYPE timestamptz USING NULL,
			ALTER COLUMN fecha_actualizacion SET DEFAULT CURRENT_TIMESTAMP;
	END IF;
END $$;

-- 3) Rol "Coordinador" (HU-03); Director, Gestor y Administrador investigativo ya existen.
INSERT INTO public.rol (nombre, descripcion)
SELECT 'Coordinador', 'Coordina gestores dentro de su organización'
WHERE NOT EXISTS (SELECT 1 FROM public.rol WHERE UPPER(nombre) = 'COORDINADOR');

-- 4) persona: el formulario captura edad (no fecha de nacimiento).
ALTER TABLE public.persona ADD COLUMN IF NOT EXISTS edad smallint NULL;

-- Un documento por organización (llave natural, HU-05). Si ya hay duplicados, avisa y sigue.
DO $$
BEGIN
	CREATE UNIQUE INDEX IF NOT EXISTS persona_org_documento_uidx
		ON public.persona (id_organizacion, documento);
EXCEPTION WHEN unique_violation THEN
	RAISE NOTICE 'Hay personas con documento repetido en una organización; revisa antes de crear el índice único.';
END $$;

-- 5) Barrios de la Comuna 13 (solo los que aún no existen).
INSERT INTO public.barrio (nombre, comuna)
SELECT v.nombre, 'Comuna 13'
FROM unnest(ARRAY[
	'Independencias I', 'Independencias II', 'Independencias III', 'El Salado',
	'Nuevos Conquistadores', 'San Javier', 'Belencito', 'Eduardo Santos',
	'Antonio Nariño', 'Veinte de Julio', 'Juan XXIII', 'La Quiebra',
	'Santa Rosa de Lima', 'Betania', 'Blanquizal', 'Los Alcázares'
]) AS v(nombre)
WHERE NOT EXISTS (
	SELECT 1 FROM public.barrio b WHERE LOWER(b.nombre) = LOWER(v.nombre)
);

-- 6) Usuarios que aún no tienen organización o rol (los administradores investigativos no se tocan).
UPDATE public.usuario u
SET id_organizacion = (
	SELECT id_organizacion FROM public.organizacion
	WHERE nombre ILIKE 'Mesa Afro%' ORDER BY fecha_creacion LIMIT 1
)
WHERE u.id_organizacion IS NULL
  AND NOT EXISTS (
	SELECT 1 FROM public.rol r
	WHERE r.id_rol = u.id_rol AND UPPER(r.nombre) LIKE 'ADMINISTRADOR%'
  );

WITH sin_rol AS (
	SELECT id_usuario, id_organizacion,
		ROW_NUMBER() OVER (PARTITION BY id_organizacion ORDER BY fecha_creacion, id_usuario) AS rn
	FROM public.usuario
	WHERE id_rol IS NULL AND id_organizacion IS NOT NULL
)
UPDATE public.usuario u
SET id_rol = CASE
	WHEN s.rn = 1 AND NOT EXISTS (
		SELECT 1 FROM public.usuario x
		JOIN public.rol r ON r.id_rol = x.id_rol
		WHERE x.id_organizacion = s.id_organizacion AND UPPER(r.nombre) = 'DIRECTOR'
	) THEN (SELECT id_rol FROM public.rol WHERE UPPER(nombre) = 'DIRECTOR' LIMIT 1)
	ELSE (SELECT id_rol FROM public.rol WHERE UPPER(nombre) = 'GESTOR' LIMIT 1)
END
FROM sin_rol s
WHERE u.id_usuario = s.id_usuario;
