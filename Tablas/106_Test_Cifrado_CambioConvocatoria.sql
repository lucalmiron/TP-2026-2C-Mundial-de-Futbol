--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02
--/Grupo 7 - Almiron, Luca / Figueroa, Santiago / Ruarte, Fidel / Villalba, Leandro
--/Entrega 8 - Seguridad y Respaldo - Fase A (Cifrado)
--/Objetivo: Mostrar que el campo Motivo de equipos.CambioConvocatoria se almacena cifrado
--/          y como se recupera el texto plano mediante descifrado.

-- ============================================
-- 1. TAL COMO SE ALMACENA EN LA BASE DE DATOS
--    Motivo aparece como VARBINARY (0x...), ilegible.
-- ============================================
-- Se muestran los nombres (pais y jugadores) para que el reporte sea legible;
-- en la tabla se guardan los Id de seleccion y de jugador.
SELECT
    c.IdCambio,
    pa.NOMBRE AS Seleccion,
    egr.Nombre AS Egreso,
    ing.Nombre AS Ingreso,
    c.Fecha,
    c.Motivo,
    c.MotivoHash
FROM equipos.CambioConvocatoria c
JOIN equipos.Seleccion s ON s.IdSeleccion = c.Seleccion
JOIN equipos.Pais pa ON pa.IdPais = s.IdPais
JOIN equipos.Persona egr ON egr.IdPersona = c.Egreso
JOIN equipos.Persona ing ON ing.IdPersona = c.Ingreso
ORDER BY c.IdCambio;
GO

-- ============================================
-- 2. DESCIFRADO DEL MOTIVO
--    Se abre la clave simetrica, se recupera el texto plano
--    y se cierra la clave.
-- ============================================
DECLARE @claveAbierta BIT = 0;
BEGIN TRY
    OPEN SYMMETRIC KEY ClaveSimetrica_AES128_Mundial
    DECRYPTION BY CERTIFICATE CertificadoCifradoMundial
    WITH PASSWORD = 'ClaveMaestra_Mundial_2026!';
    SET @claveAbierta = 1;

    SELECT
        c.IdCambio,
        pa.NOMBRE AS Seleccion,
        egr.Nombre AS Egreso,
        ing.Nombre AS Ingreso,
        c.Fecha,
        CONVERT(VARCHAR(200), DECRYPTBYKEY(c.Motivo)) AS MotivoDescifrado
    FROM equipos.CambioConvocatoria c
    JOIN equipos.Seleccion s ON s.IdSeleccion = c.Seleccion
    JOIN equipos.Pais pa ON pa.IdPais = s.IdPais
    JOIN equipos.Persona egr ON egr.IdPersona = c.Egreso
    JOIN equipos.Persona ing ON ing.IdPersona = c.Ingreso
    ORDER BY c.IdCambio;
END TRY
BEGIN CATCH
    PRINT 'Error al descifrar: ' + ERROR_MESSAGE();
END CATCH;
IF @claveAbierta = 1
    CLOSE SYMMETRIC KEY ClaveSimetrica_AES128_Mundial;
GO