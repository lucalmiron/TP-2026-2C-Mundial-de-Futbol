--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: xx/xx/2026

--Creacion de Base de Datos, Tablas y Schemas

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	CREATE DATABASE MUNDIAL
	COLLATE Latin1_General_100_CI_AS_SC
END;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

IF NOT EXISTS (SELECT name FROM sys.schemas WHERE name = 'TABLAS')
BEGIN
	EXECUTE('CREATE SCHEMA TABLAS')
END;
GO

IF NOT EXISTS (SELECT name FROM sys.schemas WHERE name = 'SPTRANS')
BEGIN
	EXECUTE('CREATE SCHEMA SPTRANS')
END;
GO

IF NOT EXISTS (SELECT name FROM sys.schemas WHERE name = 'SP')
BEGIN
	EXECUTE('CREATE SCHEMA SP')
END;
GO