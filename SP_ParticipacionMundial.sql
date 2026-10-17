--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: xx/xx/2026

--Creacion de Tabla Amonestacion

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspParticipacionMundial_Registrar'))
    DROP PROCEDURE SP.uspParticipacionMundial_Registrar
GO
CREATE PROCEDURE SP.uspParticipacionMundial_Registrar
@mundial INT,
@seleccion INT
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine varchar(300)
	
	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	--chequeo validez
	IF(@mundial IS NULL) OR (@mundial <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Mundial.'
	END

	IF(@seleccion IS NULL) OR (@seleccion <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Seleccion.'
	END

	--chequeo existencia
	IF(@errorCount = 0)
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM sedes.Mundial WHERE IdMundial = @mundial)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Mundial.'
		END

		IF NOT EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @seleccion)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Seleccion.'
		END
	END

	--chequeo duplicidad
	IF(@errorCount = 0) AND EXISTS(SELECT 1 FROM equipos.ParticipacionMundial WHERE Mundial = @mundial AND Seleccion = @seleccion)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Relacion ya existente.'
	END

	IF(@errorCount = 0)
	BEGIN
		INSERT INTO equipos.ParticipacionMundial
		VALUES (@mundial, @seleccion)
	END
	ELSE
		PRINT @errorLine
END;
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspParticipacionMundial_Bajar'))
    DROP PROCEDURE SP.uspParticipacionMundial_Bajar
GO
CREATE PROCEDURE SP.uspParticipacionMundial_Bajar
@mundial INT,
@seleccion INT
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine varchar(300)
	
	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	--chequeo validez
	IF(@mundial IS NULL) OR (@mundial <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Mundial.'
	END

	IF(@seleccion IS NULL) OR (@seleccion <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Seleccion.'
	END

	--chequeo existencia
	IF(@errorCount = 0)
	AND
	NOT EXISTS(SELECT 1 FROM equipos.ParticipacionMundial WHERE Mundial = @mundial AND Seleccion = @seleccion)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Relacion inexistente.'
	END

	IF(@errorCount = 0)
	BEGIN
		DELETE FROM equipos.ParticipacionMundial
		WHERE Mundial = @mundial AND Seleccion = @seleccion
	END
	ELSE
		PRINT @errorLine
END;
GO