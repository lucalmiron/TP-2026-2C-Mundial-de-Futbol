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

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'TABLAS' AND TABLE_NAME = 'Sede')
BEGIN
	CREATE TABLE TABLAS.Sede
	(
		IdSede INT PRIMARY KEY,
		Nombre varchar(30),
		Ciudad varchar(30),
		Capacidad int,
		IdPais INT FOREIGN KEY REFERENCES TABLAS.Pais(IdPais)
		-- falta IdHuso, poner cuando exista la tabla HusoHorario
	);
END;
GO


