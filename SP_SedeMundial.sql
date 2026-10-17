--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: xx/xx/2026

--Creacion de SPs de tabla SedeMundial

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspSedeMundial_Registrar'))
    DROP PROCEDURE SP.uspSedeMundial_Registrar
GO
CREATE PROCEDURE SP.uspSedeMundial_Registrar
@mundial INT,
@pais INT
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

	IF(@pais IS NULL) OR (@pais <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Pais.'
	END

	--chequeo existencia
	IF(@errorCount = 0)
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM sedes.Mundial WHERE IdMundial = @mundial)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Mundial.'
		END

		IF NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @pais)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Pais.'
		END
	END

	--chequeo duplicidad
	IF(@errorCount = 0) AND EXISTS(SELECT 1 FROM sedes.SedeMundial WHERE Mundial = @mundial AND Pais = @pais)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Relacion ya existente.'
	END

	IF(@errorCount = 0)
	BEGIN
		INSERT INTO sedes.SedeMundial
		VALUES (@mundial, @pais)
	END
	ELSE
		PRINT @errorLine
END;
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspSedeMundial_Bajar'))
    DROP PROCEDURE SP.uspSedeMundial_Bajar
GO
CREATE PROCEDURE SP.uspSedeMundial_Bajar
@mundial INT,
@pais INT
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

	IF(@pais IS NULL) OR (@pais <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Pais.'
	END

	--chequeo existencia
	IF(@errorCount = 0)
	AND
	NOT EXISTS(SELECT 1 FROM sedes.SedeMundial WHERE Mundial = @mundial AND Pais = @pais)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Relacion inexistente.'
	END

	IF(@errorCount = 0)
	BEGIN
		DELETE FROM sedes.SedeMundial
		WHERE Mundial = @mundial AND Pais = @pais
	END
	ELSE
		PRINT @errorLine
END;
GO