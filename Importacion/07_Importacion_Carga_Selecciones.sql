-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Comision 02
-- Grupo 7: Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 10/11/2026.
-- Objetivo: cargar selecciones con la metodologia de tres fases. El grupo sale
-- de selecciones_grupos.csv (nombre en espanol) y la confederacion del XML
-- de selecciones (nombre en ingles). equivalencias_selecciones.csv relaciona
-- ambos nombres.
--   FASE 1 STAGING     : se baja TODO a tablas temporales. #SeleccionesCrudo
--                         guarda los tres archivos originales sin modificar.
--                         #GruposStaging, #AliasStaging y #SeleccionesXml
--                         guardan una fila por registro de cada fuente, con
--                         las columnas Estado y Detalle.
--   FASE 2 DEPURACION  : primero se depura cada fuente, despues se arma el
--                         staging de selecciones cruzando las tres y por
--                         ultimo se aplican las reglas de dominio. Todo con
--                         reglas de conjunto (UPDATE); no se borra ninguna fila.
--                         Se informa el resultado antes de tocar la base.
--   FASE 3 PERSISTENCIA : solo las selecciones validas pasan por los SP de
--                         ABM (SP.uspSeleccion_Registrar / uspSeleccion_Update).
-- Requiere paises (06), grupos (01) y el Mundial con IdMundial = 1 cargados.
-- SSMS: Consulta > Modo SQLCMD. Ajustar las tres rutas del servidor SQL.
-- IMPORTANTE: cada integrante debe poner las rutas de su propia PC, porque
-- SQL Server lee los archivos desde el disco local del servidor.
-- :setvar RutaGrupos "C:\ruta\proyecto\Datos\Selecciones_grupos_scrapping\selecciones_grupos.csv"
-- :setvar RutaSelecciones "C:\ruta\proyecto\Datos\Selecciones_confederaciones_scrapping\selecciones_confederaciones.xml"
-- :setvar RutaEquivalencias "C:\ruta\proyecto\Datos\equivalencias_selecciones.csv"

:setvar RutaGrupos "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Datos\Selecciones_grupos_scrapping\selecciones_grupos.csv"
:setvar RutaSelecciones "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Datos\Selecciones_confederaciones_scrapping\selecciones_confederaciones.xml"
:setvar RutaEquivalencias "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Datos\equivalencias_selecciones.csv"

USE [MUNDIAL];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @idMundial INT = 1;

IF @@TRANCOUNT <> 0 OR (2 & @@OPTIONS) = 2
    THROW 51300, 'Ejecute sin transaccion externa y con IMPLICIT_TRANSACTIONS OFF.', 1;
IF OBJECT_ID(N'equipos.Seleccion', N'U') IS NULL
   OR OBJECT_ID(N'equipos.Pais', N'U') IS NULL
   OR OBJECT_ID(N'equipos.Grupo', N'U') IS NULL
   OR OBJECT_ID(N'sedes.Mundial', N'U') IS NULL
   OR OBJECT_ID(N'SP.uspSeleccion_Registrar', N'P') IS NULL
   OR OBJECT_ID(N'SP.uspSeleccion_Update', N'P') IS NULL
    THROW 51300, 'Faltan tablas o SP ABM. Ejecute primero el instalador.', 1;
IF NOT EXISTS (SELECT 1 FROM sedes.Mundial WHERE IdMundial = @idMundial)
    THROW 51300, 'No existe el Mundial con IdMundial = 1. Debe cargarlo primero.', 1;

IF OBJECT_ID(N'tempdb..#SeleccionesCrudo') IS NOT NULL DROP TABLE #SeleccionesCrudo;
IF OBJECT_ID(N'tempdb..#SeleccionesTexto') IS NOT NULL DROP TABLE #SeleccionesTexto;
IF OBJECT_ID(N'tempdb..#GruposStaging') IS NOT NULL DROP TABLE #GruposStaging;
IF OBJECT_ID(N'tempdb..#AliasStaging') IS NOT NULL DROP TABLE #AliasStaging;
IF OBJECT_ID(N'tempdb..#SeleccionesXml') IS NOT NULL DROP TABLE #SeleccionesXml;
IF OBJECT_ID(N'tempdb..#SeleccionesStaging') IS NOT NULL DROP TABLE #SeleccionesStaging;

---------------------------------------------------------------------------------------
-- FASE 1 - STAGING
-- Todavia no se descarta nada: primero baja todo a tablas temporales.
---------------------------------------------------------------------------------------

-- 1.a) Archivos crudos: los bytes originales, sin modificar.
--      El XML se convierte desde los bytes para que SQL Server respete la
--      declaracion encoding='utf-8' del documento.
CREATE TABLE #SeleccionesCrudo (
    Archivo NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Contenido VARBINARY(MAX)
);
-- Copia de los mismos bytes en VARCHAR con collation UTF-8, para poder leer
-- el texto de los CSV sin re-serializar el archivo.
CREATE TABLE #SeleccionesTexto (
    Archivo NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Contenido VARCHAR(MAX) COLLATE Latin1_General_100_CI_AS_SC_UTF8
);

-- 1.b) Staging por fuente: una fila por registro de cada archivo.
CREATE TABLE #GruposStaging (
    Fila INT IDENTITY(1,1) PRIMARY KEY,
    Archivo NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    NumeroLinea INT,
    LineaOriginal NVARCHAR(MAX) COLLATE DATABASE_DEFAULT,
    CantidadCampos INT,
    Seleccion NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    Grupo NVARCHAR(20) COLLATE DATABASE_DEFAULT,
    Estado VARCHAR(20) COLLATE DATABASE_DEFAULT NOT NULL DEFAULT 'Pendiente',
    Detalle NVARCHAR(2048) COLLATE DATABASE_DEFAULT
);
CREATE TABLE #AliasStaging (
    Fila INT IDENTITY(1,1) PRIMARY KEY,
    Archivo NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    NumeroLinea INT,
    LineaOriginal NVARCHAR(MAX) COLLATE DATABASE_DEFAULT,
    CantidadCampos INT,
    NombreCsv NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    NombreXml NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    Estado VARCHAR(20) COLLATE DATABASE_DEFAULT NOT NULL DEFAULT 'Pendiente',
    Detalle NVARCHAR(2048) COLLATE DATABASE_DEFAULT
);
CREATE TABLE #SeleccionesXml (
    Fila INT IDENTITY(1,1) PRIMARY KEY,
    Archivo NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Nombre NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    Confederacion NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    CantidadNombres INT,
    CantidadConfederaciones INT,
    Estado VARCHAR(20) COLLATE DATABASE_DEFAULT NOT NULL DEFAULT 'Pendiente',
    Detalle NVARCHAR(2048) COLLATE DATABASE_DEFAULT
);

BEGIN TRY
    -- SQLCMD sustituye las rutas antes de enviar el lote a SQL Server.
    INSERT #SeleccionesCrudo (Archivo, Contenido)
    SELECT N'selecciones_grupos.csv', BulkColumn
    FROM OPENROWSET(BULK '$(RutaGrupos)', SINGLE_BLOB) AS archivo;

    INSERT #SeleccionesCrudo (Archivo, Contenido)
    SELECT N'equivalencias_selecciones.csv', BulkColumn
    FROM OPENROWSET(BULK '$(RutaEquivalencias)', SINGLE_BLOB) AS archivo;

    INSERT #SeleccionesCrudo (Archivo, Contenido)
    SELECT N'selecciones_confederaciones.xml', BulkColumn
    FROM OPENROWSET(BULK '$(RutaSelecciones)', SINGLE_BLOB) AS archivo;

    -- Copia byte a byte a VARCHAR con collation UTF-8 para leer los CSV.
    INSERT #SeleccionesTexto (Archivo, Contenido)
    SELECT Archivo, Contenido FROM #SeleccionesCrudo;
END TRY
BEGIN CATCH
    DECLARE @mensaje NVARCHAR(2048) = LEFT(N'No se pudieron leer los archivos; no se modificaron selecciones. '
                                           + ERROR_MESSAGE(), 2048);
    THROW 51301, @mensaje, 1;
END CATCH;

DECLARE @textoGrupos NVARCHAR(MAX) =
    (SELECT CONVERT(NVARCHAR(MAX), Contenido) FROM #SeleccionesTexto
     WHERE Archivo = N'selecciones_grupos.csv');
DECLARE @textoAlias NVARCHAR(MAX) =
    (SELECT CONVERT(NVARCHAR(MAX), Contenido) FROM #SeleccionesTexto
     WHERE Archivo = N'equivalencias_selecciones.csv');

-- 1.c) Extraccion del XML: una fila por elemento <seleccion>.
BEGIN TRY
    DECLARE @xml XML = CONVERT(XML, (SELECT Contenido FROM #SeleccionesCrudo
                                     WHERE Archivo = N'selecciones_confederaciones.xml'));
    IF @xml.exist('/selecciones/seleccion') = 0
        THROW 51302, 'El XML no contiene /selecciones/seleccion.', 1;
    INSERT #SeleccionesXml
        (Archivo, Nombre, Confederacion, CantidadNombres, CantidadConfederaciones)
    SELECT N'selecciones_confederaciones.xml',
           LTRIM(RTRIM(n.value('(nombre/text())[1]', 'nvarchar(max)'))),
           LTRIM(RTRIM(n.value('(confederacion/text())[1]', 'nvarchar(max)'))),
           n.value('count(nombre)', 'int'), n.value('count(confederacion)', 'int')
    FROM @xml.nodes('/selecciones/seleccion') AS t(n);
END TRY
BEGIN CATCH
    DECLARE @errorXml NVARCHAR(2048) = LEFT(N'El XML de selecciones no se pudo interpretar; '
                                             + ERROR_MESSAGE(), 2048);
    THROW 51302, @errorXml, 1;
END CATCH;

-- 1.d) Extraccion de los CSV: una fila por linea de datos, con su numero de
--      linea y su texto original.
;WITH Lineas AS (
    SELECT ordinal AS Ordinal, REPLACE(value, NCHAR(13), N'') AS Linea
    FROM STRING_SPLIT(@textoGrupos, NCHAR(10), 1)
), Numeradas AS (
    SELECT ROW_NUMBER() OVER (ORDER BY Ordinal) AS Numero, Linea
    FROM Lineas WHERE LTRIM(RTRIM(Linea)) <> ''
)
INSERT #GruposStaging
    (Archivo, NumeroLinea, LineaOriginal, CantidadCampos, Seleccion, Grupo)
SELECT N'selecciones_grupos.csv', n.Numero, n.Linea,
       (SELECT COUNT(*) FROM STRING_SPLIT(n.Linea, N',', 1)),
       (SELECT MAX(v.value) FROM STRING_SPLIT(n.Linea, N',', 1) AS v WHERE v.ordinal=1),
       (SELECT MAX(v.value) FROM STRING_SPLIT(n.Linea, N',', 1) AS v WHERE v.ordinal=2)
FROM Numeradas AS n
WHERE n.Numero > 1;

;WITH Lineas AS (
    SELECT ordinal AS Ordinal, REPLACE(value, NCHAR(13), N'') AS Linea
    FROM STRING_SPLIT(@textoAlias, NCHAR(10), 1)
), Numeradas AS (
    SELECT ROW_NUMBER() OVER (ORDER BY Ordinal) AS Numero, Linea
    FROM Lineas WHERE LTRIM(RTRIM(Linea)) <> ''
)
INSERT #AliasStaging
    (Archivo, NumeroLinea, LineaOriginal, CantidadCampos, NombreCsv, NombreXml)
SELECT N'equivalencias_selecciones.csv', n.Numero, n.Linea,
       (SELECT COUNT(*) FROM STRING_SPLIT(n.Linea, N',', 1)),
       (SELECT MAX(v.value) FROM STRING_SPLIT(n.Linea, N',', 1) AS v WHERE v.ordinal=1),
       (SELECT MAX(v.value) FROM STRING_SPLIT(n.Linea, N',', 1) AS v WHERE v.ordinal=2)
FROM Numeradas AS n
WHERE n.Numero > 1;

-- 1.e) Se valida la cabecera de los CSV: si el formato cambia, se aborta antes
--      de cargar nada en lugar de interpretar los datos equivocados.
DECLARE @cabeceraGrupos NVARCHAR(200);
SELECT TOP (1) @cabeceraGrupos = LTRIM(RTRIM(REPLACE(v.value, NCHAR(13), N'')))
FROM STRING_SPLIT(@textoGrupos, NCHAR(10), 1) AS v
WHERE LTRIM(RTRIM(REPLACE(v.value, NCHAR(13), N''))) <> '';
IF @cabeceraGrupos IS NULL OR @cabeceraGrupos <> N'seleccion,grupo'
    THROW 51302, N'La cabecera de selecciones_grupos.csv no es la esperada; no se modificaron selecciones.', 1;
DECLARE @cabeceraAlias NVARCHAR(200);
SELECT TOP (1) @cabeceraAlias = LTRIM(RTRIM(REPLACE(v.value, NCHAR(13), N'')))
FROM STRING_SPLIT(@textoAlias, NCHAR(10), 1) AS v
WHERE LTRIM(RTRIM(REPLACE(v.value, NCHAR(13), N''))) <> '';
IF @cabeceraAlias IS NULL OR @cabeceraAlias <> N'nombre_csv,nombre_xml'
    THROW 51302, N'La cabecera de equivalencias_selecciones.csv no es la esperada; no se modificaron selecciones.', 1;

IF NOT EXISTS (SELECT 1 FROM #GruposStaging)
    THROW 51302, 'El CSV no contiene selecciones.', 1;

---------------------------------------------------------------------------------------
-- FASE 2 - DEPURACION
-- Reglas de conjunto: cada UPDATE marca las filas invalidas y su motivo.
-- No se borra nada; las filas validas quedan en Estado = 'Pendiente'.
---------------------------------------------------------------------------------------

-- 2.a) Reglas del CSV de grupos.
UPDATE #GruposStaging SET Estado='Error',
    Detalle=N'La linea del archivo no tiene 2 campos.'
WHERE Estado='Pendiente' AND CantidadCampos <> 2;

UPDATE #GruposStaging SET Estado='Error',
    Detalle=N'La seleccion esta vacia o no cabe fielmente en VARCHAR(50).'
WHERE Estado='Pendiente'
  AND (NULLIF(Seleccion,N'') IS NULL
       OR DATALENGTH(CONVERT(VARCHAR(MAX),Seleccion)) > 50
       OR CONVERT(NVARCHAR(MAX),CONVERT(VARCHAR(MAX),Seleccion)) COLLATE Latin1_General_100_BIN2
            <> Seleccion COLLATE Latin1_General_100_BIN2);

UPDATE #GruposStaging SET Estado='Error',
    Detalle=N'Grupo invalido: se espera una letra entre A y L.'
WHERE Estado='Pendiente'
  AND (NULLIF(Grupo,N'') IS NULL OR LEN(Grupo) <> 1
       OR Grupo COLLATE Latin1_General_100_BIN2 NOT LIKE N'[A-L]');

-- 2.b) Reglas del CSV de equivalencias.
UPDATE #AliasStaging SET Estado='Error',
    Detalle=N'La linea del archivo no tiene 2 campos.'
WHERE Estado='Pendiente' AND CantidadCampos <> 2;

UPDATE #AliasStaging SET Estado='Error',
    Detalle=N'Equivalencia invalida: nombre vacio o demasiado largo.'
WHERE Estado='Pendiente'
  AND (NULLIF(NombreCsv,N'') IS NULL OR NULLIF(NombreXml,N'') IS NULL
       OR LEN(NombreCsv) > 100 OR LEN(NombreXml) > 100);

UPDATE f SET Estado='Error',
    Detalle=N'Equivalencia contradictoria: el mismo nombre apunta a varios nombres del XML.'
FROM #AliasStaging AS f
WHERE f.Estado='Pendiente' AND EXISTS (
    SELECT 1 FROM #AliasStaging AS o
    WHERE o.NombreCsv=f.NombreCsv AND o.NombreXml<>f.NombreXml
);

-- 2.c) Reglas del XML de selecciones.
UPDATE #SeleccionesXml SET Estado='Error',
    Detalle=N'Nombre o confederacion invalidos en el XML.'
WHERE Estado='Pendiente' AND (CantidadNombres <> 1 OR CantidadConfederaciones <> 1);

UPDATE #SeleccionesXml SET Estado='Error',
    Detalle=N'El nombre no cabe fielmente en VARCHAR(50).'
WHERE Estado='Pendiente'
  AND (NULLIF(Nombre,N'') IS NULL
       OR DATALENGTH(CONVERT(VARCHAR(MAX),Nombre)) > 50
       OR CONVERT(NVARCHAR(MAX),CONVERT(VARCHAR(MAX),Nombre)) COLLATE Latin1_General_100_BIN2
            <> Nombre COLLATE Latin1_General_100_BIN2);

UPDATE #SeleccionesXml SET Estado='Error',
    Detalle=N'La confederacion no cabe sin perdida en VARCHAR(45).'
WHERE Estado='Pendiente'
  AND (NULLIF(Confederacion,N'') IS NULL
       OR DATALENGTH(CONVERT(VARCHAR(MAX),Confederacion)) > 45
       OR CONVERT(NVARCHAR(MAX),CONVERT(VARCHAR(MAX),Confederacion)) COLLATE Latin1_General_100_BIN2
            <> Confederacion COLLATE Latin1_General_100_BIN2);

-- 2.d) Se arma el staging de selecciones cruzando las tres fuentes. El nombre
--      del XML se obtiene de las equivalencias; si no hay equivalencia se usa
--      el nombre del CSV tal cual.
CREATE TABLE #SeleccionesStaging (
    Fila INT IDENTITY(1,1) PRIMARY KEY,
    NombreCsv NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    Pais NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    Grupo NVARCHAR(20) COLLATE DATABASE_DEFAULT,
    Confederacion NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    CantidadNombres INT,
    CantidadConfederaciones INT,
    IdPais INT,
    IdGrupo INT,
    IdSeleccion INT,
    Estado VARCHAR(20) COLLATE DATABASE_DEFAULT NOT NULL DEFAULT 'Pendiente',
    Detalle NVARCHAR(2048) COLLATE DATABASE_DEFAULT
);
INSERT #SeleccionesStaging
    (NombreCsv, Pais, Grupo, Confederacion, CantidadNombres, CantidadConfederaciones)
SELECT g.Seleccion, COALESCE(a.NombreXml, g.Seleccion), g.Grupo,
       x.Confederacion, x.CantidadNombres, x.CantidadConfederaciones
FROM #GruposStaging AS g
LEFT JOIN (SELECT NombreCsv, MIN(NombreXml) AS NombreXml
           FROM #AliasStaging WHERE Estado='Pendiente' GROUP BY NombreCsv) AS a
    ON a.NombreCsv = g.Seleccion
LEFT JOIN #SeleccionesXml AS x
    ON x.Nombre = COALESCE(a.NombreXml, g.Seleccion)
WHERE g.Estado = 'Pendiente';

-- 2.e) Reglas de dominio sobre la seleccion.
UPDATE #SeleccionesStaging SET Estado='Error',
    Detalle=N'La seleccion falta en el XML. Revise las equivalencias de nombres.'
WHERE Estado='Pendiente' AND CantidadNombres IS NULL;

UPDATE #SeleccionesStaging SET Estado='Error',
    Detalle=N'Nombre o confederacion invalidos en el XML.'
WHERE Estado='Pendiente' AND (ISNULL(CantidadNombres,0) <> 1 OR ISNULL(CantidadConfederaciones,0) <> 1
                              OR NULLIF(Confederacion,N'') IS NULL);

-- Rechazar todas las versiones de una seleccion si el CSV le asigna varios grupos.
UPDATE r SET Estado='Error',
    Detalle=N'El CSV asigna grupos diferentes a la misma seleccion.'
FROM #SeleccionesStaging AS r
WHERE r.Estado='Pendiente' AND EXISTS (
    SELECT 1 FROM #SeleccionesStaging AS o
    WHERE o.Pais=r.Pais AND ISNULL(o.Grupo,N'') <> ISNULL(r.Grupo,N'')
);

-- El grupo tiene que existir en equipos.Grupo (carga 01).
UPDATE #SeleccionesStaging SET Estado='Error',
    Detalle=N'El grupo no existe o es ambiguo en equipos.Grupo: revise la carga 01.'
WHERE Estado='Pendiente'
  AND (SELECT COUNT(*) FROM equipos.Grupo WHERE NOMBRE = UPPER(Grupo)) <> 1;

-- El pais tiene que existir en equipos.Pais (carga 06).
UPDATE #SeleccionesStaging SET Estado='Error',
    Detalle=N'El pais no existe o es ambiguo en equipos.Pais: revise la carga 06.'
WHERE Estado='Pendiente'
  AND (SELECT COUNT(*) FROM equipos.Pais WHERE NOMBRE = CONVERT(VARCHAR(50), Pais)) <> 1;

-- Seleccion repetida en el CSV: se conserva solo la primera aparicion.
UPDATE f SET Estado='Duplicada', Detalle=N'Seleccion ya procesada en este CSV.'
FROM #SeleccionesStaging AS f
WHERE f.Estado='Pendiente' AND EXISTS (
    SELECT 1 FROM #SeleccionesStaging AS anterior
    WHERE anterior.Estado='Pendiente'
      AND anterior.Pais=f.Pais AND anterior.Fila<f.Fila
);

-- Se resuelven los identificadores de las referencias ya cargadas.
UPDATE s SET IdGrupo = g.IdGrupo
FROM #SeleccionesStaging AS s
JOIN equipos.Grupo AS g ON g.NOMBRE = UPPER(s.Grupo)
WHERE s.Estado='Pendiente';

UPDATE s SET IdPais = p.IdPais
FROM #SeleccionesStaging AS s
JOIN equipos.Pais AS p ON p.NOMBRE = CONVERT(VARCHAR(50), s.Pais)
WHERE s.Estado='Pendiente';

-- Reporte de la depuracion: se informa ANTES de escribir en la tabla real.
SELECT 'FASE 2 - Depuracion de selecciones (antes de la persistencia)' AS Fase;
SELECT 'selecciones_grupos.csv' AS Fuente, Estado, COUNT(*) AS Cantidad
FROM #GruposStaging GROUP BY Estado
UNION ALL
SELECT 'equivalencias_selecciones.csv', Estado, COUNT(*) FROM #AliasStaging GROUP BY Estado
UNION ALL
SELECT 'selecciones_confederaciones.xml', Estado, COUNT(*) FROM #SeleccionesXml GROUP BY Estado
UNION ALL
SELECT 'selecciones (cruzado)', Estado, COUNT(*) FROM #SeleccionesStaging GROUP BY Estado
ORDER BY Fuente, Estado;

SELECT Fila, NombreCsv, Pais, Grupo, Confederacion, Estado, Detalle
FROM #SeleccionesStaging WHERE Estado IN ('Error','Duplicada') ORDER BY Fila;

SELECT Fila, NumeroLinea, Seleccion, Grupo, Estado, Detalle, LineaOriginal
FROM #GruposStaging WHERE Estado='Error' ORDER BY Fila;

SELECT Fila, NumeroLinea, NombreCsv, NombreXml, Estado, Detalle, LineaOriginal
FROM #AliasStaging WHERE Estado='Error' ORDER BY Fila;

---------------------------------------------------------------------------------------
-- FASE 3 - PERSISTENCIA
-- Solo las filas que quedaron en 'Pendiente' llegan a la tabla real, siempre
-- a traves de los SP de ABM de la entrega 5.
---------------------------------------------------------------------------------------

DECLARE @fila INT, @pais NVARCHAR(200), @grupo NVARCHAR(20), @confederacion VARCHAR(45),
        @idPais INT, @idGrupo INT, @idSeleccion INT,
        @grupoActual INT, @grupoActualizar INT, @confActual VARCHAR(45), @estado VARCHAR(20);
DECLARE crsSelecciones CURSOR LOCAL FAST_FORWARD FOR
    SELECT Fila, Pais, Grupo, Confederacion, IdPais, IdGrupo
    FROM #SeleccionesStaging WHERE Estado='Pendiente' ORDER BY Fila;
OPEN crsSelecciones;
FETCH NEXT FROM crsSelecciones INTO @fila, @pais, @grupo, @confederacion, @idPais, @idGrupo;
WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        SET @confederacion = CONVERT(VARCHAR(45), @confederacion);
        BEGIN TRANSACTION;
        -- Serializar la carga por grupo para respetar su cupo durante el upsert.
        SET @idSeleccion = NULL;
        SET @grupoActual = NULL;
        SET @confActual = NULL;
        SELECT @idSeleccion = IdSeleccion, @grupoActual = IdGrupo, @confActual = CONFEDERACION
        FROM equipos.Seleccion WITH (UPDLOCK, HOLDLOCK)
        WHERE IdPais = @idPais AND IdMundial = @idMundial;
        IF @idSeleccion IS NULL
        BEGIN
            EXEC SP.uspSeleccion_Registrar @idPais = @idPais, @idMundial = @idMundial,
                @idGrupo = @idGrupo, @confederacion = @confederacion;
            -- Se relee el identificador generado por el alta.
            SELECT @idSeleccion = IdSeleccion
            FROM equipos.Seleccion
            WHERE IdPais = @idPais AND IdMundial = @idMundial;
            SET @estado = 'Insertada';
        END
        ELSE IF @grupoActual <> @idGrupo OR @confActual <> @confederacion
        BEGIN
            SET @grupoActualizar = CASE WHEN @grupoActual <> @idGrupo THEN @idGrupo ELSE NULL END;
            EXEC SP.uspSeleccion_Update @idSeleccion = @idSeleccion,
                @idGrupo = @grupoActualizar, @confederacion = @confederacion;
            SET @estado = 'Actualizada';
        END
        ELSE SET @estado = 'SinCambios';
        COMMIT TRANSACTION;
        UPDATE #SeleccionesStaging SET IdSeleccion = @idSeleccion, Estado = @estado WHERE Fila = @fila;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        UPDATE #SeleccionesStaging SET Estado='Error', Detalle=ERROR_MESSAGE() WHERE Fila = @fila;
    END CATCH;
    FETCH NEXT FROM crsSelecciones INTO @fila, @pais, @grupo, @confederacion, @idPais, @idGrupo;
END;
CLOSE crsSelecciones;
DEALLOCATE crsSelecciones;

-- Reporte final de la persistencia.
SELECT 'FASE 3 - Persistencia de selecciones' AS Fase;
SELECT Estado, COUNT(*) AS Cantidad FROM #SeleccionesStaging GROUP BY Estado ORDER BY Estado;
SELECT Fila, NombreCsv, Pais, Grupo, Confederacion, IdPais, IdGrupo, IdSeleccion, Estado, Detalle
FROM #SeleccionesStaging ORDER BY Fila;

DECLARE @fallos INT = (SELECT COUNT(*) FROM #SeleccionesStaging WHERE Estado='Error');
DROP TABLE #SeleccionesCrudo;
DROP TABLE #SeleccionesTexto;
DROP TABLE #GruposStaging;
DROP TABLE #AliasStaging;
DROP TABLE #SeleccionesXml;
DROP TABLE #SeleccionesStaging;
IF @fallos > 0
    THROW 51304, 'Hay selecciones rechazadas. Las filas correctas se conservaron; revise el detalle.', 1;
GO
