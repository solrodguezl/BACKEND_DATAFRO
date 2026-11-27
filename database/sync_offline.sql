-- Soporte para la sincronización offline de la app móvil.
--
-- Cuando la app no tiene conexión guarda cada operación (crear actividad,
-- registrar asistencia, guardar capítulo de caracterización) en una cola local
-- con un UUID propio, y la reenvía al volver la red con el header
-- `Idempotency-Key: <uuid>`. Si la conexión se corta justo después de que el
-- servidor guardó pero antes de que llegue la respuesta, la app reintenta con
-- la misma clave y aquí se devuelve la respuesta original en vez de repetir la
-- operación (evita, por ejemplo, crear un segundo formulario_dss).
--
-- Idempotente: se puede ejecutar varias veces.

CREATE TABLE IF NOT EXISTS public.operacion_idempotente (
    clave uuid NOT NULL,
    id_usuario uuid NOT NULL,
    metodo varchar(10) NOT NULL,
    ruta text NOT NULL,
    estado_http integer NOT NULL,
    respuesta jsonb,
    fecha_creacion timestamp NOT NULL DEFAULT now(),
    CONSTRAINT operacion_idempotente_pkey PRIMARY KEY (clave, id_usuario)
);

CREATE INDEX IF NOT EXISTS idx_operacion_idempotente_fecha
    ON public.operacion_idempotente (fecha_creacion);

-- Limpieza: las claves solo hacen falta mientras el teléfono pueda reintentar.
DELETE FROM public.operacion_idempotente
WHERE fecha_creacion < now() - interval '60 days';
