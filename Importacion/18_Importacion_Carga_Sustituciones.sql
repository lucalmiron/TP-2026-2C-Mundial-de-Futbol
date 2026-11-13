-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Comision 02
-- Grupo 7: Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 13/11/2026.
-- Objetivo: cargar las sustituciones de los 104 JSON de Promiedos con la
-- metodologia de tres fases. Tipo de evento de la fuente: 15.
-- En la fuente, texts[0] es el jugador que entra (estaba en el banco) y
-- texts[1] el que sale (estaba en la titular).
-- La fuente no indica el motivo del cambio: se usa el motivo 'Tactica' del
-- catalogo de la carga 19 y queda anotado en el reporte.
--   FASE 1 STAGING     : una fila por sustitucion.
--   FASE 2 DEPURACION  : reglas de conjunto (UPDATE) sobre la staging.
--   FASE 3 PERSISTENCIA : solo las filas validas pasan por
--                         SPTRANS.uspSustitucion_Registrar.
-- Requiere ejecutar antes las cargas 10 (jugadores), 11 (partidos),
-- 13 (alineaciones) y 19 (motivos).
-- SSMS: Consulta -> Modo SQLCMD. Ajustar las rutas del servidor SQL.
-- IMPORTANTE: cada integrante debe poner las rutas de su propia PC.
-- :setvar CarpetaPartidos "C:\ruta\proyecto\Datos\Datos_Partidos\partidos"
-- :setvar RutaLecturaJSON "C:\ruta\proyecto\Importacion\11_Lectura_JSON_Partidos.sql"
-- :setvar RutaLecturaPartidos "C:\ruta\proyecto\Importacion\XX_Lectura_Partidos_JSON.sql"
-- :setvar RutaEquipos "C:\ruta\proyecto\Datos\equivalencias_equipos_jugadores.csv"
-- :setvar RutaSedes "C:\ruta\proyecto\Datos\equivalencias_sedes_partidos.csv"
-- :setvar RutaFases "C:\ruta\proyecto\Datos\equivalencias_fases_partidos.csv"
-- :setvar RutaAliasJugadores "C:\ruta\proyecto\Datos\Jugadores\equivalencias_jugadores.csv"

--L
:setvar CarpetaPartidos "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Datos\Datos_Partidos\partidos"
:setvar RutaLecturaJSON "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Importacion\11_Lectura_JSON_Partidos.sql"
:setvar RutaLecturaPartidos "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Importacion\XX_Lectura_Partidos_JSON.sql"
:setvar RutaEquipos "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Datos\equivalencias_equipos_jugadores.csv"
:setvar RutaSedes "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Datos\equivalencias_sedes_partidos.csv"
:setvar RutaFases "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Datos\equivalencias_fases_partidos.csv"
:setvar RutaAliasJugadores "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Datos\Jugadores\equivalencias_jugadores.csv"

--Fidel
--:setvar CarpetaPartidos "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Datos\Datos_Partidos\partidos"
--:setvar RutaLecturaJSON "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Importacion\11_Lectura_JSON_Partidos.sql"
--:setvar RutaLecturaPartidos "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Importacion\XX_Lectura_Partidos_JSON.sql"
--:setvar RutaEquipos "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Datos\equivalencias_equipos_jugadores.csv"
--:setvar RutaSedes "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Datos\equivalencias_sedes_partidos.csv"
--:setvar RutaFases "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Datos\equivalencias_fases_partidos.csv"
--:setvar RutaAliasJugadores "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Datos\Jugadores\equivalencias_jugadores.csv"


USE [MUNDIALtesting];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF @@TRANCOUNT <> 0 OR (2 & @@OPTIONS) = 2
    THROW 51900, 'Ejecute sin transaccion externa y con IMPLICIT_TRANSACTIONS OFF.', 1;
IF OBJECT_ID(N'partidos.Sustitucion', N'U') IS NULL
   OR OBJECT_ID(N'SPTRANS.uspSustitucion_Registrar', N'P') IS NULL
    THROW 51900, 'Faltan tablas o SP ABM. Ejecute primero el instalador.', 1;

IF OBJECT_ID(N'tempdb..#SustitucionesStaging') IS NOT NULL DROP TABLE #SustitucionesStaging;

-- Lector compartido: deja los JSON crudos, las equivalencias y el partido resuelto.
:r $(RutaLecturaPartidos)

---------------------------------------------------------------------------------------
-- FASE 1 - STAGING
-- Una fila por sustitucion (tipo 15 de la fuente).
---------------------------------------------------------------------------------------

CREATE TABLE #SustitucionesStaging (
    Fila INT IDENTITY(1,1) PRIMARY KEY,
    Archivo NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    GameId NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    IdPartido INT,
    Etapa NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    MinutoTexto NVARCHAR(20) COLLATE DATABASE_DEFAULT,
    Minuto INT,
    Periodo INT,
    Team INT,
    NombreIngreso NVARCHAR(60) COLLATE DATABASE_DEFAULT,
    NombreIngresoBd NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    NombreEgreso NVARCHAR(60) COLLATE DATABASE_DEFAULT,
    NombreEgresoBd NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    Seleccion INT,
    SeleccionPais NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    IdIngreso INT,
    IdEgreso INT,
    IdMotivo INT,
    DetallePartido NVARCHAR(2048) COLLATE DATABASE_DEFAULT,
    Estado VARCHAR(20) COLLATE DATABASE_DEFAULT NOT NULL DEFAULT 'Pendiente',
    Detalle NVARCHAR(2048) COLLATE DATABASE_DEFAULT
);

INSERT #SustitucionesStaging
    (Archivo, GameId, IdPartido, Etapa, MinutoTexto, Minuto, Periodo, Team,
     NombreIngreso, NombreEgreso, Seleccion, DetallePartido)
SELECT a.Archivo, p.GameId, p.IdPartido, JSON_VALUE(st.value, '$.name'),
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
       e.team, tx.Texto0, tx.Texto1,
       CASE WHEN e.team=1 THEN p.Eq1 ELSE p.Eq2 END, p.Detalle
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
CROSS APPLY (SELECT MAX(CASE WHEN c.[key]=0 THEN c.value END) AS Texto0,
                    MAX(CASE WHEN c.[key]=1 THEN c.value END) AS Texto1
             FROM OPENJSON(e.Texts) AS c) AS tx
WHERE e.type = 15;

IF NOT EXISTS (SELECT 1 FROM #SustitucionesStaging)
    THROW 51901, 'No se encontraron sustituciones en los JSON; revise la lectura de archivos.', 1;

---------------------------------------------------------------------------------------
-- FASE 2 - DEPURACION
-- Reglas de conjunto: cada UPDATE marca las filas invalidas y su motivo.
-- No se borra nada; las filas validas quedan en Estado = 'Pendiente'.
---------------------------------------------------------------------------------------

-- D1: el JSON del partido no se pudo resolver.
UPDATE #SustitucionesStaging SET Estado='Error',
    Detalle=ISNULL(DetallePartido, N'El JSON del partido no se pudo resolver.')
WHERE Estado='Pendiente' AND IdPartido IS NULL;

-- D2: falta el jugador que entra o el que sale.
UPDATE #SustitucionesStaging SET Estado='Error',
    Detalle=N'La sustitucion no indica el ingreso o el egreso.'
WHERE Estado='Pendiente'
  AND (NULLIF(NombreIngreso,N'') IS NULL OR NULLIF(NombreEgreso,N'') IS NULL);

-- D3: el minuto no es un numero.
UPDATE #SustitucionesStaging SET Estado='Error',
    Detalle=N'El minuto de la sustitucion no se pudo interpretar.'
WHERE Estado='Pendiente' AND Minuto IS NULL;

-- D4: la etapa no se pudo traducir a un periodo.
UPDATE #SustitucionesStaging SET Estado='Error',
    Detalle=N'La etapa del evento no corresponde a un periodo del catalogo.'
WHERE Estado='Pendiente' AND Periodo IS NULL;

-- D5: la seleccion del equipo no se pudo determinar.
UPDATE #SustitucionesStaging SET Estado='Error',
    Detalle=N'No se pudo determinar la seleccion del equipo.'
WHERE Estado='Pendiente' AND Seleccion IS NULL;

-- D6: el catalogo de motivos no esta cargado (carga 19).
UPDATE #SustitucionesStaging SET Estado='Error',
    Detalle=N'El catalogo de motivos no esta cargado: ejecute la carga 19.'
WHERE Estado='Pendiente'
  AND (SELECT COUNT(*) FROM publicidad.Motivo WHERE Descripcion=N'T'+NCHAR(225)+'ctica') <> 1;

-- Se resuelve el pais de la seleccion y el nombre del jugador en la base:
-- primero por coincidencia directa y, si no, por el archivo de equivalencias
-- (el JSON de Promiedos y el CSV de jugadores no usan siempre el mismo nombre).
UPDATE #SustitucionesStaging SET SeleccionPais = p.NOMBRE
FROM #SustitucionesStaging AS s
JOIN equipos.Seleccion AS se ON se.IdSeleccion = s.Seleccion
JOIN equipos.Pais AS p ON p.IdPais = se.IdPais
WHERE s.Estado='Pendiente';

UPDATE #SustitucionesStaging SET NombreIngresoBd = COALESCE(
    (SELECT TOP (1) pe.Nombre FROM equipos.Persona AS pe
     JOIN equipos.Jugador AS j ON j.IdJugador=pe.IdPersona
     WHERE pe.Nombre = #SustitucionesStaging.NombreIngreso AND j.Seleccion = #SustitucionesStaging.Seleccion),
    (SELECT TOP (1) pe.Nombre FROM equipos.Persona AS pe
     JOIN equipos.Jugador AS j ON j.IdJugador=pe.IdPersona
     WHERE pe.Nombre COLLATE Latin1_General_100_CI_AI = #SustitucionesStaging.NombreIngreso COLLATE Latin1_General_100_CI_AI
       AND j.Seleccion = #SustitucionesStaging.Seleccion),
    (SELECT TOP (1) al.NombreCsv FROM #AliasJugadores AS al
     WHERE al.NombrePromiedos = #SustitucionesStaging.NombreIngreso AND al.Habilitado='1'
       AND al.Seleccion = #SustitucionesStaging.SeleccionPais))
WHERE Estado='Pendiente';

UPDATE #SustitucionesStaging SET NombreEgresoBd = COALESCE(
    (SELECT TOP (1) pe.Nombre FROM equipos.Persona AS pe
     JOIN equipos.Jugador AS j ON j.IdJugador=pe.IdPersona
     WHERE pe.Nombre = #SustitucionesStaging.NombreEgreso AND j.Seleccion = #SustitucionesStaging.Seleccion),
    (SELECT TOP (1) pe.Nombre FROM equipos.Persona AS pe
     JOIN equipos.Jugador AS j ON j.IdJugador=pe.IdPersona
     WHERE pe.Nombre COLLATE Latin1_General_100_CI_AI = #SustitucionesStaging.NombreEgreso COLLATE Latin1_General_100_CI_AI
       AND j.Seleccion = #SustitucionesStaging.Seleccion),
    (SELECT TOP (1) al.NombreCsv FROM #AliasJugadores AS al
     WHERE al.NombrePromiedos = #SustitucionesStaging.NombreEgreso AND al.Habilitado='1'
       AND al.Seleccion = #SustitucionesStaging.SeleccionPais))
WHERE Estado='Pendiente';

-- D7: el jugador que entra no esta cargado para esa seleccion (carga 10).
UPDATE #SustitucionesStaging SET Estado='Error',
    Detalle=N'El jugador que entra no esta cargado para esa seleccion: ejecute la carga 10.'
WHERE Estado='Pendiente'
  AND (SELECT COUNT(*) FROM equipos.Persona AS pe
       JOIN equipos.Jugador AS j ON j.IdJugador=pe.IdPersona
       WHERE pe.Nombre = ISNULL(#SustitucionesStaging.NombreIngresoBd, #SustitucionesStaging.NombreIngreso)
         AND j.Seleccion = #SustitucionesStaging.Seleccion) = 0;

-- D8: el jugador que sale no esta cargado para esa seleccion.
UPDATE #SustitucionesStaging SET Estado='Error',
    Detalle=N'El jugador que sale no esta cargado para esa seleccion: ejecute la carga 10.'
WHERE Estado='Pendiente'
  AND (SELECT COUNT(*) FROM equipos.Persona AS pe
       JOIN equipos.Jugador AS j ON j.IdJugador=pe.IdPersona
       WHERE pe.Nombre = ISNULL(#SustitucionesStaging.NombreEgresoBd, #SustitucionesStaging.NombreEgreso)
         AND j.Seleccion = #SustitucionesStaging.Seleccion) = 0;

-- D9: alguno de los dos jugadores es ambiguo en la seleccion.
UPDATE #SustitucionesStaging SET Estado='Error',
    Detalle=N'Alguno de los jugadores es ambiguo en la seleccion: revise la carga 10.'
WHERE Estado='Pendiente'
  AND ((SELECT COUNT(*) FROM equipos.Persona AS pe
        JOIN equipos.Jugador AS j ON j.IdJugador=pe.IdPersona
        WHERE pe.Nombre = ISNULL(#SustitucionesStaging.NombreIngresoBd, #SustitucionesStaging.NombreIngreso)
          AND j.Seleccion = #SustitucionesStaging.Seleccion) > 1
    OR (SELECT COUNT(*) FROM equipos.Persona AS pe
        JOIN equipos.Jugador AS j ON j.IdJugador=pe.IdPersona
        WHERE pe.Nombre = ISNULL(#SustitucionesStaging.NombreEgresoBd, #SustitucionesStaging.NombreEgreso)
          AND j.Seleccion = #SustitucionesStaging.Seleccion) > 1);

-- D10: el mismo cambio aparece dos veces en el partido.
UPDATE f SET Estado='Duplicada', Detalle=N'La sustitucion ya aparece en este partido.'
FROM #SustitucionesStaging AS f
WHERE f.Estado='Pendiente' AND EXISTS (
    SELECT 1 FROM #SustitucionesStaging AS o
    WHERE o.IdPartido=f.IdPartido AND o.NombreIngreso=f.NombreIngreso
      AND o.NombreEgreso=f.NombreEgreso AND o.Fila<f.Fila
);

-- Se resuelven los identificadores.
UPDATE #SustitucionesStaging SET IdIngreso = j.IdJugador
FROM #SustitucionesStaging AS s
JOIN equipos.Persona AS pe ON pe.Nombre = ISNULL(s.NombreIngresoBd, s.NombreIngreso)
JOIN equipos.Jugador AS j ON j.IdJugador = pe.IdPersona AND j.Seleccion = s.Seleccion
WHERE s.Estado='Pendiente';

UPDATE #SustitucionesStaging SET IdEgreso = j.IdJugador
FROM #SustitucionesStaging AS s
JOIN equipos.Persona AS pe ON pe.Nombre = ISNULL(s.NombreEgresoBd, s.NombreEgreso)
JOIN equipos.Jugador AS j ON j.IdJugador = pe.IdPersona AND j.Seleccion = s.Seleccion
WHERE s.Estado='Pendiente';

UPDATE #SustitucionesStaging SET IdMotivo = m.IdMotivo
FROM #SustitucionesStaging AS s
JOIN publicidad.Motivo AS m ON m.Descripcion = N'T'+NCHAR(225)+'ctica'
WHERE s.Estado='Pendiente';

-- Reporte de la depuracion: se informa ANTES de escribir en la tabla real.
SELECT 'FASE 2 - Depuracion de sustituciones (antes de la persistencia)' AS Fase;
SELECT Estado, COUNT(*) AS Cantidad FROM #SustitucionesStaging GROUP BY Estado ORDER BY Estado;
SELECT Fila, GameId, MinutoTexto, Periodo, NombreIngreso, NombreEgreso, Estado, Detalle
FROM #SustitucionesStaging WHERE Estado IN ('Error','Duplicada') ORDER BY Fila;

---------------------------------------------------------------------------------------
-- FASE 3 - PERSISTENCIA
-- Solo las filas que quedaron en 'Pendiente' llegan a la tabla real, siempre
-- a traves de los SP de ABM de la entrega 5.
---------------------------------------------------------------------------------------

DECLARE @fila INT, @idPartido INT, @minuto INT, @periodo INT,
        @idIngreso INT, @idEgreso INT, @idMotivo INT, @estado VARCHAR(20);
DECLARE crsSustituciones CURSOR LOCAL FAST_FORWARD FOR
    -- El SP exige registrar los cambios en orden de minuto y periodo: se procesa
    -- partido por partido y de forma cronologica (el momento del evento es
    -- minuto * 10 + orden del periodo).
    SELECT Fila, IdPartido, Minuto, Periodo, IdIngreso, IdEgreso, IdMotivo
    FROM #SustitucionesStaging WHERE Estado='Pendiente'
    ORDER BY IdPartido, Minuto, Periodo, Fila;
OPEN crsSustituciones;
FETCH NEXT FROM crsSustituciones INTO @fila, @idPartido, @minuto, @periodo, @idIngreso, @idEgreso, @idMotivo;
WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        -- El SP de alta de sustituciones no distingue "ya cargado" de "error":
        -- se verifica si el cambio ya esta cargado para que la carga sea
        -- idempotente y no reporte falsos errores en la segunda corrida.
        IF EXISTS (SELECT 1 FROM partidos.Sustitucion AS S
                   JOIN partidos.Evento AS E ON E.IdEvento = S.IdSustitucion
                   WHERE E.Partido = @idPartido AND S.Ingreso = @idIngreso AND S.Egreso = @idEgreso)
        BEGIN
            SET @estado='SinCambios';
        END
        ELSE
        BEGIN
            EXEC SPTRANS.uspSustitucion_Registrar @minuto=@minuto, @partido=@idPartido,
                @periodo=@periodo, @ingreso=@idIngreso, @egreso=@idEgreso, @motivo=@idMotivo;
            SET @estado='Insertada';
        END;
    END TRY
    BEGIN CATCH
        SET @estado='Error';
        UPDATE #SustitucionesStaging SET Estado='Error', Detalle=ERROR_MESSAGE() WHERE Fila=@fila;
    END CATCH;
    IF @estado <> 'Error'
        UPDATE #SustitucionesStaging SET Estado=@estado WHERE Fila=@fila;
    FETCH NEXT FROM crsSustituciones INTO @fila, @idPartido, @minuto, @periodo, @idIngreso, @idEgreso, @idMotivo;
END;
CLOSE crsSustituciones;
DEALLOCATE crsSustituciones;

-- Reporte final de la persistencia.
SELECT 'FASE 3 - Persistencia de sustituciones' AS Fase;
SELECT Estado, COUNT(*) AS Cantidad FROM #SustitucionesStaging GROUP BY Estado ORDER BY Estado;
SELECT Fila, GameId, IdPartido, MinutoTexto, Minuto, Periodo, NombreIngreso, IdIngreso,
       NombreEgreso, IdEgreso, IdMotivo, Estado, Detalle
FROM #SustitucionesStaging ORDER BY Fila;

DECLARE @fallos INT = (SELECT COUNT(*) FROM #SustitucionesStaging WHERE Estado='Error');
DROP TABLE #SustitucionesStaging;
IF @fallos > 0
    THROW 51904, 'Importacion parcial: se conservaron las sustituciones correctas. Revise el detalle.', 1;
GO


