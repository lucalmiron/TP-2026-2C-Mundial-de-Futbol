-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Comision 02
-- Grupo 7: Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 13/11/2026.
-- Objetivo: cargar los goles de los 104 JSON de Promiedos con la metodologia
-- de tres fases. Tipos de evento de la fuente: 1 gol, 2 gol en contra.
--   FASE 1 STAGING     : una fila por gol.
--   FASE 2 DEPURACION  : reglas de conjunto (UPDATE) sobre la staging.
--   FASE 3 PERSISTENCIA : solo las filas validas pasan por
--                         SPTRANS.uspGol_Registrar, que crea el Evento y el Gol
--                         y actualiza el marcador del partido.
-- Requiere ejecutar antes las cargas 10 (jugadores), 11 (partidos) y
-- 13 (alineaciones): el SP exige que el autor este en cancha.
-- La tanda de penales (tipos 3 y 17) no se carga aqui: se registra con
-- SP.uspPartido_Tanda, una vez-starter el resultado del partido.
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
IF OBJECT_ID(N'partidos.Gol', N'U') IS NULL
   OR OBJECT_ID(N'SPTRANS.uspGol_Registrar', N'P') IS NULL
    THROW 51900, 'Faltan tablas o SP ABM. Ejecute primero el instalador.', 1;

IF OBJECT_ID(N'tempdb..#GolesStaging') IS NOT NULL DROP TABLE #GolesStaging;

-- Lector compartido: deja los JSON crudos, las equivalencias y el partido resuelto.
:r $(RutaLecturaPartidos)

---------------------------------------------------------------------------------------
-- FASE 1 - STAGING
-- Una fila por evento de gol (tipos 1 y 2 de la fuente).
---------------------------------------------------------------------------------------

CREATE TABLE #GolesStaging (
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

INSERT #GolesStaging
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
            WHEN JSON_VALUE(st.value, '$.name')=N'Penales' THEN 6 END,
       e.team, tx.Texto,
       -- En un gol en contra el equipo indicado es el beneficiario: el autor
       -- pertenece al equipo contrario.
       CASE WHEN e.type=2 THEN CASE WHEN e.team=1 THEN p.Eq2 ELSE p.Eq1 END
            ELSE CASE WHEN e.team=1 THEN p.Eq1 ELSE p.Eq2 END END,
       CASE WHEN e.type=2 THEN 'En contra' ELSE 'Jugada' END, p.Detalle
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
WHERE e.type IN (1,2);

IF NOT EXISTS (SELECT 1 FROM #GolesStaging)
    THROW 51901, 'No se encontraron goles en los JSON; revise la lectura de archivos.', 1;

---------------------------------------------------------------------------------------
-- FASE 2 - DEPURACION
-- Reglas de conjunto: cada UPDATE marca las filas invalidas y su motivo.
-- No se borra nada; las filas validas quedan en Estado = 'Pendiente'.
---------------------------------------------------------------------------------------

-- D1: el JSON del partido no se pudo resolver.
UPDATE #GolesStaging SET Estado='Error',
    Detalle=ISNULL(DetallePartido, N'El JSON del partido no se pudo resolver.')
WHERE Estado='Pendiente' AND IdPartido IS NULL;

-- D2: falta el nombre del autor.
UPDATE #GolesStaging SET Estado='Error',
    Detalle=N'El evento no indica el autor del gol.'
WHERE Estado='Pendiente' AND NULLIF(NombreAutor,N'') IS NULL;

-- D3: el minuto no es un numero.
UPDATE #GolesStaging SET Estado='Error',
    Detalle=N'El minuto del gol no se pudo interpretar.'
WHERE Estado='Pendiente' AND Minuto IS NULL;

-- D4: la etapa no se pudo traducir a un periodo.
UPDATE #GolesStaging SET Estado='Error',
    Detalle=N'La etapa del evento no corresponde a un periodo del catalogo.'
WHERE Estado='Pendiente' AND Periodo IS NULL;

-- D5: la seleccion del autor no se pudo determinar.
UPDATE #GolesStaging SET Estado='Error',
    Detalle=N'No se pudo determinar la seleccion del autor del gol.'
WHERE Estado='Pendiente' AND Seleccion IS NULL;

-- Se resuelve el pais de la seleccion y el nombre del jugador en la base:
-- primero por coincidencia directa y, si no, por el archivo de equivalencias
-- (el JSON de Promiedos y el CSV de jugadores no usan siempre el mismo nombre).
UPDATE #GolesStaging SET SeleccionPais = p.NOMBRE
FROM #GolesStaging AS s
JOIN equipos.Seleccion AS se ON se.IdSeleccion = s.Seleccion
JOIN equipos.Pais AS p ON p.IdPais = se.IdPais
WHERE s.Estado='Pendiente';

UPDATE #GolesStaging SET NombreAutorBd = COALESCE(
    (SELECT TOP (1) pe.Nombre FROM equipos.Persona AS pe
     JOIN equipos.Jugador AS j ON j.IdJugador=pe.IdPersona
     WHERE pe.Nombre = #GolesStaging.NombreAutor AND j.Seleccion = #GolesStaging.Seleccion),
    (SELECT TOP (1) pe.Nombre FROM equipos.Persona AS pe
     JOIN equipos.Jugador AS j ON j.IdJugador=pe.IdPersona
     WHERE pe.Nombre COLLATE Latin1_General_100_CI_AI = #GolesStaging.NombreAutor COLLATE Latin1_General_100_CI_AI
       AND j.Seleccion = #GolesStaging.Seleccion),
    (SELECT TOP (1) al.NombreCsv FROM #AliasJugadores AS al
     WHERE al.NombrePromiedos = #GolesStaging.NombreAutor AND al.Habilitado='1'
       AND al.Seleccion = #GolesStaging.SeleccionPais))
WHERE Estado='Pendiente';

-- D6: el autor no esta cargado para esa seleccion (carga 10).
UPDATE #GolesStaging SET Estado='Error',
    Detalle=N'El autor del gol no esta cargado para esa seleccion: ejecute la carga 10.'
WHERE Estado='Pendiente'
  AND (SELECT COUNT(*) FROM equipos.Persona AS pe
       JOIN equipos.Jugador AS j ON j.IdJugador=pe.IdPersona
       WHERE pe.Nombre = ISNULL(#GolesStaging.NombreAutorBd, #GolesStaging.NombreAutor)
         AND j.Seleccion = #GolesStaging.Seleccion) = 0;

-- D7: el autor es ambiguo dentro de la seleccion.
UPDATE #GolesStaging SET Estado='Error',
    Detalle=N'El autor del gol es ambiguo en la seleccion: revise la carga 10.'
WHERE Estado='Pendiente'
  AND (SELECT COUNT(*) FROM equipos.Persona AS pe
       JOIN equipos.Jugador AS j ON j.IdJugador=pe.IdPersona
       WHERE pe.Nombre = ISNULL(#GolesStaging.NombreAutorBd, #GolesStaging.NombreAutor)
         AND j.Seleccion = #GolesStaging.Seleccion) > 1;

-- Se resuelve el identificador del autor.
UPDATE #GolesStaging SET IdJugador = j.IdJugador
FROM #GolesStaging AS s
JOIN equipos.Persona AS pe ON pe.Nombre = ISNULL(s.NombreAutorBd, s.NombreAutor)
JOIN equipos.Jugador AS j ON j.IdJugador = pe.IdPersona AND j.Seleccion = s.Seleccion
WHERE s.Estado='Pendiente';

-- D8: el autor no estaba en la cancha (misma validacion del SP, aqui preventiva).
UPDATE #GolesStaging SET Estado='Error',
    Detalle=N'El autor del gol no estaba en cancha: revise la carga 13.'
WHERE Estado='Pendiente' AND IdJugador IS NOT NULL
  AND partidos.fnJugadorEnCanchaPeriodo(IdPartido, IdJugador, ISNULL(Minuto,2147483647), Periodo) = 0;

-- Reporte de la depuracion: se informa ANTES de escribir en la tabla real.
SELECT 'FASE 2 - Depuracion de goles (antes de la persistencia)' AS Fase;
SELECT Estado, COUNT(*) AS Cantidad FROM #GolesStaging GROUP BY Estado ORDER BY Estado;
SELECT Fila, GameId, MinutoTexto, Periodo, NombreAutor, Seleccion, Tipo, Estado, Detalle
FROM #GolesStaging WHERE Estado IN ('Error','Duplicada') ORDER BY Fila;

---------------------------------------------------------------------------------------
-- FASE 3 - PERSISTENCIA
-- Solo las filas que quedaron en 'Pendiente' llegan a la tabla real, siempre
-- a traves de los SP de ABM de la entrega 5.
---------------------------------------------------------------------------------------

DECLARE @fila INT, @idPartido INT, @minuto INT, @periodo INT, @idJugador INT,
        @tipo VARCHAR(20), @estado VARCHAR(20);
DECLARE crsGoles CURSOR LOCAL FAST_FORWARD FOR
    SELECT Fila, IdPartido, Minuto, Periodo, IdJugador, Tipo
    FROM #GolesStaging WHERE Estado='Pendiente' ORDER BY Fila;
OPEN crsGoles;
FETCH NEXT FROM crsGoles INTO @fila, @idPartido, @minuto, @periodo, @idJugador, @tipo;
WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        -- El SP de alta de goles no valida duplicados: se verifica si el gol ya
        -- esta cargado para que la carga sea idempotente.
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
        UPDATE #GolesStaging SET Estado='Error', Detalle=ERROR_MESSAGE() WHERE Fila=@fila;
    END CATCH;
    IF @estado <> 'Error'
        UPDATE #GolesStaging SET Estado=@estado WHERE Fila=@fila;
    FETCH NEXT FROM crsGoles INTO @fila, @idPartido, @minuto, @periodo, @idJugador, @tipo;
END;
CLOSE crsGoles;
DEALLOCATE crsGoles;

-- Reporte final de la persistencia.
SELECT 'FASE 3 - Persistencia de goles' AS Fase;
SELECT Estado, COUNT(*) AS Cantidad FROM #GolesStaging GROUP BY Estado ORDER BY Estado;
SELECT Fila, GameId, IdPartido, MinutoTexto, Minuto, Periodo, NombreAutor, IdJugador, Tipo, Estado, Detalle
FROM #GolesStaging ORDER BY Fila;

DECLARE @fallos INT = (SELECT COUNT(*) FROM #GolesStaging WHERE Estado='Error');
DROP TABLE #GolesStaging;
IF @fallos > 0
    THROW 51904, 'Importacion parcial: se conservaron los goles correctos. Revise el detalle.', 1;
GO


