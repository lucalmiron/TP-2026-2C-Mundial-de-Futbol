-- Universidad Nacional de La Matanza
-- Bases de datos aplicada 
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 08/10/2026
-- Objetivo: Registrar y Eliminar Alineacion

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID ('SP.uspAlineacion_Registrar'))
	DROP PROCEDURE SP.uspAlineacion_Registrar
GO

CREATE PROCEDURE SP.uspAlineacion_Registrar 
@IdPartido INT, @IdJugador INT,
@Rol VARCHAR (10), @PosicionCancha VARCHAR(20) = NULL, @Esquema VARCHAR (10) = NULL
AS
BEGIN 
	BEGIN TRY
		IF (@IdPartido IS NULL OR @IdPartido <=0)
			THROW 50000, '-Valor Invalido: IdPartido', 1;

		IF (@IdJugador IS NULL OR @IdJugador <=0)
			THROW 50000, '-Valor Invalido: IdJugador', 1;

		IF (@Rol IS NULL)
			THROW 50000, '-Valor Invalido: Rol nulo', 1;

		IF (@ROL NOT IN ('Suplente', 'Titular'))
			THROW 50000, '-Valor Invalido: Rol', 1;

		IF NOT EXISTS(SELECT 1 FROM partidos.Partido WHERE IdPartido = @IdPartido)
			THROW 50000, '- Valor inexistente: Partido', 1;

		IF NOT EXISTS(SELECT 1 FROM equipos.Jugador WHERE IdJugador = @IdJugador)
			THROW 50000, '- Valor inexistente: Jugador', 1;

		IF NOT EXISTS(SELECT 1 FROM partidos.Partido P
				INNER JOIN equipos.Jugador J ON J.IdJugador = @IdJugador
				WHERE P.IdPartido = @IdPartido AND (P.Eq1 = J.Seleccion OR P.Eq2 = J.Seleccion))
			THROW 50000, '- La seleccion del jugador no juega este partido', 1;

		IF EXISTS (SELECT 1 FROM partidos.Alineacion WHERE IdJugador = @IdJugador AND IdPartido = @IdPartido)
			THROW 50000, '- Jugador ya cargado', 1;

		INSERT INTO partidos.Alineacion (IdPartido, IdJugador, Rol, PosicionCancha, Esquema) 
		VALUES (@IdPartido, @IdJugador, @Rol, @PosicionCancha, @Esquema) 
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO 

---------------------------------------------------------------------------------------------------------------

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID ('SP.uspAlineacion_Bajar'))
	DROP PROCEDURE SP.uspAlineacion_Bajar
GO

CREATE PROCEDURE SP.uspAlineacion_Bajar
@IdPartido INT, @IdJugador INT
AS
BEGIN 
	BEGIN TRY
		IF (@IdPartido IS NULL OR @IdPartido <=0)
			THROW 50000, '-Valor Invalido: IdPartido', 1;

		IF (@IdJugador IS NULL OR @IdJugador <=0)
			THROW 50000, '-Valor Invalido: IdJugador', 1;

		IF NOT EXISTS (SELECT 1 FROM partidos.Alineacion WHERE IdJugador = @IdJugador AND IdPartido = @IdPartido)
			THROW 50000, '-No existe alineacion a eliminar', 1;

		IF EXISTS(SELECT 1 FROM partidos.Evento WHERE Partido = @IdPartido)
			THROW 50000, '-Tabla siendo utilizada en Evento, no se puede eliminar', 1;

		DELETE FROM partidos.Alineacion WHERE IdJugador = @IdJugador AND IdPartido = @IdPartido
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO