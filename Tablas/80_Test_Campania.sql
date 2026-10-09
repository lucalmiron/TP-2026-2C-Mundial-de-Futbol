-- Universidad Nacional de La Matanza
-- Bases de datos aplicada
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 08/10/2026
-- Objetivo: Testear Registro, Update y Baja de Campania

--Los objetos de negocio viven en MUNDIAL, el test se ejecuta contra ellos.
--Sin prerrequisitos.
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END
GO

-- Esperado: inserta 1 fila
EXEC SP.uspCampania_Registrar 'Qatar 2026', 'Campania mundialista'
GO
SELECT * FROM publicidad.Campania
GO

-- Esperado: PRINT nulo, 0 filas nuevas
EXEC SP.uspCampania_Registrar NULL, 'Campania mundialista'
GO
SELECT * FROM publicidad.Campania
GO

-- Esperado: update 1
EXEC SP.uspCampania_Update 1, 'Qatar 2026', 'Descripcion nueva'
GO
SELECT * FROM publicidad.Campania
GO

-- Esperado: PRINT inexistente Id (99)
EXEC SP.uspCampania_Update 99, 'Qatar 2026', 'Descripcion nueva'
GO
SELECT * FROM publicidad.Campania
GO

-- Esperado: borra Id 1
EXEC SP.uspCampania_Bajar 1
GO
SELECT * FROM publicidad.Campania
GO

-- Esperado: PRINT inexistente (99), 0 borradas
EXEC SP.uspCampania_Bajar 99
GO
SELECT * FROM publicidad.Campania
GO