-- Universidad Nacional de La Matanza
-- Bases de datos aplicada
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 21/10/2026
-- Objetivo: Testear Registro, Update y Baja de HistorialPublicidad

--Los objetos de negocio viven en MUNDIAL, el test se ejecuta contra ellos.
--El test arma su propio juego de datos y lo borra al final, asi se puede ejecutar mas de una vez.
--usHistorialPublicidad_* lanza excepciones (THROW), por eso los casos esperados a fallar van
--envueltos en TRY/CATCH: el CATCH captura la excepcion y deja el mensaje en el log del test.
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END
GO

--/Datos de prueba

-- Esperado: se crea el pais.
IF NOT EXISTS (SELECT 1 FROM equipos.Pais WHERE NOMBRE = 'Pais Test 83')
	EXEC SP.uspPais_Registrar @nombre = 'Pais Test 83', @pbi = 90;
GO

-- Esperado: se crea un segundo pais. Cada seleccion es de un pais distinto,
-- si no, la clave (pais, mundial) quedaria duplicada y la segunda no se crearia.
IF NOT EXISTS (SELECT 1 FROM equipos.Pais WHERE NOMBRE = 'Pais Test 83b')
	EXEC SP.uspPais_Registrar @nombre = 'Pais Test 83b', @pbi = 91;
GO

DECLARE @hPais INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test 83');

-- Esperado: se crea el mundial (minimo de jugadores 0 para poder limpiar).
IF NOT EXISTS (SELECT 1 FROM sedes.Mundial WHERE IdPais = @hPais)
	EXEC SP.uspMundial_Registrar @idPais = @hPais, @fechaInicio = '2026-06-01', @fechaFin = '2026-07-30',
		@tamMin = 0, @tamMax = 23, @ventanas = 3, @cantidad = 5, @suspMax = 2, @suspTiempo = 1;
GO

-- Esperado: se crea el grupo.
IF NOT EXISTS (SELECT 1 FROM equipos.Grupo WHERE NOMBRE = 'Grupo 83')
	EXEC SP.uspGrupo_Registrar @nombre = 'Grupo 83';
GO

DECLARE @hPais2 INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test 83');
DECLARE @hMund  INT = (SELECT MIN(IdMundial) FROM sedes.Mundial WHERE IdPais = @hPais2);
DECLARE @hGrup  INT = (SELECT MIN(IdGrupo) FROM equipos.Grupo WHERE NOMBRE = 'Grupo 83');

-- Esperado: se crean las dos selecciones que juegan.
IF NOT EXISTS (SELECT 1 FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF 831')
	EXEC SP.uspSeleccion_Registrar @idPais = @hPais2, @idMundial = @hMund, @idGrupo = @hGrup, @confederacion = 'CONF 831';
GO

DECLARE @hPais3 INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test 83b');
DECLARE @hMund2 INT = (SELECT MIN(IdMundial) FROM sedes.Mundial WHERE IdPais = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test 83'));
DECLARE @hGrup2 INT = (SELECT MIN(IdGrupo) FROM equipos.Grupo WHERE NOMBRE = 'Grupo 83');

IF NOT EXISTS (SELECT 1 FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF 832')
	EXEC SP.uspSeleccion_Registrar @idPais = @hPais3, @idMundial = @hMund2, @idGrupo = @hGrup2, @confederacion = 'CONF 832';
GO

DECLARE @hPais4 INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test 83');

-- Esperado: se crea el huso horario y la sede.
IF NOT EXISTS (SELECT 1 FROM sedes.HusoHorario WHERE Nombre = 'UTC-3 (83)')
	EXEC SP.uspHusoHorario_Registrar @nombre = 'UTC-3 (83)', @idPais = @hPais4;
GO

DECLARE @hHuso  INT = (SELECT MIN(IdHuso) FROM sedes.HusoHorario WHERE Nombre = 'UTC-3 (83)');
DECLARE @hPais5 INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test 83');

IF NOT EXISTS (SELECT 1 FROM sedes.Sede WHERE Nombre = 'Sede Test 83')
	EXEC SP.uspSede_Registrar @nombre = 'Sede Test 83', @ciudad = 'Ciudad Test 83', @capacidad = 50000, @pais = @hPais5, @huso = @hHuso;
GO

-- Esperado: se crea la fase.
IF NOT EXISTS (SELECT 1 FROM partidos.Fase WHERE Descripcion = 'Grupos')
	EXEC SP.uspFase_Registrar @Descripcion = 'Grupos';
GO

DECLARE @hFase INT = (SELECT MIN(IdFase) FROM partidos.Fase WHERE Descripcion = 'Grupos');
DECLARE @hSede INT = (SELECT MIN(IdSede) FROM sedes.Sede WHERE Nombre = 'Sede Test 83');
DECLARE @hMund3 INT = (SELECT MIN(IdMundial) FROM sedes.Mundial WHERE IdPais = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test 83'));
DECLARE @hEq1  INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF 831');
DECLARE @hEq2  INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF 832');

-- Esperado: se crea el partido.
IF NOT EXISTS (SELECT 1 FROM partidos.Partido WHERE IdFase = @hFase AND Eq1 = @hEq1 AND Eq2 = @hEq2)
	EXEC SP.uspPartido_Registrar @IdFase=@hFase, @IdSede=@hSede, @IdMundial=@hMund3, @Eq1=@hEq1, @Eq2=@hEq2,
		@Fecha='2026-06-15', @HoraUTC='16:00', @HoraLocal='13:00', @Asistencia=40000;
GO

-- Esperado: se crea el espacio publicitario de la sede.
IF NOT EXISTS (SELECT 1 FROM publicidad.EspacioPublicitario WHERE IdSede = (SELECT MIN(IdSede) FROM sedes.Sede WHERE Nombre = 'Sede Test 83'))
	EXEC SP.EspacioPublicitario_Registrar @tipo = 'Tanda de anuncios', @costo = 500.00,
		@idSede = (SELECT MIN(IdSede) FROM sedes.Sede WHERE Nombre = 'Sede Test 83'), @numero = 1;
GO

-- Esperado: se crea la franja de costo (el historial la referencia por IdCF, que no admite NULL).
IF NOT EXISTS (SELECT 1 FROM publicidad.CostoFranja WHERE IdSede = (SELECT MIN(IdSede) FROM sedes.Sede WHERE Nombre = 'Sede Test 83'))
	EXEC SP.CostoFranja_Registrar @tipoFranja = 'Prime Time T83', @costo = 1000.00,
		@idSede = (SELECT MIN(IdSede) FROM sedes.Sede WHERE Nombre = 'Sede Test 83');
GO

-- Esperado: se crea el idioma, la campania y la publicidad.
IF NOT EXISTS (SELECT 1 FROM arbitros.Idioma WHERE Descripcion = 'Idioma T83')
	EXEC SP.uspIdioma_Registrar @descripcion = 'Idioma T83';
GO
IF NOT EXISTS (SELECT 1 FROM publicidad.Campania WHERE Nombre = 'Campania T83')
	EXEC SP.uspCampania_Registrar @nombre = 'Campania T83', @descripcion = 'Campania de prueba del test 83';
GO

DECLARE @hCamp INT = (SELECT MIN(IdCampania) FROM publicidad.Campania WHERE Nombre = 'Campania T83');
DECLARE @hIdio INT = (SELECT MIN(IdIdioma) FROM arbitros.Idioma WHERE Descripcion = 'Idioma T83');

IF NOT EXISTS (SELECT 1 FROM publicidad.Publicidad WHERE Nombre = 'Pub Test 83')
	EXEC SP.uspPublicidad_Registrar @nombre = 'Pub Test 83', @idCampania = @hCamp, @idIdioma = @hIdio;
GO

--/ALTA

DECLARE @qPub  INT = (SELECT MIN(IdPublicidad) FROM publicidad.Publicidad WHERE Nombre = 'Pub Test 83');
DECLARE @qPart INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
DECLARE @qEP   INT = (SELECT MIN(IdEP) FROM publicidad.EspacioPublicitario);
DECLARE @qCF1 INT = (SELECT MIN(IdCF) FROM publicidad.CostoFranja WHERE TipoFranja = 'Prime Time T83');

-- Esperado: inserta 1 fila
IF NOT EXISTS (SELECT 1 FROM publicidad.HistorialPublicidad WHERE IdPublicidad = @qPub AND IdPartido = @qPart)
	BEGIN TRY
		EXEC SP.uspHistorialPublicidad_Registrar @qPub, @qPart, @qEP, 1000.00, @qCF1
	END TRY
	BEGIN CATCH
		PRINT 'Esperado: ' + ERROR_MESSAGE()
	END CATCH
GO
SELECT * FROM publicidad.HistorialPublicidad
GO

DECLARE @qPub2  INT = (SELECT MIN(IdPublicidad) FROM publicidad.Publicidad WHERE Nombre = 'Pub Test 83');
DECLARE @qPart2 INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
DECLARE @qEP2   INT = (SELECT MIN(IdEP) FROM publicidad.EspacioPublicitario);
DECLARE @qCF2 INT = (SELECT MIN(IdCF) FROM publicidad.CostoFranja WHERE TipoFranja = 'Prime Time T83');

-- Esperado: costo invalido (0), 0 filas nuevas
BEGIN TRY
	EXEC SP.uspHistorialPublicidad_Registrar @qPub2, @qPart2, @qEP2, 0, @qCF2
END TRY
BEGIN CATCH
	PRINT 'Esperado: ' + ERROR_MESSAGE()
END CATCH
GO
SELECT * FROM publicidad.HistorialPublicidad
GO

DECLARE @qPub3  INT = (SELECT MIN(IdPublicidad) FROM publicidad.Publicidad WHERE Nombre = 'Pub Test 83');
DECLARE @qPart3 INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
DECLARE @qEP3   INT = (SELECT MIN(IdEP) FROM publicidad.EspacioPublicitario);
DECLARE @qCF3 INT = (SELECT MIN(IdCF) FROM publicidad.CostoFranja WHERE TipoFranja = 'Prime Time T83');

-- Esperado: duplicada (misma publicidad, partido y espacio), 0 filas nuevas
BEGIN TRY
	EXEC SP.uspHistorialPublicidad_Registrar @qPub3, @qPart3, @qEP3, 1000.00, @qCF3
END TRY
BEGIN CATCH
	PRINT 'Esperado: ' + ERROR_MESSAGE()
END CATCH
GO
SELECT * FROM publicidad.HistorialPublicidad
GO

DECLARE @qPart4 INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
DECLARE @qEP4   INT = (SELECT MIN(IdEP) FROM publicidad.EspacioPublicitario);
DECLARE @qCF4 INT = (SELECT MIN(IdCF) FROM publicidad.CostoFranja WHERE TipoFranja = 'Prime Time T83');

-- Esperado: publicidad inexistente (99), 0 filas nuevas
BEGIN TRY
	EXEC SP.uspHistorialPublicidad_Registrar 99, @qPart4, @qEP4, 1000.00, @qCF4
END TRY
BEGIN CATCH
	PRINT 'Esperado: ' + ERROR_MESSAGE()
END CATCH
GO
SELECT * FROM publicidad.HistorialPublicidad
GO

DECLARE @qPub4  INT = (SELECT MIN(IdPublicidad) FROM publicidad.Publicidad WHERE Nombre = 'Pub Test 83');
DECLARE @qEP5   INT = (SELECT MIN(IdEP) FROM publicidad.EspacioPublicitario);
DECLARE @qCF5 INT = (SELECT MIN(IdCF) FROM publicidad.CostoFranja WHERE TipoFranja = 'Prime Time T83');

-- Esperado: partido inexistente (99), 0 filas nuevas
BEGIN TRY
	EXEC SP.uspHistorialPublicidad_Registrar @qPub4, 99, @qEP5, 1000.00, @qCF5
END TRY
BEGIN CATCH
	PRINT 'Esperado: ' + ERROR_MESSAGE()
END CATCH
GO
SELECT * FROM publicidad.HistorialPublicidad
GO

--/UPDATE

DECLARE @qId    INT = (SELECT MIN(IdHistorial) FROM publicidad.HistorialPublicidad);
DECLARE @qPub5  INT = (SELECT MIN(IdPublicidad) FROM publicidad.Publicidad WHERE Nombre = 'Pub Test 83');
DECLARE @qPart5 INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
DECLARE @qEP6   INT = (SELECT MIN(IdEP) FROM publicidad.EspacioPublicitario);
DECLARE @qCF6 INT = (SELECT MIN(IdCF) FROM publicidad.CostoFranja WHERE TipoFranja = 'Prime Time T83');

-- Esperado: update del costo, SELECT muestra 1500.00
BEGIN TRY
	EXEC SP.uspHistorialPublicidad_Update @qId, @qPub5, @qPart5, @qEP6, 1500.00, @qCF6
END TRY
BEGIN CATCH
	PRINT 'Esperado: ' + ERROR_MESSAGE()
END CATCH
GO
SELECT * FROM publicidad.HistorialPublicidad
GO

DECLARE @qPub6  INT = (SELECT MIN(IdPublicidad) FROM publicidad.Publicidad WHERE Nombre = 'Pub Test 83');
DECLARE @qPart6 INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
DECLARE @qEP7   INT = (SELECT MIN(IdEP) FROM publicidad.EspacioPublicitario);
DECLARE @qCF7 INT = (SELECT MIN(IdCF) FROM publicidad.CostoFranja WHERE TipoFranja = 'Prime Time T83');

-- Esperado: id inexistente (99)
BEGIN TRY
	EXEC SP.uspHistorialPublicidad_Update 99, @qPub6, @qPart6, @qEP7, 1500.00, @qCF7
END TRY
BEGIN CATCH
	PRINT 'Esperado: ' + ERROR_MESSAGE()
END CATCH
GO
SELECT * FROM publicidad.HistorialPublicidad
GO

--/BAJA

DECLARE @qIdB INT = (SELECT MIN(IdHistorial) FROM publicidad.HistorialPublicidad);

-- Esperado: borra el registro
BEGIN TRY
	EXEC SP.uspHistorialPublicidad_Bajar @qIdB
END TRY
BEGIN CATCH
	PRINT 'Esperado: ' + ERROR_MESSAGE()
END CATCH
GO
SELECT * FROM publicidad.HistorialPublicidad
GO

-- Esperado: id inexistente (99), 0 borradas
BEGIN TRY
	EXEC SP.uspHistorialPublicidad_Bajar 99
END TRY
BEGIN CATCH
	PRINT 'Esperado: ' + ERROR_MESSAGE()
END CATCH
GO
SELECT * FROM publicidad.HistorialPublicidad
GO

--/Limpieza de lo que genera el test (en orden, por las claves foraneas)

DECLARE @lId INT, @lAux INT, @li INT = 0;

--1) El historial que haya quedado.
WHILE @li < 10
BEGIN
	SET @lId = (SELECT MIN(IdHistorial) FROM publicidad.HistorialPublicidad);
	IF @lId IS NULL BREAK;
	BEGIN TRY
		EXEC SP.uspHistorialPublicidad_Bajar @lId
	END TRY
	BEGIN CATCH
		PRINT 'Esperado: ' + ERROR_MESSAGE()
	END CATCH
	SET @li = @li + 1;
END

--2) El espacio publicitario.
DECLARE @lEP INT = (SELECT MIN(IdEP) FROM publicidad.EspacioPublicitario
	WHERE IdSede = (SELECT MIN(IdSede) FROM sedes.Sede WHERE Nombre = 'Sede Test 83'));
IF @lEP IS NOT NULL
	BEGIN TRY
		EXEC SP.EspacioPublicitario_Bajar @idEP = @lEP
	END TRY
	BEGIN CATCH
		PRINT 'Esperado: ' + ERROR_MESSAGE()
	END CATCH

--3) La publicidad, la campania y el idioma.
DECLARE @lPub INT = (SELECT MIN(IdPublicidad) FROM publicidad.Publicidad WHERE Nombre = 'Pub Test 83');
IF @lPub IS NOT NULL
	BEGIN TRY
		EXEC SP.uspPublicidad_Bajar @id = @lPub
	END TRY
	BEGIN CATCH
		PRINT 'Esperado: ' + ERROR_MESSAGE()
	END CATCH

DECLARE @lCamp INT = (SELECT MIN(IdCampania) FROM publicidad.Campania WHERE Nombre = 'Campania T83');
IF @lCamp IS NOT NULL
	BEGIN TRY
		EXEC SP.uspCampania_Bajar @id = @lCamp
	END TRY
	BEGIN CATCH
		PRINT 'Esperado: ' + ERROR_MESSAGE()
	END CATCH

DECLARE @lIdio INT = (SELECT MIN(IdIdioma) FROM arbitros.Idioma WHERE Descripcion = 'Idioma T83');
IF @lIdio IS NOT NULL
	BEGIN TRY
		EXEC SP.uspIdioma_Bajar @id = @lIdio
	END TRY
	BEGIN CATCH
		PRINT 'Esperado: ' + ERROR_MESSAGE()
	END CATCH

--4) El partido, la fase, la sede y el huso.
SET @li = 0;
WHILE @li < 10
BEGIN
	SET @lId = (SELECT MIN(IdPartido) FROM partidos.Partido);
	IF @lId IS NULL BREAK;
	BEGIN TRY
		EXEC SP.uspPartido_Bajar @Id = @lId
	END TRY
	BEGIN CATCH
		PRINT 'Esperado: ' + ERROR_MESSAGE()
	END CATCH
	SET @li = @li + 1;
END

DECLARE @lFase INT = (SELECT MIN(IdFase) FROM partidos.Fase WHERE Descripcion = 'Grupos');
IF @lFase IS NOT NULL
	BEGIN TRY
		EXEC SP.uspFase_Bajar @Id = @lFase
	END TRY
	BEGIN CATCH
		PRINT 'Esperado: ' + ERROR_MESSAGE()
	END CATCH

DECLARE @lSede INT = (SELECT MIN(IdSede) FROM sedes.Sede WHERE Nombre = 'Sede Test 83');
IF @lSede IS NOT NULL
	BEGIN TRY
		EXEC SP.uspSede_Bajar @idSede = @lSede
	END TRY
	BEGIN CATCH
		PRINT 'Esperado: ' + ERROR_MESSAGE()
	END CATCH

DECLARE @lHuso INT = (SELECT MIN(IdHuso) FROM sedes.HusoHorario WHERE Nombre = 'UTC-3 (83)');
IF @lHuso IS NOT NULL
	BEGIN TRY
		EXEC SP.uspHusoHorario_Bajar @idHuso = @lHuso
	END TRY
	BEGIN CATCH
		PRINT 'Esperado: ' + ERROR_MESSAGE()
	END CATCH

--5) Las selecciones, el grupo, el mundial y el pais.
DECLARE @lSel INT, @lj INT = 0;
WHILE @lj < 5
BEGIN
	SET @lSel = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION LIKE 'CONF 83%');
	IF @lSel IS NULL BREAK;
	BEGIN TRY
		EXEC SP.uspSeleccion_Bajar @idSeleccion = @lSel
	END TRY
	BEGIN CATCH
		PRINT 'Esperado: ' + ERROR_MESSAGE()
	END CATCH
	SET @lj = @lj + 1;
END

DECLARE @lGrup INT = (SELECT MIN(IdGrupo) FROM equipos.Grupo WHERE NOMBRE = 'Grupo 83');
IF @lGrup IS NOT NULL
	BEGIN TRY
		EXEC SP.uspGrupo_Bajar @id = @lGrup
	END TRY
	BEGIN CATCH
		PRINT 'Esperado: ' + ERROR_MESSAGE()
	END CATCH

DECLARE @lMund INT = (SELECT MIN(IdMundial) FROM sedes.Mundial WHERE IdPais = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test 83'));
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
	SET @lAux = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE LIKE 'Pais Test 83%');
	IF @lAux IS NULL BREAK;
	BEGIN TRY
		EXEC SP.uspPais_Bajar @idPais = @lAux
	END TRY
	BEGIN CATCH
		PRINT 'Esperado: ' + ERROR_MESSAGE()
	END CATCH
	SET @lj = @lj + 1;
END

-- Esperado: no queda nada del test.
SELECT * FROM publicidad.HistorialPublicidad;
SELECT * FROM publicidad.EspacioPublicitario;
GO
