--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 08/10/2026

--Testing de StoredProcedures asociados a la entidad Club

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIALtesting')
BEGIN
	USE MUNDIALtesting
END;
GO

DROP TABLE IF EXISTS equipos.Jugador
DROP TABLE IF EXISTS equipos.Club
GO

--tablas a testear
CREATE TABLE equipos.Club
(
	IdClub INT PRIMARY KEY IDENTITY(1, 1),
	Nombre VARCHAR(20)
);
GO

--tablas aux de testing
CREATE TABLE equipos.Jugador
(
	IdJugador INT PRIMARY KEY,
	Club INT NULL,
	FOREIGN KEY(Club) REFERENCES equipos.Club(IdClub)
);
GO

--SPs a testear
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspClub_Registrar'))
    DROP PROCEDURE SP.uspClub_Registrar
GO
CREATE PROCEDURE SP.uspClub_Registrar @nombre VARCHAR(20)
AS
BEGIN
	BEGIN TRY
		IF(@nombre IS NULL)
			THROW 50000, '- Valor invalido: Nombre.', 1;

		IF EXISTS(SELECT 1 FROM equipos.Club WHERE Nombre = @nombre)
			THROW 50000, '- Valor duplicado: Nombre.', 1;

		INSERT INTO equipos.Club(Nombre) VALUES (@nombre)
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspClub_Update'))
    DROP PROCEDURE SP.uspClub_Update
GO
CREATE PROCEDURE SP.uspClub_Update @id INT, @nombre VARCHAR(20)
AS
BEGIN
	BEGIN TRY
		IF(@id IS NULL) OR (@id <= 0)
			THROW 50000, '- Valor invalido: ID Club.', 1;

		IF(@nombre IS NULL)
			THROW 50000, '- Valor invalido: Nombre.', 1;

		IF NOT EXISTS(SELECT 1 FROM equipos.Club WHERE IdClub = @id)
			THROW 50000, '- Valor inexistente: ID Club.', 1;

		IF EXISTS(SELECT 1 FROM equipos.Club WHERE Nombre = @nombre AND IdClub <> @id)
			THROW 50000, '- Valor duplicado: Nombre.', 1;

		UPDATE equipos.Club
		SET Nombre = @nombre
		WHERE IdClub = @id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspClub_Bajar'))
    DROP PROCEDURE SP.uspClub_Bajar
GO
CREATE PROCEDURE SP.uspClub_Bajar @id INT
AS
BEGIN
	BEGIN TRY
		IF(@id IS NULL) OR (@id <= 0)
			THROW 50000, '- Valor invalido: ID Club.', 1;

		IF NOT EXISTS(SELECT 1 FROM equipos.Club WHERE IdClub = @id)
			THROW 50000, '- Valor inexistente: ID Club.', 1;

		IF EXISTS(SELECT 1 FROM equipos.Jugador WHERE Club = @id)
			THROW 50000, '- Existen 1 o mas registros relacionados: Jugador. Elimine dichos registros para continuar.', 1;

		DELETE FROM equipos.Club WHERE IdClub = @id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

--llenado de tablas a testear con registro exitoso
EXECUTE SP.uspClub_Registrar @nombre = 'Real Madrid';
EXECUTE SP.uspClub_Registrar @nombre = 'Barcelona FC';

SELECT * FROM equipos.Club;
GO
--llenado de tablas auxiliares
INSERT INTO equipos.Jugador VALUES (1, 2);

SELECT * FROM equipos.Jugador;
GO


----Testeo
--/Registro
--Fallido (Valores invalidos)
EXECUTE SP.uspClub_Registrar @nombre = NULL;

SELECT * FROM equipos.Club;
GO
--Fallido (Valores dup)
EXECUTE SP.uspClub_Registrar @nombre = 'Real Madrid';

SELECT * FROM equipos.Club;
GO
--/Update
--Exitoso
EXECUTE SP.uspClub_Update @id = 1, @nombre = 'Realisimo Madrid';

SELECT * FROM equipos.Club;
GO
--Fallido(Valores invalidos)
EXECUTE SP.uspClub_Update @id = 0, @nombre = NULL;

SELECT * FROM equipos.Club;
GO
--Fallido(Valores inexistentes)
EXECUTE SP.uspClub_Update @id = 40, @nombre = 'Realisimo Madrid';

SELECT * FROM equipos.Club;
GO
--Fallido(Valores dup)
EXECUTE SP.uspClub_Update @id = 1, @nombre = 'Barcelona FC';

SELECT * FROM equipos.Club;
GO
--/Baja
--Exitoso
EXECUTE SP.uspClub_Bajar @id = 1;

SELECT * FROM equipos.Club;
GO
--Fallido(Valores invalidos)
EXECUTE SP.uspClub_Bajar @id = 0;

SELECT * FROM equipos.Club;
GO
--Fallido(Valores inexistentes)
EXECUTE SP.uspClub_Bajar @id = 40;

SELECT * FROM equipos.Club;
GO
--Fallido(Registros referenciados)
EXECUTE SP.uspClub_Bajar @id = 2;

SELECT * FROM equipos.Club;
GO

--limpieza
DROP PROCEDURE SP.uspClub_Registrar;
DROP PROCEDURE SP.uspClub_Update;
DROP PROCEDURE SP.uspClub_Bajar;
GO

DROP TABLE equipos.Jugador;
DROP TABLE equipos.Club;
GO