-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Comision 02
-- Grupo 7: Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 06/11/2026.
-- Objetivo: registrar el Mundial con IdMundial = 1 usando SP.uspMundial_Registrar.
-- Requiere ejecutar despues del script 06 (paises) y antes del script 07 (selecciones).
-- Re-ejecutable: si el Mundial ya existe, no falla.

USE MUNDIALtesting;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

IF @@TRANCOUNT <> 0 OR (2 & @@OPTIONS) = 2
    THROW 51800, 'Ejecute sin transaccion externa y con IMPLICIT_TRANSACTIONS OFF.', 1;

IF OBJECT_ID(N'SP.uspMundial_Registrar', N'P') IS NULL
    THROW 51801, 'Falta SP.uspMundial_Registrar. Ejecute primero el instalador (00_Ejecutar_Todo.sql).', 1;

IF OBJECT_ID(N'equipos.Pais', N'U') IS NULL
    THROW 51802, 'Falta la tabla equipos.Pais. Ejecute primero la carga 06.', 1;

IF OBJECT_ID(N'sedes.Mundial', N'U') IS NULL
    THROW 51803, 'Falta la tabla sedes.Mundial. Ejecute primero el instalador.', 1;

DECLARE @idPais INT;
DECLARE @fechaInicio DATE = '2026-06-11';
DECLARE @fechaFin DATE = '2026-07-19';
DECLARE @tamMin INT = 23;
DECLARE @tamMax INT = 26;
DECLARE @ventanas INT = 3;
DECLARE @cantidad INT = 5;
DECLARE @suspMax INT = 2;
DECLARE @suspTiempo INT = 1;

SELECT @idPais = MIN(IdPais)
FROM equipos.Pais WITH (HOLDLOCK)
WHERE NOMBRE = 'USA';

IF @idPais IS NULL
    THROW 51804, 'No se encontro el pais Estados Unidos en equipos.Pais. Ejecute primero la carga 06 y verificá el nombre exacto.', 1;

IF NOT EXISTS (SELECT 1 FROM sedes.Mundial WITH (HOLDLOCK) WHERE IdMundial = 1)
BEGIN
    EXEC SP.uspMundial_Registrar
        @idPais = @idPais,
        @fechaInicio = @fechaInicio,
        @fechaFin = @fechaFin,
        @tamMin = @tamMin,
        @tamMax = @tamMax,
        @ventanas = @ventanas,
        @cantidad = @cantidad,
        @suspMax = @suspMax,
        @suspTiempo = @suspTiempo;

    PRINT 'Mundial IdMundial = 1 creado con pais Estados Unidos (IdPais = ' + CAST(@idPais AS VARCHAR) + ').';
END
ELSE
BEGIN
    PRINT 'El Mundial IdMundial = 1 ya existe. No se realizaron cambios.';
END;
GO