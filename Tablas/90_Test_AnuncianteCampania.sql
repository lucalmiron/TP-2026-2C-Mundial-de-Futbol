--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 09/10/2026

--Objetivo: Testear Registro y Baja de AnuncianteCampania (sin Update, PK inmutable)

--Los objetos de negocio (TABLAS y SP) viven en MUNDIAL, el test se ejecuta contra ellos.
--Requiere Anunciante 1 y Campania 1 existentes.
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END
GO

-- Esperado: inserta (1, 1), 1 fila
EXEC SP.uspAnuncianteCampania_Registrar @idAnunciante = 1, @idCampania = 1
GO
SELECT * FROM publicidad.AnuncianteCampania
GO

-- Esperado: PRINT duplicado, 0 filas nuevas
EXEC SP.uspAnuncianteCampania_Registrar @idAnunciante = 1, @idCampania = 1
GO
SELECT * FROM publicidad.AnuncianteCampania
GO

-- Esperado: PRINT inexistente Anunciante (99), 0 filas nuevas
EXEC SP.uspAnuncianteCampania_Registrar @idAnunciante = 99, @idCampania = 1
GO
SELECT * FROM publicidad.AnuncianteCampania
GO

-- Esperado: PRINT inexistente Campania (99), 0 filas nuevas
EXEC SP.uspAnuncianteCampania_Registrar @idAnunciante = 1, @idCampania = 99
GO
SELECT * FROM publicidad.AnuncianteCampania
GO

-- Esperado: PRINT invalido Id (0), 0 filas nuevas
EXEC SP.uspAnuncianteCampania_Registrar @idAnunciante = 0, @idCampania = 1
GO
SELECT * FROM publicidad.AnuncianteCampania
GO

-- Esperado: borra (1, 1), SELECT vacio
EXEC SP.uspAnuncianteCampania_Bajar @idAnunciante = 1, @idCampania = 1
GO
SELECT * FROM publicidad.AnuncianteCampania
GO

-- Esperado: PRINT inexistente (1, 1), 0 borradas
EXEC SP.uspAnuncianteCampania_Bajar @idAnunciante = 1, @idCampania = 1
GO
SELECT * FROM publicidad.AnuncianteCampania
GO
