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
		IdEP INT IDENTITY(1,1),
		IdSede INT NOT NULL,
        Numero TINYINT NOT NULL,
        Tipo VARCHAR(30) NOT NULL,
		Costo DECIMAL(10,2) NOT NULL,
		CONSTRAINT CK_EspacioPublicitario_Numero CHECK (Numero BETWEEN 1 AND 4),
        CONSTRAINT UQ_EspacioPublicitario_SedeNumero UNIQUE (IdSede, Numero),
        CONSTRAINT PK_EspacioPublicitario PRIMARY KEY (IdEP),
		CONSTRAINT CK_EspacioPublicitario_Costo CHECK (Costo >= 0)
	);
END;
GO
