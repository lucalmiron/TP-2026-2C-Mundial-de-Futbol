--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 09/10/2026

--Objetivo: Testear Registro, Update y Baja de Grupo

--Los objetos de negocio (TABLAS y SP) viven en MUNDIAL, el test se ejecuta contra ellos.
--Requiere que no haya filas en equipos.Seleccion que referencien al grupo 1 ni grupos 'A' o 'C' previos.
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END
GO

-- Esperado: inserta A, 1 fila
EXEC SP.uspGrupo_Registrar 'A'
GO
SELECT * FROM equipos.Grupo
GO

-- Esperado: PRINT nulo, 0 filas nuevas
EXEC SP.uspGrupo_Registrar NULL
GO
SELECT * FROM equipos.Grupo
GO

-- Esperado: PRINT duplicado, 0 filas nuevas
EXEC SP.uspGrupo_Registrar 'A'
GO
SELECT * FROM equipos.Grupo
GO

-- Esperado: inserta C, 2 filas
EXEC SP.uspGrupo_Registrar 'C'
GO
SELECT * FROM equipos.Grupo
GO

-- Esperado: update 1 a B, SELECT muestra B
EXEC SP.uspGrupo_Update 1, 'B'
GO
SELECT * FROM equipos.Grupo
GO

-- Esperado: PRINT duplicado (C ya existe en Id 2), 0 filas modificadas
EXEC SP.uspGrupo_Update 1, 'C'
GO
SELECT * FROM equipos.Grupo
GO

-- Esperado: PRINT invalido Id (0)
EXEC SP.uspGrupo_Update 0, 'B'
GO
SELECT * FROM equipos.Grupo
GO

-- Esperado: PRINT inexistente Id (99)
EXEC SP.uspGrupo_Update 99, 'B'
GO
SELECT * FROM equipos.Grupo
GO

-- Esperado: borra Id 2, SELECT sin esa fila
EXEC SP.uspGrupo_Bajar 2
GO
SELECT * FROM equipos.Grupo
GO

-- Esperado: borra Id 1, SELECT vacio
EXEC SP.uspGrupo_Bajar 1
GO
SELECT * FROM equipos.Grupo
GO

-- Esperado: PRINT inexistente Id (99), 0 borradas
EXEC SP.uspGrupo_Bajar 99
GO
SELECT * FROM equipos.Grupo
GO
