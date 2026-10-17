--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: xx/xx/2026

--Creacion de Tabla SedeMundial

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'sedes' AND TABLE_NAME = 'SedeMundial')
BEGIN
	CREATE TABLE sedes.SedeMundial
	(
		Mundial INT,
		Pais INT,
		FOREIGN KEY(Mundial) REFERENCES sedes.Mundial(IdMundial),
		FOREIGN KEY(Pais) REFERENCES equipos.Pais(IdPais),
		PRIMARY KEY(Mundial, Pais)
	)
END;
GO