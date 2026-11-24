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

BEGIN TRY
    BEGIN TRANSACTION;
    SELECT @sql = @sql + N'ALTER TABLE '
        + QUOTENAME(SCHEMA_NAME(t.schema_id)) + N'.' + QUOTENAME(t.name)
        + N' DROP CONSTRAINT ' + QUOTENAME(fk.name) + N';' + NCHAR(10)
    FROM sys.foreign_keys AS fk
    JOIN sys.tables AS t ON t.object_id = fk.parent_object_id
    WHERE t.is_ms_shipped = 0
    ORDER BY t.object_id, fk.object_id;

    IF @sql <> N'' EXEC sys.sp_executesql @sql;

    SET @sql = N'';
    SELECT @sql = @sql + N'DROP TABLE '
        + QUOTENAME(SCHEMA_NAME(schema_id)) + N'.' + QUOTENAME(name)
        + N';' + NCHAR(10)
    FROM sys.tables
    WHERE is_ms_shipped = 0
    ORDER BY object_id;

    IF @sql <> N'' EXEC sys.sp_executesql @sql;
    IF EXISTS (SELECT 1 FROM sys.tables WHERE is_ms_shipped = 0)
        THROW 51001, 'Quedaron tablas sin eliminar. Se revierte la operacion.', 1;

    COMMIT TRANSACTION;
    SELECT DB_NAME() AS Base, @cantidad AS TablasEliminadas,
           N'Listo: puede ejecutar nuevamente el archivo 00.' AS Resultado;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
