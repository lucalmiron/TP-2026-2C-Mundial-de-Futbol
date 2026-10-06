--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: xx/xx/2026

--Creacion de Tabla Amonestacion

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.Amonestacion_Registrar'))
    DROP PROCEDURE SPTRANS.Amonestacion_Registrar
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
	DECLARE @errorCount INT
	DECLARE @errorLine varchar(300)
	DECLARE @vRol VARCHAR(10)
	DECLARE @vLimSuspension INT
	DECLARE @vTarjetasAcum INT
	DECLARE @vAutoRoja INT

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	--Chequeo validez
	IF(@minuto IS NOT NULL) AND (@minuto < 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Minuto.'
	END

	IF(@partido IS NULL) OR (@partido <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Partido.'
	END

	IF(@periodo IS NULL) OR (@periodo <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Periodo.'
	END

	IF(@amonestado IS NULL) OR (@amonestado <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Amonestado.'
	END

	IF(@arbitro IS NULL) OR (@arbitro <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Arbitro.'
	END

	IF(@tarjeta IS NULL) OR (@tarjeta NOT IN ('Amarilla', 'Roja'))
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Tarjeta.'
	END

	IF(@motivo IS NULL)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Motivo.'
	END

	--chequeo existencia
	IF(@errorCount = 0)
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM TABLAS.Periodo WHERE IdPeriodo = @periodo)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Periodo.'
		END

		IF NOT EXISTS(SELECT 1 FROM TABLAS.Persona WHERE IdPersona = @amonestado)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Amonestado.'
		END

		IF NOT EXISTS(SELECT 1 FROM TABLAS.Arbitro WHERE IdArbitro = @arbitro)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Arbitro.'
		END

		IF NOT EXISTS(SELECT 1 FROM TABLAS.Partido WHERE IdPartido = @partido)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Partido.'
		END
	END

	--validez del minuto en relacion al periodo
	IF(@errorCount = 0)
	AND
	(
		(
			(@minuto IS NULL) 
			AND 
			((SELECT Descripcion FROM TABLAS.Periodo WHERE IdPeriodo = @periodo) <> 'Penales')
		)
		OR
		(
			(@minuto IS NOT NULL)
			AND
			(@minuto < (SELECT Inicio FROM TABLAS.Periodo WHERE IdPeriodo = @periodo))
			AND
			(@minuto > (SELECT Fin FROM TABLAS.Periodo WHERE IdPeriodo = @periodo))
		)
	)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- El minuto esta fuera del rango del periodo indicado.'
	END

	--validez del amonestado
	IF(@errorCount = 0)
		SET @vRol = (SELECT Rol FROM TABLAS.Persona WHERE IdPersona = @amonestado)

	IF(@errorCount = 0) AND (@vRol = 'Arbitro')
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Objetivo de amonestacion invalido.'
	END

	--chequeo participacion
	IF(@errorCount = 0)
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM TABLAS.Arbitraje WHERE Arbitro = @arbitro AND Partido = @partido AND Funcion = 'Principal')
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- El arbitro no participo del encuentro o su funcion no le permite sancionar.'
		END

		IF(@vRol = 'Tecnico') AND 
		NOT EXISTS
		(
			SELECT 1 FROM TABLAS.Tecnico 
			WHERE IdTecnico = @amonestado AND 
			Seleccion IN
			((SELECT EquipoA FROM TABLAS.Partido WHERE IdPartido = @partido)
			UNION
			(SELECT EquipoB FROM TABLAS.Partido WHERE IdPartido = @partido))
		)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- El tecnico no participo del encuentro.'
		END

		IF(@vRol = 'Jugador') AND
		NOT EXISTS
		(
			SELECT 1 FROM TABLAS.Jugador 
			WHERE IdJugador = @amonestado AND
			Seleccion IN
			((SELECT EquipoA FROM TABLAS.Partido WHERE IdPartido = @partido)
			UNION
			(SELECT EquipoB FROM TABLAS.Partido WHERE IdPartido = @partido))
		)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- El jugador no participo del encuentro.'
		END
	END

	IF(@errorCount = 0)
	BEGIN
		SET @vLimSuspension = (SELECT MaxTarjetas FROM TABLAS.Mundial WHERE IdMundial = (SELECT Mundial FROM TABLAS.Partido WHERE IdPartido = @partido))
		SET @vAutoRoja = 0

		BEGIN TRANSACTION
		BEGIN TRY

			IF
			EXISTS(
			SELECT 1
			FROM 
			TABLAS.Amonestacion AS A
			LEFT JOIN
			(SELECT IdEvento FROM TABLAS.Evento WHERE Partido = @partido AND Tipo = 'Amonestacion') AS E
			ON A.IdAmonestacion = E.IdEvento
			WHERE A.Amonestado = @amonestado AND A.Tarjeta = 'Roja')
				THROW 50000, '- Esta persona ya fue expulsada.', 1

			INSERT INTO TABLAS.Evento (Minuto, Periodo, Partido)
			VALUES (@minuto, @periodo, @partido)

			INSERT INTO TABLAS.Amonestacion(Amonestado, Arbitro, Tarjeta, Motivo)
			VALUES (@amonestado, @arbitro, @tarjeta, @motivo)

			IF(
			(
				SELECT COUNT(IdAmonestacion)
				FROM TABLAS.Amonestacion
				WHERE 
				Amonestado = @amonestado
				AND
				Tarjeta = 'Amarilla'
				AND
				IdAmonestacion IN (SELECT IdEvento FROM TABLAS.Evento WHERE Partido = @partido)
			) = 2)
			BEGIN
				INSERT INTO TABLAS.Evento (Minuto, Periodo, Partido)
				VALUES (@minuto, @periodo, @partido)

				INSERT INTO TABLAS.Amonestacion(Amonestado, Arbitro, Tarjeta, Motivo)
				VALUES (@amonestado, @arbitro, 'Roja', 'Otorgada por recibir 2 tarjetas amarillas previamente.')

				SET @vAutoRoja = 1
			END

			IF(@vRol = 'Jugador')
			BEGIN
				SET @vTarjetasAcum = (SELECT TarjetasAcum FROM TABLAS.Jugador WHERE IdJugador = @amonestado)

				IF
				(@vTarjetasAcum = @vLimSuspension)
				OR
				(@tarjeta = 'Roja')
				OR
				(@vAutoRoja = 1)
				BEGIN
					UPDATE TABLAS.Jugador
					SET
					Estado = 'Suspendido',
					TarjetasAcum = 0
				END
				ELSE
					UPDATE TABLAS.Jugador SET TarjetasAcum = TarjetasAcum + 1
			END
			ELSE
			BEGIN
				SET @vTarjetasAcum = (SELECT TarjetasAcum FROM TABLAS.Tecnico WHERE IdTecnico = @amonestado)

				IF
				(@vTarjetasAcum = @vLimSuspension)
				OR
				(@tarjeta = 'Roja')
				OR
				(@vAutoRoja = 1)
				BEGIN
					UPDATE TABLAS.Tecnico
					SET
					Estado = 'Suspendido',
					TarjetasAcum = 0
				END
				ELSE
					UPDATE TABLAS.Tecnico SET TarjetasAcum = TarjetasAcum + 1
			END

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

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.Amonestacion_UpdateTiempo'))
    DROP PROCEDURE SPTRANS.Amonestacion_UpdateTiempo
GO
CREATE PROCEDURE SPTRANS.uspAmonestacion_UpdateTiempo
@id INT,
@minuto INT,
@periodo INT = NULL
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine varchar(300)
	DECLARE @vCheck INT

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	--Chequeo validez
	IF(@id IS NULL) OR (@id <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Amonestacion.'
	END

	IF(@minuto IS NOT NULL) AND (@minuto < 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Minuto.'
	END

	IF(@periodo IS NOT NULL) AND (@periodo <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Periodo.'
	END

	--chequeo existencia
	IF(@errorCount = 0)
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM TABLAS.Amonestacion WHERE IdAmonestacion = @id)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Registro inexistente.'
		END

		IF(@periodo IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM TABLAS.Periodo WHERE IdPeriodo = @periodo)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Periodo.'
		END
	END
	
	--validez del minuto en relacion al periodo(cambiando solo el minuto)
	IF(@errorCount = 0) AND (@periodo IS NULL)
	BEGIN
		SET @vCheck = (SELECT Periodo FROM TABLAS.Evento WHERE IdEvento = @id)

		IF
		( 
			(@minuto IS NULL) 
			AND 
			((SELECT Descripcion FROM TABLAS.Periodo WHERE IdPeriodo = @vCheck) <> 'Penales')
		)
		OR
		(
			(@minuto IS NOT NULL)
			AND
			(@minuto < (SELECT Inicio FROM TABLAS.Periodo WHERE IdPeriodo = @vCheck))
			AND
			(@minuto > (SELECT Fin FROM TABLAS.Periodo WHERE IdPeriodo = @vCheck))
		)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- El minuto esta fuera del rango del periodo indicado.'
		END
	END

	--validez del minuto en relacion al periodo(cambiando ambos)
	IF(@errorCount = 0) AND (@periodo IS NOT NULL)
	BEGIN
		IF
		(
			(@minuto IS NULL) 
			AND 
			((SELECT Descripcion FROM TABLAS.Periodo WHERE IdPeriodo = @periodo) <> 'Penales')
		)
		OR
		(
			(@minuto IS NOT NULL)
			AND
			(@minuto < (SELECT Inicio FROM TABLAS.Periodo WHERE IdPeriodo = @periodo))
			AND
			(@minuto > (SELECT Fin FROM TABLAS.Periodo WHERE IdPeriodo = @periodo))
		)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- El minuto esta fuera del rango del periodo indicado.'
		END
	END

	IF(@errorCount = 0)
	BEGIN
		BEGIN TRANSACTION
		BEGIN TRY

			UPDATE TABLAS.Evento
			SET
			Minuto = @minuto,
			Periodo = COALESCE(@periodo, Periodo)
			WHERE IdEvento = @id

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

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspAmonestacion_UpdateMotivo'))
    DROP PROCEDURE SPTRANS.uspAmonestacion_UpdateMotivo
GO
CREATE PROCEDURE SPTRANS.uspAmonestacion_UpdateMotivo
@id INT,
@motivo VARCHAR(300) 
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
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Amonestacion.'
	END

	IF(@motivo IS NULL)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Motivo.'
	END

	--chequeo existencia
	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM TABLAS.Amonestacion WHERE IdAmonestacion = @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Registro inexistente.'
	END

	IF(@errorCount = 0)
	BEGIN
		BEGIN TRANSACTION
		BEGIN TRY

			UPDATE TABLAS.Amonestacion
			SET Motivo = @motivo
			WHERE IdAmonestacion = @id

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

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.Amonestacion_Bajar'))
    DROP PROCEDURE SPTRANS.Amonestacion_Bajar
GO
CREATE PROCEDURE SPTRANS.uspAmonestacion_Bajar
@id INT
AS
BEGIN
	DECLARE @errorCount INT

	SET @errorCount = 0

	--Chequeo validez
	IF(@id IS NULL) OR (@id <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Valor invalido: ID Amonestacion.'
	END

	--chequeo existencia
	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM TABLAS.Amonestacion WHERE IdAmonestacion = @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Registro inexistente.'
	END

	IF(@errorCount = 0)
	BEGIN
		BEGIN TRANSACTION
		BEGIN TRY

			DELETE FROM TABLAS.Amonestacion
			WHERE IdAmonestacion = @id

			DELETE FROM TABLAS.Evento
			WHERE IdEvento = @id

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