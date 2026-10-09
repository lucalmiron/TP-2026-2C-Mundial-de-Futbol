--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 09/10/2026

--Objetivo: Testear Registro y Baja de PublicidadPais (sin Update, PK inmutable)

--Los objetos de negocio (TABLAS y SP) viven en MUNDIAL, el test se ejecuta contra ellos.
--Requiere Publicidad 1 y Pais 1 existentes.
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END
GO

-- Esperado: inserta (1, 1), 1 fila
EXEC SP.uspPublicidadPais_Registrar @idPublicidad = 1, @idPais = 1
GO
SELECT * FROM publicidad.PublicidadPais
GO

-- Esperado: PRINT duplicado, 0 filas nuevas
EXEC SP.uspPublicidadPais_Registrar @idPublicidad = 1, @idPais = 1
GO
SELECT * FROM publicidad.PublicidadPais
GO

-- Esperado: PRINT inexistente Publicidad (99), 0 filas nuevas
EXEC SP.uspPublicidadPais_Registrar @idPublicidad = 99, @idPais = 1
GO
SELECT * FROM publicidad.PublicidadPais
GO

-- Esperado: PRINT inexistente Pais (99), 0 filas nuevas
EXEC SP.uspPublicidadPais_Registrar @idPublicidad = 1, @idPais = 99
GO
SELECT * FROM publicidad.PublicidadPais
GO

-- Esperado: PRINT invalido Id (0), 0 filas nuevas
EXEC SP.uspPublicidadPais_Registrar @idPublicidad = 0, @idPais = 1
GO
SELECT * FROM publicidad.PublicidadPais
GO

-- Esperado: borra (1, 1), SELECT vacio
EXEC SP.uspPublicidadPais_Bajar @idPublicidad = 1, @idPais = 1
GO
SELECT * FROM publicidad.PublicidadPais
GO

-- Esperado: PRINT inexistente (1, 1), 0 borradas
EXEC SP.uspPublicidadPais_Bajar @idPublicidad = 1, @idPais = 1
GO
SELECT * FROM publicidad.PublicidadPais
GO
