const AppError = require('../utils/AppError');
const organizacionesRepository = require('../repositories/organizacionesRepository');
const miembrosRepository = require('../repositories/miembrosRepository');
const miembrosService = require('../services/miembrosService');

// El admin gestiona cualquier organización, no solo la suya: se arma una
// "membresía" con la organización que viene en la URL (no la de su propia
// cuenta) y su propio rol/nivel, para reutilizar las mismas reglas de
// jerarquía de miembrosService (HU-03) sin duplicarlas.
const membresiaPara = (req) => ({
    organizacion_id: req.params.id,
    usuario_id: req.sesion.usuario_id,
    rol: req.sesion.rol,
    nivel: req.sesion.nivel,
});

const obtenerOrganizacionOFallar = async (id) => {
    const organizacion = await organizacionesRepository.obtenerPorId(id);

    if (!organizacion) {
        throw new AppError('Organización no encontrada', 404);
    }

    return organizacion;
};

/** GET /api/admin/organizaciones — panel del administrador: historial de organizaciones. */
const listar = async (req, res, next) => {
    try {
        res.json(await organizacionesRepository.listarTodas());
    } catch (error) {
        next(error);
    }
};

/** GET /api/admin/organizaciones/:id/miembros — registrados de una organización. */
const miembros = async (req, res, next) => {
    try {
        const organizacion = await organizacionesRepository.obtenerPorId(
            req.params.id
        );

        if (!organizacion) {
            throw new AppError('Organización no encontrada', 404);
        }

        const listaMiembros = await miembrosRepository.listarPorOrganizacion(
            req.params.id
        );

        res.json({ organizacion, miembros: listaMiembros });
    } catch (error) {
        next(error);
    }
};

/** POST /api/admin/organizaciones/:id/miembros — crea un perfil en esa organización. */
const crearMiembro = async (req, res, next) => {
    try {
        await obtenerOrganizacionOFallar(req.params.id);
        res.status(201).json(await miembrosService.crear(membresiaPara(req), req.body));
    } catch (error) {
        next(error);
    }
};

/** PUT /api/admin/organizaciones/:id/miembros/:idUsuario — edita/activa/restablece clave. */
const actualizarMiembro = async (req, res, next) => {
    try {
        await obtenerOrganizacionOFallar(req.params.id);
        res.json(
            await miembrosService.actualizar(
                membresiaPara(req),
                req.params.idUsuario,
                req.body
            )
        );
    } catch (error) {
        next(error);
    }
};

/** GET /api/admin/organizaciones/:id/miembros/:idUsuario/resumen — perfil de actividad. */
const resumenMiembro = async (req, res, next) => {
    try {
        await obtenerOrganizacionOFallar(req.params.id);
        res.json(
            await miembrosService.resumenActividad(membresiaPara(req), req.params.idUsuario)
        );
    } catch (error) {
        next(error);
    }
};

module.exports = { listar, miembros, crearMiembro, actualizarMiembro, resumenMiembro };
