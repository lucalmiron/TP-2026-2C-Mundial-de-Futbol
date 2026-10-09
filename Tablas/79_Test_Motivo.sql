-- Universidad Nacional de La Matanza
-- Bases de datos aplicada
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 08/10/2026
-- Objetivo: Testear Registro, Update y Baja de Motivo

--Los objetos de negocio (TABLAS y SP) viven en MUNDIAL, el test se ejecuta contra ellos.
--Sin prerrequisitos.
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END
GO

-- Esperado: inserta 1 fila
EXEC SP.uspMotivo_Registrar 'Tactico'
GO
SELECT * FROM publicidad.Motivo
GO

-- Esperado: PRINT nulo, 0 filas nuevas
EXEC SP.uspMotivo_Registrar NULL
GO
SELECT * FROM publicidad.Motivo
GO

-- Esperado: PRINT duplicado, 0 filas nuevas
EXEC SP.uspMotivo_Registrar 'Tactico'
GO
SELECT * FROM publicidad.Motivo
GO

-- Esperado: update a Lesion
EXEC SP.uspMotivo_Update 1, 'Lesion'
GO
SELECT * FROM publicidad.Motivo
GO

-- Esperado: PRINT inexistente Id (99)
EXEC SP.uspMotivo_Update 99, 'Lesion'
GO
SELECT * FROM publicidad.Motivo
GO

-- Esperado: borra Id 1
EXEC SP.uspMotivo_Bajar 1
GO
SELECT * FROM publicidad.Motivo
GO

-- Esperado: PRINT inexistente (99), 0 borradas
EXEC SP.uspMotivo_Bajar 99
GO
SELECT * FROM publicidad.Motivo
GO