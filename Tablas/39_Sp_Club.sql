--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Creacion de Stored Procedures

-- Ejecutar en la base seleccionada por el instalador.
GO

--Club
IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspClub_Registrar'))
    DROP PROCEDURE SP.uspClub_Registrar
GO
CREATE PROCEDURE SP.uspClub_Registrar @nombre VARCHAR(20)
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF(@nombre IS NULL)
			SET @errores += '- Valor invalido: Nombre.' + N' ';

		IF EXISTS(SELECT 1 FROM equipos.Club WHERE Nombre = @nombre)
			SET @errores += '- Valor duplicado: Nombre.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

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
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF(@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Club.' + N' ';

		IF(@nombre IS NULL)
			SET @errores += '- Valor invalido: Nombre.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM equipos.Club WHERE IdClub = @id)
			SET @errores += '- Valor inexistente: ID Club.' + N' ';

		IF EXISTS(SELECT 1 FROM equipos.Club WHERE Nombre = @nombre AND IdClub <> @id)
			SET @errores += '- Valor duplicado: Nombre.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

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
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF(@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Club.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM equipos.Club WHERE IdClub = @id)
			SET @errores += '- Valor inexistente: ID Club.' + N' ';

		IF EXISTS(SELECT 1 FROM equipos.Jugador WHERE Club = @id)
			SET @errores += '- Existen 1 o mas registros relacionados: Jugador. Elimine dichos registros para continuar.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		DELETE FROM equipos.Club WHERE IdClub = @id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO