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

--Arbitro
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspArbitro_Registrar'))
    DROP PROCEDURE SPTRANS.uspArbitro_Registrar
GO
CREATE PROCEDURE SPTRANS.uspArbitro_Registrar 
@nombre VARCHAR(30),
@fnac DATE,
@pais INT,
@categoria VARCHAR(13)
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

	IF(@categoria IS NULL) OR (@categoria NOT IN ('FIFA', 'Confederacion'))
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Categoria.'
	END

	--chequeo existencia
	IF (@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM TABLAS.Pais WHERE IdPais = @pais)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Pais.'
	END

	--chequeo dup
	IF (@errorCount = 0) AND EXISTS(SELECT 1 FROM TABLAS.Persona WHERE Nombre LIKE @nombre)
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
			VALUES (@nombre, @fnac, @pais, 'Arbitro')

			INSERT INTO TABLAS.Arbitro(IdArbitro, Categoria)
			VALUES((SELECT ID FROM @id), @categoria)

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

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspArbitro_Update'))
    DROP PROCEDURE SPTRANS.uspArbitro_Update
GO
CREATE PROCEDURE SPTRANS.uspArbitro_Update 
@id INT,
@nombre VARCHAR(30) = NULL,
@fnac DATE = NULL,
@pais INT = NULL,
@categoria VARCHAR(13) = NULL
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
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Arbitro.'
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

	IF(@categoria IS NOT NULL) AND (@categoria NOT IN ('FIFA', 'Confederacion'))
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Categoria.'
	END

	--chequeo existencia
	IF(@errorCount = 0)
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM TABLAS.Arbitro WHERE IdArbitro = @id)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: IdArbitro.'
		END

		IF (@pais IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM TABLAS.Pais WHERE IdPais = @pais)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Pais.'
		END
	END

	--chequeo dup
	IF (@errorCount = 0) AND (@nombre IS NOT NULL) AND EXISTS(SELECT 1 FROM TABLAS.Persona WHERE Nombre LIKE @nombre AND IdPersona <> @id)
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

			UPDATE TABLAS.Arbitro
			SET
			Categoria = COALESCE(@categoria, Categoria)
			WHERE IdArbitro = @id

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

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspArbitro_Bajar'))
    DROP PROCEDURE SPTRANS.uspArbitro_Bajar
GO
CREATE PROCEDURE SPTRANS.uspArbitro_Bajar
@id INT
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
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: IdArbitro.'
	END

	--Chequeo existencia
	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM TABLAS.Arbitro WHERE IdArbitro = @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: IdArbitro.'
	END

	--Chequeo relaciones
	IF(@errorCount = 0)
	BEGIN
		IF EXISTS(SELECT 1 FROM TABLAS.Reporte WHERE Arbitro = @id)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Existen 1 o mas registros relacionados: Reporte. Elimine dichos registros para continuar.'
		END

		IF EXISTS(SELECT 1 FROM TABLAS.Arbitraje WHERE Arbitro = @id)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Existen 1 o mas registros relacionados: Arbitraje. Elimine dichos registros para continuar.'
		END

		IF EXISTS(SELECT 1 FROM TABLAS.Amonestacion WHERE Arbitro = @id)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Existen 1 o mas registros relacionados: Amonestacion. Elimine dichos registros para continuar.'
		END
	END

	IF(@errorCount = 0)
	BEGIN
		BEGIN TRANSACTION
		BEGIN TRY
			DELETE FROM TABLAS.HablaIdioma
			WHERE Arbitro = @id

			DELETE FROM TABLAS.Arbitro
			WHERE IdArbitro = @id

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
	ELSE
		PRINT @errorLine
END;
GO
