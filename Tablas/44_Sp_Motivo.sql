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

--Motivo
IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspMotivo_Registrar'))
    DROP PROCEDURE SP.uspMotivo_Registrar
GO
CREATE PROCEDURE SP.uspMotivo_Registrar @descripcion VARCHAR(100)
AS
BEGIN
	DECLARE @errorCount INT

	SET @errorCount = 0

	IF(@descripcion IS NULL)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Descripcion invalido.'
	END

	IF(@errorCount = 0) AND EXISTS(SELECT 1 FROM publicidad.Motivo WHERE Descripcion = @descripcion)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Descripcion duplicado.'
	END

	IF(@errorCount = 0)
		INSERT INTO publicidad.Motivo(Descripcion) VALUES (@descripcion)
END;
GO

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspMotivo_Update'))
    DROP PROCEDURE SP.uspMotivo_Update
GO
CREATE PROCEDURE SP.uspMotivo_Update @id INT, @descripcion VARCHAR(100)
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine varchar(300)

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	IF(@id IS NULL) OR (@id <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Motivo.'
	END

	IF(@descripcion IS NULL)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Descripcion.'
	END

	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM publicidad.Motivo WHERE IdMotivo = @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: ID Motivo.'
	END

	IF(@errorCount = 0) AND EXISTS(SELECT 1 FROM publicidad.Motivo WHERE Descripcion = @descripcion AND IdMotivo <> @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor duplicado: Descripcion.'
	END

	IF(@errorCount = 0)
	BEGIN
		UPDATE publicidad.Motivo
		SET Descripcion = @descripcion
		WHERE IdMotivo = @id
	END
	ELSE
		PRINT @errorLine
END;
GO

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspMotivo_Bajar'))
    DROP PROCEDURE SP.uspMotivo_Bajar
GO
CREATE PROCEDURE SP.uspMotivo_Bajar @id INT
AS
BEGIN
	DECLARE @errorCount INT

	SET @errorCount = 0

	IF(@id IS NULL) OR (@id <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Valor invalido: ID Motivo.'
	END

	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM publicidad.Motivo WHERE IdMotivo = @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Valor inexistente: ID Motivo.'
	END
	IF(@errorCount = 0) AND EXISTS(SELECT 1 FROM partidos.Sustitucion WHERE Motivo = @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Existen 1 o mas registros relacionados: Sustitucion. Elimine dichos registros para continuar.'
	END

	IF(@errorCount = 0)
		DELETE FROM publicidad.Motivo WHERE IdMotivo = @id
END;
GO