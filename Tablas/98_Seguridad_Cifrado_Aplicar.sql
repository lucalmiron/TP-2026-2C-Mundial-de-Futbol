--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 20/11/2026

--Entrega 8: Seguridad y Respaldo - Fase A (Cifrado)
--SPs para aplicar cifrado a equipos.Persona.Nombre.
--Ejecutar DESPUES de 97_Seguridad_Cifrado_Claves.sql y DESPUES de que existan los SPs de ABM (61-63).

-- Ejecutar en la base seleccionada por el instalador.
GO

-- ============================================
-- SP.uspSeguridad_CifrarPersona
-- Cifra los nombres de equipos.Persona que aún no estén cifrados.
-- Idempotente: solo cifra filas con NombreHash IS NULL.
-- ============================================
IF OBJECT_ID('SP.uspSeguridad_CifrarPersona', 'P') IS NOT NULL
    DROP PROCEDURE SP.uspSeguridad_CifrarPersona;
GO
CREATE PROCEDURE SP.uspSeguridad_CifrarPersona
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @claveAbierta BIT = 0;

    BEGIN TRY
        -- Abrir la clave simetrica para poder usar ENCRYPTBYKEY / DECRYPTBYKEY
        OPEN SYMMETRIC KEY ClaveSimetrica_AES128_Mundial
        DECRYPTION BY CERTIFICATE CertificadoCifradoMundial
        WITH PASSWORD = 'ClaveMaestra_Mundial_2026!';
        SET @claveAbierta = 1;

        -- Cifrar filas pendientes (NombreHash es NULL indica que no se cifró aún)
        UPDATE equipos.Persona
        SET
            NombreHash = HASHBYTES('SHA2_256', CONVERT(NVARCHAR(30), DECRYPTBYKEY(Nombre))),
            Nombre = ENCRYPTBYKEY(KEY_GUID('ClaveSimetrica_AES128_Mundial'), CONVERT(NVARCHAR(30), DECRYPTBYKEY(Nombre)))
        WHERE NombreHash IS NULL;

        PRINT 'Cifrado de personas completado.';
    END TRY
    BEGIN CATCH
        PRINT 'Error en uspSeguridad_CifrarPersona: ' + ERROR_MESSAGE();
        THROW;
    END CATCH

    IF @claveAbierta = 1
    BEGIN
        CLOSE SYMMETRIC KEY ClaveSimetrica_AES128_Mundial;
    END
END
GO

-- ============================================
-- SP.uspSeguridad_DescifrarNombre
-- Devuelve el nombre en claro de una persona dada su IdPersona.
-- ============================================
IF OBJECT_ID('SP.uspSeguridad_DescifrarNombre', 'P') IS NOT NULL
    DROP PROCEDURE SP.uspSeguridad_DescifrarNombre;
GO
CREATE PROCEDURE SP.uspSeguridad_DescifrarNombre
    @idPersona INT,
    @nombre NVARCHAR(30) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @claveAbierta BIT = 0;
    SET @nombre = NULL;

    BEGIN TRY
        OPEN SYMMETRIC KEY ClaveSimetrica_AES128_Mundial
        DECRYPTION BY CERTIFICATE CertificadoCifradoMundial
        WITH PASSWORD = 'ClaveMaestra_Mundial_2026!';
        SET @claveAbierta = 1;

        SELECT @nombre = CONVERT(NVARCHAR(30), DECRYPTBYKEY(Nombre))
        FROM equipos.Persona
        WHERE IdPersona = @idPersona;
    END TRY
    BEGIN CATCH
        PRINT 'Error en uspSeguridad_DescifrarNombre: ' + ERROR_MESSAGE();
        THROW;
    END CATCH

    IF @claveAbierta = 1
    BEGIN
        CLOSE SYMMETRIC KEY ClaveSimetrica_AES128_Mundial;
    END
END
GO

-- ============================================
-- SP.uspSeguridad_AplicarCifrado
-- Orquesta la modificacion de esquema y migracion de datos.
-- NOTA: Las operaciones DDL críticas van separadas por GO para evitar
-- problemas de metadatos de SQL Server al dropear/agregar columnas.
-- ============================================

-- Paso 1: Agregar columnas auxiliares si no existen
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('equipos.Persona') AND name = 'NombreHash')
BEGIN
    ALTER TABLE equipos.Persona ADD NombreHash VARBINARY(32) NULL;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('equipos.Persona') AND name = 'NombreCifrado')
BEGIN
    ALTER TABLE equipos.Persona ADD NombreCifrado VARBINARY(256) NULL;
END
GO

-- Paso 2: Si Nombre todavia es texto (NVARCHAR), migrar a cifrado
IF EXISTS (
    SELECT 1 FROM sys.columns c
    JOIN sys.types t ON t.user_type_id = c.user_type_id
    WHERE c.object_id = OBJECT_ID('equipos.Persona')
      AND c.name = 'Nombre'
      AND t.name = 'nvarchar'
)
BEGIN
    -- Abrir clave para cifrar datos existentes
    OPEN SYMMETRIC KEY ClaveSimetrica_AES128_Mundial
    DECRYPTION BY CERTIFICATE CertificadoCifradoMundial
    WITH PASSWORD = 'ClaveMaestra_Mundial_2026!';

    UPDATE equipos.Persona
    SET
        NombreHash = HASHBYTES('SHA2_256', Nombre),
        NombreCifrado = ENCRYPTBYKEY(KEY_GUID('ClaveSimetrica_AES128_Mundial'), Nombre)
    WHERE Nombre IS NOT NULL
      AND (NombreHash IS NULL OR NombreCifrado IS NULL);

    CLOSE SYMMETRIC KEY ClaveSimetrica_AES128_Mundial;
END
GO

-- Paso 3: Si Nombre todavia es NVARCHAR (texto plano), dropear y recrear como VARBINARY
-- (SQL Server no permite ALTER directo de NVARCHAR a VARBINARY con datos)
IF EXISTS (
    SELECT 1 FROM sys.columns c
    JOIN sys.types t ON t.user_type_id = c.user_type_id
    WHERE c.object_id = OBJECT_ID('equipos.Persona')
      AND c.name = 'Nombre'
      AND t.name = 'nvarchar'
)
BEGIN
    ALTER TABLE equipos.Persona DROP COLUMN Nombre;
END
GO

-- Agregar Nombre como VARBINARY NULL primero (necesario si la tabla no esta vacia)
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('equipos.Persona') AND name = 'Nombre')
BEGIN
    ALTER TABLE equipos.Persona ADD Nombre VARBINARY(256) NULL;
END
GO

-- Copiar datos cifrados a la columna Nombre (si existe NombreCifrado con datos)
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('equipos.Persona') AND name = 'NombreCifrado')
BEGIN
    UPDATE equipos.Persona
    SET Nombre = NombreCifrado
    WHERE NombreCifrado IS NOT NULL;
END
GO

-- Hacer Nombre NOT NULL una vez que tiene datos (o la tabla esta vacia)
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('equipos.Persona') AND name = 'Nombre')
   AND NOT EXISTS (SELECT 1 FROM equipos.Persona WHERE Nombre IS NULL)
BEGIN
    ALTER TABLE equipos.Persona ALTER COLUMN Nombre VARBINARY(256) NOT NULL;
END
GO

-- Dropar columna auxiliar NombreCifrado si existe
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('equipos.Persona') AND name = 'NombreCifrado')
BEGIN
    ALTER TABLE equipos.Persona DROP COLUMN NombreCifrado;
END
GO

-- Paso 4: Ejecutar cifrado de filas pendientes (idempotente)
EXEC SP.uspSeguridad_CifrarPersona;
GO

PRINT 'Aplicacion de cifrado completada.';
GO
