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
	Funcion VARCHAR(9),
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

INSERT INTO TABLAS.Partido(IdPartido, EquipoA, EquipoB, Mundial) 
VALUES 
(1, 1, 2, 1), 
(3, 2, 1, 1);

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

--Inspeccion de datos cargados
/*
SELECT * FROM TABLAS.Mundial
SELECT * FROM TABLAS.Partido
SELECT * FROM TABLAS.Persona
SELECT * FROM TABLAS.Jugador
SELECT * FROM TABLAS.Tecnico
SELECT * FROM TABLAS.Arbitro
SELECT * FROM TABLAS.Periodo
SELECT * FROM TABLAS.Arbitraje
*/

--Tablas a testear
CREATE TABLE TABLAS.Evento
(
	IdEvento INT PRIMARY KEY IDENTITY(1, 1),
	Minuto INT,
	Tipo VARCHAR(12),
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
		IF NOT EXISTS(SELECT 1 FROM TABLAS.Periodo WHERE IdPeriodo = @periodo)
			THROW 50000, '- Valor inexistente: Periodo.', 1;

		IF NOT EXISTS(SELECT 1 FROM TABLAS.Persona WHERE IdPersona = @amonestado)
			THROW 50000, '- Valor inexistente: Amonestado.', 1;

		IF NOT EXISTS(SELECT 1 FROM TABLAS.Arbitro WHERE IdArbitro = @arbitro)
			THROW 50000, '- Valor inexistente: Arbitro.', 1;

		IF NOT EXISTS(SELECT 1 FROM TABLAS.Partido WHERE IdPartido = @partido)
			THROW 50000, '- Valor inexistente: Partido.', 1;

		--validez del minuto en relacion al periodo
		IF(
			(
				(@minuto IS NULL) 
				AND 
				((SELECT Descripcion FROM TABLAS.Periodo WHERE IdPeriodo = @periodo) <> 'Penales')
			)
			OR
			(
				(@minuto IS NOT NULL)
				AND
				(
					(@minuto < (SELECT Inicio FROM TABLAS.Periodo WHERE IdPeriodo = @periodo))
					OR
					(@minuto > (SELECT Fin FROM TABLAS.Periodo WHERE IdPeriodo = @periodo))
				)
			)
		)
			THROW 50000, '- El minuto esta fuera del rango del periodo indicado.', 1;

		--validez del amonestado
		SET @vRol = (SELECT Rol FROM TABLAS.Persona WHERE IdPersona = @amonestado)

		IF(@vRol = 'Arbitro')
			THROW 50000, '- Objetivo de amonestacion invalido.', 1;

		--chequeo participacion
		IF NOT EXISTS(SELECT 1 FROM TABLAS.Arbitraje WHERE Arbitro = @arbitro AND Partido = @partido AND Funcion = 'Principal')
			THROW 50000, '- El arbitro no participo del encuentro o su funcion no le permite sancionar.', 1;

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
			THROW 50000, '- El tecnico no participo del encuentro.', 1;

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
			THROW 50000, '- El jugador no participo del encuentro.', 1;

		SET @vLimSuspension = (SELECT MaxTarjetas FROM TABLAS.Mundial WHERE IdMundial = (SELECT Mundial FROM TABLAS.Partido WHERE IdPartido = @partido))
		SET @vAutoRoja = 0
		SET @vSusp = 0

		BEGIN TRANSACTION

			IF
			EXISTS(
			SELECT 1
			FROM 
			TABLAS.Amonestacion AS A
			LEFT JOIN
			(SELECT IdEvento FROM TABLAS.Evento WHERE Partido = @partido AND Tipo = 'Amonestacion') AS E
			ON A.IdAmonestacion = E.IdEvento
			WHERE A.Amonestado = @amonestado AND A.Tarjeta = 'Roja')
				THROW 50000, 'Esta persona ya fue expulsada.', 1

			INSERT INTO TABLAS.Evento (Minuto, Periodo, Partido, Tipo)
			OUTPUT INSERTED.IdEvento into @ID
			VALUES (@minuto, @periodo, @partido, 'Amonestacion')

			INSERT INTO TABLAS.Amonestacion(IdAmonestacion, Amonestado, Arbitro, Tarjeta, Motivo)
			VALUES ((SELECT ID FROM @ID), @amonestado, @arbitro, @tarjeta, @motivo)

			IF(@tarjeta = 'Amarilla')
			BEGIN
				IF(@vRol = 'Jugador')
					SET @vTarjetasAcum = (SELECT TarjetasAcum FROM TABLAS.Jugador WHERE IdJugador = @amonestado)
				ELSE
					SET @vTarjetasAcum = (SELECT TarjetasAcum FROM TABLAS.Tecnico WHERE IdTecnico = @amonestado)

				IF( (@vTarjetasAcum + 1) = @vLimSuspension )
					SET @vSusp = 1
			END

			--chequeo si merece roja automatica(tiene 2 amarillas)
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
				INSERT INTO TABLAS.Evento (Minuto, Periodo, Partido, Tipo)
				OUTPUT INSERTED.IdEvento into @ID
				VALUES (@minuto, @periodo, @partido, 'Amonestacion')

				INSERT INTO TABLAS.Amonestacion(IdAmonestacion, Amonestado, Arbitro, Tarjeta, Motivo)
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
					UPDATE TABLAS.Jugador
					SET
					Estado = 'Suspendido', TarjetasAcum = 0
					WHERE IdJugador = @amonestado
				END
				ELSE
					UPDATE TABLAS.Jugador SET TarjetasAcum = TarjetasAcum + 1 WHERE IdJugador = @amonestado
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
					UPDATE TABLAS.Tecnico
					SET
					Estado = 'Suspendido', TarjetasAcum = 0
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
	DECLARE @vCheck INT

	BEGIN TRY
		--Chequeo validez
		IF(@id IS NULL) OR (@id <= 0)
			THROW 50000, '- Valor invalido: ID Amonestacion.', 1;

		IF(@minuto IS NOT NULL) AND (@minuto < 0)
			THROW 50000, '- Valor invalido: Minuto.', 1;

		IF(@periodo IS NOT NULL) AND (@periodo <= 0)
			THROW 50000, '- Valor invalido: Periodo.', 1;

		--chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM TABLAS.Amonestacion WHERE IdAmonestacion = @id)
			THROW 50000, '- Registro inexistente.', 1;

		IF(@periodo IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM TABLAS.Periodo WHERE IdPeriodo = @periodo)
			THROW 50000, '- Valor inexistente: Periodo.', 1;
		
		--validez del minuto en relacion al periodo(cambiando solo el minuto)
		IF(@periodo IS NULL)
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
				(
					(@minuto < (SELECT Inicio FROM TABLAS.Periodo WHERE IdPeriodo = @vCheck))
					OR
					(@minuto > (SELECT Fin FROM TABLAS.Periodo WHERE IdPeriodo = @vCheck))
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
				( (SELECT Descripcion FROM TABLAS.Periodo WHERE IdPeriodo = @periodo) <> 'Penales' )
			)
			OR
			(
				(@minuto IS NOT NULL)
				AND
				(
					(@minuto < (SELECT Inicio FROM TABLAS.Periodo WHERE IdPeriodo = @periodo))
					OR
					(@minuto > (SELECT Fin FROM TABLAS.Periodo WHERE IdPeriodo = @periodo))
				)
			)
				THROW 50000, '- El minuto esta fuera del rango del periodo indicado.', 1;
		END

		BEGIN TRANSACTION

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
		IF NOT EXISTS(SELECT 1 FROM TABLAS.Amonestacion WHERE IdAmonestacion = @id)
			THROW 50000, '- Registro inexistente.', 1;

		BEGIN TRANSACTION

			UPDATE TABLAS.Amonestacion
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
		IF NOT EXISTS(SELECT 1 FROM TABLAS.Amonestacion WHERE IdAmonestacion = @id)
			THROW 50000, '- Registro inexistente.', 1;

		BEGIN TRANSACTION

			DELETE FROM TABLAS.Amonestacion
			WHERE IdAmonestacion = @id

			DELETE FROM TABLAS.Evento
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
@motivo = 'Golpeo a un adversario.';

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
@motivo = 'Insulto a un adversario.';
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
@arbitro = 5,
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
SELECT * FROM TABLAS.Periodo
--Cambio de Tiempo
EXECUTE SPTRANS.uspAmonestacion_UpdateTiempo @id = 1, @minuto = 23;
SELECT * FROM TABLAS.Evento WHERE IdEvento = 1;
SELECT * FROM TABLAS.Amonestacion WHERE IdAmonestacion = 1;
GO
--Cambio de Tiempo y Periodo
EXECUTE SPTRANS.uspAmonestacion_UpdateTiempo @id = 1, @minuto = 47, @periodo = 2;
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
GO
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
GO
--Individuo ya fue expulsado
EXECUTE SPTRANS.uspAmonestacion_Registrar 
@minuto = 36, 
@partido = 1, 
@periodo = 1, 
@amonestado = 10,
@arbitro = 5,
@tarjeta = 'Amarilla',
@motivo = 'Golpe a zonas bajas.';
GO
--Minuto no corresponde con el periodo
EXECUTE SPTRANS.uspAmonestacion_Registrar 
@minuto = 36, 
@partido = 1, 
@periodo = 3, 
@amonestado = 4,
@arbitro = 5,
@tarjeta = 'Amarilla',
@motivo = 'Golpe a zonas bajas.';
GO

--/Update
SELECT * FROM TABLAS.Evento WHERE Tipo = 'Amonestacion';
SELECT * FROM TABLAS.Amonestacion;
GO
--Valores invalidos/inexistentes
EXECUTE SPTRANS.uspAmonestacion_UpdateTiempo @id = 0, @minuto = -1, @periodo = 0;
EXECUTE SPTRANS.uspAmonestacion_UpdateTiempo @id = 56, @minuto = 11, @periodo = 1;
EXECUTE SPTRANS.uspAmonestacion_UpdateMotivo @id = 0, @motivo = NULL;
EXECUTE SPTRANS.uspAmonestacion_UpdateMotivo @id = 56, @motivo = 'Ataque con piñas y patadas.';
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
DROP TABLE TABLAS.Evento;
DROP TABLE TABLAS.Arbitraje;
DROP TABLE TABLAS.Partido;
DROP TABLE TABLAS.Mundial;
DROP TABLE TABLAS.Jugador;
DROP TABLE TABLAS.Tecnico;
DROP TABLE TABLAS.Arbitro;
DROP TABLE TABLAS.Persona;
DROP TABLE TABLAS.Periodo;
GO