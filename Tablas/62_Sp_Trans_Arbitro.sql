--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 25/10/26

--Creacion de Stored Procedures que involucran transacciones

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END
GO

--Arbitro
IF OBJECT_ID('SPTRANS.uspArbitro_Registrar', 'P') IS NOT NULL
    DROP PROCEDURE SPTRANS.uspArbitro_Registrar;
GO
CREATE PROCEDURE SPTRANS.uspArbitro_Registrar 
@nombre VARCHAR(30),
@fnac DATE,
@pais INT,
@categoria VARCHAR(13)
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	DECLARE @idPersona INT;
	DECLARE @nuevo TABLE(ID INT);

	BEGIN TRY
		--Chequeo validez
		IF(@nombre IS NULL)
			SET @errores += '- Valor invalido: Nombre.' + N' ';

		IF(@fnac IS NULL) OR ( @fnac > CONVERT(DATE, GETDATE()) )
			SET @errores += '- Valor invalido: Fecha de Nacimiento.' + N' ';

		IF(@pais IS NULL) OR (@pais <= 0)
			SET @errores += '- Valor invalido: Pais.' + N' ';

		IF(@categoria IS NULL) OR (@categoria NOT IN ('FIFA', 'Confederacion'))
			SET @errores += '- Valor invalido: Categoria.' + N' ';

		--chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @pais)
			SET @errores += '- Valor inexistente: Pais.' + N' ';

		--chequeo dup
		IF EXISTS(SELECT 1 FROM equipos.Persona WHERE Nombre = @nombre)
			SET @errores += '- Valor duplicado: Nombre.' + N' ';

		BEGIN TRANSACTION;

		IF LEN(@errores)>0 THROW 50000, @errores, 1;
			INSERT INTO equipos.Persona(Nombre, Fnac, Pais, Rol)
			OUTPUT INSERTED.IdPersona INTO @nuevo(ID)
			VALUES (@nombre, @fnac, @pais, 'Arbitro');

			SELECT TOP 1 @idPersona = ID FROM @nuevo;

			INSERT INTO arbitros.Arbitro(IdArbitro, Categoria)
			VALUES(@idPersona, @categoria);

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END
GO

IF OBJECT_ID('SPTRANS.uspArbitro_Update', 'P') IS NOT NULL
    DROP PROCEDURE SPTRANS.uspArbitro_Update;
GO
CREATE PROCEDURE SPTRANS.uspArbitro_Update 
@id INT,
@nombre VARCHAR(30) = NULL,
@fnac DATE = NULL,
@pais INT = NULL,
@categoria VARCHAR(13) = NULL
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		--Chequeo validez
		IF(@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Arbitro.' + N' ';

		IF(@fnac IS NOT NULL) AND ( @fnac > CONVERT(DATE, GETDATE()) )
			SET @errores += '- Valor invalido: Fecha de Nacimiento.' + N' ';

		IF(@pais IS NOT NULL) AND (@pais <= 0)
			SET @errores += '- Valor invalido: Pais.' + N' ';

		IF(@categoria IS NOT NULL) AND (@categoria NOT IN ('FIFA', 'Confederacion'))
			SET @errores += '- Valor invalido: Categoria.' + N' ';

		--chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM arbitros.Arbitro WHERE IdArbitro = @id)
			SET @errores += '- Valor inexistente: IdArbitro.' + N' ';

		IF (@pais IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @pais)
			SET @errores += '- Valor inexistente: Pais.' + N' ';

		--chequeo dup
		IF (@nombre IS NOT NULL) AND EXISTS(SELECT 1 FROM equipos.Persona WHERE Nombre = @nombre AND IdPersona <> @id)
			SET @errores += '- Valor duplicado: Nombre.' + N' ';

		BEGIN TRANSACTION;

		IF LEN(@errores)>0 THROW 50000, @errores, 1;
			UPDATE equipos.Persona
			SET
			Nombre = COALESCE(@nombre, Nombre),
			Fnac = COALESCE(@fnac, Fnac),
			Pais = COALESCE(@pais, Pais)
			WHERE IdPersona = @id;

			UPDATE arbitros.Arbitro
			SET
			Categoria = COALESCE(@categoria, Categoria)
			WHERE IdArbitro = @id;

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END
GO

IF OBJECT_ID('SPTRANS.uspArbitro_Bajar', 'P') IS NOT NULL
    DROP PROCEDURE SPTRANS.uspArbitro_Bajar;
GO
CREATE PROCEDURE SPTRANS.uspArbitro_Bajar
@id INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		--Chequeo validez
		IF(@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: IdArbitro.' + N' ';

		--Chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM arbitros.Arbitro WHERE IdArbitro = @id)
			SET @errores += '- Valor inexistente: IdArbitro.' + N' ';

		--Chequeo relaciones
		IF EXISTS(SELECT 1 FROM arbitros.Reporte WHERE Arbitro = @id)
			SET @errores += '- Existen 1 o mas registros relacionados: Reporte. Elimine dichos registros para continuar.' + N' ';

		IF EXISTS(SELECT 1 FROM arbitros.Arbitraje WHERE Arbitro = @id)
			SET @errores += '- Existen 1 o mas registros relacionados: Arbitraje. Elimine dichos registros para continuar.' + N' ';

		IF EXISTS(SELECT 1 FROM partidos.Amonestacion WHERE Arbitro = @id)
			SET @errores += '- Existen 1 o mas registros relacionados: Amonestacion. Elimine dichos registros para continuar.' + N' ';

		BEGIN TRANSACTION;

		IF LEN(@errores)>0 THROW 50000, @errores, 1;
			DELETE FROM arbitros.HablaIdioma
			WHERE Arbitro = @id;

			DELETE FROM arbitros.Arbitro
			WHERE IdArbitro = @id;

			DELETE FROM equipos.Persona
			WHERE IdPersona = @id;

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END
GO