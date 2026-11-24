--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: xx/xx/2026

--Testing de SP de conversion de horario a traves de API

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

/*
--Activo opciones para habilitar el uso de APIs
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'Ole Automation Procedures', 1;
RECONFIGURE;
GO
*/

--Testing
DECLARE @horaI TIME;
DECLARE @horaF TIME;

SET @horaI = CONVERT(TIME, GETDATE())

EXECUTE SP.uspAPIconversionHora 
@fecha = '2026-10-23', 
@hora = @horaI,
@timezone = 'America/New_York', 
@horaConv = @horaF OUTPUT;

PRINT @horaF
GO

/*
--Desactivo opciones para habilitar el uso de APIs
EXEC sp_configure 'Ole Automation Procedures', 0;
RECONFIGURE;
EXEC sp_configure 'show advanced options', 0;
RECONFIGURE;
GO
*/