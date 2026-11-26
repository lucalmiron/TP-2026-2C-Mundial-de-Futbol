USE [MUNDIAL];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

-- Este control tambien protege si el USE anterior falla y el cliente continua.
IF UPPER(DB_NAME()) <> N'MUNDIAL'
    THROW 51000, 'Cancelado: la base seleccionada no es MUNDIAL.', 1;
IF @@TRANCOUNT <> 0
    THROW 51000, 'Ejecute fuera de una transaccion existente.', 1;
IF (2 & @@OPTIONS) = 2
    THROW 51000, 'Ejecute con IMPLICIT_TRANSACTIONS OFF.', 1;

DECLARE @sql NVARCHAR(MAX) = N'';
DECLARE @cantidad INT = (SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped = 0);
DECLARE @sps INT = (SELECT COUNT(*) FROM sys.procedures WHERE is_ms_shipped = 0);
DECLARE @vistas INT = (SELECT COUNT(*) FROM sys.views WHERE is_ms_shipped = 0);
DECLARE @funciones INT = (SELECT COUNT(*) FROM sys.objects
                          WHERE is_ms_shipped = 0 AND type IN ('FN','IF','TF','FS','FT'));

BEGIN TRY
    BEGIN TRANSACTION;

    -- 1) Triggers DDL de base de datos
    SET @sql = N'';
    SELECT @sql = @sql + N'DROP TRIGGER ' + QUOTENAME(name) + N' ON DATABASE;' + NCHAR(10)
    FROM sys.triggers
    WHERE parent_class_desc = 'DATABASE' AND is_ms_shipped = 0;
    IF @sql <> N'' EXEC sys.sp_executesql @sql;

    -- 2) Stored procedures (incluye CLR)
    SET @sql = N'';
    SELECT @sql = @sql + N'DROP PROCEDURE '
        + QUOTENAME(SCHEMA_NAME(schema_id)) + N'.' + QUOTENAME(name) + N';' + NCHAR(10)
    FROM sys.objects
    WHERE is_ms_shipped = 0 AND type IN ('P','PC','RF')
    ORDER BY object_id;
    IF @sql <> N'' EXEC sys.sp_executesql @sql;

    -- 3) Vistas
    SET @sql = N'';
    SELECT @sql = @sql + N'DROP VIEW '
        + QUOTENAME(SCHEMA_NAME(schema_id)) + N'.' + QUOTENAME(name) + N';' + NCHAR(10)
    FROM sys.views
    WHERE is_ms_shipped = 0
    ORDER BY object_id DESC;
    IF @sql <> N'' EXEC sys.sp_executesql @sql;

    -- 4) Funciones (escalares, inline, de tabla, CLR)
    -- Se hacen varias pasadas por si hay funciones que dependen de otras con SCHEMABINDING
    DECLARE @pasada INT = 0;
    WHILE @pasada < 5 AND EXISTS (SELECT 1 FROM sys.objects
                                  WHERE is_ms_shipped = 0 AND type IN ('FN','IF','TF','FS','FT'))
    BEGIN
        SET @sql = N'';
        SELECT @sql = @sql + N'BEGIN TRY DROP FUNCTION '
            + QUOTENAME(SCHEMA_NAME(schema_id)) + N'.' + QUOTENAME(name)
            + N'; END TRY BEGIN CATCH END CATCH;' + NCHAR(10)
        FROM sys.objects
        WHERE is_ms_shipped = 0 AND type IN ('FN','IF','TF','FS','FT')
        ORDER BY object_id DESC;
        IF @sql <> N'' EXEC sys.sp_executesql @sql;
        SET @pasada += 1;
    END;
    IF EXISTS (SELECT 1 FROM sys.objects
               WHERE is_ms_shipped = 0 AND type IN ('FN','IF','TF','FS','FT'))
        THROW 51002, 'Quedaron funciones sin eliminar. Se revierte la operacion.', 1;

    -- 5) Sinonimos
    SET @sql = N'';
    SELECT @sql = @sql + N'DROP SYNONYM '
        + QUOTENAME(SCHEMA_NAME(schema_id)) + N'.' + QUOTENAME(name) + N';' + NCHAR(10)
    FROM sys.synonyms
    WHERE is_ms_shipped = 0;
    IF @sql <> N'' EXEC sys.sp_executesql @sql;

    -- 6) Foreign keys
    SET @sql = N'';
    SELECT @sql = @sql + N'ALTER TABLE '
        + QUOTENAME(SCHEMA_NAME(t.schema_id)) + N'.' + QUOTENAME(t.name)
        + N' DROP CONSTRAINT ' + QUOTENAME(fk.name) + N';' + NCHAR(10)
    FROM sys.foreign_keys AS fk
    JOIN sys.tables AS t ON t.object_id = fk.parent_object_id
    WHERE t.is_ms_shipped = 0
    ORDER BY t.object_id, fk.object_id;
    IF @sql <> N'' EXEC sys.sp_executesql @sql;

    -- 7) Tablas
    SET @sql = N'';
    SELECT @sql = @sql + N'DROP TABLE '
        + QUOTENAME(SCHEMA_NAME(schema_id)) + N'.' + QUOTENAME(name)
        + N';' + NCHAR(10)
    FROM sys.tables
    WHERE is_ms_shipped = 0
    ORDER BY object_id;
    IF @sql <> N'' EXEC sys.sp_executesql @sql;

    -- 8) Secuencias
    SET @sql = N'';
    SELECT @sql = @sql + N'DROP SEQUENCE '
        + QUOTENAME(SCHEMA_NAME(schema_id)) + N'.' + QUOTENAME(name) + N';' + NCHAR(10)
    FROM sys.sequences
    WHERE is_ms_shipped = 0;
    IF @sql <> N'' EXEC sys.sp_executesql @sql;

    -- Verificaciones finales
    IF EXISTS (SELECT 1 FROM sys.tables WHERE is_ms_shipped = 0)
        THROW 51001, 'Quedaron tablas sin eliminar. Se revierte la operacion.', 1;
    IF EXISTS (SELECT 1 FROM sys.objects WHERE is_ms_shipped = 0 AND type IN ('P','PC','RF'))
        THROW 51003, 'Quedaron procedimientos sin eliminar. Se revierte la operacion.', 1;
    IF EXISTS (SELECT 1 FROM sys.views WHERE is_ms_shipped = 0)
        THROW 51004, 'Quedaron vistas sin eliminar. Se revierte la operacion.', 1;

    COMMIT TRANSACTION;
    SELECT DB_NAME() AS Base,
           @cantidad  AS TablasEliminadas,
           @sps       AS ProcedimientosEliminados,
           @vistas    AS VistasEliminadas,
           @funciones AS FuncionesEliminadas,
           N'Listo: puede ejecutar nuevamente el archivo 00.' AS Resultado;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO