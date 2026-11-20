--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 20/11/2026

--Entrega 8: Seguridad y Respaldo - Test de permisos del usuario usr_publicidad (rol_GestorPublicidad)
--Ejecutar como sa/dbo. Usa EXECUTE AS USER para probar permisos efectivos.

USE MUNDIAL;
GO

EXECUTE AS USER = 'usr_publicidad';
GO

PRINT '--- usr_publicidad: PRUEBAS QUE DEBEN PERMITIRSE ---';
GO

BEGIN TRY
    SELECT TOP 1 IdAnunciante FROM publicidad.Anunciante;
    PRINT 'PERMITIDO OK: SELECT en publicidad.Anunciante';
END TRY
BEGIN CATCH
    PRINT 'DENEGADO (inesperado): SELECT en publicidad.Anunciante -> ' + ERROR_MESSAGE();
END CATCH;
GO

-- Ejecuta un SP de publicidad (puede fallar por validacion de negocio, pero NO por permiso)
BEGIN TRY
    EXEC SP.uspAnunciante_Bajar @id = -1;
    PRINT 'PERMITIDO OK: EXECUTE en SP.uspAnunciante_Bajar';
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (229, 230, 15151, 916, 262)
        PRINT 'DENEGADO (inesperado): EXECUTE en SP.uspAnunciante_Bajar -> ' + ERROR_MESSAGE();
    ELSE
        PRINT 'PERMITIDO OK: ejecuto el SP (error de negocio ' + CAST(ERROR_NUMBER() AS VARCHAR) + '): ' + ERROR_MESSAGE();
END CATCH;
GO

PRINT '--- usr_publicidad: PRUEBAS QUE DEBEN DENEGARSE ---';
GO

BEGIN TRY
    EXEC SP.uspReporte_Goleadores @categoria = 'Mundial', @mundial = 1;
    PRINT 'PERMITIDO (inesperado): EXECUTE en SP.uspReporte_Goleadores';
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (229, 230, 15151, 916, 262)
        PRINT 'DENEGADO OK: reporte no permitido -> ' + ERROR_MESSAGE();
    ELSE
        PRINT 'DENEGADO OK (error ' + CAST(ERROR_NUMBER() AS VARCHAR) + '): ' + ERROR_MESSAGE();
END CATCH;
GO

BEGIN TRY
    INSERT INTO publicidad.Anunciante (Nombre, IdPais) VALUES ('Anunciante No Permitido', 1);
    PRINT 'PERMITIDO (inesperado): INSERT directo en publicidad.Anunciante';
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (229, 230, 15151, 916, 262)
        PRINT 'DENEGADO OK: INSERT directo no permitido -> ' + ERROR_MESSAGE();
    ELSE
        PRINT 'DENEGADO OK (error ' + CAST(ERROR_NUMBER() AS VARCHAR) + '): ' + ERROR_MESSAGE();
END CATCH;
GO

REVERT;
GO
