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
@IdPartido INT, @IdJugador INT, @IdSeleccion INT,
@Rol VARCHAR (10), @PosicionCancha VARCHAR(20) = NULL, @Esquema VARCHAR (10) = NULL
AS
BEGIN 
	DECLARE @errorCount INT = 0
	DECLARE @errorLine VARCHAR (300) = 'Error/es:'

	IF (@IdPartido IS NULL OR @IdPartido <=0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR (13) + '-Valor Invalido: IdPartido'
	END

	IF (@IdJugador IS NULL OR @IdJugador <=0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR (13) + '-Valor Invalido: IdJugador'
	END

	IF (@IdSeleccion IS NULL OR @IdSeleccion <=0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR (13) + '-Valor Invalido: IdSeleccion'
	END

	IF (@Rol IS NULL)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR (13) + '-Valor Invalido: Rol nulo'
	END

	IF (@ROL NOT IN ('Suplente', 'Titular'))
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR (13) + '-Valor Invalido: Rol'
	END

	IF (@errorCount = 0 AND NOT EXISTS(SELECT 1 FROM partidos.Partido WHERE IdPartido = @IdPartido))
	BEGIN
		SET @errorCount=@errorCount+1
		SET @errorLine=@errorLine+CHAR(13)+'- Valor inexistente: Partido'
	END

	IF (@errorCount = 0 AND NOT EXISTS(SELECT 1 FROM equipos.Jugador WHERE IdJugador = @IdJugador))
	BEGIN
		SET @errorCount=@errorCount+1
		SET @errorLine=@errorLine+CHAR(13)+'- Valor inexistente: Jugador'
	END

	IF (@errorCount = 0 AND NOT EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @IdSeleccion))
	BEGIN
		SET @errorCount=@errorCount+1
		SET @errorLine=@errorLine+CHAR(13)+'- Valor inexistente: Seleccion'
	END

	IF (@errorCount = 0 AND NOT EXISTS(SELECT 1 FROM equipos.Jugador WHERE IdJugador = @IdJugador AND Seleccion = @IdSeleccion))
	BEGIN
		SET @errorCount=@errorCount+1
		SET @errorLine=@errorLine+CHAR(13)+'- El jugador no esta convocado a esa seleccion'
	END

	IF (@errorCount = 0 AND NOT EXISTS(SELECT 1 FROM partidos.Partido WHERE IdPartido = @IdPartido AND (Eq1 = @IdSeleccion OR Eq2 = @IdSeleccion)))
	BEGIN
		SET @errorCount=@errorCount+1
		SET @errorLine=@errorLine+CHAR(13)+'- La seleccion no juega este partido'
	END

	IF (@errorCount = 0 AND EXISTS (SELECT 1 FROM partidos.Alineacion WHERE IdJugador = @IdJugador AND IdPartido = @IdPartido))
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR (13) + '- Jugador ya cargado'
	END

	IF (@errorCount = 0)
	INSERT INTO partidos.Alineacion (IdPartido, IdJugador, IdSeleccion, Rol, PosicionCancha, Esquema) 
	VALUES (@IdPartido, @IdJugador, @IdSeleccion, @Rol, @PosicionCancha, @Esquema)

	ELSE PRINT @errorLine

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
	DECLARE @errorCount INT = 0
	DECLARE @errorLine VARCHAR (300) = 'Error/es:'

	IF (@IdPartido IS NULL OR @IdPartido <=0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR (13) + '-Valor Invalido: IdPartido'
	END

	IF (@IdJugador IS NULL OR @IdJugador <=0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR (13) + '-Valor Invalido: IdJugador'
	END

	IF (@errorCount = 0 AND NOT EXISTS (SELECT 1 FROM partidos.Alineacion WHERE IdJugador = @IdJugador AND IdPartido = @IdPartido))
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR (13) + '-No existe alineacion a eliminar'
	END

	IF (@errorCount = 0 AND EXISTS(SELECT 1 FROM partidos.Evento WHERE Partido = @IdPartido))
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR (13) + '-Tabla siendo utilizada en Evento, no se puede eliminar'
	END

	IF (@errorCount = 0)
		DELETE FROM partidos.Alineacion WHERE IdJugador = @IdJugador AND IdPartido = @IdPartido

	ELSE PRINT @errorLine

END
GO
