--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 08/10/2026

--Creacion de Tabla Anunciante

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'publicidad' AND TABLE_NAME = 'Anunciante')
BEGIN
	CREATE TABLE publicidad.Anunciante
	(
		IdAnunciante INT PRIMARY KEY IDENTITY(1, 1),
		Nombre VARCHAR(50) NOT NULL,
		IdPais INT NOT NULL,
		FOREIGN KEY(IdPais) REFERENCES equipos.Pais(IdPais)
	)
END;
GO