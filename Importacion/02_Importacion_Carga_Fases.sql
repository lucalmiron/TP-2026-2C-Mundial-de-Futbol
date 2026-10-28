-- Universidad Nacional de La Matanza
-- Bases de Datos Aplicadas - Comision 02 - Grupo 7
-- Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 28/10/2026
-- Objetivo: carga inicial de Fase usando el SP existente.
-- Ejecutar en MUNDIAL despues de instalar tablas y procedimientos.
-- Puede repetirse sin duplicar registros por descripcion.

SET NOCOUNT ON;

IF OBJECT_ID('partidos.Fase', 'U') IS NULL
    THROW 50001, 'Falta la tabla partidos.Fase.', 1;
IF OBJECT_ID('SP.uspFase_Registrar', 'P') IS NULL
    THROW 50002, 'Falta SP.uspFase_Registrar.', 1;

IF NOT EXISTS (SELECT 1 FROM partidos.Fase WHERE Descripcion = 'Grupos')
    EXEC SP.uspFase_Registrar @Descripcion = 'Grupos';

IF NOT EXISTS (SELECT 1 FROM partidos.Fase WHERE Descripcion = 'Dieciseisavos')
    EXEC SP.uspFase_Registrar @Descripcion = 'Dieciseisavos';

IF NOT EXISTS (SELECT 1 FROM partidos.Fase WHERE Descripcion = 'Octavos')
    EXEC SP.uspFase_Registrar @Descripcion = 'Octavos';

IF NOT EXISTS (SELECT 1 FROM partidos.Fase WHERE Descripcion = 'Cuartos')
    EXEC SP.uspFase_Registrar @Descripcion = 'Cuartos';

IF NOT EXISTS (SELECT 1 FROM partidos.Fase WHERE Descripcion = 'Semifinal')
    EXEC SP.uspFase_Registrar @Descripcion = 'Semifinal';

IF NOT EXISTS (SELECT 1 FROM partidos.Fase WHERE Descripcion = 'Tercer Puesto')
    EXEC SP.uspFase_Registrar @Descripcion = 'Tercer Puesto';

IF NOT EXISTS (SELECT 1 FROM partidos.Fase WHERE Descripcion = 'Final')
    EXEC SP.uspFase_Registrar @Descripcion = 'Final';

PRINT 'Carga de Fase finalizada.';
