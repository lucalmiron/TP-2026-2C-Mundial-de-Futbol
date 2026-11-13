-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Comision 02
-- Grupo 7: Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 13/11/2026.
-- Objetivo: cargar los clubes desde la columna 'club' del CSV original de
-- jugadores, con la metodologia de tres fases.
--   FASE 1 STAGING     : se baja TODO a tablas temporales. #ClubesCrudo guarda
--                         el archivo original sin modificar y #ClubesStaging
--                         una fila por club distinto, con las columnas
--                         Estado y Detalle.
--   FASE 2 DEPURACION  : reglas de conjunto (UPDATE) sobre la staging.
--   FASE 3 PERSISTENCIA : solo los clubes validos pasan por
--                         SP.uspClub_Registrar.
-- Debe ejecutarse antes de la carga 10 (jugadores), que busca el club por
-- nombre: si el club no esta cargado, el jugador se rechaza.
-- SSMS: Consulta > Modo SQLCMD. Ajustar la ruta del servidor SQL.
-- IMPORTANTE: cada integrante debe poner la ruta de su propia PC, porque
-- SQL Server lee los archivos desde el disco local del servidor.
-- :setvar RutaJugadores "C:\ruta\proyecto\Datos\Jugadores\jugadores.csv"

--L
:setvar RutaJugadores "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Datos\Jugadores\jugadores.csv"

--Fidel
--:setvar RutaJugadores "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Datos\Jugadores\jugadores.csv"

USE MUNDIALtesting;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF @@TRANCOUNT<>0 OR (2 & @@OPTIONS)=2
    THROW 51500, 'Ejecute sin transaccion externa y con IMPLICIT_TRANSACTIONS OFF.', 1;
IF OBJECT_ID(N'equipos.Club',N'U') IS NULL
   OR OBJECT_ID(N'SP.uspClub_Registrar',N'P') IS NULL
    THROW 51500, 'Falta la tabla Club o su SP de alta.', 1;

IF OBJECT_ID(N'tempdb..#ClubesCrudo') IS NOT NULL DROP TABLE #ClubesCrudo;
IF OBJECT_ID(N'tempdb..#JugadoresCsv') IS NOT NULL DROP TABLE #JugadoresCsv;
IF OBJECT_ID(N'tempdb..#ClubesStaging') IS NOT NULL DROP TABLE #ClubesStaging;

---------------------------------------------------------------------------------------
-- FASE 1 - STAGING
-- Todavia no se descarta nada: primero baja todo a tablas temporales.
---------------------------------------------------------------------------------------

-- 1.a) Archivo crudo: los bytes originales del CSV, sin modificar.
CREATE TABLE #ClubesCrudo (
    Archivo NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Contenido VARBINARY(MAX)
);

-- 1.b) Lectura del CSV con el orden original de sus 72 columnas. Se recibe
--      texto para no exigir conversiones numericas de campos que no usamos.
--      ROWTERMINATOR = 0x0d0a porque el archivo usa fin de linea CRLF.
CREATE TABLE #JugadoresCsv (
    [player] NVARCHAR(100) COLLATE DATABASE_DEFAULT NULL,
    [team] NVARCHAR(60) COLLATE DATABASE_DEFAULT NULL,
    [team_country] NVARCHAR(60) COLLATE DATABASE_DEFAULT NULL,
    [position] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [age] NVARCHAR(10) COLLATE DATABASE_DEFAULT NULL,
    [birth_year] NVARCHAR(10) COLLATE DATABASE_DEFAULT NULL,
    [club] NVARCHAR(100) COLLATE DATABASE_DEFAULT NULL,
    [games] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [games_starts] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [minutes] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [minutes_90s] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [goals] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [assists] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [goals_assists] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [goals_pens] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [pens_made] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [pens_att] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [cards_yellow] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [cards_red] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [goals_per90] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [assists_per90] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [goals_assists_per90] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [goals_pens_per90] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [goals_assists_pens_per90] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [shots] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [shots_on_target] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [shots_on_target_pct] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [shots_per90] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [shots_on_target_per90] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [goals_per_shot] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [goals_per_shot_on_target] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [minutes_per_game] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [minutes_pct] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [minutes_per_start] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [games_complete] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [games_subs] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [minutes_per_sub] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [unused_subs] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [points_per_game] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [on_goals_for] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [on_goals_against] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [plus_minus] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [plus_minus_per90] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [plus_minus_wowy] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [cards_yellow_red] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [fouls] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [fouled] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [offsides] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [crosses] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [interceptions] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [tackles_won] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [pens_won] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [pens_conceded] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [own_goals] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [gk_games] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [gk_games_starts] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [gk_minutes] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [gk_goals_against] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [gk_goals_against_per90] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [gk_shots_on_target_against] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [gk_saves] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [gk_save_pct] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [gk_wins] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [gk_ties] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [gk_losses] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [gk_clean_sheets] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [gk_clean_sheets_pct] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [gk_pens_att] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [gk_pens_allowed] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [gk_pens_saved] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [gk_pens_missed] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [gk_pens_save_pct] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL
);

-- 1.c) Staging de campos: una fila por club distinto del archivo.
CREATE TABLE #ClubesStaging (
    Fila INT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    CantidadJugadores INT,
    IdClub INT,
    Estado VARCHAR(20) COLLATE DATABASE_DEFAULT NOT NULL DEFAULT 'Pendiente',
    Detalle NVARCHAR(2048) COLLATE DATABASE_DEFAULT
);

BEGIN TRY
    -- Copia del archivo original sin modificar.
    INSERT #ClubesCrudo (Archivo, Contenido)
    SELECT N'jugadores.csv', BulkColumn
    FROM OPENROWSET(BULK '$(RutaJugadores)', SINGLE_BLOB) AS archivo;

    BULK INSERT #JugadoresCsv FROM '$(RutaJugadores)'
    WITH (FORMAT='CSV', FIRSTROW=2, FIELDTERMINATOR=',', ROWTERMINATOR='0x0d0a',
          CODEPAGE='65001', MAXERRORS=0);
END TRY
BEGIN CATCH
    DECLARE @mensaje NVARCHAR(2048) = LEFT(N'No se pudo leer el CSV de jugadores: '
                                           + ERROR_MESSAGE(), 2048);
    THROW 51501, @mensaje, 1;
END CATCH;

DECLARE @filas INT=(SELECT COUNT(*) FROM #JugadoresCsv), @sinClub INT;
UPDATE #JugadoresCsv SET club=LTRIM(RTRIM(club));
SELECT @sinClub=COUNT(*) FROM #JugadoresCsv WHERE NULLIF(club,N'') IS NULL;

INSERT #ClubesStaging (Nombre, CantidadJugadores)
SELECT club, COUNT(*) FROM #JugadoresCsv
WHERE NULLIF(club,N'') IS NOT NULL
GROUP BY club;

DROP TABLE #JugadoresCsv;

IF @filas=0 THROW 51501, 'El CSV no contiene jugadores.', 1;

---------------------------------------------------------------------------------------
-- FASE 2 - DEPURACION
-- Reglas de conjunto: cada UPDATE marca las filas invalidas y su motivo.
-- No se borra nada; las filas validas quedan en Estado = 'Pendiente'.
---------------------------------------------------------------------------------------

-- D1: el nombre no cabe en Club.NOMBRE NVARCHAR(40).
--     La columna es NVARCHAR: no hay perdida de caracteres, solo cuenta longitud.
UPDATE #ClubesStaging SET Estado='Error',
    Detalle=N'El nombre del club excede los 40 caracteres de Club.NOMBRE.'
WHERE Estado='Pendiente'
  AND (NULLIF(Nombre,N'') IS NULL OR LEN(Nombre) > 40);

-- D2: el club esta repetido en el archivo (la unicidad la impone la tabla).
UPDATE f SET Estado='Duplicada', Detalle=N'El club ya aparece en otra fila del archivo.'
FROM #ClubesStaging AS f
WHERE f.Estado='Pendiente' AND EXISTS (
    SELECT 1 FROM #ClubesStaging AS o
    WHERE o.Nombre=f.Nombre AND o.Fila<f.Fila
);

-- Reporte de la depuracion: se informa ANTES de escribir en la tabla real.
SELECT 'FASE 2 - Depuracion de clubes (antes de la persistencia)' AS Fase;
SELECT @filas AS FilasJugadores, @sinClub AS JugadoresSinClubInformado;
SELECT Estado, COUNT(*) AS Cantidad FROM #ClubesStaging GROUP BY Estado ORDER BY Estado;
SELECT Fila, Nombre, CantidadJugadores, Estado, Detalle
FROM #ClubesStaging WHERE Estado IN ('Error','Duplicada') ORDER BY Fila;

---------------------------------------------------------------------------------------
-- FASE 3 - PERSISTENCIA
-- Solo las filas que quedaron en 'Pendiente' llegan a la tabla real, siempre
-- a traves de los SP de ABM de la entrega 5.
---------------------------------------------------------------------------------------

DECLARE @fila INT, @nombre NVARCHAR(40), @id INT, @cantidad INT, @estado VARCHAR(20);
DECLARE crsClubes CURSOR LOCAL FAST_FORWARD FOR
    SELECT Fila, CONVERT(NVARCHAR(40), Nombre) FROM #ClubesStaging
    WHERE Estado='Pendiente' ORDER BY Fila;
OPEN crsClubes;
FETCH NEXT FROM crsClubes INTO @fila, @nombre;
WHILE @@FETCH_STATUS=0
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        SELECT @cantidad=COUNT(*),@id=MIN(IdClub)
        FROM equipos.Club WITH (UPDLOCK,HOLDLOCK) WHERE Nombre=@nombre;
        IF @cantidad>1 THROW 51502, 'Nombre de club duplicado en la base.', 1;
        IF @cantidad=0
        BEGIN
            EXEC SP.uspClub_Registrar @nombre=@nombre;
            SELECT @id=IdClub FROM equipos.Club WHERE Nombre=@nombre;
            SET @estado='Insertada';
        END
        ELSE SET @estado='SinCambios';
        COMMIT TRANSACTION;
        UPDATE #ClubesStaging SET IdClub=@id,Estado=@estado WHERE Fila=@fila;
    END TRY
    BEGIN CATCH
        IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
        UPDATE #ClubesStaging SET Estado='Error',Detalle=ERROR_MESSAGE() WHERE Fila=@fila;
    END CATCH;
    FETCH NEXT FROM crsClubes INTO @fila, @nombre;
END;
CLOSE crsClubes;
DEALLOCATE crsClubes;

-- Reporte final de la persistencia.
SELECT 'FASE 3 - Persistencia de clubes' AS Fase;
SELECT Estado, COUNT(*) AS Cantidad FROM #ClubesStaging GROUP BY Estado ORDER BY Estado;
SELECT Fila, Nombre, CantidadJugadores, IdClub, Estado, Detalle
FROM #ClubesStaging ORDER BY Fila;

DECLARE @fallos INT = (SELECT COUNT(*) FROM #ClubesStaging WHERE Estado='Error');
DROP TABLE #ClubesCrudo;
DROP TABLE #ClubesStaging;
IF @fallos>0
    THROW 51503, 'Hubo clubes rechazados. Los correctos se conservaron; revise el detalle.', 1;
GO
