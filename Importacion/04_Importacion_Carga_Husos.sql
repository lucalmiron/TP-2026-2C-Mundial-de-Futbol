-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Comision 02
-- Grupo 7: Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 10/11/2026.
-- Objetivo: importar el JSON original de GET /timezones (OpenTimezone) con la
-- metodologia de tres fases.
--   FASE 1 STAGING     : se baja TODO a tablas temporales. #HusosCrudo guarda
--                         el archivo original sin modificar y #HusosStaging una
--                         fila por elemento del arreglo, con los campos del
--                         dominio y las columnas Estado y Detalle.
--   FASE 2 DEPURACION  : reglas de conjunto (UPDATE) que marcan los elementos
--                         invalidos con su motivo, sin borrar ninguno. Se
--                         informa el resultado antes de tocar la base.
--   FASE 3 PERSISTENCIA : solo los elementos validos pasan por el SP de ABM
--                         (SP.uspHusoHorario_Registrar).
-- SSMS: Consulta -> Modo SQLCMD. Ajustar la ruta del servidor SQL.
-- IMPORTANTE: cada integrante debe poner la ruta de su propia PC, porque
-- SQL Server lee los archivos desde el disco local del servidor.
-- :setvar RutaHusos "C:\ruta\proyecto\Datos\Husos_horarios\husos_horarios.json"

--L
:setvar RutaHusos "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Datos\Husos_horarios\husos_horarios.json"

--Fidel
--:setvar RutaHusos "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Datos\Husos_horarios\husos_horarios.json"

USE MUNDIALtesting
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

-- Se confirma cada fila por separado para conservar las validas si otra falla.
IF @@TRANCOUNT <> 0
    THROW 51000, 'Ejecute el importador fuera de una transaccion externa.', 1;
IF (2 & @@OPTIONS) = 2
    THROW 51000, 'Desactive IMPLICIT_TRANSACTIONS antes de importar.', 1;
IF NULLIF(LTRIM(RTRIM(N'$(RutaHusos)')), N'') IS NULL
    THROW 51000, 'Debe indicar la ruta del JSON en el servidor SQL.', 1;
IF OBJECT_ID(N'sedes.HusoHorario', N'U') IS NULL
   OR OBJECT_ID(N'SP.uspHusoHorario_Registrar', N'P') IS NULL
    THROW 51000, 'Faltan la tabla HusoHorario o su SP de registro.', 1;
IF COL_LENGTH(N'sedes.HusoHorario', N'IdPais') IS NOT NULL
    THROW 51000, 'Este importador requiere la version de HusoHorario sin IdPais.', 1;

IF OBJECT_ID(N'tempdb..#HusosCrudo') IS NOT NULL DROP TABLE #HusosCrudo;
IF OBJECT_ID(N'tempdb..#HusosStaging') IS NOT NULL DROP TABLE #HusosStaging;

---------------------------------------------------------------------------------------
-- FASE 1 - STAGING
-- Todavia no se descarta nada: primero baja todo a tablas temporales.
---------------------------------------------------------------------------------------

-- 1.a) Archivo crudo: los bytes originales del JSON, sin modificar.
--      VARCHAR con collation UTF-8 para leer el texto sin re-serializar.
CREATE TABLE #HusosCrudo (
    Archivo NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Contenido VARCHAR(MAX) COLLATE Latin1_General_100_CI_AS_SC_UTF8
);

-- 1.b) Staging de campos: una fila por elemento del arreglo JSON.
CREATE TABLE #HusosStaging (
    Fila INT IDENTITY(1,1) PRIMARY KEY,
    Archivo NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    NumeroElemento INT,
    TipoElemento INT,
    CantidadId INT,
    TipoId INT,
    IdZona NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    DisplayName NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    BaseOffset NVARCHAR(50) COLLATE DATABASE_DEFAULT,
    IdHuso INT,
    Estado VARCHAR(20) COLLATE DATABASE_DEFAULT NOT NULL DEFAULT 'Pendiente',
    Detalle NVARCHAR(2048) COLLATE DATABASE_DEFAULT
);

BEGIN TRY
    -- SQLCMD sustituye la ruta antes de enviar el lote a SQL Server.
    INSERT #HusosCrudo (Archivo, Contenido)
    SELECT N'husos_horarios.json', BulkColumn
    FROM OPENROWSET(
        BULK '$(RutaHusos)', SINGLE_BLOB
    ) AS archivo;
END TRY
BEGIN CATCH
    DECLARE @errorLectura NVARCHAR(2048) = LEFT(
        N'No se pudo leer el JSON. Verifique ruta y permisos del servicio SQL. '
        + ERROR_MESSAGE(), 2048);
    THROW 51001, @errorLectura, 1;
END CATCH;

DECLARE @json NVARCHAR(MAX) =
    (SELECT CONVERT(NVARCHAR(MAX), Contenido) FROM #HusosCrudo);

-- 1.c) Se valida la forma del documento antes de interpretarlo.
IF LEFT(@json, 1) = NCHAR(65279) SET @json = SUBSTRING(@json, 2, LEN(@json));
IF ISNULL(ISJSON(@json), 0) <> 1
    THROW 51002, 'El archivo no contiene JSON valido; no se cargo ninguna fila.', 1;
-- Reconocer el primer caracter distinto de los espacios JSON permitidos.
DECLARE @primero INT = PATINDEX(N'%[^' + NCHAR(32) + NCHAR(9)
                             + NCHAR(10) + NCHAR(13) + N']%', @json);
IF SUBSTRING(@json, @primero, 1) <> N'['
    THROW 51002, 'Se esperaba un arreglo JSON de zonas horarias.', 1;
IF NOT EXISTS (SELECT 1 FROM OPENJSON(@json))
    THROW 51002, 'El arreglo de zonas horarias esta vacio.', 1;

-- 1.d) Extraccion: una fila por elemento. Si un elemento no es un objeto, se
--      lee igual y queda marcado en la fase 2; no se pierde informacion.
INSERT #HusosStaging
    (Archivo, NumeroElemento, TipoElemento, CantidadId, TipoId,
     IdZona, DisplayName, BaseOffset)
SELECT N'husos_horarios.json', CONVERT(INT, j.[key]) + 1, j.[type],
       a.CantidadId, a.TipoId, a.IdZona, b.DisplayName, c.BaseOffset
FROM OPENJSON(@json) AS j
OUTER APPLY (
    -- Se lee id como texto ancho antes de validar su longitud: sin truncar.
    SELECT MAX(p.value) AS IdZona, MAX(p.type) AS TipoId, COUNT(*) AS CantidadId
    FROM OPENJSON(CASE WHEN j.type = 5 THEN j.value ELSE N'{}' END) AS p
    WHERE p.[key] COLLATE Latin1_General_100_BIN2 = N'id'
) AS a
OUTER APPLY (
    SELECT MAX(p.value) AS DisplayName
    FROM OPENJSON(CASE WHEN j.type = 5 THEN j.value ELSE N'{}' END) AS p
    WHERE p.[key] COLLATE Latin1_General_100_BIN2 = N'displayName'
) AS b
OUTER APPLY (
    SELECT MAX(p.value) AS BaseOffset
    FROM OPENJSON(CASE WHEN j.type = 5 THEN j.value ELSE N'{}' END) AS p
    WHERE p.[key] COLLATE Latin1_General_100_BIN2 = N'baseOffset'
) AS c;

IF NOT EXISTS (SELECT 1 FROM #HusosStaging)
    THROW 51002, 'El arreglo de zonas horarias esta vacio.', 1;

---------------------------------------------------------------------------------------
-- FASE 2 - DEPURACION
-- Reglas de conjunto: cada UPDATE marca los elementos invalidos y su motivo.
-- No se borra nada; los elementos validos quedan en Estado = 'Pendiente'.
---------------------------------------------------------------------------------------

-- D1: el elemento debe ser un objeto JSON.
UPDATE #HusosStaging SET Estado='Error',
    Detalle=N'El elemento debe ser un objeto.'
WHERE Estado='Pendiente' AND TipoElemento <> 5;

-- D2: debe existir exactamente una propiedad id.
UPDATE #HusosStaging SET Estado='Error',
    Detalle=N'Debe existir exactamente una propiedad id.'
WHERE Estado='Pendiente' AND CantidadId <> 1;

-- D3: id debe ser una cadena de texto.
UPDATE #HusosStaging SET Estado='Error',
    Detalle=N'id debe ser una cadena de texto.'
WHERE Estado='Pendiente' AND TipoId <> 1;

-- D4: id vacio, mayor de 50 caracteres (VARCHAR(50) de la tabla) o con
--      caracteres no admitidos. Se mide sobre la conversion a VARCHAR para
--      no contar bytes de UTF-16 como caracteres.
UPDATE #HusosStaging SET Estado='Error',
    Detalle=N'id vacio, mayor de 50 caracteres o con caracteres no admitidos.'
WHERE Estado='Pendiente'
  AND (IdZona IS NULL OR DATALENGTH(IdZona) = 0
       OR DATALENGTH(CONVERT(VARCHAR(MAX), IdZona)) > 50
       OR CONVERT(NVARCHAR(MAX),CONVERT(VARCHAR(MAX),IdZona)) COLLATE Latin1_General_100_BIN2
            <> IdZona COLLATE Latin1_General_100_BIN2
       OR IdZona COLLATE Latin1_General_100_BIN2 LIKE N'%[^A-Za-z0-9/_+-]%');

-- D5: id repetido dentro del archivo: se conserva solo la primera aparicion.
UPDATE f SET Estado='Duplicada', Detalle=N'id repetido en este archivo.'
FROM #HusosStaging AS f
WHERE f.Estado='Pendiente' AND EXISTS (
    SELECT 1 FROM #HusosStaging AS anterior
    WHERE anterior.Estado='Pendiente'
      AND anterior.IdZona=f.IdZona AND anterior.Fila<f.Fila
);

-- Reporte de la depuracion: se informa ANTES de escribir en la tabla real.
SELECT 'FASE 2 - Depuracion de husos horarios (antes de la persistencia)' AS Fase;
SELECT Estado, COUNT(*) AS Cantidad FROM #HusosStaging GROUP BY Estado ORDER BY Estado;
SELECT Fila, NumeroElemento, IdZona, DisplayName, Estado, Detalle
FROM #HusosStaging WHERE Estado IN ('Error','Duplicada') ORDER BY Fila;

---------------------------------------------------------------------------------------
-- FASE 3 - PERSISTENCIA
-- Solo las filas que quedaron en 'Pendiente' llegan a la tabla real, siempre
-- a traves del SP de ABM de la entrega 5.
---------------------------------------------------------------------------------------

DECLARE @fila INT, @nombre VARCHAR(50), @id INT, @cantidad INT, @estado VARCHAR(20);
DECLARE filas CURSOR LOCAL FAST_FORWARD FOR
    SELECT Fila, CONVERT(VARCHAR(50), IdZona)
    FROM #HusosStaging WHERE Estado='Pendiente' ORDER BY Fila;
OPEN filas;
FETCH NEXT FROM filas INTO @fila, @nombre;
WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        -- Retener bloqueos hasta confirmar evita duplicados entre importadores.
        SELECT @cantidad = COUNT(*), @id = MIN(IdHuso)
        FROM sedes.HusoHorario WITH (UPDLOCK, HOLDLOCK)
        WHERE Nombre = @nombre;
        IF @cantidad > 1
            THROW 51003, 'Existen varios husos con ese nombre en la base.', 1;
        IF @cantidad = 0
        BEGIN
            EXEC SP.uspHusoHorario_Registrar @nombre = @nombre;
            SET @id = NULL;
        SELECT @id = IdHuso FROM sedes.HusoHorario WHERE Nombre = @nombre;
        END;
        COMMIT TRANSACTION;
        UPDATE #HusosStaging SET IdHuso = @id,
            Estado = CASE WHEN @cantidad = 0 THEN 'Insertada' ELSE 'SinCambios' END
        WHERE Fila = @fila;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        UPDATE #HusosStaging SET Estado = 'Error', Detalle = ERROR_MESSAGE()
        WHERE Fila = @fila;
    END CATCH;
    FETCH NEXT FROM filas INTO @fila, @nombre;
END;
CLOSE filas;
DEALLOCATE filas;

-- Reporte final de la persistencia.
SELECT 'FASE 3 - Persistencia de husos horarios' AS Fase;
SELECT Estado, COUNT(*) AS Cantidad FROM #HusosStaging GROUP BY Estado ORDER BY Estado;
SELECT Fila, NumeroElemento, IdZona, DisplayName, BaseOffset, IdHuso, Estado, Detalle
FROM #HusosStaging ORDER BY Fila;

DECLARE @fallos INT = (SELECT COUNT(*) FROM #HusosStaging WHERE Estado='Error');
DROP TABLE #HusosCrudo;
DROP TABLE #HusosStaging;
IF @fallos > 0
    THROW 51004, 'Importacion parcial: se conservaron las filas validas. Revise el resultado de errores.', 1;
GO
