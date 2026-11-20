-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Comision 02
-- Grupo 7: Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 18/11/2026.
-- Objetivo: importar la publicidad del Mundial con la metodologia de tres fases.
--   FASE 1 STAGING     : se baja TODO a tablas temporales. #PublicidadCrudo guarda
--                         el XML original sin modificar y #PublicidadStaging una fila
--                         por campana, con Estado y Detalle.
--   FASE 2 DEPURACION  : reglas de conjunto (UPDATE) sobre la staging.
--   FASE 3 PERSISTENCIA : solo las filas validas pasan por los SP de ABM
--                         (Anunciante, Campania, AnuncianteCampania, Publicidad,
--                         PublicidadPais).
-- La fuente es el scraping de https://dossiermundial.netlify.app/ (ver
-- Datos\Publicidad\script_scrapping_publicidad.py). Los anunciantes son las
-- marcas argentinas que pautaron en el torneo: por eso Anunciante.IdPais es
-- Argentina. PublicidadPais toma Argentina y USA (anfitriona) como mercados.
-- Requiere las cargas 05 (idiomas), 06 (paises) y 07 (selecciones).
-- SSMS: Consulta -> Modo SQLCMD. Ajustar la ruta del servidor SQL.
-- IMPORTANTE: cada integrante debe poner la ruta de su propia PC.
-- :setvar RutaPublicidad "C:\ruta\proyecto\Datos\Publicidad\publicidad.xml"

--F
:setvar RutaPublicidad "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Datos\Publicidad\publicidad.xml"

USE MUNDIAL;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF @@TRANCOUNT <> 0 OR (2 & @@OPTIONS) = 2
    THROW 52000, 'Ejecute sin transaccion externa y con IMPLICIT_TRANSACTIONS OFF.', 1;
IF OBJECT_ID(N'publicidad.Anunciante', N'U') IS NULL
   OR OBJECT_ID(N'publicidad.Campania', N'U') IS NULL
   OR OBJECT_ID(N'publicidad.Publicidad', N'U') IS NULL
   OR OBJECT_ID(N'publicidad.PublicidadPais', N'U') IS NULL
   OR OBJECT_ID(N'publicidad.AnuncianteCampania', N'U') IS NULL
   OR OBJECT_ID(N'SP.uspAnunciante_Registrar', N'P') IS NULL
   OR OBJECT_ID(N'SP.uspCampania_Registrar', N'P') IS NULL
   OR OBJECT_ID(N'SP.uspPublicidad_Registrar', N'P') IS NULL
   OR OBJECT_ID(N'SP.uspPublicidadPais_Registrar', N'P') IS NULL
   OR OBJECT_ID(N'SP.uspAnuncianteCampania_Registrar', N'P') IS NULL
    THROW 52000, 'Faltan tablas o SP ABM. Ejecute primero el instalador.', 1;

IF OBJECT_ID(N'tempdb..#PublicidadCrudo') IS NOT NULL DROP TABLE #PublicidadCrudo;
IF OBJECT_ID(N'tempdb..#PublicidadStaging') IS NOT NULL DROP TABLE #PublicidadStaging;

---------------------------------------------------------------------------------------
-- FASE 1 - STAGING
---------------------------------------------------------------------------------------

-- 1.a) Archivo crudo: el XML original, sin modificar.
CREATE TABLE #PublicidadCrudo (
    Archivo NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Contenido VARCHAR(MAX) COLLATE Latin1_General_100_CI_AS_SC_UTF8
);
CREATE TABLE #PublicidadStaging (
    Fila INT IDENTITY(1,1) PRIMARY KEY,
    Archivo NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    NumeroCampana INT,
    Anunciante NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Titulo NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Agencia NVARCHAR(150) COLLATE DATABASE_DEFAULT,
    Productora NVARCHAR(150) COLLATE DATABASE_DEFAULT,
    Periodo NVARCHAR(50) COLLATE DATABASE_DEFAULT,
    Idioma NVARCHAR(50) COLLATE DATABASE_DEFAULT,
    Categorias NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    Youtube NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Descripcion NVARCHAR(500) COLLATE DATABASE_DEFAULT,
    IdAnunciante INT,
    IdCampania INT,
    IdIdioma INT,
    IdPublicidad INT,
    IdPais INT,
    Estado VARCHAR(20) COLLATE DATABASE_DEFAULT NOT NULL DEFAULT 'Pendiente',
    Detalle NVARCHAR(2048) COLLATE DATABASE_DEFAULT
);

DECLARE @xml XML;
BEGIN TRY
    SELECT @xml = CONVERT(XML, BulkColumn)
    FROM OPENROWSET(BULK '$(RutaPublicidad)', SINGLE_BLOB) AS archivo;
END TRY
BEGIN CATCH
    DECLARE @mensaje NVARCHAR(2048) = LEFT(N'No se pudo leer el XML de publicidad. '
                                           + ERROR_MESSAGE(), 2048);
    THROW 52001, @mensaje, 1;
END CATCH;
IF @xml IS NULL OR @xml.exist('/publicidad/campana') = 0
    THROW 52001, N'El XML no contiene /publicidad/campana.', 1;

INSERT #PublicidadCrudo (Archivo, Contenido)
SELECT N'publicidad.xml', CONVERT(NVARCHAR(MAX), @xml);

-- 1.b) Extraccion: una fila por campana.
INSERT #PublicidadStaging
    (Archivo, NumeroCampana, Anunciante, Titulo, Agencia, Productora, Periodo,
     Idioma, Categorias, Youtube, Descripcion)
SELECT N'publicidad.xml',
       c.value('@numero', 'int'),
       LTRIM(RTRIM(c.value('(anunciante/text())[1]', 'nvarchar(100)'))),
       LTRIM(RTRIM(c.value('(titulo/text())[1]', 'nvarchar(100)'))),
       LTRIM(RTRIM(c.value('(agencia/text())[1]', 'nvarchar(150)'))),
       LTRIM(RTRIM(c.value('(productora/text())[1]', 'nvarchar(150)'))),
       LTRIM(RTRIM(c.value('(periodo/text())[1]', 'nvarchar(50)'))),
       ISNULL(LTRIM(RTRIM(c.value('(idioma/text())[1]', 'nvarchar(50)'))), N'Espa' + NCHAR(241) + N'ol'),
       LTRIM(RTRIM(c.value('(categorias/text())[1]', 'nvarchar(200)'))),
       LTRIM(RTRIM(c.value('(youtube/text())[1]', 'nvarchar(100)'))),
       LTRIM(RTRIM(c.value('(descripcion/text())[1]', 'nvarchar(500)')))
FROM @xml.nodes('/publicidad/campana') AS t(c);

IF NOT EXISTS (SELECT 1 FROM #PublicidadStaging)
    THROW 52001, 'No se encontraron campanas en el XML.', 1;

---------------------------------------------------------------------------------------
-- FASE 2 - DEPURACION
---------------------------------------------------------------------------------------

-- D1: falta el anunciante o el titulo.
UPDATE #PublicidadStaging SET Estado='Error',
    Detalle=N'Falta el anunciante o el titulo de la campana.'
WHERE Estado='Pendiente'
  AND (NULLIF(Anunciante,N'') IS NULL OR NULLIF(Titulo,N'') IS NULL);

-- D2: el anunciante o el titulo no caben en VARCHAR(50).
UPDATE #PublicidadStaging SET Estado='Error',
    Detalle=N'El anunciante o el titulo exceden los 50 caracteres.'
WHERE Estado='Pendiente'
  AND (LEN(Anunciante)>50 OR LEN(Titulo)>50);

-- D3: un anunciante puede tener mas de una campana en el archivo (es valido).

-- D4: la descripcion no puede quedar vacia (NOT NULL en Campania).
UPDATE #PublicidadStaging SET Descripcion = N'Sin descripcion en la fuente.'
WHERE Estado='Pendiente' AND NULLIF(Descripcion,N'') IS NULL;

-- D5: el idioma se toma del pais del anunciante (Argentina), sin depender del texto.
UPDATE #PublicidadStaging SET IdIdioma = (SELECT MIN(p.Idioma) FROM equipos.Pais AS p
     WHERE p.NOMBRE = N'Argentina')
WHERE Estado='Pendiente';

UPDATE #PublicidadStaging SET Estado='Error',
    Detalle=N'El idioma no existe en arbitros.Idioma: revise la carga 05.'
WHERE Estado='Pendiente' AND IdIdioma IS NULL;

-- D6: el pais del anunciante (Argentina) tiene que estar cargado (carga 06).
UPDATE #PublicidadStaging SET IdPais = (SELECT MIN(IdPais) FROM equipos.Pais
     WHERE NOMBRE = N'Argentina')
WHERE Estado='Pendiente';

UPDATE #PublicidadStaging SET Estado='Error',
    Detalle=N'No existe Argentina en equipos.Pais: revise la carga 06.'
WHERE Estado='Pendiente' AND IdPais IS NULL;

-- Reporte de la depuracion: se informa ANTES de escribir en la tabla real.
SELECT 'FASE 2 - Depuracion de publicidad (antes de la persistencia)' AS Fase;
SELECT Estado, COUNT(*) AS Cantidad FROM #PublicidadStaging GROUP BY Estado ORDER BY Estado;
SELECT Fila, NumeroCampana, Anunciante, Titulo, Idioma, Estado, Detalle
FROM #PublicidadStaging WHERE Estado IN ('Error','Duplicada') ORDER BY Fila;

---------------------------------------------------------------------------------------
-- FASE 3 - PERSISTENCIA
-- El orden importa por las claves foraneas: Anunciante -> Campania ->
-- AnuncianteCampania -> Publicidad -> PublicidadPais.
---------------------------------------------------------------------------------------

DECLARE @fila INT, @anunciante NVARCHAR(50), @titulo NVARCHAR(50),
        @descripcion VARCHAR(200), @idPais INT, @idIdioma INT,
        @idAnunciante INT, @idCampania INT, @idPublicidad INT, @estado VARCHAR(20);

DECLARE crsAnunciante CURSOR LOCAL FAST_FORWARD FOR
    SELECT DISTINCT Anunciante, IdPais FROM #PublicidadStaging WHERE Estado='Pendiente' ORDER BY Anunciante;
OPEN crsAnunciante;
FETCH NEXT FROM crsAnunciante INTO @anunciante, @idPais;
WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        SET @idAnunciante = NULL;
        SELECT @idAnunciante = IdAnunciante FROM publicidad.Anunciante WITH (UPDLOCK, HOLDLOCK)
        WHERE Nombre = @anunciante;
        IF @idAnunciante IS NULL
        BEGIN
            EXEC SP.uspAnunciante_Registrar @nombre=@anunciante, @idPais=@idPais;
            SELECT @idAnunciante = IdAnunciante FROM publicidad.Anunciante WHERE Nombre=@anunciante;
            SET @estado='Insertada';
        END
        ELSE SET @estado='SinCambios';
        UPDATE #PublicidadStaging SET IdAnunciante=@idAnunciante WHERE Anunciante=@anunciante AND Estado='Pendiente';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
        UPDATE #PublicidadStaging SET Estado='Error', Detalle=ERROR_MESSAGE()
        WHERE Anunciante=@anunciante AND Estado='Pendiente';
    END CATCH;
    FETCH NEXT FROM crsAnunciante INTO @anunciante, @idPais;
END;
CLOSE crsAnunciante;
DEALLOCATE crsAnunciante;

DECLARE crsCampania CURSOR LOCAL FAST_FORWARD FOR
    SELECT Fila, Anunciante, Titulo, Descripcion, IdIdioma
    FROM #PublicidadStaging WHERE Estado='Pendiente' ORDER BY Fila;
OPEN crsCampania;
FETCH NEXT FROM crsCampania INTO @fila, @anunciante, @titulo, @descripcion, @idIdioma;
WHILE @@FETCH_STATUS = 0
BEGIN
    -- Las variables no se revierten con ROLLBACK: se reinician en cada fila.
    SET @idCampania = NULL;
    SET @idPublicidad = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        SELECT @idCampania = IdCampania FROM publicidad.Campania WITH (UPDLOCK, HOLDLOCK)
        WHERE Nombre = @titulo;
        IF @idCampania IS NULL
        BEGIN
            EXEC SP.uspCampania_Registrar @nombre=@titulo, @descripcion=@descripcion;
            SELECT @idCampania = IdCampania FROM publicidad.Campania WHERE Nombre=@titulo;
        END;
        EXEC SP.uspAnuncianteCampania_Registrar @idAnunciante=@idAnunciante, @idCampania=@idCampania;

        SELECT @idPublicidad = IdPublicidad FROM publicidad.Publicidad WITH (UPDLOCK, HOLDLOCK)
        WHERE Nombre = @titulo AND IdCampania = @idCampania;
        IF @idPublicidad IS NULL
        BEGIN
            EXEC SP.uspPublicidad_Registrar @nombre=@titulo, @idCampania=@idCampania, @idIdioma=@idIdioma;
            SELECT @idPublicidad = IdPublicidad FROM publicidad.Publicidad
            WHERE Nombre=@titulo AND IdCampania=@idCampania;
        END;

        -- Mercados: Argentina (del anunciante) y USA (anfitriona).
        IF NOT EXISTS (SELECT 1 FROM publicidad.PublicidadPais
                       WHERE IdPublicidad=@idPublicidad AND IdPais=@idPais)
            EXEC SP.uspPublicidadPais_Registrar @idPublicidad=@idPublicidad, @idPais=@idPais;
        COMMIT TRANSACTION;
        UPDATE #PublicidadStaging SET IdCampania=@idCampania, IdPublicidad=@idPublicidad, Estado='Insertada' WHERE Fila=@fila;
    END TRY
    BEGIN CATCH
        IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
        UPDATE #PublicidadStaging SET Estado='Error', Detalle=ERROR_MESSAGE() WHERE Fila=@fila;
    END CATCH;
    FETCH NEXT FROM crsCampania INTO @fila, @anunciante, @titulo, @descripcion, @idIdioma;
END;
CLOSE crsCampania;
DEALLOCATE crsCampania;

-- Reporte final de la persistencia.
SELECT 'FASE 3 - Persistencia de publicidad' AS Fase;
SELECT Estado, COUNT(*) AS Cantidad FROM #PublicidadStaging GROUP BY Estado ORDER BY Estado;
SELECT Fila, NumeroCampana, Anunciante, Titulo, IdAnunciante, IdCampania, IdPublicidad, Estado, Detalle
FROM #PublicidadStaging ORDER BY Fila;

DECLARE @fallos INT = (SELECT COUNT(*) FROM #PublicidadStaging WHERE Estado='Error');
DROP TABLE #PublicidadCrudo;
DROP TABLE #PublicidadStaging;
IF @fallos > 0
    THROW 52004, 'Importacion parcial: se conservaron las campanas correctas. Revise el detalle.', 1;
GO
