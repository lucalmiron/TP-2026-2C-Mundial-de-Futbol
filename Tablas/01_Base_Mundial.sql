--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 08/10/2026

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

--/Limpieza de las tablas de la version anterior.
--/Estas entidades vivian en el schema TABLAS; hoy cada una esta en su schema
--/(sedes, publicidad). Si no se eliminan quedan duplicadas con el mismo nombre.
IF EXISTS (SELECT name FROM MUNDIAL.sys.tables WHERE schema_id = SCHEMA_ID('TABLAS') AND name = 'Sede')
BEGIN
	DROP TABLE TABLAS.Sede;
END;
GO

IF EXISTS (SELECT name FROM MUNDIAL.sys.tables WHERE schema_id = SCHEMA_ID('TABLAS') AND name = 'EspacioPublicitario')
BEGIN
	DROP TABLE TABLAS.EspacioPublicitario;
END;
GO

IF EXISTS (SELECT name FROM MUNDIAL.sys.tables WHERE schema_id = SCHEMA_ID('TABLAS') AND name = 'CostoFranja')
BEGIN
	DROP TABLE TABLAS.CostoFranja;
END;
GO