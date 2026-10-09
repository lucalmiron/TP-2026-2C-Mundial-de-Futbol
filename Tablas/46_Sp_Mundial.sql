--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 09/10/2026

--Objetivo: Gestionar Tabla Mundial

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspMundial_Registrar'))
    DROP PROCEDURE SP.uspMundial_Registrar
GO
CREATE PROCEDURE SP.uspMundial_Registrar
@idPais INT,
@fechaInicio DATE,
@fechaFin DATE,
@tamMin INT,
@tamMax INT,
@ventanas INT,
@cantidad INT,
@suspMax INT,
@suspTiempo INT
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine VARCHAR(300)

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	IF (@idPais IS NULL) OR (@idPais <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Pais.'
	END

	IF (@fechaInicio IS NULL) OR (@fechaFin IS NULL)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Fechas de actividad.'
	END

	IF (@fechaInicio IS NOT NULL) AND (@fechaFin IS NOT NULL) AND (@fechaFin <= @fechaInicio)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- La fecha de fin debe ser posterior a la de inicio.'
	END

	IF (@tamMin IS NULL) OR (@tamMax IS NULL)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Tamanio de seleccion.'
	END

	IF (@tamMin IS NOT NULL) AND (@tamMax IS NOT NULL) AND (@tamMin > @tamMax)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- El tamanio minimo no puede superar al maximo.'
	END

	IF (@ventanas IS NULL) OR (@ventanas <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Ventanas de cambios.'
	END

	IF (@cantidad IS NULL) OR (@cantidad <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Cantidad de cambios.'
	END

	IF (@suspMax IS NULL) OR (@suspMax <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Maximo de tarjetas para suspension.'
	END

	IF (@suspTiempo IS NULL) OR (@suspTiempo <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Tiempo de suspension.'
	END

	IF (@errorCount = 0) AND NOT EXISTS (SELECT 1 FROM equipos.Pais WHERE IdPais = @idPais)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: ID Pais.'
	END

	IF (@errorCount = 0)
	BEGIN
		BEGIN TRY
			INSERT INTO sedes.Mundial (IdPais, ACTIVIDAD_FECHA_INICIO, ACTIVIDAD_FECHA_FIN, TAMANIO_SELECCION_MINIMO, TAMANIO_SELECCION_MAXIMO, CAMBIOS_VENTANAS, CAMBIOS_CANTIDAD, SUSPENSION_TARJETAS_MAXIMAS, SUSPENSION_TIEMPO)
			VALUES (@idPais, @fechaInicio, @fechaFin, @tamMin, @tamMax, @ventanas, @cantidad, @suspMax, @suspTiempo)
		END TRY
		BEGIN CATCH
			PRINT CONCAT('ERROR (', ERROR_NUMBER(), '): ', ERROR_MESSAGE())
		END CATCH
	END
	ELSE
		PRINT @errorLine
END
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspMundial_Update'))
    DROP PROCEDURE SP.uspMundial_Update
GO
CREATE PROCEDURE SP.uspMundial_Update
@id INT,
@idPais INT = NULL,
@fechaInicio DATE = NULL,
@fechaFin DATE = NULL,
@tamMin INT = NULL,
@tamMax INT = NULL,
@ventanas INT = NULL,
@cantidad INT = NULL,
@suspMax INT = NULL,
@suspTiempo INT = NULL
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine VARCHAR(300)
	DECLARE @vFechaInicio DATE
	DECLARE @vFechaFin DATE
	DECLARE @vTamMin INT
	DECLARE @vTamMax INT

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	IF (@id IS NULL) OR (@id <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Mundial.'
	END

	IF (@idPais IS NOT NULL) AND (@idPais <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Pais.'
	END

	IF (@ventanas IS NOT NULL) AND (@ventanas <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Ventanas de cambios.'
	END

	IF (@cantidad IS NOT NULL) AND (@cantidad <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Cantidad de cambios.'
	END

	IF (@suspMax IS NOT NULL) AND (@suspMax <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Maximo de tarjetas para suspension.'
	END

	IF (@suspTiempo IS NOT NULL) AND (@suspTiempo <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Tiempo de suspension.'
	END

	IF (@errorCount = 0) AND NOT EXISTS (SELECT 1 FROM sedes.Mundial WHERE IdMundial = @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: ID Mundial.'
	END

	IF (@errorCount = 0) AND (@idPais IS NOT NULL) AND NOT EXISTS (SELECT 1 FROM equipos.Pais WHERE IdPais = @idPais)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: ID Pais.'
	END

	IF (@errorCount = 0) AND ((@fechaInicio IS NOT NULL) OR (@fechaFin IS NOT NULL))
	BEGIN
		SELECT @vFechaInicio = COALESCE(@fechaInicio, ACTIVIDAD_FECHA_INICIO), @vFechaFin = COALESCE(@fechaFin, ACTIVIDAD_FECHA_FIN) FROM sedes.Mundial WHERE IdMundial = @id

		IF (@vFechaFin <= @vFechaInicio)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- La fecha de fin debe ser posterior a la de inicio.'
		END
	END

	IF (@errorCount = 0) AND ((@tamMin IS NOT NULL) OR (@tamMax IS NOT NULL))
	BEGIN
		SELECT @vTamMin = COALESCE(@tamMin, TAMANIO_SELECCION_MINIMO), @vTamMax = COALESCE(@tamMax, TAMANIO_SELECCION_MAXIMO) FROM sedes.Mundial WHERE IdMundial = @id

		IF (@vTamMin > @vTamMax)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- El tamanio minimo no puede superar al maximo.'
		END
	END

	IF (@errorCount = 0)
	BEGIN
		BEGIN TRY
			UPDATE sedes.Mundial
			SET IdPais = COALESCE(@idPais, IdPais),
				ACTIVIDAD_FECHA_INICIO = COALESCE(@fechaInicio, ACTIVIDAD_FECHA_INICIO),
				ACTIVIDAD_FECHA_FIN = COALESCE(@fechaFin, ACTIVIDAD_FECHA_FIN),
				TAMANIO_SELECCION_MINIMO = COALESCE(@tamMin, TAMANIO_SELECCION_MINIMO),
				TAMANIO_SELECCION_MAXIMO = COALESCE(@tamMax, TAMANIO_SELECCION_MAXIMO),
				CAMBIOS_VENTANAS = COALESCE(@ventanas, CAMBIOS_VENTANAS),
				CAMBIOS_CANTIDAD = COALESCE(@cantidad, CAMBIOS_CANTIDAD),
				SUSPENSION_TARJETAS_MAXIMAS = COALESCE(@suspMax, SUSPENSION_TARJETAS_MAXIMAS),
				SUSPENSION_TIEMPO = COALESCE(@suspTiempo, SUSPENSION_TIEMPO)
			WHERE IdMundial = @id
		END TRY
		BEGIN CATCH
			PRINT CONCAT('ERROR (', ERROR_NUMBER(), '): ', ERROR_MESSAGE())
		END CATCH
	END
	ELSE
		PRINT @errorLine
END
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspMundial_Bajar'))
    DROP PROCEDURE SP.uspMundial_Bajar
GO
CREATE PROCEDURE SP.uspMundial_Bajar
@id INT
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine VARCHAR(300)

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	IF (@id IS NULL) OR (@id <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Mundial.'
	END

	IF (@errorCount = 0) AND NOT EXISTS (SELECT 1 FROM sedes.Mundial WHERE IdMundial = @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: ID Mundial.'
	END

	IF (@errorCount = 0)
	BEGIN
		IF EXISTS (SELECT 1 FROM equipos.Seleccion WHERE IdMundial = @id)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Existen 1 o mas registros relacionados: Seleccion. Elimine dichos registros para continuar.'
		END

		IF EXISTS (SELECT 1 FROM partidos.Partido WHERE IdMundial = @id)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Existen 1 o mas registros relacionados: Partido. Elimine dichos registros para continuar.'
		END
	END

	IF (@errorCount = 0)
	BEGIN
		BEGIN TRY
			DELETE FROM sedes.Mundial WHERE IdMundial = @id
		END TRY
		BEGIN CATCH
			PRINT CONCAT('ERROR (', ERROR_NUMBER(), '): ', ERROR_MESSAGE())
		END CATCH
	END
	ELSE
		PRINT @errorLine
END
GO
