--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 09/10/2026

--Objetivo: Gestionar Tabla PublicidadPais (solo Registrar y Bajar, PK inmutable)

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspPublicidadPais_Registrar'))
    DROP PROCEDURE SP.uspPublicidadPais_Registrar
GO
CREATE PROCEDURE SP.uspPublicidadPais_Registrar
@idPublicidad INT,
@idPais INT
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine VARCHAR(300)

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	IF (@idPublicidad IS NULL) OR (@idPublicidad <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Publicidad.'
	END

	IF (@idPais IS NULL) OR (@idPais <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Pais.'
	END

	IF (@errorCount = 0) AND NOT EXISTS (SELECT 1 FROM publicidad.Publicidad WHERE IdPublicidad = @idPublicidad)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: ID Publicidad.'
	END

	IF (@errorCount = 0) AND NOT EXISTS (SELECT 1 FROM equipos.Pais WHERE IdPais = @idPais)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: ID Pais.'
	END

	IF (@errorCount = 0) AND EXISTS (SELECT 1 FROM publicidad.PublicidadPais WHERE IdPublicidad = @idPublicidad AND IdPais = @idPais)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor duplicado: PublicidadPais.'
	END

	IF (@errorCount = 0)
	BEGIN
		BEGIN TRY
			INSERT INTO publicidad.PublicidadPais (IdPublicidad, IdPais)
			VALUES (@idPublicidad, @idPais)
		END TRY
		BEGIN CATCH
			PRINT CONCAT('ERROR (', ERROR_NUMBER(), '): ', ERROR_MESSAGE())
		END CATCH
	END
	ELSE
		PRINT @errorLine
END
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspPublicidadPais_Bajar'))
    DROP PROCEDURE SP.uspPublicidadPais_Bajar
GO
CREATE PROCEDURE SP.uspPublicidadPais_Bajar
@idPublicidad INT,
@idPais INT
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine VARCHAR(300)

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	IF (@idPublicidad IS NULL) OR (@idPublicidad <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Publicidad.'
	END

	IF (@idPais IS NULL) OR (@idPais <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Pais.'
	END

	IF (@errorCount = 0) AND NOT EXISTS (SELECT 1 FROM publicidad.PublicidadPais WHERE IdPublicidad = @idPublicidad AND IdPais = @idPais)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: PublicidadPais.'
	END

	IF (@errorCount = 0)
	BEGIN
		BEGIN TRY
			DELETE FROM publicidad.PublicidadPais WHERE IdPublicidad = @idPublicidad AND IdPais = @idPais
		END TRY
		BEGIN CATCH
			PRINT CONCAT('ERROR (', ERROR_NUMBER(), '): ', ERROR_MESSAGE())
		END CATCH
	END
	ELSE
		PRINT @errorLine
END
GO
