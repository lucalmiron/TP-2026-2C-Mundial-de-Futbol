--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 08/10/2026

--Testing de StoredProcedures asociados a la entidad Amonestacion

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIALtesting')
BEGIN
	USE MUNDIALtesting
END;
GO

--Limpieza previa para re-ejecucion en base sucia (orden inverso de dependencias)
DROP TABLE IF EXISTS TABLAS.Amonestacion
DROP TABLE IF EXISTS TABLAS.Arbitraje
DROP TABLE IF EXISTS TABLAS.Evento
DROP TABLE IF EXISTS TABLAS.Jugador
DROP TABLE IF EXISTS TABLAS.Tecnico
DROP TABLE IF EXISTS TABLAS.Arbitro
DROP TABLE IF EXISTS TABLAS.Partido
DROP TABLE IF EXISTS TABLAS.Periodo
DROP TABLE IF EXISTS TABLAS.Persona
DROP TABLE IF EXISTS TABLAS.Mundial
GO

--tablas auxiliares de testing
CREATE TABLE TABLAS.Mundial
(
	IdMundial INT PRIMARY KEY,
	MaxTarjetas INT
);
GO
CREATE TABLE TABLAS.Partido
(
	IdPartido INT PRIMARY KEY,
	EquipoA INT,
	EquipoB INT,
	Mundial INT,
	FOREIGN KEY(Mundial) REFERENCES TABLAS.Mundial(IdMundial)
);
GO
CREATE TABLE TABLAS.Persona
(
	IdPersona INT PRIMARY KEY,
	Rol VARCHAR(10)
);
GO
CREATE TABLE TABLAS.Jugador
(
	IdJugador INT,
	Seleccion INT,
	TarjetasAcum INT, 
	Estado VARCHAR(10),
	FOREIGN KEY(IdJugador) REFERENCES TABLAS.Persona(IdPersona)
);
GO
CREATE TABLE TABLAS.Tecnico
(
	IdTecnico INT,
	Seleccion INT,
	TarjetasAcum INT,
	Estado VARCHAR(10),
	FOREIGN KEY(IdTecnico) REFERENCES TABLAS.Persona(IdPersona)
);
GO
CREATE TABLE TABLAS.Arbitro
(
	IdArbitro INT,
	FOREIGN KEY(IdArbitro) REFERENCES TABLAS.Persona(IdPersona),
	PRIMARY KEY(IdArbitro)
);

CREATE TABLE TABLAS.Arbitraje
(
	Arbitro INT,
	Partido INT,
	Funcion VARCHAR(20),
	FOREIGN KEY(Partido) REFERENCES TABLAS.Partido(IdPartido),
	FOREIGN KEY(Arbitro) REFERENCES TABLAS.Arbitro(IdArbitro),
	PRIMARY KEY(Arbitro, Partido)
);
GO
CREATE TABLE TABLAS.Periodo
(
	IdPeriodo INT PRIMARY KEY,
	Descripcion VARCHAR(12),
	Inicio INT,
	Fin INT
);
GO

--Llenado de tablas auxiliares de testing
INSERT INTO TABLAS.Mundial(IdMundial, MaxTarjetas) VALUES (1, 6);

INSERT INTO TABLAS.Partido(IdPartido, EquipoA, EquipoB, Mundial) VALUES (1, 1, 2, 1), (2, 3, 4, 1), (3, 5, 6, 1);

INSERT INTO TABLAS.Persona(IdPersona, Rol)
VALUES
(1, 'Jugador'),
(2, 'Jugador'),
(3, 'Jugador'),
(4, 'Tecnico'),
(5, 'Arbitro'),
(6, 'Arbitro'),
(7, 'Arbitro'),
(8, 'Tecnico'),
(9, 'Tecnico'),
(10, 'Jugador'),
(11, 'Jugador'),
(12, 'Tecnico'),
(13, 'Tecnico');

INSERT INTO TABLAS.Jugador(IdJugador, Seleccion, Estado, TarjetasAcum)
VALUES
(1, 1, 'Activo', 3),
(2, 2, 'Activo', 5),
(3, 5, 'Activo', 5),
(10, 1, 'Activo', 0),
(11, 2, 'Activo', 0);

INSERT INTO TABLAS.Tecnico(IdTecnico, Seleccion, TarjetasAcum, Estado)
VALUES
(4, 1, 3, 'Activo'),
(8, 2, 5, 'Activo'),
(9, 5, 5, 'Activo'),
(12, 1, 0, 'Activo'),
(13, 2, 0, 'Activo');

INSERT INTO TABLAS.Arbitro(IdArbitro)
VALUES
(5), (6), (7);

INSERT INTO TABLAS.Arbitraje(Arbitro, Partido, Funcion)
VALUES
(5, 1, 'Principal'),
(6, 1, 'Asistente'),
(7, 3, 'Principal');

INSERT INTO TABLAS.Periodo(IdPeriodo, Descripcion, Inicio, Fin)
VALUES
(1, '1erTiempo', 0, 45),
(2, '1erAdicional', 45, 50),
(3, '2doTiempo', 45, 90),
(4, '2doAdicional', 90, 95),
(5, '1erProrroga', 0, 15),
(6, '2daProrroga', 0, 15),
(7, 'Penales', NULL, NULL);
GO

--Tablas a testear
CREATE TABLE TABLAS.Evento
(
	IdEvento INT PRIMARY KEY IDENTITY(1, 1),
	Minuto INT,
	Tipo VARCHAR(12) NOT NULL,
	Partido INT,
	Periodo INT,
	FOREIGN KEY(Partido) REFERENCES TABLAS.Partido(IdPartido),
	FOREIGN KEY(Periodo) REFERENCES TABLAS.Periodo(IdPeriodo)
);
GO
CREATE TABLE TABLAS.Amonestacion
(
	IdAmonestacion INT,
	Amonestado INT,
	Arbitro INT,
	Tarjeta VARCHAR(8),
	Motivo VARCHAR(300),
	FOREIGN KEY(IdAmonestacion) REFERENCES TABLAS.Evento,
	FOREIGN KEY(Amonestado) REFERENCES TABLAS.Persona,
	FOREIGN KEY(Arbitro) REFERENCES TABLAS.Arbitro,
	PRIMARY KEY(IdAmonestacion)
);
GO

--SPs a testear
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
			OR
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

			INSERT INTO TABLAS.Evento (Minuto, Tipo, Periodo, Partido)
			VALUES (@minuto, 'Amonestacion', @periodo, @partido)

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
				INSERT INTO TABLAS.Evento (Minuto, Tipo, Periodo, Partido)
				VALUES (@minuto, 'Amonestacion', @periodo, @partido)

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
					WHERE IdJugador = @amonestado
				END
				ELSE
					UPDATE TABLAS.Jugador SET TarjetasAcum = TarjetasAcum + 1 WHERE IdJugador = @amonestado
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
					WHERE IdTecnico = @amonestado
				END
				ELSE
					UPDATE TABLAS.Tecnico SET TarjetasAcum = TarjetasAcum + 1 WHERE IdTecnico = @amonestado
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

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspAmonestacion_UpdateTiempo'))
    DROP PROCEDURE SPTRANS.uspAmonestacion_UpdateTiempo
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
			OR
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
			OR
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

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspAmonestacion_Bajar'))
    DROP PROCEDURE SPTRANS.uspAmonestacion_Bajar
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
			DECLARE @vAmonestado INT = (SELECT Amonestado FROM TABLAS.Amonestacion WHERE IdAmonestacion = @id)

			--Al eliminar la amonestacion se restaura el estado del amonestado.
			IF EXISTS(SELECT 1 FROM TABLAS.Jugador WHERE IdJugador = @vAmonestado)
				UPDATE TABLAS.Jugador
				SET Estado = 'Activo'
				WHERE IdJugador = @vAmonestado

			ELSE IF EXISTS(SELECT 1 FROM TABLAS.Tecnico WHERE IdTecnico = @vAmonestado)
				UPDATE TABLAS.Tecnico
				SET Estado = 'Activo'
				WHERE IdTecnico = @vAmonestado

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

--////Testing de Registro exitoso

--/Jugador
--A)Jugador recibe (1) amarilla y acumula
SELECT * FROM TABLAS.Jugador;

EXECUTE SPTRANS.uspAmonestacion_Registrar 
@minuto = 39, 
@partido = 1, 
@periodo = 1, 
@amonestado = 1,
@arbitro = 5,
@tarjeta = 'Amarilla',
@motivo = 'Tacleo a un adversario.';

SELECT * FROM TABLAS.Jugador;
SELECT * FROM TABLAS.Evento WHERE Tipo = 'Amonestacion';
SELECT * FROM TABLAS.Amonestacion;
GO

--B)Jugador recibe (1) amarilla estando al limite y queda suspendido
SELECT * FROM TABLAS.Jugador;

EXECUTE SPTRANS.uspAmonestacion_Registrar 
@minuto = 39, 
@partido = 1, 
@periodo = 1, 
@amonestado = 2,
@arbitro = 5,
@tarjeta = 'Amarilla',
@motivo = 'Tacleo a un adversario.';

SELECT * FROM TABLAS.Jugador;
SELECT * FROM TABLAS.Evento WHERE Tipo = 'Amonestacion';
SELECT * FROM TABLAS.Amonestacion;
GO

--C)Jugador recibe (1) una roja directa y queda suspendido
SELECT * FROM TABLAS.Jugador;

EXECUTE SPTRANS.uspAmonestacion_Registrar 
@minuto = 39, 
@partido = 1, 
@periodo = 1, 
@amonestado = 10,
@arbitro = 5,
@tarjeta = 'Roja',
@motivo = 'Tacleo a un adversario.';

SELECT * FROM TABLAS.Jugador;
SELECT * FROM TABLAS.Evento WHERE Tipo = 'Amonestacion';
SELECT * FROM TABLAS.Amonestacion;
GO

--D)Jugador recibe (2) tarjetas amarillas, y queda suspendido
SELECT * FROM TABLAS.Jugador;

EXECUTE SPTRANS.uspAmonestacion_Registrar 
@minuto = 39, 
@partido = 1, 
@periodo = 1, 
@amonestado = 11,
@arbitro = 5,
@tarjeta = 'Amarilla',
@motivo = 'Tacleo a un adversario.';
EXECUTE SPTRANS.uspAmonestacion_Registrar 
@minuto = 42, 
@partido = 1, 
@periodo = 1, 
@amonestado = 11,
@arbitro = 5,
@tarjeta = 'Amarilla',
@motivo = 'Mordio a un adversario.';

SELECT * FROM TABLAS.Jugador;
SELECT * FROM TABLAS.Evento WHERE Tipo = 'Amonestacion';
SELECT * FROM TABLAS.Amonestacion;
GO

--/Tecnico
--A)Tecnico recibe (1) amarilla y acumula
SELECT * FROM TABLAS.Tecnico;

EXECUTE SPTRANS.uspAmonestacion_Registrar 
@minuto = 39, 
@partido = 1, 
@periodo = 1, 
@amonestado = 4,
@arbitro = 5,
@tarjeta = 'Amarilla',
@motivo = 'Tacleo a un adversario.';

SELECT * FROM TABLAS.Tecnico;
SELECT * FROM TABLAS.Evento WHERE Tipo = 'Amonestacion';
SELECT * FROM TABLAS.Amonestacion;
GO

--B)Tecnico recibe (1) amarilla estando al limite y queda suspendido
SELECT * FROM TABLAS.Tecnico;

EXECUTE SPTRANS.uspAmonestacion_Registrar 
@minuto = 39, 
@partido = 1, 
@periodo = 1, 
@amonestado = 8,
@arbitro = 5,
@tarjeta = 'Amarilla',
@motivo = 'Tacleo a un adversario.';

SELECT * FROM TABLAS.Tecnico;
SELECT * FROM TABLAS.Evento WHERE Tipo = 'Amonestacion';
SELECT * FROM TABLAS.Amonestacion;
GO

--C)Tecnico recibe (1) una roja directa y queda suspendido
SELECT * FROM TABLAS.Tecnico;

EXECUTE SPTRANS.uspAmonestacion_Registrar 
@minuto = 39, 
@partido = 1, 
@periodo = 1, 
@amonestado = 12,
@arbitro = 5,
@tarjeta = 'Roja',
@motivo = 'Tacleo a un adversario.';

SELECT * FROM TABLAS.Tecnico;
SELECT * FROM TABLAS.Evento WHERE Tipo = 'Amonestacion';
SELECT * FROM TABLAS.Amonestacion;
GO

--D)Tecnico recibe (2) tarjetas amarillas, y queda suspendido
SELECT * FROM TABLAS.Tecnico;

EXECUTE SPTRANS.uspAmonestacion_Registrar 
@minuto = 39, 
@partido = 1, 
@periodo = 1, 
@amonestado = 13,
@arbitro = 5,
@tarjeta = 'Amarilla',
@motivo = 'Tacleo a un adversario.';
EXECUTE SPTRANS.uspAmonestacion_Registrar 
@minuto = 42, 
@partido = 1, 
@periodo = 1, 
@amonestado = 13,
@arbitro = 1,
@tarjeta = 'Amarilla',
@motivo = 'Mordio a un adversario.';

SELECT * FROM TABLAS.Tecnico;
SELECT * FROM TABLAS.Evento WHERE Tipo = 'Amonestacion';
SELECT * FROM TABLAS.Amonestacion;
GO

--Testing de Update exitoso
--Datos actuales
SELECT * FROM TABLAS.Evento WHERE IdEvento = 1;
SELECT * FROM TABLAS.Amonestacion WHERE IdAmonestacion = 1;
GO

--Cambio de Tiempo
EXECUTE SPTRANS.uspAmonestacion_UpdateTiempo @id = 1, @minuto = 23;
SELECT * FROM TABLAS.Evento WHERE IdEvento = 1;
SELECT * FROM TABLAS.Amonestacion WHERE IdAmonestacion = 1;
GO
--Cambio de Tiempo y Periodo
EXECUTE SPTRANS.uspAmonestacion_UpdateTiempo @id = 1, @minuto = 42, @periodo = 2;
SELECT * FROM TABLAS.Evento WHERE IdEvento = 1;
SELECT * FROM TABLAS.Amonestacion WHERE IdAmonestacion = 1;
GO
--Cambio de Motivo
EXECUTE SPTRANS.uspAmonestacion_UpdateMotivo @id = 1, @motivo = 'Ataco con una patada al rival.';
SELECT * FROM TABLAS.Evento WHERE IdEvento = 1;
SELECT * FROM TABLAS.Amonestacion WHERE IdAmonestacion = 1;
GO

--Testing de Baja exitosa
SELECT * FROM TABLAS.Evento WHERE IdEvento = 1;
SELECT * FROM TABLAS.Amonestacion WHERE IdAmonestacion = 1;

EXECUTE SPTRANS.uspAmonestacion_Bajar @id = 1;

SELECT * FROM TABLAS.Evento WHERE IdEvento = 1;
SELECT * FROM TABLAS.Amonestacion WHERE IdAmonestacion = 1;
GO

--////Testing de Casos de Falla

--/Registro
--Valores invalidos/inexistentes
EXECUTE SPTRANS.uspAmonestacion_Registrar 
@minuto = -36, 
@partido = NULL, 
@periodo = 0, 
@amonestado = NULL,
@arbitro = -1,
@tarjeta = 'Violeta',
@motivo = NULL;
EXECUTE SPTRANS.uspAmonestacion_Registrar 
@minuto = 36, 
@partido = 65, 
@periodo = 768, 
@amonestado = 234,
@arbitro = 456,
@tarjeta = 'Amarilla',
@motivo = 'Golpe a zonas bajas.';
--Jugador/Tecnico/Arbitro no estuvo involucrado en el encuentro o el Arbitro no fue el Principal para poder amonestar
EXECUTE SPTRANS.uspAmonestacion_Registrar 
@minuto = 36, 
@partido = 1, 
@periodo = 1, 
@amonestado = 3,
@arbitro = 7,
@tarjeta = 'Amarilla',
@motivo = 'Golpe a zonas bajas.';
EXECUTE SPTRANS.uspAmonestacion_Registrar 
@minuto = 36, 
@partido = 1, 
@periodo = 1, 
@amonestado = 9,
@arbitro = 6,
@tarjeta = 'Amarilla',
@motivo = 'Golpe a zonas bajas.';
--Individuo ya fue expulsado
EXECUTE SPTRANS.uspAmonestacion_Registrar 
@minuto = 36, 
@partido = 1, 
@periodo = 1, 
@amonestado = 10,
@arbitro = 5,
@tarjeta = 'Amarilla',
@motivo = 'Golpe a zonas bajas.';
--Minuto no corresponde con el periodo
EXECUTE SPTRANS.uspAmonestacion_Registrar 
@minuto = 36, 
@partido = 1, 
@periodo = 3, 
@amonestado = 4,
@arbitro = 5,
@tarjeta = 'Amarilla',
@motivo = 'Golpe a zonas bajas.';

--/Update
SELECT * FROM TABLAS.Evento WHERE Tipo = 'Amonestacion';
SELECT * FROM TABLAS.Amonestacion;
GO
--Valores invalidos/inexistentes
EXECUTE SPTRANS.uspAmonestacion_UpdateTiempo @id = 0, @minuto = -1, @periodo = 0;
EXECUTE SPTRANS.uspAmonestacion_UpdateTiempo @id = 56, @minuto = 11, @periodo = 1;
EXECUTE SPTRANS.uspAmonestacion_UpdateTiempo @id = 1, @minuto = 11, @periodo = 1;
EXECUTE SPTRANS.uspAmonestacion_UpdateMotivo @id = 0, @motivo = NULL;
EXECUTE SPTRANS.uspAmonestacion_UpdateMotivo @id = 56, @motivo = 'Ataque con pi�as y patadas.';
GO
--Minuto y Periodo no coinciden
EXECUTE SPTRANS.uspAmonestacion_UpdateTiempo @id = 2, @minuto = 65;
EXECUTE SPTRANS.uspAmonestacion_UpdateTiempo @id = 2, @minuto = 65, @periodo = 1;
GO

--/Baja
--Valores invalidos/inexistentes
EXECUTE SPTRANS.uspAmonestacion_Bajar @id = 0;
EXECUTE SPTRANS.uspAmonestacion_Bajar @id = 67;
GO

--Limpieza
DROP PROCEDURE SPTRANS.uspAmonestacion_Registrar;
DROP PROCEDURE SPTRANS.uspAmonestacion_UpdateTiempo;
DROP PROCEDURE SPTRANS.uspAmonestacion_UpdateMotivo;
DROP PROCEDURE SPTRANS.uspAmonestacion_Bajar;
GO

DROP TABLE TABLAS.Amonestacion;
DROP TABLE TABLAS.Arbitraje;
DROP TABLE TABLAS.Evento;
DROP TABLE TABLAS.Jugador;
DROP TABLE TABLAS.Tecnico;
DROP TABLE TABLAS.Arbitro;
DROP TABLE TABLAS.Partido;
DROP TABLE TABLAS.Persona;
DROP TABLE TABLAS.Mundial;
GO