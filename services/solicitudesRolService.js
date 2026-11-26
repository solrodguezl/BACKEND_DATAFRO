const solicitudesRolRepository = require('../repositories/solicitudesRolRepository');
const AppError = require('../utils/AppError');
const { NIVEL_ROL } = require('../utils/catalogos');

const crear = async (sesion, data) => {
    const nivelSolicitado = NIVEL_ROL[data.rolSolicitado];

    if (sesion.nivel && nivelSolicitado <= sesion.nivel) {
        throw new AppError(
            'Ya tienes un rol con ese nivel o uno superior',
            400
        );
    }

    return solicitudesRolRepository.crear({
        usuarioId: sesion.usuario_id,
        rolSolicitado: data.rolSolicitado,
        organizacionNombre: data.organizacionNombre,
        nit: data.nit,
        celular: data.celular,
        cargo: data.cargo,
        motivo: data.motivo,
    });
};

const misSolicitudes = (sesion) =>
    solicitudesRolRepository.listarPorUsuario(sesion.usuario_id);

const listarAdmin = (estado) => solicitudesRolRepository.listarAdmin(estado ?? null);

const aprobar = (sesion, id, comentario) =>
    solicitudesRolRepository.aprobar({
        id,
        resueltoPor: sesion.usuario_id,
        comentario,
    });

const rechazar = (sesion, id, comentario) =>
    solicitudesRolRepository.rechazar({
        id,
        resueltoPor: sesion.usuario_id,
        comentario,
    });

module.exports = {
    crear,
    misSolicitudes,
    listarAdmin,
    aprobar,
    rechazar,
};
