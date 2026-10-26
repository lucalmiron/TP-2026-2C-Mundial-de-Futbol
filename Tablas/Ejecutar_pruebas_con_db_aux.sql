-- Ejecutar en modo SQLCMD.
-- Cambiar la ruta y el archivo de test.
:setvar RutaTP "."
:setvar ArchivoTest "74_Test_Club.sql"

:ON ERROR EXIT

-- 1. Crear la base e instalar tablas y procedimientos.
:r "$(RutaTP)\71_Preparar_Pruebas.sql"
GO

-- 2. Seleccionar la base y ejecutar el test.
USE [MUNDIAL_Final_Test_E5];
GO

:r "$(RutaTP)\$(ArchivoTest)"
GO

-- 3. Si llegamos hasta aca, eliminar la base de prueba.
USE master;
GO

IF DB_ID(N'MUNDIAL_Final_Test_E5') IS NOT NULL
BEGIN
    ALTER DATABASE [MUNDIAL_Final_Test_E5]
        SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

    DROP DATABASE [MUNDIAL_Final_Test_E5];
END;
GO

PRINT 'Test terminado y base de pruebas eliminada.';