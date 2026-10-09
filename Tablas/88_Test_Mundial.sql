--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 09/10/2026

--Objetivo: Testear Registro, Update y Baja de Mundial

--Los objetos de negocio (TABLAS y SP) viven en MUNDIAL, el test se ejecuta contra ellos.
--Requiere Pais 1 existente y que no haya filas en equipos.Seleccion ni partidos.Partido que referencien al mundial 1.
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END
GO

-- Esperado: inserta 1 fila (Pais 1, 2026-06-11 a 2026-07-19)
EXEC SP.uspMundial_Registrar @idPais = 1, @fechaInicio = '2026-06-11', @fechaFin = '2026-07-19', @tamMin = 23, @tamMax = 26, @ventanas = 5, @cantidad = 5, @suspMax = 2, @suspTiempo = 1
GO
SELECT * FROM sedes.Mundial
GO

-- Esperado: PRINT inexistente Pais (99), 0 filas nuevas
EXEC SP.uspMundial_Registrar @idPais = 99, @fechaInicio = '2026-06-11', @fechaFin = '2026-07-19', @tamMin = 23, @tamMax = 26, @ventanas = 5, @cantidad = 5, @suspMax = 2, @suspTiempo = 1
GO
SELECT * FROM sedes.Mundial
GO

-- Esperado: PRINT fin anterior a inicio, 0 filas nuevas
EXEC SP.uspMundial_Registrar @idPais = 1, @fechaInicio = '2026-07-19', @fechaFin = '2026-06-11', @tamMin = 23, @tamMax = 26, @ventanas = 5, @cantidad = 5, @suspMax = 2, @suspTiempo = 1
GO
SELECT * FROM sedes.Mundial
GO

-- Esperado: PRINT minimo mayor que maximo, 0 filas nuevas
EXEC SP.uspMundial_Registrar @idPais = 1, @fechaInicio = '2026-06-11', @fechaFin = '2026-07-19', @tamMin = 26, @tamMax = 23, @ventanas = 5, @cantidad = 5, @suspMax = 2, @suspTiempo = 1
GO
SELECT * FROM sedes.Mundial
GO

-- Esperado: PRINT ventanas invalido (0), 0 filas nuevas
EXEC SP.uspMundial_Registrar @idPais = 1, @fechaInicio = '2026-06-11', @fechaFin = '2026-07-19', @tamMin = 23, @tamMax = 26, @ventanas = 0, @cantidad = 5, @suspMax = 2, @suspTiempo = 1
GO
SELECT * FROM sedes.Mundial
GO

-- Esperado: update parcial de Id 1 (tiempo de suspension a 2), SELECT muestra 2
EXEC SP.uspMundial_Update @id = 1, @suspTiempo = 2
GO
SELECT * FROM sedes.Mundial
GO

-- Esperado: PRINT fin anterior a inicio en update, 0 filas modificadas
EXEC SP.uspMundial_Update @id = 1, @fechaFin = '2026-01-01'
GO
SELECT * FROM sedes.Mundial
GO

-- Esperado: PRINT invalido Id (0)
EXEC SP.uspMundial_Update @id = 0, @suspTiempo = 2
GO
SELECT * FROM sedes.Mundial
GO

-- Esperado: PRINT inexistente Id (99)
EXEC SP.uspMundial_Update @id = 99, @suspTiempo = 2
GO
SELECT * FROM sedes.Mundial
GO

-- Esperado: borra Id 1, SELECT vacio
EXEC SP.uspMundial_Bajar 1
GO
SELECT * FROM sedes.Mundial
GO

-- Esperado: PRINT inexistente Id (99), 0 borradas
EXEC SP.uspMundial_Bajar 99
GO
SELECT * FROM sedes.Mundial
GO
