--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 09/10/2026

--Objetivo: Gestionar Tabla AnuncianteCampania (solo Registrar y Bajar, PK inmutable)

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspAnuncianteCampania_Registrar'))
    DROP PROCEDURE SP.uspAnuncianteCampania_Registrar
GO
CREATE PROCEDURE SP.uspAnuncianteCampania_Registrar
@idAnunciante INT,
@idCampania INT
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine VARCHAR(300)

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	IF (@idAnunciante IS NULL) OR (@idAnunciante <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Anunciante.'
	END

	IF (@idCampania IS NULL) OR (@idCampania <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Campania.'
	END

	IF (@errorCount = 0) AND NOT EXISTS (SELECT 1 FROM publicidad.Anunciante WHERE IdAnunciante = @idAnunciante)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: ID Anunciante.'
	END

	IF (@errorCount = 0) AND NOT EXISTS (SELECT 1 FROM publicidad.Campania WHERE IdCampania = @idCampania)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: ID Campania.'
	END

	IF (@errorCount = 0) AND EXISTS (SELECT 1 FROM publicidad.AnuncianteCampania WHERE IdAnunciante = @idAnunciante AND IdCampania = @idCampania)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor duplicado: AnuncianteCampania.'
	END

	IF (@errorCount = 0)
	BEGIN
		BEGIN TRY
			INSERT INTO publicidad.AnuncianteCampania (IdAnunciante, IdCampania)
			VALUES (@idAnunciante, @idCampania)
		END TRY
		BEGIN CATCH
			PRINT CONCAT('ERROR (', ERROR_NUMBER(), '): ', ERROR_MESSAGE())
		END CATCH
	END
	ELSE
		PRINT @errorLine
END
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspAnuncianteCampania_Bajar'))
    DROP PROCEDURE SP.uspAnuncianteCampania_Bajar
GO
CREATE PROCEDURE SP.uspAnuncianteCampania_Bajar
@idAnunciante INT,
@idCampania INT
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine VARCHAR(300)

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	IF (@idAnunciante IS NULL) OR (@idAnunciante <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Anunciante.'
	END

	IF (@idCampania IS NULL) OR (@idCampania <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Campania.'
	END

	IF (@errorCount = 0) AND NOT EXISTS (SELECT 1 FROM publicidad.AnuncianteCampania WHERE IdAnunciante = @idAnunciante AND IdCampania = @idCampania)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: AnuncianteCampania.'
	END

	IF (@errorCount = 0)
	BEGIN
		BEGIN TRY
			DELETE FROM publicidad.AnuncianteCampania WHERE IdAnunciante = @idAnunciante AND IdCampania = @idCampania
		END TRY
		BEGIN CATCH
			PRINT CONCAT('ERROR (', ERROR_NUMBER(), '): ', ERROR_MESSAGE())
		END CATCH
	END
	ELSE
		PRINT @errorLine
END
GO
