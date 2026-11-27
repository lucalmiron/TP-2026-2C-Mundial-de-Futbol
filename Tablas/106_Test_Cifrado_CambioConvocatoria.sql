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

-- ============================================
-- 3. DESCIFRADO USANDO EL STORED PROCEDURE
--    Se llama a SP.uspSeguridad_DescifrarMotivoCambioConvocatoria
--    (definido en 98_Seguridad_Cifrado_Aplicar.sql).
--    Primero lista los IdCambio disponibles,
--    luego descifra UNO (ejemplo concreto) y finalmente
--    recorre TODOS llamando al SP uno por uno.
-- ============================================

-- 3a. IdCambio disponibles
SELECT
    c.IdCambio,
    c.Fecha,
    pa.NOMBRE AS Seleccion
FROM equipos.CambioConvocatoria c
JOIN equipos.Seleccion s ON s.IdSeleccion = c.Seleccion
JOIN equipos.Pais pa ON pa.IdPais = s.IdPais
ORDER BY c.IdCambio;
GO

-- 3b. Ejemplo concreto: descifrar UN cambio usando el SP
DECLARE @idEjemplo INT;
SELECT TOP 1 @idEjemplo = IdCambio FROM equipos.CambioConvocatoria ORDER BY IdCambio;

DECLARE @motivoEjemplo VARCHAR(200);
EXEC SP.uspSeguridad_DescifrarMotivoCambioConvocatoria
    @idCambio = @idEjemplo,
    @motivo = @motivoEjemplo OUTPUT;

SELECT
    c.IdCambio,
    pa.NOMBRE AS Seleccion,
    egr.Nombre AS Egreso,
    ing.Nombre AS Ingreso,
    c.Fecha,
    @motivoEjemplo AS MotivoDescifrado
FROM equipos.CambioConvocatoria c
JOIN equipos.Seleccion s ON s.IdSeleccion = c.Seleccion
JOIN equipos.Pais pa ON pa.IdPais = s.IdPais
JOIN equipos.Persona egr ON egr.IdPersona = c.Egreso
JOIN equipos.Persona ing ON ing.IdPersona = c.Ingreso
WHERE c.IdCambio = @idEjemplo;
GO

-- 3c. Recorrer TODOS los cambios llamando al SP uno por uno
IF OBJECT_ID('tempdb..#ResultadosSP') IS NOT NULL DROP TABLE #ResultadosSP;
CREATE TABLE #ResultadosSP (
    IdCambio INT,
    Seleccion VARCHAR(100),
    Egreso VARCHAR(100),
    Ingreso VARCHAR(100),
    Fecha DATETIME,
    MotivoDescifrado VARCHAR(200)
);

DECLARE @idActual INT;
DECLARE @motivoActual VARCHAR(200);

DECLARE curCambios CURSOR LOCAL FAST_FORWARD FOR
    SELECT c.IdCambio
    FROM equipos.CambioConvocatoria c
    ORDER BY c.IdCambio;

OPEN curCambios;
FETCH NEXT FROM curCambios INTO @idActual;

WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC SP.uspSeguridad_DescifrarMotivoCambioConvocatoria
        @idCambio = @idActual,
        @motivo = @motivoActual OUTPUT;

    INSERT INTO #ResultadosSP (IdCambio, Seleccion, Egreso, Ingreso, Fecha, MotivoDescifrado)
    SELECT
        c.IdCambio,
        pa.NOMBRE,
        egr.Nombre,
        ing.Nombre,
        c.Fecha,
        @motivoActual
    FROM equipos.CambioConvocatoria c
    JOIN equipos.Seleccion s ON s.IdSeleccion = c.Seleccion
    JOIN equipos.Pais pa ON pa.IdPais = s.IdPais
    JOIN equipos.Persona egr ON egr.IdPersona = c.Egreso
    JOIN equipos.Persona ing ON ing.IdPersona = c.Ingreso
    WHERE c.IdCambio = @idActual;

    FETCH NEXT FROM curCambios INTO @idActual;
END

CLOSE curCambios;
DEALLOCATE curCambios;

SELECT * FROM #ResultadosSP ORDER BY IdCambio;
GO