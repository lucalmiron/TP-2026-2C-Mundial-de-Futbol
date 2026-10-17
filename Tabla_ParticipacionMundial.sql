--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: xx/xx/2026

--Creacion de Tabla ParticipacionMundial

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'equipos' AND TABLE_NAME = 'ParticipacionMundial')
BEGIN
	CREATE TABLE equipos.ParticipacionMundial
	(
		Mundial INT,
		Seleccion INT,
		FOREIGN KEY(Mundial) REFERENCES sedes.Mundial(IdMundial),
		FOREIGN KEY(Seleccion) REFERENCES equipos.Seleccion(IdSeleccion),
		PRIMARY KEY(Mundial, Seleccion)
	)
END;
GO