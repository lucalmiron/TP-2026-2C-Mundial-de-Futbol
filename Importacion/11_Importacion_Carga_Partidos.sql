-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Comision 02
-- Grupo 7: Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 10/11/2026.
-- Objetivo: importar los 104 partidos de los JSON de Promiedos con la
-- metodologia de tres fases.
--   FASE 1 STAGING     : se baja TODO a tablas temporales. #PartidosCrudo
--                         guarda los archivos originales sin modificar y
--                         #PartidosStaging una fila por JSON con los campos
--                         del dominio y las columnas Estado y Detalle.
--   FASE 2 DEPURACION  : reglas de conjunto (UPDATE) sobre la staging.
--   FASE 3 PERSISTENCIA : solo las filas validas pasan por
--                         SP.uspPartido_Registrar / SP.uspPartido_Update.
--
-- El marcador NO se carga aqui: el modelo (Entrega 5) lo modifica unicamente
-- mediante el alta y baja de goles, que hace el importador 14. La asistencia
-- tampoco viene en la fuente Promiedos (game_info solo trae Estadio,
-- Capacidad, Arbitro y Arg TV), por lo que queda en NULL.
--
-- Requiere las cargas 02 (fases), 04 (husos), 06 (paises), 07 (selecciones)
-- y 08 (sedes).
-- SSMS: Consulta -> Modo SQLCMD. Ajustar las rutas del servidor SQL.
-- IMPORTANTE: cada integrante debe poner las rutas de su propia PC, porque
-- SQL Server lee los archivos desde el disco local del servidor.
-- :setvar CarpetaPartidos "C:\ruta\proyecto\Datos\Datos_Partidos\partidos"
-- :setvar RutaLectura "C:\ruta\proyecto\Importacion\11_Lectura_JSON_Partidos.sql"
-- :setvar RutaEquipos "C:\ruta\proyecto\Datos\equivalencias_equipos_jugadores.csv"
-- :setvar RutaSedes "C:\ruta\proyecto\Datos\equivalencias_sedes_partidos.csv"
-- :setvar RutaFases "C:\ruta\proyecto\Datos\equivalencias_fases_partidos.csv"

:setvar CarpetaPartidos "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Datos\Datos_Partidos\partidos"
:setvar RutaLectura "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Importacion\11_Lectura_JSON_Partidos.sql"
:setvar RutaEquipos "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Datos\equivalencias_equipos_jugadores.csv"
:setvar RutaSedes "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Datos\equivalencias_sedes_partidos.csv"
:setvar RutaFases "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Datos\equivalencias_fases_partidos.csv"

USE [MUNDIAL];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @idMundial INT = 1;
-- Desplazamiento de la hora de la fuente (UTC-3). Es un supuesto documentado.
DECLARE @OffsetOrigen VARCHAR(6) = '-03:00';

IF @@TRANCOUNT <> 0 OR (2 & @@OPTIONS) = 2
    THROW 51700, 'Ejecute sin transaccion externa y con IMPLICIT_TRANSACTIONS OFF.', 1;
IF OBJECT_ID(N'partidos.Partido', N'U') IS NULL
   OR OBJECT_ID(N'SP.uspPartido_Registrar', N'P') IS NULL
   OR OBJECT_ID(N'SP.uspPartido_Update', N'P') IS NULL
    THROW 51700, 'Faltan tablas o SP ABM. Ejecute primero el instalador.', 1;
IF NOT EXISTS (SELECT 1 FROM sedes.Mundial WHERE IdMundial = @idMundial)
    THROW 51700, 'No existe el Mundial con IdMundial = 1. Debe cargarlo primero.', 1;

IF OBJECT_ID(N'tempdb..#PartidosCrudo') IS NOT NULL DROP TABLE #PartidosCrudo;
IF OBJECT_ID(N'tempdb..#PartidosStaging') IS NOT NULL DROP TABLE #PartidosStaging;
IF OBJECT_ID(N'tempdb..#EquiposPartidos') IS NOT NULL DROP TABLE #EquiposPartidos;
IF OBJECT_ID(N'tempdb..#SedesPartidos') IS NOT NULL DROP TABLE #SedesPartidos;
IF OBJECT_ID(N'tempdb..#FasesPartidos') IS NOT NULL DROP TABLE #FasesPartidos;
IF OBJECT_ID(N'tempdb..#ArchivosPartidos') IS NOT NULL DROP TABLE #ArchivosPartidos;
IF OBJECT_ID(N'tempdb..#ErroresArchivos') IS NOT NULL DROP TABLE #ErroresArchivos;

---------------------------------------------------------------------------------------
-- FASE 1 - STAGING
-- Todavia no se descarta nada: primero baja todo a tablas temporales.
---------------------------------------------------------------------------------------

-- 1.a) Archivo crudo: los bytes originales de cada JSON, sin modificar.
CREATE TABLE #PartidosCrudo (
    Archivo NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Contenido VARCHAR(MAX) COLLATE Latin1_General_100_CI_AS_SC_UTF8
);
CREATE TABLE #PartidosStaging (
    Fila INT IDENTITY(1,1) PRIMARY KEY,
    Archivo NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    IdFuente NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Torneo NVARCHAR(20) COLLATE DATABASE_DEFAULT,
    CantidadEquipos INT,
    Equipo1 NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Equipo2 NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Etapa NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    FechaTexto NVARCHAR(30) COLLATE DATABASE_DEFAULT,
    FechaUTC DATE,
    HoraUTC TIME(0),
    HoraLocal TIME(0),
    SedeOrigen NVARCHAR(150) COLLATE DATABASE_DEFAULT,
    Marcador1 INT,
    Marcador2 INT,
    Penales1 INT,
    Penales2 INT,
    IdFase INT,
    IdSede INT,
    Eq1 INT,
    Eq2 INT,
    IdPartido INT,
    Estado VARCHAR(20) COLLATE DATABASE_DEFAULT NOT NULL DEFAULT 'Pendiente',
    Detalle NVARCHAR(2048) COLLATE DATABASE_DEFAULT
);
CREATE TABLE #EquiposPartidos (
    SeleccionCsv NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Slug NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Pais NVARCHAR(100) COLLATE DATABASE_DEFAULT
);
CREATE TABLE #SedesPartidos (
    NombreJson NVARCHAR(150) COLLATE DATABASE_DEFAULT,
    NombreSede NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Ciudad NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Pais NVARCHAR(100) COLLATE DATABASE_DEFAULT
);
CREATE TABLE #FasesPartidos (
    Tipo NVARCHAR(20) COLLATE DATABASE_DEFAULT,
    Valor NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Fase NVARCHAR(50) COLLATE DATABASE_DEFAULT
);

BEGIN TRY
    BULK INSERT #EquiposPartidos FROM '$(RutaEquipos)'
    WITH (FORMAT='CSV', FIRSTROW=2, FIELDTERMINATOR=',',
          ROWTERMINATOR='0x0a', CODEPAGE='65001', MAXERRORS=0);
    BULK INSERT #SedesPartidos FROM '$(RutaSedes)'
    WITH (FORMAT='CSV', FIRSTROW=2, FIELDTERMINATOR=',',
          ROWTERMINATOR='0x0a', CODEPAGE='65001', MAXERRORS=0);
    BULK INSERT #FasesPartidos FROM '$(RutaFases)'
    WITH (FORMAT='CSV', FIRSTROW=2, FIELDTERMINATOR=',',
          ROWTERMINATOR='0x0a', CODEPAGE='65001', MAXERRORS=0);
END TRY
BEGIN CATCH
    DECLARE @mensaje NVARCHAR(2048) = LEFT(N'No se pudieron leer las tablas de equivalencias. '
                                           + ERROR_MESSAGE(), 2048);
    THROW 51701, @mensaje, 1;
END CATCH;

UPDATE #EquiposPartidos SET SeleccionCsv=LTRIM(RTRIM(SeleccionCsv)), Slug=LTRIM(RTRIM(Slug)),
    Pais=LTRIM(RTRIM(REPLACE(Pais,NCHAR(13),N'')));
UPDATE #SedesPartidos SET NombreJson=LTRIM(RTRIM(NombreJson)), NombreSede=LTRIM(RTRIM(NombreSede)),
    Ciudad=LTRIM(RTRIM(Ciudad)), Pais=LTRIM(RTRIM(REPLACE(Pais,NCHAR(13),N'')));
UPDATE #FasesPartidos SET Tipo=LTRIM(RTRIM(Tipo)), Valor=LTRIM(RTRIM(Valor)),
    Fase=LTRIM(RTRIM(REPLACE(Fase,NCHAR(13),N'')));

-- El lector de esta carga deja los JSON en #ArchivosPartidos.
-- El contenido se guarda como VARCHAR con collation UTF8 porque SINGLE_BLOB
-- entrega los bytes crudos del archivo; luego se convierte a NVARCHAR al leerlo.
CREATE TABLE #ArchivosPartidos (
    Archivo NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Contenido VARCHAR(MAX) COLLATE Latin1_General_100_CI_AS_SC_UTF8
);
CREATE TABLE #ErroresArchivos (
    Archivo NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Detalle NVARCHAR(2048) COLLATE DATABASE_DEFAULT
);

-- Los 104 JSON originales se leen con el lector de esta carga.
:r $(RutaLectura)

-- JSON_VALUE solo se aplica a documentos validos; los invalidos se informan aparte.
INSERT #ErroresArchivos
SELECT Archivo, N'JSON invalido.' FROM #ArchivosPartidos WHERE ISNULL(ISJSON(Contenido),0)<>1;
DELETE FROM #ArchivosPartidos WHERE ISNULL(ISJSON(Contenido),0)<>1;

-- 1.b) Copia de los archivos originales, sin modificar.
INSERT #PartidosCrudo (Archivo, Contenido)
SELECT Archivo, Contenido FROM #ArchivosPartidos;

-- 1.c) Extraccion: una fila por JSON.
INSERT #PartidosStaging
    (Archivo, IdFuente, Torneo, CantidadEquipos, Equipo1, Equipo2, Etapa, FechaTexto,
     SedeOrigen, Marcador1, Marcador2, Penales1, Penales2)
SELECT a.Archivo,
       JSON_VALUE(a.Contenido,'$.game.id'),
       JSON_VALUE(a.Contenido,'$.game.league.id'),
       (SELECT COUNT(*) FROM OPENJSON(a.Contenido,'$.game.teams')),
       JSON_VALUE(a.Contenido,'$.game.teams[0].url_name'),
       JSON_VALUE(a.Contenido,'$.game.teams[1].url_name'),
       JSON_VALUE(a.Contenido,'$.game.stage_round_name'),
       JSON_VALUE(a.Contenido,'$.game.start_time'),
       (SELECT MIN(g.Valor) FROM OPENJSON(a.Contenido,'$.game.game_info')
        WITH (Nombre NVARCHAR(100) '$.name', Valor NVARCHAR(150) '$.value') AS g
        WHERE g.Nombre=N'Estadio'),
       TRY_CONVERT(INT, JSON_VALUE(a.Contenido,'$.game.scores[0]')),
       TRY_CONVERT(INT, JSON_VALUE(a.Contenido,'$.game.scores[1]')),
       TRY_CONVERT(INT, JSON_VALUE(a.Contenido,'$.game.penalties[0]')),
       TRY_CONVERT(INT, JSON_VALUE(a.Contenido,'$.game.penalties[1]'))
FROM #ArchivosPartidos AS a;

IF NOT EXISTS (SELECT 1 FROM #PartidosStaging)
    THROW 51702, 'No se pudo procesar ningun partido.', 1;

-- 1.d) Fecha y hora en UTC a partir de la hora de la fuente.
UPDATE #PartidosStaging SET
    FechaUTC = CONVERT(DATE, SWITCHOFFSET(TODATETIMEOFFSET(
        TRY_CONVERT(DATETIME2(0), FechaTexto, 105), @OffsetOrigen), '+00:00')),
    HoraUTC = CONVERT(TIME(0), SWITCHOFFSET(TODATETIMEOFFSET(
        TRY_CONVERT(DATETIME2(0), FechaTexto, 105), @OffsetOrigen), '+00:00'))
WHERE TRY_CONVERT(DATETIME2(0), FechaTexto, 105) IS NOT NULL;

---------------------------------------------------------------------------------------
-- FASE 2 - DEPURACION
-- Reglas de conjunto: cada UPDATE marca las filas invalidas y su motivo.
-- No se borra nada; las filas validas quedan en Estado = 'Pendiente'.
---------------------------------------------------------------------------------------

-- D1: el JSON no corresponde al torneo Mundial esperado.
UPDATE #PartidosStaging SET Estado='Error',
    Detalle=N'El JSON no corresponde al torneo Mundial esperado.'
WHERE Estado='Pendiente' AND (Torneo IS NULL OR Torneo<>N'fjda');

-- D2: deben existir exactamente dos equipos diferentes.
UPDATE #PartidosStaging SET Estado='Error',
    Detalle=N'Deben existir exactamente dos equipos diferentes.'
WHERE Estado='Pendiente'
  AND (CantidadEquipos<>2 OR NULLIF(Equipo1,N'') IS NULL
    OR NULLIF(Equipo2,N'') IS NULL OR Equipo1=Equipo2);

-- D3: el identificador de la fuente debe coincidir con el archivo y no repetirse.
UPDATE #PartidosStaging SET Estado='Error',
    Detalle=N'ID fuente vacio, repetido o diferente del archivo.'
WHERE Estado='Pendiente'
  AND (NULLIF(IdFuente,N'') IS NULL OR Archivo<>IdFuente+N'.json'
    OR EXISTS (SELECT 1 FROM #PartidosStaging o WHERE o.IdFuente=IdFuente AND o.Fila<>Fila));

-- D4: la fecha no se pudo interpretar.
UPDATE #PartidosStaging SET Estado='Error',
    Detalle=N'Fecha/hora invalida: se espera dd-mm-aaaa hh:mm.'
WHERE Estado='Pendiente' AND (FechaUTC IS NULL OR LEN(FechaTexto)<>16);

-- D5: falta un estadio unico en game_info.
UPDATE #PartidosStaging SET Estado='Error',
    Detalle=N'Falta un estadio unico en game_info.'
WHERE Estado='Pendiente' AND NULLIF(SedeOrigen,N'') IS NULL;

-- D6: la fase no se pudo determinar.
UPDATE #PartidosStaging SET IdFase = (SELECT MIN(f.IdFase) FROM #FasesPartidos AS fp
     JOIN partidos.Fase AS f ON f.Descripcion = fp.Fase
     WHERE (fp.Tipo='etapa' AND fp.Valor = #PartidosStaging.Etapa)
        OR (fp.Tipo='partido' AND fp.Valor = #PartidosStaging.IdFuente
            AND NULLIF(#PartidosStaging.Etapa,N'') IS NULL))
WHERE Estado='Pendiente';

UPDATE #PartidosStaging SET Estado='Error',
    Detalle=N'Fase inexistente o ambigua: revise carga 02 y equivalencias.'
WHERE Estado='Pendiente' AND IdFase IS NULL;

-- D7: las selecciones de los dos equipos.
UPDATE #PartidosStaging SET Eq1 = (SELECT MIN(s.IdSeleccion) FROM #EquiposPartidos AS e
     JOIN equipos.Pais AS p ON p.NOMBRE = e.Pais
     JOIN equipos.Seleccion AS s ON s.IdPais=p.IdPais AND s.IdMundial=@idMundial
     WHERE e.Slug = #PartidosStaging.Equipo1),
     Eq2 = (SELECT MIN(s.IdSeleccion) FROM #EquiposPartidos AS e
     JOIN equipos.Pais AS p ON p.NOMBRE = e.Pais
     JOIN equipos.Seleccion AS s ON s.IdPais=p.IdPais AND s.IdMundial=@idMundial
     WHERE e.Slug = #PartidosStaging.Equipo2)
WHERE Estado='Pendiente';

UPDATE #PartidosStaging SET Estado='Error',
    Detalle=N'Seleccion de un equipo inexistente o ambigua: revise carga 07 y equivalencias.'
WHERE Estado='Pendiente' AND (Eq1 IS NULL OR Eq2 IS NULL);

-- D8: la sede.
UPDATE #PartidosStaging SET IdSede = (SELECT MIN(sd.IdSede) FROM #SedesPartidos AS sp
     JOIN equipos.Pais AS p ON p.NOMBRE = sp.Pais
     JOIN sedes.Sede AS sd ON sd.Nombre=sp.NombreSede AND sd.Ciudad=sp.Ciudad AND sd.IdPais=p.IdPais
     WHERE sp.NombreJson = #PartidosStaging.SedeOrigen)
WHERE Estado='Pendiente';

UPDATE #PartidosStaging SET Estado='Error',
    Detalle=N'Sede inexistente o ambigua: revise carga 08 y equivalencias.'
WHERE Estado='Pendiente' AND IdSede IS NULL;

-- D9: la hora local se calcula con la funcion de horarios de la Entrega 5.
UPDATE #PartidosStaging SET HoraLocal = (SELECT CONVERT(TIME(0), sedes.fnFechaHoraLocal(
     #PartidosStaging.FechaUTC, #PartidosStaging.HoraUTC, h.Nombre))
     FROM sedes.Sede AS s JOIN sedes.HusoHorario AS h ON h.IdHuso=s.IdHuso
     WHERE s.IdSede = #PartidosStaging.IdSede)
WHERE Estado='Pendiente';

UPDATE #PartidosStaging SET Estado='Error',
    Detalle=N'La funcion de horarios no reconoce el huso de la sede.'
WHERE Estado='Pendiente' AND HoraLocal IS NULL;

-- D10: la misma fase y los mismos equipos no pueden repetirse en la fuente.
UPDATE #PartidosStaging SET Estado='Error',
    Detalle=N'Misma fase y equipos repetidos en la fuente; revisar identidad.'
WHERE Estado='Pendiente' AND EXISTS (
    SELECT 1 FROM #PartidosStaging o
    WHERE o.IdFase=#PartidosStaging.IdFase AND o.Equipo1=#PartidosStaging.Equipo1
      AND o.Equipo2=#PartidosStaging.Equipo2 AND o.Fila<#PartidosStaging.Fila);

-- Reporte de la depuracion: se informa ANTES de escribir en la tabla real.
SELECT 'FASE 2 - Depuracion de partidos (antes de la persistencia)' AS Fase;
SELECT Estado, COUNT(*) AS Cantidad FROM #PartidosStaging GROUP BY Estado ORDER BY Estado;
SELECT Fila, Archivo, IdFuente, Equipo1, Equipo2, Etapa, FechaTexto, SedeOrigen,
       Marcador1, Marcador2, Estado, Detalle
FROM #PartidosStaging WHERE Estado IN ('Error','Duplicada') ORDER BY Fila;

---------------------------------------------------------------------------------------
-- FASE 3 - PERSISTENCIA
-- Solo las filas que quedaron en 'Pendiente' llegan a la tabla real, siempre
-- a traves de los SP de ABM de la entrega 5.
---------------------------------------------------------------------------------------

DECLARE @fila INT, @idFase INT, @idSede INT, @eq1 INT, @eq2 INT,
        @fecha DATE, @hora TIME(0), @local TIME(0), @idPartido INT,
        @cantidad INT, @estado VARCHAR(20);
DECLARE crsPartidos CURSOR LOCAL FAST_FORWARD FOR
    SELECT Fila, IdFase, IdSede, Eq1, Eq2, FechaUTC, HoraUTC, HoraLocal
    FROM #PartidosStaging WHERE Estado='Pendiente' ORDER BY Fila;
OPEN crsPartidos;
FETCH NEXT FROM crsPartidos INTO @fila, @idFase, @idSede, @eq1, @eq2, @fecha, @hora, @local;
WHILE @@FETCH_STATUS=0
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        SET @idPartido = NULL;
        SELECT @cantidad=COUNT(*), @idPartido=MIN(IdPartido) FROM partidos.Partido
          WITH (UPDLOCK, HOLDLOCK)
          WHERE IdMundial=@idMundial AND IdFase=@idFase AND Eq1=@eq1 AND Eq2=@eq2;
        IF @cantidad>1
            THROW 51703, 'Hay varios partidos con la misma fase y equipos; no se puede decidir cual actualizar.', 1;
        IF @cantidad=0
        BEGIN
            -- Una fase diferente podria ser una correccion o un nuevo cruce: no adivinar.
            IF EXISTS (SELECT 1 FROM partidos.Partido WITH (UPDLOCK, HOLDLOCK)
              WHERE IdMundial=@idMundial AND Eq1=@eq1 AND Eq2=@eq2 AND Fecha=@fecha)
                THROW 51703, 'Ya existe este cruce y fecha con otra fase; revisar antes de insertar.', 1;
            -- La asistencia no viene en la fuente: queda en NULL.
            EXEC SP.uspPartido_Registrar @IdFase=@idFase, @IdSede=@idSede, @IdMundial=@idMundial,
              @Eq1=@eq1, @Eq2=@eq2, @Fecha=@fecha, @HoraUTC=@hora, @HoraLocal=@local, @Asistencia=NULL;
            SELECT @idPartido=IdPartido FROM partidos.Partido
              WHERE IdMundial=@idMundial AND IdFase=@idFase AND Eq1=@eq1 AND Eq2=@eq2;
            SET @estado='Insertado';
        END
        ELSE IF EXISTS (SELECT 1 FROM partidos.Partido WHERE IdPartido=@idPartido
             AND (IdSede<>@idSede OR Fecha<>@fecha OR HoraUTC<>@hora OR HoraLocal<>@local))
        BEGIN
            EXEC SP.uspPartido_Update @Id=@idPartido, @IdSede=@idSede,
              @Fecha=@fecha, @HoraUTC=@hora, @HoraLocal=@local;
            SET @estado='Actualizado';
        END
        ELSE SET @estado='SinCambios';
        COMMIT TRANSACTION;
        UPDATE #PartidosStaging SET IdPartido=@idPartido, Estado=@estado WHERE Fila=@fila;
    END TRY
    BEGIN CATCH
        IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
        UPDATE #PartidosStaging SET Estado='Error', Detalle=ERROR_MESSAGE() WHERE Fila=@fila;
    END CATCH;
    FETCH NEXT FROM crsPartidos INTO @fila, @idFase, @idSede, @eq1, @eq2, @fecha, @hora, @local;
END;
CLOSE crsPartidos;
DEALLOCATE crsPartidos;

-- Reporte final de la persistencia.
SELECT 'FASE 3 - Persistencia de partidos' AS Fase;
SELECT Estado, COUNT(*) AS Cantidad FROM #PartidosStaging GROUP BY Estado ORDER BY Estado;
SELECT Fila, Archivo, IdFuente, Equipo1, Equipo2, Etapa, SedeOrigen, FechaTexto,
       @OffsetOrigen AS OffsetOrigenAsumido, FechaUTC, HoraUTC, HoraLocal,
       Marcador1, Marcador2, Penales1, Penales2, IdPartido, Estado, Detalle
FROM #PartidosStaging ORDER BY FechaUTC, HoraUTC, IdFuente;
SELECT Archivo, Detalle FROM #ErroresArchivos ORDER BY Archivo;

DECLARE @fallos INT = (SELECT COUNT(*) FROM #PartidosStaging WHERE Estado='Error')
                     + (SELECT COUNT(*) FROM #ErroresArchivos);
DROP TABLE #PartidosCrudo;
DROP TABLE #PartidosStaging;
DROP TABLE #EquiposPartidos;
DROP TABLE #SedesPartidos;
DROP TABLE #FasesPartidos;
IF @fallos>0
    THROW 51702, 'Importacion parcial: se conservaron los partidos correctos. Revise el detalle.', 1;
GO
