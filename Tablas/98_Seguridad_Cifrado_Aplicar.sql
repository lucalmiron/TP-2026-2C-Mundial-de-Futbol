--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 23/11/26

--Entrega 8: Seguridad y Respaldo - Fase A (Cifrado)
--SPs para cifrar/descifrar Motivo de equipos.CambioConvocatoria.
--Ejecutar DESPUES de 97_Seguridad_Cifrado_Claves.sql.

-- Ejecutar en la base seleccionada por el instalador.
GO

-- ============================================
-- SP.uspSeguridad_CifrarMotivoCambioConvocatoria
-- Cifra @motivo VARCHAR(200) -> devuelve @motivoCifrado VARBINARY(256), @motivoHash VARBINARY(32)
-- ============================================
IF OBJECT_ID('SP.uspSeguridad_CifrarMotivoCambioConvocatoria', 'P') IS NOT NULL
    DROP PROCEDURE SP.uspSeguridad_CifrarMotivoCambioConvocatoria;
GO
CREATE PROCEDURE SP.uspSeguridad_CifrarMotivoCambioConvocatoria
    @motivo VARCHAR(200),
    @motivoCifrado VARBINARY(256) OUTPUT,
    @motivoHash VARBINARY(32) OUTPUT
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @claveAbierta BIT = 0;
    BEGIN TRY
        OPEN SYMMETRIC KEY ClaveSimetrica_AES128_Mundial
        DECRYPTION BY CERTIFICATE CertificadoCifradoMundial
        WITH PASSWORD = 'ClaveMaestra_Mundial_2026!';
        SET @claveAbierta = 1;

        SET @motivoCifrado = ENCRYPTBYKEY(KEY_GUID('ClaveSimetrica_AES128_Mundial'), @motivo);
        SET @motivoHash = HASHBYTES('SHA2_256', @motivo);
    END TRY
    BEGIN CATCH
        PRINT 'Error en uspSeguridad_CifrarMotivoCambioConvocatoria: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
    IF @claveAbierta = 1
        CLOSE SYMMETRIC KEY ClaveSimetrica_AES128_Mundial;
END
GO

-- ============================================
-- SP.uspSeguridad_DescifrarMotivoCambioConvocatoria
-- @idCambio INT, @motivo VARCHAR(200) OUTPUT
-- ============================================
IF OBJECT_ID('SP.uspSeguridad_DescifrarMotivoCambioConvocatoria', 'P') IS NOT NULL
    DROP PROCEDURE SP.uspSeguridad_DescifrarMotivoCambioConvocatoria;
GO
CREATE PROCEDURE SP.uspSeguridad_DescifrarMotivoCambioConvocatoria
    @idCambio INT,
    @motivo VARCHAR(200) OUTPUT
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @claveAbierta BIT = 0;
    SET @motivo = NULL;
    BEGIN TRY
        OPEN SYMMETRIC KEY ClaveSimetrica_AES128_Mundial
        DECRYPTION BY CERTIFICATE CertificadoCifradoMundial
        WITH PASSWORD = 'ClaveMaestra_Mundial_2026!';
        SET @claveAbierta = 1;

        DECLARE @motivoRecuperado VARCHAR(200);
        DECLARE @motivoHashGuardado VARBINARY(32);
        DECLARE @motivoHashCalculado VARBINARY(32);

        SELECT @motivoRecuperado = CONVERT(VARCHAR(200), DECRYPTBYKEY(Motivo)),
               @motivoHashGuardado = MotivoHash
        FROM equipos.CambioConvocatoria
        WHERE IdCambio = @idCambio;

        IF @motivoRecuperado IS NOT NULL
        BEGIN
            SET @motivoHashCalculado = HASHBYTES('SHA2_256', @motivoRecuperado);
            IF @motivoHashCalculado <> @motivoHashGuardado
            BEGIN
                THROW 50001, 'Integridad comprometida: el hash del motivo descifrado no coincide con el almacenado.', 1;
            END
        END

        SET @motivo = @motivoRecuperado;
    END TRY
    BEGIN CATCH
        PRINT 'Error en uspSeguridad_DescifrarMotivoCambioConvocatoria: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
    IF @claveAbierta = 1
        CLOSE SYMMETRIC KEY ClaveSimetrica_AES128_Mundial;
END
GO

PRINT 'SPs de cifrado Motivo CambioConvocatoria creados.';
GO