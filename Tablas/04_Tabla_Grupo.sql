--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 08/10/2026

--Creacion de Tablas

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
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
