--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 08/10/2026

--Objetivo: Gestionar Tabla Sustitucion

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspSustitucion_Registrar'))
    DROP PROCEDURE SPTRANS.uspSustitucion_Registrar
GO
CREATE PROCEDURE SPTRANS.uspSustitucion_Registrar
@minuto INT,
@partido INT,
@periodo INT,
@ingreso INT,
@egreso INT,
@motivo INT
AS
BEGIN
	DECLARE @vSeleccion INT
	DECLARE @vIdMundial INT
	DECLARE @vCambios INT
	DECLARE @vVentanas INT
	DECLARE @vMaxCambios INT
	DECLARE @vMaxVentanas INT

	BEGIN TRY
		IF (@minuto IS NULL) OR (@minuto < 0)
			THROW 50000, '- Valor invalido: Minuto.', 1;

		IF (@partido IS NULL) OR (@partido <= 0)
			THROW 50000, '- Valor invalido: Partido.', 1;

		IF (@periodo IS NULL) OR (@periodo <= 0)
			THROW 50000, '- Valor invalido: Periodo.', 1;

		IF (@ingreso IS NULL) OR (@ingreso <= 0)
			THROW 50000, '- Valor invalido: Ingreso.', 1;

		IF (@egreso IS NULL) OR (@egreso <= 0)
			THROW 50000, '- Valor invalido: Egreso.', 1;

		IF (@motivo IS NULL) OR (@motivo <= 0)
			THROW 50000, '- Valor invalido: Motivo.', 1;

		IF (@ingreso = @egreso)
			THROW 50000, '- Ingreso y egreso no pueden ser el mismo jugador.', 1;

		IF NOT EXISTS (SELECT 1 FROM partidos.Partido WHERE IdPartido = @partido)
			THROW 50000, '- Valor inexistente: Partido.', 1;

		IF NOT EXISTS (SELECT 1 FROM partidos.Periodo WHERE IdPeriodo = @periodo)
			THROW 50000, '- Valor inexistente: Periodo.', 1;

		IF NOT EXISTS (SELECT 1 FROM equipos.Jugador WHERE IdJugador = @ingreso)
			THROW 50000, '- Valor inexistente: Ingreso.', 1;

		IF NOT EXISTS (SELECT 1 FROM equipos.Jugador WHERE IdJugador = @egreso)
			THROW 50000, '- Valor inexistente: Egreso.', 1;

		IF NOT EXISTS (SELECT 1 FROM publicidad.Motivo WHERE IdMotivo = @motivo)
			THROW 50000, '- Valor inexistente: Motivo.', 1;

		SET @vSeleccion = (SELECT Seleccion FROM equipos.Jugador WHERE IdJugador = @egreso)

		IF (SELECT Seleccion FROM equipos.Jugador WHERE IdJugador = @ingreso) <> @vSeleccion
			THROW 50000, '- Ingreso y egreso deben ser de la misma seleccion.', 1;

		IF NOT EXISTS (SELECT 1 FROM partidos.Partido WHERE IdPartido = @partido AND (Eq1 = @vSeleccion OR Eq2 = @vSeleccion))
			THROW 50000, '- La seleccion no juega este partido.', 1;

		IF partidos.fnJugadorEnCancha(@partido,@egreso,@minuto)=0
			THROW 50000, '- El egreso no estaba en cancha.', 1;

		IF NOT EXISTS (SELECT 1 FROM partidos.Alineacion WHERE IdPartido = @partido AND IdJugador = @ingreso AND Rol = 'Suplente')
			THROW 50000, '- El ingreso no estaba en el banco.', 1;

		IF EXISTS (SELECT 1 FROM partidos.Sustitucion S JOIN partidos.Evento E ON E.IdEvento=S.IdSustitucion
			WHERE E.Partido=@partido AND (S.Ingreso=@ingreso OR S.Egreso=@ingreso OR S.Egreso=@egreso))
			THROW 50000, '- El ingreso ya participo o el egreso ya fue reemplazado.', 1;

		IF EXISTS (SELECT 1 FROM partidos.Amonestacion A JOIN partidos.Evento E ON E.IdEvento=A.IdAmonestacion
			WHERE E.Partido=@partido AND A.Amonestado=@ingreso AND A.Tarjeta='Roja' AND E.Minuto<=@minuto)
			THROW 50000, '- No puede ingresar un jugador expulsado.', 1;

		-- Los cambios se cargan antes de los eventos posteriores del partido.
		IF EXISTS (SELECT 1 FROM partidos.Evento WHERE Partido=@partido AND Minuto>@minuto)
			THROW 50000, '- Registrar los cambios en orden de minuto, antes de los eventos posteriores.', 1;

		SELECT @vIdMundial = IdMundial FROM partidos.Partido WHERE IdPartido = @partido

		SELECT @vMaxCambios = CAMBIOS_CANTIDAD, @vMaxVentanas = CAMBIOS_VENTANAS FROM sedes.Mundial WHERE IdMundial = @vIdMundial

		SELECT @vCambios = COUNT(*) FROM partidos.Sustitucion S INNER JOIN partidos.Evento E ON S.IdSustitucion = E.IdEvento INNER JOIN equipos.Jugador J ON S.Egreso = J.IdJugador WHERE E.Partido = @partido AND J.Seleccion = @vSeleccion

		SELECT @vVentanas = COUNT(DISTINCT E.Minuto) FROM partidos.Sustitucion S INNER JOIN partidos.Evento E ON S.IdSustitucion = E.IdEvento INNER JOIN equipos.Jugador J ON S.Egreso = J.IdJugador WHERE E.Partido = @partido AND J.Seleccion = @vSeleccion

		IF (@vCambios + 1) > @vMaxCambios
			THROW 50000, '- Tope de cambios del reglamento excedido.', 1;

		IF NOT EXISTS (SELECT 1 FROM partidos.Sustitucion S INNER JOIN partidos.Evento E ON S.IdSustitucion = E.IdEvento INNER JOIN equipos.Jugador J ON S.Egreso = J.IdJugador WHERE E.Partido = @partido AND J.Seleccion = @vSeleccion AND E.Minuto = @minuto)
		AND (@vVentanas + 1) > @vMaxVentanas
			THROW 50000, '- Tope de ventanas del reglamento excedido.', 1;

		DECLARE @idEvento INT

		BEGIN TRANSACTION
			INSERT INTO partidos.Evento (Minuto, Tipo, Partido, Periodo)
			VALUES (@minuto, 'Sustitucion', @partido, @periodo)

			SET @idEvento = SCOPE_IDENTITY()

			INSERT INTO partidos.Sustitucion (IdSustitucion, Ingreso, Egreso, Motivo)
			VALUES (@idEvento, @ingreso, @egreso, @motivo)

			COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspSustitucion_Bajar'))
    DROP PROCEDURE SPTRANS.uspSustitucion_Bajar
GO
CREATE PROCEDURE SPTRANS.uspSustitucion_Bajar
@id INT
AS
BEGIN
	BEGIN TRY
		IF (@id IS NULL) OR (@id <= 0)
			THROW 50000, '- Valor invalido: ID Sustitucion.', 1;

		IF NOT EXISTS (SELECT 1 FROM partidos.Sustitucion WHERE IdSustitucion = @id)
			THROW 50000, '- Registro inexistente.', 1;

		BEGIN TRANSACTION
			DELETE FROM partidos.Sustitucion
			WHERE IdSustitucion = @id

			DELETE FROM partidos.Evento
			WHERE IdEvento = @id

			COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END
GO