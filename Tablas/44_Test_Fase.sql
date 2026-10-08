-- Universidad Nacional de La Matanza
-- Bases de datos aplicada 
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 08/10/2026
-- Objetivo: Testear Registro, Update y Baja de Fase

--Los objetos de negocio (TABLAS y SP) viven en MUNDIAL, el test se ejecuta contra ellos.
--Requiere que no haya filas en TABLAS.Partido que referencien la fase 1.
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

--DROP TABLE TABLAS.Fase

-- Esperado: inserta Grupos, 1 fila
EXEC SP.uspFase_Registrar 'Grupos';
GO
SELECT * FROM TABLAS.Fase;
GO

-- Esperado: PRINT invalido Amistoso, 0 filas nuevas
EXEC SP.uspFase_Registrar 'Amistoso';
GO
SELECT * FROM TABLAS.Fase;
GO

-- Esperado: PRINT nula, 0 filas nuevas
EXEC SP.uspFase_Registrar NULL;
GO
SELECT * FROM TABLAS.Fase;
GO

-- Esperado: PRINT duplicado, 0 filas nuevas
EXEC SP.uspFase_Registrar 'Grupos';
GO
SELECT * FROM TABLAS.Fase;
GO

-- Esperado: update 1 a Final, SELECT muestra Final
EXEC SP.uspFase_Update 1, 'Final';
GO
SELECT * FROM TABLAS.Fase;
GO

-- Esperado: PRINT invalido Id (0)
EXEC SP.uspFase_Update 0, 'Grupos';
GO
SELECT * FROM TABLAS.Fase;
GO

-- Esperado: PRINT inexistente Id (99)
EXEC SP.uspFase_Update 99, 'Grupos';
GO
SELECT * FROM TABLAS.Fase;
GO

-- Esperado: borra Id 1, SELECT sin esa fila
EXEC SP.uspFase_Bajar 1;
GO
SELECT * FROM TABLAS.Fase;
GO

-- Esperado: PRINT inexistente Id (99), 0 borradas
EXEC SP.uspFase_Bajar 99;
GO
SELECT * FROM TABLAS.Fase;
GO