-- Universidad Nacional de La Matanza
-- Bases de datos aplicada
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 08/10/2026
-- Objetivo: Testear Registro y Baja de Gol

--Los objetos de negocio (TABLAS y SP) viven en MUNDIAL, el test se ejecuta contra ellos.
--El test arma su propio juego de datos y lo borra al final, asi se puede ejecutar mas de una vez.
--Juegan CONF G1 (autor) y CONF G2 (asistencia); CONF G3 esta preservada para probar los casos
--de jugador que no participo del encuentro.

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END
GO

--/Datos de prueba

-- Esperado: se crean los 3 paises.
IF NOT EXISTS (SELECT 1 FROM equipos.Pais WHERE NOMBRE = 'Pais Test G1')
	EXEC SP.uspPais_Registrar @nombre = 'Pais Test G1', @pbi = 51;
GO
IF NOT EXISTS (SELECT 1 FROM equipos.Pais WHERE NOMBRE = 'Pais Test G2')
	EXEC SP.uspPais_Registrar @nombre = 'Pais Test G2', @pbi = 52;
GO
IF NOT EXISTS (SELECT 1 FROM equipos.Pais WHERE NOMBRE = 'Pais Test G3')
	EXEC SP.uspPais_Registrar @nombre = 'Pais Test G3', @pbi = 53;
GO

DECLARE @gPais1 INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test G1');

-- Esperado: se crea el mundial (minimo de jugadores 0 para que la limpieza pueda borrarlos).
IF NOT EXISTS (SELECT 1 FROM sedes.Mundial WHERE IdPais = @gPais1)
	EXEC SP.uspMundial_Registrar @idPais = @gPais1, @fechaInicio = '2026-06-01', @fechaFin = '2026-07-30',
		@tamMin = 0, @tamMax = 23, @ventanas = 3, @cantidad = 5, @suspMax = 2, @suspTiempo = 1;
GO

-- Esperado: se crea el grupo.
IF NOT EXISTS (SELECT 1 FROM equipos.Grupo WHERE NOMBRE = 'Grupo G')
	EXEC SP.uspGrupo_Registrar @nombre = 'Grupo G';
GO

DECLARE @gPais1b INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test G1');
DECLARE @gPais2  INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test G2');
DECLARE @gPais3  INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test G3');
DECLARE @gMundial INT = (SELECT MIN(IdMundial) FROM sedes.Mundial WHERE IdPais = @gPais1b);
DECLARE @gGrupo  INT = (SELECT MIN(IdGrupo) FROM equipos.Grupo WHERE NOMBRE = 'Grupo G');

-- Esperado: se crean las 3 selecciones del mundial.
IF NOT EXISTS (SELECT 1 FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF G1')
	EXEC SP.uspSeleccion_Registrar @idPais = @gPais1b, @idMundial = @gMundial, @idGrupo = @gGrupo, @confederacion = 'CONF G1';
GO

DECLARE @gPais1c INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test G1');
DECLARE @gPais2b INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test G2');
DECLARE @gMundial2 INT = (SELECT MIN(IdMundial) FROM sedes.Mundial WHERE IdPais = @gPais1c);
DECLARE @gGrupo2  INT = (SELECT MIN(IdGrupo) FROM equipos.Grupo WHERE NOMBRE = 'Grupo G');

IF NOT EXISTS (SELECT 1 FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF G2')
	EXEC SP.uspSeleccion_Registrar @idPais = @gPais2b, @idMundial = @gMundial2, @idGrupo = @gGrupo2, @confederacion = 'CONF G2';
GO

DECLARE @gPais1d INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test G1');
DECLARE @gPais3b INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test G3');
DECLARE @gMundial3 INT = (SELECT MIN(IdMundial) FROM sedes.Mundial WHERE IdPais = @gPais1d);
DECLARE @gGrupo3  INT = (SELECT MIN(IdGrupo) FROM equipos.Grupo WHERE NOMBRE = 'Grupo G');

IF NOT EXISTS (SELECT 1 FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF G3')
	EXEC SP.uspSeleccion_Registrar @idPais = @gPais3b, @idMundial = @gMundial3, @idGrupo = @gGrupo3, @confederacion = 'CONF G3';
GO

DECLARE @gPais1e INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test G1');

-- Esperado: se crea el huso horario y la sede.
IF NOT EXISTS (SELECT 1 FROM sedes.HusoHorario WHERE Nombre = 'UTC-3 (G)')
	EXEC SP.uspHusoHorario_Registrar @nombre = 'UTC-3 (G)', @idPais = @gPais1e;
GO

DECLARE @gHuso   INT = (SELECT MIN(IdHuso) FROM sedes.HusoHorario WHERE Nombre = 'UTC-3 (G)');
DECLARE @gPais1f INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test G1');

IF NOT EXISTS (SELECT 1 FROM sedes.Sede WHERE Nombre = 'Sede Test G')
	EXEC SP.uspSede_Registrar @nombre = 'Sede Test G', @ciudad = 'Ciudad Test G', @capacidad = 50000, @pais = @gPais1f, @huso = @gHuso;
GO

-- Esperado: se crea la fase y el periodo.
IF NOT EXISTS (SELECT 1 FROM partidos.Fase WHERE Descripcion = 'Grupos')
	EXEC SP.uspFase_Registrar @Descripcion = 'Grupos';
GO

IF NOT EXISTS (SELECT 1 FROM partidos.Periodo WHERE IdPeriodo = 901)
	EXEC partidos.Periodo_Alta @idPeriodo = 901, @descripcion = 'Tiempo G', @inicio = 0, @fin = 45;
GO

DECLARE @gSede     INT = (SELECT MIN(IdSede) FROM sedes.Sede WHERE Nombre = 'Sede Test G');
DECLARE @gFase     INT = (SELECT MIN(IdFase) FROM partidos.Fase WHERE Descripcion = 'Grupos');
DECLARE @gPais1g   INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test G1');
DECLARE @gMundial4 INT = (SELECT MIN(IdMundial) FROM sedes.Mundial WHERE IdPais = @gPais1g);
DECLARE @gSel1     INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF G1');
DECLARE @gSel2     INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF G2');

-- Esperado: se crea el partido entre CONF G1 y CONF G2 (G3 no juega).
IF NOT EXISTS (SELECT 1 FROM partidos.Partido WHERE IdFase = @gFase AND Eq1 = @gSel1 AND Eq2 = @gSel2)
	EXEC SP.uspPartido_Registrar @IdFase = @gFase, @IdSede = @gSede, @IdMundial = @gMundial4,
		@Eq1 = @gSel1, @Eq2 = @gSel2, @Fecha = '2026-06-15', @HoraUTC = '16:00', @HoraLocal = '13:00';
GO

-- Esperado: se registran 3 jugadores (A1 y A2 juegan, A3 no).
DECLARE @gJugPais1 INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test G1');
DECLARE @gJugSel1  INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF G1');

IF NOT EXISTS (SELECT 1 FROM equipos.Persona WHERE Nombre = 'Gol Test A1')
	EXEC SPTRANS.uspJugador_Registrar @nombre = 'Gol Test A1', @fnac = '2003-01-01', @pais = @gJugPais1, @posicion = 'DEL', @numero = 7, @seleccion = @gJugSel1;
GO

DECLARE @gJugPais2 INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test G2');
DECLARE @gJugSel2  INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF G2');

IF NOT EXISTS (SELECT 1 FROM equipos.Persona WHERE Nombre = 'Gol Test A2')
	EXEC SPTRANS.uspJugador_Registrar @nombre = 'Gol Test A2', @fnac = '2003-01-02', @pais = @gJugPais2, @posicion = 'DEL', @numero = 9, @seleccion = @gJugSel2;
GO

DECLARE @gJugPais3 INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test G3');
DECLARE @gJugSel3  INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF G3');

IF NOT EXISTS (SELECT 1 FROM equipos.Persona WHERE Nombre = 'Gol Test A3')
	EXEC SPTRANS.uspJugador_Registrar @nombre = 'Gol Test A3', @fnac = '2003-01-03', @pais = @gJugPais3, @posicion = 'DEL', @numero = 11, @seleccion = @gJugSel3;
GO

--/ALTA

-- Esperado: gol de jugada con asistencia, 1 fila en Evento y Gol, GolesEq1 = 1 (autor de CONF G1)
DECLARE @gP1 INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
DECLARE @gA1 INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Gol Test A1');
DECLARE @gA2 INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Gol Test A2');
EXEC SPTRANS.uspGol_Registrar @minuto = 23, @partido = @gP1, @periodo = 901, @autor = @gA1, @asistencia = @gA2, @tipo = 'Jugada'
GO
SELECT * FROM partidos.Evento WHERE Tipo = 'Gol'
GO
SELECT * FROM partidos.Gol
GO
SELECT IdPartido, Eq1, Eq2, GolesEq1, GolesEq2 FROM partidos.Partido
GO

-- Esperado: autor y asistencia iguales, 0 filas nuevas, marcador sin cambios
DECLARE @gP2 INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
DECLARE @gA1b INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Gol Test A1');
EXEC SPTRANS.uspGol_Registrar @minuto = 30, @partido = @gP2, @periodo = 901, @autor = @gA1b, @asistencia = @gA1b, @tipo = 'Jugada'
GO
SELECT * FROM partidos.Gol
GO

-- Esperado: el gol en contra no lleva asistencia, 0 filas nuevas, marcador sin cambios
DECLARE @gP3 INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
DECLARE @gA1c INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Gol Test A1');
DECLARE @gA2b INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Gol Test A2');
EXEC SPTRANS.uspGol_Registrar @minuto = 40, @partido = @gP3, @periodo = 901, @autor = @gA1c, @asistencia = @gA2b, @tipo = 'En contra'
GO
SELECT * FROM partidos.Gol
GO

-- Esperado: el autor no participo del encuentro (A3 es de CONF G3), 0 filas nuevas
DECLARE @gP4 INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
DECLARE @gA1d INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Gol Test A1');
DECLARE @gA3  INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Gol Test A3');
EXEC SPTRANS.uspGol_Registrar @minuto = 42, @partido = @gP4, @periodo = 901, @autor = @gA3, @asistencia = NULL, @tipo = 'Jugada'
GO
SELECT * FROM partidos.Gol
GO

-- Esperado: la asistencia no participo del encuentro (A3 es de CONF G3), 0 filas nuevas
DECLARE @gP5 INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
DECLARE @gA1e INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Gol Test A1');
DECLARE @gA3b INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Gol Test A3');
EXEC SPTRANS.uspGol_Registrar @minuto = 43, @partido = @gP5, @periodo = 901, @autor = @gA1e, @asistencia = @gA3b, @tipo = 'Jugada'
GO
SELECT * FROM partidos.Gol
GO

-- Esperado: inexistente Autor (999999), 0 filas nuevas, marcador sin cambios
DECLARE @gP6 INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
DECLARE @gA2c INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Gol Test A2');
EXEC SPTRANS.uspGol_Registrar @minuto = 45, @partido = @gP6, @periodo = 901, @autor = 999999, @asistencia = @gA2c, @tipo = 'Penal'
GO
SELECT * FROM partidos.Gol
GO

-- Esperado: inexistente Asistencia (999999), 0 filas nuevas, marcador sin cambios
DECLARE @gP7 INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
DECLARE @gA1f INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Gol Test A1');
EXEC SPTRANS.uspGol_Registrar @minuto = 45, @partido = @gP7, @periodo = 901, @autor = @gA1f, @asistencia = 999999, @tipo = 'Penal'
GO
SELECT * FROM partidos.Gol
GO

-- Esperado: tipo invalido (Chilena es tecnica, no situacion), 0 filas nuevas, marcador sin cambios
DECLARE @gP8 INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
DECLARE @gA1g INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Gol Test A1');
EXEC SPTRANS.uspGol_Registrar @minuto = 50, @partido = @gP8, @periodo = 901, @autor = @gA1g, @asistencia = NULL, @tipo = 'Chilena'
GO
SELECT * FROM partidos.Gol
GO

-- Esperado: periodo inexistente (999999), 0 filas nuevas, marcador sin cambios
DECLARE @gP9 INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
DECLARE @gA1h INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Gol Test A1');
EXEC SPTRANS.uspGol_Registrar @minuto = 55, @partido = @gP9, @periodo = 999999, @autor = @gA1h, @asistencia = NULL, @tipo = 'Penal'
GO
SELECT * FROM partidos.Gol
GO

-- Esperado: gol en contra sin asistencia del autor de CONF G2, GolesEq1 = 2 (suma al rival)
DECLARE @gP10 INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
DECLARE @gA2d INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Gol Test A2');
EXEC SPTRANS.uspGol_Registrar @minuto = 45, @partido = @gP10, @periodo = 901, @autor = @gA2d, @asistencia = NULL, @tipo = 'En contra'
GO
SELECT * FROM partidos.Gol
GO
SELECT IdPartido, Eq1, Eq2, GolesEq1, GolesEq2 FROM partidos.Partido
GO

--/BAJA

-- Esperado: borra el gol en contra y descuenta 1 del rival, GolesEq1 = 1
DECLARE @gCont INT = (SELECT MIN(G.IdGol) FROM partidos.Gol G INNER JOIN equipos.Jugador J ON G.Autor = J.IdJugador
					 INNER JOIN equipos.Persona P ON P.IdPersona = J.IdJugador WHERE P.Nombre = 'Gol Test A2');
EXEC SPTRANS.uspGol_Bajar @id = @gCont
GO
SELECT * FROM partidos.Gol
GO
SELECT IdPartido, Eq1, Eq2, GolesEq1, GolesEq2 FROM partidos.Partido
GO

-- Esperado: borra el gol de jugada y su evento y descuenta 1, GolesEq1 = 0
DECLARE @gJug INT = (SELECT MIN(G.IdGol) FROM partidos.Gol G INNER JOIN equipos.Jugador J ON G.Autor = J.IdJugador
					 INNER JOIN equipos.Persona P ON P.IdPersona = J.IdJugador WHERE P.Nombre = 'Gol Test A1');
EXEC SPTRANS.uspGol_Bajar @id = @gJug
GO
SELECT * FROM partidos.Gol
GO
SELECT * FROM partidos.Evento WHERE Tipo = 'Gol'
GO
SELECT IdPartido, Eq1, Eq2, GolesEq1, GolesEq2 FROM partidos.Partido
GO

-- Esperado: inexistente (999999), 0 borradas, marcador sin cambios
EXEC SPTRANS.uspGol_Bajar @id = 999999
GO
SELECT * FROM partidos.Gol
GO

--/Limpieza de lo que genera el test (en orden, por las claves foraneas)
--Todo en un solo bloque para no perder las variables. Cada loop tiene su propio contador y tope.

DECLARE @gId INT, @i INT = 0;

--1) Los goles que quedaron.
WHILE @i < 10
BEGIN
	SET @gId = (SELECT MIN(IdGol) FROM partidos.Gol);
	IF @gId IS NULL BREAK;
	EXEC SPTRANS.uspGol_Bajar @id = @gId;
	SET @i = @i + 1;
END

--2) Los jugadores del test.
SET @i = 0;
WHILE @i < 10
BEGIN
	SET @gId = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre LIKE 'Gol Test%');
	IF @gId IS NULL BREAK;
	EXEC SPTRANS.uspJugador_Bajar @id = @gId;
	SET @i = @i + 1;
END

--3) El partido, el periodo y la fase.
DECLARE @gPartB INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
IF @gPartB IS NOT NULL
	EXEC SP.uspPartido_Bajar @Id = @gPartB;

IF EXISTS (SELECT 1 FROM partidos.Periodo WHERE IdPeriodo = 901)
	EXEC partidos.Periodo_Baja @idPeriodo = 901;

DECLARE @gFaseB INT = (SELECT MIN(IdFase) FROM partidos.Fase WHERE Descripcion = 'Grupos');
IF @gFaseB IS NOT NULL
	EXEC SP.uspFase_Bajar @Id = @gFaseB;

--4) La sede, el huso horario, las selecciones, el grupo, el mundial y los paises.
DECLARE @gSedeB INT = (SELECT MIN(IdSede) FROM sedes.Sede WHERE Nombre = 'Sede Test G');
IF @gSedeB IS NOT NULL
	EXEC SP.uspSede_Bajar @idSede = @gSedeB;

DECLARE @gHusoB INT = (SELECT MIN(IdHuso) FROM sedes.HusoHorario WHERE Nombre = 'UTC-3 (G)');
IF @gHusoB IS NOT NULL
	EXEC SP.uspHusoHorario_Bajar @idHuso = @gHusoB;

SET @i = 0;
WHILE @i < 5
BEGIN
	SET @gId = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION LIKE 'CONF G%');
	IF @gId IS NULL BREAK;
	EXEC SP.uspSeleccion_Bajar @idSeleccion = @gId;
	SET @i = @i + 1;
END

DECLARE @gGrupoB INT = (SELECT MIN(IdGrupo) FROM equipos.Grupo WHERE NOMBRE = 'Grupo G');
IF @gGrupoB IS NOT NULL
	EXEC SP.uspGrupo_Bajar @id = @gGrupoB;

DECLARE @gPaisE INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test G1');
DECLARE @gMundialB INT = (SELECT MIN(IdMundial) FROM sedes.Mundial WHERE IdPais = @gPaisE);
IF @gMundialB IS NOT NULL
	EXEC SP.uspMundial_Bajar @id = @gMundialB;

SET @i = 0;
WHILE @i < 5
BEGIN
	SET @gId = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE LIKE 'Pais Test G%');
	IF @gId IS NULL BREAK;
	EXEC SP.uspPais_Bajar @idPais = @gId;
	SET @i = @i + 1;
END

-- Esperado: no queda nada del test.
SELECT * FROM partidos.Gol;
SELECT * FROM partidos.Evento;
SELECT * FROM equipos.Jugador;
GO