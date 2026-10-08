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

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'TABLAS' AND TABLE_NAME = 'Pais')
BEGIN
	CREATE TABLE TABLAS.Pais(
		IdPais INT IDENTITY(1,1) PK_Pais PRIMARY KEY,
		NOMBRE VARCHAR(50) NOT NULL,
		PBI BIGINT
	);
END;
GO