--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: xx/xx/2026

--Creacion de Tablas

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO


IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'TABLAS' AND TABLE_NAME = 'Persona')
BEGIN
	CREATE TABLE TABLAS.Persona
	(
		IdPersona INT PRIMARY KEY IDENTITY(1, 1),
		Nombre VARCHAR(30),
		Fnac DATE,
		Rol VARCHAR(10),
		Pais INT,
		FOREIGN KEY(Pais) REFERENCES TABLAS.Pais(IdPais)
	);
END;
GO
