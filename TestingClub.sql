--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: xx/xx/2026

--Testing de StoredProcedures asociados a la entidad Club

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIALtesting')
BEGIN
	USE MUNDIALtesting
END;
GO

--tablas a testear
CREATE TABLE TABLAS.Club
(
	IdClub INT PRIMARY KEY IDENTITY(1, 1),
	Nombre VARCHAR(20)
);
GO

--tablas aux de testing
CREATE TABLE TABLAS.Jugador
(
	IdJugador INT PRIMARY KEY,
	Club INT NULL,
	FOREIGN KEY(Club) REFERENCES TABLAS.Club(IdClub)
);
GO

--SPs a testear
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspClub_Registrar'))
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

	IF(@errorCount = 0) AND EXISTS(SELECT 1 FROM TABLAS.Club WHERE Nombre LIKE @nombre)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Nombre duplicado.'
	END

	IF(@errorCount = 0)
		INSERT INTO TABLAS.Club(Nombre) VALUES (@nombre)
END;
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspClub_Update'))
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

	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM TABLAS.Club WHERE IdClub = @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: ID Club.'
	END

	IF(@errorCount = 0) AND EXISTS(SELECT 1 FROM TABLAS.Club WHERE Nombre LIKE @nombre AND IdClub <> @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor duplicado: Nombre.'
	END

	IF(@errorCount = 0)
	BEGIN
		UPDATE TABLAS.Club
		SET Nombre = @nombre
		WHERE IdClub = @id
	END
	ELSE
		PRINT @errorLine
END;
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspClub_Bajar'))
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

	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM TABLAS.Club WHERE IdClub = @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Valor inexistente: ID Club.'
	END

	IF(@errorCount = 0) AND EXISTS(SELECT 1 FROM TABLAS.Jugador WHERE Club LIKE @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Existen 1 o mas registros relacionados: Jugador. Elimine dichos registros para continuar.'
	END

	IF(@errorCount = 0)
		DELETE FROM TABLAS.Club WHERE IdClub = @id
END;
GO

--llenado de tablas a testear con registro exitoso
EXECUTE SP.uspClub_Registrar @nombre = 'Real Madrid';
EXECUTE SP.uspClub_Registrar @nombre = 'Barcelona FC';

SELECT * FROM TABLAS.Club;
GO
--llenado de tablas auxiliares
INSERT INTO TABLAS.Jugador VALUES (1, 2);

SELECT * FROM TABLAS.Jugador;
GO

----Testeo
--/Registro
--Fallido (Valores invalidos)
EXECUTE SP.uspClub_Registrar @nombre = NULL;

SELECT * FROM TABLAS.Club;
GO
--Fallido (Valores dup)
EXECUTE SP.uspClub_Registrar @nombre = 'Real Madrid';

SELECT * FROM TABLAS.Club;
GO
--/Update
--Exitoso
EXECUTE SP.uspClub_Update @id = 1, @nombre = 'Realisimo Madrid';

SELECT * FROM TABLAS.Club;
GO
--Fallido(Valores invalidos)
EXECUTE SP.uspClub_Update @id = 0, @nombre = NULL;

SELECT * FROM TABLAS.Club;
GO
--Fallido(Valores inexistentes)
EXECUTE SP.uspClub_Update @id = 40, @nombre = 'Realisimo Madrid';

SELECT * FROM TABLAS.Club;
GO
--Fallido(Valores dup)
EXECUTE SP.uspClub_Update @id = 1, @nombre = 'Barcelona FC';

SELECT * FROM TABLAS.Club;
GO
--/Baja
--Exitoso
EXECUTE SP.uspClub_Bajar @id = 1;

SELECT * FROM TABLAS.Club;
GO
--Fallido(Valores invalidos)
EXECUTE SP.uspClub_Bajar @id = 0;

SELECT * FROM TABLAS.Club;
GO
--Fallido(Valores inexistentes)
EXECUTE SP.uspClub_Bajar @id = 40;

SELECT * FROM TABLAS.Club;
GO
--Fallido(Registros referenciados)
EXECUTE SP.uspClub_Bajar @id = 2;

SELECT * FROM TABLAS.Club;
GO

--limpieza
DROP PROCEDURE SP.uspClub_Registrar;
DROP PROCEDURE SP.uspClub_Update;
DROP PROCEDURE SP.uspClub_Bajar;
GO

DROP TABLE TABLAS.Jugador;
DROP TABLE TABLAS.Club;
GO