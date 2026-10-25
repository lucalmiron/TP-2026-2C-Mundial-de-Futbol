--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 08/10/2026

--Creacion de BD y Schemas para testing

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIALtesting')
BEGIN
	CREATE DATABASE MUNDIALtesting
	COLLATE Latin1_General_100_CI_AS_SC
END;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIALtesting')
BEGIN
	USE MUNDIALtesting
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

IF NOT EXISTS (SELECT name FROM sys.schemas WHERE name = 'equipos')
BEGIN
	EXECUTE('CREATE SCHEMA equipos')
END;
GO

IF NOT EXISTS (SELECT name FROM sys.schemas WHERE name = 'sedes')
BEGIN
	EXECUTE('CREATE SCHEMA sedes')
END;
GO

IF NOT EXISTS (SELECT name FROM sys.schemas WHERE name = 'partidos')
BEGIN
	EXECUTE('CREATE SCHEMA partidos')
END;
GO

IF NOT EXISTS (SELECT name FROM sys.schemas WHERE name = 'arbitros')
BEGIN
	EXECUTE('CREATE SCHEMA arbitros')
END;
GO

IF NOT EXISTS (SELECT name FROM sys.schemas WHERE name = 'publicidad')
BEGIN
	EXECUTE('CREATE SCHEMA publicidad')
END;
GO