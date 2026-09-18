// Nombres de rol con los que se opera en la app (se comparan en mayúsculas con rol.nombre).
const ROLES = ['DIRECTOR', 'COORDINADOR', 'GESTOR'];

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
module.exports = { ROLES, ETNIAS, GENEROS };
