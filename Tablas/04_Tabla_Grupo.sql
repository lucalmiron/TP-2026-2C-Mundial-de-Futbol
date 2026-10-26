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

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'equipos' AND TABLE_NAME = 'Grupo')
BEGIN
	CREATE TABLE equipos.Grupo
	(
		IdGrupo INT IDENTITY(1,1),
		NOMBRE VARCHAR(10) NOT NULL,
		CONSTRAINT PK_Grupo PRIMARY KEY (IdGrupo),
		CONSTRAINT UQ_Grupo_NOMBRE UNIQUE (NOMBRE)
	);
END;
GO
