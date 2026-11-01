-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas
-- Comision 02 - Grupo 7
-- Almiron Luca, 
-- Figueroa Santiago, 
-- Ruarte Fidel, 
-- Villalba Leandro
-- Fecha 01/11/26
-- Entrega 6: importar el JSON original de GET /timezones (OpenTimezone).

USE MUNDIAL
GO

DECLARE @rutaArchivo NVARCHAR(4000) = N'C:\Users\Administrator\Desktop\tp_bdda\TP-2026-2C-Mundial-de-Futbol\Datos\Husos_horarios\husos_horarios.json';

SET NOCOUNT ON;
SET XACT_ABORT ON;

-- Se confirma cada fila por separado para conservar las validas si otra falla.
IF @@TRANCOUNT <> 0
    THROW 51000, 'Ejecute el importador fuera de una transaccion externa.', 1;
IF (2 & @@OPTIONS) = 2
    THROW 51000, 'Desactive IMPLICIT_TRANSACTIONS antes de importar.', 1;
IF NULLIF(LTRIM(RTRIM(@rutaArchivo)), N'') IS NULL
    THROW 51000, 'Debe indicar la ruta del JSON en el servidor SQL.', 1;
IF OBJECT_ID(N'sedes.HusoHorario', N'U') IS NULL
   OR OBJECT_ID(N'SP.uspHusoHorario_Registrar', N'P') IS NULL
    THROW 51000, 'Faltan la tabla HusoHorario o su SP de registro.', 1;
IF COL_LENGTH(N'sedes.HusoHorario', N'IdPais') IS NOT NULL
    THROW 51000, 'Este importador requiere la version de HusoHorario sin IdPais.', 1;

DECLARE @json NVARCHAR(MAX), @sql NVARCHAR(MAX);
-- BULK no acepta la ruta como variable. Se escapan comillas simples.
SET @sql = N'SELECT @contenido = BulkColumn FROM OPENROWSET(BULK '''
         + REPLACE(@rutaArchivo, N'''', N'''''')
         + N''', SINGLE_CLOB, CODEPAGE = ''65001'') AS archivo;';
BEGIN TRY
    EXEC sys.sp_executesql @sql, N'@contenido NVARCHAR(MAX) OUTPUT',
         @contenido = @json OUTPUT;
END TRY
BEGIN CATCH
    DECLARE @errorLectura NVARCHAR(2048) = LEFT(
        N'No se pudo leer el JSON. Verifique ruta y permisos del servicio SQL. '
        + ERROR_MESSAGE(), 2048);
    THROW 51001, @errorLectura, 1;
END CATCH;

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

DECLARE @Filas TABLE (
    Fila INT PRIMARY KEY,
    Zona NVARCHAR(MAX) COLLATE DATABASE_DEFAULT NULL,
    TipoElemento INT NOT NULL,
    TipoId INT NULL,
    CantidadId INT NOT NULL,
    IdHuso INT NULL,
    Estado VARCHAR(20) NOT NULL DEFAULT 'Pendiente',
    Detalle NVARCHAR(2048) NULL
);
-- Se lee id como texto ancho antes de validar su longitud: sin truncar.
INSERT @Filas(Fila, Zona, TipoElemento, TipoId, CantidadId)
SELECT CONVERT(INT, j.[key]) + 1, a.Zona, j.[type], a.TipoId, a.CantidadId
FROM OPENJSON(@json) AS j
OUTER APPLY (
    SELECT MAX(p.value) AS Zona, MAX(p.type) AS TipoId, COUNT(*) AS CantidadId
    FROM OPENJSON(CASE WHEN j.type = 5 THEN j.value ELSE N'{}' END) AS p
    WHERE p.[key] COLLATE Latin1_General_100_BIN2 = N'id'
) AS a;

UPDATE @Filas SET Estado = 'Error', Detalle =
    CASE WHEN TipoElemento <> 5 THEN N'El elemento debe ser un objeto.'
         WHEN CantidadId <> 1 THEN N'Debe existir exactamente una propiedad id.'
         WHEN TipoId <> 1 THEN N'id debe ser una cadena de texto.'
         ELSE N'id vacio, mayor de 50 caracteres o con caracteres no admitidos.' END
WHERE TipoElemento <> 5 OR CantidadId <> 1 OR TipoId <> 1
   OR Zona IS NULL OR DATALENGTH(Zona) = 0 OR DATALENGTH(Zona) > 100
   OR Zona COLLATE Latin1_General_100_BIN2 LIKE N'%[^A-Za-z0-9/_+-]%';

-- Deduplicar con la collation de la base, igual que el SP de alta.
UPDATE f SET Estado = 'Duplicada', Detalle = N'id repetido en este archivo.'
FROM @Filas AS f
WHERE f.Estado = 'Pendiente' AND EXISTS (
    SELECT 1 FROM @Filas AS anterior
    WHERE anterior.Estado = 'Pendiente'
      AND anterior.Zona = f.Zona AND anterior.Fila < f.Fila
);

DECLARE @fila INT, @nombre VARCHAR(50), @id INT, @cantidad INT;
DECLARE filas CURSOR LOCAL FAST_FORWARD FOR
    SELECT Fila, CONVERT(VARCHAR(50), Zona)
    FROM @Filas WHERE Estado = 'Pendiente' ORDER BY Fila;
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
            SELECT @id = IdHuso FROM sedes.HusoHorario WHERE Nombre = @nombre;
        END;
        COMMIT TRANSACTION;
        UPDATE @Filas SET IdHuso = @id,
            Estado = CASE WHEN @cantidad = 0 THEN 'Insertada' ELSE 'SinCambios' END
        WHERE Fila = @fila;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        UPDATE @Filas SET Estado = 'Error', Detalle = ERROR_MESSAGE()
        WHERE Fila = @fila;
    END CATCH;
    FETCH NEXT FROM filas INTO @fila, @nombre;
END;
CLOSE filas;
DEALLOCATE filas;

SELECT Estado, COUNT(*) AS Cantidad FROM @Filas GROUP BY Estado ORDER BY Estado;
SELECT Fila, Zona, IdHuso, Estado, Detalle FROM @Filas ORDER BY Fila;
IF EXISTS (SELECT 1 FROM @Filas WHERE Estado = 'Error')
    THROW 51004, 'Importacion parcial: se conservaron las filas validas. Revise el resultado de errores.', 1;
GO


