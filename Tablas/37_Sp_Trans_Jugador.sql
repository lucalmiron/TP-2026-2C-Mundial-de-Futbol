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
		IF NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @pais)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Pais.'
		END

		IF (@club IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM equipos.Club WHERE IdClub = @club)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Club.'
		END

		IF NOT EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @seleccion)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Seleccion.'
		END
	END

	--chequeo cupo
	IF(@errorCount = 0)
	BEGIN
		SET @cantJugadores = (SELECT COUNT(IdJugador) FROM equipos.Jugador WHERE Seleccion = @seleccion AND Estado <> 'Inactivo')
		IF( (@cantJugadores + 1) > (SELECT TAMANIO_SELECCION_MAXIMO FROM sedes.Mundial WHERE IdMundial = (SELECT IdMundial FROM equipos.Seleccion WHERE IdSeleccion = @seleccion)) )
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Cupo maximo de jugadores excedido.'
		END
	END

	--chequeo dup
	IF(@errorCount = 0)
	BEGIN
		IF EXISTS(SELECT 1 FROM equipos.Persona WHERE Nombre = @nombre)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor duplicado: Nombre.'
		END
		
		--El dorsal es unico por seleccion (UQ_Jugador_Dorsal), no globalmente.
		IF EXISTS(SELECT 1 FROM equipos.Jugador WHERE Numero = @numero AND Seleccion = @seleccion)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor duplicado: Numero.'
		END
	END

	IF(@errorCount = 0)
	BEGIN
		BEGIN TRANSACTION
		BEGIN TRY
			INSERT INTO equipos.Persona(Nombre, Fnac, Pais, Rol)
			OUTPUT INSERTED.IdPersona INTO @id(ID)
			VALUES (@nombre, @fnac, @pais, 'Jugador')

			INSERT INTO equipos.Jugador(IdJugador, Estado, Posicion, Numero, TarjetasAcum, Club, Seleccion)
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
		IF NOT EXISTS(SELECT 1 FROM equipos.Jugador WHERE IdJugador = @id)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: IdJugador.'
		END

		IF (@pais IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @pais)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Pais.'
		END

		IF (@seleccion IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @seleccion)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Seleccion.'
		END
	END

	--chequeo dup
	IF(@errorCount = 0)
	BEGIN
		IF EXISTS(SELECT 1 FROM equipos.Persona WHERE Nombre = @nombre AND IdPersona <> @id)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor duplicado: Nombre.'
		END

		IF (@numero IS NOT NULL) AND EXISTS(SELECT 1 FROM equipos.Jugador WHERE Numero = @numero AND IdJugador <> @id)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor duplicado: Numero.'
		END
	END

	IF(@errorCount = 0)
	BEGIN
		BEGIN TRANSACTION
		BEGIN TRY
			UPDATE equipos.Persona
			SET
			Nombre = COALESCE(@nombre, Nombre),
			Fnac = COALESCE(@fnac, Fnac),
			Pais = COALESCE(@pais, Pais)
			WHERE IdPersona = @id

			UPDATE equipos.Jugador
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
	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM equipos.Jugador WHERE IdJugador = @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: IdJugador.'
	END

	--Chequeo relaciones
	IF(@errorCount = 0)
	BEGIN
		IF EXISTS(SELECT 1 FROM partidos.Amonestacion WHERE Amonestado = @id)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Existen 1 o mas registros relacionados: Amonestacion. Elimine dichos registros para continuar.'
		END

		/*
		--Las tablas Gol, Sustitucion y Cambio_Convocatoria todavia no fueron creadas.
		--Descomentar cuando existan los scripts de creacion correspondientes.

		IF EXISTS(SELECT 1 FROM partidos.Gol WHERE Autor = @id OR Asistencia = @id)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Existen 1 o mas registros relacionados: Gol. Elimine dichos registros para continuar.'
		END

		IF EXISTS(SELECT 1 FROM partidos.Sustitucion WHERE Ingreso = @id OR Egreso = @id)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Existen 1 o mas registros relacionados: Sustitucion. Elimine dichos registros para continuar.'
		END

		IF EXISTS(SELECT 1 FROM partidos.Cambio_Convocatoria WHERE Ingreso = @id OR Egreso = @id)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Existen 1 o mas registros relacionados: Cambio en Convocatoria. Elimine dichos registros para continuar.'
		END
		*/
	END

	--chequeo cupo
	IF(@errorCount = 0)
	BEGIN
		SET @seleccion = (SELECT Seleccion FROM equipos.Jugador WHERE IdJugador = @id)
		SET @cantJugadores = (SELECT COUNT(IdJugador) FROM equipos.Jugador WHERE Seleccion = @seleccion AND Estado <> 'Inactivo')

		IF( (@cantJugadores - 1) < (SELECT TAMANIO_SELECCION_MINIMO FROM sedes.Mundial WHERE IdMundial = (SELECT IdMundial FROM equipos.Seleccion WHERE IdSeleccion = @seleccion)) )
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Cupo minimo de jugadores no respetado.'
		END
	END

	IF(@errorCount = 0)
	BEGIN
		BEGIN TRANSACTION
		BEGIN TRY
			DELETE FROM equipos.Jugador
			WHERE IdJugador = @id

			DELETE FROM equipos.Persona
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
