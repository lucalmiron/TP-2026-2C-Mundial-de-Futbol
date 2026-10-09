--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 09/10/2026

--Objetivo: Gestionar Tabla Grupo

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspGrupo_Registrar'))
    DROP PROCEDURE SP.uspGrupo_Registrar
GO
CREATE PROCEDURE SP.uspGrupo_Registrar
@nombre VARCHAR(10)
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine VARCHAR(300)

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	IF (@nombre IS NULL) OR (LTRIM(RTRIM(@nombre)) = '')
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Nombre.'
	END

	IF (@errorCount = 0) AND EXISTS (SELECT 1 FROM equipos.Grupo WHERE NOMBRE = LTRIM(RTRIM(@nombre)))
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor duplicado: Grupo (nombre).'
	END

	IF (@errorCount = 0)
	BEGIN
		BEGIN TRY
			INSERT INTO equipos.Grupo (NOMBRE)
			VALUES (LTRIM(RTRIM(@nombre)))
		END TRY
		BEGIN CATCH
			PRINT CONCAT('ERROR (', ERROR_NUMBER(), '): ', ERROR_MESSAGE())
		END CATCH
	END
	ELSE
		PRINT @errorLine
END
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspGrupo_Update'))
    DROP PROCEDURE SP.uspGrupo_Update
GO
CREATE PROCEDURE SP.uspGrupo_Update
@id INT,
@nombre VARCHAR(10)
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine VARCHAR(300)

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	IF (@id IS NULL) OR (@id <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Grupo.'
	END

	IF (@nombre IS NULL) OR (LTRIM(RTRIM(@nombre)) = '')
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Nombre.'
	END

	IF (@errorCount = 0) AND NOT EXISTS (SELECT 1 FROM equipos.Grupo WHERE IdGrupo = @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: ID Grupo.'
	END

	IF (@errorCount = 0) AND EXISTS (SELECT 1 FROM equipos.Grupo WHERE NOMBRE = LTRIM(RTRIM(@nombre)) AND IdGrupo <> @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor duplicado: Grupo (nombre).'
	END

	IF (@errorCount = 0)
	BEGIN
		BEGIN TRY
			UPDATE equipos.Grupo
			SET NOMBRE = LTRIM(RTRIM(@nombre))
			WHERE IdGrupo = @id
		END TRY
		BEGIN CATCH
			PRINT CONCAT('ERROR (', ERROR_NUMBER(), '): ', ERROR_MESSAGE())
		END CATCH
	END
	ELSE
		PRINT @errorLine
END
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspGrupo_Bajar'))
    DROP PROCEDURE SP.uspGrupo_Bajar
GO
CREATE PROCEDURE SP.uspGrupo_Bajar
@id INT
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine VARCHAR(300)

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	IF (@id IS NULL) OR (@id <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Grupo.'
	END

	IF (@errorCount = 0) AND NOT EXISTS (SELECT 1 FROM equipos.Grupo WHERE IdGrupo = @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: ID Grupo.'
	END

	IF (@errorCount = 0) AND EXISTS (SELECT 1 FROM equipos.Seleccion WHERE IdGrupo = @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Existen 1 o mas registros relacionados: Seleccion. Elimine dichos registros para continuar.'
	END

	IF (@errorCount = 0)
	BEGIN
		BEGIN TRY
			DELETE FROM equipos.Grupo WHERE IdGrupo = @id
		END TRY
		BEGIN CATCH
			PRINT CONCAT('ERROR (', ERROR_NUMBER(), '): ', ERROR_MESSAGE())
		END CATCH
	END
	ELSE
		PRINT @errorLine
END
GO
