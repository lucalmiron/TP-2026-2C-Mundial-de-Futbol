--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 23/10/2026

--/Objetivo: SP orquestador de importacion masiva (Entrega 6)

IF OBJECT_ID('SP.uspImportacion_Registrar', 'P') IS NOT NULL
    DROP PROCEDURE SP.uspImportacion_Registrar;
GO

CREATE PROCEDURE SP.uspImportacion_Registrar
    @NombreArchivo VARCHAR(200),
    @RutaArchivo   VARCHAR(500) = NULL,
    @TipoArchivo   VARCHAR(10)  = 'CSV',
    @Usuario       VARCHAR(50)  = SYSTEM_USER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @IdArchivo INT;
    DECLARE @FechaImportacion DATETIME = GETDATE();
    DECLARE @Estado VARCHAR(20) = 'Procesando';
    DECLARE @CantidadFilas INT = 0;
    DECLARE @CantidadErrores INT = 0;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Paso 1: Registrar metadata del archivo importado
        -- (AQUÍ TU COMPAÑERO: crear tabla importacion.ArchivoImportado si no existe)
        INSERT INTO importacion.ArchivoImportado
            (NombreArchivo, RutaArchivo, TipoArchivo, FechaImportacion, Usuario, Estado, CantidadFilas, CantidadErrores)
        VALUES
            (@NombreArchivo, @RutaArchivo, @TipoArchivo, @FechaImportacion, @Usuario, @Estado, 0, 0);

        SET @IdArchivo = SCOPE_IDENTITY();

        -- Paso 2: Cargar archivo a tabla de Staging
        -- (AQUÍ TU COMPAÑERO: BULK INSERT / XML / EXCEL segun @TipoArchivo)
        -- BULK INSERT importacion.Staging_Archivo FROM @RutaArchivo ...

        -- Paso 3: Validar filas (LLAMAR A SP.uspImportacion_Validar - LO HACE TU COMPAÑERO)
        -- EXEC SP.uspImportacion_Validar @IdArchivo = @IdArchivo, @CantidadErrores = @CantidadErrores OUTPUT;

        -- Paso 4: Transformar datos (LLAMAR A SP.uspImportacion_Transformar - LO HACE TU COMPAÑERO)
        -- EXEC SP.uspImportacion_Transformar @IdArchivo = @IdArchivo;

        -- Paso 5: Cargar / Upsert en tabla definitiva (LLAMAR A SP.uspImportacion_Cargar - LO HACE TU COMPAÑERO)
        -- EXEC SP.uspImportacion_Cargar @IdArchivo = @IdArchivo;

        -- Paso 6: Actualizar metadata final
        IF @CantidadErrores > 0 AND @CantidadFilas > 0
            SET @Estado = 'Parcial';
        ELSE IF @CantidadErrores > 0
            SET @Estado = 'Fallido';
        ELSE
            SET @Estado = 'Completado';

        UPDATE importacion.ArchivoImportado
        SET Estado = @Estado,
            CantidadFilas = @CantidadFilas,
            CantidadErrores = @CantidadErrores
        WHERE IdArchivo = @IdArchivo;

        COMMIT TRANSACTION;

        SELECT @IdArchivo AS IdArchivo,
               @Estado AS Estado,
               @CantidadFilas AS CantidadFilas,
               @CantidadErrores AS CantidadErrores;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        IF @IdArchivo IS NOT NULL
        BEGIN
            UPDATE importacion.ArchivoImportado
            SET Estado = 'Fallido'
            WHERE IdArchivo = @IdArchivo;
        END

        DECLARE @Msg NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @Num INT = ERROR_NUMBER();
        THROW 50001, 'Error en SP.uspImportacion_Registrar (' + CAST(@Num AS VARCHAR) + '): ' + @Msg, 1;
    END CATCH
END;
GO