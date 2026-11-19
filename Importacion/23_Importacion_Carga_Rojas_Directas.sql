-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Comision 02
-- Grupo 7: Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 18/11/2026.
-- Objetivo: cargar las TARJETAS ROJAS DIRECTAS, con la metodologia de tres fases.
-- La carga 17 toma los tipos 4 (amarilla) y 6 (segunda amarilla) y deja afuera
-- el tipo 5, que es la roja directa.
--   FASE 1 STAGING     : una fila por roja directa (tipo 5).
--   FASE 2 DEPURACION  : reglas de conjunto (UPDATE) sobre la staging.
--   FASE 3 PERSISTENCIA : solo las filas validas pasan por
--                         SPTRANS.uspAmonestacion_Registrar con Tarjeta='Roja',
--                         que crea el Evento y la Amonestacion y deja al jugador
--                         en estado Suspendido.
--
-- Fuente: los 104 JSON de Promiedos (Datos\Datos_Partidos\partidos).
-- Se observaron 14 rojas directas en 11 partidos. Ninguna de esas personas tiene
-- amarillas previas ni una roja por doble amarilla en el mismo partido, asi que
-- no se superpone con la carga 17 ni con la roja automatica del SP.
--
-- Requiere ejecutar antes las cargas 10 (jugadores), 11 (partidos),
-- 14 (alineaciones) y 15 (arbitrajes): el SP exige que el arbitro sea el
-- principal del partido y que la persona este cargada.
-- No modifica ningun importador existente.
--
-- SSMS: Consulta -> Modo SQLCMD. Ajustar las rutas del servidor SQL.
-- IMPORTANTE: cada integrante debe poner las rutas de su propia PC.
-- :setvar CarpetaPartidos "C:\ruta\proyecto\Datos\Datos_Partidos\partidos"
-- :setvar RutaLecturaJSON "C:\ruta\proyecto\Importacion\11_Lectura_JSON_Partidos.sql"
-- :setvar RutaLecturaPartidos "C:\ruta\proyecto\Importacion\XX_Lectura_Partidos_JSON.sql"
-- :setvar RutaEquipos "C:\ruta\proyecto\Datos\equivalencias_equipos_jugadores.csv"
-- :setvar RutaSedes "C:\ruta\proyecto\Datos\equivalencias_sedes_partidos.csv"
-- :setvar RutaFases "C:\ruta\proyecto\Datos\equivalencias_fases_partidos.csv"
-- :setvar RutaAliasJugadores "C:\ruta\proyecto\Datos\Jugadores\equivalencias_jugadores.csv"

-- Rutas de la maquina actual (ajustar si el proyecto esta en otra carpeta).
:setvar CarpetaPartidos "C:\Users\Administrator\Desktop\tp_bdda\TP-2026-2C-Mundial-de-Futbol\Datos\Datos_Partidos\partidos"
:setvar RutaLecturaJSON "C:\Users\Administrator\Desktop\tp_bdda\TP-2026-2C-Mundial-de-Futbol\Importacion\11_Lectura_JSON_Partidos.sql"
:setvar RutaLecturaPartidos "C:\Users\Administrator\Desktop\tp_bdda\TP-2026-2C-Mundial-de-Futbol\Importacion\XX_Lectura_Partidos_JSON.sql"
:setvar RutaEquipos "C:\Users\Administrator\Desktop\tp_bdda\TP-2026-2C-Mundial-de-Futbol\Datos\equivalencias_equipos_jugadores.csv"
:setvar RutaSedes "C:\Users\Administrator\Desktop\tp_bdda\TP-2026-2C-Mundial-de-Futbol\Datos\equivalencias_sedes_partidos.csv"
:setvar RutaFases "C:\Users\Administrator\Desktop\tp_bdda\TP-2026-2C-Mundial-de-Futbol\Datos\equivalencias_fases_partidos.csv"
:setvar RutaAliasJugadores "C:\Users\Administrator\Desktop\tp_bdda\TP-2026-2C-Mundial-de-Futbol\Datos\Jugadores\equivalencias_jugadores.csv"

USE [MUNDIALtesting];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF @@TRANCOUNT <> 0 OR (2 & @@OPTIONS) = 2
    THROW 51900, 'Ejecute sin transaccion externa y con IMPLICIT_TRANSACTIONS OFF.', 1;
IF OBJECT_ID(N'partidos.Amonestacion', N'U') IS NULL
   OR OBJECT_ID(N'SPTRANS.uspAmonestacion_Registrar', N'P') IS NULL
    THROW 51900, 'Faltan tablas o SP ABM. Ejecute primero el instalador.', 1;

IF OBJECT_ID(N'tempdb..#RojasStaging') IS NOT NULL DROP TABLE #RojasStaging;

-- Lector compartido: deja los JSON crudos, las equivalencias y el partido resuelto.
:r $(RutaLecturaPartidos)

---------------------------------------------------------------------------------------
-- FASE 1 - STAGING
-- Una fila por roja directa (tipo 5 de la fuente).
---------------------------------------------------------------------------------------

CREATE TABLE #RojasStaging (
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

INSERT #RojasStaging
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
       'Roja',
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
WHERE e.type = 5;

IF NOT EXISTS (SELECT 1 FROM #RojasStaging)
    THROW 51901, 'No se encontraron rojas directas en los JSON; revise la lectura de archivos.', 1;

---------------------------------------------------------------------------------------
-- FASE 2 - DEPURACION
-- Reglas de conjunto: cada UPDATE marca las filas invalidas y su motivo.
-- No se borra nada; las filas validas quedan en Estado = 'Pendiente'.
---------------------------------------------------------------------------------------

-- D1: el JSON del partido no se pudo resolver.
UPDATE #RojasStaging SET Estado='Error',
    Detalle=ISNULL(DetallePartido, N'El JSON del partido no se pudo resolver.')
WHERE Estado='Pendiente' AND IdPartido IS NULL;

-- D2: falta el nombre del expulsado.
UPDATE #RojasStaging SET Estado='Error',
    Detalle=N'El evento no indica a quien se expulsa.'
WHERE Estado='Pendiente' AND NULLIF(NombreAmonestado, N'') IS NULL;

-- D3: el minuto no es un numero.
UPDATE #RojasStaging SET Estado='Error',
    Detalle=N'El minuto de la expulsion no se pudo interpretar.'
WHERE Estado='Pendiente' AND Minuto IS NULL;

-- D4: la etapa no se pudo traducir a un periodo.
UPDATE #RojasStaging SET Estado='Error',
    Detalle=N'La etapa del evento no corresponde a un periodo del catalogo.'
WHERE Estado='Pendiente' AND Periodo IS NULL;

-- D5: la seleccion del expulsado no se pudo determinar.
UPDATE #RojasStaging SET Estado='Error',
    Detalle=N'No se pudo determinar la seleccion del expulsado.'
WHERE Estado='Pendiente' AND Seleccion IS NULL;

-- Se resuelve el pais de la seleccion y el nombre del expulsado en la base:
-- primero por coincidencia directa y, si no, por el archivo de equivalencias
-- (el JSON de Promiedos y el CSV de jugadores no usan siempre el mismo nombre).
UPDATE s SET SeleccionPais = p.NOMBRE
FROM #RojasStaging AS s
JOIN equipos.Seleccion AS se ON se.IdSeleccion = s.Seleccion
JOIN equipos.Pais AS p ON p.IdPais = se.IdPais
WHERE s.Estado='Pendiente';

UPDATE #RojasStaging SET NombreAmonestadoBd = COALESCE(
    (SELECT TOP (1) pe.Nombre FROM equipos.Persona AS pe
     JOIN equipos.Jugador AS j ON j.IdJugador=pe.IdPersona
     WHERE pe.Nombre = #RojasStaging.NombreAmonestado AND j.Seleccion = #RojasStaging.Seleccion),
    (SELECT TOP (1) pe.Nombre FROM equipos.Persona AS pe
     JOIN equipos.Jugador AS j ON j.IdJugador=pe.IdPersona
     WHERE pe.Nombre COLLATE Latin1_General_100_CI_AI = #RojasStaging.NombreAmonestado COLLATE Latin1_General_100_CI_AI
       AND j.Seleccion = #RojasStaging.Seleccion),
    (SELECT TOP (1) al.NombreCsv FROM #AliasJugadores AS al
     WHERE al.NombrePromiedos = #RojasStaging.NombreAmonestado AND al.Habilitado='1'
       AND al.Seleccion = #RojasStaging.SeleccionPais))
WHERE Estado='Pendiente';

-- D6: el expulsado no esta cargado para esa seleccion (carga 10).
UPDATE #RojasStaging SET Estado='Error',
    Detalle=N'El expulsado no esta cargado para esa seleccion: ejecute la carga 10.'
WHERE Estado='Pendiente'
  AND (SELECT COUNT(*) FROM equipos.Persona AS pe
       JOIN equipos.Jugador AS j ON j.IdJugador=pe.IdPersona
       WHERE pe.Nombre = ISNULL(#RojasStaging.NombreAmonestadoBd, #RojasStaging.NombreAmonestado)
         AND j.Seleccion = #RojasStaging.Seleccion) = 0;

-- D7: el expulsado es ambiguo dentro de la seleccion.
UPDATE #RojasStaging SET Estado='Error',
    Detalle=N'El expulsado es ambiguo en la seleccion: revise la carga 10.'
WHERE Estado='Pendiente'
  AND (SELECT COUNT(*) FROM equipos.Persona AS pe
       JOIN equipos.Jugador AS j ON j.IdJugador=pe.IdPersona
       WHERE pe.Nombre = ISNULL(#RojasStaging.NombreAmonestadoBd, #RojasStaging.NombreAmonestado)
         AND j.Seleccion = #RojasStaging.Seleccion) > 1;

-- D8: el arbitro del partido no esta cargado (carga 15).
UPDATE #RojasStaging SET Estado='Error',
    Detalle=N'El arbitro del partido no esta cargado: ejecute la carga 15.'
WHERE Estado='Pendiente'
  AND (NULLIF(NombreArbitro, N'') IS NULL
    OR (SELECT COUNT(*) FROM arbitros.Arbitro AS ar
        JOIN equipos.Persona AS pe ON pe.IdPersona=ar.IdArbitro
        WHERE pe.Nombre = #RojasStaging.NombreArbitro) <> 1);

-- Se resuelven los identificadores.
UPDATE s SET IdJugador = j.IdJugador
FROM #RojasStaging AS s
JOIN equipos.Persona AS pe ON pe.Nombre = ISNULL(s.NombreAmonestadoBd, s.NombreAmonestado)
JOIN equipos.Jugador AS j ON j.IdJugador = pe.IdPersona AND j.Seleccion = s.Seleccion
WHERE s.Estado='Pendiente';

UPDATE s SET IdArbitro = ar.IdArbitro
FROM #RojasStaging AS s
JOIN equipos.Persona AS pe ON pe.Nombre = s.NombreArbitro
JOIN arbitros.Arbitro AS ar ON ar.IdArbitro = pe.IdPersona
WHERE s.Estado='Pendiente';

-- D9: la persona ya tiene una roja en ese partido (por ejemplo, la roja por
-- doble amarilla que carga el importador 17, o una roja directa ya importada).
-- Una persona no puede ser expulsada dos veces en el mismo partido.
UPDATE s SET Estado='Duplicada',
    Detalle=N'La persona ya tiene una roja cargada en este partido: revise la carga 17.'
FROM #RojasStaging AS s
WHERE s.Estado='Pendiente' AND EXISTS (
    SELECT 1 FROM partidos.Amonestacion AS a
    JOIN partidos.Evento AS e ON e.IdEvento = a.IdAmonestacion
    WHERE e.Partido = s.IdPartido AND a.Amonestado = s.IdJugador AND a.Tarjeta = 'Roja'
);

-- Reporte de la depuracion: se informa ANTES de escribir en la tabla real.
SELECT 'FASE 2 - Depuracion de rojas directas (antes de la persistencia)' AS Fase;
SELECT Estado, COUNT(*) AS Cantidad FROM #RojasStaging GROUP BY Estado ORDER BY Estado;
SELECT Fila, GameId, MinutoTexto, Periodo, NombreAmonestado, NombreArbitro, Estado, Detalle
FROM #RojasStaging WHERE Estado IN ('Error','Duplicada') ORDER BY Fila;

---------------------------------------------------------------------------------------
-- FASE 3 - PERSISTENCIA
-- Solo las filas que quedaron en 'Pendiente' llegan a la tabla real, siempre
-- a traves de los SP de ABM de la entrega 5.
---------------------------------------------------------------------------------------

DECLARE @fila INT, @idPartido INT, @minuto INT, @periodo INT, @idJugador INT,
        @idArbitro INT, @tarjeta VARCHAR(8), @estado VARCHAR(20);
DECLARE crsRojas CURSOR LOCAL FAST_FORWARD FOR
    SELECT Fila, IdPartido, Minuto, Periodo, IdJugador, IdArbitro, Tarjeta
    FROM #RojasStaging WHERE Estado='Pendiente' ORDER BY Fila;
OPEN crsRojas;
FETCH NEXT FROM crsRojas INTO @fila, @idPartido, @minuto, @periodo, @idJugador, @idArbitro, @tarjeta;
WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        -- El SP de alta de amonestaciones no valida duplicados: se verifica si
        -- la roja ya esta cargada para que la carga sea idempotente.
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
                @tarjeta=@tarjeta, @motivo=N'Roja directa informada por la fuente del torneo.';
            SET @estado='Insertada';
        END;
    END TRY
    BEGIN CATCH
        SET @estado='Error';
        UPDATE #RojasStaging SET Estado='Error', Detalle=ERROR_MESSAGE() WHERE Fila=@fila;
    END CATCH;
    IF @estado <> 'Error'
        UPDATE #RojasStaging SET Estado=@estado WHERE Fila=@fila;
    FETCH NEXT FROM crsRojas INTO @fila, @idPartido, @minuto, @periodo, @idJugador, @idArbitro, @tarjeta;
END;
CLOSE crsRojas;
DEALLOCATE crsRojas;

-- Reporte final de la persistencia.
SELECT 'FASE 3 - Persistencia de rojas directas' AS Fase;
SELECT Estado, COUNT(*) AS Cantidad FROM #RojasStaging GROUP BY Estado ORDER BY Estado;
SELECT Fila, GameId, IdPartido, MinutoTexto, Minuto, Periodo, NombreAmonestado, IdJugador,
       Tarjeta, NombreArbitro, IdArbitro, Estado, Detalle
FROM #RojasStaging ORDER BY Fila;

-- Control: rojas directas cargadas por partido contra las que trae la fuente.
SELECT 'VERIFICACION - Rojas directas cargadas contra la fuente' AS Fase;
SELECT s.GameId, s.IdPartido, s.CantidadFuente,
       (SELECT COUNT(*) FROM partidos.Amonestacion AS a
        JOIN partidos.Evento AS e ON e.IdEvento = a.IdAmonestacion
        WHERE e.Partido = s.IdPartido AND a.Tarjeta = 'Roja'
          AND a.Motivo LIKE N'Roja directa%') AS CantidadCargada,
       CASE WHEN s.CantidadFuente =
                 (SELECT COUNT(*) FROM partidos.Amonestacion AS a
                  JOIN partidos.Evento AS e ON e.IdEvento = a.IdAmonestacion
                  WHERE e.Partido = s.IdPartido AND a.Tarjeta = 'Roja'
                    AND a.Motivo LIKE N'Roja directa%')
            THEN 'OK' ELSE 'DIFERENCIA' END AS Control
FROM (
    SELECT GameId, IdPartido, COUNT(*) AS CantidadFuente
    FROM #RojasStaging WHERE Estado IN ('Insertada','SinCambios')
    GROUP BY GameId, IdPartido
) AS s
ORDER BY s.IdPartido;

DECLARE @fallos INT = (SELECT COUNT(*) FROM #RojasStaging WHERE Estado='Error');
DROP TABLE #RojasStaging;
IF @fallos > 0
    THROW 51904, 'Importacion parcial: se conservaron las rojas directas correctas. Revise el detalle.', 1;
GO
