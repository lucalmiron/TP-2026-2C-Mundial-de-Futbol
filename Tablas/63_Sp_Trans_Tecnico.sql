--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Creacion de Stored Procedures que involucran transacciones

-- Ejecutar en la base seleccionada por el instalador.
GO

--Tecnico
IF OBJECT_ID('SPTRANS.uspTecnico_Registrar', 'P') IS NOT NULL
    DROP PROCEDURE SPTRANS.uspTecnico_Registrar;
GO
CREATE PROCEDURE SPTRANS.uspTecnico_Registrar 
@nombre VARCHAR(30),
@fnac DATE,
@pais INT,
@funcion VARCHAR(40),
@seleccion INT
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

		IF(@funcion IS NULL)
			SET @errores += '- Valor invalido: Funcion.' + N' ';

		IF(@seleccion IS NULL) OR (@seleccion <= 0)
			SET @errores += '- Valor invalido: Seleccion.' + N' ';

		--chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @pais)
			SET @errores += '- Valor inexistente: Pais.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @seleccion)
			SET @errores += '- Valor inexistente: Seleccion.' + N' ';

		--chequeo dup
		IF EXISTS(SELECT 1 FROM equipos.Persona WHERE Nombre = @nombre)
			SET @errores += '- Valor duplicado: Nombre.' + N' ';

		BEGIN TRANSACTION;

		IF LEN(@errores)>0 THROW 50000, @errores, 1;
			INSERT INTO equipos.Persona(Nombre, Fnac, Pais, Rol)
			OUTPUT INSERTED.IdPersona INTO @nuevo(ID)
			VALUES (@nombre, @fnac, @pais, 'Tecnico');

			SELECT TOP 1 @idPersona = ID FROM @nuevo;

			INSERT INTO equipos.Tecnico(IdTecnico, Funcion, Seleccion, TarjetasAcum, Estado)
			VALUES(@idPersona, @funcion, @seleccion, 0, 'Activo');

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END
GO

IF OBJECT_ID('SPTRANS.uspTecnico_Update', 'P') IS NOT NULL
    DROP PROCEDURE SPTRANS.uspTecnico_Update;
GO
CREATE PROCEDURE SPTRANS.uspTecnico_Update 
@id INT,
@nombre VARCHAR(30) = NULL,
@fnac DATE = NULL,
@pais INT = NULL,
@funcion VARCHAR(40) = NULL,
@seleccion INT = NULL
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		--Chequeo validez
		IF(@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Tecnico.' + N' ';

		IF(@fnac IS NOT NULL) AND ( @fnac > CONVERT(DATE, GETDATE()) )
			SET @errores += '- Valor invalido: Fecha de Nacimiento.' + N' ';

		IF(@pais IS NOT NULL) AND (@pais <= 0)
			SET @errores += '- Valor invalido: Pais.' + N' ';

		IF(@seleccion IS NOT NULL) AND (@seleccion <= 0)
			SET @errores += '- Valor invalido: Seleccion.' + N' ';

		--chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM equipos.Tecnico WHERE IdTecnico = @id)
			SET @errores += '- Valor inexistente: ID Tecnico.' + N' ';

		IF (@pais IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @pais)
			SET @errores += '- Valor inexistente: Pais.' + N' ';

		IF (@seleccion IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @seleccion)
			SET @errores += '- Valor inexistente: Seleccion.' + N' ';

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

			UPDATE equipos.Tecnico
			SET
			Funcion = COALESCE(@funcion, Funcion),
			Seleccion = COALESCE(@seleccion, Seleccion)
			WHERE IdTecnico = @id;

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END
GO

IF OBJECT_ID('SPTRANS.uspTecnico_Bajar', 'P') IS NOT NULL
    DROP PROCEDURE SPTRANS.uspTecnico_Bajar;
GO
CREATE PROCEDURE SPTRANS.uspTecnico_Bajar
@id INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		--Chequeo validez
		IF(@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Tecnico.' + N' ';

		--Chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM equipos.Tecnico WHERE IdTecnico = @id)
			SET @errores += '- Valor inexistente: ID Tecnico.' + N' ';

		--Chequeo relaciones
		IF EXISTS(SELECT 1 FROM partidos.Amonestacion WHERE Amonestado = @id)
			SET @errores += '- Existen 1 o mas registros relacionados: Amonestacion. Elimine dichos registros para continuar.' + N' ';

		BEGIN TRANSACTION;

		IF LEN(@errores)>0 THROW 50000, @errores, 1;
			DELETE FROM equipos.Tecnico
			WHERE IdTecnico = @id;

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