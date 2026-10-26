--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 25/10/26
-- Objetivo: separar goles de juego y conversiones de tanda en una transaccion.
 
USE MUNDIAL;
GO
 
CREATE OR ALTER PROCEDURE SPTRANS.uspGol_Registrar
    @minuto     INT,
    @partido    INT,
    @periodo    INT,
    @autor      INT,
    @asistencia INT = NULL,
    @tipo       VARCHAR(20),
    @idGol      INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
 
    DECLARE @errores   NVARCHAR(2048) = N'',
            @penales   BIT,
            @eq1       INT,
            @eq2       INT,
            @seleccion INT;
 
    SELECT @penales = EsPenales
    FROM partidos.Periodo
    WHERE IdPeriodo = @periodo;
 
    IF @penales IS NULL
        SET @errores += N'Periodo inexistente. ';
 
    IF NOT EXISTS (SELECT 1 FROM partidos.Partido WHERE IdPartido = @partido)
        SET @errores += N'Partido inexistente. ';
 
    IF @tipo IS NULL OR @tipo NOT IN ('Jugada', 'Penal', 'Tiro libre', 'Corner', 'En contra')
        SET @errores += N'Tipo de gol invalido. ';
 
    IF @minuto < 0
        SET @errores += N'Minuto invalido. ';
 
    IF @penales = 0 AND @minuto IS NULL
        SET @errores += N'El minuto es obligatorio fuera de la tanda. ';
 
    DECLARE @minutoJuego INT = COALESCE(@minuto, 2147483647);
 
    IF partidos.fnJugadorEnCancha(@partido, @autor, @minutoJuego) = 0
        SET @errores += N'El autor no estaba en cancha. ';
 
    IF @asistencia IS NOT NULL AND partidos.fnJugadorEnCancha(@partido, @asistencia, @minutoJuego) = 0
        SET @errores += N'El asistente no estaba en cancha. ';
 
    IF @penales = 1 AND (@minuto IS NOT NULL OR @tipo <> 'Penal' OR @asistencia IS NOT NULL)
        SET @errores += N'La tanda requiere tipo Penal, minuto NULL y sin asistencia. ';
 
    IF @penales = 0
       AND @minuto IS NOT NULL
       AND EXISTS (
            SELECT 1
            FROM partidos.Periodo
            WHERE IdPeriodo = @periodo
              AND (@minuto < Inicio OR @minuto > Fin)
       )
        SET @errores += N'Minuto fuera del periodo. ';
 
    IF @autor = @asistencia
        SET @errores += N'Autor y asistente deben ser diferentes. ';
 
    IF @tipo = 'En contra' AND @asistencia IS NOT NULL
        SET @errores += N'Un gol en contra no lleva asistencia. ';
 
    SELECT @seleccion = Seleccion
    FROM equipos.Jugador
    WHERE IdJugador = @autor;
 
    SELECT @eq1 = Eq1,
           @eq2 = Eq2
    FROM partidos.Partido
    WHERE IdPartido = @partido;
 
    IF @seleccion IS NULL OR @seleccion NOT IN (@eq1, @eq2)
        SET @errores += N'El autor no pertenece a un equipo del partido. ';
 
    IF @asistencia IS NOT NULL
       AND NOT EXISTS (
            SELECT 1
            FROM equipos.Jugador
            WHERE IdJugador = @asistencia
              AND Seleccion = @seleccion
       )
        SET @errores += N'El asistente debe pertenecer al equipo del autor. ';
 

 
    BEGIN TRY
        BEGIN TRANSACTION;
 
        -- Serializa goles y bajas del mismo partido para no perder incrementos.
        SELECT @eq1 = Eq1,
               @eq2 = Eq2
        FROM partidos.Partido WITH (UPDLOCK, HOLDLOCK)
        WHERE IdPartido = @partido;
 
        IF @penales = 1
           AND EXISTS (
                SELECT 1
                FROM partidos.Partido p
                JOIN partidos.Fase f ON f.IdFase = p.IdFase
                WHERE p.IdPartido = @partido
                  AND f.Descripcion = 'Grupos'
           )
            SET @errores += 'La fase de grupos no admite definicion por penales.' + N' ';
 
        IF @penales = 1
           AND EXISTS (
                SELECT 1
                FROM partidos.Partido
                WHERE IdPartido = @partido
                  AND GolesEq1 <> GolesEq2
           )
            SET @errores += 'Solo se puede iniciar una tanda con marcador empatado.' + N' ';
 
        IF @penales = 0
           AND EXISTS (
                SELECT 1
                FROM partidos.Partido
                WHERE IdPartido = @partido
                  AND PenalesEq1 IS NOT NULL
           )
            SET @errores += 'Anular la tanda antes de corregir goles del partido.' + N' ';
 
        IF LEN(@errores)>0 THROW 51000,@errores,1;

        INSERT partidos.Evento (Minuto, Tipo, Partido, Periodo)
        VALUES (@minuto, 'Gol', @partido, @periodo);
 
        SET @idGol = CONVERT(INT, SCOPE_IDENTITY());
 
        INSERT partidos.Gol (IdGol, Autor, Asistencia, Tipo)
        VALUES (@idGol, @autor, @asistencia, @tipo);
 
        IF @penales = 1
            UPDATE partidos.Partido
            SET PenalesEq1 = COALESCE(PenalesEq1, 0) + CASE WHEN @seleccion = @eq1 THEN 1 ELSE 0 END,
                PenalesEq2 = COALESCE(PenalesEq2, 0) + CASE WHEN @seleccion = @eq2 THEN 1 ELSE 0 END
            WHERE IdPartido = @partido;
        ELSE
            UPDATE partidos.Partido
            SET GolesEq1 = GolesEq1 + CASE WHEN (@seleccion = @eq1 AND @tipo <> 'En contra') OR (@seleccion = @eq2 AND @tipo = 'En contra') THEN 1 ELSE 0 END,
                GolesEq2 = GolesEq2 + CASE WHEN (@seleccion = @eq2 AND @tipo <> 'En contra') OR (@seleccion = @eq1 AND @tipo = 'En contra') THEN 1 ELSE 0 END
            WHERE IdPartido = @partido;
 
        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;
 
        THROW;
    END CATCH;
END;
GO
 
CREATE OR ALTER PROCEDURE SPTRANS.uspGol_Bajar
    @id INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
 
    DECLARE @partido INT,
            @penales BIT,
            @tipo    VARCHAR(20),
            @sel     INT,
            @eq1     INT,
            @eq2     INT;
 
    SELECT @partido = Partido
    FROM partidos.Evento
    WHERE IdEvento = @id;
 
    IF @partido IS NULL OR NOT EXISTS (SELECT 1 FROM partidos.Gol WHERE IdGol = @id)
        SET @errores += 'Gol inexistente.' + N' ';
 
    BEGIN TRY
        BEGIN TRANSACTION;
 
        SELECT @eq1 = Eq1,
               @eq2 = Eq2
        FROM partidos.Partido WITH (UPDLOCK, HOLDLOCK)
        WHERE IdPartido = @partido;
 
        IF NOT EXISTS (SELECT 1 FROM partidos.Gol WHERE IdGol = @id)
            SET @errores += 'El gol ya fue eliminado.' + N' ';
 
        SELECT @penales = r.EsPenales,
               @tipo    = g.Tipo,
               @sel     = j.Seleccion
        FROM partidos.Gol g
        JOIN partidos.Evento e  ON e.IdEvento  = g.IdGol
        JOIN partidos.Periodo r ON r.IdPeriodo = e.Periodo
        JOIN equipos.Jugador j  ON j.IdJugador = g.Autor
        WHERE g.IdGol = @id;
 
        IF @penales = 0
           AND EXISTS (
                SELECT 1
                FROM partidos.Partido
                WHERE IdPartido = @partido
                  AND PenalesEq1 IS NOT NULL
           )
            SET @errores += 'Anular la tanda antes de corregir goles del partido.' + N' ';
 
        IF LEN(@errores)>0 THROW 50000, @errores, 1;

        IF @penales = 1
            UPDATE partidos.Partido
            SET PenalesEq1 = PenalesEq1 - CASE WHEN @sel = @eq1 THEN 1 ELSE 0 END,
                PenalesEq2 = PenalesEq2 - CASE WHEN @sel = @eq2 THEN 1 ELSE 0 END
            WHERE IdPartido = @partido;
        ELSE
            UPDATE partidos.Partido
            SET GolesEq1 = GolesEq1 - CASE WHEN (@sel = @eq1 AND @tipo <> 'En contra') OR (@sel = @eq2 AND @tipo = 'En contra') THEN 1 ELSE 0 END,
                GolesEq2 = GolesEq2 - CASE WHEN (@sel = @eq2 AND @tipo <> 'En contra') OR (@sel = @eq1 AND @tipo = 'En contra') THEN 1 ELSE 0 END
            WHERE IdPartido = @partido;
 
        DELETE partidos.Gol
        WHERE IdGol = @id;
 
        DELETE partidos.Evento
        WHERE IdEvento = @id;
 
        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;
 
        THROW;
    END CATCH;
END;
GO
 
-- Iniciar permite representar una tanda 0-0; anular la deja NULL-NULL.
-- No representa cierre de partido ni verifica todas las reglas de tiros de una tanda.
CREATE OR ALTER PROCEDURE SP.uspPartido_Tanda
    @IdPartido INT,
    @Iniciar   BIT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
 
    IF @Iniciar IS NULL
        SET @errores += 'Iniciar es obligatorio.' + N' ';
 
    IF NOT EXISTS (SELECT 1 FROM partidos.Partido WHERE IdPartido = @IdPartido)
        SET @errores += 'Partido inexistente.' + N' ';
 
    BEGIN TRY
        BEGIN TRANSACTION;
 
        DECLARE @g1 INT,
                @g2 INT;
 
        SELECT @g1 = GolesEq1,
               @g2 = GolesEq2
        FROM partidos.Partido WITH (UPDLOCK, HOLDLOCK)
        WHERE IdPartido = @IdPartido;
 
        IF @Iniciar = 1
           AND EXISTS (
                SELECT 1
                FROM partidos.Partido p
                JOIN partidos.Fase f ON f.IdFase = p.IdFase
                WHERE p.IdPartido = @IdPartido
                  AND f.Descripcion = 'Grupos'
           )
            SET @errores += 'La fase de grupos no admite definicion por penales.' + N' ';
 
        IF @Iniciar = 1 AND @g1 <> @g2
            SET @errores += 'La tanda requiere empate.' + N' ';
 
        IF @Iniciar = 0
           AND EXISTS (
                SELECT 1
                FROM partidos.Evento e
                JOIN partidos.Gol g     ON g.IdGol     = e.IdEvento
                JOIN partidos.Periodo r ON r.IdPeriodo = e.Periodo
                WHERE e.Partido = @IdPartido
                  AND r.EsPenales = 1
           )
            SET @errores += 'Eliminar primero las conversiones de la tanda.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;
 
        UPDATE partidos.Partido
        SET PenalesEq1 = CASE WHEN @Iniciar = 1 THEN COALESCE(PenalesEq1, 0) ELSE NULL END,
            PenalesEq2 = CASE WHEN @Iniciar = 1 THEN COALESCE(PenalesEq2, 0) ELSE NULL END
        WHERE IdPartido = @IdPartido;
 
        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;
 
        THROW;
    END CATCH;
END;
GO
 
CREATE OR ALTER VIEW partidos.vResultadoPartido AS
    SELECT IdPartido,
           GolesEq1,
           GolesEq2,
           PenalesEq1,
           PenalesEq2,
           CONCAT(
               GolesEq1,
               CASE WHEN PenalesEq1 IS NOT NULL THEN CONCAT('(', PenalesEq1, ')') ELSE '' END,
               ' - ',
               GolesEq2,
               CASE WHEN PenalesEq2 IS NOT NULL THEN CONCAT('(', PenalesEq2, ')') ELSE '' END
           ) AS Resultado
    FROM partidos.Partido;
GO
 
-- Fuente para reportes de goleadores: excluye tandas y goles en contra.
CREATE OR ALTER VIEW partidos.vGolesComputables AS
    SELECT g.IdGol,
           g.Autor,
           g.Asistencia,
           g.Tipo,
           e.Partido,
           e.Minuto,
           e.Periodo
    FROM partidos.Gol g
    JOIN partidos.Evento e  ON e.IdEvento  = g.IdGol
    JOIN partidos.Periodo r ON r.IdPeriodo = e.Periodo
    WHERE r.EsPenales = 0
      AND g.Tipo <> 'En contra';
GO