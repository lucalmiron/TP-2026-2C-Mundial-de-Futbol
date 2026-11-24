--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 20/11/2026

--Entrega 8: Seguridad y Respaldo - Test de permisos del usuario usr_consulta (rol_Consulta)
--Ejecutar como sa/dbo. Usa EXECUTE AS USER para probar permisos efectivos.

USE MUNDIAL;
GO

EXECUTE AS USER = 'usr_consulta';
GO

PRINT '--- usr_consulta: PRUEBAS QUE DEBEN PERMITIRSE ---';
GO

BEGIN TRY
    EXEC SP.uspReporte_Goleadores @categoria = 'Mundial', @mundial = 1;
    PRINT 'PERMITIDO OK: EXECUTE en SP.uspReporte_Goleadores';
END TRY
BEGIN CATCH
    PRINT 'DENEGADO (inesperado): EXECUTE en SP.uspReporte_Goleadores -> ' + ERROR_MESSAGE();
END CATCH;
GO

BEGIN TRY
    SELECT TOP 1 IdPais FROM equipos.Pais;
    PRINT 'PERMITIDO OK: SELECT en equipos.Pais';
END TRY
BEGIN CATCH
    PRINT 'DENEGADO (inesperado): SELECT en equipos.Pais -> ' + ERROR_MESSAGE();
END CATCH;
GO

PRINT '--- usr_consulta: PRUEBAS QUE DEBEN DENEGARSE ---';
GO

BEGIN TRY
    INSERT INTO equipos.Pais (NOMBRE) VALUES ('Pais No Permitido');
    PRINT 'PERMITIDO (inesperado): INSERT directo en equipos.Pais';
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (229, 230, 15151, 916, 262)
        PRINT 'DENEGADO OK: INSERT directo no permitido -> ' + ERROR_MESSAGE();
    ELSE
        PRINT 'DENEGADO OK (error ' + CAST(ERROR_NUMBER() AS VARCHAR) + '): ' + ERROR_MESSAGE();
END CATCH;
GO

BEGIN TRY
    EXEC SP.uspAlineacion_Registrar @IdPartido = 1, @IdJugador = 1, @Rol = 'Titular', @PosicionCancha = 'DEL', @Esquema = '4-3-3';
    PRINT 'PERMITIDO (inesperado): EXECUTE en SP.uspAlineacion_Registrar';
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (229, 230, 15151, 916, 262)
        PRINT 'DENEGADO OK: SP de ABM no permitido -> ' + ERROR_MESSAGE();
    ELSE
        PRINT 'DENEGADO OK (error ' + CAST(ERROR_NUMBER() AS VARCHAR) + '): ' + ERROR_MESSAGE();
END CATCH;
GO

REVERT;
GO
