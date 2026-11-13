-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Comision 02
-- Grupo 7: Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 13/11/2026.
-- Objetivo: cargar las amonestaciones de los 104 JSON de Promiedos con la
-- metodologia de tres fases. Tipos de evento de la fuente: 4 amarilla,
-- 6 segunda amarilla con expulsion.
--   FASE 1 STAGING     : una fila por tarjeta.
--   FASE 2 DEPURACION  : reglas de conjunto (UPDATE) sobre la staging.
--   FASE 3 PERSISTENCIA : solo las filas validas pasan por
--                         SPTRANS.uspAmonestacion_Registrar.
-- Requiere ejecutar antes las cargas 10 (jugadores), 11 (partidos),
-- 13 (alineaciones) y 18 (arbitros: el arbitro del partido es obligatorio).
-- SSMS: Consulta -> Modo SQLCMD. Ajustar las rutas del servidor SQL.
-- IMPORTANTE: cada integrante debe poner las rutas de su propia PC.
-- :setvar CarpetaPartidos "C:\ruta\proyecto\Datos\Datos_Partidos\partidos"
-- :setvar RutaLecturaJSON "C:\ruta\proyecto\Importacion\11_Lectura_JSON_Partidos.sql"
-- :setvar RutaLecturaPartidos "C:\ruta\proyecto\Importacion\XX_Lectura_Partidos_JSON.sql"
-- :setvar RutaEquipos "C:\ruta\proyecto\Datos\equivalencias_equipos_jugadores.csv"
-- :setvar RutaSedes "C:\ruta\proyecto\Datos\equivalencias_sedes_partidos.csv"
-- :setvar RutaFases "C:\ruta\proyecto\Datos\equivalencias_fases_partidos.csv"
:setvar RutaAliasJugadores "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Datos\Jugadores\equivalencias_jugadores.csv"
-- :setvar RutaAliasJugadores "C:\ruta\proyecto\Datos\Jugadores\equivalencias_jugadores.csv"

:setvar CarpetaPartidos "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Datos\Datos_Partidos\partidos"
:setvar RutaLecturaJSON "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Importacion\11_Lectura_JSON_Partidos.sql"
:setvar RutaLecturaPartidos "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Importacion\XX_Lectura_Partidos_JSON.sql"
:setvar RutaEquipos "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Datos\equivalencias_equipos_jugadores.csv"
:setvar RutaSedes "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Datos\equivalencias_sedes_partidos.csv"
:setvar RutaFases "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Datos\equivalencias_fases_partidos.csv"

USE [MUNDIAL];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF @@TRANCOUNT <> 0 OR (2 & @@OPTIONS) = 2
    THROW 51900, 'Ejecute sin transaccion externa y con IMPLICIT_TRANSACTIONS OFF.', 1;
IF OBJECT_ID(N'partidos.Amonestacion', N'U') IS NULL
   OR OBJECT_ID(N'SPTRANS.uspAmonestacion_Registrar', N'P') IS NULL
    THROW 51900, 'Faltan tablas o SP ABM. Ejecute primero el instalador.', 1;

IF OBJECT_ID(N'tempdb..#AmonestacionesStaging') IS NOT NULL DROP TABLE #AmonestacionesStaging;

-- Lector compartido: deja los JSON crudos, las equivalencias y el partido resuelto.
:r $(RutaLecturaPartidos)

---------------------------------------------------------------------------------------
-- FASE 1 - STAGING
-- Una fila por tarjeta (tipos 4 y 6 de la fuente).
---------------------------------------------------------------------------------------

CREATE TABLE #AmonestacionesStaging (
    Fila INT IDENTITY(1,1) PRIMARY KEY,
    Archivo NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    GameId NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    IdPartido INT,
    TipoEvento INT,
    Etapa NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    MinutoTexto NVARCHAR(20) COLLATE DATABASE_DEFAULT,
    Minuto INT,
    Periodo INT,
    Team INT,
    NombreAmonestado NVARCHAR(60) COLLATE DATABASE_DEFAULT,
    NombreAmonestadoBd NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    Seleccion INT,
    SeleccionPais NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Tarjeta VARCHAR(8) COLLATE DATABASE_DEFAULT,
    NombreArbitro NVARCHAR(60) COLLATE DATABASE_DEFAULT,
    IdJugador INT,
    IdArbitro INT,
    DetallePartido NVARCHAR(2048) COLLATE DATABASE_DEFAULT,
    Estado VARCHAR(20) COLLATE DATABASE_DEFAULT NOT NULL DEFAULT 'Pendiente',
    Detalle NVARCHAR(2048) COLLATE DATABASE_DEFAULT
);

INSERT #AmonestacionesStaging
    (Archivo, GameId, IdPartido, TipoEvento, Etapa, MinutoTexto, Minuto, Periodo,
     Team, NombreAmonestado, Seleccion, Tarjeta, NombreArbitro, DetallePartido)
SELECT a.Archivo, p.GameId, p.IdPartido, e.Type, JSON_VALUE(st.value, '$.name'),
       e.time,
       TRY_CONVERT(INT, CASE WHEN CHARINDEX(NCHAR(39), CONVERT(NVARCHAR(20), e.time)) > 0
            THEN LEFT(CONVERT(NVARCHAR(20), e.time), CHARINDEX(NCHAR(39), CONVERT(NVARCHAR(20), e.time))-1)
            ELSE CONVERT(NVARCHAR(20), e.time) END),
       CASE WHEN JSON_VALUE(st.value, '$.name')=N'Entretiempo' THEN 1
            WHEN JSON_VALUE(st.value, '$.name')=N'Fin de los 90 minutos' THEN 3
            WHEN JSON_VALUE(st.value, '$.name')=N'Suplementario' THEN
                 CASE WHEN TRY_CONVERT(INT, CASE WHEN CHARINDEX(NCHAR(39), CONVERT(NVARCHAR(20), e.time)) > 0
                      THEN LEFT(CONVERT(NVARCHAR(20), e.time), CHARINDEX(NCHAR(39), CONVERT(NVARCHAR(20), e.time))-1)
                      ELSE CONVERT(NVARCHAR(20), e.time) END) <= 105 THEN 4 ELSE 5 END
            WHEN JSON_VALUE(st.value, '$.name')=N'Penales' THEN 6 END,
       e.team, tx.Texto,
       CASE WHEN e.team=1 THEN p.Eq1 ELSE p.Eq2 END,
       CASE WHEN e.type=6 THEN 'Roja' ELSE 'Amarilla' END,
       (SELECT MIN(g.value) FROM OPENJSON(a.Contenido,'$.game.game_info')
        WITH (name NVARCHAR(100) '$.name', value NVARCHAR(150) '$.value') AS g
        WHERE g.name=NCHAR(193)+'rbitro'), p.Detalle
FROM #ArchivosPartidos AS a
LEFT JOIN #PartidosJson AS p ON p.Archivo=a.Archivo
CROSS APPLY OPENJSON(a.Contenido, '$.game.events') AS st
CROSS APPLY OPENJSON(st.value, '$.rows') WITH (
    Events NVARCHAR(MAX) '$.events' AS JSON
) AS r
CROSS APPLY OPENJSON(r.Events) WITH (
    Type INT '$.type',
    Time NVARCHAR(20) '$.time',
    Team INT '$.team',
    Texts NVARCHAR(MAX) '$.texts' AS JSON
) AS e
CROSS APPLY (SELECT MAX(CASE WHEN c.[key]=0 THEN c.value END) AS Texto
             FROM OPENJSON(e.Texts) AS c) AS tx
WHERE e.type IN (4,6);

IF NOT EXISTS (SELECT 1 FROM #AmonestacionesStaging)
    THROW 51901, 'No se encontraron amonestaciones en los JSON; revise la lectura de archivos.', 1;

---------------------------------------------------------------------------------------
-- FASE 2 - DEPURACION
-- Reglas de conjunto: cada UPDATE marca las filas invalidas y su motivo.
-- No se borra nada; las filas validas quedan en Estado = 'Pendiente'.
---------------------------------------------------------------------------------------

-- D1: el JSON del partido no se pudo resolver.
UPDATE #AmonestacionesStaging SET Estado='Error',
    Detalle=ISNULL(DetallePartido, N'El JSON del partido no se pudo resolver.')
WHERE Estado='Pendiente' AND IdPartido IS NULL;

-- D2: falta el nombre del amonestado.
UPDATE #AmonestacionesStaging SET Estado='Error',
    Detalle=N'El evento no indica a quien se amonesta.'
WHERE Estado='Pendiente' AND NULLIF(NombreAmonestado,N'') IS NULL;

-- D3: el minuto no es un numero.
UPDATE #AmonestacionesStaging SET Estado='Error',
    Detalle=N'El minuto de la amonestacion no se pudo interpretar.'
WHERE Estado='Pendiente' AND Minuto IS NULL;

-- D4: la etapa no se pudo traducir a un periodo.
UPDATE #AmonestacionesStaging SET Estado='Error',
    Detalle=N'La etapa del evento no corresponde a un periodo del catalogo.'
WHERE Estado='Pendiente' AND Periodo IS NULL;

-- D5: la seleccion del amonestado no se pudo determinar.
UPDATE #AmonestacionesStaging SET Estado='Error',
    Detalle=N'No se pudo determinar la seleccion del amonestado.'
WHERE Estado='Pendiente' AND Seleccion IS NULL;

-- Se resuelve el pais de la seleccion y el nombre del amonestado en la base:
-- primero por coincidencia directa y, si no, por el archivo de equivalencias
-- (el JSON de Promiedos y el CSV de jugadores no usan siempre el mismo nombre).
UPDATE #AmonestacionesStaging SET SeleccionPais = p.NOMBRE
FROM #AmonestacionesStaging AS s
JOIN equipos.Seleccion AS se ON se.IdSeleccion = s.Seleccion
JOIN equipos.Pais AS p ON p.IdPais = se.IdPais
WHERE s.Estado='Pendiente';

UPDATE #AmonestacionesStaging SET NombreAmonestadoBd = COALESCE(
    (SELECT TOP (1) pe.Nombre FROM equipos.Persona AS pe
     JOIN equipos.Jugador AS j ON j.IdJugador=pe.IdPersona
     WHERE pe.Nombre = #AmonestacionesStaging.NombreAmonestado AND j.Seleccion = #AmonestacionesStaging.Seleccion),
    (SELECT TOP (1) pe.Nombre FROM equipos.Persona AS pe
     JOIN equipos.Jugador AS j ON j.IdJugador=pe.IdPersona
     WHERE pe.Nombre COLLATE Latin1_General_100_CI_AI = #AmonestacionesStaging.NombreAmonestado COLLATE Latin1_General_100_CI_AI
       AND j.Seleccion = #AmonestacionesStaging.Seleccion),
    (SELECT TOP (1) al.NombreCsv FROM #AliasJugadores AS al
     WHERE al.NombrePromiedos = #AmonestacionesStaging.NombreAmonestado AND al.Habilitado='1'
       AND al.Seleccion = #AmonestacionesStaging.SeleccionPais))
WHERE Estado='Pendiente';

-- D6: el amonestado no esta cargado para esa seleccion (carga 10).
UPDATE #AmonestacionesStaging SET Estado='Error',
    Detalle=N'El amonestado no esta cargado para esa seleccion: ejecute la carga 10.'
WHERE Estado='Pendiente'
  AND (SELECT COUNT(*) FROM equipos.Persona AS pe
       JOIN equipos.Jugador AS j ON j.IdJugador=pe.IdPersona
       WHERE pe.Nombre = ISNULL(#AmonestacionesStaging.NombreAmonestadoBd, #AmonestacionesStaging.NombreAmonestado)
         AND j.Seleccion = #AmonestacionesStaging.Seleccion) = 0;

-- D7: el amonestado es ambiguo dentro de la seleccion.
UPDATE #AmonestacionesStaging SET Estado='Error',
    Detalle=N'El amonestado es ambiguo en la seleccion: revise la carga 10.'
WHERE Estado='Pendiente'
  AND (SELECT COUNT(*) FROM equipos.Persona AS pe
       JOIN equipos.Jugador AS j ON j.IdJugador=pe.IdPersona
       WHERE pe.Nombre = ISNULL(#AmonestacionesStaging.NombreAmonestadoBd, #AmonestacionesStaging.NombreAmonestado)
         AND j.Seleccion = #AmonestacionesStaging.Seleccion) > 1;

-- D8: el arbitro del partido no esta cargado (carga 18).
UPDATE #AmonestacionesStaging SET Estado='Error',
    Detalle=N'El arbitro del partido no esta cargado: ejecute la carga 18.'
WHERE Estado='Pendiente'
  AND (NULLIF(NombreArbitro,N'') IS NULL
    OR (SELECT COUNT(*) FROM arbitros.Arbitro AS ar
        JOIN equipos.Persona AS pe ON pe.IdPersona=ar.IdArbitro
        WHERE pe.Nombre = #AmonestacionesStaging.NombreArbitro) <> 1);

-- Se resuelven los identificadores.
UPDATE #AmonestacionesStaging SET IdJugador = j.IdJugador
FROM #AmonestacionesStaging AS s
JOIN equipos.Persona AS pe ON pe.Nombre = ISNULL(s.NombreAmonestadoBd, s.NombreAmonestado)
JOIN equipos.Jugador AS j ON j.IdJugador = pe.IdPersona AND j.Seleccion = s.Seleccion
WHERE s.Estado='Pendiente';

UPDATE #AmonestacionesStaging SET IdArbitro = ar.IdArbitro
FROM #AmonestacionesStaging AS s
JOIN equipos.Persona AS pe ON pe.Nombre = s.NombreArbitro
JOIN arbitros.Arbitro AS ar ON ar.IdArbitro = pe.IdPersona
WHERE s.Estado='Pendiente';

-- Reporte de la depuracion: se informa ANTES de escribir en la tabla real.
SELECT 'FASE 2 - Depuracion de amonestaciones (antes de la persistencia)' AS Fase;
SELECT Estado, COUNT(*) AS Cantidad FROM #AmonestacionesStaging GROUP BY Estado ORDER BY Estado;
SELECT Fila, GameId, MinutoTexto, Periodo, NombreAmonestado, Tarjeta, NombreArbitro, Estado, Detalle
FROM #AmonestacionesStaging WHERE Estado IN ('Error','Duplicada') ORDER BY Fila;

---------------------------------------------------------------------------------------
-- FASE 3 - PERSISTENCIA
-- Solo las filas que quedaron en 'Pendiente' llegan a la tabla real, siempre
-- a traves de los SP de ABM de la entrega 5.
---------------------------------------------------------------------------------------

DECLARE @fila INT, @idPartido INT, @minuto INT, @periodo INT, @idJugador INT,
        @idArbitro INT, @tarjeta VARCHAR(8), @estado VARCHAR(20);
DECLARE crsAmonestaciones CURSOR LOCAL FAST_FORWARD FOR
    SELECT Fila, IdPartido, Minuto, Periodo, IdJugador, IdArbitro, Tarjeta
    FROM #AmonestacionesStaging WHERE Estado='Pendiente' ORDER BY Fila;
OPEN crsAmonestaciones;
FETCH NEXT FROM crsAmonestaciones INTO @fila, @idPartido, @minuto, @periodo, @idJugador, @idArbitro, @tarjeta;
WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        -- El SP de alta de amonestaciones no valida duplicados: se verifica si
        -- la tarjeta ya esta cargada para que la carga sea idempotente.
        IF EXISTS (SELECT 1 FROM partidos.Amonestacion AS a
                   JOIN partidos.Evento AS e ON e.IdEvento = a.IdAmonestacion
                   WHERE e.Partido = @idPartido AND e.Periodo = @periodo
                     AND e.Minuto = @minuto AND a.Amonestado = @idJugador
                     AND a.Tarjeta = @tarjeta)
        BEGIN
            SET @estado='SinCambios';
        END
        ELSE
        BEGIN
            EXEC SPTRANS.uspAmonestacion_Registrar @minuto=@minuto, @partido=@idPartido,
                @periodo=@periodo, @amonestado=@idJugador, @arbitro=@idArbitro,
                @tarjeta=@tarjeta, @motivo=N'Amonestacion registrada en la fuente del torneo.';
            SET @estado='Insertada';
        END;
    END TRY
    BEGIN CATCH
        SET @estado='Error';
        UPDATE #AmonestacionesStaging SET Estado='Error', Detalle=ERROR_MESSAGE() WHERE Fila=@fila;
    END CATCH;
    IF @estado <> 'Error'
        UPDATE #AmonestacionesStaging SET Estado=@estado WHERE Fila=@fila;
    FETCH NEXT FROM crsAmonestaciones INTO @fila, @idPartido, @minuto, @periodo, @idJugador, @idArbitro, @tarjeta;
END;
CLOSE crsAmonestaciones;
DEALLOCATE crsAmonestaciones;

-- Reporte final de la persistencia.
SELECT 'FASE 3 - Persistencia de amonestaciones' AS Fase;
SELECT Estado, COUNT(*) AS Cantidad FROM #AmonestacionesStaging GROUP BY Estado ORDER BY Estado;
SELECT Fila, GameId, IdPartido, MinutoTexto, Minuto, Periodo, NombreAmonestado, IdJugador,
       Tarjeta, NombreArbitro, IdArbitro, Estado, Detalle
FROM #AmonestacionesStaging ORDER BY Fila;

DECLARE @fallos INT = (SELECT COUNT(*) FROM #AmonestacionesStaging WHERE Estado='Error');
DROP TABLE #AmonestacionesStaging;
IF @fallos > 0
    THROW 51904, 'Importacion parcial: se conservaron las amonestaciones correctas. Revise el detalle.', 1;
GO


