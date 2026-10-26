--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02
--/Grupo 7 - Integrantes:
--/Almiron, Luca
--/Figueroa, Santiago
--/Ruarte, Fidel
--/Villalba, Leandro
--/Fecha: 26/10/26
--/Objetivo: SP de transformacion de datos de importacion (Entrega 6)
--/  Limpia y convierte los tipos de las filas validas

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

IF OBJECT_ID('SP.uspImportacion_Transformar', 'P') IS NOT NULL
	DROP PROCEDURE SP.uspImportacion_Transformar;
GO

CREATE PROCEDURE SP.uspImportacion_Transformar
	@idArchivo INT
AS
BEGIN
	SET NOCOUNT ON;

	-- Limpieza de texto y conversion a los tipos de la tabla destino.
	-- El PBI se guarda tal cual viene (el dataset de Pais no trae montos en otra moneda).
	-- Si un archivo trajera montos en otra moneda, la conversion se haria aca, en T-SQL.
	UPDATE importacion.StagingPais
	SET NombreLimpio = LTRIM(RTRIM(REPLACE(REPLACE(NOMBRE, CHAR(13), ''), CHAR(10), ''))),
		PBIValor = CAST(TRY_CAST(
			NULLIF(LTRIM(RTRIM(REPLACE(REPLACE(PBI, CHAR(13), ''), CHAR(10), ''))), '') 
		AS DECIMAL(24,2)) AS BIGINT)
	WHERE IdArchivo = @idArchivo
	  AND Estado = 'Valida';
END;
GO

PRINT 'SP.uspImportacion_Transformar creado correctamente.';
GO