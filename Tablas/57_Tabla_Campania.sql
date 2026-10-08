--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 08/10/2026

--Creacion de Tabla Campania

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'TABLAS' AND TABLE_NAME = 'Campania')
BEGIN
	CREATE TABLE TABLAS.Campania
	(
		IdCampania INT PRIMARY KEY IDENTITY(1, 1),
		Nombre VARCHAR(50) NOT NULL,
		Descripcion VARCHAR(200) NOT NULL
	)
END;
GO