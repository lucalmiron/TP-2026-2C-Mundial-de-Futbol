--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 25/10/26

--Creacion de Stored Procedures que involucran transacciones

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END
GO

--Arbitraje
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspArbitraje_Registrar'))
    DROP PROCEDURE SPTRANS.uspArbitraje_Registrar
GO
CREATE PROCEDURE SPTRANS.uspArbitraje_Registrar 
@arbitro INT,
@funcion VARCHAR(20),
@partido INT
AS
BEGIN
	BEGIN TRY
		--Chequeo validez
		IF(@arbitro IS NULL) OR (@arbitro <= 0)
			THROW 50000, '- Valor invalido: ID Arbitro.', 1;

		IF(@funcion IS NULL) OR (@funcion NOT IN ('Principal', 'Asistente', '4to', 'VAR'))
			THROW 50000, '- Valor invalido: Funcion.', 1;

		IF(@partido IS NULL) OR (@partido <= 0)
			THROW 50000, '- Valor invalido: ID Partido.', 1;

		--chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM arbitros.Arbitro WHERE IdArbitro = @arbitro)
			THROW 50000, '- Valor inexistente: ID Arbitro.', 1;

		IF NOT EXISTS(SELECT 1 FROM partidos.Partido WHERE IdPartido = @partido)
			THROW 50000, '- Valor inexistente: ID Partido.', 1;

		--chequeo dup
		IF EXISTS(SELECT 1 FROM arbitros.Arbitraje WHERE Arbitro = @arbitro AND Partido = @partido)
			THROW 50000, '- Valor duplicado: Arbitro. Se encuentra ya asignado a alguna funcion de ese partido.', 1;

		--chequeo cupo
		IF(
			((@funcion = 'Principal') AND ((SELECT COUNT(Arbitro) FROM arbitros.Arbitraje WHERE Partido = @partido AND Funcion = 'Principal') >= 1))
			OR
			((@funcion = 'Asistente') AND ((SELECT COUNT(Arbitro) FROM arbitros.Arbitraje WHERE Partido = @partido AND Funcion = 'Asistente') >= 2))
			OR
			((@funcion = 'VAR') AND ((SELECT COUNT(Arbitro) FROM arbitros.Arbitraje WHERE Partido = @partido AND Funcion = 'VAR') >= 1))
			OR
			((@funcion = '4to') AND ((SELECT COUNT(Arbitro) FROM arbitros.Arbitraje WHERE Partido = @partido AND Funcion = '4to') >= 1))
		)
			THROW 50000, '- Cupo excedido para esa funcion.', 1;

		--chequeo nacionalidad(para este partido)
		IF EXISTS
		(
			SELECT 1
			FROM
			(
				SELECT IdPais
				FROM equipos.Seleccion
				WHERE IdSeleccion 
				IN (SELECT Eq1 FROM partidos.Partido WHERE IdPartido = @partido UNION SELECT Eq2 FROM partidos.Partido WHERE IdPartido = @partido)
			) AS P
			WHERE P.IdPais = (SELECT Pais FROM equipos.Persona WHERE IdPersona = @arbitro)
		)
			THROW 50000, '- No se puede asignar este arbitro, el pais al que pertenece disputa este partido.', 1;

		-- Aviso preventivo: el fixture no guarda las llaves de eliminacion.
		IF EXISTS (
			SELECT 1 FROM partidos.Partido Actual
			JOIN partidos.Fase FA ON FA.IdFase = Actual.IdFase
			JOIN partidos.Partido Otro ON Otro.IdMundial = Actual.IdMundial AND Otro.IdPartido <> Actual.IdPartido
			JOIN partidos.Fase FO ON FO.IdFase = Otro.IdFase
			JOIN equipos.Seleccion S ON S.IdSeleccion IN (Otro.Eq1, Otro.Eq2)
			JOIN equipos.Persona A ON A.Pais = S.IdPais AND A.IdPersona = @arbitro
			WHERE Actual.IdPartido = @partido
			AND FA.Descripcion IN ('Dieciseisavos', 'Octavos', 'Cuartos', 'Semifinal')
			AND FO.Descripcion IN ('Dieciseisavos', 'Octavos', 'Cuartos', 'Semifinal', 'Final')
			AND (Otro.Fecha > Actual.Fecha OR (Otro.Fecha = Actual.Fecha AND Otro.HoraUTC >= Actual.HoraUTC))
		)
			PRINT '-ADVERTENCIA- La seleccion del pais del arbitro tiene otro partido eliminatorio programado en este mundial. Revisar posibles cruces.';

		BEGIN TRANSACTION
			INSERT INTO arbitros.Arbitraje
			VALUES (@arbitro, @funcion, @partido)

			COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspArbitraje_Update'))
    DROP PROCEDURE SPTRANS.uspArbitraje_Update
GO
CREATE PROCEDURE SPTRANS.uspArbitraje_Update 
@arbitro INT,
@funcion VARCHAR(20),
@partido INT
AS
BEGIN
	BEGIN TRY
		--Chequeo validez
		IF(@arbitro IS NULL) OR (@arbitro <= 0)
			THROW 50000, '- Valor invalido: ID Arbitro.', 1;

		IF(@funcion IS NULL) OR (@funcion NOT IN ('Principal', 'Asistente', '4to', 'VAR'))
			THROW 50000, '- Valor invalido: Funcion.', 1;

		IF(@partido IS NULL) OR (@partido <= 0)
			THROW 50000, '- Valor invalido: ID Partido.', 1;

		--chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM arbitros.Arbitraje WHERE Arbitro = @arbitro AND Partido = @partido)
			THROW 50000, '- Registro inexistente.', 1;

		--chequeo dup
		IF EXISTS(SELECT 1 FROM arbitros.Arbitraje WHERE Arbitro = @arbitro AND Partido = @partido AND Funcion = @funcion)
			THROW 50000, '- Valor duplicado: Arbitro. Se encuentra ya asignado a esa funcion.', 1;

		--chequeo cupo (se excluye el propio registro para no contarse a si mismo)
		IF(
			((@funcion = 'Principal') AND ((SELECT COUNT(Arbitro) FROM arbitros.Arbitraje WHERE Partido = @partido AND Funcion = 'Principal' AND Arbitro <> @arbitro) >= 1))
			OR
			((@funcion = 'Asistente') AND ((SELECT COUNT(Arbitro) FROM arbitros.Arbitraje WHERE Partido = @partido AND Funcion = 'Asistente' AND Arbitro <> @arbitro) >= 2))
			OR
			((@funcion = 'VAR') AND ((SELECT COUNT(Arbitro) FROM arbitros.Arbitraje WHERE Partido = @partido AND Funcion = 'VAR' AND Arbitro <> @arbitro) >= 1))
			OR
			((@funcion = '4to') AND ((SELECT COUNT(Arbitro) FROM arbitros.Arbitraje WHERE Partido = @partido AND Funcion = '4to' AND Arbitro <> @arbitro) >= 1))
		)
			THROW 50000, '- Cupo excedido para esa funcion.', 1;

		IF EXISTS (SELECT 1 FROM partidos.Partido P
			JOIN equipos.Seleccion S ON S.IdSeleccion IN (P.Eq1, P.Eq2)
			JOIN equipos.Persona A ON A.Pais = S.IdPais AND A.IdPersona = @arbitro
			WHERE P.IdPartido = @partido)
			THROW 50000, '- No se puede asignar este arbitro, el pais al que pertenece disputa este partido.', 1;
		-- Aviso preventivo: el fixture no guarda las llaves de eliminacion.
		IF EXISTS (
			SELECT 1 FROM partidos.Partido Actual
			JOIN partidos.Fase FA ON FA.IdFase = Actual.IdFase
			JOIN partidos.Partido Otro ON Otro.IdMundial = Actual.IdMundial AND Otro.IdPartido <> Actual.IdPartido
			JOIN partidos.Fase FO ON FO.IdFase = Otro.IdFase
			JOIN equipos.Seleccion S ON S.IdSeleccion IN (Otro.Eq1, Otro.Eq2)
			JOIN equipos.Persona A ON A.Pais = S.IdPais AND A.IdPersona = @arbitro
			WHERE Actual.IdPartido = @partido
			AND FA.Descripcion IN ('Dieciseisavos', 'Octavos', 'Cuartos', 'Semifinal')
			AND FO.Descripcion IN ('Dieciseisavos', 'Octavos', 'Cuartos', 'Semifinal', 'Final')
			AND (Otro.Fecha > Actual.Fecha OR (Otro.Fecha = Actual.Fecha AND Otro.HoraUTC >= Actual.HoraUTC))
		)
			PRINT '-ADVERTENCIA- La seleccion del pais del arbitro tiene otro partido eliminatorio programado en este mundial. Revisar posibles cruces.';

		BEGIN TRANSACTION
			UPDATE arbitros.Arbitraje
			SET Funcion = @funcion
			WHERE Arbitro = @arbitro AND Partido = @partido

			COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspArbitraje_Bajar'))
    DROP PROCEDURE SPTRANS.uspArbitraje_Bajar
GO
CREATE PROCEDURE SPTRANS.uspArbitraje_Bajar 
@arbitro INT,
@partido INT
AS
BEGIN
	BEGIN TRY
		--Chequeo validez
		IF(@arbitro IS NULL) OR (@arbitro <= 0)
			THROW 50000, '- Valor invalido: ID Arbitro.', 1;

		IF(@partido IS NULL) OR (@partido <= 0)
			THROW 50000, '- Valor invalido: ID Partido.', 1;

		--chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM arbitros.Arbitraje WHERE Arbitro = @arbitro AND Partido = @partido)
			THROW 50000, '- Registro inexistente.', 1;

		BEGIN TRANSACTION
			DELETE FROM arbitros.Arbitraje
			WHERE Arbitro = @arbitro AND Partido = @partido

			COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END
GO