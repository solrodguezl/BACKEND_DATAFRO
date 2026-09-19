-- ASISTIR / DATAFRO: esquema base (modelo original). Sirve para crear una base NUEVA
-- (por ejemplo en la nube). En una base que ya tiene estas tablas no cambia nada
-- (CREATE TABLE IF NOT EXISTS). Se ejecuta con: npm run migrate

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS public.rol (
	id_rol uuid NOT NULL DEFAULT uuid_generate_v4(),
	nombre varchar(60) NOT NULL,
	descripcion text,
	CONSTRAINT rol_pkey PRIMARY KEY (id_rol)
);

CREATE TABLE IF NOT EXISTS public.organizacion (
	id_organizacion uuid NOT NULL DEFAULT uuid_generate_v4(),
	nombre varchar(150) NOT NULL,
	tipo varchar(80),
	nit varchar(20),
	fecha_creacion timestamp NOT NULL DEFAULT now(),
	CONSTRAINT organizacion_pkey PRIMARY KEY (id_organizacion)
);

CREATE TABLE IF NOT EXISTS public.barrio (
	id_barrio uuid NOT NULL DEFAULT uuid_generate_v4(),
	nombre varchar(100) NOT NULL,
	comuna varchar(50) NOT NULL,
	ciudad varchar(60) NOT NULL DEFAULT 'Medellín',
	CONSTRAINT barrio_pkey PRIMARY KEY (id_barrio)
);

CREATE TABLE IF NOT EXISTS public.usuario (
	id_usuario uuid NOT NULL DEFAULT uuid_generate_v4(),
	id_organizacion uuid,
	id_rol uuid,
	nombre varchar(150),
	documento varchar(20),
	correo varchar(150),
	telefono varchar(20),
	activo boolean NOT NULL DEFAULT true,
	fecha_creacion timestamp NOT NULL DEFAULT now(),
	fecha_actualizacion timestamptz DEFAULT CURRENT_TIMESTAMP,
	clave_hash varchar(255),
	CONSTRAINT usuario_pkey PRIMARY KEY (id_usuario),
	CONSTRAINT usuario_id_organizacion_fkey FOREIGN KEY (id_organizacion) REFERENCES public.organizacion (id_organizacion),
	CONSTRAINT usuario_id_rol_fkey FOREIGN KEY (id_rol) REFERENCES public.rol (id_rol)
);

CREATE TABLE IF NOT EXISTS public.sesiones (
	id uuid NOT NULL DEFAULT uuid_generate_v4(),
	usuario_id uuid,
	token_renovacion text NOT NULL,
	info_dispositivo text,
	direccion_ip inet,
	revocado boolean DEFAULT false,
	fecha_expiracion timestamptz NOT NULL,
	fecha_creacion timestamptz DEFAULT CURRENT_TIMESTAMP,
	CONSTRAINT sesiones_pkey PRIMARY KEY (id),
	CONSTRAINT sesiones_token_renovacion_key UNIQUE (token_renovacion),
	CONSTRAINT sesiones_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuario (id_usuario) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS public.persona (
	id_persona uuid NOT NULL DEFAULT uuid_generate_v4(),
	id_organizacion uuid NOT NULL,
	id_barrio uuid,
	nombres varchar(150) NOT NULL,
	apellidos varchar(150),
	documento varchar(20),
	tipo_documento varchar(20),
	etnia varchar(60),
	fecha_nacimiento date,
	genero varchar(30),
	fecha_registro timestamp NOT NULL DEFAULT now(),
	sincronizado boolean NOT NULL DEFAULT false,
	fecha_sincronizacion timestamp,
	CONSTRAINT persona_pkey PRIMARY KEY (id_persona),
	CONSTRAINT persona_id_barrio_fkey FOREIGN KEY (id_barrio) REFERENCES public.barrio (id_barrio),
	CONSTRAINT persona_id_organizacion_fkey FOREIGN KEY (id_organizacion) REFERENCES public.organizacion (id_organizacion)
);
CREATE INDEX IF NOT EXISTS idx_persona_barrio ON public.persona (id_barrio);

CREATE TABLE IF NOT EXISTS public.actividad (
	id_actividad uuid NOT NULL DEFAULT uuid_generate_v4(),
	id_organizacion uuid NOT NULL,
	id_usuario_responsable uuid,
	nombre varchar(150) NOT NULL,
	tipo varchar(60),
	fecha date NOT NULL,
	lugar varchar(150),
	descripcion text,
	CONSTRAINT actividad_pkey PRIMARY KEY (id_actividad),
	CONSTRAINT actividad_id_organizacion_fkey FOREIGN KEY (id_organizacion) REFERENCES public.organizacion (id_organizacion),
	CONSTRAINT actividad_id_usuario_responsable_fkey FOREIGN KEY (id_usuario_responsable) REFERENCES public.usuario (id_usuario)
);

CREATE TABLE IF NOT EXISTS public.asistencia (
	id_asistencia uuid NOT NULL DEFAULT uuid_generate_v4(),
	id_persona uuid NOT NULL,
	id_actividad uuid NOT NULL,
	id_usuario uuid NOT NULL,
	fecha_hora_registro timestamp NOT NULL DEFAULT now(),
	sincronizado boolean NOT NULL DEFAULT false,
	fecha_sincronizacion timestamp,
	CONSTRAINT asistencia_pkey PRIMARY KEY (id_asistencia),
	CONSTRAINT asistencia_id_persona_id_actividad_key UNIQUE (id_persona, id_actividad),
	CONSTRAINT asistencia_id_actividad_fkey FOREIGN KEY (id_actividad) REFERENCES public.actividad (id_actividad),
	CONSTRAINT asistencia_id_persona_fkey FOREIGN KEY (id_persona) REFERENCES public.persona (id_persona),
	CONSTRAINT asistencia_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.usuario (id_usuario)
);
CREATE INDEX IF NOT EXISTS idx_asistencia_actividad ON public.asistencia (id_actividad);

CREATE TABLE IF NOT EXISTS public.categoria_dss (
	id_categoria uuid NOT NULL DEFAULT uuid_generate_v4(),
	nombre varchar(60) NOT NULL,
	CONSTRAINT categoria_dss_pkey PRIMARY KEY (id_categoria)
);

CREATE TABLE IF NOT EXISTS public.pregunta_dss (
	id_pregunta uuid NOT NULL DEFAULT uuid_generate_v4(),
	id_categoria uuid NOT NULL,
	texto_pregunta text NOT NULL,
	tipo_respuesta varchar(30) NOT NULL,
	orden integer NOT NULL DEFAULT 0,
	activa boolean NOT NULL DEFAULT true,
	CONSTRAINT pregunta_dss_pkey PRIMARY KEY (id_pregunta),
	CONSTRAINT pregunta_dss_id_categoria_fkey FOREIGN KEY (id_categoria) REFERENCES public.categoria_dss (id_categoria)
);

CREATE TABLE IF NOT EXISTS public.opcion_respuesta (
	id_opcion uuid NOT NULL DEFAULT uuid_generate_v4(),
	id_pregunta uuid NOT NULL,
	texto_opcion varchar(150) NOT NULL,
	valor varchar(50),
	CONSTRAINT opcion_respuesta_pkey PRIMARY KEY (id_opcion),
	CONSTRAINT opcion_respuesta_id_pregunta_fkey FOREIGN KEY (id_pregunta) REFERENCES public.pregunta_dss (id_pregunta) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS public.formulario_dss (
	id_formulario uuid NOT NULL DEFAULT uuid_generate_v4(),
	id_persona uuid NOT NULL,
	id_usuario uuid NOT NULL,
	estado varchar(20) NOT NULL DEFAULT 'borrador',
	fecha_diligenciamiento date,
	fecha_ultima_actualizacion timestamp NOT NULL DEFAULT now(),
	sincronizado boolean NOT NULL DEFAULT false,
	fecha_sincronizacion timestamp,
	CONSTRAINT formulario_dss_pkey PRIMARY KEY (id_formulario),
	CONSTRAINT formulario_dss_id_persona_fkey FOREIGN KEY (id_persona) REFERENCES public.persona (id_persona),
	CONSTRAINT formulario_dss_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.usuario (id_usuario)
);
CREATE INDEX IF NOT EXISTS idx_formulario_persona ON public.formulario_dss (id_persona);

CREATE TABLE IF NOT EXISTS public.respuesta_dss (
	id_respuesta uuid NOT NULL DEFAULT uuid_generate_v4(),
	id_formulario uuid NOT NULL,
	id_pregunta uuid NOT NULL,
	id_opcion uuid,
	valor_respuesta text,
	CONSTRAINT respuesta_dss_pkey PRIMARY KEY (id_respuesta),
	CONSTRAINT respuesta_dss_id_formulario_id_pregunta_key UNIQUE (id_formulario, id_pregunta),
	CONSTRAINT respuesta_dss_id_formulario_fkey FOREIGN KEY (id_formulario) REFERENCES public.formulario_dss (id_formulario) ON DELETE CASCADE,
	CONSTRAINT respuesta_dss_id_opcion_fkey FOREIGN KEY (id_opcion) REFERENCES public.opcion_respuesta (id_opcion),
	CONSTRAINT respuesta_dss_id_pregunta_fkey FOREIGN KEY (id_pregunta) REFERENCES public.pregunta_dss (id_pregunta)
);
CREATE INDEX IF NOT EXISTS idx_respuesta_formulario ON public.respuesta_dss (id_formulario);

CREATE TABLE IF NOT EXISTS public.indicador_territorial (
	id_indicador uuid NOT NULL DEFAULT uuid_generate_v4(),
	nombre varchar(150) NOT NULL,
	categoria varchar(60),
	unidad_medida varchar(30),
	CONSTRAINT indicador_territorial_pkey PRIMARY KEY (id_indicador)
);

CREATE TABLE IF NOT EXISTS public.dato_oficial (
	id_dato_oficial uuid NOT NULL DEFAULT uuid_generate_v4(),
	id_indicador uuid NOT NULL,
	id_barrio uuid NOT NULL,
	valor numeric(10, 2) NOT NULL,
	fuente varchar(60) NOT NULL,
	periodo varchar(20) NOT NULL,
	fecha_publicacion date,
	CONSTRAINT dato_oficial_pkey PRIMARY KEY (id_dato_oficial),
	CONSTRAINT dato_oficial_id_barrio_fkey FOREIGN KEY (id_barrio) REFERENCES public.barrio (id_barrio),
	CONSTRAINT dato_oficial_id_indicador_fkey FOREIGN KEY (id_indicador) REFERENCES public.indicador_territorial (id_indicador)
);

CREATE TABLE IF NOT EXISTS public.permiso (
	id_permiso uuid NOT NULL DEFAULT uuid_generate_v4(),
	nombre varchar(100) NOT NULL,
	modulo varchar(60) NOT NULL,
	CONSTRAINT permiso_pkey PRIMARY KEY (id_permiso)
);

CREATE TABLE IF NOT EXISTS public.rol_permiso (
	id_rol uuid NOT NULL,
	id_permiso uuid NOT NULL,
	CONSTRAINT rol_permiso_pkey PRIMARY KEY (id_rol, id_permiso),
	CONSTRAINT rol_permiso_id_permiso_fkey FOREIGN KEY (id_permiso) REFERENCES public.permiso (id_permiso) ON DELETE CASCADE,
	CONSTRAINT rol_permiso_id_rol_fkey FOREIGN KEY (id_rol) REFERENCES public.rol (id_rol) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS public.organizaciones_usuarios (
	id_usuario uuid NOT NULL,
	id_organizacion uuid NOT NULL,
	activo boolean NOT NULL DEFAULT true,
	fecha_creacion timestamp NOT NULL DEFAULT now(),
	CONSTRAINT organizaciones_usuarios_id_organizacion_fkey FOREIGN KEY (id_organizacion) REFERENCES public.organizacion (id_organizacion),
	CONSTRAINT organizaciones_usuarios_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.usuario (id_usuario)
);
