-- Universidad Nacional de La Matanza
-- Bases de datos aplicada
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 08/10/2026
-- Objetivo: Testear Registro, Update y Baja de Publicidad

--Los objetos de negocio viven en MUNDIAL, el test se ejecuta contra ellos.
--Requiere Campania 1 e Idioma 1.
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END
GO

-- Esperado: inserta 1 fila
EXEC SP.uspPublicidad_Registrar 'Spot 30s', 1, 1
GO
SELECT * FROM publicidad.Publicidad
GO

-- Esperado: PRINT nulo, 0 filas nuevas
EXEC SP.uspPublicidad_Registrar NULL, 1, 1
GO
SELECT * FROM publicidad.Publicidad
GO

-- Esperado: PRINT duplicado, 0 filas nuevas
EXEC SP.uspPublicidad_Registrar 'Spot 30s', 1, 1
GO
SELECT * FROM publicidad.Publicidad
GO

-- Esperado: PRINT inexistente Campania (99), 0 filas nuevas
EXEC SP.uspPublicidad_Registrar 'Spot 60s', 99, 1
GO
SELECT * FROM publicidad.Publicidad
GO

-- Esperado: PRINT inexistente Idioma (99), 0 filas nuevas
EXEC SP.uspPublicidad_Registrar 'Spot 60s', 1, 99
GO
SELECT * FROM publicidad.Publicidad
GO

-- Esperado: update 1
EXEC SP.uspPublicidad_Update 1, 'Spot 60s', 1, 1
GO
SELECT * FROM publicidad.Publicidad
GO

-- Esperado: PRINT inexistente Id (99)
EXEC SP.uspPublicidad_Update 99, 'Spot 60s', 1, 1
GO
SELECT * FROM publicidad.Publicidad
GO

-- Esperado: borra Id 1
EXEC SP.uspPublicidad_Bajar 1
GO
SELECT * FROM publicidad.Publicidad
GO

-- Esperado: PRINT inexistente (99), 0 borradas
EXEC SP.uspPublicidad_Bajar 99
GO
SELECT * FROM publicidad.Publicidad
GO