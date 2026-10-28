-- Universidad Nacional de La Matanza
-- Bases de datos aplicada
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 26/10/26
-- Objetivo: Testear Registro, Update y Baja de Anunciante

--Los objetos de negocio viven en MUNDIAL, el test se ejecuta contra ellos.
--El test arma su propio juego de datos y lo borra al final, asi se puede ejecutar mas de una vez.
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END
GO

--/Datos de prueba

--1 idioma y 1 huso horario para poder insertar paises
IF NOT EXISTS (SELECT 1 FROM arbitros.Idioma WHERE Descripcion = 'Idioma_Test1')
	EXEC SP.uspIdioma_Registrar @descripcion = 'Idioma_Test1';
GO
IF NOT EXISTS (SELECT 1 FROM sedes.HusoHorario WHERE Nombre = 'Huso_Test1')
	EXEC SP.uspHusoHorario_Registrar @nombre = 'Huso_Test1';
GO

-- Esperado: se crean los dos paises.
DECLARE @idIdioma1 INT = (SELECT IdIdioma FROM arbitros.Idioma WHERE Descripcion = 'Idioma_Test1');
DECLARE @idHuso1 INT = (SELECT IdHuso FROM sedes.HusoHorario WHERE Nombre = 'Huso_Test1');

IF NOT EXISTS (SELECT 1 FROM equipos.Pais WHERE NOMBRE = 'Pais Test AD1')
	EXEC SP.uspPais_Registrar @nombre = 'Pais Test AD1', @idioma = @idIdioma1, @huso = @idHuso1, @ptIni = '17:00', @ptFin = '23:00', @pbi = 84;
IF NOT EXISTS (SELECT 1 FROM equipos.Pais WHERE NOMBRE = 'Pais Test AD2')
	EXEC SP.uspPais_Registrar @nombre = 'Pais Test AD2', @idioma = @idIdioma1, @huso = @idHuso1, @ptIni = '17:00', @ptFin = '23:00', @pbi = 85;
GO

--/ALTA

DECLARE @aPais1 INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test AD1');

-- Esperado: inserta 1 fila
IF NOT EXISTS (SELECT 1 FROM publicidad.Anunciante WHERE Nombre = 'Anun Test A')
	EXEC SP.uspAnunciante_Registrar 'Anun Test A', @aPais1;
GO
SELECT * FROM publicidad.Anunciante;
GO

-- Esperado: nombre nulo, 0 filas nuevas
EXEC SP.uspAnunciante_Registrar NULL, 1
GO
SELECT * FROM publicidad.Anunciante
GO

-- Esperado: duplicado, 0 filas nuevas
EXEC SP.uspAnunciante_Registrar 'Anun Test A', 1
GO
SELECT * FROM publicidad.Anunciante
GO

-- Esperado: pais inexistente (99), 0 filas nuevas
EXEC SP.uspAnunciante_Registrar 'Anun Test B', 99
GO
SELECT * FROM publicidad.Anunciante
GO

--/UPDATE

DECLARE @aId INT = (SELECT MIN(IdAnunciante) FROM publicidad.Anunciante WHERE Nombre = 'Anun Test A');
DECLARE @aPais2 INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test AD2');

-- Esperado: cambia el nombre y el pais
EXEC SP.uspAnunciante_Update @aId, 'Anun Test B', @aPais2
GO
SELECT * FROM publicidad.Anunciante
GO

-- Esperado: id inexistente (99)
EXEC SP.uspAnunciante_Update 99, 'Anun Test B', 1
GO
SELECT * FROM publicidad.Anunciante
GO

--/BAJA

DECLARE @aIdB INT = (SELECT MIN(IdAnunciante) FROM publicidad.Anunciante WHERE Nombre = 'Anun Test B');

-- Esperado: borra el anunciante
EXEC SP.uspAnunciante_Bajar @aIdB
GO
SELECT * FROM publicidad.Anunciante
GO

-- Esperado: id inexistente (99), 0 borradas
EXEC SP.uspAnunciante_Bajar 99
GO
SELECT * FROM publicidad.Anunciante
GO

--/Limpieza de lo que genera el test

--/Limpieza de lo que genera el test

DECLARE @vHuso INT, @vIdioma INT, @aP INT, @aI INT = 0;

WHILE @aI < 5
BEGIN
	SET @aP = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE IN ('Pais Test AD1','Pais Test AD2'));
	IF @aP IS NULL BREAK;
	EXEC SP.uspPais_Bajar @idPais = @aP;
	SET @aI = @aI + 1;
END

SET @aI = 0;
WHILE @aI < 10
BEGIN
	SET @vHuso = (SELECT MIN(IdHuso) FROM sedes.HusoHorario WHERE Nombre LIKE 'Huso_Test%');
	IF @vHuso IS NULL BREAK;
	EXEC SP.uspHusoHorario_Bajar @idHuso = @vHuso;
	SET @aI = @aI + 1;
END

SET @aI = 0;
WHILE @aI < 10
BEGIN
	SET @vIdioma = (SELECT MIN(IdIdioma) FROM arbitros.Idioma WHERE Descripcion LIKE 'Idioma_Test%');
	IF @vIdioma IS NULL BREAK;
	EXEC SP.uspIdioma_Bajar @id = @vIdioma;
	SET @aI = @aI + 1;
END

-- Esperado: no queda nada del test.
SELECT * FROM publicidad.Anunciante;
GO
