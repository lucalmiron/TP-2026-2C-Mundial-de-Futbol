-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Comision 02
-- Grupo 7: Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 13/11/2026.
-- Objetivo: cargar el catalogo de motivos de publicidad.Motivo, que usa la
-- tabla de sustituciones como clave foranea. La fuente Promiedos no indica el
-- motivo de cada cambio, asi que el catalogo se define con los motivos
-- estandar del torneo.
--   FASE 1 STAGING     : las lineas del archivo, tal cual.
--   FASE 2 DEPURACION  : reglas de conjunto sobre la staging.
--   FASE 3 PERSISTENCIA : solo los motivos validos pasan por
--                         SP.uspMotivo_Registrar.
-- SSMS: Consulta -> Modo SQLCMD. Ajustar la ruta del servidor SQL.
-- IMPORTANTE: cada integrante debe poner la ruta de su propia PC.
-- :setvar RutaMotivos "C:\ruta\proyecto\Datos\motivos_sustitucion.csv"

--L
:setvar RutaMotivos "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Datos\motivos_sustitucion.csv"

--Fidel
--:setvar RutaMotivos "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Datos\motivos_sustitucion.csv"

USE [MUNDIALtesting];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF @@TRANCOUNT <> 0 OR (2 & @@OPTIONS) = 2
    THROW 51900, 'Ejecute sin transaccion externa y con IMPLICIT_TRANSACTIONS OFF.', 1;
IF OBJECT_ID(N'publicidad.Motivo', N'U') IS NULL
   OR OBJECT_ID(N'SP.uspMotivo_Registrar', N'P') IS NULL
    THROW 51900, 'Faltan tablas o SP ABM. Ejecute primero el instalador.', 1;

IF OBJECT_ID(N'tempdb..#MotivosCrudo') IS NOT NULL DROP TABLE #MotivosCrudo;
IF OBJECT_ID(N'tempdb..#MotivosStaging') IS NOT NULL DROP TABLE #MotivosStaging;

---------------------------------------------------------------------------------------
-- FASE 1 - STAGING
---------------------------------------------------------------------------------------

CREATE TABLE #MotivosCrudo (
    Archivo NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Contenido VARCHAR(MAX) COLLATE Latin1_General_100_CI_AS_SC_UTF8
);
CREATE TABLE #MotivosStaging (
    Fila INT IDENTITY(1,1) PRIMARY KEY,
    Archivo NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    NumeroLinea INT,
    LineaOriginal NVARCHAR(MAX) COLLATE DATABASE_DEFAULT,
    CantidadCampos INT,
    Descripcion NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    IdMotivo INT,
    Estado VARCHAR(20) COLLATE DATABASE_DEFAULT NOT NULL DEFAULT 'Pendiente',
    Detalle NVARCHAR(2048) COLLATE DATABASE_DEFAULT
);

BEGIN TRY
    INSERT #MotivosCrudo (Archivo, Contenido)
    SELECT N'motivos_sustitucion.csv', BulkColumn
    FROM OPENROWSET(BULK '$(RutaMotivos)', SINGLE_BLOB) AS archivo;
END TRY
BEGIN CATCH
    DECLARE @mensaje NVARCHAR(2048) = LEFT(N'No se pudo leer el CSV de motivos: ' + ERROR_MESSAGE(), 2048);
    THROW 51901, @mensaje, 1;
END CATCH;

DECLARE @texto NVARCHAR(MAX) =
    (SELECT CONVERT(NVARCHAR(MAX), Contenido) FROM #MotivosCrudo);

;WITH Lineas AS (
    SELECT ordinal AS Ordinal, REPLACE(value, NCHAR(13), N'') AS Linea
    FROM STRING_SPLIT(@texto, NCHAR(10), 1)
), Numeradas AS (
    SELECT ROW_NUMBER() OVER (ORDER BY Ordinal) AS Numero, Linea
    FROM Lineas WHERE LTRIM(RTRIM(Linea)) <> ''
)
INSERT #MotivosStaging
    (Archivo, NumeroLinea, LineaOriginal, CantidadCampos, Descripcion)
SELECT N'motivos_sustitucion.csv', n.Numero, n.Linea,
       (SELECT COUNT(*) FROM STRING_SPLIT(n.Linea, N',', 1)),
       (SELECT MAX(v.value) FROM STRING_SPLIT(n.Linea, N',', 1) AS v WHERE v.ordinal=1)
FROM Numeradas AS n
WHERE n.Numero > 1;

DECLARE @cabecera NVARCHAR(200);
SELECT TOP (1) @cabecera = LTRIM(RTRIM(REPLACE(v.value, NCHAR(13), N'')))
FROM STRING_SPLIT(@texto, NCHAR(10), 1) AS v
WHERE LTRIM(RTRIM(REPLACE(v.value, NCHAR(13), N''))) <> '';
IF @cabecera IS NULL OR @cabecera <> N'motivo'
    THROW 51901, N'La cabecera de motivos_sustitucion.csv no es la esperada.', 1;

IF NOT EXISTS (SELECT 1 FROM #MotivosStaging)
    THROW 51901, 'El CSV de motivos esta vacio.', 1;

UPDATE #MotivosStaging SET Descripcion = LTRIM(RTRIM(Descripcion));

---------------------------------------------------------------------------------------
-- FASE 2 - DEPURACION
---------------------------------------------------------------------------------------

-- D1: la linea no tiene un solo campo.
UPDATE #MotivosStaging SET Estado='Error',
    Detalle=N'La linea del archivo no tiene 1 campo.'
WHERE Estado='Pendiente' AND CantidadCampos <> 1;

-- D2: el motivo esta vacio o excede los 100 caracteres de la columna.
UPDATE #MotivosStaging SET Estado='Error',
    Detalle=N'El motivo esta vacio o excede los 100 caracteres de Motivo.DESCRIPCION.'
WHERE Estado='Pendiente'
  AND (NULLIF(Descripcion,N'') IS NULL
       OR DATALENGTH(CONVERT(VARCHAR(MAX),Descripcion)) > 100
       OR CONVERT(NVARCHAR(MAX),CONVERT(VARCHAR(MAX),Descripcion)) COLLATE Latin1_General_100_BIN2
            <> Descripcion COLLATE Latin1_General_100_BIN2);

-- D3: el motivo esta repetido en el archivo.
UPDATE f SET Estado='Duplicada', Detalle=N'El motivo ya aparece en otra fila del archivo.'
FROM #MotivosStaging AS f
WHERE f.Estado='Pendiente' AND EXISTS (
    SELECT 1 FROM #MotivosStaging AS o
    WHERE o.Descripcion=f.Descripcion AND o.Fila<f.Fila
);

-- Reporte de la depuracion: se informa ANTES de escribir en la tabla real.
SELECT 'FASE 2 - Depuracion de motivos (antes de la persistencia)' AS Fase;
SELECT Estado, COUNT(*) AS Cantidad FROM #MotivosStaging GROUP BY Estado ORDER BY Estado;
SELECT Fila, NumeroLinea, Descripcion, Estado, Detalle, LineaOriginal
FROM #MotivosStaging WHERE Estado IN ('Error','Duplicada') ORDER BY Fila;

---------------------------------------------------------------------------------------
-- FASE 3 - PERSISTENCIA
---------------------------------------------------------------------------------------

DECLARE @fila INT, @descripcion VARCHAR(100), @id INT, @estado VARCHAR(20);
DECLARE crsMotivos CURSOR LOCAL FAST_FORWARD FOR
    SELECT Fila, CONVERT(VARCHAR(100), Descripcion)
    FROM #MotivosStaging WHERE Estado='Pendiente' ORDER BY Fila;
OPEN crsMotivos;
FETCH NEXT FROM crsMotivos INTO @fila, @descripcion;
WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        SET @id = NULL;
        SELECT @id = IdMotivo FROM publicidad.Motivo WITH (UPDLOCK, HOLDLOCK)
        WHERE Descripcion = @descripcion;
        IF @id IS NULL
        BEGIN
            EXEC SP.uspMotivo_Registrar @descripcion = @descripcion;
            SET @id = NULL;
            SELECT @id = IdMotivo FROM publicidad.Motivo WHERE Descripcion = @descripcion;
            SET @estado='Insertada';
        END
        ELSE SET @estado='SinCambios';
        COMMIT TRANSACTION;
        UPDATE #MotivosStaging SET IdMotivo = @id, Estado = @estado WHERE Fila = @fila;
    END TRY
    BEGIN CATCH
        IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
        UPDATE #MotivosStaging SET Estado='Error', Detalle=ERROR_MESSAGE() WHERE Fila=@fila;
    END CATCH;
    FETCH NEXT FROM crsMotivos INTO @fila, @descripcion;
END;
CLOSE crsMotivos;
DEALLOCATE crsMotivos;

-- Reporte final de la persistencia.
SELECT 'FASE 3 - Persistencia de motivos' AS Fase;
SELECT Estado, COUNT(*) AS Cantidad FROM #MotivosStaging GROUP BY Estado ORDER BY Estado;
SELECT Fila, NumeroLinea, Descripcion, IdMotivo, Estado, Detalle
FROM #MotivosStaging ORDER BY Fila;

DECLARE @fallos INT = (SELECT COUNT(*) FROM #MotivosStaging WHERE Estado='Error');
DROP TABLE #MotivosCrudo;
DROP TABLE #MotivosStaging;
IF @fallos > 0
    THROW 51904, 'Importacion parcial: se conservaron los motivos correctos. Revise el detalle.', 1;
GO
