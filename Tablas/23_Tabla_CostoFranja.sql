-- Universidad Nacional de La Matanza
-- Bases de datos aplicada 
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 08/10/2026
-- Objetivo: Creacion  tabla costoFranja.

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'publicidad' AND TABLE_NAME = 'CostoFranja')
BEGIN
	CREATE TABLE publicidad.CostoFranja
	(
		IdCF INT,
		TipoFranja VARCHAR(30) NOT NULL,
		Costo DECIMAL(10,2) NOT NULL,
		CONSTRAINT PK_CostoFranja PRIMARY KEY (IdCF),
		CONSTRAINT CK_CostoFranja_Costo CHECK (Costo >= 0)
	);
END;
GO
