--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 08/10/2026

--Creacion de Stored Procedures (ABM de Pais)

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspPais_Registrar'))
    DROP PROCEDURE SP.uspPais_Registrar
GO
CREATE PROCEDURE SP.uspPais_Registrar
@nombre VARCHAR(50),
@pbi BIGINT = NULL
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine varchar(800)

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	--Chequeo validez
	IF(@nombre IS NULL) OR (LTRIM(RTRIM(@nombre)) = '')
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Nombre.'
	END

	IF(@pbi IS NOT NULL) AND (@pbi < 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: PBI.'
	END

	--Chequeo dup
	IF(@errorCount = 0) AND EXISTS(SELECT 1 FROM equipos.Pais WHERE NOMBRE = LTRIM(RTRIM(@nombre)))
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor duplicado: Pais (nombre).'
	END

	IF(@errorCount = 0)
	BEGIN
		BEGIN TRY
			INSERT INTO equipos.Pais(NOMBRE, PBI)
			VALUES(LTRIM(RTRIM(@nombre)), @pbi)
		END TRY
		BEGIN CATCH
			PRINT CONCAT('ERROR (', ERROR_NUMBER(), '): ', ERROR_MESSAGE())
		END CATCH
	END
	ELSE
		PRINT @errorLine
END;
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspPais_Update'))
    DROP PROCEDURE SP.uspPais_Update
GO
CREATE PROCEDURE SP.uspPais_Update
@idPais INT,
@nombre VARCHAR(50) = NULL,
@pbi BIGINT = NULL
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine varchar(800)

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	--Chequeo validez
	IF(@idPais IS NULL) OR (@idPais <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Pais.'
	END

	IF(@nombre IS NOT NULL) AND (LTRIM(RTRIM(@nombre)) = '')
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Nombre.'
	END

	IF(@pbi IS NOT NULL) AND (@pbi < 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: PBI.'
	END

	--Chequeo existencia
	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @idPais)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: ID Pais.'
	END

	--Chequeo dup
	IF(@errorCount = 0) AND (@nombre IS NOT NULL)
	   AND EXISTS(SELECT 1 FROM equipos.Pais WHERE NOMBRE = LTRIM(RTRIM(@nombre)) AND IdPais <> @idPais)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor duplicado: Pais (nombre).'
	END

	IF(@errorCount = 0)
	BEGIN
		BEGIN TRY
			UPDATE equipos.Pais
			SET NOMBRE = COALESCE(LTRIM(RTRIM(@nombre)), NOMBRE),
				PBI = COALESCE(@pbi, PBI)
			WHERE IdPais = @idPais
		END TRY
		BEGIN CATCH
			PRINT CONCAT('ERROR (', ERROR_NUMBER(), '): ', ERROR_MESSAGE())
		END CATCH
	END
	ELSE
		PRINT @errorLine
END;
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspPais_Bajar'))
    DROP PROCEDURE SP.uspPais_Bajar
GO
CREATE PROCEDURE SP.uspPais_Bajar
@idPais INT
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine varchar(800)

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	--Chequeo validez
	IF(@idPais IS NULL) OR (@idPais <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Pais.'
	END

	--Chequeo existencia
	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @idPais)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: ID Pais.'
	END

	--Chequeo relaciones
	IF(@errorCount = 0)
	BEGIN
		IF EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdPais = @idPais)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Existen 1 o mas registros relacionados: Seleccion. Elimine dichos registros para continuar.'
		END

		IF EXISTS(SELECT 1 FROM sedes.Mundial WHERE IdPais = @idPais)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Existen 1 o mas registros relacionados: Mundial. Elimine dichos registros para continuar.'
		END

		IF EXISTS(SELECT 1 FROM sedes.HusoHorario WHERE IdPais = @idPais)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Existen 1 o mas registros relacionados: HusoHorario. Elimine dichos registros para continuar.'
		END

		IF EXISTS(SELECT 1 FROM sedes.Sede WHERE IdPais = @idPais)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Existen 1 o mas registros relacionados: Sede. Elimine dichos registros para continuar.'
		END

		IF EXISTS(SELECT 1 FROM equipos.Persona WHERE Pais = @idPais)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Existen 1 o mas registros relacionados: Persona. Elimine dichos registros para continuar.'
		END

		IF EXISTS(SELECT 1 FROM publicidad.Anunciante WHERE IdPais = @idPais)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Existen 1 o mas registros relacionados: Anunciante. Elimine dichos registros para continuar.'
		END

		IF EXISTS(SELECT 1 FROM publicidad.PublicidadPais WHERE IdPais = @idPais)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Existen 1 o mas registros relacionados: PublicidadPais. Elimine dichos registros para continuar.'
		END
	END

	IF(@errorCount = 0)
	BEGIN
		BEGIN TRY
			DELETE FROM equipos.Pais WHERE IdPais = @idPais
		END TRY
		BEGIN CATCH
			PRINT CONCAT('ERROR (', ERROR_NUMBER(), '): ', ERROR_MESSAGE())
		END CATCH
	END
	ELSE
		PRINT @errorLine
END;
GO
