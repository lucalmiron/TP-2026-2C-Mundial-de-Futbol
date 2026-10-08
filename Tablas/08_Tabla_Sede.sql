-- Universidad Nacional de La Matanza
-- Bases de datos aplicada 
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 08/10/2026
-- Objetivo: Creacion sede.

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'sedes' AND TABLE_NAME = 'Sede')
BEGIN
	CREATE TABLE sedes.Sede
	(
		IdSede INT,
		Nombre VARCHAR(30) NOT NULL,
		Ciudad VARCHAR(30) NOT NULL,
		Capacidad INT NOT NULL,
		IdPais INT NOT NULL,
		-- falta IdHuso, poner cuando exista la tabla HusoHorario
		CONSTRAINT PK_Sede PRIMARY KEY (IdSede),
		CONSTRAINT CK_Sede_Capacidad CHECK (Capacidad > 0),
		CONSTRAINT UQ_Sede_Nombre_Ciudad UNIQUE (Nombre, Ciudad),
		CONSTRAINT FK_Sede_Pais FOREIGN KEY (IdPais) REFERENCES equipos.Pais(IdPais)
	);
END;
GO
