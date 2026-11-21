-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Comision 02
-- Grupo 7: Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 18/11/2026.
-- Objetivo: cargar las definiciones por penales (tanda) de los partidos que
-- terminaron empatados, con la metodologia de tres fases.
--   FASE 1 STAGING     : una fila por tiro de la etapa "Penales" del JSON.
--   FASE 2 DEPURACION  : reglas de conjunto (UPDATE) sobre la staging.
--   FASE 3 PERSISTENCIA : la tanda se abre con SP.uspPartido_Tanda y cada
--                         conversion se registra con SPTRANS.uspGol_Registrar
--                         (@penales = 1), que es el unico camino que actualiza
--                         partidos.Partido.PenalesEq1 y PenalesEq2.
--
-- Fuente: los 104 JSON de Promiedos (Datos\Datos_Partidos\partidos).
-- Tipos de evento observados en la etapa "Penales":
--   3  -> penal convertido
--   16 -> penal convertido (la fuente usa 3 y 16 de forma inconsistente:
--         en dos partidos marca las conversiones con 3 y en los otros dos con 16)
--   17 -> penal errado. El modelo no tiene tabla para penales fallados, por eso
--         la fila se conserva en la staging como 'Omitida' y no se persiste.
--
-- Requiere ejecutar antes las cargas 03 (periodos), 10 (jugadores),
-- 11 (partidos) y 14 (alineaciones): el SP exige que el autor este en cancha y
-- que el partido haya terminado empatado.
-- No modifica ningun importador existente: la carga 17 solo toma los tipos 1 y 2
-- y deja la etapa "Penales" afuera, asi que este script no se superpone.
--
-- SSMS: Consulta -> Modo SQLCMD. TP_BDDA se define en los archivos 00_Importar_Todo_Parte*.sql.
-- IMPORTANTE: no editar rutas aca; TP_BDDA se define en los archivos 00_Importar_Todo_Parte*.sql.



USE MUNDIAL;
GO
-- Entrega 8: equipos.Persona.Nombre esta cifrado; se lee con DECRYPTBYKEYAUTOCERT.
-- No depende de que la clave este abierta en la sesion (los SP de ABM la cierran).
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF @@TRANCOUNT <> 0 OR (2 & @@OPTIONS) = 2
    THROW 51900, 'Ejecute sin transaccion externa y con IMPLICIT_TRANSACTIONS OFF.', 1;
IF OBJECT_ID(N'partidos.Partido', N'U') IS NULL
   OR OBJECT_ID(N'partidos.Gol', N'U') IS NULL
   OR OBJECT_ID(N'SP.uspPartido_Tanda', N'P') IS NULL
   OR OBJECT_ID(N'SPTRANS.uspGol_Registrar', N'P') IS NULL
    THROW 51900, 'Faltan tablas o SP ABM. Ejecute primero el instalador.', 1;

IF OBJECT_ID(N'tempdb..#TandaStaging') IS NOT NULL DROP TABLE #TandaStaging;

-- Lector compartido: deja los JSON crudos, las equivalencias y el partido resuelto.
:r $(TP_BDDA)\Importacion\XX_Lectura_Partidos_JSON.sql

---------------------------------------------------------------------------------------
-- FASE 1 - STAGING
-- Una fila por tiro de la etapa "Penales" (tipos 3, 16 y 17 de la fuente).
---------------------------------------------------------------------------------------

CREATE TABLE #TandaStaging (
    Fila INT IDENTITY(1,1) PRIMARY KEY,
    Archivo NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    GameId NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    IdPartido INT,
    Etapa NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Turno INT,
    Team INT,
    TipoEvento INT,
    Convertido BIT,
    NombreAutor NVARCHAR(60) COLLATE DATABASE_DEFAULT,
    NombreAutorBd NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    Seleccion INT,
    SeleccionPais NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    IdJugador INT,
    DetallePartido NVARCHAR(2048) COLLATE DATABASE_DEFAULT,
    Estado VARCHAR(20) COLLATE DATABASE_DEFAULT NOT NULL DEFAULT 'Pendiente',
    Detalle NVARCHAR(2048) COLLATE DATABASE_DEFAULT
);

INSERT #TandaStaging
    (Archivo, GameId, IdPartido, Etapa, Turno, Team, TipoEvento, Convertido,
     NombreAutor, Seleccion, DetallePartido, Estado, Detalle)
SELECT a.Archivo, p.GameId, p.IdPartido, JSON_VALUE(st.value, '$.name'),
       TRY_CONVERT(INT, e.time), e.team, e.type,
       CASE WHEN e.type IN (3,16) THEN 1 ELSE 0 END,
       tx.Texto,
       CASE WHEN e.team = 1 THEN p.Eq1 ELSE p.Eq2 END,
       p.Detalle,
       CASE WHEN e.type = 17 THEN 'Omitida' ELSE 'Pendiente' END,
       CASE WHEN e.type = 17
            THEN N'Tiro errado: el modelo no tiene tabla para penales fallados.'
       END
FROM #ArchivosPartidos AS a
LEFT JOIN #PartidosJson AS p ON p.Archivo = a.Archivo
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
CROSS APPLY (SELECT MAX(CASE WHEN c.[key] = 0 THEN c.value END) AS Texto
             FROM OPENJSON(e.Texts) AS c) AS tx
WHERE JSON_VALUE(st.value, '$.name') = N'Penales'
  AND e.type IN (3,16,17);

IF NOT EXISTS (SELECT 1 FROM #TandaStaging)
    THROW 51901, 'No se encontraron tiros de tanda en los JSON; revise la lectura de archivos.', 1;

-- Periodo de la tanda: no se hardcodea el id, se busca por EsPenales.
DECLARE @idPeriodoPenales INT =
    (SELECT MIN(IdPeriodo) FROM partidos.Periodo WHERE EsPenales = 1);
IF @idPeriodoPenales IS NULL
    THROW 51901, 'No existe el periodo Penales: ejecute la carga 03.', 1;

---------------------------------------------------------------------------------------
-- FASE 2 - DEPURACION
-- Reglas de conjunto: cada UPDATE marca las filas invalidas y su motivo.
-- No se borra nada; las filas validas quedan en Estado = 'Pendiente'.
---------------------------------------------------------------------------------------

-- D1: el JSON del partido no se pudo resolver.
UPDATE #TandaStaging SET Estado='Error',
    Detalle=ISNULL(DetallePartido, N'El JSON del partido no se pudo resolver.')
WHERE Estado='Pendiente' AND IdPartido IS NULL;

-- D2: falta el nombre del ejecutante.
UPDATE #TandaStaging SET Estado='Error',
    Detalle=N'El tiro de la tanda no indica el ejecutante.'
WHERE Estado='Pendiente' AND NULLIF(NombreAutor, N'') IS NULL;

-- D3: la seleccion del ejecutante no se pudo determinar.
UPDATE #TandaStaging SET Estado='Error',
    Detalle=N'No se pudo determinar la seleccion del ejecutante.'
WHERE Estado='Pendiente' AND Seleccion IS NULL;

-- Se resuelve el pais de la seleccion y el nombre del jugador en la base:
-- primero por coincidencia directa y, si no, por el archivo de equivalencias
-- (el JSON de Promiedos y el CSV de jugadores no usan siempre el mismo nombre).
UPDATE s SET SeleccionPais = p.NOMBRE
FROM #TandaStaging AS s
JOIN equipos.Seleccion AS se ON se.IdSeleccion = s.Seleccion
JOIN equipos.Pais AS p ON p.IdPais = se.IdPais
WHERE s.Estado='Pendiente';

UPDATE #TandaStaging SET NombreAutorBd = COALESCE(
    (SELECT TOP (1) CONVERT(NVARCHAR(30), DECRYPTBYKEYAUTOCERT(CERT_ID(N'CertificadoCifradoMundial'), N'ClaveMaestra_Mundial_2026!', pe.Nombre)) FROM equipos.Persona AS pe
     JOIN equipos.Jugador AS j ON j.IdJugador=pe.IdPersona
     WHERE CONVERT(NVARCHAR(30), DECRYPTBYKEYAUTOCERT(CERT_ID(N'CertificadoCifradoMundial'), N'ClaveMaestra_Mundial_2026!', pe.Nombre)) = #TandaStaging.NombreAutor AND j.Seleccion = #TandaStaging.Seleccion),
    (SELECT TOP (1) CONVERT(NVARCHAR(30), DECRYPTBYKEYAUTOCERT(CERT_ID(N'CertificadoCifradoMundial'), N'ClaveMaestra_Mundial_2026!', pe.Nombre)) FROM equipos.Persona AS pe
     JOIN equipos.Jugador AS j ON j.IdJugador=pe.IdPersona
     WHERE CONVERT(NVARCHAR(30), DECRYPTBYKEYAUTOCERT(CERT_ID(N'CertificadoCifradoMundial'), N'ClaveMaestra_Mundial_2026!', pe.Nombre)) COLLATE Latin1_General_100_CI_AI = #TandaStaging.NombreAutor COLLATE Latin1_General_100_CI_AI
       AND j.Seleccion = #TandaStaging.Seleccion),
    (SELECT TOP (1) al.NombreCsv FROM #AliasJugadores AS al
     WHERE al.NombrePromiedos = #TandaStaging.NombreAutor AND al.Habilitado='1'
       AND al.Seleccion = #TandaStaging.SeleccionPais))
WHERE Estado='Pendiente';

-- D4: el ejecutante no esta cargado para esa seleccion (carga 10).
UPDATE #TandaStaging SET Estado='Error',
    Detalle=N'El ejecutante no esta cargado para esa seleccion: ejecute la carga 10.'
WHERE Estado='Pendiente'
  AND (SELECT COUNT(*) FROM equipos.Persona AS pe
       JOIN equipos.Jugador AS j ON j.IdJugador=pe.IdPersona
       WHERE CONVERT(NVARCHAR(30), DECRYPTBYKEYAUTOCERT(CERT_ID(N'CertificadoCifradoMundial'), N'ClaveMaestra_Mundial_2026!', pe.Nombre)) = ISNULL(#TandaStaging.NombreAutorBd, #TandaStaging.NombreAutor)
         AND j.Seleccion = #TandaStaging.Seleccion) = 0;

-- D5: el ejecutante es ambiguo dentro de la seleccion.
UPDATE #TandaStaging SET Estado='Error',
    Detalle=N'El ejecutante es ambiguo en la seleccion: revise la carga 10.'
WHERE Estado='Pendiente'
  AND (SELECT COUNT(*) FROM equipos.Persona AS pe
       JOIN equipos.Jugador AS j ON j.IdJugador=pe.IdPersona
       WHERE CONVERT(NVARCHAR(30), DECRYPTBYKEYAUTOCERT(CERT_ID(N'CertificadoCifradoMundial'), N'ClaveMaestra_Mundial_2026!', pe.Nombre)) = ISNULL(#TandaStaging.NombreAutorBd, #TandaStaging.NombreAutor)
         AND j.Seleccion = #TandaStaging.Seleccion) > 1;

-- Se resuelve el identificador del ejecutante.
UPDATE s SET IdJugador = j.IdJugador
FROM #TandaStaging AS s
JOIN equipos.Persona AS pe ON CONVERT(NVARCHAR(30), DECRYPTBYKEYAUTOCERT(CERT_ID(N'CertificadoCifradoMundial'), N'ClaveMaestra_Mundial_2026!', pe.Nombre)) = ISNULL(s.NombreAutorBd, s.NombreAutor)
JOIN equipos.Jugador AS j ON j.IdJugador = pe.IdPersona AND j.Seleccion = s.Seleccion
WHERE s.Estado='Pendiente';

-- D6a: el ejecutante estaba en el banco y su ingreso no figura en la carga 16
-- (por ejemplo, un cambio rechazado por el tope del reglamento). El tiro no se
-- puede registrar: queda 'Omitida' con el detalle; no es un error de datos.
UPDATE #TandaStaging SET Estado='Omitida',
    Detalle=N'El ejecutante estaba en el banco y su ingreso no figura en la carga 16: el tiro se omite.'
WHERE Estado='Pendiente' AND IdJugador IS NOT NULL
  AND partidos.fnJugadorEnCanchaPeriodo(IdPartido, IdJugador, NULL, @idPeriodoPenales) = 0
  AND EXISTS (SELECT 1 FROM partidos.Alineacion AS a
              WHERE a.IdPartido = #TandaStaging.IdPartido
                AND a.IdJugador = #TandaStaging.IdJugador
                AND a.Rol = 'Suplente');

-- D6b: el ejecutante no estaba en cancha por un problema de datos (no figura
-- ni como suplente): es un error que hay que revisar.
UPDATE #TandaStaging SET Estado='Error',
    Detalle=N'El ejecutante no estaba en cancha: revise la carga 14.'
WHERE Estado='Pendiente' AND IdJugador IS NOT NULL
  AND partidos.fnJugadorEnCanchaPeriodo(IdPartido, IdJugador, NULL, @idPeriodoPenales) = 0;

-- D7: el partido no termino empatado. SP.uspPartido_Tanda exige el empate
-- porque la tanda no se juega si hay un ganador en los 120 minutos.
-- Si el marcador no coincide con la fuente, primero hay que revisar la carga 16
-- (goles de penal de tiempo regular que hoy se descartan).
UPDATE s SET Estado='Error',
    Detalle=N'El marcador del partido no esta empatado: revise las cargas 16 y 22 antes de la tanda.'
FROM #TandaStaging AS s
JOIN partidos.Partido AS p ON p.IdPartido = s.IdPartido
WHERE s.Estado='Pendiente' AND p.GolesEq1 <> p.GolesEq2;

-- D8: la fase de grupos no admite definicion por penales.
UPDATE s SET Estado='Error',
    Detalle=N'La fase de grupos no admite definicion por penales: revise la fase del partido.'
FROM #TandaStaging AS s
JOIN partidos.Partido AS p ON p.IdPartido = s.IdPartido
JOIN partidos.Fase AS f ON f.IdFase = p.IdFase
WHERE s.Estado='Pendiente' AND f.Descripcion = 'Grupos';

-- D9: el turno esta repetido para el mismo equipo dentro de la misma tanda.
UPDATE f SET Estado='Duplicada',
    Detalle=N'El turno esta repetido para el mismo equipo en la tanda.'
FROM #TandaStaging AS f
WHERE f.Estado='Pendiente' AND EXISTS (
    SELECT 1 FROM #TandaStaging AS o
    WHERE o.Estado='Pendiente' AND o.IdPartido=f.IdPartido
      AND o.Team=f.Team AND o.Turno=f.Turno AND o.Fila<f.Fila
);

-- Reporte de la depuracion: se informa ANTES de escribir en la tabla real.
SELECT 'FASE 2 - Depuracion de la tanda (antes de la persistencia)' AS Fase;
SELECT Estado, COUNT(*) AS Cantidad FROM #TandaStaging GROUP BY Estado ORDER BY Estado;
SELECT Fila, GameId, Turno, Team, TipoEvento, NombreAutor, Seleccion, Estado, Detalle
FROM #TandaStaging WHERE Estado IN ('Error','Duplicada','Omitida') ORDER BY Fila;

---------------------------------------------------------------------------------------
-- FASE 3 - PERSISTENCIA
-- Primero se abre la tanda de cada partido (una sola vez) y despues se cargan
-- las conversiones. El orden importa: uspGol_Registrar exige que PenalesEq1/2
-- ya esten inicializados para sumar sobre la tanda.
---------------------------------------------------------------------------------------

DECLARE @idPartido INT, @penales1 INT, @estado VARCHAR(20);

DECLARE crsPartidos CURSOR LOCAL FAST_FORWARD FOR
    SELECT DISTINCT IdPartido FROM #TandaStaging
    WHERE Estado='Pendiente' ORDER BY IdPartido;
OPEN crsPartidos;
FETCH NEXT FROM crsPartidos INTO @idPartido;
WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        SELECT @penales1 = PenalesEq1 FROM partidos.Partido WHERE IdPartido = @idPartido;
        IF @penales1 IS NULL
            EXEC SP.uspPartido_Tanda @IdPartido=@idPartido, @Iniciar=1;
    END TRY
    BEGIN CATCH
        -- Si la tanda no se puede abrir, ninguna conversion de ese partido se carga.
        UPDATE #TandaStaging SET Estado='Error', Detalle=ERROR_MESSAGE()
        WHERE IdPartido=@idPartido AND Estado='Pendiente';
    END CATCH;
    FETCH NEXT FROM crsPartidos INTO @idPartido;
END;
CLOSE crsPartidos;
DEALLOCATE crsPartidos;

DECLARE @fila INT, @idJugador INT, @turno INT;
DECLARE crsTiros CURSOR LOCAL FAST_FORWARD FOR
    SELECT Fila, IdPartido, IdJugador, Turno FROM #TandaStaging
    WHERE Estado='Pendiente' ORDER BY IdPartido, Turno, Fila;
OPEN crsTiros;
FETCH NEXT FROM crsTiros INTO @fila, @idPartido, @idJugador, @turno;
WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        SET @estado = NULL;
        -- El SP de alta de goles no valida duplicados: se verifica si esa
        -- conversion ya esta cargada para que la carga sea idempotente.
        IF EXISTS (SELECT 1 FROM partidos.Gol AS g
                   JOIN partidos.Evento AS e ON e.IdEvento = g.IdGol
                   WHERE e.Partido = @idPartido AND e.Periodo = @idPeriodoPenales
                     AND g.Autor = @idJugador)
        BEGIN
            SET @estado = 'SinCambios';
        END
        ELSE
        BEGIN
            EXEC SPTRANS.uspGol_Registrar @minuto=NULL, @partido=@idPartido,
                @periodo=@idPeriodoPenales, @autor=@idJugador,
                @asistencia=NULL, @tipo='Penal';
            SET @estado = 'Insertada';
        END;
    END TRY
    BEGIN CATCH
        SET @estado = 'Error';
        UPDATE #TandaStaging SET Estado='Error', Detalle=ERROR_MESSAGE() WHERE Fila=@fila;
    END CATCH;
    IF @estado <> 'Error'
        UPDATE #TandaStaging SET Estado=@estado WHERE Fila=@fila;
    FETCH NEXT FROM crsTiros INTO @fila, @idPartido, @idJugador, @turno;
END;
CLOSE crsTiros;
DEALLOCATE crsTiros;

-- Reporte final de la persistencia.
SELECT 'FASE 3 - Persistencia de la tanda' AS Fase;
SELECT Estado, COUNT(*) AS Cantidad FROM #TandaStaging GROUP BY Estado ORDER BY Estado;
SELECT Fila, GameId, IdPartido, Turno, Team, TipoEvento, NombreAutor, IdJugador, Estado, Detalle
FROM #TandaStaging ORDER BY Fila;

-- Control: PenalesEq1/2 guardados contra las conversiones que trae la fuente.
-- Se parte de todos los partidos que tienen tanda en el JSON, aunque hayan
-- quedado sin cargar, para que la diferencia se vea en el reporte.
SELECT 'VERIFICACION - Tanda cargada contra la fuente' AS Fase;
SELECT p.IdPartido, p.PenalesEq1, p.PenalesEq2,
       ISNULL(s.Eq1Fuente, 0) AS Eq1Fuente, ISNULL(s.Eq2Fuente, 0) AS Eq2Fuente,
       CASE WHEN p.PenalesEq1 = ISNULL(s.Eq1Fuente, 0)
             AND p.PenalesEq2 = ISNULL(s.Eq2Fuente, 0)
            THEN 'OK' ELSE 'DIFERENCIA' END AS Control
FROM (SELECT DISTINCT IdPartido FROM #TandaStaging WHERE Convertido = 1) AS t
JOIN partidos.Partido AS p ON p.IdPartido = t.IdPartido
LEFT JOIN (
    SELECT IdPartido,
           SUM(CASE WHEN Team = 1 THEN 1 ELSE 0 END) AS Eq1Fuente,
           SUM(CASE WHEN Team = 2 THEN 1 ELSE 0 END) AS Eq2Fuente
    FROM #TandaStaging
    WHERE Convertido = 1 AND Estado IN ('Insertada','SinCambios')
    GROUP BY IdPartido
) AS s ON s.IdPartido = p.IdPartido
ORDER BY p.IdPartido;

DECLARE @fallos INT = (SELECT COUNT(*) FROM #TandaStaging WHERE Estado='Error');
DROP TABLE #TandaStaging;
IF @fallos > 0
    THROW 51904, 'Importacion parcial: se conservaron las tandas correctas. Revise el detalle.', 1;
GO
