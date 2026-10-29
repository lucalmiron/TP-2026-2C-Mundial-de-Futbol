-- Universidad Nacional de La Matanza
-- Bases de datos aplicada 
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 28/10/26
-- Objetivo: Registrar y Eliminar Alineacion

-- Ajuste: soporte de Descanso y orden por minuto/periodo.
-- Ejecutar en la base seleccionada por el instalador.
GO

-- Orden temporal: distingue 45 del primer tiempo, descanso y segundo tiempo.
-- Los nombres corresponden al catalogo de Periodo. No representa descuento.
CREATE OR ALTER FUNCTION partidos.fnMomentoEvento(@minuto INT, @periodo INT)
RETURNS BIGINT
AS
BEGIN
    DECLARE @orden INT = 0;
    IF @periodo IS NULL
        SET @orden = 9; -- Consulta antigua: incluye todo lo registrado en ese minuto.
    ELSE
        SELECT @orden = CASE
            WHEN EsPenales = 1 THEN 5
            WHEN Descripcion = 'Descanso' THEN 1
            WHEN Descripcion = '2do tiempo' THEN 2
            WHEN Descripcion = 'Alargue 1' THEN 3
            WHEN Descripcion = 'Alargue 2' THEN 4
            ELSE 0 END
        FROM partidos.Periodo WHERE IdPeriodo = @periodo;
    RETURN CONVERT(BIGINT, COALESCE(@minuto, 2147483647)) * 10 + @orden;
END;
GO

-- Consulta precisa: los eventos ya registrados en el mismo momento se aplican.
CREATE OR ALTER FUNCTION partidos.fnJugadorEnCanchaPeriodo
(@partido INT, @jugador INT, @minuto INT, @periodo INT)
RETURNS BIT
AS
BEGIN
    DECLARE @momento BIGINT = partidos.fnMomentoEvento(@minuto, @periodo);
    IF NOT EXISTS (SELECT 1 FROM partidos.Alineacion WHERE IdPartido=@partido AND IdJugador=@jugador)
        RETURN 0;
    IF NOT EXISTS (SELECT 1 FROM partidos.Alineacion WHERE IdPartido=@partido AND IdJugador=@jugador AND Rol='Titular')
       AND NOT EXISTS (SELECT 1 FROM partidos.Sustitucion S JOIN partidos.Evento E ON E.IdEvento=S.IdSustitucion
                       WHERE E.Partido=@partido AND S.Ingreso=@jugador
                         AND partidos.fnMomentoEvento(E.Minuto,E.Periodo)<=@momento)
        RETURN 0;
    IF EXISTS (SELECT 1 FROM partidos.Sustitucion S JOIN partidos.Evento E ON E.IdEvento=S.IdSustitucion
               WHERE E.Partido=@partido AND S.Egreso=@jugador
                 AND partidos.fnMomentoEvento(E.Minuto,E.Periodo)<=@momento)
        RETURN 0;
    IF EXISTS (SELECT 1 FROM partidos.Amonestacion A JOIN partidos.Evento E ON E.IdEvento=A.IdAmonestacion
               WHERE E.Partido=@partido AND A.Amonestado=@jugador AND A.Tarjeta='Roja'
                 AND partidos.fnMomentoEvento(E.Minuto,E.Periodo)<=@momento)
        RETURN 0;
    RETURN 1;
END;
GO

-- Conserva la firma y semantica de las consultas anteriores.
-- Para distinguir periodos en un minuto compartido usar la funcion de 4 parametros.
CREATE OR ALTER FUNCTION partidos.fnJugadorEnCancha(@partido INT, @jugador INT, @minuto INT)
RETURNS BIT
AS
BEGIN
    RETURN partidos.fnJugadorEnCanchaPeriodo(@partido, @jugador, @minuto, NULL);
END;
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID ('SP.uspAlineacion_Registrar'))
	DROP PROCEDURE SP.uspAlineacion_Registrar
GO

CREATE PROCEDURE SP.uspAlineacion_Registrar 
@IdPartido INT, @IdJugador INT,
@Rol VARCHAR (10), @PosicionCancha VARCHAR(20) = NULL, @Esquema VARCHAR (10) = NULL
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF (@IdPartido IS NULL OR @IdPartido <=0)
			SET @errores += '-Valor Invalido: IdPartido' + N' ';

		IF (@IdJugador IS NULL OR @IdJugador <=0)
			SET @errores += '-Valor Invalido: IdJugador' + N' ';

		IF (@Rol IS NULL)
			SET @errores += '-Valor Invalido: Rol nulo' + N' ';

		IF (@ROL NOT IN ('Suplente', 'Titular'))
			SET @errores += '-Valor Invalido: Rol' + N' ';

		IF NOT EXISTS(SELECT 1 FROM partidos.Partido WHERE IdPartido = @IdPartido)
			SET @errores += '- Valor inexistente: Partido' + N' ';

		IF NOT EXISTS(SELECT 1 FROM equipos.Jugador WHERE IdJugador = @IdJugador)
			SET @errores += '- Valor inexistente: Jugador' + N' ';

		IF NOT EXISTS(SELECT 1 FROM partidos.Partido P
				INNER JOIN equipos.Jugador J ON J.IdJugador = @IdJugador
				WHERE P.IdPartido = @IdPartido AND (P.Eq1 = J.Seleccion OR P.Eq2 = J.Seleccion))
			SET @errores += '- La seleccion del jugador no juega este partido' + N' ';

		IF EXISTS (SELECT 1 FROM partidos.Alineacion WHERE IdJugador = @IdJugador AND IdPartido = @IdPartido)
			SET @errores += '- Jugador ya cargado' + N' ';

		IF EXISTS (SELECT 1 FROM equipos.Jugador WHERE IdJugador=@IdJugador AND Estado<>'Activo')
			SET @errores += '- El jugador no esta habilitado para integrar la alineacion.' + N' ';

		IF @Rol='Titular' AND (SELECT COUNT(*) FROM partidos.Alineacion A
			JOIN equipos.Jugador J ON J.IdJugador=A.IdJugador
			WHERE A.IdPartido=@IdPartido AND A.Rol='Titular'
			AND J.Seleccion=(SELECT Seleccion FROM equipos.Jugador WHERE IdJugador=@IdJugador)) >= 11
			SET @errores += '- La seleccion ya tiene once titulares.' + N' ';

		IF @Esquema IS NOT NULL AND EXISTS (SELECT 1 FROM partidos.Alineacion A
			JOIN equipos.Jugador J ON J.IdJugador=A.IdJugador
			WHERE A.IdPartido=@IdPartido AND A.Esquema<>@Esquema
			AND J.Seleccion=(SELECT Seleccion FROM equipos.Jugador WHERE IdJugador=@IdJugador))
			SET @errores += '- El esquema debe coincidir con el de la seleccion en el partido.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		INSERT INTO partidos.Alineacion (IdPartido, IdJugador, Rol, PosicionCancha, Esquema) 
		VALUES (@IdPartido, @IdJugador, @Rol, @PosicionCancha, @Esquema) 
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO 

---------------------------------------------------------------------------------------------------------------

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID ('SP.uspAlineacion_Bajar'))
	DROP PROCEDURE SP.uspAlineacion_Bajar
GO

CREATE PROCEDURE SP.uspAlineacion_Bajar
@IdPartido INT, @IdJugador INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF (@IdPartido IS NULL OR @IdPartido <=0)
			SET @errores += '-Valor Invalido: IdPartido' + N' ';

		IF (@IdJugador IS NULL OR @IdJugador <=0)
			SET @errores += '-Valor Invalido: IdJugador' + N' ';

		IF NOT EXISTS (SELECT 1 FROM partidos.Alineacion WHERE IdJugador = @IdJugador AND IdPartido = @IdPartido)
			SET @errores += '-No existe alineacion a eliminar' + N' ';

		IF EXISTS(SELECT 1 FROM partidos.Evento WHERE Partido = @IdPartido)
			SET @errores += '-Tabla siendo utilizada en Evento, no se puede eliminar' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		DELETE FROM partidos.Alineacion WHERE IdJugador = @IdJugador AND IdPartido = @IdPartido
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO