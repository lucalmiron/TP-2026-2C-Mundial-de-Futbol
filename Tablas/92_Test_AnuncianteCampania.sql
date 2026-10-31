--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Objetivo: Testear Registro y Baja de AnuncianteCampania (sin Update, PK inmutable)

--Los objetos de negocio (TABLAS y SP) viven en MUNDIAL, el test se ejecuta contra ellos.
--El test arma su propio juego de datos y lo borra al final, asi se puede ejecutar mas de una vez.
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END
GO

--/Datos de prueba

-- Esperado: se crea un idioma y un huso para insertar pais
IF NOT EXISTS (SELECT 1 FROM arbitros.Idioma WHERE Descripcion = 'Idioma Test')
	EXEC SP.uspIdioma_Registrar @descripcion = 'Idioma Test';
IF NOT EXISTS (SELECT 1 FROM sedes.HusoHorario WHERE Nombre = 'Huso Test')
	EXEC SP.uspHusoHorario_Registrar @nombre = 'Huso Test';

DECLARE @husoT INT = (SELECT IdHuso FROM sedes.HusoHorario WHERE Nombre = 'Huso Test');
DECLARE @idiomaT INT = (SELECT IdIdioma FROM arbitros.Idioma WHERE Descripcion = 'Idioma Test');

-- Esperado: se crea el pais.
IF NOT EXISTS (SELECT 1 FROM equipos.Pais WHERE NOMBRE = 'Pais Test 90')
	EXEC SP.uspPais_Registrar @nombre = 'Pais Test 90', @idioma = @idiomaT, @huso = @husoT, @ptIni = '17:00', @ptFin = '23:00', @pbi = 87;
GO

DECLARE @cPais INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test 90');

-- Esperado: se crea el anunciante.
IF NOT EXISTS (SELECT 1 FROM publicidad.Anunciante WHERE Nombre = 'Anun Test 90')
	EXEC SP.uspAnunciante_Registrar @nombre = 'Anun Test 90', @idPais = @cPais;
GO

-- Esperado: se crea la campania.
IF NOT EXISTS (SELECT 1 FROM publicidad.Campania WHERE Nombre = 'Campania 90')
	EXEC SP.uspCampania_Registrar @nombre = 'Campania 90', @descripcion = 'Campania de prueba del test 90';
GO

--/ALTA

DECLARE @cAnun INT = (SELECT MIN(IdAnunciante) FROM publicidad.Anunciante WHERE Nombre = 'Anun Test 90');
DECLARE @cCamp INT = (SELECT MIN(IdCampania) FROM publicidad.Campania WHERE Nombre = 'Campania 90');

-- Esperado: inserta (anunciante, campania), 1 fila
EXEC SP.uspAnuncianteCampania_Registrar @idAnunciante = @cAnun, @idCampania = @cCamp
GO
SELECT * FROM publicidad.AnuncianteCampania
GO

-- Esperado: duplicado, 0 filas nuevas
DECLARE @cAnun INT = (SELECT MIN(IdAnunciante) FROM publicidad.Anunciante WHERE Nombre = 'Anun Test 90');
DECLARE @cCamp INT = (SELECT MIN(IdCampania) FROM publicidad.Campania WHERE Nombre = 'Campania 90');
EXEC SP.uspAnuncianteCampania_Registrar @idAnunciante = @cAnun, @idCampania = @cCamp
GO
SELECT * FROM publicidad.AnuncianteCampania
GO

-- Esperado: anunciante inexistente (99), 0 filas nuevas
DECLARE @cCamp INT = (SELECT MIN(IdCampania) FROM publicidad.Campania WHERE Nombre = 'Campania 90');
EXEC SP.uspAnuncianteCampania_Registrar @idAnunciante = 99, @idCampania = @cCamp
GO
SELECT * FROM publicidad.AnuncianteCampania
GO

-- Esperado: campania inexistente (99), 0 filas nuevas
DECLARE @cAnun INT = (SELECT MIN(IdAnunciante) FROM publicidad.Anunciante WHERE Nombre = 'Anun Test 90');
EXEC SP.uspAnuncianteCampania_Registrar @idAnunciante = @cAnun, @idCampania = 99
GO
SELECT * FROM publicidad.AnuncianteCampania
GO

-- Esperado: id invalido (0), 0 filas nuevas
DECLARE @cCamp INT = (SELECT MIN(IdCampania) FROM publicidad.Campania WHERE Nombre = 'Campania 90');
EXEC SP.uspAnuncianteCampania_Registrar @idAnunciante = 0, @idCampania = @cCamp
GO
SELECT * FROM publicidad.AnuncianteCampania
GO

--/BAJA

-- Esperado: borra (anunciante, campania), SELECT sin esa fila
DECLARE @cAnun INT = (SELECT MIN(IdAnunciante) FROM publicidad.Anunciante WHERE Nombre = 'Anun Test 90');
DECLARE @cCamp INT = (SELECT MIN(IdCampania) FROM publicidad.Campania WHERE Nombre = 'Campania 90');
EXEC SP.uspAnuncianteCampania_Bajar @idAnunciante = @cAnun, @idCampania = @cCamp
GO
SELECT * FROM publicidad.AnuncianteCampania
GO

-- Esperado: inexistente, 0 borradas
DECLARE @cAnun INT = (SELECT MIN(IdAnunciante) FROM publicidad.Anunciante WHERE Nombre = 'Anun Test 90');
DECLARE @cCamp INT = (SELECT MIN(IdCampania) FROM publicidad.Campania WHERE Nombre = 'Campania 90');
EXEC SP.uspAnuncianteCampania_Bajar @idAnunciante = @cAnun, @idCampania = @cCamp
GO
SELECT * FROM publicidad.AnuncianteCampania
GO

--/Limpieza de lo que genera el test

DECLARE @cCampB INT = (SELECT MIN(IdCampania) FROM publicidad.Campania WHERE Nombre = 'Campania 90');
IF @cCampB IS NOT NULL
	EXEC SP.uspCampania_Bajar @id = @cCampB;

DECLARE @cAnunB INT = (SELECT MIN(IdAnunciante) FROM publicidad.Anunciante WHERE Nombre = 'Anun Test 90');
IF @cAnunB IS NOT NULL
	EXEC SP.uspAnunciante_Bajar @id = @cAnunB;

DECLARE @cPaisB INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test 90');
IF @cPaisB IS NOT NULL
	EXEC SP.uspPais_Bajar @idPais = @cPaisB;

DECLARE @cHusoB INT = (SELECT MIN(IdHuso) FROM sedes.HusoHorario WHERE Nombre = 'Huso Test');
IF @cHusoB IS NOT NULL
	EXEC SP.uspHusoHorario_Bajar @idHuso = @cHusoB;

DECLARE @cIdiomaB INT = (SELECT MIN(IdIdioma) FROM arbitros.Idioma WHERE Nombre = 'Idioma Test');
IF @cIdiomaB IS NOT NULL
	EXEC SP.uspIdioma_Bajar @id = @cIdiomaB;

-- Esperado: no queda nada del test.
SELECT * FROM publicidad.AnuncianteCampania;
GO
