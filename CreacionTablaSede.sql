-- Universidad Nacional de La Matanza
-- Bases de datos aplicada 
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 03/10/2026
-- Objetivo: Creacion sede.
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'mundial')
BEGIN
	USE mundial
END;
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'TABLAS' AND TABLE_NAME = 'Sede')
BEGIN
	CREATE TABLE TABLAS.Sede
	(
		IdSede INT PRIMARY KEY,
		Nombre varchar(30),
		Ciudad varchar(30),
		Capacidad int
		-- falta idpais y huso horario , poner cuando esten todas las tablas juntas
	);
END;
GO


