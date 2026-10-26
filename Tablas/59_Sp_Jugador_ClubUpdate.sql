--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Creacion de Stored Procedures

-- Ejecutar en la base seleccionada por el instalador.
GO

--Jugador
IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspJugador_ClubUpdate'))
    DROP PROCEDURE SP.uspJugador_ClubUpdate
GO
CREATE PROCEDURE SP.uspJugador_ClubUpdate
@id INT,
@club INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF(@id IS NULL) OR (@id<= 0)
			SET @errores += '- Valor invalido: ID Jugador.' + N' ';

		IF(@club IS NOT NULL) AND (@club <= 0)
			SET @errores += '- Valor invalido: Club.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM equipos.Jugador WHERE IdJugador = @id)
			SET @errores += '- Valor inexistente: IdJugador.' + N' ';

		IF (@club IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM equipos.Club WHERE IdClub = @club)
			SET @errores += '- Valor inexistente: Club.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		UPDATE equipos.Jugador
		SET Club = @club
		WHERE IdJugador = @id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO