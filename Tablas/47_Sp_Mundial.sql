--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Objetivo: Gestionar Tabla Mundial

-- Ejecutar en la base seleccionada por el instalador.
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
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF (@idPais IS NULL) OR (@idPais <= 0)
			SET @errores += '- Valor invalido: ID Pais.' + N' ';

		IF (@fechaInicio IS NULL) OR (@fechaFin IS NULL)
			SET @errores += '- Valor invalido: Fechas de actividad.' + N' ';

		IF (@fechaInicio IS NOT NULL) AND (@fechaFin IS NOT NULL) AND (@fechaFin <= @fechaInicio)
			SET @errores += '- La fecha de fin debe ser posterior a la de inicio.' + N' ';

		IF (@tamMin IS NULL) OR (@tamMax IS NULL)
			SET @errores += '- Valor invalido: Tamanio de seleccion.' + N' ';

		IF (@tamMin IS NOT NULL) AND (@tamMax IS NOT NULL) AND (@tamMin > @tamMax)
			SET @errores += '- El tamanio minimo no puede superar al maximo.' + N' ';

		IF (@ventanas IS NULL) OR (@ventanas <= 0)
			SET @errores += '- Valor invalido: Ventanas de cambios.' + N' ';

		IF (@cantidad IS NULL) OR (@cantidad <= 0)
			SET @errores += '- Valor invalido: Cantidad de cambios.' + N' ';

		IF (@suspMax IS NULL) OR (@suspMax <= 0)
			SET @errores += '- Valor invalido: Maximo de tarjetas para suspension.' + N' ';

		IF (@suspTiempo IS NULL) OR (@suspTiempo <= 0)
			SET @errores += '- Valor invalido: Tiempo de suspension.' + N' ';

		IF NOT EXISTS (SELECT 1 FROM equipos.Pais WHERE IdPais = @idPais)
			SET @errores += '- Valor inexistente: ID Pais.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		INSERT INTO sedes.Mundial (IdPais, ACTIVIDAD_FECHA_INICIO, ACTIVIDAD_FECHA_FIN, TAMANIO_SELECCION_MINIMO, TAMANIO_SELECCION_MAXIMO, CAMBIOS_VENTANAS, CAMBIOS_CANTIDAD, SUSPENSION_TARJETAS_MAXIMAS, SUSPENSION_TIEMPO)
		VALUES (@idPais, @fechaInicio, @fechaFin, @tamMin, @tamMax, @ventanas, @cantidad, @suspMax, @suspTiempo)
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
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
	DECLARE @errores NVARCHAR(2048) = N'';
	DECLARE @vFechaInicio DATE
	DECLARE @vFechaFin DATE
	DECLARE @vTamMin INT
	DECLARE @vTamMax INT

	BEGIN TRY
		IF (@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Mundial.' + N' ';

		IF (@idPais IS NOT NULL) AND (@idPais <= 0)
			SET @errores += '- Valor invalido: ID Pais.' + N' ';

		IF (@ventanas IS NOT NULL) AND (@ventanas <= 0)
			SET @errores += '- Valor invalido: Ventanas de cambios.' + N' ';

		IF (@cantidad IS NOT NULL) AND (@cantidad <= 0)
			SET @errores += '- Valor invalido: Cantidad de cambios.' + N' ';

		IF (@suspMax IS NOT NULL) AND (@suspMax <= 0)
			SET @errores += '- Valor invalido: Maximo de tarjetas para suspension.' + N' ';

		IF (@suspTiempo IS NOT NULL) AND (@suspTiempo <= 0)
			SET @errores += '- Valor invalido: Tiempo de suspension.' + N' ';

		IF NOT EXISTS (SELECT 1 FROM sedes.Mundial WHERE IdMundial = @id)
			SET @errores += '- Valor inexistente: ID Mundial.' + N' ';

		IF (@idPais IS NOT NULL) AND NOT EXISTS (SELECT 1 FROM equipos.Pais WHERE IdPais = @idPais)
			SET @errores += '- Valor inexistente: ID Pais.' + N' ';

		IF ((@fechaInicio IS NOT NULL) OR (@fechaFin IS NOT NULL))
		BEGIN
			SELECT @vFechaInicio = COALESCE(@fechaInicio, ACTIVIDAD_FECHA_INICIO), @vFechaFin = COALESCE(@fechaFin, ACTIVIDAD_FECHA_FIN) FROM sedes.Mundial WHERE IdMundial = @id

			IF (@vFechaFin <= @vFechaInicio)
				SET @errores += '- La fecha de fin debe ser posterior a la de inicio.' + N' ';
		END

		IF ((@tamMin IS NOT NULL) OR (@tamMax IS NOT NULL))
		BEGIN
			SELECT @vTamMin = COALESCE(@tamMin, TAMANIO_SELECCION_MINIMO), @vTamMax = COALESCE(@tamMax, TAMANIO_SELECCION_MAXIMO) FROM sedes.Mundial WHERE IdMundial = @id

			IF (@vTamMin > @vTamMax)
				SET @errores += '- El tamanio minimo no puede superar al maximo.' + N' ';
		END

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

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
		THROW;
	END CATCH
END
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspMundial_Bajar'))
    DROP PROCEDURE SP.uspMundial_Bajar
GO
CREATE PROCEDURE SP.uspMundial_Bajar
@id INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF (@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Mundial.' + N' ';

		IF NOT EXISTS (SELECT 1 FROM sedes.Mundial WHERE IdMundial = @id)
			SET @errores += '- Valor inexistente: ID Mundial.' + N' ';

		IF EXISTS (SELECT 1 FROM equipos.Seleccion WHERE IdMundial = @id)
			SET @errores += '- Existen 1 o mas registros relacionados: Seleccion. Elimine dichos registros para continuar.' + N' ';

		IF EXISTS (SELECT 1 FROM partidos.Partido WHERE IdMundial = @id)
			SET @errores += '- Existen 1 o mas registros relacionados: Partido. Elimine dichos registros para continuar.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		DELETE FROM sedes.Mundial WHERE IdMundial = @id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO