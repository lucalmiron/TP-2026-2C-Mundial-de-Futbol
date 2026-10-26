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
	DECLARE @errores NVARCHAR(2048) = N'';
	DECLARE @vActivos INT
	DECLARE @vIdMundial INT
	DECLARE @vMin INT
	DECLARE @vMax INT

	BEGIN TRY
		IF (@seleccion IS NULL) OR (@seleccion <= 0)
			SET @errores += '- Valor invalido: Seleccion.' + N' ';

		IF (@egreso IS NULL) OR (@egreso <= 0)
			SET @errores += '- Valor invalido: Egreso.' + N' ';

		IF (@ingreso IS NULL) OR (@ingreso <= 0)
			SET @errores += '- Valor invalido: Ingreso.' + N' ';

		IF (@fecha IS NULL)
			SET @errores += '- Valor invalido: Fecha.' + N' ';

		IF (@motivo IS NULL)
			SET @errores += '- Valor invalido: Motivo.' + N' ';

		IF (@egreso = @ingreso)
			SET @errores += '- Egreso e ingreso no pueden ser el mismo jugador.' + N' ';

		IF NOT EXISTS (SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @seleccion)
			SET @errores += '- Valor inexistente: Seleccion.' + N' ';

		IF NOT EXISTS (SELECT 1 FROM equipos.Jugador WHERE IdJugador = @egreso AND Seleccion = @seleccion AND Estado = 'Activo')
			SET @errores += '- El egreso no es un convocado activo de la seleccion.' + N' ';

		IF NOT EXISTS (SELECT 1 FROM equipos.Jugador WHERE IdJugador = @ingreso AND Seleccion = @seleccion)
			SET @errores += '- El ingreso no pertenece a la seleccion.' + N' ';

		IF EXISTS (SELECT 1 FROM equipos.Jugador WHERE IdJugador = @ingreso AND Estado <> 'Inactivo')
			SET @errores += '- El ingreso debe ser un jugador inactivo.' + N' ';

		SELECT @vIdMundial = IdMundial FROM equipos.Seleccion WHERE IdSeleccion = @seleccion

		SELECT @vMin = TAMANIO_SELECCION_MINIMO, @vMax = TAMANIO_SELECCION_MAXIMO FROM sedes.Mundial WHERE IdMundial = @vIdMundial

		SELECT @vActivos = COUNT(*) FROM equipos.Jugador WHERE Seleccion = @seleccion AND Estado <> 'Inactivo'

		IF (@vActivos < @vMin) OR (@vActivos > @vMax)
			SET @errores += '- La convocatoria incumple el cupo del reglamento.' + N' ';

		IF EXISTS (SELECT 1 FROM equipos.CambioConvocatoria
			WHERE (Ingreso IN (@ingreso, @egreso) OR Egreso IN (@ingreso, @egreso)) AND Fecha > @fecha)
			SET @errores += '- Existen cambios de convocatoria posteriores para estos jugadores.' + N' ';

		IF EXISTS (SELECT 1 FROM partidos.Alineacion A JOIN partidos.Partido P ON P.IdPartido = A.IdPartido
			WHERE A.IdJugador = @egreso AND P.Fecha >= @fecha)
			SET @errores += '- El egreso tiene alineaciones desde la fecha del cambio.' + N' ';

		BEGIN TRANSACTION

		IF LEN(@errores)>0 THROW 50000, @errores, 1;
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
	DECLARE @errores NVARCHAR(2048) = N'';
	DECLARE @vEgreso INT
	DECLARE @vIngreso INT
	DECLARE @vFecha DATE

	BEGIN TRY
		IF (@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Cambio.' + N' ';

		IF NOT EXISTS (SELECT 1 FROM equipos.CambioConvocatoria WHERE IdCambio = @id)
			SET @errores += '- Registro inexistente.' + N' ';

		BEGIN TRANSACTION
			SELECT @vEgreso = Egreso, @vIngreso = Ingreso, @vFecha = Fecha FROM equipos.CambioConvocatoria WHERE IdCambio = @id

			IF EXISTS (SELECT 1 FROM equipos.CambioConvocatoria
				WHERE (Ingreso IN (@vIngreso, @vEgreso) OR Egreso IN (@vIngreso, @vEgreso))
				AND (Fecha > @vFecha OR (Fecha = @vFecha AND IdCambio > @id)))
				SET @errores += '- Anule primero los cambios de convocatoria posteriores.' + N' ';

			IF NOT EXISTS (SELECT 1 FROM equipos.Jugador WHERE IdJugador = @vEgreso AND Estado = 'Inactivo')
			OR NOT EXISTS (SELECT 1 FROM equipos.Jugador WHERE IdJugador = @vIngreso AND Estado = 'Activo')
				SET @errores += '- Los estados actuales no permiten anular el cambio.' + N' ';

			IF EXISTS (SELECT 1 FROM partidos.Alineacion A JOIN partidos.Partido P ON P.IdPartido = A.IdPartido
				WHERE A.IdJugador = @vIngreso AND P.Fecha >= @vFecha)
				SET @errores += '- El ingreso tiene alineaciones desde la fecha del cambio.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

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