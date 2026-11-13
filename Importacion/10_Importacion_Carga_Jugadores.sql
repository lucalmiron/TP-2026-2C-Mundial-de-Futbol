-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Comision 02
-- Grupo 7: Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 10/11/2026.
-- Objetivo: importar jugadores con la metodologia de tres fases.
--   FASE 1 STAGING     : se baja TODO a tablas temporales. #JugadoresCrudo
--                         guarda el CSV original sin modificar y
--                         #JugadoresStaging una fila por jugador del CSV, con
--                         los campos del dominio y las columnas Estado y
--                         Detalle.
--   FASE 2 DEPURACION  : reglas de conjunto (UPDATE) sobre la staging.
--   FASE 3 PERSISTENCIA : solo las filas validas pasan por
--                         SPTRANS.uspJugador_Registrar / uspJugador_Update.
--
-- Fecha de nacimiento APROXIMADA autorizada para el TP: 1 de enero de
-- birth_year. Se aplica solo a altas; no reemplaza fechas ya registradas.
-- Nombre y club: CSV. Posicion y dorsal: Promiedos. Pais: seleccion representada.
-- Cruce por seleccion y nombre (ignora mayusculas/acentos, no adivina
-- abreviaturas). Si no hay coincidencia directa, se consulta el CSV de
-- equivalencias habilitadas. Las propuestas con habilitado=0 NO se aplican.
-- No se inventan dorsales.
-- Dependencias: paises, selecciones del Mundial 1, clubes y SP de entrega 5.
-- SSMS: activar Consulta > Modo SQLCMD y ejecutar el archivo completo.
-- IMPORTANTE: cada integrante debe poner las rutas de su propia PC.
-- :setvar RutaJugadores "C:\ruta\proyecto\Datos\Jugadores\jugadores.csv"
-- :setvar RutaAliasJugadores "C:\ruta\proyecto\Datos\Jugadores\equivalencias_jugadores.csv"
-- :setvar RutaEquipos "C:\ruta\proyecto\Datos\equivalencias_equipos_jugadores.csv"
-- :setvar CarpetaPartidos "C:\ruta\proyecto\Datos\Datos_Partidos\partidos"
-- :setvar RutaLectura "C:\ruta\proyecto\Importacion\10_Lectura_JSON_Jugadores.sql"

--L
:setvar RutaJugadores "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Datos\Jugadores\jugadores.csv"
:setvar RutaAliasJugadores "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Datos\Jugadores\equivalencias_jugadores.csv"
:setvar RutaEquipos "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Datos\equivalencias_equipos_jugadores.csv"
:setvar CarpetaPartidos "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Datos\Datos_Partidos\partidos"
:setvar RutaLectura "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Importacion\10_Lectura_JSON_Jugadores.sql"

--Fidel
--:setvar RutaJugadores "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Datos\Jugadores\jugadores.csv"
--:setvar RutaAliasJugadores "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Datos\Jugadores\equivalencias_jugadores.csv"
--:setvar RutaEquipos "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Datos\equivalencias_equipos_jugadores.csv"
--:setvar CarpetaPartidos "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Datos\Datos_Partidos\partidos"
--:setvar RutaLectura "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Importacion\10_Lectura_JSON_Jugadores.sql"

USE [MUNDIALtesting];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @idMundial INT = 1;

IF @@TRANCOUNT<>0 OR (2 & @@OPTIONS)=2
    THROW 51600, 'Ejecute sin transaccion externa y con IMPLICIT_TRANSACTIONS OFF.', 1;
IF OBJECT_ID(N'SPTRANS.uspJugador_Registrar',N'P') IS NULL
    THROW 51600, 'Ejecute primero el instalador 00: falta SPTRANS.uspJugador_Registrar.', 1;
IF NOT EXISTS (SELECT 1 FROM sedes.Mundial WHERE IdMundial=@idMundial)
    THROW 51600, 'No existe el Mundial 1.', 1;

IF OBJECT_ID(N'tempdb..#JugadoresCrudo') IS NOT NULL DROP TABLE #JugadoresCrudo;
IF OBJECT_ID(N'tempdb..#JugadoresCsv') IS NOT NULL DROP TABLE #JugadoresCsv;
IF OBJECT_ID(N'tempdb..#EquiposCsv') IS NOT NULL DROP TABLE #EquiposCsv;
IF OBJECT_ID(N'tempdb..#AliasJugadores') IS NOT NULL DROP TABLE #AliasJugadores;
IF OBJECT_ID(N'tempdb..#ArchivosJugadores') IS NOT NULL DROP TABLE #ArchivosJugadores;
IF OBJECT_ID(N'tempdb..#ErroresArchivos') IS NOT NULL DROP TABLE #ErroresArchivos;
IF OBJECT_ID(N'tempdb..#Dorsales') IS NOT NULL DROP TABLE #Dorsales;
IF OBJECT_ID(N'tempdb..#JugadoresStaging') IS NOT NULL DROP TABLE #JugadoresStaging;

---------------------------------------------------------------------------------------
-- FASE 1 - STAGING
-- Todavia no se descarta nada: primero baja todo a tablas temporales.
---------------------------------------------------------------------------------------

-- 1.a) Archivo crudo: los bytes originales del CSV de jugadores, sin modificar.
CREATE TABLE #JugadoresCrudo (
    Archivo NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Contenido VARCHAR(MAX) COLLATE Latin1_General_100_CI_AS_SC_UTF8
);
-- Tabla temporal con el orden original de las 72 columnas del CSV.
-- Se recibe texto para no exigir conversiones numericas de campos que no usamos.
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
CREATE TABLE #AliasJugadores (
    Seleccion NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    NombreCsv NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    NombrePromiedos NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    Habilitado VARCHAR(10) COLLATE DATABASE_DEFAULT,
    Criterio NVARCHAR(500) COLLATE DATABASE_DEFAULT
);
CREATE TABLE #EquiposCsv (
    SeleccionCsv NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Slug NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Pais NVARCHAR(100) COLLATE DATABASE_DEFAULT
);
-- El lector deja los JSON originales.
CREATE TABLE #ArchivosJugadores (
    Archivo NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Contenido VARCHAR(MAX) COLLATE Latin1_General_100_CI_AS_SC_UTF8
);
CREATE TABLE #ErroresArchivos (
    Archivo NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Detalle NVARCHAR(2048) COLLATE DATABASE_DEFAULT
);
-- Dorsales y posiciones que se leen de los JSON de Promiedos.
CREATE TABLE #Dorsales (
    Slug NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Nombre NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    Numero INT,
    Posicion NVARCHAR(100) COLLATE DATABASE_DEFAULT
);
-- Staging: una fila por jugador del CSV.
CREATE TABLE #JugadoresStaging (
    Fila INT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Equipo NVARCHAR(60) COLLATE DATABASE_DEFAULT,
    Anio NVARCHAR(10) COLLATE DATABASE_DEFAULT,
    Club NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    PosicionCsv NVARCHAR(20) COLLATE DATABASE_DEFAULT,
    Slug NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Pais NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    NombrePromiedos NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    TipoCruce VARCHAR(20) COLLATE DATABASE_DEFAULT,
    Numero INT,
    Posicion NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    IdPais INT,
    IdSeleccion INT,
    IdClub INT,
    IdJugador INT,
    Estado VARCHAR(20) COLLATE DATABASE_DEFAULT NOT NULL DEFAULT 'Pendiente',
    Detalle NVARCHAR(2048) COLLATE DATABASE_DEFAULT
);

BEGIN TRY
    INSERT #JugadoresCrudo (Archivo, Contenido)
    SELECT N'jugadores.csv', BulkColumn
    FROM OPENROWSET(BULK '$(RutaJugadores)', SINGLE_BLOB) AS archivo;

    BULK INSERT #JugadoresCsv FROM '$(RutaJugadores)'
    WITH (FORMAT='CSV', FIRSTROW=2, FIELDTERMINATOR=',',
          ROWTERMINATOR='0x0d0a', CODEPAGE='65001', MAXERRORS=0);
    BULK INSERT #AliasJugadores FROM '$(RutaAliasJugadores)'
    WITH (FORMAT='CSV', FIRSTROW=2, FIELDTERMINATOR=',',
          ROWTERMINATOR='0x0d0a', CODEPAGE='65001', MAXERRORS=0);
    BULK INSERT #EquiposCsv FROM '$(RutaEquipos)'
    WITH (FORMAT='CSV', FIRSTROW=2, FIELDTERMINATOR=',',
          ROWTERMINATOR='0x0a', CODEPAGE='65001', MAXERRORS=0);
END TRY
BEGIN CATCH
    DECLARE @mensaje NVARCHAR(2048) = LEFT(N'No se pudieron leer los archivos de jugadores. '
                                           + ERROR_MESSAGE(), 2048);
    THROW 51601, @mensaje, 1;
END CATCH;

UPDATE #EquiposCsv SET SeleccionCsv=LTRIM(RTRIM(SeleccionCsv)), Slug=LTRIM(RTRIM(Slug)),
    Pais=LTRIM(RTRIM(REPLACE(Pais,NCHAR(13),N'')));
UPDATE #AliasJugadores SET Seleccion=LTRIM(RTRIM(Seleccion)), NombreCsv=LTRIM(RTRIM(NombreCsv)),
    NombrePromiedos=LTRIM(RTRIM(NombrePromiedos)), Habilitado=LTRIM(RTRIM(Habilitado)),
    Criterio=LTRIM(RTRIM(REPLACE(Criterio,NCHAR(13),N'')));

IF EXISTS (SELECT SeleccionCsv FROM #EquiposCsv GROUP BY SeleccionCsv HAVING COUNT(*)>1)
    THROW 51602, 'Hay equivalencias duplicadas para la misma seleccion.', 1;
IF EXISTS (SELECT 1 FROM #AliasJugadores WHERE Habilitado IS NULL OR Habilitado NOT IN ('0','1'))
    THROW 51602, 'El archivo de equivalencias tiene valores de habilitado invalidos.', 1;
IF EXISTS (SELECT 1 FROM #AliasJugadores WHERE Habilitado='1'
           AND (NULLIF(Seleccion,N'') IS NULL OR NULLIF(NombreCsv,N'') IS NULL
                OR NULLIF(NombrePromiedos,N'') IS NULL))
    THROW 51602, 'El archivo de equivalencias tiene nomes vacios.', 1;
IF EXISTS (SELECT Seleccion,NombreCsv FROM #AliasJugadores WHERE Habilitado='1'
           GROUP BY Seleccion,NombreCsv HAVING COUNT(DISTINCT NombrePromiedos)>1)
    THROW 51602, 'El archivo de equivalencias tiene destinos contradictorios.', 1;
IF EXISTS (SELECT Seleccion,NombrePromiedos FROM #AliasJugadores WHERE Habilitado='1'
           GROUP BY Seleccion,NombrePromiedos HAVING COUNT(DISTINCT NombreCsv)>1)
    THROW 51602, 'El archivo de equivalencias tiene orígenes contradictorios.', 1;
-- Un nombre de Promiedos no puede adjudicarse a otro jugador que ya coincide directamente.
IF EXISTS (
    SELECT 1 FROM #AliasJugadores a
    JOIN #Dorsales d ON d.Nombre COLLATE Latin1_General_100_CI_AI = a.NombrePromiedos COLLATE Latin1_General_100_CI_AI
    WHERE a.Habilitado='1'
      AND EXISTS (SELECT 1 FROM #Dorsales x
                  WHERE x.Slug = d.Slug AND x.Nombre COLLATE Latin1_General_100_CI_AI = a.NombreCsv COLLATE Latin1_General_100_CI_AI)
)
    THROW 51602, 'Una equivalencia habilitada pisa un nombre que ya coincide directamente.', 1;

-- Lecturas estaticas. Para incorporar archivos nuevos, agregar bloques al auxiliar.
:r $(RutaLectura)

-- 1.b) Dorsales y posiciones desde los JSON de Promiedos.
DECLARE @archivo NVARCHAR(100), @json NVARCHAR(MAX);
DECLARE crsArchivos CURSOR LOCAL FAST_FORWARD FOR SELECT Archivo,Contenido FROM #ArchivosJugadores;
OPEN crsArchivos;
FETCH NEXT FROM crsArchivos INTO @archivo,@json;
WHILE @@FETCH_STATUS=0
BEGIN
    BEGIN TRY
        IF LEFT(@json,1)=NCHAR(65279) SET @json=SUBSTRING(@json,2,LEN(@json));
        IF ISNULL(ISJSON(@json),0)<>1 THROW 51601,'JSON invalido.',1;
        IF JSON_QUERY(@json,'$.game.players.lineups.teams') IS NULL
            THROW 51601,'JSON sin alineaciones de jugadores.',1;
        INSERT #Dorsales
        SELECT t.Slug,LTRIM(RTRIM(p.Nombre)),p.Numero,LTRIM(RTRIM(p.Posicion))
        FROM OPENJSON(@json,'$.game.players.lineups.teams')
        WITH (Equipo INT '$.team_num',Titulares NVARCHAR(MAX) '$.starting' AS JSON,
              Suplentes NVARCHAR(MAX) '$.bench' AS JSON) l
        JOIN (
            SELECT CONVERT(INT,j.[key])+1 AS Equipo,JSON_VALUE(j.value,'$.url_name') AS Slug
            FROM OPENJSON(@json,'$.game.teams') j
        ) t ON t.Equipo=l.Equipo
        CROSS APPLY (SELECT l.Titulares AS Plantel UNION ALL SELECT l.Suplentes) a
        CROSS APPLY OPENJSON(a.Plantel)
        WITH (Nombre NVARCHAR(200) '$.name',Numero INT '$.jersey_num',Posicion NVARCHAR(100) '$.position') p;
    END TRY
    BEGIN CATCH
        INSERT #ErroresArchivos VALUES (@archivo,ERROR_MESSAGE());
    END CATCH;
    FETCH NEXT FROM crsArchivos INTO @archivo,@json;
END;
CLOSE crsArchivos;
DEALLOCATE crsArchivos;

-- 1.c) Staging: una fila por jugador del CSV.
INSERT #JugadoresStaging (Nombre, Equipo, Anio, Club, PosicionCsv)
SELECT LTRIM(RTRIM(player)), LTRIM(RTRIM(team)), LTRIM(RTRIM(birth_year)),
       NULLIF(LTRIM(RTRIM(club)),N''), NULLIF(LTRIM(RTRIM(position)),N'')
FROM #JugadoresCsv;
DROP TABLE #JugadoresCsv;

IF NOT EXISTS (SELECT 1 FROM #JugadoresStaging) THROW 51600,'CSV de jugadores vacio.',1;

---------------------------------------------------------------------------------------
-- FASE 2 - DEPURACION
-- Reglas de conjunto: cada UPDATE marca las filas invalidas y su motivo.
-- No se borra nada; las filas validas quedan en Estado = 'Pendiente'.
---------------------------------------------------------------------------------------

-- D1: nombre repetido en la misma seleccion del CSV: no se puede decidir cual es.
UPDATE r SET Estado='Error', Detalle=N'Nombre repetido en la misma seleccion del CSV; revisar identidad.'
FROM #JugadoresStaging r WHERE EXISTS (SELECT 1 FROM #JugadoresStaging o
  WHERE o.Fila<>r.Fila AND o.Equipo=r.Equipo
  AND o.Nombre COLLATE Latin1_General_100_CI_AI=r.Nombre COLLATE Latin1_General_100_CI_AI);

-- D2: nombre vacio o anio de nacimiento invalido.
UPDATE #JugadoresStaging SET Estado='Error',
    Detalle=N'Nombre vacio o anio de nacimiento invalido.'
WHERE Estado='Pendiente' AND (NULLIF(Nombre,N'') IS NULL
    OR TRY_CONVERT(INT,Anio) IS NULL OR TRY_CONVERT(INT,Anio)<1900
    OR TRY_CONVERT(INT,Anio)>YEAR(GETDATE()));

-- D3: la seleccion del CSV no tiene equivalencia unica.
UPDATE #JugadoresStaging SET Slug = (SELECT MIN(Slug) FROM #EquiposCsv
     WHERE #EquiposCsv.SeleccionCsv = #JugadoresStaging.Equipo),
     Pais = (SELECT MIN(Pais) FROM #EquiposCsv
     WHERE #EquiposCsv.SeleccionCsv = #JugadoresStaging.Equipo)
WHERE Estado='Pendiente';

UPDATE #JugadoresStaging SET Estado='Error',
    Detalle=N'No existe equivalencia unica para la seleccion del CSV.'
WHERE Estado='Pendiente' AND (Slug IS NULL OR Pais IS NULL);

-- D4: el nombre se resuelve primero de forma directa en Promiedos y, si no,
--     por el archivo de equivalencias habilitadas.
UPDATE #JugadoresStaging SET NombrePromiedos = COALESCE(
    (SELECT MIN(d.Nombre) FROM #Dorsales AS d
     WHERE d.Slug = #JugadoresStaging.Slug
       AND d.Nombre COLLATE Latin1_General_100_CI_AI = #JugadoresStaging.Nombre COLLATE Latin1_General_100_CI_AI),
    (SELECT MIN(a.NombrePromiedos) FROM #AliasJugadores AS a
     WHERE a.Habilitado='1' AND a.Seleccion = #JugadoresStaging.Equipo
       AND a.NombreCsv COLLATE Latin1_General_100_CI_AI = #JugadoresStaging.Nombre COLLATE Latin1_General_100_CI_AI)),
    TipoCruce = CASE WHEN EXISTS (SELECT 1 FROM #Dorsales AS d
             WHERE d.Slug = #JugadoresStaging.Slug
               AND d.Nombre COLLATE Latin1_General_100_CI_AI = #JugadoresStaging.Nombre COLLATE Latin1_General_100_CI_AI)
            THEN 'Directo' ELSE 'Equivalencia' END
WHERE Estado='Pendiente';

UPDATE #JugadoresStaging SET Estado='Error',
    Detalle=N'Sin coincidencia directa ni equivalencia habilitada. Revisar equivalencias_jugadores.csv.'
WHERE Estado='Pendiente' AND NombrePromiedos IS NULL;

-- D5: el nombre resuelto no puede tener mas de una equivalencia habilitada.
UPDATE #JugadoresStaging SET Estado='Error',
    Detalle=N'La equivalencia habilitada es ambigua para ese jugador.'
WHERE Estado='Pendiente' AND TipoCruce='Equivalencia'
  AND (SELECT COUNT(*) FROM #AliasJugadores a
       WHERE a.Habilitado='1' AND a.Seleccion=#JugadoresStaging.Equipo
         AND a.NombreCsv COLLATE Latin1_General_100_CI_AI = #JugadoresStaging.Nombre COLLATE Latin1_General_100_CI_AI) <> 1;

-- D6: dorsal y posicion unicos en Promiedos para el nombre resuelto.
UPDATE #JugadoresStaging SET Numero = (SELECT MIN(d.Numero) FROM #Dorsales AS d
     WHERE d.Slug = #JugadoresStaging.Slug
       AND d.Nombre COLLATE Latin1_General_100_CI_AI = #JugadoresStaging.NombrePromiedos COLLATE Latin1_General_100_CI_AI),
     Posicion = (SELECT MIN(NULLIF(d.Posicion,N'')) FROM #Dorsales AS d
     WHERE d.Slug = #JugadoresStaging.Slug
       AND d.Nombre COLLATE Latin1_General_100_CI_AI = #JugadoresStaging.NombrePromiedos COLLATE Latin1_General_100_CI_AI)
WHERE Estado='Pendiente';

UPDATE #JugadoresStaging SET Estado='Error',
    Detalle=N'Sin dorsal y posicion unicos en Promiedos para el nombre resuelto.'
WHERE Estado='Pendiente' AND (Numero IS NULL OR Numero<=0
    OR (SELECT COUNT(DISTINCT d.Numero) FROM #Dorsales AS d
        WHERE d.Slug = #JugadoresStaging.Slug
          AND d.Nombre COLLATE Latin1_General_100_CI_AI = #JugadoresStaging.NombrePromiedos COLLATE Latin1_General_100_CI_AI) <> 1);

-- D7: Promiedos omite la posicion en algunos planteles abreviados: se usa la del CSV.
UPDATE #JugadoresStaging SET Posicion = CASE LEFT(PosicionCsv,2)
        WHEN 'GK' THEN N'Arquero' WHEN 'DF' THEN N'Defensor'
        WHEN 'MF' THEN N'Mediocampista' WHEN 'FW' THEN N'Delantero' END
WHERE Estado='Pendiente' AND NULLIF(Posicion,N'') IS NULL;

UPDATE #JugadoresStaging SET Estado='Error',
    Detalle=N'Sin dorsal y posicion unicos en Promiedos para el nombre resuelto.'
WHERE Estado='Pendiente' AND NULLIF(Posicion,N'') IS NULL;

-- D8: el dorsal no puede estar asociado a otro nombre en Promiedos.
--     Se comparan inicial y apellido para no confundir al mismo jugador con otro.
UPDATE s SET Estado='Error',
    Detalle=N'El dorsal aparece asociado a otro nombre en Promiedos. Revisar identidad.'
FROM #JugadoresStaging AS s
WHERE s.Estado='Pendiente' AND s.Numero IS NOT NULL AND EXISTS (
    SELECT 1 FROM #Dorsales AS d
    WHERE d.Slug=s.Slug AND d.Numero=s.Numero
      AND NOT (
        LEFT(d.Nombre,1) COLLATE Latin1_General_100_CI_AI = LEFT(s.NombrePromiedos,1) COLLATE Latin1_General_100_CI_AI
        AND REVERSE(LEFT(REVERSE(d.Nombre),CHARINDEX(' ',REVERSE(d.Nombre)+' ')-1)) COLLATE Latin1_General_100_CI_AI
          = REVERSE(LEFT(REVERSE(s.NombrePromiedos),CHARINDEX(' ',REVERSE(s.NombrePromiedos)+' ')-1)) COLLATE Latin1_General_100_CI_AI
      ));

-- D9: el nombre y la posicion no pueden exceder el largo del modelo.
UPDATE #JugadoresStaging SET Estado='Error',
    Detalle=N'Nombre o posicion exceden el largo permitido (30/20).'
WHERE Estado='Pendiente' AND (LEN(Nombre)>30 OR LEN(Posicion)>20);

-- D10: el pais y la seleccion del Mundial 1 deben estar cargados.
UPDATE #JugadoresStaging SET IdPais = (SELECT MIN(IdPais) FROM equipos.Pais
     WHERE NOMBRE = #JugadoresStaging.Pais)
WHERE Estado='Pendiente';

UPDATE #JugadoresStaging SET IdSeleccion = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion
     WHERE IdPais = #JugadoresStaging.IdPais AND IdMundial = @idMundial)
WHERE Estado='Pendiente';

UPDATE #JugadoresStaging SET Estado='Error',
    Detalle=N'Pais o seleccion no cargados para el Mundial 1.'
WHERE Estado='Pendiente' AND (IdPais IS NULL OR IdSeleccion IS NULL);

-- D11: el club informado debe estar cargado (carga 09).
UPDATE #JugadoresStaging SET IdClub = (SELECT MIN(IdClub) FROM equipos.Club
     WHERE Nombre = #JugadoresStaging.Club)
WHERE Estado='Pendiente' AND Club IS NOT NULL;

UPDATE #JugadoresStaging SET Estado='Error',
    Detalle=N'Club informado no cargado. Revisar errores del importador 09.'
WHERE Estado='Pendiente' AND Club IS NOT NULL AND IdClub IS NULL;

-- D12: no puede haber dos jugadores con el mismo nombre en la misma seleccion.
UPDATE s SET Estado='Error',
    Detalle=N'Identidad ambigua: varios jugadores con ese nombre en la seleccion.'
FROM #JugadoresStaging AS s
WHERE s.Estado='Pendiente' AND EXISTS (
    SELECT 1 FROM #JugadoresStaging o
    WHERE o.Fila<>s.Fila AND o.IdSeleccion=s.IdSeleccion AND o.Nombre=s.Nombre);

-- Reporte de la depuracion: se informa ANTES de escribir en la tabla real.
SELECT 'FASE 2 - Depuracion de jugadores (antes de la persistencia)' AS Fase;
SELECT Estado, COUNT(*) AS Cantidad FROM #JugadoresStaging GROUP BY Estado ORDER BY Estado;
SELECT Fila, Nombre, Equipo, Anio, Club, NombrePromiedos, TipoCruce, Numero, Posicion, Estado, Detalle
FROM #JugadoresStaging WHERE Estado IN ('Error','Duplicada') ORDER BY Fila;

---------------------------------------------------------------------------------------
-- FASE 3 - PERSISTENCIA
-- Solo las filas que quedaron en 'Pendiente' llegan a la tabla real, siempre
-- a traves de los SP de ABM de la entrega 5.
---------------------------------------------------------------------------------------

DECLARE @fila INT, @nombre NVARCHAR(100), @equipo NVARCHAR(60), @anioTxt NVARCHAR(10),
        @club NVARCHAR(100), @numero INT, @pos NVARCHAR(100),
        @anio INT, @fnac DATE, @idPais INT, @idSeleccion INT, @idClub INT, @idJugador INT,
        @cantidad INT, @estado VARCHAR(20), @nombreSp NVARCHAR(30), @posSp NVARCHAR(20);
DECLARE crsJugadores CURSOR LOCAL FAST_FORWARD FOR
    SELECT Fila, Nombre, Equipo, Anio, Club, Numero, Posicion,
           IdPais, IdSeleccion, IdClub
    FROM #JugadoresStaging WHERE Estado='Pendiente' ORDER BY Fila;
OPEN crsJugadores;
FETCH NEXT FROM crsJugadores INTO @fila,@nombre,@equipo,@anioTxt,@club,@numero,@pos,@idPais,@idSeleccion,@idClub;
WHILE @@FETCH_STATUS=0
BEGIN
    BEGIN TRY
        SET @anio = TRY_CONVERT(INT, @anioTxt);
        SET @fnac = DATEFROMPARTS(@anio,1,1);
        SET @nombreSp = CONVERT(NVARCHAR(30), @nombre);
        SET @posSp = CONVERT(NVARCHAR(20), @pos);
        BEGIN TRANSACTION;
        SET @idJugador = NULL;
        SELECT @cantidad=COUNT(*), @idJugador=MIN(j.IdJugador)
        FROM equipos.Jugador j WITH (UPDLOCK, HOLDLOCK)
        JOIN equipos.Persona p ON p.IdPersona=j.IdJugador
        WHERE j.Seleccion=@idSeleccion AND p.Nombre=@nombreSp;
        IF @cantidad>1 THROW 51602,'Identidad ambigua: varios jugadores con ese nombre en la seleccion.',1;
        IF @cantidad=0
        BEGIN
            EXEC SPTRANS.uspJugador_Registrar @nombre=@nombreSp,@fnac=@fnac,@pais=@idPais,
              @posicion=@posSp,@numero=@numero,@club=@idClub,@seleccion=@idSeleccion,@estado='Activo';
            SET @estado='Insertada';
        END
        ELSE
        BEGIN
            SET @estado='SinCambios';
            IF EXISTS (SELECT 1 FROM equipos.Jugador WHERE IdJugador=@idJugador
                       AND (Posicion<>@posSp OR Numero<>@numero))
            BEGIN
                EXEC SPTRANS.uspJugador_Update @id=@idJugador,@posicion=@posSp,@numero=@numero;
                SET @estado='Actualizada';
            END;
            IF @idClub IS NOT NULL AND EXISTS (SELECT 1 FROM equipos.Jugador WHERE IdJugador=@idJugador
                                               AND (Club IS NULL OR Club<>@idClub))
            BEGIN
                EXEC SP.uspJugador_ClubUpdate @id=@idJugador,@club=@idClub;
                SET @estado='Actualizada';
            END;
        END;
        COMMIT TRANSACTION;
        UPDATE #JugadoresStaging SET IdJugador=@idJugador, Estado=@estado WHERE Fila=@fila;
    END TRY
    BEGIN CATCH
        IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
        UPDATE #JugadoresStaging SET Estado='Error', Detalle=ERROR_MESSAGE() WHERE Fila=@fila;
    END CATCH;
    FETCH NEXT FROM crsJugadores INTO @fila,@nombre,@equipo,@anioTxt,@club,@numero,@pos,@idPais,@idSeleccion,@idClub;
END;
CLOSE crsJugadores;
DEALLOCATE crsJugadores;

-- Reporte final de la persistencia.
SELECT 'FASE 3 - Persistencia de jugadores' AS Fase;
SELECT Estado, COUNT(*) AS Cantidad FROM #JugadoresStaging GROUP BY Estado ORDER BY Estado;
SELECT Fila, Nombre, Equipo, NombrePromiedos, TipoCruce, Anio AS AnioNacimiento,
       Club, Numero, Posicion, IdJugador, Estado, Detalle
FROM #JugadoresStaging ORDER BY Equipo, Nombre;
SELECT Archivo, Detalle FROM #ErroresArchivos;

DECLARE @hayErrores BIT = CASE WHEN EXISTS (SELECT 1 FROM #JugadoresStaging WHERE Estado='Error')
  OR EXISTS (SELECT 1 FROM #ErroresArchivos) THEN 1 ELSE 0 END;
DROP TABLE #JugadoresCrudo;
DROP TABLE #AliasJugadores;
DROP TABLE #EquiposCsv;
DROP TABLE #ArchivosJugadores;
DROP TABLE #ErroresArchivos;
DROP TABLE #Dorsales;
DROP TABLE #JugadoresStaging;
IF @hayErrores=1 THROW 51603,'Importacion parcial: se conservaron los jugadores validos. Revise el detalle.',1;
GO
