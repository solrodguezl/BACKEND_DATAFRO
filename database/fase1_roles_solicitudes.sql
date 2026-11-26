-- FASE 1 — Roles por nivel + solicitudes de permisos (HU-03 extendido).
-- Córrelo TÚ en pgAdmin contra tu base (local o Neon). Es idempotente: se puede
-- correr varias veces sin romper nada ni borrar datos. No usa ningún ORM.

BEGIN;

-- 1) Niveles de rol: GESTOR=1, COORDINADOR=2, DIRECTOR=3, ADMIN=4.
--    "Administrador investigativo" = tu rol ADMIN (nivel 4): confirmado por ti.
ALTER TABLE public.rol ADD COLUMN IF NOT EXISTS nivel smallint;

UPDATE public.rol SET nivel = 1 WHERE UPPER(nombre) = 'GESTOR' AND nivel IS DISTINCT FROM 1;
UPDATE public.rol SET nivel = 2 WHERE UPPER(nombre) = 'COORDINADOR' AND nivel IS DISTINCT FROM 2;
UPDATE public.rol SET nivel = 3 WHERE UPPER(nombre) = 'DIRECTOR' AND nivel IS DISTINCT FROM 3;
UPDATE public.rol SET nivel = 4 WHERE UPPER(nombre) = 'ADMINISTRADOR INVESTIGATIVO' AND nivel IS DISTINCT FROM 4;

-- Si tienes roles viejos con otro nombre ("Líder", "Gerente", etc.), este SELECT
-- los muestra sin nivel asignado para que decidas a cuál de los 4 se mapean:
--   SELECT id_rol, nombre, nivel FROM public.rol WHERE nivel IS NULL;

-- 2) Función que da el id del rol GESTOR, para usarla como DEFAULT de usuario.id_rol.
CREATE OR REPLACE FUNCTION public.fn_id_rol_gestor()
RETURNS uuid
LANGUAGE sql
STABLE
AS $$
    SELECT id_rol FROM public.rol WHERE UPPER(nombre) = 'GESTOR' LIMIT 1;
$$;

-- 3) Todo usuario nuevo que no traiga id_rol explícito queda como GESTOR.
--    (id_organizacion sigue sin default: no tiene organización hasta que se le
--    apruebe una solicitud.) Estas dos columnas ya las dejaste nullable tú
--    mismo en pgAdmin; se repite aquí por si corres este script en otra base.
ALTER TABLE public.usuario ALTER COLUMN id_rol DROP NOT NULL;
ALTER TABLE public.usuario ALTER COLUMN id_organizacion DROP NOT NULL;
ALTER TABLE public.usuario ALTER COLUMN nombre DROP NOT NULL;
ALTER TABLE public.usuario ALTER COLUMN clave_hash TYPE varchar(255);
ALTER TABLE public.usuario ALTER COLUMN id_rol SET DEFAULT public.fn_id_rol_gestor();

-- Usuarios que ya existen sin rol (por ejemplo, autorregistrados antes de hoy)
-- quedan como GESTOR en vez de quedarse huérfanos para siempre.
UPDATE public.usuario
SET id_rol = public.fn_id_rol_gestor()
WHERE id_rol IS NULL;

-- 4) Llaves naturales que pide tu brief.
CREATE UNIQUE INDEX IF NOT EXISTS organizacion_nit_uidx
    ON public.organizacion (nit)
    WHERE nit IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS organizaciones_usuarios_uidx
    ON public.organizaciones_usuarios (id_usuario, id_organizacion);

-- 5) Solicitudes de rol (HU-03 extendido): un GESTOR pide ser COORDINADOR o
--    DIRECTOR de una organización; el ADMIN (Administrador investigativo) la
--    aprueba o la rechaza.
CREATE TABLE IF NOT EXISTS public.solicitud_rol (
    id_solicitud uuid NOT NULL DEFAULT uuid_generate_v4(),
    id_usuario uuid NOT NULL,
    rol_solicitado varchar(20) NOT NULL,
    organizacion_nombre varchar(150) NOT NULL,
    nit varchar(20),
    celular varchar(20),
    cargo varchar(100),
    motivo text,
    estado varchar(20) NOT NULL DEFAULT 'pendiente',
    fecha_solicitud timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_resolucion timestamptz,
    resuelto_por uuid,
    comentario_resolucion text,
    CONSTRAINT solicitud_rol_pkey PRIMARY KEY (id_solicitud),
    CONSTRAINT solicitud_rol_id_usuario_fkey FOREIGN KEY (id_usuario)
        REFERENCES public.usuario (id_usuario) ON DELETE CASCADE,
    CONSTRAINT solicitud_rol_resuelto_por_fkey FOREIGN KEY (resuelto_por)
        REFERENCES public.usuario (id_usuario),
    CONSTRAINT solicitud_rol_rol_solicitado_check
        CHECK (rol_solicitado IN ('COORDINADOR', 'DIRECTOR')),
    CONSTRAINT solicitud_rol_estado_check
        CHECK (estado IN ('pendiente', 'aprobada', 'rechazada'))
);

-- Un usuario no puede tener dos solicitudes pendientes a la vez: la segunda
-- solicitud choca con este índice único parcial -> el backend ya traduce esa
-- violación (23505) en un 409 "El recurso ya existe".
CREATE UNIQUE INDEX IF NOT EXISTS solicitud_rol_pendiente_uidx
    ON public.solicitud_rol (id_usuario)
    WHERE estado = 'pendiente';

CREATE INDEX IF NOT EXISTS idx_solicitud_rol_estado ON public.solicitud_rol (estado);

-- 6) Permisos nuevos: cualquiera puede pedir rol; solo ADMIN revisa solicitudes.
INSERT INTO public.permiso (nombre, modulo)
SELECT v.nombre, 'roles'
FROM (VALUES ('solicitud_rol.crear'), ('solicitud_rol.revisar')) AS v(nombre)
WHERE NOT EXISTS (
    SELECT 1 FROM public.permiso p WHERE p.nombre = v.nombre
);

INSERT INTO public.rol_permiso (id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso
FROM public.rol r
CROSS JOIN public.permiso p
WHERE p.nombre = 'solicitud_rol.crear'
  AND UPPER(r.nombre) IN ('GESTOR', 'COORDINADOR', 'DIRECTOR', 'ADMINISTRADOR INVESTIGATIVO')
  AND NOT EXISTS (
    SELECT 1 FROM public.rol_permiso rp
    WHERE rp.id_rol = r.id_rol AND rp.id_permiso = p.id_permiso
  );

INSERT INTO public.rol_permiso (id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso
FROM public.rol r
CROSS JOIN public.permiso p
WHERE p.nombre = 'solicitud_rol.revisar'
  AND UPPER(r.nombre) = 'ADMINISTRADOR INVESTIGATIVO'
  AND NOT EXISTS (
    SELECT 1 FROM public.rol_permiso rp
    WHERE rp.id_rol = r.id_rol AND rp.id_permiso = p.id_permiso
  );

COMMIT;

-- Verificación (corre esto después y revisa que todo tenga sentido):
-- SELECT nombre, nivel FROM public.rol ORDER BY nivel;
-- SELECT r.nombre AS rol, p.nombre AS permiso FROM public.rol_permiso rp
--   JOIN public.rol r ON r.id_rol = rp.id_rol
--   JOIN public.permiso p ON p.id_permiso = rp.id_permiso
--   WHERE p.modulo = 'roles' ORDER BY r.nombre;
-- SELECT COUNT(*) FROM public.usuario WHERE id_rol IS NULL; -- debe dar 0
