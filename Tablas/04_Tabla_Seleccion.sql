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

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'TABLAS' AND TABLE_NAME = 'Seleccion')
BEGIN
	CREATE TABLE TABLAS.Seleccion(
		ID_SELECCION INT IDENTITY(1,1) PK_Seleccion PRIMARY KEY,
		ID_PAIS INT NOT NULL FK_Pais_Seleccion REFERENCES Pais(ID_PAIS),
		ID_MUNDIAL INT NOT NULL FK_Seleccion_Mundial REFERENCES Mundial(ID_MUNDIAL),
		ID_GRUPO INT NOT NULL FK_Seleccion_Grupo REFERENCES Grupo(ID_GRUPO),
		CONFEDERACION VARCHAR(45) NOT NULL
	);
END;
GO