-- Universidad Nacional de La Matanza
-- Bases de datos aplicada 
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 26/10/26
-- Objetivo: Creacion  tabla costoFranja.

-- Ejecutar en la base seleccionada por el instalador.
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'publicidad' AND TABLE_NAME = 'CostoFranja')
BEGIN
	CREATE TABLE publicidad.CostoFranja
	(
		IdCF INT IDENTITY(1,1),
		IdSede INT NOT NULL,
        TipoFranja VARCHAR(30) NOT NULL,
		Costo DECIMAL(10,2) NOT NULL,
		CONSTRAINT UQ_CostoFranja_SedeTipo UNIQUE (IdSede, TipoFranja),
        CONSTRAINT PK_CostoFranja PRIMARY KEY (IdCF),
		CONSTRAINT CK_CostoFranja_Costo CHECK (Costo >= 0)
	);
END;
GO
