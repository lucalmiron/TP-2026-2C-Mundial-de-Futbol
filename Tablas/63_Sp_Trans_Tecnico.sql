--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 08/10/2026

--Creacion de Stored Procedures que involucran transacciones

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END
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
	DECLARE @idPersona INT;
	DECLARE @nuevo TABLE(ID INT);

	BEGIN TRY
		--Chequeo validez
		IF(@nombre IS NULL)
			THROW 50000, '- Valor invalido: Nombre.', 1;

		IF(@fnac IS NULL) OR ( @fnac > CONVERT(DATE, GETDATE()) )
			THROW 50000, '- Valor invalido: Fecha de Nacimiento.', 1;

		IF(@pais IS NULL) OR (@pais <= 0)
			THROW 50000, '- Valor invalido: Pais.', 1;

		IF(@funcion IS NULL)
			THROW 50000, '- Valor invalido: Funcion.', 1;

		IF(@seleccion IS NULL) OR (@seleccion <= 0)
			THROW 50000, '- Valor invalido: Seleccion.', 1;

		--chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @pais)
			THROW 50000, '- Valor inexistente: Pais.', 1;

		IF NOT EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @seleccion)
			THROW 50000, '- Valor inexistente: Seleccion.', 1;

		--chequeo dup
		IF EXISTS(SELECT 1 FROM equipos.Persona WHERE Nombre = @nombre)
			THROW 50000, '- Valor duplicado: Nombre.', 1;

		BEGIN TRANSACTION;
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
	BEGIN TRY
		--Chequeo validez
		IF(@id IS NULL) OR (@id <= 0)
			THROW 50000, '- Valor invalido: ID Tecnico.', 1;

		IF(@fnac IS NOT NULL) AND ( @fnac > CONVERT(DATE, GETDATE()) )
			THROW 50000, '- Valor invalido: Fecha de Nacimiento.', 1;

		IF(@pais IS NOT NULL) AND (@pais <= 0)
			THROW 50000, '- Valor invalido: Pais.', 1;

		IF(@seleccion IS NOT NULL) AND (@seleccion <= 0)
			THROW 50000, '- Valor invalido: Seleccion.', 1;

		--chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM equipos.Tecnico WHERE IdTecnico = @id)
			THROW 50000, '- Valor inexistente: ID Tecnico.', 1;

		IF (@pais IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @pais)
			THROW 50000, '- Valor inexistente: Pais.', 1;

		IF (@seleccion IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @seleccion)
			THROW 50000, '- Valor inexistente: Seleccion.', 1;

		--chequeo dup
		IF (@nombre IS NOT NULL) AND EXISTS(SELECT 1 FROM equipos.Persona WHERE Nombre = @nombre AND IdPersona <> @id)
			THROW 50000, '- Valor duplicado: Nombre.', 1;

		BEGIN TRANSACTION;
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
	BEGIN TRY
		--Chequeo validez
		IF(@id IS NULL) OR (@id <= 0)
			THROW 50000, '- Valor invalido: ID Tecnico.', 1;

		--Chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM equipos.Tecnico WHERE IdTecnico = @id)
			THROW 50000, '- Valor inexistente: ID Tecnico.', 1;

		--Chequeo relaciones
		IF EXISTS(SELECT 1 FROM partidos.Amonestacion WHERE Amonestado = @id)
			THROW 50000, '- Existen 1 o mas registros relacionados: Amonestacion. Elimine dichos registros para continuar.', 1;

		BEGIN TRANSACTION;
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