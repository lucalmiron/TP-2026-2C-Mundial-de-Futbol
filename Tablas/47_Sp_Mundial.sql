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
	BEGIN TRY
		IF (@idPais IS NULL) OR (@idPais <= 0)
			THROW 50000, '- Valor invalido: ID Pais.', 1;

		IF (@fechaInicio IS NULL) OR (@fechaFin IS NULL)
			THROW 50000, '- Valor invalido: Fechas de actividad.', 1;

		IF (@fechaInicio IS NOT NULL) AND (@fechaFin IS NOT NULL) AND (@fechaFin <= @fechaInicio)
			THROW 50000, '- La fecha de fin debe ser posterior a la de inicio.', 1;

		IF (@tamMin IS NULL) OR (@tamMax IS NULL)
			THROW 50000, '- Valor invalido: Tamanio de seleccion.', 1;

		IF (@tamMin IS NOT NULL) AND (@tamMax IS NOT NULL) AND (@tamMin > @tamMax)
			THROW 50000, '- El tamanio minimo no puede superar al maximo.', 1;

		IF (@ventanas IS NULL) OR (@ventanas <= 0)
			THROW 50000, '- Valor invalido: Ventanas de cambios.', 1;

		IF (@cantidad IS NULL) OR (@cantidad <= 0)
			THROW 50000, '- Valor invalido: Cantidad de cambios.', 1;

		IF (@suspMax IS NULL) OR (@suspMax <= 0)
			THROW 50000, '- Valor invalido: Maximo de tarjetas para suspension.', 1;

		IF (@suspTiempo IS NULL) OR (@suspTiempo <= 0)
			THROW 50000, '- Valor invalido: Tiempo de suspension.', 1;

		IF NOT EXISTS (SELECT 1 FROM equipos.Pais WHERE IdPais = @idPais)
			THROW 50000, '- Valor inexistente: ID Pais.', 1;

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
	DECLARE @vFechaInicio DATE
	DECLARE @vFechaFin DATE
	DECLARE @vTamMin INT
	DECLARE @vTamMax INT

	BEGIN TRY
		IF (@id IS NULL) OR (@id <= 0)
			THROW 50000, '- Valor invalido: ID Mundial.', 1;

		IF (@idPais IS NOT NULL) AND (@idPais <= 0)
			THROW 50000, '- Valor invalido: ID Pais.', 1;

		IF (@ventanas IS NOT NULL) AND (@ventanas <= 0)
			THROW 50000, '- Valor invalido: Ventanas de cambios.', 1;

		IF (@cantidad IS NOT NULL) AND (@cantidad <= 0)
			THROW 50000, '- Valor invalido: Cantidad de cambios.', 1;

		IF (@suspMax IS NOT NULL) AND (@suspMax <= 0)
			THROW 50000, '- Valor invalido: Maximo de tarjetas para suspension.', 1;

		IF (@suspTiempo IS NOT NULL) AND (@suspTiempo <= 0)
			THROW 50000, '- Valor invalido: Tiempo de suspension.', 1;

		IF NOT EXISTS (SELECT 1 FROM sedes.Mundial WHERE IdMundial = @id)
			THROW 50000, '- Valor inexistente: ID Mundial.', 1;

		IF (@idPais IS NOT NULL) AND NOT EXISTS (SELECT 1 FROM equipos.Pais WHERE IdPais = @idPais)
			THROW 50000, '- Valor inexistente: ID Pais.', 1;

		IF ((@fechaInicio IS NOT NULL) OR (@fechaFin IS NOT NULL))
		BEGIN
			SELECT @vFechaInicio = COALESCE(@fechaInicio, ACTIVIDAD_FECHA_INICIO), @vFechaFin = COALESCE(@fechaFin, ACTIVIDAD_FECHA_FIN) FROM sedes.Mundial WHERE IdMundial = @id

			IF (@vFechaFin <= @vFechaInicio)
				THROW 50000, '- La fecha de fin debe ser posterior a la de inicio.', 1;
		END

		IF ((@tamMin IS NOT NULL) OR (@tamMax IS NOT NULL))
		BEGIN
			SELECT @vTamMin = COALESCE(@tamMin, TAMANIO_SELECCION_MINIMO), @vTamMax = COALESCE(@tamMax, TAMANIO_SELECCION_MAXIMO) FROM sedes.Mundial WHERE IdMundial = @id

			IF (@vTamMin > @vTamMax)
				THROW 50000, '- El tamanio minimo no puede superar al maximo.', 1;
		END

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
	BEGIN TRY
		IF (@id IS NULL) OR (@id <= 0)
			THROW 50000, '- Valor invalido: ID Mundial.', 1;

		IF NOT EXISTS (SELECT 1 FROM sedes.Mundial WHERE IdMundial = @id)
			THROW 50000, '- Valor inexistente: ID Mundial.', 1;

		IF EXISTS (SELECT 1 FROM equipos.Seleccion WHERE IdMundial = @id)
			THROW 50000, '- Existen 1 o mas registros relacionados: Seleccion. Elimine dichos registros para continuar.', 1;

		IF EXISTS (SELECT 1 FROM partidos.Partido WHERE IdMundial = @id)
			THROW 50000, '- Existen 1 o mas registros relacionados: Partido. Elimine dichos registros para continuar.', 1;

		DELETE FROM sedes.Mundial WHERE IdMundial = @id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO