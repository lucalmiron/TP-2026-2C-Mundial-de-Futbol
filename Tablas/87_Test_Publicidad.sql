-- Universidad Nacional de La Matanza
-- Bases de datos aplicada
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 26/10/26
-- Objetivo: Testear Registro, Update y Baja de Publicidad

--El test arma su propio juego de datos y lo borra al final, asi se puede ejecutar mas de una vez.
IF DB_NAME() NOT LIKE 'MUNDIAL[_]Final[_]Test%'
    THROW 51000, 'Seleccionar la base aislada de pruebas.', 1;
GO

--/Datos de prueba

-- Esperado: se crea el idioma y la campania.
IF NOT EXISTS (SELECT 1 FROM arbitros.Idioma WHERE Descripcion = 'Idioma T82')
	EXEC SP.uspIdioma_Registrar @descripcion = 'Idioma T82';
GO
IF NOT EXISTS (SELECT 1 FROM publicidad.Campania WHERE Nombre = 'Campania T82')
	EXEC SP.uspCampania_Registrar @nombre = 'Campania T82', @descripcion = 'Campania de prueba del test 82';
GO

--/ALTA

DECLARE @bCamp INT = (SELECT MIN(IdCampania) FROM publicidad.Campania WHERE Nombre = 'Campania T82');
DECLARE @bIdio INT = (SELECT MIN(IdIdioma) FROM arbitros.Idioma WHERE Descripcion = 'Idioma T82');

-- Esperado: inserta 1 fila
IF NOT EXISTS (SELECT 1 FROM publicidad.Publicidad WHERE Nombre = 'Spot Test 82')
	EXEC SP.uspPublicidad_Registrar 'Spot Test 82', @bCamp, @bIdio
GO
SELECT * FROM publicidad.Publicidad
GO

-- Esperado: nombre nulo, 0 filas nuevas
BEGIN TRY
    EXEC SP.uspPublicidad_Registrar NULL, 1, 1;
    THROW 51999, 'Se esperaba que el procedimiento rechazara los datos.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() NOT IN (50000, 51000) THROW;
END CATCH;
GO
SELECT * FROM publicidad.Publicidad
GO

-- Esperado: duplicada, 0 filas nuevas
BEGIN TRY
    EXEC SP.uspPublicidad_Registrar 'Spot Test 82', 1, 1;
    THROW 51999, 'Se esperaba que el procedimiento rechazara los datos.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() NOT IN (50000, 51000) THROW;
END CATCH;
GO
SELECT * FROM publicidad.Publicidad
GO

-- Esperado: campania inexistente (99), 0 filas nuevas
BEGIN TRY
    EXEC SP.uspPublicidad_Registrar 'Spot Test 82b', 99, 1;
    THROW 51999, 'Se esperaba que el procedimiento rechazara los datos.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() NOT IN (50000, 51000) THROW;
END CATCH;
GO
SELECT * FROM publicidad.Publicidad
GO

-- Esperado: idioma inexistente (99), 0 filas nuevas
BEGIN TRY
    EXEC SP.uspPublicidad_Registrar 'Spot Test 82b', 1, 99;
    THROW 51999, 'Se esperaba que el procedimiento rechazara los datos.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() NOT IN (50000, 51000) THROW;
END CATCH;
GO
SELECT * FROM publicidad.Publicidad
GO

--/UPDATE

DECLARE @bPub INT = (SELECT MIN(IdPublicidad) FROM publicidad.Publicidad WHERE Nombre = 'Spot Test 82');

-- Esperado: cambia el nombre, SELECT muestra el nuevo
EXEC SP.uspPublicidad_Update @bPub, 'Spot Test 82b', 1, 1
GO
SELECT * FROM publicidad.Publicidad
GO

-- Esperado: id inexistente (99)
BEGIN TRY
    EXEC SP.uspPublicidad_Update 99, 'Spot Test 82b', 1, 1;
    THROW 51999, 'Se esperaba que el procedimiento rechazara los datos.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() NOT IN (50000, 51000) THROW;
END CATCH;
GO
SELECT * FROM publicidad.Publicidad
GO

--/BAJA

-- Esperado: borra la publicidad
DECLARE @bPub INT = (SELECT MIN(IdPublicidad) FROM publicidad.Publicidad WHERE Nombre = 'Spot Test 82b');
EXEC SP.uspPublicidad_Bajar @bPub
GO
SELECT * FROM publicidad.Publicidad
GO

-- Esperado: id inexistente (99), 0 borradas
BEGIN TRY
    EXEC SP.uspPublicidad_Bajar 99;
    THROW 51999, 'Se esperaba que el procedimiento rechazara los datos.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() NOT IN (50000, 51000) THROW;
END CATCH;
GO
SELECT * FROM publicidad.Publicidad
GO

--/Limpieza de lo que genera el test

DECLARE @bCampB INT = (SELECT MIN(IdCampania) FROM publicidad.Campania WHERE Nombre = 'Campania T82');
IF @bCampB IS NOT NULL
	EXEC SP.uspCampania_Bajar @id = @bCampB;

DECLARE @bIdioB INT = (SELECT MIN(IdIdioma) FROM arbitros.Idioma WHERE Descripcion = 'Idioma T82');
IF @bIdioB IS NOT NULL
	EXEC SP.uspIdioma_Bajar @id = @bIdioB;

-- Esperado: no queda nada del test.
SELECT * FROM publicidad.Publicidad;
GO
