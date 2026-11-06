-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas
-- Comision 02 - Grupo 7
-- Almiron Luca; 
-- Figueroa Santiago; 
-- Ruarte Fidel; 
-- Villalba Leandro.
-- Fecha 01/11/26
-- Carga del catalogo Idioma leyendo los idiomas desde pais_idioma.csv. Ejecutar en MUNDIAL.

-- En SSMS: Consulta -> Modo SQLCMD. Cambiar la ruta de abajo.
--L
:setvar RutaIdiomas "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Datos\pais_idioma.csv"
-- :setvar RutaIdiomas "C:\ruta\proyecto\Datos\pais_idioma.csv"

USE [MUNDIAL];
GO
SET NOCOUNT ON;

IF UPPER(DB_NAME()) <> N'MUNDIAL'
    THROW 51000, 'Seleccione la base MUNDIAL.', 1;
IF OBJECT_ID(N'arbitros.Idioma', N'U') IS NULL
   OR OBJECT_ID(N'SP.uspIdioma_Registrar', N'P') IS NULL
    THROW 51000, 'Ejecute primero el instalador 00: faltan Idioma o su SP.', 1;
IF @@TRANCOUNT <> 0 OR (2 & @@OPTIONS) = 2
    THROW 51000, 'Ejecute sin transaccion externa y con IMPLICIT_TRANSACTIONS OFF.', 1;

-- 1) Staging: el CSV se carga tal cual (pais,idioma), con una fila por pais.
CREATE TABLE #PaisIdiomaCsv (Pais NVARCHAR(100) NULL, Idioma NVARCHAR(100) NULL);

BEGIN TRY
    -- SQLCMD sustituye la ruta antes de enviar el lote a SQL Server.
    BULK INSERT #PaisIdiomaCsv
    FROM '$(RutaIdiomas)'
    WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',',
          ROWTERMINATOR = '0x0a', CODEPAGE = '65001', TABLOCK);
END TRY
BEGIN CATCH
    DROP TABLE #PaisIdiomaCsv;
    DECLARE @msg NVARCHAR(2048) = N'No se pudo leer el CSV: ' + ERROR_MESSAGE();
    THROW 51002, @msg, 1;
END CATCH;

-- 2) Idiomas distintos (el CSV repite el idioma por cada pais).
DECLARE @Idiomas TABLE (Descripcion NVARCHAR(20) PRIMARY KEY);
INSERT @Idiomas (Descripcion)
SELECT DISTINCT LTRIM(RTRIM(REPLACE(Idioma, CHAR(13), N'')))
FROM #PaisIdiomaCsv
WHERE NULLIF(LTRIM(RTRIM(REPLACE(Idioma, CHAR(13), N''))), N'') IS NOT NULL
  AND LEN(LTRIM(RTRIM(REPLACE(Idioma, CHAR(13), N'')))) <= 20;

-- Idiomas que no entran en NVARCHAR(20): se informan en vez de truncarse en silencio.
IF EXISTS (SELECT 1 FROM #PaisIdiomaCsv WHERE LEN(LTRIM(RTRIM(REPLACE(Idioma, CHAR(13), N'')))) > 20)
    SELECT DISTINCT Idioma AS IdiomaDemasiadoLargo FROM #PaisIdiomaCsv
    WHERE LEN(LTRIM(RTRIM(REPLACE(Idioma, CHAR(13), N'')))) > 20;

DROP TABLE #PaisIdiomaCsv;

IF NOT EXISTS (SELECT 1 FROM @Idiomas)
    THROW 51003, 'El CSV no aportó ningún idioma. Revise ruta y formato.', 1;

-- 3) Alta idempotente, igual que antes.
DECLARE @Resultado TABLE (
    Idioma NVARCHAR(20), Estado VARCHAR(20), Detalle NVARCHAR(2048)
);
DECLARE @descripcion NVARCHAR(20);
DECLARE idiomas CURSOR LOCAL FAST_FORWARD FOR
    SELECT Descripcion FROM @Idiomas ORDER BY Descripcion;
OPEN idiomas;
FETCH NEXT FROM idiomas INTO @descripcion;
WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        IF EXISTS (SELECT 1 FROM arbitros.Idioma WHERE Descripcion = @descripcion)
            INSERT @Resultado VALUES (@descripcion, 'SinCambios', NULL);
        ELSE
        BEGIN
            EXEC SP.uspIdioma_Registrar @descripcion = @descripcion;
            INSERT @Resultado VALUES (@descripcion, 'Insertada', NULL);
        END;
    END TRY
    BEGIN CATCH
        INSERT @Resultado VALUES (@descripcion, 'Error', ERROR_MESSAGE());
    END CATCH;
    FETCH NEXT FROM idiomas INTO @descripcion;
END;
CLOSE idiomas;
DEALLOCATE idiomas;

IF EXISTS (SELECT 1 FROM @Resultado WHERE Estado = 'Error')
    THROW 51001, 'Hubo errores. Revise el detalle; las altas exitosas se conservaron.', 1;
GO