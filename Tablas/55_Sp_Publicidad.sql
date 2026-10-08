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

--Publicidad
IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspPublicidad_Registrar'))
    DROP PROCEDURE SP.uspPublicidad_Registrar
GO
CREATE PROCEDURE SP.uspPublicidad_Registrar @nombre VARCHAR(50), @idCampania INT, @idIdioma INT
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine varchar(300)

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	IF(@nombre IS NULL)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Nombre.'
	END

	IF(@idCampania IS NULL) OR (@idCampania <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Campania.'
	END

	IF(@idIdioma IS NULL) OR (@idIdioma <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Idioma.'
	END

	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM TABLAS.Campania WHERE IdCampania = @idCampania)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: ID Campania.'
	END

	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM TABLAS.Idioma WHERE IdIdioma = @idIdioma)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: ID Idioma.'
	END

	IF(@errorCount = 0) AND EXISTS(SELECT 1 FROM TABLAS.Publicidad WHERE Nombre = @nombre)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor duplicado: Nombre.'
	END

	IF(@errorCount = 0)
		INSERT INTO TABLAS.Publicidad(Nombre, IdCampania, IdIdioma) VALUES (@nombre, @idCampania, @idIdioma)
	ELSE
		PRINT @errorLine
END;
GO

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspPublicidad_Update'))
    DROP PROCEDURE SP.uspPublicidad_Update
GO
CREATE PROCEDURE SP.uspPublicidad_Update @id INT, @nombre VARCHAR(50), @idCampania INT, @idIdioma INT
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine varchar(300)

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	IF(@id IS NULL) OR (@id <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Publicidad.'
	END

	IF(@nombre IS NULL)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Nombre.'
	END

	IF(@idCampania IS NULL) OR (@idCampania <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Campania.'
	END

	IF(@idIdioma IS NULL) OR (@idIdioma <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Idioma.'
	END

	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM TABLAS.Publicidad WHERE IdPublicidad = @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: ID Publicidad.'
	END

	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM TABLAS.Campania WHERE IdCampania = @idCampania)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: ID Campania.'
	END

	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM TABLAS.Idioma WHERE IdIdioma = @idIdioma)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: ID Idioma.'
	END

	IF(@errorCount = 0) AND EXISTS(SELECT 1 FROM TABLAS.Publicidad WHERE Nombre = @nombre AND IdPublicidad <> @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor duplicado: Nombre.'
	END

	IF(@errorCount = 0)
	BEGIN
		UPDATE TABLAS.Publicidad
		SET Nombre = @nombre, IdCampania = @idCampania, IdIdioma = @idIdioma
		WHERE IdPublicidad = @id
	END
	ELSE
		PRINT @errorLine
END;
GO

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspPublicidad_Bajar'))
    DROP PROCEDURE SP.uspPublicidad_Bajar
GO
CREATE PROCEDURE SP.uspPublicidad_Bajar @id INT
AS
BEGIN
	DECLARE @errorCount INT

	SET @errorCount = 0

	IF(@id IS NULL) OR (@id <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Valor invalido: ID Publicidad.'
	END

	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM TABLAS.Publicidad WHERE IdPublicidad = @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Valor inexistente: ID Publicidad.'
	END

	IF(@errorCount = 0) AND EXISTS(SELECT 1 FROM TABLAS.HistorialPublicidad WHERE IdPublicidad = @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Existen 1 o mas registros relacionados: HistorialPublicidad. Elimine dichos registros para continuar.'
	END

	IF(@errorCount = 0) AND EXISTS(SELECT 1 FROM TABLAS.PublicidadPais WHERE IdPublicidad = @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Existen 1 o mas registros relacionados: PublicidadPais. Elimine dichos registros para continuar.'
	END

	IF(@errorCount = 0)
		DELETE FROM TABLAS.Publicidad WHERE IdPublicidad = @id
END;
GO