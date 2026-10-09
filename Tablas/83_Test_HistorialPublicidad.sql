-- Universidad Nacional de La Matanza
-- Bases de datos aplicada
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 08/10/2026
-- Objetivo: Testear Registro, Update y Baja de HistorialPublicidad

--Los objetos de negocio viven en MUNDIAL, el test se ejecuta contra ellos.
--Requiere Publicidad 1, Partido 1 (partidos.Partido) y EspacioPublicitario 1.
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END
GO

-- Esperado: inserta 1 fila
EXEC SP.uspHistorialPublicidad_Registrar 1, 1, 1, 1000.00
GO
SELECT * FROM publicidad.HistorialPublicidad
GO

-- Esperado: PRINT costo invalido (0), 0 filas nuevas
EXEC SP.uspHistorialPublicidad_Registrar 1, 1, 1, 0
GO
SELECT * FROM publicidad.HistorialPublicidad
GO

-- Esperado: PRINT duplicado (misma publicidad, partido y espacio), 0 filas nuevas
EXEC SP.uspHistorialPublicidad_Registrar 1, 1, 1, 1000.00
GO
SELECT * FROM publicidad.HistorialPublicidad
GO

-- Esperado: PRINT inexistente Publicidad (99), 0 filas nuevas
EXEC SP.uspHistorialPublicidad_Registrar 99, 1, 1, 1000.00
GO
SELECT * FROM publicidad.HistorialPublicidad
GO

-- Esperado: PRINT inexistente Partido (99), 0 filas nuevas
EXEC SP.uspHistorialPublicidad_Registrar 1, 99, 1, 1000.00
GO
SELECT * FROM publicidad.HistorialPublicidad
GO

-- Esperado: update costo de Id 1
EXEC SP.uspHistorialPublicidad_Update 1, 1, 1, 1, 1500.00
GO
SELECT * FROM publicidad.HistorialPublicidad
GO

-- Esperado: PRINT inexistente Id (99)
EXEC SP.uspHistorialPublicidad_Update 99, 1, 1, 1, 1500.00
GO
SELECT * FROM publicidad.HistorialPublicidad
GO

-- Esperado: borra Id 1
EXEC SP.uspHistorialPublicidad_Bajar 1
GO
SELECT * FROM publicidad.HistorialPublicidad
GO

-- Esperado: PRINT inexistente (99), 0 borradas
EXEC SP.uspHistorialPublicidad_Bajar 99
GO
SELECT * FROM publicidad.HistorialPublicidad
GO