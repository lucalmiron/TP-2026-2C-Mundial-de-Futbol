--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: xx/xx/2026

--Creacion de Stored Procedures que involucran transacciones

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

--Tecnico
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspTecnico_Registrar'))
    DROP PROCEDURE SPTRANS.uspTecnico_Registrar
GO
CREATE PROCEDURE SPTRANS.uspTecnico_Registrar 
@nombre VARCHAR(30),
@fnac DATE,
@pais INT,
@funcion VARCHAR(40),
@seleccion INT
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine varchar(300)
	DECLARE @id TABLE(ID INT)

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	--Chequeo validez
	IF(@nombre IS NULL)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Nombre.'
	END

	IF(@fnac IS NULL) OR ( @fnac > CONVERT(DATE, GETDATE()) )
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Fecha de Nacimiento.'
	END

	IF(@pais IS NULL) OR (@pais <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Pais.'
	END

	IF(@funcion IS NULL)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Funcion.'
	END

	IF(@seleccion IS NULL) OR (@seleccion <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Seleccion.'
	END

	--chequeo existencia
	IF(@errorCount = 0)
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM TABLAS.Pais WHERE IdPais = @pais)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Pais.'
		END

		IF NOT EXISTS(SELECT 1 FROM TABLAS.Seleccion WHERE IdSeleccion = @seleccion)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Seleccion.'
		END
	END

	--chequeo dup
	IF(@errorCount = 0) AND EXISTS(SELECT 1 FROM TABLAS.Persona WHERE Nombre LIKE @nombre AND IdPersona <> @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor duplicado: Nombre.'
	END

	IF(@errorCount = 0)
	BEGIN
		BEGIN TRANSACTION
		BEGIN TRY
			INSERT INTO TABLAS.Persona(Nombre, Fnac, Pais, Rol)
			OUTPUT INSERTED.IdPersona INTO @id(ID)
			VALUES (@nombre, @fnac, @pais, 'Tecnico')
			
			INSERT INTO TABLAS.Tecnico(IdTecnico, Funcion, Seleccion, TarjetasAcum, Estado)
			VALUES((SELECT ID FROM @id), @funcion, @seleccion, 0, 'Activo')
			
			COMMIT TRANSACTION;

			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION;

			DECLARE @Msg NVARCHAR(500) = ERROR_MESSAGE();
			DECLARE @Num INT           = ERROR_NUMBER();
			PRINT CONCAT('ERROR (', @Num, '): ', @Msg);
		END CATCH
	END
	ELSE
		PRINT @errorLine
END;
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspTecnico_Update'))
    DROP PROCEDURE SPTRANS.uspTecnico_Update
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
	DECLARE @errorCount INT
	DECLARE @errorLine varchar(300)

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	--Chequeo validez
	IF(@id IS NULL) OR (@id <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Tecnico.'
	END

	IF(@fnac IS NOT NULL) AND ( @fnac > CONVERT(DATE, GETDATE()) )
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Fecha de Nacimiento.'
	END

	IF(@pais IS NOT NULL) AND (@pais <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Pais.'
	END

	IF(@seleccion IS NOT NULL) AND (@seleccion <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Seleccion.'
	END

	--chequeo existencia
	IF(@errorCount = 0)
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM TABLAS.Tecnico WHERE IdTecnico = @id)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: ID Tecnico.'
		END

		IF (@pais IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM TABLAS.Pais WHERE IdPais = @pais)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Pais.'
		END

		IF (@seleccion IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM TABLAS.Seleccion WHERE IdSeleccion = @seleccion)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Seleccion.'
		END
	END

	--chequeo dup
	IF(@errorCount = 0) AND (@nombre IS NOT NULL) AND EXISTS(SELECT 1 FROM TABLAS.Persona WHERE Nombre LIKE @nombre AND IdPersona <> @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor duplicado: Nombre.'
	END

	IF(@errorCount = 0)
	BEGIN
		BEGIN TRANSACTION
		BEGIN TRY
			UPDATE TABLAS.Persona
			SET
			Nombre = COALESCE(@nombre, Nombre),
			Fnac = COALESCE(@fnac, Fnac),
			Pais = COALESCE(@pais, Pais)
			WHERE IdPersona = @id

			UPDATE TABLAS.Tecnico
			SET
			Funcion = COALESCE(@funcion, Funcion),
			Seleccion = COALESCE(@seleccion, Seleccion)
			WHERE IdTecnico = @id

			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION;

			DECLARE @Msg NVARCHAR(500) = ERROR_MESSAGE();
			DECLARE @Num INT           = ERROR_NUMBER();
			PRINT CONCAT('ERROR (', @Num, '): ', @Msg);
		END CATCH
	END
	ELSE
		PRINT @errorLine
END;
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspTecnico_Bajar'))
    DROP PROCEDURE SPTRANS.uspTecnico_Bajar
GO
CREATE PROCEDURE SPTRANS.uspTecnico_Bajar
@id INT
AS
BEGIN
	DECLARE @errorCount INT

	SET @errorCount = 0

	--Chequeo validez
	IF(@id IS NULL) OR (@id <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT 'ERROR: ID Tecnico invalido.'
	END

	--Chequeo existencia
	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM TABLAS.Tecnico WHERE IdTecnico = @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT 'ERROR: ID Tecnico inexistente.'
	END

	--Chequeo relaciones
	IF(@errorCount = 0) AND EXISTS(SELECT 1 FROM TABLAS.Amonestacion WHERE Amonestado = @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT 'ERROR: Existen 1 o mas registros relacionados: Amonestacion. Elimine dichos registros para continuar.'
	END

	IF(@errorCount = 0)
	BEGIN
		BEGIN TRANSACTION
		BEGIN TRY
			DELETE FROM TABLAS.Tecnico
			WHERE IdTecnico = @id

			DELETE FROM TABLAS.Persona
			WHERE IdPersona = @id

			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION;

			DECLARE @Msg NVARCHAR(500) = ERROR_MESSAGE();
			DECLARE @Num INT           = ERROR_NUMBER();
			PRINT CONCAT('ERROR (', @Num, '): ', @Msg);
		END CATCH
	END
END;
GO
