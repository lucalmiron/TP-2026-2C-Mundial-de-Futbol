--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Creacion de Tablas

-- Ejecutar en la base seleccionada por el instalador.
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'equipos' AND TABLE_NAME = 'Club')
BEGIN
	CREATE TABLE equipos.Club
	(
		IdClub INT IDENTITY(1, 1),
		Nombre NVARCHAR(40) NOT NULL,
		CONSTRAINT PK_Club PRIMARY KEY (IdClub),
		CONSTRAINT UQ_Club_Nombre UNIQUE (Nombre)
	);
END;
GO

-- Bases creadas con la version anterior tenian VARCHAR(20): se migra a NVARCHAR(40).
-- El ALTER es idempotente: si ya es NVARCHAR(40) no hace nada.
IF EXISTS (
	SELECT 1
	FROM sys.columns c
	JOIN sys.types t ON t.user_type_id = c.user_type_id
	WHERE c.object_id = OBJECT_ID(N'equipos.Club')
	  AND c.name = N'Nombre'
	  AND (t.name <> N'nvarchar' OR c.max_length <> 80)
)
BEGIN
	IF EXISTS (SELECT 1 FROM sys.key_constraints
	           WHERE parent_object_id = OBJECT_ID(N'equipos.Club') AND name = N'UQ_Club_Nombre')
		ALTER TABLE equipos.Club DROP CONSTRAINT UQ_Club_Nombre;

	ALTER TABLE equipos.Club ALTER COLUMN Nombre NVARCHAR(40) NOT NULL;

	ALTER TABLE equipos.Club ADD CONSTRAINT UQ_Club_Nombre UNIQUE (Nombre);
END;
GO
