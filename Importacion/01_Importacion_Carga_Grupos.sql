-- Universidad Nacional de La Matanza
-- Bases de Datos Aplicadas - Comision 02 - Grupo 7
-- Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 28/10/2026
-- Objetivo: cargar los grupos A a L mediante el SP de la entrega 5.
-- Ejecutar despues de instalar las tablas y SP, seleccionando MUNDIAL en SSMS.
-- Puede repetirse: solo registra grupos que todavia no existen.
-- Los IdGrupo los genera SQL Server; no se presupone que A tenga ID 1.

SET NOCOUNT ON;

IF OBJECT_ID('equipos.Grupo', 'U') IS NULL
    THROW 50001, 'Primero debe crear la tabla equipos.Grupo.', 1;

IF OBJECT_ID('SP.uspGrupo_Registrar', 'P') IS NULL
    THROW 50002, 'Primero debe crear SP.uspGrupo_Registrar.', 1;

IF NOT EXISTS (SELECT 1 FROM equipos.Grupo WHERE NOMBRE = 'A')
    EXEC SP.uspGrupo_Registrar @nombre = 'A';

IF NOT EXISTS (SELECT 1 FROM equipos.Grupo WHERE NOMBRE = 'B')
    EXEC SP.uspGrupo_Registrar @nombre = 'B';

IF NOT EXISTS (SELECT 1 FROM equipos.Grupo WHERE NOMBRE = 'C')
    EXEC SP.uspGrupo_Registrar @nombre = 'C';

IF NOT EXISTS (SELECT 1 FROM equipos.Grupo WHERE NOMBRE = 'D')
    EXEC SP.uspGrupo_Registrar @nombre = 'D';

IF NOT EXISTS (SELECT 1 FROM equipos.Grupo WHERE NOMBRE = 'E')
    EXEC SP.uspGrupo_Registrar @nombre = 'E';

IF NOT EXISTS (SELECT 1 FROM equipos.Grupo WHERE NOMBRE = 'F')
    EXEC SP.uspGrupo_Registrar @nombre = 'F';

IF NOT EXISTS (SELECT 1 FROM equipos.Grupo WHERE NOMBRE = 'G')
    EXEC SP.uspGrupo_Registrar @nombre = 'G';

IF NOT EXISTS (SELECT 1 FROM equipos.Grupo WHERE NOMBRE = 'H')
    EXEC SP.uspGrupo_Registrar @nombre = 'H';

IF NOT EXISTS (SELECT 1 FROM equipos.Grupo WHERE NOMBRE = 'I')
    EXEC SP.uspGrupo_Registrar @nombre = 'I';

IF NOT EXISTS (SELECT 1 FROM equipos.Grupo WHERE NOMBRE = 'J')
    EXEC SP.uspGrupo_Registrar @nombre = 'J';

IF NOT EXISTS (SELECT 1 FROM equipos.Grupo WHERE NOMBRE = 'K')
    EXEC SP.uspGrupo_Registrar @nombre = 'K';

IF NOT EXISTS (SELECT 1 FROM equipos.Grupo WHERE NOMBRE = 'L')
    EXEC SP.uspGrupo_Registrar @nombre = 'L';

PRINT 'Carga de grupos A a L finalizada.';
