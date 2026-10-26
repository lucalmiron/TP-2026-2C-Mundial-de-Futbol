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
@seleccion INT,
@estado VARCHAR(10) = 'Activo'
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	DECLARE @cantJugadores INT;
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

		IF(@posicion IS NULL)
			SET @errores += '- Valor invalido: Posicion.' + N' ';

		IF(@numero IS NULL) OR (@numero <= 0)
			SET @errores += '- Valor invalido: Numero.' + N' ';

		IF( (@club IS NOT NULL) AND (@club <= 0) )
			SET @errores += '- Valor invalido: Club.' + N' ';

		IF(@seleccion IS NULL) OR (@seleccion <= 0)
			SET @errores += '- Valor invalido: Seleccion.' + N' ';

		--chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @pais)
			SET @errores += '- Valor inexistente: Pais.' + N' ';

		IF (@club IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM equipos.Club WHERE IdClub = @club)
			SET @errores += '- Valor inexistente: Club.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @seleccion)
			SET @errores += '- Valor inexistente: Seleccion.' + N' ';

		IF @estado IS NULL OR @estado NOT IN ('Activo', 'Inactivo')
			SET @errores += '- Estado inicial invalido: use Activo o Inactivo.' + N' ';

		-- Los reemplazantes inactivos no ocupan un lugar en la convocatoria.
		SET @cantJugadores = (SELECT COUNT(IdJugador) FROM equipos.Jugador WHERE Seleccion = @seleccion AND Estado <> 'Inactivo');
		IF @estado = 'Activo' AND ( (@cantJugadores + 1) > (SELECT TAMANIO_SELECCION_MAXIMO FROM sedes.Mundial WHERE IdMundial = (SELECT IdMundial FROM equipos.Seleccion WHERE IdSeleccion = @seleccion)) )
			SET @errores += '- Cupo maximo de jugadores excedido.' + N' ';

		--chequeo dup
		IF EXISTS(SELECT 1 FROM equipos.Persona WHERE Nombre = @nombre)
			SET @errores += '- Valor duplicado: Nombre.' + N' ';
		
		--El dorsal es unico por seleccion (UQ_Jugador_Dorsal), no globalmente.
		IF EXISTS(SELECT 1 FROM equipos.Jugador WHERE Numero = @numero AND Seleccion = @seleccion)
			SET @errores += '- Valor duplicado: Numero.' + N' ';

		BEGIN TRANSACTION;

		IF LEN(@errores)>0 THROW 50000, @errores, 1;
			INSERT INTO equipos.Persona(Nombre, Fnac, Pais, Rol)
			OUTPUT INSERTED.IdPersona INTO @nuevo(ID)
			VALUES (@nombre, @fnac, @pais, 'Jugador');

			SELECT TOP 1 @idPersona = ID FROM @nuevo;

			INSERT INTO equipos.Jugador(IdJugador, Estado, Posicion, Numero, TarjetasAcum, Club, Seleccion)
			VALUES(@idPersona, @estado, @posicion, @numero, 0, @club, @seleccion);

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
	DECLARE @errores NVARCHAR(2048) = N'';
	DECLARE @selDestino INT;

	BEGIN TRY
		--Chequeo validez
		IF(@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Jugador.' + N' ';

		IF(@fnac IS NOT NULL) AND ( @fnac > CONVERT(DATE, GETDATE()) )
			SET @errores += '- Valor invalido: Fecha de Nacimiento.' + N' ';

		IF(@pais IS NOT NULL) AND (@pais <= 0)
			SET @errores += '- Valor invalido: Pais.' + N' ';

		IF(@numero IS NOT NULL) AND (@numero <= 0)
			SET @errores += '- Valor invalido: Numero.' + N' ';

		IF(@seleccion IS NOT NULL) AND (@seleccion <= 0)
			SET @errores += '- Valor invalido: Seleccion.' + N' ';

		--chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM equipos.Jugador WHERE IdJugador = @id)
			SET @errores += '- Valor inexistente: IdJugador.' + N' ';

		IF (@pais IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @pais)
			SET @errores += '- Valor inexistente: Pais.' + N' ';

		IF (@seleccion IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @seleccion)
			SET @errores += '- Valor inexistente: Seleccion.' + N' ';

		--chequeo dup
		IF (@nombre IS NOT NULL) AND EXISTS(SELECT 1 FROM equipos.Persona WHERE Nombre = @nombre AND IdPersona <> @id)
			SET @errores += '- Valor duplicado: Nombre.' + N' ';

		--El dorsal es unico por seleccion: se controla contra la seleccion que quedara.
		SET @selDestino = COALESCE(@seleccion, (SELECT Seleccion FROM equipos.Jugador WHERE IdJugador = @id));

		IF EXISTS(SELECT 1 FROM equipos.Jugador WHERE Numero = COALESCE(@numero, (SELECT Numero FROM equipos.Jugador WHERE IdJugador = @id)) AND Seleccion = @selDestino AND IdJugador <> @id)
			SET @errores += '- Valor duplicado: Numero.' + N' ';


		IF @selDestino <> (SELECT Seleccion FROM equipos.Jugador WHERE IdJugador = @id)
		BEGIN
			IF EXISTS (SELECT 1 FROM partidos.Alineacion WHERE IdJugador = @id)
			OR EXISTS (SELECT 1 FROM partidos.Gol WHERE Autor = @id OR Asistencia = @id)
			OR EXISTS (SELECT 1 FROM partidos.Amonestacion WHERE Amonestado = @id)
			OR EXISTS (SELECT 1 FROM partidos.Sustitucion WHERE Ingreso = @id OR Egreso = @id)
			OR EXISTS (SELECT 1 FROM equipos.CambioConvocatoria WHERE Ingreso = @id OR Egreso = @id)
				SET @errores += '- No se puede cambiar la seleccion de un jugador con historial.' + N' ';

			IF EXISTS (SELECT 1 FROM equipos.Jugador WHERE IdJugador = @id AND Estado <> 'Inactivo')
			BEGIN
				IF (SELECT COUNT(*) FROM equipos.Jugador WHERE Seleccion = @selDestino AND Estado <> 'Inactivo') >=
				   (SELECT M.TAMANIO_SELECCION_MAXIMO FROM sedes.Mundial M JOIN equipos.Seleccion S ON S.IdMundial = M.IdMundial WHERE S.IdSeleccion = @selDestino)
					SET @errores += '- Cupo maximo de jugadores excedido en la seleccion destino.' + N' ';

				IF (SELECT COUNT(*) FROM equipos.Jugador WHERE Seleccion = (SELECT Seleccion FROM equipos.Jugador WHERE IdJugador = @id) AND Estado <> 'Inactivo' AND IdJugador <> @id) <
				   (SELECT M.TAMANIO_SELECCION_MINIMO FROM sedes.Mundial M JOIN equipos.Seleccion S ON S.IdMundial = M.IdMundial JOIN equipos.Jugador J ON J.Seleccion = S.IdSeleccion WHERE J.IdJugador = @id)
					SET @errores += '- Cupo minimo de jugadores no respetado en la seleccion origen.' + N' ';
			END
		END

		BEGIN TRANSACTION;

		IF LEN(@errores)>0 THROW 50000, @errores, 1;
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
	DECLARE @errores NVARCHAR(2048) = N'';
	DECLARE @cantJugadores INT;
	DECLARE @seleccion INT;

	BEGIN TRY
		--Chequeo validez
		IF(@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Jugador.' + N' ';

		--Chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM equipos.Jugador WHERE IdJugador = @id)
			SET @errores += '- Valor inexistente: IdJugador.' + N' ';

		--Chequeo relaciones
		IF EXISTS(SELECT 1 FROM partidos.Amonestacion WHERE Amonestado = @id)
			SET @errores += '- Existen 1 o mas registros relacionados: Amonestacion. Elimine dichos registros para continuar.' + N' ';

		IF EXISTS(SELECT 1 FROM partidos.Gol WHERE Autor = @id OR Asistencia = @id)
			SET @errores += '- Existen 1 o mas registros relacionados: Gol. Elimine dichos registros para continuar.' + N' ';

		IF EXISTS(SELECT 1 FROM partidos.Sustitucion WHERE Ingreso = @id OR Egreso = @id)
			SET @errores += '- Existen 1 o mas registros relacionados: Sustitucion. Elimine dichos registros para continuar.' + N' ';

		IF EXISTS(SELECT 1 FROM equipos.CambioConvocatoria WHERE Ingreso = @id OR Egreso = @id)
			SET @errores += '- Existen 1 o mas registros relacionados: Cambio en Convocatoria. Elimine dichos registros para continuar.' + N' ';

		--chequeo cupo
		SET @seleccion = (SELECT Seleccion FROM equipos.Jugador WHERE IdJugador = @id);
		--Se cuentan SOLO los jugadores activos que quedarian, es decir, sin contar al que se elimina.
		SET @cantJugadores = (SELECT COUNT(IdJugador) FROM equipos.Jugador WHERE Seleccion = @seleccion AND Estado <> 'Inactivo' AND IdJugador <> @id);

		IF( @cantJugadores < (SELECT TAMANIO_SELECCION_MINIMO FROM sedes.Mundial WHERE IdMundial = (SELECT IdMundial FROM equipos.Seleccion WHERE IdSeleccion = @seleccion)) )
			SET @errores += '- Cupo minimo de jugadores no respetado.' + N' ';

		BEGIN TRANSACTION;
			-- Baja logica en vez de DELETE fisico.
			-- El jugador pasa a Estado='Inactivo' (puede ser reingresado como ingreso de cambio de convocatoria).

		IF LEN(@errores)>0 THROW 50000, @errores, 1;
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