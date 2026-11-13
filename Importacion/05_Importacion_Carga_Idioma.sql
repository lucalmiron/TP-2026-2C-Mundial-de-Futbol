-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Comision 02
-- Grupo 7: Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 10/11/2026.
-- Objetivo: cargar el catalogo de idiomas leyendo pais_idioma.csv con la
-- metodologia de tres fases. El CSV repite el idioma de cada pais: en la fase
-- de depuracion se descartan las repeticiones y quedan los idiomas distintos.
--   FASE 1 STAGING     : se baja TODO a tablas temporales. #IdiomasCrudo guarda
--                         el archivo original sin modificar y #IdiomasStaging una
--                         fila por linea del CSV (pais, idioma), con las columnas
--                         Estado y Detalle.
--   FASE 2 DEPURACION  : reglas de conjunto (UPDATE) que marcan las filas
--                         invalidas con su motivo, sin borrar ninguna. Se
--                         informa el resultado antes de tocar la base.
--   FASE 3 PERSISTENCIA : solo los idiomas validos pasan por el SP de ABM
--                         (SP.uspIdioma_Registrar).
-- SSMS: Consulta -> Modo SQLCMD. Ajustar la ruta del servidor SQL.
-- IMPORTANTE: cada integrante debe poner la ruta de su propia PC, porque
-- SQL Server lee los archivos desde el disco local del servidor.
-- :setvar RutaIdiomas "C:\ruta\proyecto\Datos\pais_idioma.csv"

:setvar RutaIdiomas "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Datos\pais_idioma.csv"

USE [MUNDIAL];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF UPPER(DB_NAME()) <> N'MUNDIAL'
    THROW 51000, 'Seleccione la base MUNDIAL.', 1;
IF OBJECT_ID(N'arbitros.Idioma', N'U') IS NULL
   OR OBJECT_ID(N'SP.uspIdioma_Registrar', N'P') IS NULL
    THROW 51000, 'Ejecute primero el instalador 00: faltan Idioma o su SP.', 1;
IF @@TRANCOUNT <> 0 OR (2 & @@OPTIONS) = 2
    THROW 51000, 'Ejecute sin transaccion externa y con IMPLICIT_TRANSACTIONS OFF.', 1;

IF OBJECT_ID(N'tempdb..#IdiomasCrudo') IS NOT NULL DROP TABLE #IdiomasCrudo;
IF OBJECT_ID(N'tempdb..#IdiomasStaging') IS NOT NULL DROP TABLE #IdiomasStaging;

---------------------------------------------------------------------------------------
-- FASE 1 - STAGING
-- Todavia no se descarta nada: primero baja todo a tablas temporales.
---------------------------------------------------------------------------------------

-- 1.a) Archivo crudo: los bytes originales del CSV, sin modificar.
CREATE TABLE #IdiomasCrudo (
    Archivo NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Contenido VARCHAR(MAX) COLLATE Latin1_General_100_CI_AS_SC_UTF8
);

-- 1.b) Staging de campos: una fila por linea del CSV.
CREATE TABLE #IdiomasStaging (
    Fila INT IDENTITY(1,1) PRIMARY KEY,
    Archivo NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    NumeroLinea INT,
    LineaOriginal NVARCHAR(MAX) COLLATE DATABASE_DEFAULT,
    CantidadCampos INT,
    Pais NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    Idioma NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    IdIdioma INT,
    Estado VARCHAR(20) COLLATE DATABASE_DEFAULT NOT NULL DEFAULT 'Pendiente',
    Detalle NVARCHAR(2048) COLLATE DATABASE_DEFAULT
);

BEGIN TRY
    -- SQLCMD sustituye la ruta antes de enviar el lote a SQL Server.
    INSERT #IdiomasCrudo (Archivo, Contenido)
    SELECT N'pais_idioma.csv', BulkColumn
    FROM OPENROWSET(
        BULK '$(RutaIdiomas)', SINGLE_BLOB
    ) AS archivo;
END TRY
BEGIN CATCH
    DECLARE @msg NVARCHAR(2048) = LEFT(N'No se pudo leer el CSV: ' + ERROR_MESSAGE(), 2048);
    THROW 51002, @msg, 1;
END CATCH;

DECLARE @texto NVARCHAR(MAX) =
    (SELECT CONVERT(NVARCHAR(MAX), Contenido) FROM #IdiomasCrudo);

-- 1.c) Extraccion: una fila por linea de datos. Se trabaja sobre los bytes
--      originales, de modo que cada fila conserva su numero de linea y su
--      texto tal cual. Una linea malformada queda con la cantidad de campos
--      detectada y se rechaza en la fase 2.
;WITH Lineas AS (
    SELECT ordinal AS Ordinal, REPLACE(value, NCHAR(13), N'') AS Linea
    FROM STRING_SPLIT(@texto, NCHAR(10), 1)
), Numeradas AS (
    SELECT ROW_NUMBER() OVER (ORDER BY Ordinal) AS Numero, Linea
    FROM Lineas WHERE LTRIM(RTRIM(Linea)) <> ''
)
INSERT #IdiomasStaging
    (Archivo, NumeroLinea, LineaOriginal, CantidadCampos, Pais, Idioma)
SELECT N'pais_idioma.csv', n.Numero, n.Linea,
       (SELECT COUNT(*) FROM STRING_SPLIT(n.Linea, N',', 1)),
       (SELECT MAX(v.value) FROM STRING_SPLIT(n.Linea, N',', 1) AS v WHERE v.ordinal=1),
       (SELECT MAX(v.value) FROM STRING_SPLIT(n.Linea, N',', 1) AS v WHERE v.ordinal=2)
FROM Numeradas AS n
WHERE n.Numero > 1;

-- 1.d) Se valida la cabecera del archivo: si el formato cambia, se aborta antes
--      de cargar nada en lugar de interpretar los datos equivocados.
DECLARE @cabecera NVARCHAR(200);
SELECT TOP (1) @cabecera = LTRIM(RTRIM(REPLACE(v.value, NCHAR(13), N'')))
FROM STRING_SPLIT(@texto, NCHAR(10), 1) AS v
WHERE LTRIM(RTRIM(REPLACE(v.value, NCHAR(13), N''))) <> '';
IF @cabecera IS NULL OR @cabecera <> N'pais,idioma'
    THROW 51003, N'La cabecera de pais_idioma.csv no es la esperada; no se cargo ningun idioma.', 1;

IF NOT EXISTS (SELECT 1 FROM #IdiomasStaging)
    THROW 51003, 'El CSV no aporto ningun idioma. Revise ruta y formato.', 1;

-- Normalizacion de espacios: el dato se conserva, solo se limpian los bordes.
UPDATE #IdiomasStaging SET
    Pais = LTRIM(RTRIM(Pais)),
    Idioma = LTRIM(RTRIM(Idioma));

---------------------------------------------------------------------------------------
-- FASE 2 - DEPURACION
-- Reglas de conjunto: cada UPDATE marca las filas invalidas y su motivo.
-- No se borra nada; las filas validas quedan en Estado = 'Pendiente'.
---------------------------------------------------------------------------------------

-- D1: la linea no tiene la cantidad de campos del archivo.
UPDATE #IdiomasStaging SET Estado='Error',
    Detalle=N'La linea del archivo no tiene 2 campos.'
WHERE Estado='Pendiente' AND CantidadCampos <> 2;

-- D2: falta el idioma o el pais.
UPDATE #IdiomasStaging SET Estado='Error',
    Detalle=N'El idioma o el pais esta vacio.'
WHERE Estado='Pendiente'
  AND (NULLIF(Idioma,N'') IS NULL OR NULLIF(Pais,N'') IS NULL);

-- D3: el idioma no cabe fielmente en VARCHAR(20) (columna de la tabla).
UPDATE #IdiomasStaging SET Estado='Error',
    Detalle=N'El idioma no cabe fielmente en VARCHAR(20).'
WHERE Estado='Pendiente'
  AND (DATALENGTH(CONVERT(VARCHAR(MAX),Idioma))>20
    OR CONVERT(NVARCHAR(MAX),CONVERT(VARCHAR(MAX),Idioma)) COLLATE Latin1_General_100_BIN2
         <> Idioma COLLATE Latin1_General_100_BIN2);

-- D4: el mismo idioma aparece en otro pais: se conserva la primera aparicion.
--      Es lo esperable: el CSV asigna un idioma a cada pais.
UPDATE f SET Estado='Duplicada',
    Detalle=N'El idioma ya aparece en otra fila del archivo.'
FROM #IdiomasStaging AS f
WHERE f.Estado='Pendiente' AND EXISTS (
    SELECT 1 FROM #IdiomasStaging AS anterior
    WHERE anterior.Estado='Pendiente'
      AND anterior.Idioma=f.Idioma AND anterior.Fila<f.Fila
);

-- Reporte de la depuracion: se informa ANTES de escribir en la tabla real.
SELECT 'FASE 2 - Depuracion de idiomas (antes de la persistencia)' AS Fase;
SELECT Estado, COUNT(*) AS Cantidad FROM #IdiomasStaging GROUP BY Estado ORDER BY Estado;
SELECT Fila, NumeroLinea, Pais, Idioma, Estado, Detalle, LineaOriginal
FROM #IdiomasStaging WHERE Estado IN ('Error','Duplicada') ORDER BY Fila;

---------------------------------------------------------------------------------------
-- FASE 3 - PERSISTENCIA
-- Solo las filas que quedaron en 'Pendiente' llegan a la tabla real, siempre
-- a traves del SP de ABM de la entrega 5.
---------------------------------------------------------------------------------------

DECLARE @fila INT, @descripcion VARCHAR(20), @id INT, @estado VARCHAR(20);
DECLARE idiomas CURSOR LOCAL FAST_FORWARD FOR
    SELECT Fila, CONVERT(VARCHAR(20), Idioma)
    FROM #IdiomasStaging WHERE Estado='Pendiente' ORDER BY Fila;
OPEN idiomas;
FETCH NEXT FROM idiomas INTO @fila, @descripcion;
WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        -- Retener bloqueos hasta confirmar evita duplicados entre importadores.
        SET @id = NULL;
        SELECT @id = IdIdioma FROM arbitros.Idioma WITH (UPDLOCK, HOLDLOCK)
        WHERE Descripcion = @descripcion;
        IF @id IS NULL
        BEGIN
            EXEC SP.uspIdioma_Registrar @descripcion = @descripcion;
            SELECT @id = IdIdioma FROM arbitros.Idioma WHERE Descripcion = @descripcion;
            SET @estado = 'Insertada';
        END
        ELSE SET @estado = 'SinCambios';
        COMMIT TRANSACTION;
        UPDATE #IdiomasStaging SET IdIdioma = @id, Estado = @estado WHERE Fila = @fila;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        UPDATE #IdiomasStaging SET Estado='Error', Detalle=ERROR_MESSAGE() WHERE Fila = @fila;
    END CATCH;
    FETCH NEXT FROM idiomas INTO @fila, @descripcion;
END;
CLOSE idiomas;
DEALLOCATE idiomas;

-- Reporte final de la persistencia.
SELECT 'FASE 3 - Persistencia de idiomas' AS Fase;
SELECT Estado, COUNT(*) AS Cantidad FROM #IdiomasStaging GROUP BY Estado ORDER BY Estado;
SELECT Fila, NumeroLinea, Pais, Idioma, IdIdioma, Estado, Detalle
FROM #IdiomasStaging ORDER BY Fila;

DECLARE @fallos INT = (SELECT COUNT(*) FROM #IdiomasStaging WHERE Estado='Error');
DROP TABLE #IdiomasCrudo;
DROP TABLE #IdiomasStaging;
IF @fallos > 0
    THROW 51001, 'Hubo errores. Revise el detalle; las altas exitosas se conservaron.', 1;
GO
