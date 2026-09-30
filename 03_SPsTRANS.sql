IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

--Jugador
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspJugador_Registrar'))
    DROP PROCEDURE SPTRANS.uspJugador_Registrar
GO
CREATE PROCEDURE SPTRANS.uspJugador_Registrar 
@nombre VARCHAR(30),
@fnac DATE,
@pais INT,
@posicion VARCHAR(20),
@numero INT,
@club INT = NULL,
@seleccion INT
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine varchar(300)
	DECLARE @cantJugadores INT
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

	IF(@posicion IS NULL)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Posicion.'
	END

	IF(@numero IS NULL) OR (@numero <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Numero.'
	END

	IF( (@club IS NOT NULL) AND (@club <= 0) )
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Club.'
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

		IF (@club IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM TABLAS.Club WHERE IdClub = @club)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Club.'
		END

		IF NOT EXISTS(SELECT 1 FROM TABLAS.Seleccion WHERE IdSeleccion = @seleccion)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Seleccion.'
		END
	END

	--chequeo cupo
	IF(@errorCount = 0)
	BEGIN
		SET @cantJugadores = (SELECT COUNT(IdJugador) FROM TABLAS.Jugador WHERE Seleccion = @seleccion AND Estado <> 'Inactivo')
		IF( (@cantJugadores + 1) > (SELECT CantJugadoresMax FROM TABLAS.Mundial) )
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Cupo maximo de jugadores excedido.'
		END
	END

	--chequeo dup
	IF(@errorCount = 0)
	BEGIN
		IF EXISTS(SELECT 1 FROM TABLAS.Persona WHERE Nombre LIKE @nombre)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor duplicado: Nombre.'
		END
		
		IF EXISTS(SELECT 1 FROM TABLAS.Jugador WHERE Numero LIKE @numero)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor duplicado: Numero.'
		END
	END

	IF(@errorCount = 0)
	BEGIN
		BEGIN TRANSACTION
		BEGIN TRY
			INSERT INTO TABLAS.Persona(Nombre, Fnac, Pais, Rol)
			OUTPUT INSERTED.IdPersona INTO @id(ID)
			VALUES (@nombre, @fnac, @pais, 'Jugador')

			INSERT INTO TABLAS.Jugador(IdJugador, Estado, Posicion, Numero, TarjetasAcum, Club, Seleccion)
			VALUES((SELECT ID FROM @id), 'Activo', @posicion, @numero, 0, @club, @seleccion)

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

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspJugador_Update'))
    DROP PROCEDURE SPTRANS.uspJugador_Update
GO
CREATE PROCEDURE SPTRANS.uspJugador_Update 
@id INT,
@nombre VARCHAR(30) = NULL,
@fnac DATE = NULL,
@pais INT = NULL,
@posicion VARCHAR(20) = NULL,
@numero INT = NULL,
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
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Jugador.'
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

	IF(@numero IS NOT NULL) AND (@numero <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Numero.'
	END

	IF(@seleccion IS NULL) OR (@seleccion <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Seleccion.'
	END

	--chequeo existencia
	IF(@errorCount = 0)
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM TABLAS.Jugador WHERE IdJugador = @id)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: IdJugador.'
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
	IF(@errorCount = 0)
	BEGIN
		IF EXISTS(SELECT 1 FROM TABLAS.Persona WHERE Nombre LIKE @nombre AND IdPersona <> @id)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor duplicado: Nombre.'
		END

		IF (@numero IS NOT NULL) AND EXISTS(SELECT 1 FROM TABLAS.Jugador WHERE Numero LIKE @numero AND IdJugador <> @id)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor duplicado: Numero.'
		END
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

			UPDATE TABLAS.Jugador
			SET
			Posicion = COALESCE(@posicion, Posicion),
			Numero = COALESCE(@numero, Numero),
			Seleccion = COALESCE(@seleccion, Seleccion)
			WHERE IdJugador = @id

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

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspJugador_Bajar'))
    DROP PROCEDURE SPTRANS.uspJugador_Bajar
GO
CREATE PROCEDURE SPTRANS.uspJugador_Bajar
@id INT
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine varchar(300)
	DECLARE @cantJugadores INT
	DECLARE @seleccion INT

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	--Chequeo validez
	IF(@id IS NULL) OR (@id <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Jugador.'
	END

	--Chequeo existencia
	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM TABLAS.Jugador WHERE IdJugador = @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: IdJugador.'
	END

	--Chequeo relaciones
	IF(@errorCount = 0)
	BEGIN
		IF EXISTS(SELECT 1 FROM TABLAS.Amonestacion WHERE Amonestado = @id)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Existen 1 o mas registros relacionados: Amonestacion. Elimine dichos registros para continuar.'
		END

		IF EXISTS(SELECT 1 FROM TABLAS.Gol WHERE Autor = @id OR Asistencia = @id)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Existen 1 o mas registros relacionados: Gol. Elimine dichos registros para continuar.'
		END

		IF EXISTS(SELECT 1 FROM TABLAS.Sustitucion WHERE Ingreso = @id OR Egreso = @id)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Existen 1 o mas registros relacionados: Sustitucion. Elimine dichos registros para continuar.'
		END

		IF EXISTS(SELECT 1 FROM TABLAS.Cambio_Convocatoria WHERE Ingreso = @id OR Egreso = @id)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Existen 1 o mas registros relacionados: Cambio en Convocatoria. Elimine dichos registros para continuar.'
		END
	END

	--chequeo cupo
	IF(@errorCount = 0)
	BEGIN
		SET @seleccion = (SELECT Seleccion FROM TABLAS.Jugador WHERE IdJugador = @id)
		SET @cantJugadores = (SELECT COUNT(IdJugador) FROM TABLAS.Jugador WHERE Seleccion = @seleccion AND Estado <> 'Inactivo')

		IF( (@cantJugadores - 1) < (SELECT CantJugadoresMin FROM TABLAS.Mundial) )
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Cupo minimo de jugadores no respetado.'
		END
	END

	IF(@errorCount = 0)
	BEGIN
		BEGIN TRANSACTION
		BEGIN TRY
			DELETE FROM TABLAS.Jugador
			WHERE IdJugador = @id

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

			INSERT INTO TABLAS.Tecnico(IdTecnico, Funcion, Seleccion)
			VALUES((SELECT ID FROM @id), @funcion, @seleccion)

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
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: IdTecnico.'
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
		PRINT 'ERROR: IdTecnico invalido.'
	END

	--Chequeo existencia
	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM TABLAS.Tecnico WHERE IdTecnico = @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT 'ERROR: IdTecnico inexistente.'
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