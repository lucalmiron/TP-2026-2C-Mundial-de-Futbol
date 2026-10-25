--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02
--/Grupo 7 - Integrantes:
--/Almiron, Luca
--/Figueroa, Santiago
--/Ruarte, Fidel
--/Villalba, Leandro
--/Fecha: 23/10/2026
--/Objetivo: SP orquestador de importacion masiva (Entrega 6)

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
    USE MUNDIAL
END;
GO

IF OBJECT_ID('SP.uspImportacion_Registrar', 'P') IS NOT NULL
    DROP PROCEDURE SP.uspImportacion_Registrar;
GO

CREATE PROCEDURE SP.uspImportacion_Registrar
    @nombreArchivo VARCHAR(200),
    @rutaCarpeta VARCHAR(500) = 'C:\Users\Luca\Downloads\TP-2026-2C-Mundial-de-Futbol\TP-2026-2C-Mundial-de-Futbol\ArchivosPrueba\',
    @tipoArchivo VARCHAR(10) = 'CSV',
    @usuario VARCHAR(128) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    -- XACT_ABORT OFF: uspImportacion_Cargar maneja sus errores con TRY/CATCH dentro de la transaccion.
    SET XACT_ABORT OFF;

    DECLARE @errorCount INT = 0;
    DECLARE @errorLine NVARCHAR(2048) = N'Error/es:';
    DECLARE @idArchivo INT = NULL;
    DECLARE @rutaCompleta VARCHAR(700);
    DECLARE @estado VARCHAR(20) = 'Procesando';
    DECLARE @cantidadFilas INT = 0;
    DECLARE @cantidadErrores INT = 0;
    DECLARE @insertadas INT = 0;
    DECLARE @actualizadas INT = 0;
    DECLARE @sinCambios INT = 0;
    DECLARE @omitidas INT = 0;
    DECLARE @sql NVARCHAR(MAX);
    DECLARE @sysUser NVARCHAR(128);
    DECLARE @throwMsg NVARCHAR(2048);
    DECLARE @errMsg NVARCHAR(200);

    BEGIN TRY
        SET @sysUser = SYSTEM_USER;
        SET @usuario = COALESCE(@usuario, @sysUser);
        SET @rutaCarpeta = COALESCE(NULLIF(LTRIM(RTRIM(@rutaCarpeta)), ''), 'C:\Users\Luca\Downloads\TP-2026-2C-Mundial-de-Futbol\TP-2026-2C-Mundial-de-Futbol\ArchivosPrueba\');

        IF (@nombreArchivo IS NULL) OR (LTRIM(RTRIM(@nombreArchivo)) = '')
        BEGIN
            SET @errorCount = @errorCount + 1;
            SET @errorLine = @errorLine + CHAR(13) + N'- Valor invalido: Nombre de archivo.';
        END
        ELSE IF (CHARINDEX('\', @nombreArchivo) > 0) OR (CHARINDEX('/', @nombreArchivo) > 0) OR (CHARINDEX(':', @nombreArchivo) > 0)
        BEGIN
            SET @errorCount = @errorCount + 1;
            SET @errorLine = @errorLine + CHAR(13) + N'- Valor invalido: Nombre de archivo (no debe incluir la ruta, usar @rutaCarpeta).';
        END;

        IF (@tipoArchivo IS NULL) OR (UPPER(LTRIM(RTRIM(@tipoArchivo))) <> 'CSV')
        BEGIN
            SET @errorCount = @errorCount + 1;
            SET @errorLine = @errorLine + CHAR(13) + N'- Valor invalido: Tipo de archivo (por ahora solo CSV).';
        END;

        IF (@errorCount > 0)
        BEGIN
            SET @throwMsg = @errorLine;
            ;THROW 50001, @throwMsg, 1;
        END;

        IF RIGHT(@rutaCarpeta, 1) NOT IN ('\', '/')
            SET @rutaCarpeta = @rutaCarpeta + '\';

        SET @nombreArchivo = LTRIM(RTRIM(@nombreArchivo));
        SET @tipoArchivo = UPPER(LTRIM(RTRIM(@tipoArchivo)));
        SET @rutaCompleta = @rutaCarpeta + @nombreArchivo;

        INSERT INTO importacion.ArchivoImportado
            (NombreArchivo, RutaArchivo, TipoArchivo, FechaImportacion, Usuario, Estado, CantidadFilas, CantidadErrores)
        VALUES
            (@nombreArchivo, @rutaCompleta, @tipoArchivo, GETDATE(), @usuario, @estado, 0, 0);

        SET @idArchivo = SCOPE_IDENTITY();

        BEGIN TRANSACTION;

        SET @sql = N'BULK INSERT importacion.vwStagingPais FROM ''' + REPLACE(@rutaCompleta, '''', '''''')
                 + N''' WITH (FORMAT = ''CSV'', FIRSTROW = 2, FIELDTERMINATOR = '','', CODEPAGE = ''65001'', TABLOCK);';
        EXEC sp_executesql @sql;

        UPDATE importacion.StagingPais
        SET IdArchivo = @idArchivo
        WHERE IdArchivo IS NULL;

        SET @cantidadFilas = @@ROWCOUNT;

        IF (@cantidadFilas = 0)
        BEGIN
            SET @errMsg = N'El archivo no contiene filas de datos.';
            ;THROW 50002, @errMsg, 1;
        END;

        EXEC SP.uspImportacion_Validar @idArchivo = @idArchivo, @cantidadErrores = @cantidadErrores OUTPUT;
        EXEC SP.uspImportacion_Transformar @idArchivo = @idArchivo;
        EXEC SP.uspImportacion_Cargar @idArchivo = @idArchivo,
                                      @insertadas = @insertadas OUTPUT,
                                      @actualizadas = @actualizadas OUTPUT,
                                      @sinCambios = @sinCambios OUTPUT;

        SELECT @cantidadErrores = COUNT(*) FROM importacion.StagingPais WHERE IdArchivo = @idArchivo AND Estado = 'Error';
        SELECT @omitidas = COUNT(*) FROM importacion.StagingPais WHERE IdArchivo = @idArchivo AND Estado = 'Omitida';

        COMMIT TRANSACTION;

        IF @cantidadErrores = 0
            SET @estado = 'Completado';
        ELSE IF (@insertadas + @actualizadas + @sinCambios) > 0
            SET @estado = 'Parcial';
        ELSE
            SET @estado = 'Fallido';

        UPDATE importacion.ArchivoImportado
        SET Estado = @estado,
            CantidadFilas = @cantidadFilas,
            CantidadErrores = @cantidadErrores
        WHERE IdArchivo = @idArchivo;

        SELECT @idArchivo AS IdArchivo,
               @estado AS Estado,
               @cantidadFilas AS CantidadFilas,
               @insertadas AS Insertadas,
               @actualizadas AS Actualizadas,
               @sinCambios AS SinCambios,
               @omitidas AS Omitidas,
               @cantidadErrores AS CantidadErrores;

        SELECT IdFila, NOMBRE, PBI, Detalle
        FROM importacion.StagingPais
        WHERE IdArchivo = @idArchivo
          AND Estado = 'Error'
        ORDER BY IdFila;
    END TRY
    BEGIN CATCH
        DECLARE @msgCatch NVARCHAR(500) = LEFT(ERROR_MESSAGE(), 500);

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        IF @idArchivo IS NOT NULL
        BEGIN
            UPDATE importacion.ArchivoImportado
            SET Estado = 'Fallido',
                MensajeError = @msgCatch
            WHERE IdArchivo = @idArchivo;
        END;

        ;THROW;
    END CATCH
END;
GO