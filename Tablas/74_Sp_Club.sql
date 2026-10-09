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

--Club
IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspClub_Registrar'))
    DROP PROCEDURE SP.uspClub_Registrar
GO
CREATE PROCEDURE SP.uspClub_Registrar @nombre VARCHAR(20)
AS
BEGIN
	DECLARE @errorCount INT

	SET @errorCount = 0

	IF(@nombre IS NULL)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Nombre invalido.'
	END

	IF(@errorCount = 0) AND EXISTS(SELECT 1 FROM equipos.Club WHERE Nombre = @nombre)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Nombre duplicado.'
	END

	IF(@errorCount = 0)
		INSERT INTO equipos.Club(Nombre) VALUES (@nombre)
END;
GO

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspClub_Update'))
    DROP PROCEDURE SP.uspClub_Update
GO
CREATE PROCEDURE SP.uspClub_Update @id INT, @nombre VARCHAR(20)
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine varchar(300)

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	IF(@id IS NULL) OR (@id <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Club.'
	END

	IF(@nombre IS NULL)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Nombre.'
	END

	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM equipos.Club WHERE IdClub = @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: ID Club.'
	END

	IF(@errorCount = 0) AND EXISTS(SELECT 1 FROM equipos.Club WHERE Nombre = @nombre AND IdClub <> @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor duplicado: Nombre.'
	END

	IF(@errorCount = 0)
	BEGIN
		UPDATE equipos.Club
		SET Nombre = @nombre
		WHERE IdClub = @id
	END
	ELSE
		PRINT @errorLine
END;
GO

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspClub_Bajar'))
    DROP PROCEDURE SP.uspClub_Bajar
GO
CREATE PROCEDURE SP.uspClub_Bajar @id INT
AS
BEGIN
	DECLARE @errorCount INT

	SET @errorCount = 0

	IF(@id IS NULL) OR (@id <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Valor invalido: ID Club.'
	END

	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM equipos.Club WHERE IdClub = @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Valor inexistente: ID Club.'
	END

	IF(@errorCount = 0) AND EXISTS(SELECT 1 FROM equipos.Jugador WHERE Club = @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Existen 1 o mas registros relacionados: Jugador. Elimine dichos registros para continuar.'
	END

	IF(@errorCount = 0)
		DELETE FROM equipos.Club WHERE IdClub = @id
END;
GO
