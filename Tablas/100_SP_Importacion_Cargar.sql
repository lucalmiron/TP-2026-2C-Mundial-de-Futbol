--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02
--/Grupo 7 - Integrantes:
--/Almiron, Luca
--/Figueroa, Santiago
--/Ruarte, Fidel
--/Villalba, Leandro
--/Fecha: 23/10/2026
--/Objetivo: SP de carga/Upsert de importacion (Entrega 6)
--/  Staging + INSERT/UPDATE separados (set-based), sin cursor, sin MERGE
--/  Las validaciones ya se hicieron en SP.uspImportacion_Validar y SP.uspImportacion_Transformar

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

IF OBJECT_ID('SP.uspImportacion_Cargar', 'P') IS NOT NULL
	DROP PROCEDURE SP.uspImportacion_Cargar;
GO

CREATE PROCEDURE SP.uspImportacion_Cargar
	@idArchivo INT,
	@insertadas INT OUTPUT,
	@actualizadas INT OUTPUT,
	@sinCambios INT OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	SET @insertadas = 0;
	SET @actualizadas = 0;
	SET @sinCambios = 0;

	-- ============================================================
	-- Tabla temporal: clasificacion de filas validas
	-- ============================================================
	CREATE TABLE #Clasificacion (
		IdFila INT PRIMARY KEY,
		NombreLimpio VARCHAR(50) NOT NULL,
		PBIValor BIGINT NULL,
		Accion VARCHAR(12) NOT NULL -- 'Nuevo', 'Actualizar', 'SinCambios'
	);

	INSERT INTO #Clasificacion (IdFila, NombreLimpio, PBIValor, Accion)
	SELECT
		s.IdFila,
		s.NombreLimpio,
		s.PBIValor,
		CASE
			WHEN p.IdPais IS NULL THEN 'Nuevo'
			WHEN s.PBIValor IS NULL OR s.PBIValor = p.PBI THEN 'SinCambios'
			ELSE 'Actualizar'
		END
	FROM importacion.StagingPais s
	LEFT JOIN equipos.Pais p ON p.NOMBRE = s.NombreLimpio
	WHERE s.IdArchivo = @idArchivo
	  AND s.Estado = 'Valida';

	-- ============================================================
	-- 1) INSERTAR NUEVOS PAISES
	-- ============================================================
	BEGIN TRY
		INSERT INTO equipos.Pais (NOMBRE, PBI)
		SELECT c.NombreLimpio, c.PBIValor
		FROM #Clasificacion c
		WHERE c.Accion = 'Nuevo';

		UPDATE s
		SET s.Estado = 'Insertada'
		FROM importacion.StagingPais s
		INNER JOIN #Clasificacion c ON c.IdFila = s.IdFila
		WHERE c.Accion = 'Nuevo';

		SET @insertadas = @@ROWCOUNT;
	END TRY
	BEGIN CATCH
		UPDATE s
		SET s.Estado = 'Error',
			s.Detalle = 'Error/es:' + CHAR(13) + '- Error en INSERT: ' + ERROR_MESSAGE()
		FROM importacion.StagingPais s
		INNER JOIN #Clasificacion c ON c.IdFila = s.IdFila
		WHERE c.Accion = 'Nuevo';
		SET @insertadas = 0;
	END CATCH;

	-- ============================================================
	-- 2) ACTUALIZAR PAISES EXISTENTES CON CAMBIO DE PBI
	-- ============================================================
	BEGIN TRY
		UPDATE p
		SET p.PBI = c.PBIValor
		FROM equipos.Pais p
		INNER JOIN #Clasificacion c ON p.NOMBRE = c.NombreLimpio
		WHERE c.Accion = 'Actualizar';

		UPDATE s
		SET s.Estado = 'Actualizada'
		FROM importacion.StagingPais s
		INNER JOIN #Clasificacion c ON c.IdFila = s.IdFila
		WHERE c.Accion = 'Actualizar';

		SET @actualizadas = @@ROWCOUNT;
	END TRY
	BEGIN CATCH
		UPDATE s
		SET s.Estado = 'Error',
			s.Detalle = 'Error/es:' + CHAR(13) + '- Error en UPDATE: ' + ERROR_MESSAGE()
		FROM importacion.StagingPais s
		INNER JOIN #Clasificacion c ON c.IdFila = s.IdFila
		WHERE c.Accion = 'Actualizar';
		SET @actualizadas = 0;
	END CATCH;

	-- ============================================================
	-- 3) SIN CAMBIOS
	-- ============================================================
	UPDATE s
	SET s.Estado = 'SinCambios'
	FROM importacion.StagingPais s
	INNER JOIN #Clasificacion c ON c.IdFila = s.IdFila
	WHERE c.Accion = 'SinCambios';

	SET @sinCambios = @@ROWCOUNT;

	DROP TABLE #Clasificacion;
END;
GO

PRINT 'SP.uspImportacion_Cargar creado correctamente (set-based, sin cursor, sin MERGE).';
GO