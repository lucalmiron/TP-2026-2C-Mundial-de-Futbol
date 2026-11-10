-- Preparación de base de prueba para ejecutar tests sueltos (03-69).
-- Crea la base, schemas, tablas y SPs. NO elimina la base al finalizar.
:setvar ScriptPath "."
:setvar BasePrueba "MUNDIAL_Final_Test_E5"

IF DB_ID('$(BasePrueba)') IS NOT NULL
BEGIN
    PRINT 'La base $(BasePrueba) ya existe. Se reutilizará.';
END
ELSE
BEGIN
    CREATE DATABASE [$(BasePrueba)] COLLATE Latin1_General_100_CI_AS_SC;
    PRINT 'Base $(BasePrueba) creada.';
END
GO

USE [$(BasePrueba)];
GO

IF NOT EXISTS (SELECT name FROM sys.schemas WHERE name = 'equipos')
BEGIN
    EXECUTE('CREATE SCHEMA equipos')
END
GO

IF NOT EXISTS (SELECT name FROM sys.schemas WHERE name = 'sedes')
BEGIN
    EXECUTE('CREATE SCHEMA sedes')
END
GO

IF NOT EXISTS (SELECT name FROM sys.schemas WHERE name = 'partidos')
BEGIN
    EXECUTE('CREATE SCHEMA partidos')
END
GO

IF NOT EXISTS (SELECT name FROM sys.schemas WHERE name = 'arbitros')
BEGIN
    EXECUTE('CREATE SCHEMA arbitros')
END
GO

IF NOT EXISTS (SELECT name FROM sys.schemas WHERE name = 'publicidad')
BEGIN
    EXECUTE('CREATE SCHEMA publicidad')
END
GO

IF NOT EXISTS (SELECT name FROM sys.schemas WHERE name = 'SP')
BEGIN
    EXECUTE('CREATE SCHEMA SP')
END
GO

IF NOT EXISTS (SELECT name FROM sys.schemas WHERE name = 'SPTRANS')
BEGIN
    EXECUTE('CREATE SCHEMA SPTRANS')
END

PRINT 'Base de prueba $(BasePrueba) lista para tests sueltos.';



-- Elimina la base de prueba creada por el 71_Preparar_Pruebas.sql.
-- Ejecutar con la base 'master' seleccionada (o cualquier otra que no sea la de prueba).
USE master;
GO

IF DB_ID(N'MUNDIAL_Final_Test_E5') IS NOT NULL
BEGIN
    ALTER DATABASE [MUNDIAL_Final_Test_E5] 
    SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    
    DROP DATABASE [MUNDIAL_Final_Test_E5];
    
    PRINT 'Base de prueba MUNDIAL_Final_Test_E5 eliminada.';
END
ELSE
BEGIN
    PRINT 'La base de prueba MUNDIAL_Final_Test_E5 no existe.';
END
GO