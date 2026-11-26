-- Córrelo DESPUÉS de fase1_roles_solicitudes.sql.
-- Convierte tu cuenta de prueba (1001445409) en ADMINISTRADOR INVESTIGATIVO,
-- para que puedas probar la pantalla de "Revisar solicitudes".
-- No necesita organización: el admin nunca ve datos de organización, solo
-- revisa/aprueba/rechaza solicitudes de otros.

BEGIN;

UPDATE usuario
SET id_rol = (
    SELECT id_rol FROM rol WHERE UPPER(nombre) = 'ADMINISTRADOR INVESTIGATIVO'
)
WHERE documento = '1001445409';

COMMIT;

-- Verifica que quedó bien:
-- SELECT u.documento, r.nombre AS rol, u.id_organizacion
-- FROM usuario u LEFT JOIN rol r ON r.id_rol = u.id_rol
-- WHERE u.documento = '1001445409';
