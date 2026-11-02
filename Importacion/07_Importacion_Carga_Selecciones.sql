-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Comision 02
-- Grupo 7: Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 02/11/2026.
-- Objetivo: cargar selecciones mediante los SP ABM existentes, leyendo grupos
-- del CSV y confederaciones del XML original.
-- Requiere paises (06), grupos (01) y el Mundial con IdMundial = 1 cargados.

-- En SSMS: Consulta > Modo SQLCMD. Ajustar estas tres rutas del servidor SQL.
:setvar RutaGrupos "C:\ruta\proyecto\Datos\selecciones_grupos.csv"
:setvar RutaSelecciones "C:\ruta\proyecto\Datos\Selecciones_confederaciones_scrapping\selecciones_confederaciones.xml"
:setvar RutaEquivalencias "C:\ruta\proyecto\Datos\equivalencias_selecciones.csv"

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

IF OBJECT_ID(N'tempdb..#GruposCsv') IS NOT NULL DROP TABLE #GruposCsv;
CREATE TABLE #GruposCsv (
    Seleccion NVARCHAR(MAX) COLLATE DATABASE_DEFAULT,
    Grupo NVARCHAR(MAX) COLLATE DATABASE_DEFAULT
);
IF OBJECT_ID(N'tempdb..#AliasCsv') IS NOT NULL DROP TABLE #AliasCsv;
CREATE TABLE #AliasCsv (
    NombreCsv NVARCHAR(MAX) COLLATE DATABASE_DEFAULT,
    NombreXml NVARCHAR(MAX) COLLATE DATABASE_DEFAULT
);
DECLARE @xml XML, @mensaje NVARCHAR(2048);
BEGIN TRY
    BULK INSERT #GruposCsv
    FROM '$(RutaGrupos)'
    WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',',
          ROWTERMINATOR = '0x0a', CODEPAGE = '65001', MAXERRORS = 0);

    BULK INSERT #AliasCsv
    FROM '$(RutaEquivalencias)'
    WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',',
          ROWTERMINATOR = '0x0a', CODEPAGE = '65001', MAXERRORS = 0);

    SELECT @xml = CONVERT(XML, BulkColumn)
    FROM OPENROWSET(BULK '$(RutaSelecciones)', SINGLE_BLOB) AS archivo;
END TRY
BEGIN CATCH
    DROP TABLE #AliasCsv;
    DROP TABLE #GruposCsv;
    SET @mensaje = LEFT(N'No se pudieron leer los archivos; no se modificaron selecciones. '
                        + ERROR_MESSAGE(), 2048);
    THROW 51301, @mensaje, 1;
END CATCH;
IF @xml IS NULL OR @xml.exist('/selecciones/seleccion') = 0
BEGIN
    DROP TABLE #GruposCsv;
    DROP TABLE #AliasCsv;
    THROW 51302, 'El XML no contiene /selecciones/seleccion.', 1;
END;

-- Equivalencias cargadas desde CSV: no hay nombres de paises en el codigo.
-- Los nombres que coinciden en ambos archivos se utilizan directamente.
DECLARE @Alias TABLE (
    NombreCsv NVARCHAR(100) PRIMARY KEY,
    NombreXml NVARCHAR(100) NOT NULL
);
-- El archivo auxiliar solo relaciona los nombres de las dos fuentes.
UPDATE #AliasCsv SET NombreCsv = LTRIM(RTRIM(NombreCsv)),
    NombreXml = LTRIM(RTRIM(REPLACE(NombreXml, NCHAR(13), N'')));
IF EXISTS (SELECT 1 FROM #AliasCsv
           WHERE NULLIF(NombreCsv, N'') IS NULL OR NULLIF(NombreXml, N'') IS NULL
              OR LEN(NombreCsv) > 100 OR LEN(NombreXml) > 100)
   OR EXISTS (SELECT NombreCsv FROM #AliasCsv GROUP BY NombreCsv
              HAVING COUNT(DISTINCT NombreXml) > 1)
BEGIN
    SELECT NombreCsv, NombreXml FROM #AliasCsv;
    DROP TABLE #GruposCsv;
    DROP TABLE #AliasCsv;
    THROW 51302, 'Equivalencias invalidas: nombres vacios, demasiado largos o destinos contradictorios.', 1;
END;
INSERT @Alias (NombreCsv, NombreXml)
SELECT DISTINCT NombreCsv, NombreXml FROM #AliasCsv;
DROP TABLE #AliasCsv;

DECLARE @SeleccionesXml TABLE (
    Nombre NVARCHAR(MAX), Confederacion NVARCHAR(MAX),
    CantidadNombres INT, CantidadConfederaciones INT
);
INSERT @SeleccionesXml
SELECT LTRIM(RTRIM(n.value('(nombre/text())[1]', 'nvarchar(max)'))),
       LTRIM(RTRIM(n.value('(confederacion/text())[1]', 'nvarchar(max)'))),
       n.value('count(nombre)', 'int'), n.value('count(confederacion)', 'int')
FROM @xml.nodes('/selecciones/seleccion') AS t(n);

UPDATE #GruposCsv SET Seleccion = LTRIM(RTRIM(Seleccion)),
    Grupo = UPPER(LTRIM(RTRIM(REPLACE(Grupo, NCHAR(13), N''))));
DECLARE @Resultado TABLE (
    Fila INT IDENTITY(1,1) PRIMARY KEY,
    NombreCsv NVARCHAR(MAX), Pais NVARCHAR(MAX), Grupo NVARCHAR(MAX),
    Estado VARCHAR(20) NOT NULL DEFAULT 'Pendiente', Detalle NVARCHAR(2048)
);
INSERT @Resultado (NombreCsv, Pais, Grupo)
SELECT c.Seleccion, COALESCE(a.NombreXml, c.Seleccion), c.Grupo
FROM #GruposCsv c LEFT JOIN @Alias a ON a.NombreCsv = c.Seleccion;
DROP TABLE #GruposCsv;
IF NOT EXISTS (SELECT 1 FROM @Resultado)
    THROW 51302, 'El CSV no contiene selecciones.', 1;

-- Rechazar todas las versiones de una seleccion si el CSV le asigna varios grupos.
UPDATE r SET Estado = 'Error', Detalle = N'El CSV asigna grupos diferentes a la misma seleccion.'
FROM @Resultado r
WHERE EXISTS (SELECT 1 FROM @Resultado o WHERE o.Pais = r.Pais
              AND ISNULL(o.Grupo, N'') <> ISNULL(r.Grupo, N''));

DECLARE @fila INT, @pais NVARCHAR(MAX), @grupo NVARCHAR(MAX),
        @conf NVARCHAR(MAX), @confederacion VARCHAR(45), @cantidad INT,
        @idPais INT, @idGrupo INT, @idSeleccion INT, @grupoActual INT,
        @grupoActualizar INT, @confActual VARCHAR(45), @estado VARCHAR(20);
DECLARE crsSelecciones CURSOR LOCAL FAST_FORWARD FOR
    SELECT Fila, Pais, Grupo FROM @Resultado WHERE Estado = 'Pendiente' ORDER BY Fila;
OPEN crsSelecciones;
FETCH NEXT FROM crsSelecciones INTO @fila, @pais, @grupo;
WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        IF NULLIF(@pais, N'') IS NULL OR LEN(@pais) > 50
            THROW 51303, 'Nombre de seleccion vacio o mayor de 50 caracteres.', 1;
        IF @grupo IS NULL OR LEN(@grupo) <> 1
           OR @grupo COLLATE Latin1_General_100_BIN2 NOT LIKE N'[A-L]'
            THROW 51303, 'Grupo invalido: se espera una letra entre A y L.', 1;
        IF EXISTS (SELECT 1 FROM @Resultado WHERE Fila < @fila AND Pais = @pais
                   AND Estado IN ('Insertada', 'Actualizada', 'SinCambios'))
        BEGIN
            UPDATE @Resultado SET Estado = 'Duplicada', Detalle = N'Seleccion ya procesada en este CSV.'
            WHERE Fila = @fila;
        END
        ELSE
        BEGIN
            SELECT @cantidad = COUNT(*), @conf = MIN(Confederacion)
            FROM @SeleccionesXml WHERE Nombre = @pais;
            IF @cantidad <> 1
                THROW 51303, 'La seleccion falta o esta repetida en el XML. Revise las equivalencias de nombres.', 1;
            IF EXISTS (SELECT 1 FROM @SeleccionesXml WHERE Nombre = @pais
                       AND (CantidadNombres <> 1 OR CantidadConfederaciones <> 1))
               OR NULLIF(@conf, N'') IS NULL OR LEN(@conf) > 45
                THROW 51303, 'Nombre o confederacion invalidos en el XML.', 1;
            IF DATALENGTH(CONVERT(VARCHAR(MAX), @conf)) > 45
               OR CONVERT(NVARCHAR(MAX), CONVERT(VARCHAR(MAX), @conf))
                    COLLATE Latin1_General_100_BIN2 <> @conf COLLATE Latin1_General_100_BIN2
                THROW 51303, 'La confederacion no cabe sin perdida en VARCHAR(45).', 1;
            SET @confederacion = CONVERT(VARCHAR(45), @conf);

            BEGIN TRANSACTION;
            -- Serializar la carga por grupo para respetar su cupo durante el upsert.
            SELECT @cantidad = COUNT(*), @idGrupo = MIN(IdGrupo)
            FROM equipos.Grupo WITH (UPDLOCK, HOLDLOCK) WHERE NOMBRE = @grupo;
            IF @cantidad <> 1
                THROW 51303, 'El grupo no existe o es ambiguo. Ejecute la carga 01.', 1;
            SELECT @cantidad = COUNT(*), @idPais = MIN(IdPais)
            FROM equipos.Pais WITH (HOLDLOCK) WHERE NOMBRE = @pais;
            IF @cantidad <> 1
                THROW 51303, 'El pais no existe o es ambiguo. Revise la carga 06.', 1;

            SET @idSeleccion = NULL;
            SET @grupoActual = NULL;
            SET @confActual = NULL;
            SELECT @idSeleccion = IdSeleccion, @grupoActual = IdGrupo,
                   @confActual = CONFEDERACION
            FROM equipos.Seleccion WITH (UPDLOCK, HOLDLOCK)
            WHERE IdPais = @idPais AND IdMundial = @idMundial;
            IF @idSeleccion IS NULL
            BEGIN
                EXEC SP.uspSeleccion_Registrar @idPais = @idPais, @idMundial = @idMundial,
                    @idGrupo = @idGrupo, @confederacion = @confederacion;
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
            UPDATE @Resultado SET Estado = @estado WHERE Fila = @fila;
        END;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        UPDATE @Resultado SET Estado = 'Error', Detalle = ERROR_MESSAGE() WHERE Fila = @fila;
    END CATCH;
    FETCH NEXT FROM crsSelecciones INTO @fila, @pais, @grupo;
END;
CLOSE crsSelecciones;
DEALLOCATE crsSelecciones;

SELECT Estado, COUNT(*) AS Cantidad FROM @Resultado GROUP BY Estado ORDER BY Estado;
SELECT Fila, NombreCsv, Pais, Grupo, Estado, Detalle FROM @Resultado ORDER BY Fila;
IF EXISTS (SELECT 1 FROM @Resultado WHERE Estado = 'Error')
    THROW 51304, 'Hay selecciones rechazadas. Las filas correctas se conservaron; revise el detalle.', 1;
GO
