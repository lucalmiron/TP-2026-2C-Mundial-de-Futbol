--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 21/10/2026

--Objetivo: Testear Registro y Baja de PublicidadPais (sin Update, PK inmutable)

--Los objetos de negocio (TABLAS y SP) viven en MUNDIAL, el test se ejecuta contra ellos.
--El test arma su propio juego de datos y lo borra al final, asi se puede ejecutar mas de una vez.
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END
GO

--/Datos de prueba

-- Esperado: se crea el idioma y la campania.
IF NOT EXISTS (SELECT 1 FROM arbitros.Idioma WHERE Descripcion = 'Idioma T89')
	EXEC SP.uspIdioma_Registrar @descripcion = 'Idioma T89';
GO
IF NOT EXISTS (SELECT 1 FROM publicidad.Campania WHERE Nombre = 'Campania T89')
	EXEC SP.uspCampania_Registrar @nombre = 'Campania T89', @descripcion = 'Campania de prueba del test 89';
GO

DECLARE @pCamp INT = (SELECT MIN(IdCampania) FROM publicidad.Campania WHERE Nombre = 'Campania T89');
DECLARE @pIdio INT = (SELECT MIN(IdIdioma) FROM arbitros.Idioma WHERE Descripcion = 'Idioma T89');

-- Esperado: se crea la publicidad.
IF NOT EXISTS (SELECT 1 FROM publicidad.Publicidad WHERE Nombre = 'Pub Test 89')
	EXEC SP.uspPublicidad_Registrar @nombre = 'Pub Test 89', @idCampania = @pCamp, @idIdioma = @pIdio;
GO

-- Esperado: se crea el pais.
IF NOT EXISTS (SELECT 1 FROM equipos.Pais WHERE NOMBRE = 'Pais Test 89')
	EXEC SP.uspPais_Registrar @nombre = 'Pais Test 89', @pbi = 86;
GO

--/ALTA

DECLARE @pPub INT = (SELECT MIN(IdPublicidad) FROM publicidad.Publicidad WHERE Nombre = 'Pub Test 89');
DECLARE @pPais INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test 89');

-- Esperado: inserta (publicidad, pais), 1 fila
EXEC SP.uspPublicidadPais_Registrar @idPublicidad = @pPub, @idPais = @pPais
GO
SELECT * FROM publicidad.PublicidadPais
GO

-- Esperado: duplicado, 0 filas nuevas
DECLARE @pPub INT = (SELECT MIN(IdPublicidad) FROM publicidad.Publicidad WHERE Nombre = 'Pub Test 89');
DECLARE @pPais INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test 89');
EXEC SP.uspPublicidadPais_Registrar @idPublicidad = @pPub, @idPais = @pPais
GO
SELECT * FROM publicidad.PublicidadPais
GO

-- Esperado: publicidad inexistente (99), 0 filas nuevas
DECLARE @pPais INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test 89');
EXEC SP.uspPublicidadPais_Registrar @idPublicidad = 99, @idPais = @pPais
GO
SELECT * FROM publicidad.PublicidadPais
GO

-- Esperado: pais inexistente (99), 0 filas nuevas
DECLARE @pPub INT = (SELECT MIN(IdPublicidad) FROM publicidad.Publicidad WHERE Nombre = 'Pub Test 89');
EXEC SP.uspPublicidadPais_Registrar @idPublicidad = @pPub, @idPais = 99
GO
SELECT * FROM publicidad.PublicidadPais
GO

-- Esperado: id invalido (0), 0 filas nuevas
DECLARE @pPais INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test 89');
EXEC SP.uspPublicidadPais_Registrar @idPublicidad = 0, @idPais = @pPais
GO
SELECT * FROM publicidad.PublicidadPais
GO

--/BAJA

-- Esperado: borra (publicidad, pais), SELECT sin esa fila
DECLARE @pPub INT = (SELECT MIN(IdPublicidad) FROM publicidad.Publicidad WHERE Nombre = 'Pub Test 89');
DECLARE @pPais INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test 89');
EXEC SP.uspPublicidadPais_Bajar @idPublicidad = @pPub, @idPais = @pPais
GO
SELECT * FROM publicidad.PublicidadPais
GO

-- Esperado: inexistente, 0 borradas
DECLARE @pPub INT = (SELECT MIN(IdPublicidad) FROM publicidad.Publicidad WHERE Nombre = 'Pub Test 89');
DECLARE @pPais INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test 89');
EXEC SP.uspPublicidadPais_Bajar @idPublicidad = @pPub, @idPais = @pPais
GO
SELECT * FROM publicidad.PublicidadPais
GO

--/Limpieza de lo que genera el test

DECLARE @pPubB INT = (SELECT MIN(IdPublicidad) FROM publicidad.Publicidad WHERE Nombre = 'Pub Test 89');
IF @pPubB IS NOT NULL
	EXEC SP.uspPublicidad_Bajar @id = @pPubB;

DECLARE @pCampB INT = (SELECT MIN(IdCampania) FROM publicidad.Campania WHERE Nombre = 'Campania T89');
IF @pCampB IS NOT NULL
	EXEC SP.uspCampania_Bajar @id = @pCampB;

DECLARE @pIdioB INT = (SELECT MIN(IdIdioma) FROM arbitros.Idioma WHERE Descripcion = 'Idioma T89');
IF @pIdioB IS NOT NULL
	EXEC SP.uspIdioma_Bajar @id = @pIdioB;

DECLARE @pPaisB INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test 89');
IF @pPaisB IS NOT NULL
	EXEC SP.uspPais_Bajar @idPais = @pPaisB;

-- Esperado: no queda nada del test.
SELECT * FROM publicidad.PublicidadPais;
GO
