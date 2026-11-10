-- Elimina la base de prueba creada por el 71_Preparar_Pruebas.sql.
-- Ejecutar con la base 'master' seleccionada (o cualquier otra que no sea la de prueba).
USE master;
GO

IF DB_ID(N'MUNDIAL_Final_Test_E5') IS NOT NULL
BEGIN
    ALTER DATABASE [MUNDIAL_Final_Test_E5] 
    SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    
    DROP DATABASE [MUNDIAL_Final_Test_E5];
    
    PRINT 'Base de prueba MUNDIAL_Final_Test_E5 eliminada.';
END
ELSE
BEGIN
    PRINT 'La base de prueba MUNDIAL_Final_Test_E5 no existe.';
END
GO