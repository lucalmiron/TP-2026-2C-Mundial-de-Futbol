-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Comision 02
-- Grupo 7: Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 18/11/2026.
-- ORDEN: ejecutar despues de la carga 18 (sustituciones): el SP valida que el autor
-- este en cancha y un suplente solo esta en cancha si su ingreso ya fue cargado.
-- Objetivo: cargar los goles de los 104 JSON de Promiedos con la metodologia
-- de tres fases. Tipos de evento de la fuente: 1 gol, 2 gol en contra.
-- La ASISTENCIA del gol viene en el mismo evento, en texts[1] (texts[0] es el
-- autor). De los 278 goles de jugada, 228 traen asistente; los 14 goles en
-- contra no llevan asistencia. Se verifico contra las alineaciones que los 228
-- asistentes son jugadores convocados de su equipo y estaban en cancha en el
-- minuto del gol, asi que en una carga limpia se cargan las 228.
-- Es un dato OPCIONAL: si no se puede resolver, el gol se carga igual con
-- Asistencia NULL y queda el aviso en la staging.
--   FASE 1 STAGING     : una fila por gol, con autor y asistente informados.
--   FASE 2 DEPURACION  : reglas de conjunto (UPDATE) sobre la staging.
--   FASE 3 PERSISTENCIA : solo las filas validas pasan por
--                         SPTRANS.uspGol_Registrar, que crea el Evento y el Gol
--                         y actualiza el marcador del partido.
-- Requiere ejecutar antes las cargas 10 (jugadores), 11 (partidos) y
-- 14 (alineaciones): el SP exige que el autor y el asistente esten en cancha.
-- La tanda de penales (tipos 3, 16 y 17) no se carga aqui: la tanda se registra
-- con SP.uspPartido_Tanda (carga 21) y los penales de tiempo regular con la
-- carga 22.
-- No existe SP de modificacion de goles (solo uspGol_Registrar y uspGol_Bajar):
-- si los goles ya estaban cargados sin asistencia, hay que darlos de baja y
-- volver a ejecutar esta carga. El importador lo informa, no lo hace solo.
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
--:setvar CarpetaPartidos "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Datos\Datos_Partidos\partidos"
--:setvar RutaLecturaJSON "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Importacion\11_Lectura_JSON_Partidos.sql"
--:setvar RutaLecturaPartidos "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Importacion\XX_Lectura_Partidos_JSON.sql"
--:setvar RutaEquipos "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Datos\equivalencias_equipos_jugadores.csv"
--:setvar RutaSedes "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Datos\equivalencias_sedes_partidos.csv"
--:setvar RutaFases "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Datos\equivalencias_fases_partidos.csv"
--:setvar RutaAliasJugadores "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Datos\Jugadores\equivalencias_jugadores.csv"

--Fidel
:setvar CarpetaPartidos "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Datos\Datos_Partidos\partidos"
:setvar RutaLecturaJSON "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Importacion\11_Lectura_JSON_Partidos.sql"
:setvar RutaLecturaPartidos "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Importacion\XX_Lectura_Partidos_JSON.sql"
:setvar RutaEquipos "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Datos\equivalencias_equipos_jugadores.csv"
:setvar RutaSedes "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Datos\equivalencias_sedes_partidos.csv"
:setvar RutaFases "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Datos\equivalencias_fases_partidos.csv"
:setvar RutaAliasJugadores "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Datos\Jugadores\equivalencias_jugadores.csv"


USE MUNDIAL;
GO
-- Entrega 8: equipos.Persona.Nombre esta cifrado; se lee con DECRYPTBYKEYAUTOCERT.
-- No depende de que la clave este abierta en la sesion (los SP de ABM la cierran).
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
    NombreAsistencia NVARCHAR(60) COLLATE DATABASE_DEFAULT,
    NombreAsistenciaBd NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    Seleccion INT,
    SeleccionPais NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Tipo VARCHAR(20) COLLATE DATABASE_DEFAULT,
    IdJugador INT,
    IdAsistencia INT,
    DetallePartido NVARCHAR(2048) COLLATE DATABASE_DEFAULT,
    Estado VARCHAR(20) COLLATE DATABASE_DEFAULT NOT NULL DEFAULT 'Pendiente',
    Detalle NVARCHAR(2048) COLLATE DATABASE_DEFAULT,
    -- Aviso: la asistencia no se pudo cargar pero el gol si. No es un error.
    Aviso NVARCHAR(300) COLLATE DATABASE_DEFAULT
);

INSERT #GolesStaging
    (Archivo, GameId, IdPartido, TipoEvento, Etapa, MinutoTexto, Minuto, Periodo,
     Team, NombreAutor, NombreAsistencia, Seleccion, Tipo, DetallePartido)
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
       e.team, tx.Texto, tx.Texto2,
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
CROSS APPLY (SELECT MAX(CASE WHEN c.[key]=0 THEN c.value END) AS Texto,
                    -- texts[1] es el asistente; puede no venir.
                    MAX(CASE WHEN c.[key]=1 THEN c.value END) AS Texto2
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
    (SELECT TOP (1) CONVERT(NVARCHAR(30), DECRYPTBYKEYAUTOCERT(CERT_ID(N'CertificadoCifradoMundial'), N'ClaveMaestra_Mundial_2026!', pe.Nombre)) FROM equipos.Persona AS pe
     JOIN equipos.Jugador AS j ON j.IdJugador=pe.IdPersona
     WHERE CONVERT(NVARCHAR(30), DECRYPTBYKEYAUTOCERT(CERT_ID(N'CertificadoCifradoMundial'), N'ClaveMaestra_Mundial_2026!', pe.Nombre)) = #GolesStaging.NombreAutor AND j.Seleccion = #GolesStaging.Seleccion),
    (SELECT TOP (1) CONVERT(NVARCHAR(30), DECRYPTBYKEYAUTOCERT(CERT_ID(N'CertificadoCifradoMundial'), N'ClaveMaestra_Mundial_2026!', pe.Nombre)) FROM equipos.Persona AS pe
     JOIN equipos.Jugador AS j ON j.IdJugador=pe.IdPersona
     WHERE CONVERT(NVARCHAR(30), DECRYPTBYKEYAUTOCERT(CERT_ID(N'CertificadoCifradoMundial'), N'ClaveMaestra_Mundial_2026!', pe.Nombre)) COLLATE Latin1_General_100_CI_AI = #GolesStaging.NombreAutor COLLATE Latin1_General_100_CI_AI
       AND j.Seleccion = #GolesStaging.Seleccion),
    (SELECT TOP (1) al.NombreCsv FROM #AliasJugadores AS al
     WHERE al.NombrePromiedos = #GolesStaging.NombreAutor AND al.Habilitado='1'
       AND (al.Seleccion = #GolesStaging.SeleccionPais
            OR EXISTS (SELECT 1 FROM #EquiposPartidos AS eq
                       WHERE eq.Pais = #GolesStaging.SeleccionPais AND eq.SeleccionCsv = al.Seleccion))))
WHERE Estado='Pendiente';

-- D6: el autor no esta cargado para esa seleccion (carga 10).
UPDATE #GolesStaging SET Estado='Error',
    Detalle=N'El autor del gol no esta cargado para esa seleccion: ejecute la carga 10.'
WHERE Estado='Pendiente'
  AND (SELECT COUNT(*) FROM equipos.Persona AS pe
       JOIN equipos.Jugador AS j ON j.IdJugador=pe.IdPersona
       WHERE CONVERT(NVARCHAR(30), DECRYPTBYKEYAUTOCERT(CERT_ID(N'CertificadoCifradoMundial'), N'ClaveMaestra_Mundial_2026!', pe.Nombre)) = ISNULL(#GolesStaging.NombreAutorBd, #GolesStaging.NombreAutor)
         AND j.Seleccion = #GolesStaging.Seleccion) = 0;

-- D7: el autor es ambiguo dentro de la seleccion.
UPDATE #GolesStaging SET Estado='Error',
    Detalle=N'El autor del gol es ambiguo en la seleccion: revise la carga 10.'
WHERE Estado='Pendiente'
  AND (SELECT COUNT(*) FROM equipos.Persona AS pe
       JOIN equipos.Jugador AS j ON j.IdJugador=pe.IdPersona
       WHERE CONVERT(NVARCHAR(30), DECRYPTBYKEYAUTOCERT(CERT_ID(N'CertificadoCifradoMundial'), N'ClaveMaestra_Mundial_2026!', pe.Nombre)) = ISNULL(#GolesStaging.NombreAutorBd, #GolesStaging.NombreAutor)
         AND j.Seleccion = #GolesStaging.Seleccion) > 1;

-- Se resuelve el identificador del autor.
UPDATE #GolesStaging SET IdJugador = j.IdJugador
FROM #GolesStaging AS s
JOIN equipos.Persona AS pe ON CONVERT(NVARCHAR(30), DECRYPTBYKEYAUTOCERT(CERT_ID(N'CertificadoCifradoMundial'), N'ClaveMaestra_Mundial_2026!', pe.Nombre)) = ISNULL(s.NombreAutorBd, s.NombreAutor)
JOIN equipos.Jugador AS j ON j.IdJugador = pe.IdPersona AND j.Seleccion = s.Seleccion
WHERE s.Estado='Pendiente';

-- ASISTENCIA (opcional). Se resuelve el asistente con la misma logica que el
-- autor: coincidencia directa, sin acentos y, por ultimo, equivalencias.
-- Si no se puede resolver, el gol se carga igual con Asistencia NULL.
UPDATE #GolesStaging SET NombreAsistenciaBd = COALESCE(
    (SELECT TOP (1) CONVERT(NVARCHAR(30), DECRYPTBYKEYAUTOCERT(CERT_ID(N'CertificadoCifradoMundial'), N'ClaveMaestra_Mundial_2026!', pe.Nombre)) FROM equipos.Persona AS pe
     JOIN equipos.Jugador AS j ON j.IdJugador=pe.IdPersona
     WHERE CONVERT(NVARCHAR(30), DECRYPTBYKEYAUTOCERT(CERT_ID(N'CertificadoCifradoMundial'), N'ClaveMaestra_Mundial_2026!', pe.Nombre)) = #GolesStaging.NombreAsistencia AND j.Seleccion = #GolesStaging.Seleccion),
    (SELECT TOP (1) CONVERT(NVARCHAR(30), DECRYPTBYKEYAUTOCERT(CERT_ID(N'CertificadoCifradoMundial'), N'ClaveMaestra_Mundial_2026!', pe.Nombre)) FROM equipos.Persona AS pe
     JOIN equipos.Jugador AS j ON j.IdJugador=pe.IdPersona
     WHERE CONVERT(NVARCHAR(30), DECRYPTBYKEYAUTOCERT(CERT_ID(N'CertificadoCifradoMundial'), N'ClaveMaestra_Mundial_2026!', pe.Nombre)) COLLATE Latin1_General_100_CI_AI = #GolesStaging.NombreAsistencia COLLATE Latin1_General_100_CI_AI
       AND j.Seleccion = #GolesStaging.Seleccion),
    (SELECT TOP (1) al.NombreCsv FROM #AliasJugadores AS al
     WHERE al.NombrePromiedos = #GolesStaging.NombreAsistencia AND al.Habilitado='1'
       AND (al.Seleccion = #GolesStaging.SeleccionPais
            OR EXISTS (SELECT 1 FROM #EquiposPartidos AS eq
                       WHERE eq.Pais = #GolesStaging.SeleccionPais AND eq.SeleccionCsv = al.Seleccion))))
WHERE Estado='Pendiente' AND NULLIF(LTRIM(RTRIM(NombreAsistencia)), N'') IS NOT NULL;

-- Se resuelve el identificador del asistente (siempre del equipo del autor).
UPDATE #GolesStaging SET IdAsistencia = j.IdJugador
FROM #GolesStaging AS s
JOIN equipos.Persona AS pe ON CONVERT(NVARCHAR(30), DECRYPTBYKEYAUTOCERT(CERT_ID(N'CertificadoCifradoMundial'), N'ClaveMaestra_Mundial_2026!', pe.Nombre)) = s.NombreAsistenciaBd
JOIN equipos.Jugador AS j ON j.IdJugador = pe.IdPersona AND j.Seleccion = s.Seleccion
WHERE s.Estado='Pendiente' AND s.NombreAsistenciaBd IS NOT NULL;

-- A1: la fuente informa un asistente que no se pudo resolver en la base.
-- NO invalida el gol: se carga sin asistencia y se deja el aviso.
UPDATE #GolesStaging SET
    Aviso=N'El asistente informado por la fuente no esta cargado (carga 10): el gol se carga sin asistencia.'
WHERE Estado='Pendiente' AND IdAsistencia IS NULL
  AND NULLIF(LTRIM(RTRIM(NombreAsistencia)), N'') IS NOT NULL;

-- A2: el asistente informado es el propio autor (el SP lo rechazaria).
UPDATE #GolesStaging SET IdAsistencia=NULL,
    Aviso=N'El asistente informado coincide con el autor: el gol se carga sin asistencia.'
WHERE Estado='Pendiente' AND IdAsistencia IS NOT NULL AND IdAsistencia = IdJugador;

-- A3: el asistente no estaba en cancha en ese periodo (misma validacion del SP).
UPDATE #GolesStaging SET IdAsistencia=NULL,
    Aviso=N'El asistente no estaba en cancha en ese periodo (cargas 14 y 18): el gol se carga sin asistencia.'
WHERE Estado='Pendiente' AND IdAsistencia IS NOT NULL
  AND partidos.fnJugadorEnCanchaPeriodo(IdPartido, IdAsistencia, ISNULL(Minuto,2147483647), Periodo) = 0;

-- A4: un gol en contra no lleva asistencia (lo prohibe el SP y la fuente no la trae).
UPDATE #GolesStaging SET IdAsistencia=NULL
WHERE Estado='Pendiente' AND IdAsistencia IS NOT NULL AND Tipo='En contra';

-- D8: el autor no estaba en la cancha (misma validacion del SP, aqui preventiva).
UPDATE #GolesStaging SET Estado='Error',
    Detalle=N'El autor del gol no estaba en cancha: ejecute antes la carga 18 (sustituciones) y la 14 (alineaciones).'
WHERE Estado='Pendiente' AND IdJugador IS NOT NULL
  AND partidos.fnJugadorEnCanchaPeriodo(IdPartido, IdJugador, ISNULL(Minuto,2147483647), Periodo) = 0;

-- Reporte de la depuracion: se informa ANTES de escribir en la tabla real.
SELECT 'FASE 2 - Depuracion de goles (antes de la persistencia)' AS Fase;
SELECT Estado, COUNT(*) AS Cantidad FROM #GolesStaging GROUP BY Estado ORDER BY Estado;
SELECT Fila, GameId, MinutoTexto, Periodo, NombreAutor, Seleccion, Tipo, Estado, Detalle
FROM #GolesStaging WHERE Estado IN ('Error','Duplicada') ORDER BY Fila;

-- Avisos de asistencia: el gol es valido, pero se carga sin Asistencia.
SELECT 'FASE 2 - Avisos de asistencia (el gol se carga igual)' AS Fase;
SELECT COUNT(*) AS GolesConAsistencia FROM #GolesStaging WHERE Estado='Pendiente' AND IdAsistencia IS NOT NULL;
SELECT COUNT(*) AS GolesSinAsistencia FROM #GolesStaging WHERE Estado='Pendiente' AND IdAsistencia IS NULL;
SELECT Fila, GameId, MinutoTexto, NombreAutor, NombreAsistencia, Aviso
FROM #GolesStaging WHERE Estado='Pendiente' AND Aviso IS NOT NULL ORDER BY Fila;

---------------------------------------------------------------------------------------
-- FASE 3 - PERSISTENCIA
-- Solo las filas que quedaron en 'Pendiente' llegan a la tabla real, siempre
-- a traves de los SP de ABM de la entrega 5.
---------------------------------------------------------------------------------------

DECLARE @fila INT, @idPartido INT, @minuto INT, @periodo INT, @idJugador INT,
        @idAsistencia INT, @tipo VARCHAR(20), @estado VARCHAR(20),
        @asistenciaActual INT;
DECLARE crsGoles CURSOR LOCAL FAST_FORWARD FOR
    SELECT Fila, IdPartido, Minuto, Periodo, IdJugador, IdAsistencia, Tipo
    FROM #GolesStaging WHERE Estado='Pendiente' ORDER BY Fila;
OPEN crsGoles;
FETCH NEXT FROM crsGoles INTO @fila, @idPartido, @minuto, @periodo, @idJugador, @idAsistencia, @tipo;
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
            -- No existe SP de modificacion de goles (solo alta y baja): si el gol
            -- ya estaba cargado sin la asistencia de la fuente, se informa.
            SET @asistenciaActual = (SELECT TOP (1) g.Asistencia
                                     FROM partidos.Gol AS g
                                     JOIN partidos.Evento AS e ON e.IdEvento = g.IdGol
                                     WHERE e.Partido = @idPartido AND e.Periodo = @periodo
                                       AND e.Minuto = @minuto AND g.Autor = @idJugador
                                       AND g.Tipo = @tipo);
            IF @idAsistencia IS NOT NULL AND ISNULL(@asistenciaActual, -1) <> @idAsistencia
                UPDATE #GolesStaging SET Detalle=
                    N'El gol ya estaba cargado sin esta asistencia. No hay SP de modificacion: para corregirla hay que dar de baja el gol y volver a ejecutar esta carga.'
                WHERE Fila=@fila;
            ELSE IF @idAsistencia IS NULL AND @asistenciaActual IS NOT NULL
                UPDATE #GolesStaging SET Detalle=
                    N'El gol ya estaba cargado con una asistencia que la fuente no informa. No hay SP de modificacion: revise la carga.'
                WHERE Fila=@fila;
        END
        ELSE
        BEGIN
            EXEC SPTRANS.uspGol_Registrar @minuto=@minuto, @partido=@idPartido,
                @periodo=@periodo, @autor=@idJugador, @asistencia=@idAsistencia, @tipo=@tipo;
            SET @estado='Insertada';
        END;
    END TRY
    BEGIN CATCH
        SET @estado='Error';
        UPDATE #GolesStaging SET Estado='Error', Detalle=ERROR_MESSAGE() WHERE Fila=@fila;
    END CATCH;
    IF @estado <> 'Error'
        UPDATE #GolesStaging SET Estado=@estado WHERE Fila=@fila;
    FETCH NEXT FROM crsGoles INTO @fila, @idPartido, @minuto, @periodo, @idJugador, @idAsistencia, @tipo;
END;
CLOSE crsGoles;
DEALLOCATE crsGoles;

-- Reporte final de la persistencia.
SELECT 'FASE 3 - Persistencia de goles' AS Fase;
SELECT Estado, COUNT(*) AS Cantidad FROM #GolesStaging GROUP BY Estado ORDER BY Estado;
SELECT Fila, GameId, IdPartido, MinutoTexto, Minuto, Periodo, NombreAutor, IdJugador,
       NombreAsistencia, IdAsistencia, Tipo, Estado, Detalle
FROM #GolesStaging ORDER BY Fila;

-- Control: goles cargados con asistencia contra los que la fuente informa.
SELECT 'VERIFICACION - Asistencias cargadas contra la fuente' AS Fase;
SELECT s.GolesEnLaFuente,
       s.ConAsistenciaEnLaFuente,
       (SELECT COUNT(*) FROM #GolesStaging AS x
        JOIN partidos.Gol AS g ON g.Autor = x.IdJugador AND g.Tipo = x.Tipo
        JOIN partidos.Evento AS e ON e.IdEvento = g.IdGol
        WHERE e.Partido = x.IdPartido AND e.Periodo = x.Periodo
          AND e.Minuto = x.Minuto AND g.Asistencia IS NOT NULL) AS ConAsistenciaEnLaTabla,
       CASE WHEN s.ConAsistenciaEnLaFuente =
                 (SELECT COUNT(*) FROM #GolesStaging AS x
                  JOIN partidos.Gol AS g ON g.Autor = x.IdJugador AND g.Tipo = x.Tipo
                  JOIN partidos.Evento AS e ON e.IdEvento = g.IdGol
                  WHERE e.Partido = x.IdPartido AND e.Periodo = x.Periodo
                    AND e.Minuto = x.Minuto AND g.Asistencia IS NOT NULL)
            THEN 'OK' ELSE 'DIFERENCIA' END AS Control
FROM (SELECT COUNT(*) AS GolesEnLaFuente,
             SUM(CASE WHEN IdAsistencia IS NOT NULL THEN 1 ELSE 0 END) AS ConAsistenciaEnLaFuente
      FROM #GolesStaging WHERE Estado IN ('Insertada','SinCambios')) AS s;

DECLARE @fallos INT = (SELECT COUNT(*) FROM #GolesStaging WHERE Estado='Error');
DROP TABLE #GolesStaging;
IF @fallos > 0
    THROW 51904, 'Importacion parcial: se conservaron los goles correctos. Revise el detalle.', 1;
GO


