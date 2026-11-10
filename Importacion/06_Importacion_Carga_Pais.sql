-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Comision 02
-- Grupo 7: Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 10/11/2026.
-- Objetivo: importar paises con la metodologia de tres fases. El nombre del
-- pais sale del XML de selecciones; el idioma sale de pais_idioma.csv y la
-- zona horaria de pais_zona.csv. Las tres fuentes se cruzan por el nombre.
--   FASE 1 STAGING     : se baja TODO a tablas temporales. #PaisesCrudo guarda
--                         los tres archivos originales sin modificar.
--                         #PaisesXml, #IdiomasStaging y #ZonasStaging guardan
--                         una fila por registro de cada fuente, con las
--                         columnas Estado y Detalle.
--   FASE 2 DEPURACION  : primero se depuran los CSV, despues se arma el
--                         staging de paises cruzando las tres fuentes y por
--                         ultimo se aplican las reglas de dominio. Todo con
--                         reglas de conjunto (UPDATE); no se borra ninguna fila.
--                         Se informa el resultado antes de tocar la base.
--   FASE 3 PERSISTENCIA : solo los paises validos pasan por los SP de ABM
--                         (SP.uspPais_Registrar / SP.uspPais_Update).
-- Requiere ejecutar antes las cargas 04 (husos) y 05 (idiomas).
-- SSMS: Consulta -> Modo SQLCMD. Ajustar las tres rutas del servidor SQL.
-- IMPORTANTE: cada integrante debe poner las rutas de su propia PC, porque
-- SQL Server lee los archivos desde el disco local del servidor.
-- :setvar RutaSelecciones "C:\ruta\proyecto\Datos\Selecciones_confederaciones_scrapping\selecciones_confederaciones.xml"
-- :setvar RutaIdiomas "C:\ruta\proyecto\Datos\pais_idioma.csv"
-- :setvar RutaZonas "C:\ruta\proyecto\Datos\Husos_horarios\pais_zona.csv"

:setvar RutaSelecciones "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Datos\Selecciones_confederaciones_scrapping\selecciones_confederaciones.xml"
:setvar RutaIdiomas "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Datos\pais_idioma.csv"
:setvar RutaZonas "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Datos\Husos_horarios\pais_zona.csv"

USE [MUNDIAL];
GO

DECLARE @ptIni TIME = '19:00', @ptFin TIME = '23:00';

SET NOCOUNT ON;
SET XACT_ABORT ON;

IF @@TRANCOUNT <> 0 OR (2 & @@OPTIONS) = 2
    THROW 51100, 'Ejecute sin transaccion externa y con IMPLICIT_TRANSACTIONS OFF.', 1;
IF @ptIni IS NULL OR @ptFin IS NULL OR @ptFin <= @ptIni
    THROW 51100, 'Prime time invalido: el inicio debe ser anterior al fin.', 1;
IF OBJECT_ID(N'equipos.Pais', N'U') IS NULL
   OR OBJECT_ID(N'arbitros.Idioma', N'U') IS NULL
   OR OBJECT_ID(N'sedes.HusoHorario', N'U') IS NULL
   OR OBJECT_ID(N'SP.uspPais_Registrar', N'P') IS NULL
   OR OBJECT_ID(N'SP.uspPais_Update', N'P') IS NULL
    THROW 51100, 'Faltan tablas o SP ABM. Ejecute primero el instalador.', 1;

IF OBJECT_ID(N'tempdb..#PaisesCrudo') IS NOT NULL DROP TABLE #PaisesCrudo;
IF OBJECT_ID(N'tempdb..#PaisesTexto') IS NOT NULL DROP TABLE #PaisesTexto;
IF OBJECT_ID(N'tempdb..#PaisesXml') IS NOT NULL DROP TABLE #PaisesXml;
IF OBJECT_ID(N'tempdb..#IdiomasStaging') IS NOT NULL DROP TABLE #IdiomasStaging;
IF OBJECT_ID(N'tempdb..#ZonasStaging') IS NOT NULL DROP TABLE #ZonasStaging;
IF OBJECT_ID(N'tempdb..#PaisesStaging') IS NOT NULL DROP TABLE #PaisesStaging;

---------------------------------------------------------------------------------------
-- FASE 1 - STAGING
-- Todavia no se descarta nada: primero baja todo a tablas temporales.
---------------------------------------------------------------------------------------

-- 1.a) Archivos crudos: los bytes originales, sin modificar.
--      El XML se convierte desde los bytes para que SQL Server respete la
--      declaracion encoding='utf-8' del documento.
CREATE TABLE #PaisesCrudo (
    Archivo NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Contenido VARBINARY(MAX)
);
-- Copia de los mismos bytes en VARCHAR con collation UTF-8, para poder leer
-- el texto de los CSV sin re-serializar el archivo.
CREATE TABLE #PaisesTexto (
    Archivo NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Contenido VARCHAR(MAX) COLLATE Latin1_General_100_CI_AS_SC_UTF8
);

-- 1.b) Staging por fuente: una fila por registro de cada archivo.
CREATE TABLE #PaisesXml (
    Fila INT IDENTITY(1,1) PRIMARY KEY,
    Archivo NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Nombre NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    Confederacion NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    CantidadNombres INT,
    CantidadConfederaciones INT,
    Estado VARCHAR(20) COLLATE DATABASE_DEFAULT NOT NULL DEFAULT 'Pendiente',
    Detalle NVARCHAR(2048) COLLATE DATABASE_DEFAULT
);
CREATE TABLE #IdiomasStaging (
    Fila INT IDENTITY(1,1) PRIMARY KEY,
    Archivo NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    NumeroLinea INT,
    LineaOriginal NVARCHAR(MAX) COLLATE DATABASE_DEFAULT,
    CantidadCampos INT,
    Pais NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    Idioma NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    Estado VARCHAR(20) COLLATE DATABASE_DEFAULT NOT NULL DEFAULT 'Pendiente',
    Detalle NVARCHAR(2048) COLLATE DATABASE_DEFAULT
);
CREATE TABLE #ZonasStaging (
    Fila INT IDENTITY(1,1) PRIMARY KEY,
    Archivo NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    NumeroLinea INT,
    LineaOriginal NVARCHAR(MAX) COLLATE DATABASE_DEFAULT,
    CantidadCampos INT,
    Pais NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    Ciudad NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    Zona NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    Estado VARCHAR(20) COLLATE DATABASE_DEFAULT NOT NULL DEFAULT 'Pendiente',
    Detalle NVARCHAR(2048) COLLATE DATABASE_DEFAULT
);

BEGIN TRY
    -- SQLCMD sustituye las rutas antes de enviar el lote a SQL Server.
    INSERT #PaisesCrudo (Archivo, Contenido)
    SELECT N'selecciones_confederaciones.xml', BulkColumn
    FROM OPENROWSET(BULK '$(RutaSelecciones)', SINGLE_BLOB) AS archivo;

    INSERT #PaisesCrudo (Archivo, Contenido)
    SELECT N'pais_idioma.csv', BulkColumn
    FROM OPENROWSET(BULK '$(RutaIdiomas)', SINGLE_BLOB) AS archivo;

    INSERT #PaisesCrudo (Archivo, Contenido)
    SELECT N'pais_zona.csv', BulkColumn
    FROM OPENROWSET(BULK '$(RutaZonas)', SINGLE_BLOB) AS archivo;

    -- Copia byte a byte a VARCHAR con collation UTF-8 para leer los CSV.
    INSERT #PaisesTexto (Archivo, Contenido)
    SELECT Archivo, Contenido FROM #PaisesCrudo;
END TRY
BEGIN CATCH
    DECLARE @mensaje NVARCHAR(2048) = LEFT(N'No se pudieron leer los archivos; no se modificaron paises. '
                                           + ERROR_MESSAGE(), 2048);
    THROW 51101, @mensaje, 1;
END CATCH;

-- 1.c) Extraccion del XML: una fila por elemento <seleccion>.
--      La conversion se hace desde los bytes: asi el motor respeta la
--      declaracion encoding='utf-8' del documento original.
BEGIN TRY
    DECLARE @xml XML = CONVERT(XML, (SELECT Contenido FROM #PaisesCrudo
                                     WHERE Archivo = N'selecciones_confederaciones.xml'));
    IF @xml.exist('/selecciones/seleccion') = 0
        THROW 51102, 'El XML no contiene /selecciones/seleccion.', 1;
    INSERT #PaisesXml (Archivo, Nombre, Confederacion, CantidadNombres, CantidadConfederaciones)
    SELECT N'selecciones_confederaciones.xml',
           LTRIM(RTRIM(n.value('(nombre/text())[1]', 'nvarchar(max)'))),
           LTRIM(RTRIM(n.value('(confederacion/text())[1]', 'nvarchar(max)'))),
           n.value('count(nombre)', 'int'), n.value('count(confederacion)', 'int')
    FROM @xml.nodes('/selecciones/seleccion') AS t(n);
END TRY
BEGIN CATCH
    DECLARE @errorXml NVARCHAR(2048) = LEFT(N'El XML de selecciones no se pudo interpretar; '
                                             + ERROR_MESSAGE(), 2048);
    THROW 51102, @errorXml, 1;
END CATCH;

DECLARE @textoIdiomas NVARCHAR(MAX) =
    (SELECT CONVERT(NVARCHAR(MAX), Contenido) FROM #PaisesTexto
     WHERE Archivo = N'pais_idioma.csv');
DECLARE @textoZonas NVARCHAR(MAX) =
    (SELECT CONVERT(NVARCHAR(MAX), Contenido) FROM #PaisesTexto
     WHERE Archivo = N'pais_zona.csv');

-- 1.d) Extraccion de los CSV: una fila por linea de datos, con su numero de
--      linea y su texto original. Una linea malformada queda con la cantidad
--      de campos detectada y se rechaza en la fase 2.
;WITH Lineas AS (
    SELECT ordinal AS Ordinal, REPLACE(value, NCHAR(13), N'') AS Linea
    FROM STRING_SPLIT(@textoIdiomas, NCHAR(10), 1)
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

;WITH Lineas AS (
    SELECT ordinal AS Ordinal, REPLACE(value, NCHAR(13), N'') AS Linea
    FROM STRING_SPLIT(@textoZonas, NCHAR(10), 1)
), Numeradas AS (
    SELECT ROW_NUMBER() OVER (ORDER BY Ordinal) AS Numero, Linea
    FROM Lineas WHERE LTRIM(RTRIM(Linea)) <> ''
)
INSERT #ZonasStaging
    (Archivo, NumeroLinea, LineaOriginal, CantidadCampos, Pais, Ciudad, Zona)
SELECT N'pais_zona.csv', n.Numero, n.Linea,
       (SELECT COUNT(*) FROM STRING_SPLIT(n.Linea, N',', 1)),
       (SELECT MAX(v.value) FROM STRING_SPLIT(n.Linea, N',', 1) AS v WHERE v.ordinal=1),
       (SELECT MAX(v.value) FROM STRING_SPLIT(n.Linea, N',', 1) AS v WHERE v.ordinal=2),
       (SELECT MAX(v.value) FROM STRING_SPLIT(n.Linea, N',', 1) AS v WHERE v.ordinal=3)
FROM Numeradas AS n
WHERE n.Numero > 1;

-- 1.e) Se valida la cabecera de los CSV: si el formato cambia, se aborta antes
--      de cargar nada en lugar de interpretar los datos equivocados.
DECLARE @cabeceraIdiomas NVARCHAR(200);
SELECT TOP (1) @cabeceraIdiomas = LTRIM(RTRIM(REPLACE(v.value, NCHAR(13), N'')))
FROM STRING_SPLIT(@textoIdiomas, NCHAR(10), 1) AS v
WHERE LTRIM(RTRIM(REPLACE(v.value, NCHAR(13), N''))) <> '';
IF @cabeceraIdiomas IS NULL OR @cabeceraIdiomas <> N'pais,idioma'
    THROW 51102, N'La cabecera de pais_idioma.csv no es la esperada; no se modificaron paises.', 1;
DECLARE @cabeceraZonas NVARCHAR(200);
SELECT TOP (1) @cabeceraZonas = LTRIM(RTRIM(REPLACE(v.value, NCHAR(13), N'')))
FROM STRING_SPLIT(@textoZonas, NCHAR(10), 1) AS v
WHERE LTRIM(RTRIM(REPLACE(v.value, NCHAR(13), N''))) <> '';
IF @cabeceraZonas IS NULL OR @cabeceraZonas <> N'pais,ciudad_referencia,zona_horaria'
    THROW 51102, N'La cabecera de pais_zona.csv no es la esperada; no se modificaron paises.', 1;

IF NOT EXISTS (SELECT 1 FROM #PaisesXml)
    THROW 51102, 'El XML de selecciones no contiene paises.', 1;

---------------------------------------------------------------------------------------
-- FASE 2 - DEPURACION
-- Reglas de conjunto: cada UPDATE marca las filas invalidas y su motivo.
-- No se borra nada; las filas validas quedan en Estado = 'Pendiente'.
---------------------------------------------------------------------------------------

-- 2.a) Reglas del CSV de idiomas.
UPDATE #IdiomasStaging SET Estado='Error',
    Detalle=N'La linea del archivo no tiene 2 campos.'
WHERE Estado='Pendiente' AND CantidadCampos <> 2;

UPDATE #IdiomasStaging SET Estado='Error',
    Detalle=N'El pais o el idioma esta vacio.'
WHERE Estado='Pendiente'
  AND (NULLIF(Pais,N'') IS NULL OR NULLIF(Idioma,N'') IS NULL);

-- 2.b) Reglas del CSV de zonas.
UPDATE #ZonasStaging SET Estado='Error',
    Detalle=N'La linea del archivo no tiene 3 campos.'
WHERE Estado='Pendiente' AND CantidadCampos <> 3;

UPDATE #ZonasStaging SET Estado='Error',
    Detalle=N'El pais, la ciudad o la zona esta vacio.'
WHERE Estado='Pendiente'
  AND (NULLIF(Pais,N'') IS NULL OR NULLIF(Ciudad,N'') IS NULL OR NULLIF(Zona,N'') IS NULL);

-- 2.c) Reglas del XML de selecciones.
UPDATE #PaisesXml SET Estado='Error',
    Detalle=N'Nombre o confederacion invalidos en el XML.'
WHERE Estado='Pendiente' AND (CantidadNombres <> 1 OR CantidadConfederaciones <> 1);

UPDATE #PaisesXml SET Estado='Error',
    Detalle=N'El pais no cabe fielmente en Pais.NOMBRE VARCHAR(50).'
WHERE Estado='Pendiente'
  AND (NULLIF(Nombre,N'') IS NULL
       OR DATALENGTH(CONVERT(VARCHAR(MAX),Nombre)) > 50
       OR CONVERT(NVARCHAR(MAX),CONVERT(VARCHAR(MAX),Nombre)) COLLATE Latin1_General_100_BIN2
            <> Nombre COLLATE Latin1_General_100_BIN2);

UPDATE #PaisesXml SET Estado='Error',
    Detalle=N'La confederacion no cabe sin perdida en VARCHAR(45).'
WHERE Estado='Pendiente'
  AND (NULLIF(Confederacion,N'') IS NULL
       OR DATALENGTH(CONVERT(VARCHAR(MAX),Confederacion)) > 45
       OR CONVERT(NVARCHAR(MAX),CONVERT(VARCHAR(MAX),Confederacion)) COLLATE Latin1_General_100_BIN2
            <> Confederacion COLLATE Latin1_General_100_BIN2);

-- 2.d) Se arma el staging de paises cruzando las tres fuentes. Solo se usan
--      las filas de los CSV que pasaron la depuracion.
CREATE TABLE #PaisesStaging (
    Fila INT IDENTITY(1,1) PRIMARY KEY,
    Pais NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    Confederacion NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    Idioma NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    CantidadIdiomas INT,
    Ciudad NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    Zona NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    CantidadZonas INT,
    IdPais INT,
    IdIdioma INT,
    IdHuso INT,
    Estado VARCHAR(20) COLLATE DATABASE_DEFAULT NOT NULL DEFAULT 'Pendiente',
    Detalle NVARCHAR(2048) COLLATE DATABASE_DEFAULT
);
INSERT #PaisesStaging
    (Pais, Confederacion, Idioma, CantidadIdiomas, Ciudad, Zona, CantidadZonas)
SELECT x.Nombre, x.Confederacion, i.Idioma, i.Cantidad, z.Ciudad, z.Zona, z.Cantidad
FROM #PaisesXml AS x
LEFT JOIN (SELECT Pais, MIN(Idioma) AS Idioma, COUNT(DISTINCT Idioma) AS Cantidad
           FROM #IdiomasStaging WHERE Estado='Pendiente' GROUP BY Pais) AS i
    ON i.Pais = x.Nombre
LEFT JOIN (SELECT Pais, MIN(Ciudad) AS Ciudad, MIN(Zona) AS Zona, COUNT(DISTINCT Zona) AS Cantidad
           FROM #ZonasStaging WHERE Estado='Pendiente' GROUP BY Pais) AS z
    ON z.Pais = x.Nombre
WHERE x.Estado = 'Pendiente';

-- 2.e) Reglas de dominio sobre el pais.
UPDATE #PaisesStaging SET Estado='Error',
    Detalle=N'Falta el idioma del pais o hay idiomas contradictorios en el CSV.'
WHERE Estado='Pendiente' AND (ISNULL(CantidadIdiomas,0) <> 1 OR NULLIF(Idioma,N'') IS NULL);

UPDATE #PaisesStaging SET Estado='Error',
    Detalle=N'Falta la zona del pais o hay zonas contradictorias en el CSV.'
WHERE Estado='Pendiente' AND (ISNULL(CantidadZonas,0) <> 1 OR NULLIF(Zona,N'') IS NULL);

-- El idioma tiene que existir en arbitros.Idioma (carga 05).
UPDATE #PaisesStaging SET Estado='Error',
    Detalle=N'El idioma no existe en arbitros.Idioma: revise la carga 05.'
WHERE Estado='Pendiente'
  AND (SELECT COUNT(*) FROM arbitros.Idioma WHERE Descripcion = Idioma) = 0;

UPDATE #PaisesStaging SET Estado='Error',
    Detalle=N'El idioma es ambiguo en arbitros.Idioma: revise la carga 05.'
WHERE Estado='Pendiente'
  AND (SELECT COUNT(*) FROM arbitros.Idioma WHERE Descripcion = Idioma) > 1;

-- La zona tiene que existir en sedes.HusoHorario (carga 04).
UPDATE #PaisesStaging SET Estado='Error',
    Detalle=N'La zona no existe en sedes.HusoHorario: revise la carga 04.'
WHERE Estado='Pendiente'
  AND (SELECT COUNT(*) FROM sedes.HusoHorario WHERE Nombre = Zona) = 0;

UPDATE #PaisesStaging SET Estado='Error',
    Detalle=N'La zona es ambigua en sedes.HusoHorario: revise la carga 04.'
WHERE Estado='Pendiente'
  AND (SELECT COUNT(*) FROM sedes.HusoHorario WHERE Nombre = Zona) > 1;

-- Pais repetido en el XML: se conserva solo la primera aparicion.
UPDATE f SET Estado='Duplicada', Detalle=N'Pais ya procesado en este XML.'
FROM #PaisesStaging AS f
WHERE f.Estado='Pendiente' AND EXISTS (
    SELECT 1 FROM #PaisesStaging AS anterior
    WHERE anterior.Estado='Pendiente'
      AND anterior.Pais=f.Pais AND anterior.Fila<f.Fila
);

-- Se resuelven los identificadores de las referencias ya cargadas.
UPDATE p SET IdIdioma = i.IdIdioma
FROM #PaisesStaging AS p
JOIN arbitros.Idioma AS i ON i.Descripcion = p.Idioma
WHERE p.Estado='Pendiente';

UPDATE p SET IdHuso = h.IdHuso
FROM #PaisesStaging AS p
JOIN sedes.HusoHorario AS h ON h.Nombre = p.Zona
WHERE p.Estado='Pendiente';

UPDATE p SET IdPais = e.IdPais
FROM #PaisesStaging AS p
JOIN equipos.Pais AS e ON e.NOMBRE = CONVERT(VARCHAR(50), p.Pais)
WHERE p.Estado='Pendiente';

-- Reporte de la depuracion: se informa ANTES de escribir en la tabla real.
SELECT 'FASE 2 - Depuracion de paises (antes de la persistencia)' AS Fase;
SELECT 'pais_idioma.csv' AS Fuente, Estado, COUNT(*) AS Cantidad
FROM #IdiomasStaging GROUP BY Estado
UNION ALL
SELECT 'pais_zona.csv', Estado, COUNT(*) FROM #ZonasStaging GROUP BY Estado
UNION ALL
SELECT 'selecciones_confederaciones.xml', Estado, COUNT(*) FROM #PaisesXml GROUP BY Estado
UNION ALL
SELECT 'paises (cruzado)', Estado, COUNT(*) FROM #PaisesStaging GROUP BY Estado
ORDER BY Fuente, Estado;

SELECT Fila, Pais, Idioma, Ciudad, Zona, Estado, Detalle
FROM #PaisesStaging WHERE Estado IN ('Error','Duplicada') ORDER BY Fila;

SELECT Fila, NumeroLinea, Pais, Idioma, Estado, Detalle, LineaOriginal
FROM #IdiomasStaging WHERE Estado='Error' ORDER BY Fila;

SELECT Fila, NumeroLinea, Pais, Ciudad, Zona, Estado, Detalle, LineaOriginal
FROM #ZonasStaging WHERE Estado='Error' ORDER BY Fila;

---------------------------------------------------------------------------------------
-- FASE 3 - PERSISTENCIA
-- Solo las filas que quedaron en 'Pendiente' llegan a la tabla real, siempre
-- a traves de los SP de ABM de la entrega 5.
---------------------------------------------------------------------------------------

DECLARE @fila INT, @pais NVARCHAR(200), @confederacion NVARCHAR(200),
        @nombre VARCHAR(50), @idPais INT, @idIdioma INT, @idHuso INT,
        @inicio TIME, @fin TIME, @estado VARCHAR(20);
DECLARE crsPaises CURSOR LOCAL FAST_FORWARD FOR
    SELECT Fila, Pais, IdIdioma, IdHuso FROM #PaisesStaging
    WHERE Estado='Pendiente' ORDER BY Fila;
OPEN crsPaises;
FETCH NEXT FROM crsPaises INTO @fila, @pais, @idIdioma, @idHuso;
WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        SET @nombre = CONVERT(VARCHAR(50), @pais);
        BEGIN TRANSACTION;
        SET @idPais = NULL;
        SET @inicio = @ptIni;
        SET @fin = @ptFin;
        SELECT @idPais = IdPais,
               @inicio = COALESCE(PtIni, @ptIni), @fin = COALESCE(PtFin, @ptFin)
        FROM equipos.Pais WITH (UPDLOCK, HOLDLOCK) WHERE NOMBRE = @nombre;
        IF @idPais IS NULL
        BEGIN
            -- El PBI no existe en estas fuentes: no se inventa (NULL).
            -- Prime time es un supuesto parametrizado, no un dato importado.
            EXEC SP.uspPais_Registrar @nombre = @nombre, @idioma = @idIdioma,
                @huso = @idHuso, @ptIni = @inicio, @ptFin = @fin, @pbi = NULL;
            SET @estado = 'Insertada';
        END
        ELSE IF EXISTS (
            SELECT 1 FROM equipos.Pais WHERE IdPais = @idPais
            AND (Idioma IS NULL OR Idioma <> @idIdioma
                 OR HusoHorario IS NULL OR HusoHorario <> @idHuso
                 OR PtIni IS NULL OR PtFin IS NULL)
        )
        BEGIN
            -- El SP conserva PBI cuando recibe NULL; se conserva el prime time existente.
            EXEC SP.uspPais_Update @idPais = @idPais, @idioma = @idIdioma,
                @huso = @idHuso, @ptIni = @inicio, @ptFin = @fin, @pbi = NULL;
            SET @estado = 'Actualizada';
        END
        ELSE SET @estado = 'SinCambios';
        COMMIT TRANSACTION;
        UPDATE #PaisesStaging SET IdPais = @idPais, Estado = @estado WHERE Fila = @fila;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        UPDATE #PaisesStaging SET Estado='Error', Detalle=ERROR_MESSAGE() WHERE Fila = @fila;
    END CATCH;
    FETCH NEXT FROM crsPaises INTO @fila, @pais, @idIdioma, @idHuso;
END;
CLOSE crsPaises;
DEALLOCATE crsPaises;

-- Reporte final de la persistencia.
SELECT 'FASE 3 - Persistencia de paises' AS Fase;
SELECT Estado, COUNT(*) AS Cantidad FROM #PaisesStaging GROUP BY Estado ORDER BY Estado;
SELECT Fila, Pais, Confederacion, Idioma, Ciudad, Zona, IdPais, IdIdioma, IdHuso, Estado, Detalle
FROM #PaisesStaging ORDER BY Fila;

DECLARE @fallos INT = (SELECT COUNT(*) FROM #PaisesStaging WHERE Estado='Error');
DROP TABLE #PaisesCrudo;
DROP TABLE #PaisesTexto;
DROP TABLE #PaisesXml;
DROP TABLE #IdiomasStaging;
DROP TABLE #ZonasStaging;
DROP TABLE #PaisesStaging;
IF @fallos > 0
    THROW 51104, 'Hay registros rechazados. Las filas correctas se conservaron; revise el detalle.', 1;
GO
