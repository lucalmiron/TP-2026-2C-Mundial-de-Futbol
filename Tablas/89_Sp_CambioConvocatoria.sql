--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 08/10/2026

--Objetivo: Gestionar Tabla CambioConvocatoria

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspCambioConvocatoria_Registrar'))
    DROP PROCEDURE SPTRANS.uspCambioConvocatoria_Registrar
GO
CREATE PROCEDURE SPTRANS.uspCambioConvocatoria_Registrar
@seleccion INT,
@egreso INT,
@ingreso INT,
@fecha DATE,
@motivo VARCHAR(200)
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine VARCHAR(300)
	DECLARE @vActivos INT
	DECLARE @vMin INT
	DECLARE @vMax INT

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	IF (@seleccion IS NULL) OR (@seleccion <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Seleccion.'
	END

	IF (@egreso IS NULL) OR (@egreso <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Egreso.'
	END

	IF (@ingreso IS NULL) OR (@ingreso <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Ingreso.'
	END

	IF (@fecha IS NULL)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Fecha.'
	END

	IF (@motivo IS NULL)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Motivo.'
	END

	IF (@errorCount = 0) AND (@egreso = @ingreso)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Egreso e ingreso no pueden ser el mismo jugador.'
	END

	IF (@errorCount = 0)
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM TABLAS.Seleccion WHERE IdSeleccion = @seleccion)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Seleccion.'
		END

		IF NOT EXISTS (SELECT 1 FROM TABLAS.Jugador WHERE IdJugador = @egreso AND Seleccion = @seleccion AND Estado = 'Activo')
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- El egreso no es un convocado activo de la seleccion.'
		END

		IF NOT EXISTS (SELECT 1 FROM TABLAS.Jugador WHERE IdJugador = @ingreso AND Seleccion = @seleccion)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- El ingreso no pertenece a la seleccion.'
		END

		IF EXISTS (SELECT 1 FROM TABLAS.Jugador WHERE IdJugador = @ingreso AND Seleccion = @seleccion AND Estado = 'Activo')
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- El ingreso ya es un convocado activo.'
		END
	END

	IF (@errorCount = 0)
	BEGIN
		SELECT @vMin = TAMANIO_SELECCION_MINIMO, @vMax = TAMANIO_SELECCION_MAXIMO FROM sedes.Mundial
		SELECT @vActivos = COUNT(*) FROM TABLAS.Jugador WHERE Seleccion = @seleccion AND Estado = 'Activo'

		IF (@vActivos < @vMin) OR (@vActivos > @vMax)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- La convocatoria incumple el cupo del reglamento.'
		END
	END

	IF (@errorCount = 0)
	BEGIN
		BEGIN TRANSACTION
		BEGIN TRY
			UPDATE TABLAS.Jugador
			SET Estado = 'Inactivo'
			WHERE IdJugador = @egreso

			UPDATE TABLAS.Jugador
			SET Estado = 'Activo'
			WHERE IdJugador = @ingreso

			INSERT INTO TABLAS.CambioConvocatoria (Seleccion, Egreso, Ingreso, Fecha, Motivo)
			VALUES (@seleccion, @egreso, @ingreso, @fecha, @motivo)

			COMMIT TRANSACTION
		END TRY
		BEGIN CATCH
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION

			DECLARE @Msg NVARCHAR(500) = ERROR_MESSAGE()
			DECLARE @Num INT = ERROR_NUMBER()
			PRINT CONCAT('ERROR (', @Num, '): ', @Msg)
		END CATCH
	END
	ELSE
		PRINT @errorLine
END
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspCambioConvocatoria_Bajar'))
    DROP PROCEDURE SPTRANS.uspCambioConvocatoria_Bajar
GO
CREATE PROCEDURE SPTRANS.uspCambioConvocatoria_Bajar
@id INT
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @vEgreso INT
	DECLARE @vIngreso INT

	SET @errorCount = 0

	IF (@id IS NULL) OR (@id <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Valor invalido: ID Cambio.'
	END

	IF (@errorCount = 0) AND NOT EXISTS (SELECT 1 FROM TABLAS.CambioConvocatoria WHERE IdCambio = @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Registro inexistente.'
	END

	IF (@errorCount = 0)
	BEGIN
		BEGIN TRANSACTION
		BEGIN TRY
			SELECT @vEgreso = Egreso, @vIngreso = Ingreso FROM TABLAS.CambioConvocatoria WHERE IdCambio = @id

			UPDATE TABLAS.Jugador
			SET Estado = 'Activo'
			WHERE IdJugador = @vEgreso

			UPDATE TABLAS.Jugador
			SET Estado = 'Inactivo'
			WHERE IdJugador = @vIngreso

			DELETE FROM TABLAS.CambioConvocatoria
			WHERE IdCambio = @id

			COMMIT TRANSACTION
		END TRY
		BEGIN CATCH
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION

			DECLARE @Msg NVARCHAR(500) = ERROR_MESSAGE()
			DECLARE @Num INT = ERROR_NUMBER()
			PRINT CONCAT('ERROR (', @Num, '): ', @Msg)
		END CATCH
	END
END
GO