--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Creacion de Tabla Periodo

-- Ejecutar en la base seleccionada por el instalador.
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'partidos' AND TABLE_NAME = 'Periodo')
BEGIN
	CREATE TABLE partidos.Periodo
	(
		IdPeriodo INT,
		Descripcion VARCHAR(12) NOT NULL,
		Inicio INT NULL,
		Fin INT NULL,
		EsPenales BIT NOT NULL CONSTRAINT DF_Periodo_EsPenales DEFAULT 0,
        CONSTRAINT CK_Periodo_Limites CHECK (
            (EsPenales = 1 AND Inicio IS NULL AND Fin IS NULL) OR
            (EsPenales = 0 AND Inicio IS NOT NULL AND Fin IS NOT NULL AND Inicio >= 0 AND Fin >= Inicio)),
        CONSTRAINT PK_Periodo PRIMARY KEY (IdPeriodo),
		CONSTRAINT UQ_Periodo_Descripcion UNIQUE (Descripcion)
	);
END;
GO
