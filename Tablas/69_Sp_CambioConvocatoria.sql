--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 25/10/26

--Objetivo: Gestionar Tabla CambioConvocatoria

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspCambioConvocatoria_Registrar'))
    DROP PROCEDURE SPTRANS.uspCambioConvocatoria_Registrar
GO
CREATE PROCEDURE SPTRANS.uspCambioConvocatoria_Registrar
@seleccion INT,
@egreso INT,
@ingreso INT,
@fecha DATE,
@motivo VARCHAR(200)
AS
BEGIN
	DECLARE @vActivos INT
	DECLARE @vIdMundial INT
	DECLARE @vMin INT
	DECLARE @vMax INT

	BEGIN TRY
		IF (@seleccion IS NULL) OR (@seleccion <= 0)
			THROW 50000, '- Valor invalido: Seleccion.', 1;

		IF (@egreso IS NULL) OR (@egreso <= 0)
			THROW 50000, '- Valor invalido: Egreso.', 1;

		IF (@ingreso IS NULL) OR (@ingreso <= 0)
			THROW 50000, '- Valor invalido: Ingreso.', 1;

		IF (@fecha IS NULL)
			THROW 50000, '- Valor invalido: Fecha.', 1;

		IF (@motivo IS NULL)
			THROW 50000, '- Valor invalido: Motivo.', 1;

		IF (@egreso = @ingreso)
			THROW 50000, '- Egreso e ingreso no pueden ser el mismo jugador.', 1;

		IF NOT EXISTS (SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @seleccion)
			THROW 50000, '- Valor inexistente: Seleccion.', 1;

		IF NOT EXISTS (SELECT 1 FROM equipos.Jugador WHERE IdJugador = @egreso AND Seleccion = @seleccion AND Estado = 'Activo')
			THROW 50000, '- El egreso no es un convocado activo de la seleccion.', 1;

		IF NOT EXISTS (SELECT 1 FROM equipos.Jugador WHERE IdJugador = @ingreso AND Seleccion = @seleccion)
			THROW 50000, '- El ingreso no pertenece a la seleccion.', 1;

		IF EXISTS (SELECT 1 FROM equipos.Jugador WHERE IdJugador = @ingreso AND Estado <> 'Inactivo')
			THROW 50000, '- El ingreso debe ser un jugador inactivo.', 1;

		SELECT @vIdMundial = IdMundial FROM equipos.Seleccion WHERE IdSeleccion = @seleccion

		SELECT @vMin = TAMANIO_SELECCION_MINIMO, @vMax = TAMANIO_SELECCION_MAXIMO FROM sedes.Mundial WHERE IdMundial = @vIdMundial

		SELECT @vActivos = COUNT(*) FROM equipos.Jugador WHERE Seleccion = @seleccion AND Estado <> 'Inactivo'

		IF (@vActivos < @vMin) OR (@vActivos > @vMax)
			THROW 50000, '- La convocatoria incumple el cupo del reglamento.', 1;

		IF EXISTS (SELECT 1 FROM equipos.CambioConvocatoria
			WHERE (Ingreso IN (@ingreso, @egreso) OR Egreso IN (@ingreso, @egreso)) AND Fecha > @fecha)
			THROW 50000, '- Existen cambios de convocatoria posteriores para estos jugadores.', 1;

		IF EXISTS (SELECT 1 FROM partidos.Alineacion A JOIN partidos.Partido P ON P.IdPartido = A.IdPartido
			WHERE A.IdJugador = @egreso AND P.Fecha >= @fecha)
			THROW 50000, '- El egreso tiene alineaciones desde la fecha del cambio.', 1;

		BEGIN TRANSACTION
			UPDATE equipos.Jugador
			SET Estado = 'Inactivo'
			WHERE IdJugador = @egreso

			UPDATE equipos.Jugador
			SET Estado = 'Activo'
			WHERE IdJugador = @ingreso

			INSERT INTO equipos.CambioConvocatoria (Seleccion, Egreso, Ingreso, Fecha, Motivo)
			VALUES (@seleccion, @egreso, @ingreso, @fecha, @motivo)

			COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspCambioConvocatoria_Bajar'))
    DROP PROCEDURE SPTRANS.uspCambioConvocatoria_Bajar
GO
CREATE PROCEDURE SPTRANS.uspCambioConvocatoria_Bajar
@id INT
AS
BEGIN
	DECLARE @vEgreso INT
	DECLARE @vIngreso INT
	DECLARE @vFecha DATE

	BEGIN TRY
		IF (@id IS NULL) OR (@id <= 0)
			THROW 50000, '- Valor invalido: ID Cambio.', 1;

		IF NOT EXISTS (SELECT 1 FROM equipos.CambioConvocatoria WHERE IdCambio = @id)
			THROW 50000, '- Registro inexistente.', 1;

		BEGIN TRANSACTION
			SELECT @vEgreso = Egreso, @vIngreso = Ingreso, @vFecha = Fecha FROM equipos.CambioConvocatoria WHERE IdCambio = @id

			IF EXISTS (SELECT 1 FROM equipos.CambioConvocatoria
				WHERE (Ingreso IN (@vIngreso, @vEgreso) OR Egreso IN (@vIngreso, @vEgreso))
				AND (Fecha > @vFecha OR (Fecha = @vFecha AND IdCambio > @id)))
				THROW 50000, '- Anule primero los cambios de convocatoria posteriores.', 1;

			IF NOT EXISTS (SELECT 1 FROM equipos.Jugador WHERE IdJugador = @vEgreso AND Estado = 'Inactivo')
			OR NOT EXISTS (SELECT 1 FROM equipos.Jugador WHERE IdJugador = @vIngreso AND Estado = 'Activo')
				THROW 50000, '- Los estados actuales no permiten anular el cambio.', 1;

			IF EXISTS (SELECT 1 FROM partidos.Alineacion A JOIN partidos.Partido P ON P.IdPartido = A.IdPartido
				WHERE A.IdJugador = @vIngreso AND P.Fecha >= @vFecha)
				THROW 50000, '- El ingreso tiene alineaciones desde la fecha del cambio.', 1;

			UPDATE equipos.Jugador
			SET Estado = 'Activo'
			WHERE IdJugador = @vEgreso

			UPDATE equipos.Jugador
			SET Estado = 'Inactivo'
			WHERE IdJugador = @vIngreso

			DELETE FROM equipos.CambioConvocatoria
			WHERE IdCambio = @id

			COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END
GO