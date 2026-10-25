--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 08/10/2026

--Creacion de Tabla Amonestacion

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspAmonestacion_Registrar'))
    DROP PROCEDURE SPTRANS.uspAmonestacion_Registrar
GO
CREATE PROCEDURE SPTRANS.uspAmonestacion_Registrar 
@minuto INT,
@partido INT,
@periodo INT,
@amonestado INT,
@arbitro INT,
@tarjeta VARCHAR(8),
@motivo VARCHAR(300)
AS
BEGIN
	DECLARE @vRol VARCHAR(10)
	DECLARE @vLimSuspension INT
	DECLARE @vTarjetasAcum INT
	DECLARE @vAutoRoja INT
	DECLARE @vSusp INT
	DECLARE @ID TABLE(ID INT)

	BEGIN TRY
		--Chequeo validez
		IF(@minuto IS NOT NULL) AND (@minuto < 0)
			THROW 50000, '- Valor invalido: Minuto.', 1;

		IF(@partido IS NULL) OR (@partido <= 0)
			THROW 50000, '- Valor invalido: Partido.', 1;

		IF(@periodo IS NULL) OR (@periodo <= 0)
			THROW 50000, '- Valor invalido: Periodo.', 1;

		IF(@amonestado IS NULL) OR (@amonestado <= 0)
			THROW 50000, '- Valor invalido: Amonestado.', 1;

		IF(@arbitro IS NULL) OR (@arbitro <= 0)
			THROW 50000, '- Valor invalido: Arbitro.', 1;

		IF(@tarjeta IS NULL) OR (@tarjeta NOT IN ('Amarilla', 'Roja'))
			THROW 50000, '- Valor invalido: Tarjeta.', 1;

		IF(@motivo IS NULL)
			THROW 50000, '- Valor invalido: Motivo.', 1;

		--chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM partidos.Periodo WHERE IdPeriodo = @periodo)
			THROW 50000, '- Valor inexistente: Periodo.', 1;

		IF NOT EXISTS(SELECT 1 FROM equipos.Persona WHERE IdPersona = @amonestado)
			THROW 50000, '- Valor inexistente: Amonestado.', 1;

		IF NOT EXISTS(SELECT 1 FROM arbitros.Arbitro WHERE IdArbitro = @arbitro)
			THROW 50000, '- Valor inexistente: Arbitro.', 1;

		IF NOT EXISTS(SELECT 1 FROM partidos.Partido WHERE IdPartido = @partido)
			THROW 50000, '- Valor inexistente: Partido.', 1;

		--validez del minuto en relacion al periodo
		IF(
			(
				(@minuto IS NULL) 
				AND 
				((SELECT Descripcion FROM partidos.Periodo WHERE IdPeriodo = @periodo) <> 'Penales')
			)
			OR
			(
				(@minuto IS NOT NULL)
				AND
				(
					(@minuto < (SELECT Inicio FROM partidos.Periodo WHERE IdPeriodo = @periodo))
					OR
					(@minuto > (SELECT Fin FROM partidos.Periodo WHERE IdPeriodo = @periodo))
				)
			)
		)
			THROW 50000, '- El minuto esta fuera del rango del periodo indicado.', 1;

		--validez del amonestado
		SET @vRol = (SELECT Rol FROM equipos.Persona WHERE IdPersona = @amonestado)

		IF(@vRol = 'Arbitro')
			THROW 50000, '- Objetivo de amonestacion invalido.', 1;

		--chequeo participacion
		IF NOT EXISTS(SELECT 1 FROM arbitros.Arbitraje WHERE Arbitro = @arbitro AND Partido = @partido AND Funcion = 'Principal')
			THROW 50000, '- El arbitro no participo del encuentro o su funcion no le permite sancionar.', 1;

		IF(@vRol = 'Tecnico') AND 
		NOT EXISTS
		(
			SELECT 1 FROM equipos.Tecnico  
			WHERE IdTecnico = @amonestado AND 
			Seleccion IN
			((SELECT Eq1 FROM partidos.Partido WHERE IdPartido = @partido)
			UNION
			(SELECT Eq2 FROM partidos.Partido WHERE IdPartido = @partido))
		)
			THROW 50000, '- El tecnico no participo del encuentro.', 1;

		IF(@vRol = 'Jugador') AND
		NOT EXISTS
		(
			SELECT 1 FROM equipos.Jugador  
			WHERE IdJugador = @amonestado AND
			Seleccion IN
			((SELECT Eq1 FROM partidos.Partido WHERE IdPartido = @partido)
			UNION
			(SELECT Eq2 FROM partidos.Partido WHERE IdPartido = @partido))
		)
			THROW 50000, '- El jugador no participo del encuentro.', 1;

		SET @vLimSuspension = (SELECT SUSPENSION_TARJETAS_MAXIMAS FROM sedes.Mundial WHERE IdMundial = (SELECT IdMundial FROM partidos.Partido WHERE IdPartido = @partido))
		SET @vAutoRoja = 0
		SET @vSusp = 0

		BEGIN TRANSACTION

			IF
			EXISTS(
			SELECT 1
			FROM 
			partidos.Amonestacion AS A
			LEFT JOIN
			(SELECT IdEvento FROM partidos.Evento WHERE Partido = @partido AND Tipo = 'Amonestacion') AS E
			ON A.IdAmonestacion = E.IdEvento
			WHERE A.Amonestado = @amonestado AND A.Tarjeta = 'Roja')
				THROW 50000, 'Esta persona ya fue expulsada.', 1

			INSERT INTO partidos.Evento (Minuto, Periodo, Partido, Tipo)
			OUTPUT INSERTED.IdEvento into @ID
			VALUES (@minuto, @periodo, @partido, 'Amonestacion')

			INSERT INTO partidos.Amonestacion(IdAmonestacion, Amonestado, Arbitro, Tarjeta, Motivo)
			VALUES ((SELECT ID FROM @ID), @amonestado, @arbitro, @tarjeta, @motivo)

			IF(@tarjeta = 'Amarilla')
			BEGIN
				IF(@vRol = 'Jugador')
					SET @vTarjetasAcum = (SELECT TarjetasAcum FROM equipos.Jugador  WHERE IdJugador = @amonestado)
				ELSE
					SET @vTarjetasAcum = (SELECT TarjetasAcum FROM equipos.Tecnico  WHERE IdTecnico = @amonestado)

				IF( (@vTarjetasAcum + 1) = @vLimSuspension )
					SET @vSusp = 1
			END

			--chequeo si merece roja automatica(tiene 2 amarillas)
			IF(
			(
				SELECT COUNT(IdAmonestacion)
				FROM partidos.Amonestacion
				WHERE 
				Amonestado = @amonestado
				AND
				Tarjeta = 'Amarilla'
				AND
				IdAmonestacion IN (SELECT IdEvento FROM partidos.Evento WHERE Partido = @partido)
			) = 2)
			BEGIN
				INSERT INTO partidos.Evento (Minuto, Periodo, Partido, Tipo)
				OUTPUT INSERTED.IdEvento into @ID
				VALUES (@minuto, @periodo, @partido, 'Amonestacion')

				INSERT INTO partidos.Amonestacion(IdAmonestacion, Amonestado, Arbitro, Tarjeta, Motivo)
				VALUES ((SELECT TOP 1 ID FROM @ID ORDER BY ID DESC), @amonestado, @arbitro, 'Roja', 'Otorgada por recibir 2 tarjetas amarillas previamente.')

				SET @vAutoRoja = 1
			END

			--chequeo si merece suspension
			IF(@vRol = 'Jugador')
			BEGIN
				IF
				(@vSusp = 1)
				OR
				(@tarjeta = 'Roja')
				OR
				(@vAutoRoja = 1)
				BEGIN
					UPDATE equipos.Jugador 
					SET
					Estado = 'Suspendido', TarjetasAcum = 0
					WHERE IdJugador = @amonestado
				END
				ELSE
					UPDATE equipos.Jugador  SET TarjetasAcum = TarjetasAcum + 1 WHERE IdJugador = @amonestado
			END
			ELSE
			BEGIN
				IF
				(@vSusp = 1)
				OR
				(@tarjeta = 'Roja')
				OR
				(@vAutoRoja = 1)
				BEGIN
					UPDATE equipos.Tecnico 
					SET
					Estado = 'Suspendido', TarjetasAcum = 0
					WHERE IdTecnico = @amonestado
				END
				ELSE
					UPDATE equipos.Tecnico  SET TarjetasAcum = TarjetasAcum + 1 WHERE IdTecnico = @amonestado
			END

			COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END;
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspAmonestacion_UpdateTiempo'))
    DROP PROCEDURE SPTRANS.uspAmonestacion_UpdateTiempo
GO
CREATE PROCEDURE SPTRANS.uspAmonestacion_UpdateTiempo
@id INT,
@minuto INT,
@periodo INT = NULL
AS
BEGIN
	BEGIN TRY
		--Chequeo validez
		IF(@id IS NULL) OR (@id <= 0)
			THROW 50000, '- Valor invalido: ID Amonestacion.', 1;

		IF(@minuto IS NOT NULL) AND (@minuto < 0)
			THROW 50000, '- Valor invalido: Minuto.', 1;

		IF(@periodo IS NOT NULL) AND (@periodo <= 0)
			THROW 50000, '- Valor invalido: Periodo.', 1;

		--chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM partidos.Amonestacion WHERE IdAmonestacion = @id)
			THROW 50000, '- Registro inexistente.', 1;

		IF(@periodo IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM partidos.Periodo WHERE IdPeriodo = @periodo)
			THROW 50000, '- Valor inexistente: Periodo.', 1;
		
		--validez del minuto en relacion al periodo(cambiando solo el minuto)
		IF(@periodo IS NULL)
		BEGIN
			DECLARE @vCheck INT = (SELECT Periodo FROM partidos.Evento WHERE IdEvento = @id)

			IF
			( 
				(@minuto IS NULL) 
				AND 
				((SELECT Descripcion FROM partidos.Periodo WHERE IdPeriodo = @vCheck) <> 'Penales')
			)
			OR
			(
				(@minuto IS NOT NULL)
				AND
				(
					(@minuto < (SELECT Inicio FROM partidos.Periodo WHERE IdPeriodo = @vCheck))
					OR
					(@minuto > (SELECT Fin FROM partidos.Periodo WHERE IdPeriodo = @vCheck))
				)
			)
				THROW 50000, '- El minuto esta fuera del rango del periodo actual.', 1;
		END

		--validez del minuto en relacion al periodo(cambiando ambos)
		IF(@periodo IS NOT NULL)
		BEGIN
			IF
			(
				(@minuto IS NULL) 
				AND 
				( (SELECT Descripcion FROM partidos.Periodo WHERE IdPeriodo = @periodo) <> 'Penales' )
			)
			OR
			(
				(@minuto IS NOT NULL)
				AND
				(
					(@minuto < (SELECT Inicio FROM partidos.Periodo WHERE IdPeriodo = @periodo))
					OR
					(@minuto > (SELECT Fin FROM partidos.Periodo WHERE IdPeriodo = @periodo))
				)
			)
				THROW 50000, '- El minuto esta fuera del rango del periodo indicado.', 1;
		END

		BEGIN TRANSACTION

			UPDATE partidos.Evento
			SET
			Minuto = @minuto,
			Periodo = COALESCE(@periodo, Periodo)
			WHERE IdEvento = @id

			COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END;
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspAmonestacion_UpdateMotivo'))
    DROP PROCEDURE SPTRANS.uspAmonestacion_UpdateMotivo
GO
CREATE PROCEDURE SPTRANS.uspAmonestacion_UpdateMotivo
@id INT,
@motivo VARCHAR(300) 
AS
BEGIN
	BEGIN TRY
		--Chequeo validez
		IF(@id IS NULL) OR (@id <= 0)
			THROW 50000, '- Valor invalido: ID Amonestacion.', 1;

		IF(@motivo IS NULL)
			THROW 50000, '- Valor invalido: Motivo.', 1;

		--chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM partidos.Amonestacion WHERE IdAmonestacion = @id)
			THROW 50000, '- Registro inexistente.', 1;

		BEGIN TRANSACTION

			UPDATE partidos.Amonestacion
			SET Motivo = @motivo
			WHERE IdAmonestacion = @id

			COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END;
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspAmonestacion_Bajar'))
    DROP PROCEDURE SPTRANS.uspAmonestacion_Bajar
GO
CREATE PROCEDURE SPTRANS.uspAmonestacion_Bajar
@id INT
AS
BEGIN
	BEGIN TRY
		--Chequeo validez
		IF(@id IS NULL) OR (@id <= 0)
			THROW 50000, '- Valor invalido: ID Amonestacion.', 1;

		--chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM partidos.Amonestacion WHERE IdAmonestacion = @id)
			THROW 50000, '- Registro inexistente.', 1;

		BEGIN TRANSACTION

			DELETE FROM partidos.Amonestacion
			WHERE IdAmonestacion = @id

			DELETE FROM partidos.Evento
			WHERE IdEvento = @id

			COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END;
GO