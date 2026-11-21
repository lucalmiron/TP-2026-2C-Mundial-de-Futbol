--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 28/10/26 (ajuste de ventanas: 21/11/26)

--Objetivo: Gestionar Tabla Sustitucion

-- Ajuste: soporte de Descanso y orden por minuto/periodo.
-- Ajuste 21/11: las ventanas de cambios se cuentan agrupando minutos cercanos
--   del mismo periodo (una pausa real se registra en minutos consecutivos),
--   el suplementario no consume ventanas y admite un cambio adicional.
-- Ajuste 21/11 (2): parametro opcional @ignorarVentanas (default 0). La importacion
--   lo usa en 1 porque las pausas de hidratacion no cuentan como ventana y la
--   fuente no permite identificarlas.
-- Ejecutar en la base seleccionada por el instalador.
--USE MUNDIAL
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
@motivo INT,
-- 1 = no controla el tope de ventanas (uso exclusivo de la importacion historica:
-- la fuente no permite distinguir las pausas de hidratacion, que no cuentan como ventana).
-- Por defecto 0: el alta manual sigue controlando el tope.
@ignorarVentanas BIT = 0
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	DECLARE @vSeleccion INT
	DECLARE @vIdMundial INT
	DECLARE @vCambios INT
	DECLARE @vVentanas INT
	DECLARE @vMaxCambios INT
	DECLARE @vMaxVentanas INT

	-- Dos cambios cuyos minutos distan hasta este valor pertenecen a la misma ventana.
	DECLARE @vUmbralMin INT = 2;
	-- 1 si el periodo es el suplementario (Inicio >= 90 y no es la tanda de penales).
	DECLARE @vSuplementario BIT = 0;

	DECLARE @vDescanso BIT = 0;
	DECLARE @vMomento BIGINT = partidos.fnMomentoEvento(@minuto,@periodo);
	SELECT @vDescanso = CASE WHEN Descripcion='Descanso' THEN 1 ELSE 0 END,
	       @vSuplementario = CASE WHEN Inicio >= 90 AND EsPenales = 0 THEN 1 ELSE 0 END
	FROM partidos.Periodo WHERE IdPeriodo=@periodo;

	BEGIN TRY
		IF (@minuto IS NULL) OR (@minuto < 0)
			SET @errores += '- Valor invalido: Minuto.' + N' ';

		IF (@partido IS NULL) OR (@partido <= 0)
			SET @errores += '- Valor invalido: Partido.' + N' ';

		IF (@periodo IS NULL) OR (@periodo <= 0)
			SET @errores += '- Valor invalido: Periodo.' + N' ';

		IF (@ingreso IS NULL) OR (@ingreso <= 0)
			SET @errores += '- Valor invalido: Ingreso.' + N' ';

		IF (@egreso IS NULL) OR (@egreso <= 0)
			SET @errores += '- Valor invalido: Egreso.' + N' ';

		IF (@motivo IS NULL) OR (@motivo <= 0)
			SET @errores += '- Valor invalido: Motivo.' + N' ';

		IF (@ingreso = @egreso)
			SET @errores += '- Ingreso y egreso no pueden ser el mismo jugador.' + N' ';

		IF NOT EXISTS (SELECT 1 FROM partidos.Partido WHERE IdPartido = @partido)
			SET @errores += '- Valor inexistente: Partido.' + N' ';

		IF NOT EXISTS (SELECT 1 FROM partidos.Periodo WHERE IdPeriodo = @periodo)
			SET @errores += '- Valor inexistente: Periodo.' + N' ';

        IF EXISTS (SELECT 1 FROM partidos.Periodo WHERE IdPeriodo=@periodo AND EsPenales=1)
            SET @errores += N'- No se permiten sustituciones mediante este SP durante la tanda de penales. ';

        IF EXISTS (SELECT 1 FROM partidos.Periodo WHERE IdPeriodo=@periodo
                   AND (@minuto<Inicio OR @minuto>Fin))
            SET @errores += N'- El minuto esta fuera del rango del periodo indicado. ';

		IF NOT EXISTS (SELECT 1 FROM equipos.Jugador WHERE IdJugador = @ingreso)
			SET @errores += '- Valor inexistente: Ingreso.' + N' ';

		IF NOT EXISTS (SELECT 1 FROM equipos.Jugador WHERE IdJugador = @egreso)
			SET @errores += '- Valor inexistente: Egreso.' + N' ';

		IF NOT EXISTS (SELECT 1 FROM publicidad.Motivo WHERE IdMotivo = @motivo)
			SET @errores += '- Valor inexistente: Motivo.' + N' ';

		SET @vSeleccion = (SELECT Seleccion FROM equipos.Jugador WHERE IdJugador = @egreso)

		IF (SELECT Seleccion FROM equipos.Jugador WHERE IdJugador = @ingreso) <> @vSeleccion
			SET @errores += '- Ingreso y egreso deben ser de la misma seleccion.' + N' ';

		IF NOT EXISTS (SELECT 1 FROM partidos.Partido WHERE IdPartido = @partido AND (Eq1 = @vSeleccion OR Eq2 = @vSeleccion))
			SET @errores += '- La seleccion no juega este partido.' + N' ';

		IF partidos.fnJugadorEnCanchaPeriodo(@partido,@egreso,@minuto,@periodo)=0
			SET @errores += '- El egreso no estaba en cancha.' + N' ';

		IF NOT EXISTS (SELECT 1 FROM partidos.Alineacion WHERE IdPartido = @partido AND IdJugador = @ingreso AND Rol = 'Suplente')
			SET @errores += '- El ingreso no estaba en el banco.' + N' ';

		IF EXISTS (SELECT 1 FROM partidos.Sustitucion S JOIN partidos.Evento E ON E.IdEvento=S.IdSustitucion
			WHERE E.Partido=@partido AND (S.Ingreso=@ingreso OR S.Egreso=@ingreso OR S.Egreso=@egreso))
			SET @errores += '- El ingreso ya participo o el egreso ya fue reemplazado.' + N' ';

		IF EXISTS (SELECT 1 FROM partidos.Amonestacion A JOIN partidos.Evento E ON E.IdEvento=A.IdAmonestacion
			WHERE E.Partido=@partido AND A.Amonestado=@ingreso AND A.Tarjeta='Roja' AND partidos.fnMomentoEvento(E.Minuto,E.Periodo)<=@vMomento)
			SET @errores += '- No puede ingresar un jugador expulsado.' + N' ';

		-- Los cambios se cargan antes de los eventos posteriores del partido.
		IF EXISTS (SELECT 1 FROM partidos.Evento WHERE Partido=@partido AND partidos.fnMomentoEvento(Minuto,Periodo)>@vMomento)
			SET @errores += '- Registrar los cambios en orden de minuto y periodo, antes de los eventos posteriores.' + N' ';

		SELECT @vIdMundial = IdMundial FROM partidos.Partido WHERE IdPartido = @partido

		SELECT @vMaxCambios = CAMBIOS_CANTIDAD, @vMaxVentanas = CAMBIOS_VENTANAS FROM sedes.Mundial WHERE IdMundial = @vIdMundial

		SELECT @vCambios = COUNT(*) FROM partidos.Sustitucion S INNER JOIN partidos.Evento E ON S.IdSustitucion = E.IdEvento INNER JOIN equipos.Jugador J ON S.Egreso = J.IdJugador WHERE E.Partido = @partido AND J.Seleccion = @vSeleccion

        -- Ventanas: se agrupan los minutos de cambios del equipo (mas el del cambio
        -- que se esta registrando). Un minuto abre una ventana nueva si cambia el
        -- periodo o si dista mas de @vUmbralMin minutos del cambio anterior.
        -- El descanso y el suplementario no consumen ventanas.
        ;WITH M AS (
            SELECT E.Periodo, E.Minuto
            FROM partidos.Sustitucion S
            JOIN partidos.Evento E ON S.IdSustitucion=E.IdEvento
            JOIN equipos.Jugador J ON S.Egreso=J.IdJugador
            JOIN partidos.Periodo P ON P.IdPeriodo=E.Periodo
            WHERE E.Partido=@partido AND J.Seleccion=@vSeleccion
              AND P.Descripcion<>'Descanso' AND P.EsPenales=0 AND P.Inicio<90
            UNION
            SELECT @periodo, @minuto
            WHERE @vDescanso=0 AND @vSuplementario=0
        ), G AS (
            SELECT Periodo, Minuto,
                   CASE WHEN Periodo = LAG(Periodo) OVER (ORDER BY Periodo, Minuto)
                         AND Minuto - LAG(Minuto) OVER (ORDER BY Periodo, Minuto) <= @vUmbralMin
                        THEN 0 ELSE 1 END AS Nueva
            FROM M
        )
        SELECT @vVentanas = ISNULL(SUM(Nueva), 0) FROM G;

        -- En el suplementario el reglamento permite un cambio adicional.
		IF (@vCambios + 1) > (@vMaxCambios + CASE WHEN @vSuplementario = 1 THEN 1 ELSE 0 END)
			SET @errores += '- Tope de cambios del reglamento excedido.' + N' ';

		IF @ignorarVentanas = 0 AND @vDescanso = 0 AND @vSuplementario = 0 AND @vVentanas > @vMaxVentanas
			SET @errores += '- Tope de ventanas del reglamento excedido.' + N' ';

		DECLARE @idEvento INT

		BEGIN TRANSACTION

		IF LEN(@errores)>0 THROW 50000, @errores, 1;
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
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF (@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Sustitucion.' + N' ';

		IF NOT EXISTS (SELECT 1 FROM partidos.Sustitucion WHERE IdSustitucion = @id)
			SET @errores += '- Registro inexistente.' + N' ';

		BEGIN TRANSACTION

		IF LEN(@errores)>0 THROW 50000, @errores, 1;
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