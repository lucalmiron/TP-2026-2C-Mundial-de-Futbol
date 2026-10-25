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

--Jugador
IF OBJECT_ID('SPTRANS.uspJugador_Registrar', 'P') IS NOT NULL
    DROP PROCEDURE SPTRANS.uspJugador_Registrar;
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
	DECLARE @cantJugadores INT;
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

		IF(@posicion IS NULL)
			THROW 50000, '- Valor invalido: Posicion.', 1;

		IF(@numero IS NULL) OR (@numero <= 0)
			THROW 50000, '- Valor invalido: Numero.', 1;

		IF( (@club IS NOT NULL) AND (@club <= 0) )
			THROW 50000, '- Valor invalido: Club.', 1;

		IF(@seleccion IS NULL) OR (@seleccion <= 0)
			THROW 50000, '- Valor invalido: Seleccion.', 1;

		--chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @pais)
			THROW 50000, '- Valor inexistente: Pais.', 1;

		IF (@club IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM equipos.Club WHERE IdClub = @club)
			THROW 50000, '- Valor inexistente: Club.', 1;

		IF NOT EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @seleccion)
			THROW 50000, '- Valor inexistente: Seleccion.', 1;

		--chequeo cupo
		SET @cantJugadores = (SELECT COUNT(IdJugador) FROM equipos.Jugador WHERE Seleccion = @seleccion AND Estado <> 'Inactivo');
		IF( (@cantJugadores + 1) > (SELECT TAMANIO_SELECCION_MAXIMO FROM sedes.Mundial WHERE IdMundial = (SELECT IdMundial FROM equipos.Seleccion WHERE IdSeleccion = @seleccion)) )
			THROW 50000, '- Cupo maximo de jugadores excedido.', 1;

		--chequeo dup
		IF EXISTS(SELECT 1 FROM equipos.Persona WHERE Nombre = @nombre)
			THROW 50000, '- Valor duplicado: Nombre.', 1;
		
		--El dorsal es unico por seleccion (UQ_Jugador_Dorsal), no globalmente.
		IF EXISTS(SELECT 1 FROM equipos.Jugador WHERE Numero = @numero AND Seleccion = @seleccion)
			THROW 50000, '- Valor duplicado: Numero.', 1;

		BEGIN TRANSACTION;
			INSERT INTO equipos.Persona(Nombre, Fnac, Pais, Rol)
			OUTPUT INSERTED.IdPersona INTO @nuevo(ID)
			VALUES (@nombre, @fnac, @pais, 'Jugador');

			SELECT TOP 1 @idPersona = ID FROM @nuevo;

			INSERT INTO equipos.Jugador(IdJugador, Estado, Posicion, Numero, TarjetasAcum, Club, Seleccion)
			VALUES(@idPersona, 'Activo', @posicion, @numero, 0, @club, @seleccion);

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END
GO

IF OBJECT_ID('SPTRANS.uspJugador_Update', 'P') IS NOT NULL
    DROP PROCEDURE SPTRANS.uspJugador_Update;
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
	DECLARE @selDestino INT;

	BEGIN TRY
		--Chequeo validez
		IF(@id IS NULL) OR (@id <= 0)
			THROW 50000, '- Valor invalido: ID Jugador.', 1;

		IF(@fnac IS NOT NULL) AND ( @fnac > CONVERT(DATE, GETDATE()) )
			THROW 50000, '- Valor invalido: Fecha de Nacimiento.', 1;

		IF(@pais IS NOT NULL) AND (@pais <= 0)
			THROW 50000, '- Valor invalido: Pais.', 1;

		IF(@numero IS NOT NULL) AND (@numero <= 0)
			THROW 50000, '- Valor invalido: Numero.', 1;

		IF(@seleccion IS NOT NULL) AND (@seleccion <= 0)
			THROW 50000, '- Valor invalido: Seleccion.', 1;

		--chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM equipos.Jugador WHERE IdJugador = @id)
			THROW 50000, '- Valor inexistente: IdJugador.', 1;

		IF (@pais IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @pais)
			THROW 50000, '- Valor inexistente: Pais.', 1;

		IF (@seleccion IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @seleccion)
			THROW 50000, '- Valor inexistente: Seleccion.', 1;

		--chequeo dup
		IF (@nombre IS NOT NULL) AND EXISTS(SELECT 1 FROM equipos.Persona WHERE Nombre = @nombre AND IdPersona <> @id)
			THROW 50000, '- Valor duplicado: Nombre.', 1;

		--El dorsal es unico por seleccion: se controla contra la seleccion que quedara.
		SET @selDestino = COALESCE(@seleccion, (SELECT Seleccion FROM equipos.Jugador WHERE IdJugador = @id));

		IF (@numero IS NOT NULL) AND EXISTS(SELECT 1 FROM equipos.Jugador WHERE Numero = @numero AND Seleccion = @selDestino AND IdJugador <> @id)
			THROW 50000, '- Valor duplicado: Numero.', 1;

		BEGIN TRANSACTION;
			UPDATE equipos.Persona
			SET
			Nombre = COALESCE(@nombre, Nombre),
			Fnac = COALESCE(@fnac, Fnac),
			Pais = COALESCE(@pais, Pais)
			WHERE IdPersona = @id;

			UPDATE equipos.Jugador
			SET
			Posicion = COALESCE(@posicion, Posicion),
			Numero = COALESCE(@numero, Numero),
			Seleccion = COALESCE(@seleccion, Seleccion)
			WHERE IdJugador = @id;

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END
GO

IF OBJECT_ID('SPTRANS.uspJugador_Bajar', 'P') IS NOT NULL
    DROP PROCEDURE SPTRANS.uspJugador_Bajar;
GO
CREATE PROCEDURE SPTRANS.uspJugador_Bajar
@id INT
AS
BEGIN
	DECLARE @cantJugadores INT;
	DECLARE @seleccion INT;

	BEGIN TRY
		--Chequeo validez
		IF(@id IS NULL) OR (@id <= 0)
			THROW 50000, '- Valor invalido: ID Jugador.', 1;

		--Chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM equipos.Jugador WHERE IdJugador = @id)
			THROW 50000, '- Valor inexistente: IdJugador.', 1;

		--Chequeo relaciones
		IF EXISTS(SELECT 1 FROM partidos.Amonestacion WHERE Amonestado = @id)
			THROW 50000, '- Existen 1 o mas registros relacionados: Amonestacion. Elimine dichos registros para continuar.', 1;

		IF EXISTS(SELECT 1 FROM partidos.Gol WHERE Autor = @id OR Asistencia = @id)
			THROW 50000, '- Existen 1 o mas registros relacionados: Gol. Elimine dichos registros para continuar.', 1;

		IF EXISTS(SELECT 1 FROM partidos.Sustitucion WHERE Ingreso = @id OR Egreso = @id)
			THROW 50000, '- Existen 1 o mas registros relacionados: Sustitucion. Elimine dichos registros para continuar.', 1;

		IF EXISTS(SELECT 1 FROM equipos.CambioConvocatoria WHERE Ingreso = @id OR Egreso = @id)
			THROW 50000, '- Existen 1 o mas registros relacionados: Cambio en Convocatoria. Elimine dichos registros para continuar.', 1;

		--chequeo cupo
		SET @seleccion = (SELECT Seleccion FROM equipos.Jugador WHERE IdJugador = @id);
		--Se cuentan SOLO los jugadores activos que quedarian, es decir, sin contar al que se elimina.
		SET @cantJugadores = (SELECT COUNT(IdJugador) FROM equipos.Jugador WHERE Seleccion = @seleccion AND Estado <> 'Inactivo' AND IdJugador <> @id);

		IF( @cantJugadores < (SELECT TAMANIO_SELECCION_MINIMO FROM sedes.Mundial WHERE IdMundial = (SELECT IdMundial FROM equipos.Seleccion WHERE IdSeleccion = @seleccion)) )
			THROW 50000, '- Cupo minimo de jugadores no respetado.', 1;

		BEGIN TRANSACTION;
			-- Baja logica en vez de DELETE fisico.
			-- El jugador pasa a Estado='Inactivo' (puede ser reingresado como ingreso de cambio de convocatoria).
			UPDATE equipos.Jugador
			SET Estado = 'Inactivo'
			WHERE IdJugador = @id;

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END
GO