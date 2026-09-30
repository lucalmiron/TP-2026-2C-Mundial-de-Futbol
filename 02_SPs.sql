IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

--Jugador
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspJugador_ClubUpdate'))
    DROP PROCEDURE SP.uspJugador_ClubUpdat
GO
CREATE PROCEDURE SP.uspJugador_ClubUpdate
@idJugador INT,
@clubJugador INT
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine varchar(300)

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	IF(@idJugador IS NULL) OR (@idJugador <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Jugador.'
	END

	IF(@clubJugador IS NOT NULL) AND (@clubJugador <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Club.'
	END

	IF(@errorCount = 0)
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM TABLAS.Jugador WHERE IdJugador = @idJugador)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: IdJugador.'
		END

		IF (@clubJugador IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM TABLAS.Club WHERE IdClub = @clubJugador)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Club.'
		END
	END

	IF(@errorCount = 0)
	BEGIN
		UPDATE TABLAS.Jugador
		SET Club = @clubJugador
		WHERE IdJugador = @idJugador
	END
	ELSE
		PRINT @errorLine
END;
GO