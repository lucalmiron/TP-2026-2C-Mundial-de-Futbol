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

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspClub_Update'))
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

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspClub_Bajar'))
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