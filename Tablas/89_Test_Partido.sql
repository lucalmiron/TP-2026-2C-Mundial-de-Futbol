-- Universidad Nacional de La Matanza
-- Bases de datos aplicada
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 26/10/26
-- Objetivo: Testear Registro, Update y Baja de partido

--Los objetos de negocio (TABLAS y SP) viven en MUNDIAL, el test se ejecuta contra ellos.
--El test arma su propio juego de datos y lo borra al final, asi se puede ejecutar mas de una vez.
--uspPartido_* lanza excepciones (THROW), por eso los casos esperados a fallar van envueltos
--en TRY/CATCH: el CATCH captura la excepcion y deja el mensaje en el log del test.
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END
GO

--/Datos de prueba

-- Esperado: se crea el huso horario
IF NOT EXISTS (SELECT 1 FROM sedes.HusoHorario WHERE Nombre = 'UTC-3 (73)')
	EXEC SP.uspHusoHorario_Registrar @nombre = 'UTC-3 (73)';
-- Esperado: se crea 1 idioma para insertar los paises
IF NOT EXISTS (SELECT 1 FROM arbitros.Idioma WHERE Descripcion = 'Idioma Test')
	EXEC SP.uspIdioma_Registrar @descripcion = 'Idioma Test';
GO

DECLARE @husoT INT = (SELECT IdHuso FROM sedes.HusoHorario WHERE Nombre = 'UTC-3 (73)');
DECLARE @idiomaT INT = (SELECT IdIdioma FROM arbitros.Idioma WHERE Descripcion = 'Idioma Test')

-- Esperado: se crea el pais (equipo 1 y pais organizador del mundial).
IF NOT EXISTS (SELECT 1 FROM equipos.Pais WHERE NOMBRE = 'Pais Test 73')
	EXEC SP.uspPais_Registrar @nombre = 'Pais Test 73', @idioma = @idiomaT, @huso = @husoT, @ptIni = '17:00', @ptFin = '23:00', @pbi = 89;

-- Esperado: se crea un segundo pais. Cada seleccion es de un pais distinto,
-- si no, la clave (pais, mundial) quedaria duplicada y la segunda no se crearia.
IF NOT EXISTS (SELECT 1 FROM equipos.Pais WHERE NOMBRE = 'Pais Test 73b')
	EXEC SP.uspPais_Registrar @nombre = 'Pais Test 73b', @idioma = @idiomaT, @huso = @husoT, @ptIni = '17:00', @ptFin = '23:00', @pbi = 90;
GO

DECLARE @tPais INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test 73');

-- Esperado: se crea el mundial (minimo de jugadores 0 para poder limpiar).
IF NOT EXISTS (SELECT 1 FROM sedes.Mundial WHERE IdPais = @tPais)
	EXEC SP.uspMundial_Registrar @idPais = @tPais, @fechaInicio = '2026-06-01', @fechaFin = '2026-07-30',
		@tamMin = 0, @tamMax = 23, @ventanas = 3, @cantidad = 5, @suspMax = 2, @suspTiempo = 1;
GO

-- Esperado: se crea el grupo.
IF NOT EXISTS (SELECT 1 FROM equipos.Grupo WHERE NOMBRE = 'Grupo 73')
	EXEC SP.uspGrupo_Registrar @nombre = 'Grupo 73';
GO

DECLARE @tPais2 INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test 73');
DECLARE @tMund  INT = (SELECT MIN(IdMundial) FROM sedes.Mundial WHERE IdPais = @tPais2);
DECLARE @tGrup  INT = (SELECT MIN(IdGrupo) FROM equipos.Grupo WHERE NOMBRE = 'Grupo 73');

-- Esperado: se crean las dos selecciones que juegan.
IF NOT EXISTS (SELECT 1 FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF 731')
	EXEC SP.uspSeleccion_Registrar @idPais = @tPais2, @idMundial = @tMund, @idGrupo = @tGrup, @confederacion = 'CONF 731';
GO

DECLARE @tPais3 INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test 73b');
DECLARE @tMund2 INT = (SELECT MIN(IdMundial) FROM sedes.Mundial WHERE IdPais = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test 73'));
DECLARE @tGrup2 INT = (SELECT MIN(IdGrupo) FROM equipos.Grupo WHERE NOMBRE = 'Grupo 73');

IF NOT EXISTS (SELECT 1 FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF 732')
	EXEC SP.uspSeleccion_Registrar @idPais = @tPais3, @idMundial = @tMund2, @idGrupo = @tGrup2, @confederacion = 'CONF 732';
GO

DECLARE @tPais4 INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test 73');

-- Esperado: se crea el huso horario y la sede.


DECLARE @tHuso   INT = (SELECT MIN(IdHuso) FROM sedes.HusoHorario WHERE Nombre = 'UTC-3 (73)');
DECLARE @tPais5  INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test 73');

IF NOT EXISTS (SELECT 1 FROM sedes.Sede WHERE Nombre = 'Sede Test 73')
	EXEC SP.uspSede_Registrar @nombre = 'Sede Test 73', @ciudad = 'Ciudad Test 73', @capacidad = 50000, @pais = @tPais5, @huso = @tHuso;
GO

-- Esperado: se crea la fase.
IF NOT EXISTS (SELECT 1 FROM partidos.Fase WHERE Descripcion = 'Grupos')
	EXEC SP.uspFase_Registrar @Descripcion = 'Grupos';
GO

--/ALTA

DECLARE @pFase   INT = (SELECT MIN(IdFase) FROM partidos.Fase WHERE Descripcion = 'Grupos');
DECLARE @pSede   INT = (SELECT MIN(IdSede) FROM sedes.Sede WHERE Nombre = 'Sede Test 73');
DECLARE @pMund   INT = (SELECT MIN(IdMundial) FROM sedes.Mundial WHERE IdPais = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test 73'));
DECLARE @pEq1    INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF 731');
DECLARE @pEq2    INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF 732');

-- Esperado: inserta 1 fila con marcador 0-0 (el marcador lo mueven los goles, no el partido)
IF NOT EXISTS (SELECT 1 FROM partidos.Partido WHERE IdFase = @pFase AND Eq1 = @pEq1 AND Eq2 = @pEq2)
	EXEC SP.uspPartido_Registrar @IdFase=@pFase, @IdSede=@pSede, @IdMundial=@pMund, @Eq1=@pEq1, @Eq2=@pEq2,
		@Fecha='2026-06-11', @HoraUTC='16:00', @HoraLocal='13:00', @Asistencia=40000;
IF NOT EXISTS(SELECT 1 FROM partidos.Partido WHERE IdFase=@pFase AND Eq1=@pEq1 AND Eq2=@pEq2 AND Asistencia=40000)
 THROW 51999,'No se registro el partido.',1;
GO
SELECT IdPartido, IdFase, IdSede, IdMundial, Eq1, Eq2, GolesEq1, GolesEq2, Asistencia FROM partidos.Partido
GO

DECLARE @pFase2  INT = (SELECT MIN(IdFase) FROM partidos.Fase WHERE Descripcion = 'Grupos');
DECLARE @pSede2  INT = (SELECT MIN(IdSede) FROM sedes.Sede WHERE Nombre = 'Sede Test 73');
DECLARE @pMund2  INT = (SELECT MIN(IdMundial) FROM sedes.Mundial WHERE IdPais = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test 73'));
DECLARE @pEq1b   INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF 731');

-- Esperado: rival propio (Eq1 = Eq2), 0 filas nuevas
BEGIN TRY
	EXEC SP.uspPartido_Registrar @IdFase=@pFase2, @IdSede=@pSede2, @IdMundial=@pMund2, @Eq1=@pEq1b, @Eq2=@pEq1b,
		@Fecha='2026-06-11', @HoraUTC='16:00', @HoraLocal='13:00';
 THROW 51999,'Se esperaba rechazo.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) OR ERROR_MESSAGE() NOT LIKE '%propio rival%' THROW;
 PRINT 'Rechazo comprobado: '+ERROR_MESSAGE();
END CATCH
GO
SELECT IdPartido, IdFase, IdSede, IdMundial, Eq1, Eq2, GolesEq1, GolesEq2, Asistencia FROM partidos.Partido
GO

DECLARE @pFase3  INT = (SELECT MIN(IdFase) FROM partidos.Fase WHERE Descripcion = 'Grupos');
DECLARE @pSede3  INT = (SELECT MIN(IdSede) FROM sedes.Sede WHERE Nombre = 'Sede Test 73');
DECLARE @pEq1c   INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF 731');
DECLARE @pEq2c   INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF 732');

-- Esperado: mundial inexistente (99), 0 filas nuevas
BEGIN TRY
	EXEC SP.uspPartido_Registrar @IdFase=@pFase3, @IdSede=@pSede3, @IdMundial=99, @Eq1=@pEq1c, @Eq2=@pEq2c,
		@Fecha='2026-06-11', @HoraUTC='16:00', @HoraLocal='13:00';
 THROW 51999,'Se esperaba rechazo.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) OR ERROR_MESSAGE() NOT LIKE '%Mundial%' THROW;
 PRINT 'Rechazo comprobado: '+ERROR_MESSAGE();
END CATCH
GO
SELECT IdPartido, IdFase, IdSede, IdMundial, Eq1, Eq2, GolesEq1, GolesEq2, Asistencia FROM partidos.Partido
GO

DECLARE @pFase4  INT = (SELECT MIN(IdFase) FROM partidos.Fase WHERE Descripcion = 'Grupos');
DECLARE @pSede4  INT = (SELECT MIN(IdSede) FROM sedes.Sede WHERE Nombre = 'Sede Test 73');
DECLARE @pMund4  INT = (SELECT MIN(IdMundial) FROM sedes.Mundial WHERE IdPais = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test 73'));
DECLARE @pEq1d   INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF 731');

-- Esperado: Eq2 inexistente (99), 0 filas nuevas
BEGIN TRY
	EXEC SP.uspPartido_Registrar @IdFase=@pFase4, @IdSede=@pSede4, @IdMundial=@pMund4, @Eq1=@pEq1d, @Eq2=99,
		@Fecha='2026-06-11', @HoraUTC='16:00', @HoraLocal='13:00';
 THROW 51999,'Se esperaba rechazo.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) OR ERROR_MESSAGE() NOT LIKE '%Eq2%' THROW;
 PRINT 'Rechazo comprobado: '+ERROR_MESSAGE();
END CATCH
GO
SELECT IdPartido, IdFase, IdSede, IdMundial, Eq1, Eq2, GolesEq1, GolesEq2, Asistencia FROM partidos.Partido
GO

DECLARE @pSede5  INT = (SELECT MIN(IdSede) FROM sedes.Sede WHERE Nombre = 'Sede Test 73');
DECLARE @pMund5  INT = (SELECT MIN(IdMundial) FROM sedes.Mundial WHERE IdPais = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test 73'));
DECLARE @pEq1e   INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF 731');
DECLARE @pEq2e   INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF 732');

-- Esperado: fase inexistente (99), 0 filas nuevas
BEGIN TRY
	EXEC SP.uspPartido_Registrar @IdFase=99, @IdSede=@pSede5, @IdMundial=@pMund5, @Eq1=@pEq1e, @Eq2=@pEq2e,
		@Fecha='2026-06-11', @HoraUTC='16:00', @HoraLocal='13:00';
 THROW 51999,'Se esperaba rechazo.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) OR ERROR_MESSAGE() NOT LIKE '%Fase%' THROW;
 PRINT 'Rechazo comprobado: '+ERROR_MESSAGE();
END CATCH
GO
SELECT IdPartido, IdFase, IdSede, IdMundial, Eq1, Eq2, GolesEq1, GolesEq2, Asistencia FROM partidos.Partido
GO

DECLARE @pFase6  INT = (SELECT MIN(IdFase) FROM partidos.Fase WHERE Descripcion = 'Grupos');
DECLARE @pSede6  INT = (SELECT MIN(IdSede) FROM sedes.Sede WHERE Nombre = 'Sede Test 73');
DECLARE @pMund6  INT = (SELECT MIN(IdMundial) FROM sedes.Mundial WHERE IdPais = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test 73'));
DECLARE @pEq1f   INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF 731');
DECLARE @pEq2f   INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF 732');

-- Esperado: duplicado (repite el primero), 0 filas nuevas
BEGIN TRY
	EXEC SP.uspPartido_Registrar @IdFase=@pFase6, @IdSede=@pSede6, @IdMundial=@pMund6, @Eq1=@pEq1f, @Eq2=@pEq2f,
		@Fecha='2026-06-11', @HoraUTC='16:00', @HoraLocal='13:00';
 THROW 51999,'Se esperaba rechazo.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) OR ERROR_MESSAGE() NOT LIKE '%duplicado%' THROW;
 PRINT 'Rechazo comprobado: '+ERROR_MESSAGE();
END CATCH
GO
SELECT IdPartido, IdFase, IdSede, IdMundial, Eq1, Eq2, GolesEq1, GolesEq2, Asistencia FROM partidos.Partido
GO

--/UPDATE

DECLARE @pPart INT = (SELECT MIN(IdPartido) FROM partidos.Partido WHERE IdSede=(SELECT IdSede FROM sedes.Sede WHERE Nombre='Sede Test 73'));

-- Esperado: update de asistencia, SELECT muestra 45000
EXEC SP.uspPartido_Update @Id=@pPart, @Asistencia=45000;
IF NOT EXISTS(SELECT 1 FROM partidos.Partido WHERE IdPartido=@pPart AND Asistencia=45000) THROW 51999,'No se actualizo la asistencia.',1;
GO
SELECT IdPartido, IdFase, IdSede, IdMundial, Eq1, Eq2, GolesEq1, GolesEq2, Asistencia FROM partidos.Partido
GO

DECLARE @pPart2 INT = (SELECT MIN(IdPartido) FROM partidos.Partido WHERE IdSede=(SELECT IdSede FROM sedes.Sede WHERE Nombre='Sede Test 73'));

-- Esperado: el marcador no se cambia a mano, 0 filas modificadas
BEGIN TRY
	EXEC SP.uspPartido_Update @Id=@pPart2, @GolesEq1=3;
 THROW 51999,'Se esperaba rechazo.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) OR ERROR_MESSAGE() NOT LIKE '%marcador%' THROW;
 PRINT 'Rechazo comprobado: '+ERROR_MESSAGE();
END CATCH
GO
SELECT IdPartido, IdFase, IdSede, IdMundial, Eq1, Eq2, GolesEq1, GolesEq2, Asistencia FROM partidos.Partido
GO

DECLARE @pPart3 INT = (SELECT MIN(IdPartido) FROM partidos.Partido WHERE IdSede=(SELECT IdSede FROM sedes.Sede WHERE Nombre='Sede Test 73'));

-- Esperado: mundial inexistente (99) en update, 0 filas modificadas
BEGIN TRY
	EXEC SP.uspPartido_Update @Id=@pPart3, @IdMundial=99;
 THROW 51999,'Se esperaba rechazo.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) OR ERROR_MESSAGE() NOT LIKE '%Mundial%' THROW;
 PRINT 'Rechazo comprobado: '+ERROR_MESSAGE();
END CATCH
GO
SELECT IdPartido, IdFase, IdSede, IdMundial, Eq1, Eq2, GolesEq1, GolesEq2, Asistencia FROM partidos.Partido
GO

-- Esperado: id invalido (0)
BEGIN TRY
	EXEC SP.uspPartido_Update @Id=0, @Asistencia=45000;
 THROW 51999,'Se esperaba rechazo.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) OR ERROR_MESSAGE() NOT LIKE '%Id%' THROW;
 PRINT 'Rechazo comprobado: '+ERROR_MESSAGE();
END CATCH
GO
SELECT IdPartido, IdFase, IdSede, IdMundial, Eq1, Eq2, GolesEq1, GolesEq2, Asistencia FROM partidos.Partido
GO

-- Esperado: id inexistente (99)
BEGIN TRY
	EXEC SP.uspPartido_Update @Id=99, @Asistencia=45000;
 THROW 51999,'Se esperaba rechazo.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) OR ERROR_MESSAGE() NOT LIKE '%Partido%' THROW;
 PRINT 'Rechazo comprobado: '+ERROR_MESSAGE();
END CATCH
GO
SELECT IdPartido, IdFase, IdSede, IdMundial, Eq1, Eq2, GolesEq1, GolesEq2, Asistencia FROM partidos.Partido
GO

--/BAJA

DECLARE @pPart4 INT = (SELECT MIN(IdPartido) FROM partidos.Partido WHERE IdSede=(SELECT IdSede FROM sedes.Sede WHERE Nombre='Sede Test 73'));

-- Esperado: borra el partido
EXEC SP.uspPartido_Bajar @Id=@pPart4;
IF EXISTS(SELECT 1 FROM partidos.Partido WHERE IdPartido=@pPart4) THROW 51999,'No se elimino el partido.',1;
GO
SELECT IdPartido, IdFase, IdSede, IdMundial, Eq1, Eq2, GolesEq1, GolesEq2, Asistencia FROM partidos.Partido
GO

-- Esperado: id inexistente (99), 0 borradas
BEGIN TRY
	EXEC SP.uspPartido_Bajar @Id=99;
 THROW 51999,'Se esperaba rechazo.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) OR ERROR_MESSAGE() NOT LIKE '%Partido%' THROW;
 PRINT 'Rechazo comprobado: '+ERROR_MESSAGE();
END CATCH
GO
SELECT IdPartido, IdFase, IdSede, IdMundial, Eq1, Eq2, GolesEq1, GolesEq2, Asistencia FROM partidos.Partido
GO

--/Limpieza de lo que genera el test (en orden, por las claves foraneas)

DECLARE @lPart INT, @li INT = 0;
WHILE @li < 10
BEGIN
	SET @lPart = (SELECT MIN(IdPartido) FROM partidos.Partido WHERE IdSede=(SELECT IdSede FROM sedes.Sede WHERE Nombre='Sede Test 73'));
	IF @lPart IS NULL BREAK;
	BEGIN TRY
		EXEC SP.uspPartido_Bajar @Id = @lPart
	END TRY
	BEGIN CATCH
		PRINT 'Esperado: ' + ERROR_MESSAGE()
	END CATCH
	SET @li = @li + 1;
END

-- La fase Grupos puede ser compartida por otros casos.
DECLARE @lSede INT = (SELECT MIN(IdSede) FROM sedes.Sede WHERE Nombre = 'Sede Test 73');
IF @lSede IS NOT NULL
	BEGIN TRY
		EXEC SP.uspSede_Bajar @idSede = @lSede
	END TRY
	BEGIN CATCH
		PRINT 'Esperado: ' + ERROR_MESSAGE()
	END CATCH

DECLARE @lId INT, @lSel INT, @lj INT = 0;
WHILE @lj < 5
BEGIN
	SET @lSel = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION LIKE 'CONF 73%');
	IF @lSel IS NULL BREAK;
	BEGIN TRY
		EXEC SP.uspSeleccion_Bajar @idSeleccion = @lSel
	END TRY
	BEGIN CATCH
		PRINT 'Esperado: ' + ERROR_MESSAGE()
	END CATCH
	SET @lj = @lj + 1;
END

DECLARE @lGrup INT = (SELECT MIN(IdGrupo) FROM equipos.Grupo WHERE NOMBRE = 'Grupo 73');
IF @lGrup IS NOT NULL
	BEGIN TRY
		EXEC SP.uspGrupo_Bajar @id = @lGrup
	END TRY
	BEGIN CATCH
		PRINT 'Esperado: ' + ERROR_MESSAGE()
	END CATCH

DECLARE @lMund INT = (SELECT MIN(IdMundial) FROM sedes.Mundial WHERE IdPais = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test 73'));
IF @lMund IS NOT NULL
	BEGIN TRY
		EXEC SP.uspMundial_Bajar @id = @lMund
	END TRY
	BEGIN CATCH
		PRINT 'Esperado: ' + ERROR_MESSAGE()
	END CATCH

SET @lj = 0;
WHILE @lj < 5
BEGIN
	SET @lId = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE LIKE 'Pais Test 73%');
	IF @lId IS NULL BREAK;
	BEGIN TRY
		EXEC SP.uspPais_Bajar @idPais = @lId
	END TRY
	BEGIN CATCH
		PRINT 'Esperado: ' + ERROR_MESSAGE()
	END CATCH
	SET @lj = @lj + 1;
END

DECLARE @lHuso INT = (SELECT MIN(IdHuso) FROM sedes.HusoHorario WHERE Nombre = 'UTC-3 (73)');
IF @lHuso IS NOT NULL
	BEGIN TRY
		EXEC SP.uspHusoHorario_Bajar @idHuso = @lHuso
	END TRY
	BEGIN CATCH
		PRINT 'Esperado: ' + ERROR_MESSAGE()
	END CATCH

DECLARE @lIdioma INT = (SELECT MIN(IdIdioma) FROM arbitros.Idioma WHERE Descripcion = 'Idioma Test');
IF @lIdioma IS NOT NULL
	BEGIN TRY
		EXEC SP.uspIdioma_Bajar @id = @lIdioma
	END TRY
	BEGIN CATCH
		PRINT 'Esperado: ' + ERROR_MESSAGE()
	END CATCH

-- Esperado: no queda nada del test.
SELECT * FROM partidos.Partido;
SELECT * FROM partidos.Fase;
GO
