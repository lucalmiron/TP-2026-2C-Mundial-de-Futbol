--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02
--/Grupo 7 - Integrantes:
--/Almiron, Luca
--/Figueroa, Santiago
--/Ruarte, Fidel
--/Villalba, Leandro
--/Fecha: 26/10/26
--/Objetivo: SP de validacion de filas de importacion (Entrega 6)
--/  Marca filas validas / con error / duplicadas en el archivo

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

IF OBJECT_ID('SP.uspImportacion_Validar', 'P') IS NOT NULL
	DROP PROCEDURE SP.uspImportacion_Validar;
GO

CREATE PROCEDURE SP.uspImportacion_Validar
	@idArchivo INT,
	@cantidadErrores INT OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	-- Validez de cada fila. Los errores de una misma fila se agrupan en un unico mensaje (columna Detalle).
	UPDATE s
	SET s.Detalle = CASE WHEN e.Errores = '' THEN NULL ELSE 'Error/es:' + e.Errores END,
		s.Estado = CASE WHEN e.Errores = '' THEN 'Valida' ELSE 'Error' END
	FROM importacion.StagingPais AS s
	CROSS APPLY (
		SELECT 
			NombreL = ISNULL(LTRIM(RTRIM(REPLACE(REPLACE(s.NOMBRE, CHAR(13), ''), CHAR(10), ''))), ''),
			PBIL = NULLIF(LTRIM(RTRIM(REPLACE(REPLACE(s.PBI, CHAR(13), ''), CHAR(10), ''))), '')
	) AS l
	CROSS APPLY (SELECT PBIN = TRY_CAST(l.PBIL AS DECIMAL(24,2))) AS n
	CROSS APPLY (
		SELECT Errores = CONCAT(
			CASE WHEN l.NombreL = '' THEN CHAR(13) + '- Valor invalido: Nombre (vacio).' END,
			CASE WHEN LEN(l.NombreL) > 50 THEN CHAR(13) + '- Valor invalido: Nombre (maximo 50 caracteres).' END,
			CASE WHEN l.PBIL IS NOT NULL AND n.PBIN IS NULL THEN CHAR(13) + '- Valor invalido: PBI (formato numerico).' END,
			CASE WHEN n.PBIN < 0 THEN CHAR(13) + '- Valor invalido: PBI (negativo).' END,
			CASE WHEN n.PBIN > 9000000000000000000 THEN CHAR(13) + '- Valor invalido: PBI (fuera de rango).' END
		)
	) AS e
	WHERE s.IdArchivo = @idArchivo
	  AND s.Estado = 'Pendiente';

	-- Duplicados dentro del mismo archivo: se conserva la ultima aparicion y las anteriores se omiten (no son error).
	UPDATE s
	SET s.Estado = 'Omitida',
		s.Detalle = 'Pais repetido en el archivo: se conserva la ultima aparicion.'
	FROM importacion.StagingPais AS s
	INNER JOIN (
		SELECT IdFila,
			   ROW_NUMBER() OVER (
				   PARTITION BY LTRIM(RTRIM(REPLACE(REPLACE(NOMBRE, CHAR(13), ''), CHAR(10), '')))
				   ORDER BY IdFila DESC
			   ) AS rn
		FROM importacion.StagingPais
		WHERE IdArchivo = @idArchivo
		  AND Estado = 'Valida'
	) AS d ON d.IdFila = s.IdFila
	WHERE d.rn > 1;

	SELECT @cantidadErrores = COUNT(*)
	FROM importacion.StagingPais
	WHERE IdArchivo = @idArchivo
	  AND Estado = 'Error';
END;
GO

PRINT 'SP.uspImportacion_Validar creado correctamente.';
GO