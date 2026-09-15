-- public.perfiles definition

-- Drop table

-- DROP TABLE public.perfiles;

CREATE TABLE public.perfiles (
	usuario_id uuid NOT NULL,
	nombres varchar(100) NULL,
	apellidos varchar(100) NULL,
	telefono varchar(20) NULL,
	foto_perfil text NULL,
	fecha_actualizacion timestamptz DEFAULT CURRENT_TIMESTAMP NULL,
	CONSTRAINT perfiles_pkey PRIMARY KEY (usuario_id)
);


-- public.perfiles foreign keys

ALTER TABLE public.perfiles ADD CONSTRAINT perfiles_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuario(id_usuario) ON DELETE CASCADE;