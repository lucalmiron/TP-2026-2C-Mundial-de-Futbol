--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 08/10/2026

--Objetivo: Gestionar Tabla Sustitucion

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspSustitucion_Registrar'))
    DROP PROCEDURE SPTRANS.uspSustitucion_Registrar
GO
CREATE PROCEDURE SPTRANS.uspSustitucion_Registrar
@minuto INT,
@partido INT,
@periodo INT,
@ingreso INT,
@egreso INT,
@motivo INT
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine VARCHAR(300)
	DECLARE @vSeleccion INT
	DECLARE @vCambios INT
	DECLARE @vVentanas INT
	DECLARE @vMaxCambios INT
	DECLARE @vMaxVentanas INT

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	IF (@minuto IS NULL) OR (@minuto < 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Minuto.'
	END

	IF (@partido IS NULL) OR (@partido <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Partido.'
	END

	IF (@periodo IS NULL) OR (@periodo <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Periodo.'
	END

	IF (@ingreso IS NULL) OR (@ingreso <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Ingreso.'
	END

	IF (@egreso IS NULL) OR (@egreso <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Egreso.'
	END

	IF (@motivo IS NULL) OR (@motivo <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Motivo.'
	END

	IF (@errorCount = 0) AND (@ingreso = @egreso)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Ingreso y egreso no pueden ser el mismo jugador.'
	END

	IF (@errorCount = 0)
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM partidos.Partido WHERE IdPartido = @partido)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Partido.'
		END

		IF NOT EXISTS (SELECT 1 FROM partidos.Periodo WHERE IdPeriodo = @periodo)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Periodo.'
		END

		IF NOT EXISTS (SELECT 1 FROM equipos.Jugador WHERE IdJugador = @ingreso)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Ingreso.'
		END

		IF NOT EXISTS (SELECT 1 FROM equipos.Jugador WHERE IdJugador = @egreso)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Egreso.'
		END

		IF NOT EXISTS (SELECT 1 FROM publicidad.Motivo WHERE IdMotivo = @motivo)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Motivo.'
		END
	END

	IF (@errorCount = 0)
	BEGIN
		SET @vSeleccion = (SELECT Seleccion FROM equipos.Jugador WHERE IdJugador = @egreso)

		IF (SELECT Seleccion FROM equipos.Jugador WHERE IdJugador = @ingreso) <> @vSeleccion
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Ingreso y egreso deben ser de la misma seleccion.'
		END

		IF NOT EXISTS (SELECT 1 FROM partidos.Partido WHERE IdPartido = @partido AND (Eq1 = @vSeleccion OR Eq2 = @vSeleccion))
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- La seleccion no juega este partido.'
		END

		IF NOT EXISTS (SELECT 1 FROM partidos.Alineacion WHERE IdPartido = @partido AND IdJugador = @egreso AND Rol = 'Titular')
		AND NOT EXISTS (SELECT 1 FROM partidos.Sustitucion S INNER JOIN partidos.Evento E ON S.IdSustitucion = E.IdEvento WHERE E.Partido = @partido AND S.Egreso = @egreso)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- El egreso no estaba en cancha.'
		END

		IF NOT EXISTS (SELECT 1 FROM partidos.Alineacion WHERE IdPartido = @partido AND IdJugador = @ingreso AND Rol = 'Suplente')
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- El ingreso no estaba en el banco.'
		END
	END

	IF (@errorCount = 0)
	BEGIN
		--Solo se trabaja con el Mundial 2026, por eso se toma el limite sin filtrar por IdMundial.
		SELECT TOP 1 @vMaxCambios = CAMBIOS_CANTIDAD, @vMaxVentanas = CAMBIOS_VENTANAS FROM sedes.Mundial

		SELECT @vCambios = COUNT(*) FROM partidos.Sustitucion S INNER JOIN partidos.Evento E ON S.IdSustitucion = E.IdEvento INNER JOIN equipos.Jugador J ON S.Egreso = J.IdJugador WHERE E.Partido = @partido AND J.Seleccion = @vSeleccion

		SELECT @vVentanas = COUNT(DISTINCT E.Minuto) FROM partidos.Sustitucion S INNER JOIN partidos.Evento E ON S.IdSustitucion = E.IdEvento INNER JOIN equipos.Jugador J ON S.Egreso = J.IdJugador WHERE E.Partido = @partido AND J.Seleccion = @vSeleccion

		IF (@vCambios + 1) > @vMaxCambios
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Tope de cambios del reglamento excedido.'
		END

		IF NOT EXISTS (SELECT 1 FROM partidos.Sustitucion S INNER JOIN partidos.Evento E ON S.IdSustitucion = E.IdEvento INNER JOIN equipos.Jugador J ON S.Egreso = J.IdJugador WHERE E.Partido = @partido AND J.Seleccion = @vSeleccion AND E.Minuto = @minuto)
		AND (@vVentanas + 1) > @vMaxVentanas
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Tope de ventanas del reglamento excedido.'
		END
	END

	IF (@errorCount = 0)
	BEGIN
		DECLARE @idEvento INT

		BEGIN TRANSACTION
		BEGIN TRY
			INSERT INTO partidos.Evento (Minuto, Tipo, Partido, Periodo)
			VALUES (@minuto, 'Sustitucion', @partido, @periodo)

			SET @idEvento = SCOPE_IDENTITY()

			INSERT INTO partidos.Sustitucion (IdSustitucion, Ingreso, Egreso, Motivo)
			VALUES (@idEvento, @ingreso, @egreso, @motivo)

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

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspSustitucion_Bajar'))
    DROP PROCEDURE SPTRANS.uspSustitucion_Bajar
GO
CREATE PROCEDURE SPTRANS.uspSustitucion_Bajar
@id INT
AS
BEGIN
	DECLARE @errorCount INT

	SET @errorCount = 0

	IF (@id IS NULL) OR (@id <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Valor invalido: ID Sustitucion.'
	END

	IF (@errorCount = 0) AND NOT EXISTS (SELECT 1 FROM partidos.Sustitucion WHERE IdSustitucion = @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Registro inexistente.'
	END

	IF (@errorCount = 0)
	BEGIN
		BEGIN TRANSACTION
		BEGIN TRY
			DELETE FROM partidos.Sustitucion
			WHERE IdSustitucion = @id

			DELETE FROM partidos.Evento
			WHERE IdEvento = @id

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