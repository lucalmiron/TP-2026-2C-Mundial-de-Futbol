-- Universidad Nacional de La Matanza
-- Bases de datos aplicada 
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 08/10/2026
-- Objetivo: Creacion  tabla espacio publicitario.

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'mundial')
BEGIN
	USE mundial
END;
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'TABLAS' AND TABLE_NAME = 'EspacioPublicitario')
BEGIN
	CREATE TABLE TABLAS.EspacioPublicitario
	(
		IdEP INT primary key,	
		Tipo   varchar(30),
		Costo decimal(10,2)
	)
END
GO