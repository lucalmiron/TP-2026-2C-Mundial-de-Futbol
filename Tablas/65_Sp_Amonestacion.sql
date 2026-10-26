--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 25/10/26

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
	DECLARE @errores NVARCHAR(2048) = N'';
	DECLARE @vRol VARCHAR(10)
	DECLARE @vLimSuspension INT
	DECLARE @vTarjetasAcum INT
	DECLARE @vAutoRoja INT
	DECLARE @vSusp INT
	DECLARE @ID TABLE(ID INT)

	BEGIN TRY
		--Chequeo validez
		IF(@minuto IS NOT NULL) AND (@minuto < 0)
			SET @errores += '- Valor invalido: Minuto.' + N' ';

		IF(@partido IS NULL) OR (@partido <= 0)
			SET @errores += '- Valor invalido: Partido.' + N' ';

		IF(@periodo IS NULL) OR (@periodo <= 0)
			SET @errores += '- Valor invalido: Periodo.' + N' ';

		IF(@amonestado IS NULL) OR (@amonestado <= 0)
			SET @errores += '- Valor invalido: Amonestado.' + N' ';

		IF(@arbitro IS NULL) OR (@arbitro <= 0)
			SET @errores += '- Valor invalido: Arbitro.' + N' ';

		IF(@tarjeta IS NULL) OR (@tarjeta NOT IN ('Amarilla', 'Roja'))
			SET @errores += '- Valor invalido: Tarjeta.' + N' ';

		IF(@motivo IS NULL)
			SET @errores += '- Valor invalido: Motivo.' + N' ';

		--chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM partidos.Periodo WHERE IdPeriodo = @periodo)
			SET @errores += '- Valor inexistente: Periodo.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM equipos.Persona WHERE IdPersona = @amonestado)
			SET @errores += '- Valor inexistente: Amonestado.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM arbitros.Arbitro WHERE IdArbitro = @arbitro)
			SET @errores += '- Valor inexistente: Arbitro.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM partidos.Partido WHERE IdPartido = @partido)
			SET @errores += '- Valor inexistente: Partido.' + N' ';

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
			SET @errores += '- El minuto esta fuera del rango del periodo indicado.' + N' ';

		--validez del amonestado
		SET @vRol = (SELECT Rol FROM equipos.Persona WHERE IdPersona = @amonestado)

		IF(@vRol = 'Arbitro')
			SET @errores += '- Objetivo de amonestacion invalido.' + N' ';

		--chequeo participacion
		IF NOT EXISTS(SELECT 1 FROM arbitros.Arbitraje WHERE Arbitro = @arbitro AND Partido = @partido AND Funcion = 'Principal')
			SET @errores += '- El arbitro no participo del encuentro o su funcion no le permite sancionar.' + N' ';

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
			SET @errores += '- El tecnico no participo del encuentro.' + N' ';

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
			SET @errores += '- El jugador no participo del encuentro.' + N' ';

		SET @vLimSuspension = (SELECT SUSPENSION_TARJETAS_MAXIMAS FROM sedes.Mundial WHERE IdMundial = (SELECT IdMundial FROM partidos.Partido WHERE IdPartido = @partido))
		SET @vAutoRoja = 0
		SET @vSusp = 0

		BEGIN TRANSACTION

			IF
			EXISTS(
			SELECT 1
			FROM 
			partidos.Amonestacion AS A
			INNER JOIN
			(SELECT IdEvento FROM partidos.Evento WHERE Partido = @partido AND Tipo = 'Amonestacion') AS E
			ON A.IdAmonestacion = E.IdEvento
			WHERE A.Amonestado = @amonestado AND A.Tarjeta = 'Roja')
				SET @errores += 'Esta persona ya fue expulsada.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

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
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		--Chequeo validez
		IF(@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Amonestacion.' + N' ';

		IF(@minuto IS NOT NULL) AND (@minuto < 0)
			SET @errores += '- Valor invalido: Minuto.' + N' ';

		IF(@periodo IS NOT NULL) AND (@periodo <= 0)
			SET @errores += '- Valor invalido: Periodo.' + N' ';

		--chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM partidos.Amonestacion WHERE IdAmonestacion = @id)
			SET @errores += '- Registro inexistente.' + N' ';

		IF(@periodo IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM partidos.Periodo WHERE IdPeriodo = @periodo)
			SET @errores += '- Valor inexistente: Periodo.' + N' ';
		
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
				SET @errores += '- El minuto esta fuera del rango del periodo actual.' + N' ';
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
				SET @errores += '- El minuto esta fuera del rango del periodo indicado.' + N' ';
		END

		BEGIN TRANSACTION

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

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
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		--Chequeo validez
		IF(@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Amonestacion.' + N' ';

		IF(@motivo IS NULL)
			SET @errores += '- Valor invalido: Motivo.' + N' ';

		--chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM partidos.Amonestacion WHERE IdAmonestacion = @id)
			SET @errores += '- Registro inexistente.' + N' ';

		BEGIN TRANSACTION

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

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
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		--Chequeo validez
		IF(@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Amonestacion.' + N' ';

		--chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM partidos.Amonestacion WHERE IdAmonestacion = @id)
			SET @errores += '- Registro inexistente.' + N' ';

		BEGIN TRANSACTION

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

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