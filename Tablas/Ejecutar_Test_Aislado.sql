-- El instalador detiene la corrida si la base ya existe.
:r "$(ScriptPath)\Instalar_Base_Prueba.sql"
PRINT 'Ejecutando $(ArchivoTest)';
GO
:r "$(ScriptPath)\$(ArchivoTest)"
GO
USE master;
GO
DROP DATABASE [$(BasePrueba)];
GO
