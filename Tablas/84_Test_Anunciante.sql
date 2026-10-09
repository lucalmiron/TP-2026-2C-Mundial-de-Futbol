-- Universidad Nacional de La Matanza
-- Bases de datos aplicada
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 08/10/2026
-- Objetivo: Testear Registro, Update y Baja de Anunciante

--Los objetos de negocio viven en MUNDIAL, el test se ejecuta contra ellos.
--Requiere equipos.Pais 1.
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END
GO

-- Esperado: inserta 1 fila
EXEC SP.uspAnunciante_Registrar 'Coca', 1;
GO
SELECT * FROM publicidad.Anunciante;
GO

-- Esperado: PRINT nulo, 0 filas nuevas
EXEC SP.uspAnunciante_Registrar NULL, 1
GO
SELECT * FROM publicidad.Anunciante
GO

-- Esperado: PRINT duplicado, 0 filas nuevas
EXEC SP.uspAnunciante_Registrar 'Coca', 1
GO
SELECT * FROM publicidad.Anunciante
GO

-- Esperado: PRINT inexistente Pais (99), 0 filas nuevas
EXEC SP.uspAnunciante_Registrar 'Pepsi', 99
GO
SELECT * FROM publicidad.Anunciante
GO

-- Esperado: update 1 a Pepsi
EXEC SP.uspAnunciante_Update 1, 'Pepsi', 1
GO
SELECT * FROM publicidad.Anunciante
GO

-- Esperado: PRINT inexistente Id (99)
EXEC SP.uspAnunciante_Update 99, 'Pepsi', 1
GO
SELECT * FROM publicidad.Anunciante
GO

-- Esperado: borra Id 1
EXEC SP.uspAnunciante_Bajar 1
GO
SELECT * FROM publicidad.Anunciante
GO

-- Esperado: PRINT inexistente (99), 0 borradas
EXEC SP.uspAnunciante_Bajar 99
GO
SELECT * FROM publicidad.Anunciante
GO