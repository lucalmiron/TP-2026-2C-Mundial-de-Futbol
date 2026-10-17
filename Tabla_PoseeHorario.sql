--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: xx/xx/2026

--Creacion de Tabla PoseeHorario

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'sedes' AND TABLE_NAME = 'PoseeHorario')
BEGIN
	CREATE TABLE sedes.PoseeHorario
	(
		Horario INT,
		Pais INT,
		FOREIGN KEY(Horario) REFERENCES sedes.HusoHorario(IdHuso),
		FOREIGN KEY(Pais) REFERENCES equipos.Pais(IdPais),
		PRIMARY KEY(Horario, Pais)
	)
END;
GO