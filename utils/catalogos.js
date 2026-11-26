// Nombres de rol con los que se opera en la app (se comparan en mayúsculas con rol.nombre).
// Administrador investigativo (= ADMIN, nivel 4) queda fuera a propósito: solo ve
// datos anonimizados, nunca los de una organización (ver cargarMembresia).
const ROLES = ['DIRECTOR', 'COORDINADOR', 'GESTOR'];

// Niveles de rol (Fase 1 — roles y solicitudes). GESTOR < COORDINADOR < DIRECTOR < ADMIN.
const NIVEL_ROL = {
    GESTOR: 1,
    COORDINADOR: 2,
    DIRECTOR: 3,
    'ADMINISTRADOR INVESTIGATIVO': 4,
};

const NIVEL_ADMIN = NIVEL_ROL['ADMINISTRADOR INVESTIGATIVO'];

const ETNIAS = [
    'Afrocolombiana',
    'Negra',
    'Raizal',
    'Palenquera',
    'Indígena',
    'Rom',
    'Mestiza',
    'Ninguna',
];

const GENEROS = ['Mujer', 'Hombre', 'Otro', 'Prefiere no decir'];

// Los barrios se leen de la tabla barrio.
/**
 * Roles que alguien con este nivel puede asignar/crear/editar: solo los de
 * nivel estrictamente menor al suyo (nunca el propio ni uno superior). Así
 * un DIRECTOR (3) puede crear COORDINADOR/GESTOR pero no otro DIRECTOR, un
 * COORDINADOR (2) solo puede crear GESTOR, y el ADMINISTRADOR INVESTIGATIVO
 * (4) puede crear cualquiera de los tres roles de organización (HU-03).
 */
const rolesAsignablesPara = (nivelCreador) =>
    ROLES.filter((rol) => NIVEL_ROL[rol] < nivelCreador);

module.exports = { ROLES, ETNIAS, GENEROS, NIVEL_ROL, NIVEL_ADMIN, rolesAsignablesPara };
