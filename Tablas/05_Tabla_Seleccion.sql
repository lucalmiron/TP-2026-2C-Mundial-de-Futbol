--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 08/10/2026

--Creacion de Tablas

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'TABLAS' AND TABLE_NAME = 'Seleccion')
BEGIN
	CREATE TABLE TABLAS.Seleccion(
		IdSeleccion INT IDENTITY(1,1) PK_Seleccion PRIMARY KEY,
		IdPais INT NOT NULL FK_Seleccion_Pais REFERENCES TABLAS.Pais(IdPais),
		IdMundial INT NOT NULL FK_Seleccion_Mundial REFERENCES TABLAS.Mundial(IdMundial),
		IdGrupo INT NOT NULL FK_Seleccion_Grupo REFERENCES TABLAS.Grupo(IdGrupo),
		CONFEDERACION VARCHAR(45) NOT NULL
	);
END;
GO