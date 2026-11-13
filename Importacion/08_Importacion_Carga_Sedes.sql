-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Comision 02
-- Grupo 7: Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 10/11/2026.
-- Objetivo: importar sedes.csv con la metodologia de tres fases.
--   FASE 1 STAGING     : se baja TODO a tablas temporales. #SedesCrudo y
--                         #EquivalenciasCrudo guardan los archivos originales
--                         sin modificar (trazabilidad). #SedesStaging y
--                         #EquivalenciasStaging guardan una fila por registro,
--                         con los campos del dominio y las columnas Estado y
--                         Detalle donde la fase 2 deja la depuracion.
--   FASE 2 DEPURACION  : reglas de conjunto (UPDATE) que marcan las filas
--                         invalidas con su motivo, sin borrar ninguna. Se
--                         informa el resultado antes de tocar la base.
--   FASE 3 PERSISTENCIA : solo las filas validas pasan por los SP de ABM
--                         (SP.uspSede_Registrar / SP.uspSede_Update).
-- Requiere las cargas 04 (husos) y 06 (paises).
-- SSMS: Consulta -> Modo SQLCMD. Ajustar ambas rutas del servidor SQL.
-- IMPORTANTE: cada integrante debe poner las rutas de su propia PC, porque
-- SQL Server lee los archivos desde el disco local del servidor.
-- :setvar RutaSedes "C:\ruta\proyecto\Datos\Sedes\sedes.csv"
-- :setvar RutaEquivalencias "C:\ruta\proyecto\Datos\equivalencias_ubicacion_sedes.csv"

--L
:setvar RutaSedes "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Datos\Sedes\sedes.csv"
:setvar RutaEquivalencias "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Datos\equivalencias_ubicacion_sedes.csv"

--Fidel
--:setvar RutaSedes "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Datos\Sedes\sedes.csv"
--:setvar RutaEquivalencias "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Datos\equivalencias_ubicacion_sedes.csv"

USE MUNDIALtesting;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF @@TRANCOUNT <> 0 OR (2 & @@OPTIONS) = 2
    THROW 51400, 'Ejecute sin transaccion externa y con IMPLICIT_TRANSACTIONS OFF.', 1;
IF OBJECT_ID(N'sedes.Sede',N'U') IS NULL
   OR OBJECT_ID(N'equipos.Pais',N'U') IS NULL
   OR OBJECT_ID(N'sedes.HusoHorario',N'U') IS NULL
   OR OBJECT_ID(N'SP.uspSede_Registrar',N'P') IS NULL
   OR OBJECT_ID(N'SP.uspSede_Update',N'P') IS NULL
    THROW 51400, 'Faltan tablas o SP ABM. Ejecute primero el instalador.', 1;

IF OBJECT_ID(N'tempdb..#SedesCrudo') IS NOT NULL DROP TABLE #SedesCrudo;
IF OBJECT_ID(N'tempdb..#SedesStaging') IS NOT NULL DROP TABLE #SedesStaging;
IF OBJECT_ID(N'tempdb..#EquivalenciasCrudo') IS NOT NULL DROP TABLE #EquivalenciasCrudo;
IF OBJECT_ID(N'tempdb..#EquivalenciasStaging') IS NOT NULL DROP TABLE #EquivalenciasStaging;

---------------------------------------------------------------------------------------
-- FASE 1 - STAGING
-- Todavia no se descarta nada: primero baja todo a tablas temporales.
---------------------------------------------------------------------------------------

-- 1.a) Archivo crudo: los bytes originales del archivo, sin modificar.
--      Se guardan en VARCHAR con collation UTF-8 para que el texto se lea
--      correctamente sin re-serializar el archivo (mismo criterio que el
--      importador 11).
CREATE TABLE #SedesCrudo (
    Archivo NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Contenido VARCHAR(MAX) COLLATE Latin1_General_100_CI_AS_SC_UTF8
);
CREATE TABLE #EquivalenciasCrudo (
    Archivo NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Contenido VARCHAR(MAX) COLLATE Latin1_General_100_CI_AS_SC_UTF8
);

-- 1.b) Staging de campos: una fila por registro del archivo.
CREATE TABLE #SedesStaging (
    Fila INT IDENTITY(1,1) PRIMARY KEY,
    Archivo NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    NumeroLinea INT,
    LineaOriginal NVARCHAR(MAX) COLLATE DATABASE_DEFAULT,
    CantidadCampos INT,
    Nombre NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    Ciudad NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    CapacidadTexto NVARCHAR(50) COLLATE DATABASE_DEFAULT,
    PaisOriginal NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    ZonaOriginal NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    PaisBd NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    ZonaIana NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    Estado VARCHAR(20) COLLATE DATABASE_DEFAULT NOT NULL DEFAULT 'Pendiente',
    Detalle NVARCHAR(2048) COLLATE DATABASE_DEFAULT
);
CREATE TABLE #EquivalenciasStaging (
    Fila INT IDENTITY(1,1) PRIMARY KEY,
    Archivo NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    NumeroLinea INT,
    LineaOriginal NVARCHAR(MAX) COLLATE DATABASE_DEFAULT,
    CantidadCampos INT,
    PaisCsv NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    CiudadCsv NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    PaisBd NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    ZonaIana NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    Estado VARCHAR(20) COLLATE DATABASE_DEFAULT NOT NULL DEFAULT 'Pendiente',
    Detalle NVARCHAR(2048) COLLATE DATABASE_DEFAULT
);

BEGIN TRY
    INSERT #SedesCrudo (Archivo, Contenido)
    SELECT N'sedes.csv', BulkColumn
    FROM OPENROWSET(BULK '$(RutaSedes)', SINGLE_BLOB) AS archivo;

    INSERT #EquivalenciasCrudo (Archivo, Contenido)
    SELECT N'equivalencias_ubicacion_sedes.csv', BulkColumn
    FROM OPENROWSET(BULK '$(RutaEquivalencias)', SINGLE_BLOB) AS archivo;
END TRY
BEGIN CATCH
    DECLARE @mensaje NVARCHAR(2048) = LEFT(N'No se pudieron leer los CSV; no se modificaron sedes. '
                                           + ERROR_MESSAGE(),2048);
    THROW 51401, @mensaje, 1;
END CATCH;

-- 1.c) Extraccion: una fila por linea de datos de cada archivo.
--      Se trabaja sobre los bytes originales, de modo que cada fila conserva
--      su numero de linea y su texto tal cual. Una linea malformada queda
--      con la cantidad de campos detectada y se rechaza en la fase 2; no
--      invalida el resto del archivo.
DECLARE @textoSedes NVARCHAR(MAX) =
    (SELECT CONVERT(NVARCHAR(MAX), Contenido) FROM #SedesCrudo);
DECLARE @textoEquiv NVARCHAR(MAX) =
    (SELECT CONVERT(NVARCHAR(MAX), Contenido) FROM #EquivalenciasCrudo);

;WITH Lineas AS (
    SELECT ordinal AS Ordinal, REPLACE(value, NCHAR(13), N'') AS Linea
    FROM STRING_SPLIT(@textoSedes, NCHAR(10), 1)
), Numeradas AS (
    SELECT ROW_NUMBER() OVER (ORDER BY Ordinal) AS Numero, Linea
    FROM Lineas WHERE LTRIM(RTRIM(Linea)) <> ''
)
INSERT #SedesStaging
    (Archivo, NumeroLinea, LineaOriginal, CantidadCampos,
     Nombre, Ciudad, CapacidadTexto, PaisOriginal, ZonaOriginal)
SELECT N'sedes.csv', n.Numero, n.Linea,
       (SELECT COUNT(*) FROM STRING_SPLIT(n.Linea, N',', 1)),
       (SELECT MAX(v.value) FROM STRING_SPLIT(n.Linea, N',', 1) AS v WHERE v.ordinal=1),
       (SELECT MAX(v.value) FROM STRING_SPLIT(n.Linea, N',', 1) AS v WHERE v.ordinal=2),
       (SELECT MAX(v.value) FROM STRING_SPLIT(n.Linea, N',', 1) AS v WHERE v.ordinal=3),
       (SELECT MAX(v.value) FROM STRING_SPLIT(n.Linea, N',', 1) AS v WHERE v.ordinal=4),
       (SELECT MAX(v.value) FROM STRING_SPLIT(n.Linea, N',', 1) AS v WHERE v.ordinal=5)
FROM Numeradas AS n
WHERE n.Numero > 1;

;WITH Lineas AS (
    SELECT ordinal AS Ordinal, REPLACE(value, NCHAR(13), N'') AS Linea
    FROM STRING_SPLIT(@textoEquiv, NCHAR(10), 1)
), Numeradas AS (
    SELECT ROW_NUMBER() OVER (ORDER BY Ordinal) AS Numero, Linea
    FROM Lineas WHERE LTRIM(RTRIM(Linea)) <> ''
)
INSERT #EquivalenciasStaging
    (Archivo, NumeroLinea, LineaOriginal, CantidadCampos, PaisCsv, CiudadCsv, PaisBd, ZonaIana)
SELECT N'equivalencias_ubicacion_sedes.csv', n.Numero, n.Linea,
       (SELECT COUNT(*) FROM STRING_SPLIT(n.Linea, N',', 1)),
       (SELECT MAX(v.value) FROM STRING_SPLIT(n.Linea, N',', 1) AS v WHERE v.ordinal=1),
       (SELECT MAX(v.value) FROM STRING_SPLIT(n.Linea, N',', 1) AS v WHERE v.ordinal=2),
       (SELECT MAX(v.value) FROM STRING_SPLIT(n.Linea, N',', 1) AS v WHERE v.ordinal=3),
       (SELECT MAX(v.value) FROM STRING_SPLIT(n.Linea, N',', 1) AS v WHERE v.ordinal=4)
FROM Numeradas AS n
WHERE n.Numero > 1;

-- 1.d) Se valida la cabecera de los archivos: si el formato cambia, se aborta
--      antes de cargar nada en lugar de interpretar los datos equivocados.
--      La cabecera es la primera linea no vacia del archivo.
DECLARE @cabeceraSedes NVARCHAR(200);
SELECT TOP (1) @cabeceraSedes = LTRIM(RTRIM(REPLACE(v.value, NCHAR(13), N'')))
FROM STRING_SPLIT(@textoSedes, NCHAR(10), 1) AS v
WHERE LTRIM(RTRIM(REPLACE(v.value, NCHAR(13), N''))) <> '';
IF @cabeceraSedes IS NULL
   OR @cabeceraSedes <> N'nombre,ciudad,capacidad,pais,zona_horaria'
    THROW 51402, N'La cabecera de sedes.csv no es la esperada; no se modificaron sedes.', 1;
DECLARE @cabeceraEquiv NVARCHAR(200);
SELECT TOP (1) @cabeceraEquiv = LTRIM(RTRIM(REPLACE(v.value, NCHAR(13), N'')))
FROM STRING_SPLIT(@textoEquiv, NCHAR(10), 1) AS v
WHERE LTRIM(RTRIM(REPLACE(v.value, NCHAR(13), N''))) <> '';
IF @cabeceraEquiv IS NULL
   OR @cabeceraEquiv <> N'PaisCsv,CiudadCsv,PaisBd,ZonaIana'
    THROW 51402, N'La cabecera de equivalencias_ubicacion_sedes.csv no es la esperada; no se modificaron sedes.', 1;

IF NOT EXISTS (SELECT 1 FROM #SedesStaging)
    THROW 51402, 'El CSV de sedes esta vacio.', 1;

-- Normalizacion de espacios: el dato se conserva, solo se limpian los bordes.
UPDATE #SedesStaging SET
    Nombre = LTRIM(RTRIM(Nombre)),
    Ciudad = LTRIM(RTRIM(Ciudad)),
    CapacidadTexto = LTRIM(RTRIM(CapacidadTexto)),
    PaisOriginal = LTRIM(RTRIM(PaisOriginal)),
    ZonaOriginal = LTRIM(RTRIM(ZonaOriginal));
UPDATE #EquivalenciasStaging SET
    PaisCsv = LTRIM(RTRIM(PaisCsv)),
    CiudadCsv = LTRIM(RTRIM(CiudadCsv)),
    PaisBd = LTRIM(RTRIM(PaisBd)),
    ZonaIana = LTRIM(RTRIM(ZonaIana));

---------------------------------------------------------------------------------------
-- FASE 2 - DEPURACION
-- Reglas de conjunto: cada UPDATE marca las filas invalidas y su motivo.
-- No se borra nada; las filas validas quedan en Estado = 'Pendiente'.
---------------------------------------------------------------------------------------

-- D1: la linea no tiene la cantidad de campos del archivo.
UPDATE #SedesStaging SET Estado='Error',
    Detalle=N'La linea del archivo no tiene 5 campos.'
WHERE Estado='Pendiente' AND CantidadCampos <> 5;

-- D2: falta el nombre, la ciudad o el pais.
UPDATE #SedesStaging SET Estado='Error',
    Detalle=N'Nombre, ciudad o pais vacio.'
WHERE Estado='Pendiente'
  AND (NULLIF(Nombre,N'') IS NULL OR NULLIF(Ciudad,N'') IS NULL OR NULLIF(PaisOriginal,N'') IS NULL);

-- D3: la capacidad no es un entero positivo.
UPDATE #SedesStaging SET Estado='Error',
    Detalle=N'Capacidad ausente, no numerica o no positiva.'
WHERE Estado='Pendiente'
  AND (CapacidadTexto IS NULL OR TRY_CONVERT(INT, CapacidadTexto) IS NULL
       OR TRY_CONVERT(INT, CapacidadTexto) <= 0);

-- D4: el nombre o la ciudad no caben fielmente en VARCHAR(30).
UPDATE #SedesStaging SET Estado='Error',
    Detalle=N'Nombre o ciudad no caben fielmente en VARCHAR(30).'
WHERE Estado='Pendiente'
  AND (DATALENGTH(CONVERT(VARCHAR(MAX),Nombre))>30
    OR DATALENGTH(CONVERT(VARCHAR(MAX),Ciudad))>30
    OR CONVERT(NVARCHAR(MAX),CONVERT(VARCHAR(MAX),Nombre)) COLLATE Latin1_General_100_BIN2
         <> Nombre COLLATE Latin1_General_100_BIN2
    OR CONVERT(NVARCHAR(MAX),CONVERT(VARCHAR(MAX),Ciudad)) COLLATE Latin1_General_100_BIN2
         <> Ciudad COLLATE Latin1_General_100_BIN2);

-- D5: la misma sede con datos contradictorios: se rechazan todas sus versiones.
UPDATE r SET Estado='Error',
    Detalle=N'La misma sede tiene datos contradictorios en el CSV.'
FROM #SedesStaging AS r
WHERE r.Estado='Pendiente'
  AND EXISTS (SELECT 1 FROM #SedesStaging AS o
              WHERE o.Nombre=r.Nombre AND o.Ciudad=r.Ciudad
                AND (ISNULL(o.PaisOriginal,N'')<>ISNULL(r.PaisOriginal,N'')
                  OR ISNULL(o.CapacidadTexto,N'')<>ISNULL(r.CapacidadTexto,N'')
                  OR ISNULL(o.ZonaOriginal,N'')<>ISNULL(r.ZonaOriginal,N'')));

-- D6: falta una equivalencia unica y completa para el pais y la ciudad.
UPDATE r SET Estado='Error',
    Detalle=N'Falta una equivalencia unica y completa para el pais y la ciudad.'
FROM #SedesStaging AS r
WHERE r.Estado='Pendiente'
  AND (SELECT COUNT(DISTINCT CONCAT(e.PaisBd,N'|',e.ZonaIana)) FROM #EquivalenciasStaging AS e
       WHERE e.PaisCsv=r.PaisOriginal AND e.CiudadCsv=r.Ciudad) <> 1;

-- D7: el pais de la equivalencia no esta cargado en equipos.Pais.
UPDATE r SET Estado='Error',
    Detalle=N'El pais de la equivalencia no existe en equipos.Pais: revise la carga 06.'
FROM #SedesStaging AS r
WHERE r.Estado='Pendiente'
  AND EXISTS (SELECT 1 FROM #EquivalenciasStaging AS e
              WHERE e.PaisCsv=r.PaisOriginal AND e.CiudadCsv=r.Ciudad
                AND NOT EXISTS (SELECT 1 FROM equipos.Pais AS p
                                WHERE p.NOMBRE = e.PaisBd COLLATE DATABASE_DEFAULT));

-- D8: el pais de la equivalencia es ambiguo en equipos.Pais.
UPDATE r SET Estado='Error',
    Detalle=N'El pais de la equivalencia es ambiguo en equipos.Pais: revise la carga 06.'
FROM #SedesStaging AS r
WHERE r.Estado='Pendiente'
  AND EXISTS (SELECT 1 FROM #EquivalenciasStaging AS e
              WHERE e.PaisCsv=r.PaisOriginal AND e.CiudadCsv=r.Ciudad
                AND (SELECT COUNT(*) FROM equipos.Pais AS p
                     WHERE p.NOMBRE = e.PaisBd COLLATE DATABASE_DEFAULT) <> 1);

-- D9: la zona horaria no esta cargada en sedes.HusoHorario o es ambigua.
UPDATE r SET Estado='Error',
    Detalle=N'La zona horaria no existe o es ambigua en sedes.HusoHorario: revise la carga 04.'
FROM #SedesStaging AS r
WHERE r.Estado='Pendiente'
  AND EXISTS (SELECT 1 FROM #EquivalenciasStaging AS e
              WHERE e.PaisCsv=r.PaisOriginal AND e.CiudadCsv=r.Ciudad
                AND (SELECT COUNT(*) FROM sedes.HusoHorario AS h
                     WHERE h.Nombre = e.ZonaIana COLLATE DATABASE_DEFAULT) <> 1);

-- D10: la misma sede repetida en el CSV con datos identicos: solo se procesa la primera.
;WITH Repetidas AS (
    SELECT Fila, ROW_NUMBER() OVER (PARTITION BY Nombre, Ciudad ORDER BY Fila) AS Numero
    FROM #SedesStaging WHERE Estado='Pendiente'
)
UPDATE r SET Estado='Duplicada', Detalle=N'Sede repetida en el CSV.'
FROM #SedesStaging AS r
JOIN Repetidas AS rp ON rp.Fila = r.Fila
WHERE r.Estado='Pendiente' AND rp.Numero > 1;

-- D11: se copia el pais de la base y la zona IANA a la fila ya depurada.
UPDATE r SET PaisBd = e.PaisBd, ZonaIana = e.ZonaIana
FROM #SedesStaging AS r
JOIN (SELECT PaisCsv, CiudadCsv, MIN(PaisBd) AS PaisBd, MIN(ZonaIana) AS ZonaIana
      FROM #EquivalenciasStaging GROUP BY PaisCsv, CiudadCsv) AS e
  ON e.PaisCsv = r.PaisOriginal AND e.CiudadCsv = r.Ciudad
WHERE r.Estado='Pendiente';

-- Reporte de la depuracion: se informa ANTES de escribir en la tabla real.
SELECT 'FASE 2 - Depuracion de sedes (antes de la persistencia)' AS Fase;
SELECT Estado, COUNT(*) AS Cantidad FROM #SedesStaging GROUP BY Estado ORDER BY Estado;
SELECT Fila, NumeroLinea, Nombre, Ciudad, PaisOriginal, Estado, Detalle, LineaOriginal
FROM #SedesStaging WHERE Estado IN ('Error','Duplicada') ORDER BY Fila;

---------------------------------------------------------------------------------------
-- FASE 3 - PERSISTENCIA
-- Solo las filas que quedaron en 'Pendiente' llegan a la tabla real, siempre
-- a traves de los SP de ABM de la entrega 5.
---------------------------------------------------------------------------------------

DECLARE @fila INT, @nombre NVARCHAR(200), @ciudad NVARCHAR(200), @capTexto NVARCHAR(50),
        @paisBd NVARCHAR(200), @zona NVARCHAR(200),
        @cantidad INT, @capacidad INT, @idPais INT, @idHuso INT, @idSede INT,
        @nombreSp VARCHAR(30), @ciudadSp VARCHAR(30), @estado VARCHAR(20);
DECLARE crsSedes CURSOR LOCAL FAST_FORWARD FOR
    SELECT Fila, Nombre, Ciudad, CapacidadTexto, PaisBd, ZonaIana
    FROM #SedesStaging WHERE Estado='Pendiente' ORDER BY Fila;
OPEN crsSedes;
FETCH NEXT FROM crsSedes INTO @fila,@nombre,@ciudad,@capTexto,@paisBd,@zona;
WHILE @@FETCH_STATUS=0
BEGIN
    BEGIN TRY
        SET @capacidad = TRY_CONVERT(INT, @capTexto);
        SET @nombreSp = CONVERT(VARCHAR(30), @nombre);
        SET @ciudadSp = CONVERT(VARCHAR(30), @ciudad);
        BEGIN TRANSACTION;
        SELECT @cantidad=COUNT(*),@idPais=MIN(IdPais)
        FROM equipos.Pais WITH (HOLDLOCK)
        WHERE NOMBRE = @paisBd COLLATE DATABASE_DEFAULT;
        IF @cantidad<>1 THROW 51403, 'Pais inexistente o ambiguo: revise la carga 06.', 1;
        SELECT @cantidad=COUNT(*),@idHuso=MIN(IdHuso)
        FROM sedes.HusoHorario WITH (HOLDLOCK)
        WHERE Nombre = @zona COLLATE DATABASE_DEFAULT;
        IF @cantidad<>1 THROW 51403, 'Huso inexistente o ambiguo: revise la carga 04.', 1;
        SELECT @cantidad=COUNT(*),@idSede=MIN(IdSede)
        FROM sedes.Sede WITH (UPDLOCK,HOLDLOCK)
        WHERE Nombre=@nombreSp AND Ciudad=@ciudadSp;
        IF @cantidad>1 THROW 51403, 'Existen sedes duplicadas en la base.', 1;
        IF @cantidad=0
        BEGIN
            EXEC SP.uspSede_Registrar @nombre=@nombreSp,@ciudad=@ciudadSp,
                @capacidad=@capacidad,@pais=@idPais,@huso=@idHuso;
            SET @estado='Insertada';
        END
        ELSE IF EXISTS (SELECT 1 FROM sedes.Sede WHERE IdSede=@idSede
                        AND (Capacidad<>@capacidad OR IdPais<>@idPais OR IdHuso<>@idHuso))
        BEGIN
            EXEC SP.uspSede_Update @idSede=@idSede,
                @capacidad=@capacidad,@pais=@idPais,@huso=@idHuso;
            SET @estado='Actualizada';
        END
        ELSE SET @estado='SinCambios';
        COMMIT TRANSACTION;
        UPDATE #SedesStaging SET Estado=@estado WHERE Fila=@fila;
    END TRY
    BEGIN CATCH
        IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
        UPDATE #SedesStaging SET Estado='Error',Detalle=ERROR_MESSAGE() WHERE Fila=@fila;
    END CATCH;
    FETCH NEXT FROM crsSedes INTO @fila,@nombre,@ciudad,@capTexto,@paisBd,@zona;
END;
CLOSE crsSedes;
DEALLOCATE crsSedes;

-- Reporte final de la persistencia.
SELECT 'FASE 3 - Persistencia de sedes' AS Fase;
SELECT Estado, COUNT(*) AS Cantidad FROM #SedesStaging GROUP BY Estado ORDER BY Estado;
SELECT Fila, NumeroLinea, Nombre, Ciudad, CapacidadTexto AS Capacidad, PaisOriginal,
       PaisBd, ZonaIana, Estado, Detalle
FROM #SedesStaging ORDER BY Fila;

DECLARE @fallos INT = (SELECT COUNT(*) FROM #SedesStaging WHERE Estado='Error');
DROP TABLE #SedesCrudo;
DROP TABLE #SedesStaging;
DROP TABLE #EquivalenciasCrudo;
DROP TABLE #EquivalenciasStaging;
IF @fallos>0
    THROW 51404, 'Importacion parcial: se conservaron las sedes correctas. Revise el detalle.', 1;
GO
