--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 08/10/2026

--Creacion de Stored Procedures

IF EXISTS(SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
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
	BEGIN TRY
		IF(@id IS NULL) OR (@id<= 0)
			THROW 50000, '- Valor invalido: ID Jugador.', 1;

		IF(@club IS NOT NULL) AND (@club <= 0)
			THROW 50000, '- Valor invalido: Club.', 1;

		IF NOT EXISTS(SELECT 1 FROM equipos.Jugador WHERE IdJugador = @id)
			THROW 50000, '- Valor inexistente: IdJugador.', 1;

		IF (@club IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM equipos.Club WHERE IdClub = @club)
			THROW 50000, '- Valor inexistente: Club.', 1;

		UPDATE equipos.Jugador
		SET Club = @club
		WHERE IdJugador = @id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO