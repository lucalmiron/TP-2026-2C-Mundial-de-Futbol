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

--Campania
IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspCampania_Registrar'))
    DROP PROCEDURE SP.uspCampania_Registrar
GO
CREATE PROCEDURE SP.uspCampania_Registrar @nombre VARCHAR(50), @descripcion VARCHAR(200)
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

	IF(@descripcion IS NULL)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Descripcion.'
	END

	IF(@errorCount = 0) AND EXISTS(SELECT 1 FROM TABLAS.Campania WHERE Nombre = @nombre)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor duplicado: Nombre.'
	END

	IF(@errorCount = 0)
		INSERT INTO TABLAS.Campania(Nombre, Descripcion) VALUES (@nombre, @descripcion)
	ELSE
		PRINT @errorLine
END;
GO

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspCampania_Update'))
    DROP PROCEDURE SP.uspCampania_Update
GO
CREATE PROCEDURE SP.uspCampania_Update @id INT, @nombre VARCHAR(50), @descripcion VARCHAR(200)
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine varchar(300)

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	IF(@id IS NULL) OR (@id <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Campania.'
	END

	IF(@nombre IS NULL)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Nombre.'
	END

	IF(@descripcion IS NULL)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Descripcion.'
	END

	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM TABLAS.Campania WHERE IdCampania = @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: ID Campania.'
	END

	IF(@errorCount = 0) AND EXISTS(SELECT 1 FROM TABLAS.Campania WHERE Nombre = @nombre AND IdCampania <> @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor duplicado: Nombre.'
	END

	IF(@errorCount = 0)
	BEGIN
		UPDATE TABLAS.Campania
		SET Nombre = @nombre, Descripcion = @descripcion
		WHERE IdCampania = @id
	END
	ELSE
		PRINT @errorLine
END;
GO

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspCampania_Bajar'))
    DROP PROCEDURE SP.uspCampania_Bajar
GO
CREATE PROCEDURE SP.uspCampania_Bajar @id INT
AS
BEGIN
	DECLARE @errorCount INT

	SET @errorCount = 0

	IF(@id IS NULL) OR (@id <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Valor invalido: ID Campania.'
	END

	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM TABLAS.Campania WHERE IdCampania = @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Valor inexistente: ID Campania.'
	END

	IF(@errorCount = 0) AND EXISTS(SELECT 1 FROM TABLAS.Publicidad WHERE IdCampania = @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Existen 1 o mas registros relacionados: Publicidad. Elimine dichos registros para continuar.'
	END

	IF(@errorCount = 0) AND EXISTS(SELECT 1 FROM TABLAS.AnuncianteCampania WHERE IdCampania = @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Existen 1 o mas registros relacionados: AnuncianteCampania. Elimine dichos registros para continuar.'
	END

	IF(@errorCount = 0)
		DELETE FROM TABLAS.Campania WHERE IdCampania = @id
END;
GO