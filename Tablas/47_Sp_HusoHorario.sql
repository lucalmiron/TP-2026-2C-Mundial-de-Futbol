--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 08/10/2026

--Creacion de Stored Procedures (ABM de HusoHorario)

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

--alta de huso horario
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspHusoHorario_Registrar'))
    DROP PROCEDURE SP.uspHusoHorario_Registrar
GO
CREATE PROCEDURE SP.uspHusoHorario_Registrar
@nombre VARCHAR(50),
@idPais INT
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

	IF(@idPais IS NULL) OR (@idPais <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Pais.'
	END

	--Chequeo existencia
	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @idPais)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Pais.'
	END

	--Chequeo dup
	IF(@errorCount = 0) AND EXISTS(SELECT 1 FROM sedes.HusoHorario WHERE Nombre = @nombre)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor duplicado: Nombre.'
	END

	IF(@errorCount = 0)
	BEGIN
		BEGIN TRY
			INSERT INTO sedes.HusoHorario(Nombre, IdPais)
			VALUES(LTRIM(RTRIM(@nombre)), @idPais)
		END TRY
		BEGIN CATCH
			PRINT CONCAT('ERROR (', ERROR_NUMBER(), '): ', ERROR_MESSAGE())
		END CATCH
	END
	ELSE
		PRINT @errorLine
END;
GO

--modificacion de huso horario
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspHusoHorario_Update'))
    DROP PROCEDURE SP.uspHusoHorario_Update
GO
CREATE PROCEDURE SP.uspHusoHorario_Update
@idHuso INT,
@nombre VARCHAR(50) = NULL,
@idPais INT = NULL
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine varchar(800)

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	--Chequeo validez (solo lo que vino con valor)
	IF(@idHuso IS NULL) OR (@idHuso <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID HusoHorario.'
	END

	IF(@nombre IS NOT NULL) AND (LTRIM(RTRIM(@nombre)) = '')
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Nombre.'
	END

	IF(@idPais IS NOT NULL) AND (@idPais <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Pais.'
	END

	--Chequeo existencia
	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM sedes.HusoHorario WHERE IdHuso = @idHuso)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: ID HusoHorario.'
	END

	IF(@errorCount = 0) AND (@idPais IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @idPais)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Pais.'
	END

	--Chequeo dup (excluyendo el propio registro)
	IF(@errorCount = 0) AND (@nombre IS NOT NULL)
	   AND EXISTS(SELECT 1 FROM sedes.HusoHorario WHERE Nombre = @nombre AND IdHuso <> @idHuso)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor duplicado: Nombre.'
	END

	IF(@errorCount = 0)
	BEGIN
		BEGIN TRY
			UPDATE sedes.HusoHorario
			SET Nombre = COALESCE(LTRIM(RTRIM(@nombre)), Nombre),
				IdPais = COALESCE(@idPais, IdPais)
			WHERE IdHuso = @idHuso
		END TRY
		BEGIN CATCH
			PRINT CONCAT('ERROR (', ERROR_NUMBER(), '): ', ERROR_MESSAGE())
		END CATCH
	END
	ELSE
		PRINT @errorLine
END;
GO

--baja de huso horario
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspHusoHorario_Bajar'))
    DROP PROCEDURE SP.uspHusoHorario_Bajar
GO
CREATE PROCEDURE SP.uspHusoHorario_Bajar
@idHuso INT
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine varchar(800)

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	--Chequeo validez
	IF(@idHuso IS NULL) OR (@idHuso <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID HusoHorario.'
	END

	--Chequeo existencia
	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM sedes.HusoHorario WHERE IdHuso = @idHuso)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: ID HusoHorario.'
	END

	--Chequeo relaciones
	IF(@errorCount = 0) AND EXISTS(SELECT 1 FROM sedes.Sede WHERE IdHuso = @idHuso)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Existen 1 o mas registros relacionados: Sede. Elimine dichos registros para continuar.'
	END

	IF(@errorCount = 0)
	BEGIN
		BEGIN TRY
			DELETE FROM sedes.HusoHorario
			WHERE IdHuso = @idHuso
		END TRY
		BEGIN CATCH
			PRINT CONCAT('ERROR (', ERROR_NUMBER(), '): ', ERROR_MESSAGE())
		END CATCH
	END
	ELSE
		PRINT @errorLine
END;
GO