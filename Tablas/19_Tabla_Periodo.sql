--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 08/10/2026

--Creacion de Tabla Periodo

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'partidos' AND TABLE_NAME = 'Periodo')
BEGIN
	CREATE TABLE partidos.Periodo
	(
		IdPeriodo INT,
		Descripcion VARCHAR(12) NOT NULL,
		Inicio INT NOT NULL,
		Fin INT NOT NULL,
		CONSTRAINT PK_Periodo PRIMARY KEY (IdPeriodo),
		CONSTRAINT UQ_Periodo_Descripcion UNIQUE (Descripcion)
	);
END;
GO
