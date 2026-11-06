-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Comision 02
-- Grupo 7: Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 02/11/2026.
-- Objetivo: importar paises del XML de selecciones, relacionando idioma y zona
-- Requiere ejecutar antes las cargas 04 (husos) y 05 (idiomas).

-- En SSMS: Consulta -> Modo SQLCMD. Cambiar estas tres rutas.
--L
:setvar RutaSelecciones "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Datos\Selecciones_confederaciones_scrapping\selecciones_confederaciones.xml"
-- :setvar RutaSelecciones "C:\ruta\proyecto\Datos\Selecciones_confederaciones_scrapping\selecciones_confederaciones.xml"
--L
:setvar RutaIdiomas "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Datos\pais_idioma.csv"
-- :setvar RutaIdiomas "C:\ruta\proyecto\Datos\pais_idioma.csv"
--L
:setvar RutaZonas "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Datos\Husos_horarios\pais_zona.csv"
-- :setvar RutaZonas "C:\ruta\proyecto\Datos\Husos_horarios\pais_zona.csv"

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

-- Permitir reejecutar en la misma sesion si una lectura anterior fallo.
IF OBJECT_ID(N'tempdb..#Idiomas') IS NOT NULL DROP TABLE #Idiomas;
IF OBJECT_ID(N'tempdb..#Zonas') IS NOT NULL DROP TABLE #Zonas;
CREATE TABLE #Idiomas (
    Pais NVARCHAR(MAX) COLLATE DATABASE_DEFAULT,
    Idioma NVARCHAR(MAX) COLLATE DATABASE_DEFAULT
);
CREATE TABLE #Zonas (
    Pais NVARCHAR(MAX) COLLATE DATABASE_DEFAULT,
    Ciudad NVARCHAR(MAX) COLLATE DATABASE_DEFAULT,
    Zona NVARCHAR(MAX) COLLATE DATABASE_DEFAULT
);
DECLARE @xml XML, @mensaje NVARCHAR(2048);
BEGIN TRY
    -- SQLCMD sustituye las rutas antes de enviar el lote a SQL Server.
    -- SINGLE_BLOB respeta la declaracion UTF-8 del XML original.
    SELECT @xml = CONVERT(XML, BulkColumn)
    FROM OPENROWSET(
        BULK '$(RutaSelecciones)',
        SINGLE_BLOB
    ) AS archivo;

    BULK INSERT #Idiomas
    FROM '$(RutaIdiomas)'
    WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',',
          ROWTERMINATOR = '0x0a', CODEPAGE = '65001', MAXERRORS = 0);

    BULK INSERT #Zonas
    FROM '$(RutaZonas)'
    WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',',
          ROWTERMINATOR = '0x0a', CODEPAGE = '65001', MAXERRORS = 0);
END TRY
BEGIN CATCH
    SET @mensaje = LEFT(N'No se pudieron leer los archivos; no se modificaron paises. '
                           + ERROR_MESSAGE(), 2048);
    THROW 51101, @mensaje, 1;
END CATCH;
IF @xml IS NULL OR @xml.exist('/selecciones/seleccion') = 0
    THROW 51102, 'El XML no contiene /selecciones/seleccion.', 1;

UPDATE #Idiomas SET Pais = LTRIM(RTRIM(Pais)),
    Idioma = LTRIM(RTRIM(REPLACE(Idioma, NCHAR(13), N'')));
UPDATE #Zonas SET Pais = LTRIM(RTRIM(Pais)),
    Zona = LTRIM(RTRIM(REPLACE(Zona, NCHAR(13), N'')));

DECLARE @Resultado TABLE (
    Fila INT IDENTITY(1,1) PRIMARY KEY,
    Pais NVARCHAR(MAX), CantidadNombres INT,
    Estado VARCHAR(20) NOT NULL DEFAULT 'Pendiente',
    Detalle NVARCHAR(2048)
);
INSERT @Resultado (Pais, CantidadNombres)
SELECT LTRIM(RTRIM(n.value('(nombre/text())[1]', 'nvarchar(max)'))),
       n.value('count(nombre)', 'int')
FROM @xml.nodes('/selecciones/seleccion') AS t(n);

DECLARE @fila INT, @pais NVARCHAR(MAX), @nombres INT,
        @nombre VARCHAR(50), @idioma NVARCHAR(MAX), @zona NVARCHAR(MAX),
        @idPais INT, @idIdioma INT, @idHuso INT, @cantidad INT,
        @inicio TIME, @fin TIME, @estado VARCHAR(20);
DECLARE crsPaises CURSOR LOCAL FAST_FORWARD FOR
    SELECT Fila, Pais, CantidadNombres FROM @Resultado ORDER BY Fila;
OPEN crsPaises;
FETCH NEXT FROM crsPaises INTO @fila, @pais, @nombres;
WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        IF @nombres <> 1 OR NULLIF(@pais, N'') IS NULL OR LEN(@pais) > 50
            THROW 51103, 'Se requiere exactamente un nombre no vacio, de hasta 50 caracteres.', 1;
        -- Pais.NOMBRE es VARCHAR: no aceptar perdida de caracteres o truncamiento.
        IF DATALENGTH(CONVERT(VARCHAR(MAX), @pais)) > 50
           OR CONVERT(NVARCHAR(MAX), CONVERT(VARCHAR(MAX), @pais))
                COLLATE Latin1_General_100_BIN2 <> @pais COLLATE Latin1_General_100_BIN2
            THROW 51103, 'El nombre no se puede guardar fielmente en Pais.NOMBRE VARCHAR(50).', 1;
        IF EXISTS (SELECT 1 FROM @Resultado WHERE Fila < @fila AND Pais = @pais
                   AND Estado IN ('Insertada', 'Actualizada', 'SinCambios'))
        BEGIN
            UPDATE @Resultado SET Estado = 'Duplicada', Detalle = N'Pais ya procesado en este XML.'
            WHERE Fila = @fila;
        END
        ELSE
        BEGIN
            SELECT @cantidad = COUNT(*), @idioma = MIN(Idioma)
            FROM (SELECT DISTINCT Idioma FROM #Idiomas WHERE Pais = @pais) AS i;
            IF @cantidad <> 1 OR NULLIF(@idioma, N'') IS NULL
                THROW 51103, 'Falta el idioma del pais o hay idiomas contradictorios en el CSV.', 1;
            SELECT @cantidad = COUNT(*), @zona = MIN(Zona)
            FROM (SELECT DISTINCT Zona FROM #Zonas WHERE Pais = @pais) AS z;
            IF @cantidad <> 1 OR NULLIF(@zona, N'') IS NULL
                THROW 51103, 'Falta la zona del pais o hay zonas contradictorias en el CSV.', 1;

            BEGIN TRANSACTION;
            SELECT @cantidad = COUNT(*), @idIdioma = MIN(IdIdioma)
            FROM arbitros.Idioma WITH (HOLDLOCK) WHERE Descripcion = @idioma;
            IF @cantidad <> 1
                THROW 51103, 'El idioma no existe o es ambiguo en arbitros.Idioma. Revise la carga 05.', 1;
            SELECT @cantidad = COUNT(*), @idHuso = MIN(IdHuso)
            FROM sedes.HusoHorario WITH (HOLDLOCK) WHERE Nombre = @zona;
            IF @cantidad <> 1
                THROW 51103, 'La zona no existe o esta duplicada en sedes.HusoHorario. Revise la carga 04.', 1;

            SET @nombre = CONVERT(VARCHAR(50), @pais);
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
            UPDATE @Resultado SET Estado = @estado WHERE Fila = @fila;
        END;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        UPDATE @Resultado SET Estado = 'Error', Detalle = ERROR_MESSAGE() WHERE Fila = @fila;
    END CATCH;
    FETCH NEXT FROM crsPaises INTO @fila, @pais, @nombres;
END;
CLOSE crsPaises;
DEALLOCATE crsPaises;

SELECT Estado, COUNT(*) AS Cantidad FROM @Resultado GROUP BY Estado ORDER BY Estado;
SELECT Fila, Pais, Estado, Detalle FROM @Resultado ORDER BY Fila;
DROP TABLE #Idiomas;
DROP TABLE #Zonas;
IF EXISTS (SELECT 1 FROM @Resultado WHERE Estado = 'Error')
    THROW 51104, 'Hay registros rechazados. Las filas correctas se conservaron; revise el detalle.', 1;
GO
