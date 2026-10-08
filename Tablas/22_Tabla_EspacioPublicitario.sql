-- Universidad Nacional de La Matanza
-- Bases de datos aplicada 
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 08/10/2026
-- Objetivo: Creacion  tabla espacio publicitario.

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'publicidad' AND TABLE_NAME = 'EspacioPublicitario')
BEGIN
	CREATE TABLE publicidad.EspacioPublicitario
	(
		IdEP INT,
		Tipo VARCHAR(30) NOT NULL,
		Costo DECIMAL(10,2) NOT NULL,
		CONSTRAINT PK_EspacioPublicitario PRIMARY KEY (IdEP),
		CONSTRAINT CK_EspacioPublicitario_Costo CHECK (Costo >= 0)
	);
END;
GO
