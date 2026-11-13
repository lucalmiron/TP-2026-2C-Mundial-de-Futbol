-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Comision 02
-- Grupo 7: Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 04/11/2026.
-- Objetivo: importar el PBI per capita (NY.GDP.PCAP.CD, anio 2024) del XML de la
-- API del Banco Mundial a equipos.Pais.PBI, usando SL.uspPais_Update. El XML
-- se descarga sin modificar con Datos\BancoMundial\script_descargar_pbi_API.py.
-- Solo actualiza paises que ya existen en equipos.Pais; los demas paises del
-- XML se saltean. Requiere ejecutar antes el instalador (00_Ejecutar_Todo.sql)
-- y la carga 06_Importacion_Carga_Pais.sql (que crea los paises con PBI NULL).

-- En SSMS: Consulta -> Modo SQLCMD. Cambiar estas dos rutas.

--Santutu
 :setvar RutaPBI "C:\\Users\\Usuario\\Documents\\proyecto BDDA\\TP-2026-2C-Mundial-de-Futbol\Datos\BancoMundial\pbi_por_pais.xml"
 :setvar RutaEquiv "C:\\Users\\Usuario\\Documents\\proyecto BDDA\\TP-2026-2C-Mundial-de-Futbol\Datos\BancoMundial\pais_iso3.csv"

--L
--:setvar RutaPBI "C:\\Users\\Usuario\\Documents\\proyecto BDDA\\TP-2026-2C-Mundial-de-Futbol\Datos\BancoMundial\pbi_por_pais.xml"
--:setvar RutaEquiv "C:\\Users\\Usuario\\Documents\\proyecto BDDA\\TP-2026-2C-Mundial-de-Futbol\Datos\BancoMundial\pais_iso3.csv"

USE [MUNDIAL];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

IF @@TRANCOUNT <> 0 OR (2 & @@OPTIONS) = 2
    THROW 51100, 'Ejecute sin transaccion externa y con IMPLICIT_TRANSACTIONS OFF.', 1;
IF OBJECT_ID(N'equipos.Pais', N'U') IS NULL
   OR OBJECT_ID(N'SP.uspPais_Update', N'P') IS NULL
    THROW 51100, 'Faltan la tabla equipos.Pais o el SP SP.uspPais_Update. Ejecute primero el instalador y la carga 06.', 1;

-- Permitir reejecutar en la misma sesion si una lectura anterior fallo.
IF OBJECT_ID(N'tempdb..#Equiv') IS NOT NULL DROP TABLE #Equiv;
IF OBJECT_ID(N'tempdb..#Xml') IS NOT NULL DROP TABLE #Xml;
IF OBJECT_ID(N'tempdb..#Pendiente') IS NOT NULL DROP TABLE #Pendiente;

CREATE TABLE #Equiv (
    Pais NVARCHAR(MAX) COLLATE Latin1_General_100_CI_AS,
    ISO3 NVARCHAR(MAX) COLLATE Latin1_General_100_CI_AS
);
CREATE TABLE #Xml (
    ISO3 VARCHAR(3) COLLATE Latin1_General_100_CI_AS,
    PBI BIGINT
);
CREATE TABLE #Pendiente (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    ISO3 VARCHAR(3) COLLATE Latin1_General_100_CI_AS,
    Pais NVARCHAR(MAX) COLLATE Latin1_General_100_CI_AS,
    PBI BIGINT,
    Estado VARCHAR(20) COLLATE Latin1_General_100_CI_AS NOT NULL DEFAULT 'Pendiente',
    Detalle NVARCHAR(2048) COLLATE Latin1_General_100_CI_AS,
    Procesado BIT NOT NULL DEFAULT 0
);

DECLARE @xml XML, @mensaje NVARCHAR(2048);
BEGIN TRY
    -- SQLCMD sustituye las rutas antes de enviar el lote a SQL Server.
    -- SINGLE_BLOB respeta la declaracion UTF-8 del XML original.
    SELECT @xml = CONVERT(XML, BulkColumn)
    FROM OPENROWSET(
        BULK '$(RutaPBI)',
        SINGLE_BLOB
    ) AS archivo;

    BULK INSERT #Equiv
    FROM '$(RutaEquiv)'
    WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',',
          ROWTERMINATOR = '0x0a', CODEPAGE = '65001', MAXERRORS = 0);
END TRY
BEGIN CATCH
    SET @mensaje = LEFT(N'No se pudieron leer los archivos; no se modificaron paises. '
                           + ERROR_MESSAGE(), 2048);
    THROW 51101, @mensaje, 1;
END CATCH;
IF @xml IS NULL OR @xml.exist('/*[local-name()="data"]/*[local-name()="data"]') = 0
    THROW 51102, 'El XML no contiene datos del Banco Mundial.', 1;

UPDATE #Equiv SET Pais = LTRIM(RTRIM(Pais)),
    ISO3 = LTRIM(RTRIM(UPPER(REPLACE(ISO3, NCHAR(13), N''))));

-- Parseo del XML ignorando el namespace que usa el Banco Mundial (ns0:).
INSERT INTO #Xml (ISO3, PBI)
SELECT n.value('(*[local-name()="countryiso3code"]/text())[1]', 'varchar(3)'),
       TRY_CAST(ROUND(TRY_CAST(n.value('(*[local-name()="value"]/text())[1]', 'nvarchar(max)') AS DECIMAL(18,2)), 0) AS BIGINT)
FROM @xml.nodes('/*[local-name()="data"]/*[local-name()="data"]') AS t(n);

-- Se expande cada registro del XML con los nombres del CSV que comparten
-- ese ISO3. Un ISO3 puede tener mas de un nombre (ej: GBR para Inglaterra
-- y Escocia): en ese caso se genera una fila por nombre y se actualizan
-- todos. Si el ISO3 no esta en el CSV, queda una fila con Pais NULL.
INSERT INTO #Pendiente (ISO3, Pais, PBI)
SELECT DISTINCT x.ISO3, e.Pais, x.PBI
FROM #Xml AS x
LEFT JOIN #Equiv AS e ON e.ISO3 = x.ISO3;

DECLARE @id INT, @iso VARCHAR(3), @pais NVARCHAR(MAX), @pbi BIGINT,
        @idPais INT, @pbiActual BIGINT;

-- Sin cursores anidados: un solo bucle fila por fila, cada fila en su propia
-- transaccion, para conservar las validas si otra falla.
WHILE EXISTS (SELECT 1 FROM #Pendiente WHERE Procesado = 0)
BEGIN
    SELECT TOP (1) @id = Id FROM #Pendiente WHERE Procesado = 0 ORDER BY Id;
    UPDATE #Pendiente SET Procesado = 1 WHERE Id = @id;
    SELECT @iso = ISO3, @pais = Pais, @pbi = PBI FROM #Pendiente WHERE Id = @id;
    BEGIN TRY
        IF NULLIF(@iso, N'') IS NULL
        BEGIN
            -- Los registros sin ISO3 son agregados del Banco Mundial (High income,
            -- Low income, etc.), no paises: se saltean y quedan en el reporte.
            UPDATE #Pendiente SET Estado = 'NoEnBase',
                Detalle = N'Registro agregado del Banco Mundial sin ISO3; se saltea.'
            WHERE Id = @id;
        END
        ELSE IF EXISTS (SELECT 1 FROM #Pendiente
                   WHERE Id < @id AND ISO3 = @iso
                     AND Estado IN ('Actualizada', 'SinCambios')
                     AND Pais = @pais)
        BEGIN
            UPDATE #Pendiente SET Estado = 'Duplicada',
                Detalle = N'ISO3 ya procesado en este XML.'
            WHERE Id = @id;
        END
        ELSE IF @pais IS NULL
        BEGIN
            -- El XML trae todos los paises del mundo: solo se cargan los que
            -- ya existen en la base (los paises del Mundial, cargados en la 06).
            UPDATE #Pendiente SET Estado = 'NoEnBase',
                Detalle = N'ISO3 no esta en pais_iso3.csv.'
            WHERE Id = @id;
        END
        ELSE
        BEGIN
            BEGIN TRANSACTION;
            -- Reiniciar: si el SELECT no encuentra fila, las variables conservarian
            -- el valor de la iteracion anterior.
            SET @idPais = NULL;
            SET @pbiActual = NULL;
            SELECT @idPais = IdPais, @pbiActual = PBI
            FROM equipos.Pais WITH (UPDLOCK, HOLDLOCK)
            WHERE NOMBRE COLLATE Latin1_General_100_CI_AS = CONVERT(VARCHAR(50), @pais) COLLATE Latin1_General_100_CI_AS;

            IF @idPais IS NULL
            BEGIN
                -- El nombre del CSV no coincide con un pais cargado.
                UPDATE #Pendiente SET Estado = 'NoEnBase',
                    Detalle = N'El nombre no coincide con un pais cargado.'
                WHERE Id = @id;
            END
            ELSE IF @pbi IS NULL
            BEGIN
                UPDATE #Pendiente SET Estado = 'SinDato' WHERE Id = @id;
            END
            ELSE IF @pbi < 0
            BEGIN
                THROW 51103, 'El PBI del XML es negativo o no es numerico.', 1;
            END
            ELSE IF @pbiActual = @pbi
            BEGIN
                UPDATE #Pendiente SET Estado = 'SinCambios' WHERE Id = @id;
            END
            ELSE
            BEGIN
                -- El SP conserva los demas campos cuando recibe NULL.
                EXEC SP.uspPais_Update @idPais = @idPais, @pbi = @pbi;
                UPDATE #Pendiente SET Estado = 'Actualizada' WHERE Id = @id;
            END;
            COMMIT TRANSACTION;
        END;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        UPDATE #Pendiente SET Estado = 'Error', Detalle = ERROR_MESSAGE() WHERE Id = @id;
    END CATCH;
END;

SELECT Estado, COUNT(*) AS Cantidad FROM #Pendiente GROUP BY Estado ORDER BY Estado;
SELECT Id, ISO3, Pais, PBI, Estado, Detalle FROM #Pendiente ORDER BY Id;

DECLARE @hayErrores BIT = CASE WHEN EXISTS (
    SELECT 1 FROM #Pendiente WHERE Estado = 'Error'
) THEN 1 ELSE 0 END;

DROP TABLE #Equiv;
DROP TABLE #Xml;
DROP TABLE #Pendiente;

IF @hayErrores = 1
    THROW 51104, 'Hay registros rechazados. Las filas correctas se conservaron; revise el detalle.', 1;
GO
