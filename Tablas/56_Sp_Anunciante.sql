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

--Anunciante
IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspAnunciante_Registrar'))
    DROP PROCEDURE SP.uspAnunciante_Registrar
GO
CREATE PROCEDURE SP.uspAnunciante_Registrar @nombre VARCHAR(50), @idPais INT
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

	IF(@idPais IS NULL) OR (@idPais <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Pais.'
	END

	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM TABLAS.Pais WHERE IdPais = @idPais)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: ID Pais.'
	END

	IF(@errorCount = 0) AND EXISTS(SELECT 1 FROM TABLAS.Anunciante WHERE Nombre = @nombre)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor duplicado: Nombre.'
	END

	IF(@errorCount = 0)
		INSERT INTO TABLAS.Anunciante(Nombre, IdPais) VALUES (@nombre, @idPais)
	ELSE
		PRINT @errorLine
END;
GO

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspAnunciante_Update'))
    DROP PROCEDURE SP.uspAnunciante_Update
GO
CREATE PROCEDURE SP.uspAnunciante_Update @id INT, @nombre VARCHAR(50), @idPais INT
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine varchar(300)

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	IF(@id IS NULL) OR (@id <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Anunciante.'
	END

	IF(@nombre IS NULL)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Nombre.'
	END

	IF(@idPais IS NULL) OR (@idPais <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Pais.'
	END

	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM TABLAS.Anunciante WHERE IdAnunciante = @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: ID Anunciante.'
	END

	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM TABLAS.Pais WHERE IdPais = @idPais)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: ID Pais.'
	END

	IF(@errorCount = 0) AND EXISTS(SELECT 1 FROM TABLAS.Anunciante WHERE Nombre = @nombre AND IdAnunciante <> @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor duplicado: Nombre.'
	END

	IF(@errorCount = 0)
	BEGIN
		UPDATE TABLAS.Anunciante
		SET Nombre = @nombre, IdPais = @idPais
		WHERE IdAnunciante = @id
	END
	ELSE
		PRINT @errorLine
END;
GO

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspAnunciante_Bajar'))
    DROP PROCEDURE SP.uspAnunciante_Bajar
GO
CREATE PROCEDURE SP.uspAnunciante_Bajar @id INT
AS
BEGIN
	DECLARE @errorCount INT

	SET @errorCount = 0

	IF(@id IS NULL) OR (@id <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Valor invalido: ID Anunciante.'
	END

	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM TABLAS.Anunciante WHERE IdAnunciante = @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Valor inexistente: ID Anunciante.'
	END

	IF(@errorCount = 0) AND EXISTS(SELECT 1 FROM TABLAS.AnuncianteCampania WHERE IdAnunciante = @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Existen 1 o mas registros relacionados: AnuncianteCampania. Elimine dichos registros para continuar.'
	END

	IF(@errorCount = 0)
		DELETE FROM TABLAS.Anunciante WHERE IdAnunciante = @id
END;
GO