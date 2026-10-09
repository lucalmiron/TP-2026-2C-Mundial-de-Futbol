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

--Idioma
IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspIdioma_Registrar'))
    DROP PROCEDURE SP.uspIdioma_Registrar
GO
CREATE PROCEDURE SP.uspIdioma_Registrar @descripcion VARCHAR(20)
AS
BEGIN
	DECLARE @errorCount INT

	SET @errorCount = 0

	IF(@descripcion IS NULL)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Descripcion invalida.'
	END

	IF(@errorCount = 0) AND EXISTS(SELECT 1 FROM TABLAS.Idioma WHERE Descripcion = @descripcion)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Descripcion duplicada.'
	END

	IF(@errorCount = 0)
		INSERT INTO TABLAS.Idioma(Descripcion) VALUES (@descripcion)
END;
GO

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspIdioma_Update'))
    DROP PROCEDURE SP.uspIdioma_Update
GO
CREATE PROCEDURE SP.uspIdioma_Update @id INT, @descripcion VARCHAR(20)
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine varchar(300)

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	IF(@id IS NULL) OR (@id <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Idioma.'
	END

	IF(@descripcion IS NULL)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Descripcion.'
	END

	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM TABLAS.Idioma WHERE IdIdioma = @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: ID Idioma.'
	END

	IF(@errorCount = 0) AND EXISTS(SELECT 1 FROM TABLAS.Idioma WHERE Descripcion = @descripcion AND IdIdioma <> @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor duplicado: Descripcion.'
	END

	IF(@errorCount = 0)
	BEGIN
		UPDATE TABLAS.Idioma
		SET Descripcion = @descripcion
		WHERE IdIdioma = @id
	END
	ELSE
		PRINT @errorLine
END;
GO

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspIdioma_Bajar'))
    DROP PROCEDURE SP.uspIdioma_Bajar
GO
CREATE PROCEDURE SP.uspIdioma_Bajar @id INT
AS
BEGIN
	DECLARE @errorCount INT

	SET @errorCount = 0

	IF(@id IS NULL) OR (@id <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Valor invalido: ID Idioma.'
	END

	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM TABLAS.Idioma WHERE IdIdioma = @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Valor inexistente: ID Idioma.'
	END

	IF(@errorCount = 0)
	BEGIN
		IF EXISTS(SELECT 1 FROM TABLAS.HablaIdioma WHERE Idioma = @id)
		BEGIN
			SET @errorCount = @errorCount + 1
			PRINT '-ERROR- Existen 1 o mas registros relacionados: HablaIdioma. Elimine dichos registros para continuar.'
		END

		/*
		--La tabla Publicidad todavia no fue creada.
		--Descomentar cuando exista el script de creacion correspondiente.
		IF EXISTS(SELECT 1 FROM TABLAS.Publicidad WHERE Idioma = @id)
		BEGIN
			SET @errorCount = @errorCount + 1
			PRINT '-ERROR- Existen 1 o mas registros relacionados: Publicidad. Elimine dichos registros para continuar.'
		END
		*/
	END

	IF(@errorCount = 0)
		DELETE FROM TABLAS.Idioma WHERE IdIdioma = @id
END;
GO
