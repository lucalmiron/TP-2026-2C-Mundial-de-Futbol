--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 20/11/2026

--Entrega 8: Seguridad y Respaldo - Fase A (Cifrado)
--Creacion de certificado y clave simétrica para cifrado de datos sensibles.
--Ejecutar en la base MUNDIAL (o MUNDIALtesting) DESPUES de crear tablas y ANTES
--de ejecutar importadores o SPs que cifren/descifren.

-- Ejecutar en la base seleccionada por el instalador.
GO

-- Crear certificado protegido por contraseña (idempotente).
IF NOT EXISTS (SELECT 1 FROM sys.certificates WHERE name = 'CertificadoCifradoMundial')
BEGIN
    CREATE CERTIFICATE CertificadoCifradoMundial
    ENCRYPTION BY PASSWORD = 'ClaveMaestra_Mundial_2026!'  -- TODO: reemplazar por valor seguro en produccion
    WITH SUBJECT = 'Certificado para cifrado de datos sensibles del TP Mundial de Futbol';
END
GO

-- Crear clave simetrica AES_128 sobre el certificado (idempotente).
IF NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name = 'ClaveSimetrica_AES128_Mundial')
BEGIN
    CREATE SYMMETRIC KEY ClaveSimetrica_AES128_Mundial
    WITH ALGORITHM = AES_128
    ENCRYPTION BY CERTIFICATE CertificadoCifradoMundial;
END
GO

PRINT 'Claves de cifrado creadas/verificadas: CertificadoCifradoMundial + ClaveSimetrica_AES128_Mundial.';
GO
