-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Comision 02
-- Grupo 7: Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 18/11/2026.
-- Objetivo: cargar los goles de PENAL de tiempo regular, con la metodologia de
-- tres fases. La carga 16 solo toma los tipos 1 y 2 (Jugada y En contra) y deja
-- afuera el tipo 3, por eso los marcadores de 15 partidos quedan cortos.
--   FASE 1 STAGING     : una fila por penal convertido fuera de la etapa "Penales".
--   FASE 2 DEPURACION  : reglas de conjunto (UPDATE) sobre la staging.
--   FASE 3 PERSISTENCIA : solo las filas validas pasan por
--                         SPTRANS.uspGol_Registrar con @tipo = 'Penal', que
--                         crea el Evento, el Gol y actualiza GolesEq1/GolesEq2.
--
-- Fuente: los 104 JSON de Promiedos (Datos\Datos_Partidos\partidos).
-- En la fuente el tipo 3 significa "penal convertido". Se observaron 28 en total:
--   - 12 dentro de la etapa "Penales" -> los carga el importador 21 (tanda).
--   - 16 en tiempo regular            -> los carga este importador.
-- Los penales errados de la tanda (tipo 17) no tienen tabla en el modelo.
--
-- Requiere ejecutar antes las cargas 10 (jugadores), 11 (partidos) y
-- 14 (alineaciones): el SP exige que el autor este en cancha.
-- ORDEN: ejecutar este importador ANTES del 21. uspGol_Registrar no permite
-- corregir goles de un partido que ya tiene tanda abierta (PenalesEq1/2).
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
IF OBJECT_ID(N'partidos.Gol', N'U') IS NULL
   OR OBJECT_ID(N'partidos.Partido', N'U') IS NULL
   OR OBJECT_ID(N'SPTRANS.uspGol_Registrar', N'P') IS NULL
    THROW 51900, 'Faltan tablas o SP ABM. Ejecute primero el instalador.', 1;

IF OBJECT_ID(N'tempdb..#PenalesStaging') IS NOT NULL DROP TABLE #PenalesStaging;

-- Lector compartido: deja los JSON crudos, las equivalencias y el partido resuelto.
:r $(RutaLecturaPartidos)

---------------------------------------------------------------------------------------
-- FASE 1 - STAGING
-- Una fila por penal convertido en tiempo regular (tipo 3 fuera de "Penales").
---------------------------------------------------------------------------------------

CREATE TABLE #PenalesStaging (
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
    NombreAutor NVARCHAR(60) COLLATE DATABASE_DEFAULT,
    NombreAutorBd NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    Seleccion INT,
    SeleccionPais NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Tipo VARCHAR(20) COLLATE DATABASE_DEFAULT,
    IdJugador INT,
    DetallePartido NVARCHAR(2048) COLLATE DATABASE_DEFAULT,
    Estado VARCHAR(20) COLLATE DATABASE_DEFAULT NOT NULL DEFAULT 'Pendiente',
    Detalle NVARCHAR(2048) COLLATE DATABASE_DEFAULT
);

INSERT #PenalesStaging
    (Archivo, GameId, IdPartido, TipoEvento, Etapa, MinutoTexto, Minuto, Periodo,
     Team, NombreAutor, Seleccion, Tipo, DetallePartido)
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
       END,
       e.team, tx.Texto,
       CASE WHEN e.team=1 THEN p.Eq1 ELSE p.Eq2 END,
       'Penal', p.Detalle
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
WHERE e.type = 3
  -- La tanda se carga en el importador 21; aca solo el tiempo regular.
  AND COALESCE(JSON_VALUE(st.value, '$.name'), N'') <> N'Penales';

IF NOT EXISTS (SELECT 1 FROM #PenalesStaging)
    THROW 51901, 'No se encontraron goles de penal en los JSON; revise la lectura de archivos.', 1;

---------------------------------------------------------------------------------------
-- FASE 2 - DEPURACION
-- Reglas de conjunto: cada UPDATE marca las filas invalidas y su motivo.
-- No se borra nada; las filas validas quedan en Estado = 'Pendiente'.
---------------------------------------------------------------------------------------

-- D1: el JSON del partido no se pudo resolver.
UPDATE #PenalesStaging SET Estado='Error',
    Detalle=ISNULL(DetallePartido, N'El JSON del partido no se pudo resolver.')
WHERE Estado='Pendiente' AND IdPartido IS NULL;

-- D2: falta el nombre del autor.
UPDATE #PenalesStaging SET Estado='Error',
    Detalle=N'El evento no indica el autor del penal.'
WHERE Estado='Pendiente' AND NULLIF(NombreAutor, N'') IS NULL;

-- D3: el minuto no es un numero.
UPDATE #PenalesStaging SET Estado='Error',
    Detalle=N'El minuto del penal no se pudo interpretar.'
WHERE Estado='Pendiente' AND Minuto IS NULL;

-- D4: la etapa no se pudo traducir a un periodo (o es la tanda).
UPDATE #PenalesStaging SET Estado='Error',
    Detalle=N'La etapa del evento no corresponde a un periodo de tiempo regular.'
WHERE Estado='Pendiente' AND Periodo IS NULL;

-- D5: la seleccion del autor no se pudo determinar.
UPDATE #PenalesStaging SET Estado='Error',
    Detalle=N'No se pudo determinar la seleccion del autor del penal.'
WHERE Estado='Pendiente' AND Seleccion IS NULL;

-- Se resuelve el pais de la seleccion y el nombre del jugador en la base:
-- primero por coincidencia directa y, si no, por el archivo de equivalencias
-- (el JSON de Promiedos y el CSV de jugadores no usan siempre el mismo nombre).
UPDATE s SET SeleccionPais = p.NOMBRE
FROM #PenalesStaging AS s
JOIN equipos.Seleccion AS se ON se.IdSeleccion = s.Seleccion
JOIN equipos.Pais AS p ON p.IdPais = se.IdPais
WHERE s.Estado='Pendiente';

UPDATE #PenalesStaging SET NombreAutorBd = COALESCE(
    (SELECT TOP (1) pe.Nombre FROM equipos.Persona AS pe
     JOIN equipos.Jugador AS j ON j.IdJugador=pe.IdPersona
     WHERE pe.Nombre = #PenalesStaging.NombreAutor AND j.Seleccion = #PenalesStaging.Seleccion),
    (SELECT TOP (1) pe.Nombre FROM equipos.Persona AS pe
     JOIN equipos.Jugador AS j ON j.IdJugador=pe.IdPersona
     WHERE pe.Nombre COLLATE Latin1_General_100_CI_AI = #PenalesStaging.NombreAutor COLLATE Latin1_General_100_CI_AI
       AND j.Seleccion = #PenalesStaging.Seleccion),
    (SELECT TOP (1) al.NombreCsv FROM #AliasJugadores AS al
     WHERE al.NombrePromiedos = #PenalesStaging.NombreAutor AND al.Habilitado='1'
       AND al.Seleccion = #PenalesStaging.SeleccionPais))
WHERE Estado='Pendiente';

-- D6: el autor no esta cargado para esa seleccion (carga 10).
UPDATE #PenalesStaging SET Estado='Error',
    Detalle=N'El autor del penal no esta cargado para esa seleccion: ejecute la carga 10.'
WHERE Estado='Pendiente'
  AND (SELECT COUNT(*) FROM equipos.Persona AS pe
       JOIN equipos.Jugador AS j ON j.IdJugador=pe.IdPersona
       WHERE pe.Nombre = ISNULL(#PenalesStaging.NombreAutorBd, #PenalesStaging.NombreAutor)
         AND j.Seleccion = #PenalesStaging.Seleccion) = 0;

-- D7: el autor es ambiguo dentro de la seleccion.
UPDATE #PenalesStaging SET Estado='Error',
    Detalle=N'El autor del penal es ambiguo en la seleccion: revise la carga 10.'
WHERE Estado='Pendiente'
  AND (SELECT COUNT(*) FROM equipos.Persona AS pe
       JOIN equipos.Jugador AS j ON j.IdJugador=pe.IdPersona
       WHERE pe.Nombre = ISNULL(#PenalesStaging.NombreAutorBd, #PenalesStaging.NombreAutor)
         AND j.Seleccion = #PenalesStaging.Seleccion) > 1;

-- Se resuelve el identificador del autor.
UPDATE s SET IdJugador = j.IdJugador
FROM #PenalesStaging AS s
JOIN equipos.Persona AS pe ON pe.Nombre = ISNULL(s.NombreAutorBd, s.NombreAutor)
JOIN equipos.Jugador AS j ON j.IdJugador = pe.IdPersona AND j.Seleccion = s.Seleccion
WHERE s.Estado='Pendiente';

-- D8: el autor no estaba en la cancha (misma validacion del SP, aqui preventiva).
UPDATE #PenalesStaging SET Estado='Error',
    Detalle=N'El autor del penal no estaba en cancha: revise la carga 14.'
WHERE Estado='Pendiente' AND IdJugador IS NOT NULL
  AND partidos.fnJugadorEnCanchaPeriodo(IdPartido, IdJugador, Minuto, Periodo) = 0;

-- D9: el partido ya tiene tanda cargada. uspGol_Registrar exige anular la
-- tanda antes de corregir goles del partido; por eso este importador va antes
-- que el 21. Si aparece este error, ejecutar primero la carga 21 con Iniciar=0
-- (o revisar el orden de ejecucion).
UPDATE s SET Estado='Error',
    Detalle=N'El partido ya tiene tanda cargada: ejecute la carga 21 despues de los goles de penal.'
FROM #PenalesStaging AS s
JOIN partidos.Partido AS p ON p.IdPartido = s.IdPartido
WHERE s.Estado='Pendiente' AND p.PenalesEq1 IS NOT NULL;

-- Reporte de la depuracion: se informa ANTES de escribir en la tabla real.
SELECT 'FASE 2 - Depuracion de penales (antes de la persistencia)' AS Fase;
SELECT Estado, COUNT(*) AS Cantidad FROM #PenalesStaging GROUP BY Estado ORDER BY Estado;
SELECT Fila, GameId, MinutoTexto, Periodo, NombreAutor, Seleccion, Estado, Detalle
FROM #PenalesStaging WHERE Estado IN ('Error','Duplicada') ORDER BY Fila;

---------------------------------------------------------------------------------------
-- FASE 3 - PERSISTENCIA
-- Solo las filas que quedaron en 'Pendiente' llegan a la tabla real, siempre
-- a traves de los SP de ABM de la entrega 5.
---------------------------------------------------------------------------------------

DECLARE @fila INT, @idPartido INT, @minuto INT, @periodo INT, @idJugador INT,
        @tipo VARCHAR(20), @estado VARCHAR(20);
DECLARE crsPenales CURSOR LOCAL FAST_FORWARD FOR
    SELECT Fila, IdPartido, Minuto, Periodo, IdJugador, Tipo
    FROM #PenalesStaging WHERE Estado='Pendiente' ORDER BY Fila;
OPEN crsPenales;
FETCH NEXT FROM crsPenales INTO @fila, @idPartido, @minuto, @periodo, @idJugador, @tipo;
WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        -- El SP de alta de goles no valida duplicados: se verifica si el penal
        -- ya esta cargado para que la carga sea idempotente.
        IF EXISTS (SELECT 1 FROM partidos.Gol AS g
                   JOIN partidos.Evento AS e ON e.IdEvento = g.IdGol
                   WHERE e.Partido = @idPartido AND e.Periodo = @periodo
                     AND e.Minuto = @minuto AND g.Autor = @idJugador AND g.Tipo = @tipo)
        BEGIN
            SET @estado='SinCambios';
        END
        ELSE
        BEGIN
            EXEC SPTRANS.uspGol_Registrar @minuto=@minuto, @partido=@idPartido,
                @periodo=@periodo, @autor=@idJugador, @asistencia=NULL, @tipo=@tipo;
            SET @estado='Insertada';
        END;
    END TRY
    BEGIN CATCH
        SET @estado='Error';
        UPDATE #PenalesStaging SET Estado='Error', Detalle=ERROR_MESSAGE() WHERE Fila=@fila;
    END CATCH;
    IF @estado <> 'Error'
        UPDATE #PenalesStaging SET Estado=@estado WHERE Fila=@fila;
    FETCH NEXT FROM crsPenales INTO @fila, @idPartido, @minuto, @periodo, @idJugador, @tipo;
END;
CLOSE crsPenales;
DEALLOCATE crsPenales;

-- Reporte final de la persistencia.
SELECT 'FASE 3 - Persistencia de goles de penal' AS Fase;
SELECT Estado, COUNT(*) AS Cantidad FROM #PenalesStaging GROUP BY Estado ORDER BY Estado;
SELECT Fila, GameId, IdPartido, MinutoTexto, Minuto, Periodo, NombreAutor, IdJugador, Tipo, Estado, Detalle
FROM #PenalesStaging ORDER BY Fila;

-- Control: GolesEq1/2 de los partidos tocados contra el marcador de la fuente.
SELECT 'VERIFICACION - Marcador contra la fuente' AS Fase;
SELECT p.IdPartido, p.GolesEq1, p.GolesEq2,
       s.Eq1Fuente, s.Eq2Fuente,
       CASE WHEN p.GolesEq1 = s.Eq1Fuente AND p.GolesEq2 = s.Eq2Fuente
            THEN 'OK' ELSE 'DIFERENCIA' END AS Control
FROM (SELECT DISTINCT IdPartido FROM #PenalesStaging
      WHERE Estado IN ('Insertada','SinCambios')) AS t
JOIN partidos.Partido AS p ON p.IdPartido = t.IdPartido
JOIN (
    SELECT j.IdPartido,
           CONVERT(INT, TRY_CONVERT(DECIMAL(6,1), JSON_VALUE(a.Contenido, '$.game.scores[0]'))) AS Eq1Fuente,
           CONVERT(INT, TRY_CONVERT(DECIMAL(6,1), JSON_VALUE(a.Contenido, '$.game.scores[1]'))) AS Eq2Fuente
    FROM #ArchivosPartidos AS a
    JOIN #PartidosJson AS j ON j.Archivo = a.Archivo
    WHERE j.IdPartido IS NOT NULL
) AS s ON s.IdPartido = p.IdPartido
ORDER BY p.IdPartido;

DECLARE @fallos INT = (SELECT COUNT(*) FROM #PenalesStaging WHERE Estado='Error');
DROP TABLE #PenalesStaging;
IF @fallos > 0
    THROW 51904, 'Importacion parcial: se conservaron los penales correctos. Revise el detalle.', 1;
GO
