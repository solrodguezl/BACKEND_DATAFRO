-- Script único y definitivo (reemplaza bootstrap_admin.sql y el anterior
-- crear_organizacion_asistir.sql). Te deja como ADMINISTRADOR INVESTIGATIVO
-- y, a la vez, miembro activo de la organización "ASISTIR" -- con tu misma
-- cédula, sin crear ninguna cuenta nueva.
-- Idempotente: se puede correr más de una vez sin romper nada.

BEGIN;

-- Por si no corriste fase1_roles_solicitudes.sql todavía: asegura que
-- exista el índice único que usa el paso 3.
CREATE UNIQUE INDEX IF NOT EXISTS organizaciones_usuarios_uidx
    ON organizaciones_usuarios (id_usuario, id_organizacion);

-- 1) Crea la organización "ASISTIR" si no existe.
INSERT INTO organizacion (nombre, nit)
SELECT 'ASISTIR', NULL
WHERE NOT EXISTS (
    SELECT 1 FROM organizacion WHERE LOWER(nombre) = LOWER('ASISTIR')
);

-- 2) Tu usuario queda como ADMINISTRADOR INVESTIGATIVO, asignado a "ASISTIR".
UPDATE usuario
SET
    id_organizacion = (
        SELECT id_organizacion FROM organizacion WHERE LOWER(nombre) = LOWER('ASISTIR')
    ),
    id_rol = (
        SELECT id_rol FROM rol WHERE UPPER(nombre) = 'ADMINISTRADOR INVESTIGATIVO'
    )
WHERE documento = '1001445409';

-- 3) Activa tu membresía en esa organización.
INSERT INTO organizaciones_usuarios (id_usuario, id_organizacion, activo)
SELECT u.id_usuario, u.id_organizacion, true
FROM usuario u
WHERE u.documento = '1001445409'
ON CONFLICT (id_usuario, id_organizacion) DO UPDATE SET activo = true;

COMMIT;

-- Verifica que quedó bien:
-- SELECT u.documento, r.nombre AS rol, o.nombre AS organizacion
-- FROM usuario u
-- LEFT JOIN rol r ON r.id_rol = u.id_rol
-- LEFT JOIN organizacion o ON o.id_organizacion = u.id_organizacion
-- WHERE u.documento = '1001445409';
