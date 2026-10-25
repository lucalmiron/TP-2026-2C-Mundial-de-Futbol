-- Universidad Nacional de La Matanza
-- Bases de datos aplicada 
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 08/10/2026
-- Objetivo: Registrar y Eliminar Alineacion

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

-- Consulta si el jugador sigue en cancha en el minuto indicado.
-- En un mismo minuto se consideran los cambios y expulsiones ya registrados.
CREATE OR ALTER FUNCTION partidos.fnJugadorEnCancha(@partido INT, @jugador INT, @minuto INT)
RETURNS BIT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM partidos.Alineacion WHERE IdPartido=@partido AND IdJugador=@jugador)
        RETURN 0;
    IF NOT EXISTS (SELECT 1 FROM partidos.Alineacion WHERE IdPartido=@partido AND IdJugador=@jugador AND Rol='Titular')
       AND NOT EXISTS (SELECT 1 FROM partidos.Sustitucion S JOIN partidos.Evento E ON E.IdEvento=S.IdSustitucion
                       WHERE E.Partido=@partido AND S.Ingreso=@jugador AND E.Minuto<=@minuto)
        RETURN 0;
    IF EXISTS (SELECT 1 FROM partidos.Sustitucion S JOIN partidos.Evento E ON E.IdEvento=S.IdSustitucion
               WHERE E.Partido=@partido AND S.Egreso=@jugador AND E.Minuto<=@minuto)
        RETURN 0;
    IF EXISTS (SELECT 1 FROM partidos.Amonestacion A JOIN partidos.Evento E ON E.IdEvento=A.IdAmonestacion
               WHERE E.Partido=@partido AND A.Amonestado=@jugador AND A.Tarjeta='Roja'
                 AND (E.Minuto<=@minuto OR (E.Minuto IS NULL AND @minuto=2147483647)))
        RETURN 0;
    RETURN 1;
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
	BEGIN TRY
		IF (@IdPartido IS NULL OR @IdPartido <=0)
			THROW 50000, '-Valor Invalido: IdPartido', 1;

		IF (@IdJugador IS NULL OR @IdJugador <=0)
			THROW 50000, '-Valor Invalido: IdJugador', 1;

		IF (@Rol IS NULL)
			THROW 50000, '-Valor Invalido: Rol nulo', 1;

		IF (@ROL NOT IN ('Suplente', 'Titular'))
			THROW 50000, '-Valor Invalido: Rol', 1;

		IF NOT EXISTS(SELECT 1 FROM partidos.Partido WHERE IdPartido = @IdPartido)
			THROW 50000, '- Valor inexistente: Partido', 1;

		IF NOT EXISTS(SELECT 1 FROM equipos.Jugador WHERE IdJugador = @IdJugador)
			THROW 50000, '- Valor inexistente: Jugador', 1;

		IF NOT EXISTS(SELECT 1 FROM partidos.Partido P
				INNER JOIN equipos.Jugador J ON J.IdJugador = @IdJugador
				WHERE P.IdPartido = @IdPartido AND (P.Eq1 = J.Seleccion OR P.Eq2 = J.Seleccion))
			THROW 50000, '- La seleccion del jugador no juega este partido', 1;

		IF EXISTS (SELECT 1 FROM partidos.Alineacion WHERE IdJugador = @IdJugador AND IdPartido = @IdPartido)
			THROW 50000, '- Jugador ya cargado', 1;

		IF EXISTS (SELECT 1 FROM equipos.Jugador WHERE IdJugador=@IdJugador AND Estado<>'Activo')
			THROW 50000, '- El jugador no esta habilitado para integrar la alineacion.', 1;

		IF @Rol='Titular' AND (SELECT COUNT(*) FROM partidos.Alineacion A
			JOIN equipos.Jugador J ON J.IdJugador=A.IdJugador
			WHERE A.IdPartido=@IdPartido AND A.Rol='Titular'
			AND J.Seleccion=(SELECT Seleccion FROM equipos.Jugador WHERE IdJugador=@IdJugador)) >= 11
			THROW 50000, '- La seleccion ya tiene once titulares.', 1;

		IF @Esquema IS NOT NULL AND EXISTS (SELECT 1 FROM partidos.Alineacion A
			JOIN equipos.Jugador J ON J.IdJugador=A.IdJugador
			WHERE A.IdPartido=@IdPartido AND A.Esquema<>@Esquema
			AND J.Seleccion=(SELECT Seleccion FROM equipos.Jugador WHERE IdJugador=@IdJugador))
			THROW 50000, '- El esquema debe coincidir con el de la seleccion en el partido.', 1;

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
	BEGIN TRY
		IF (@IdPartido IS NULL OR @IdPartido <=0)
			THROW 50000, '-Valor Invalido: IdPartido', 1;

		IF (@IdJugador IS NULL OR @IdJugador <=0)
			THROW 50000, '-Valor Invalido: IdJugador', 1;

		IF NOT EXISTS (SELECT 1 FROM partidos.Alineacion WHERE IdJugador = @IdJugador AND IdPartido = @IdPartido)
			THROW 50000, '-No existe alineacion a eliminar', 1;

		IF EXISTS(SELECT 1 FROM partidos.Evento WHERE Partido = @IdPartido)
			THROW 50000, '-Tabla siendo utilizada en Evento, no se puede eliminar', 1;

		DELETE FROM partidos.Alineacion WHERE IdJugador = @IdJugador AND IdPartido = @IdPartido
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO