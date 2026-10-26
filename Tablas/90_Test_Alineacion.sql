-- Universidad Nacional de La Matanza
-- Bases de datos aplicada
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 26/10/26
-- Objetivo: Testear Registro y Baja de Alineacion

--Los objetos de negocio (TABLAS y SP) viven en MUNDIAL, el test se ejecuta contra ellos.
--El test arma su propio juego de datos y lo borra al final, asi se puede ejecutar mas de una vez.
--Juegan CONF A1 y CONF A2; CONF A3 esta preservada para probar el caso de jugador
--cuya seleccion no juega ese partido.

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END
GO

--/Datos de prueba

-- Esperado: se crean los 3 paises.
IF NOT EXISTS (SELECT 1 FROM equipos.Pais WHERE NOMBRE = 'Pais Test A1')
	EXEC SP.uspPais_Registrar @nombre = 'Pais Test A1', @pbi = 61;
GO
IF NOT EXISTS (SELECT 1 FROM equipos.Pais WHERE NOMBRE = 'Pais Test A2')
	EXEC SP.uspPais_Registrar @nombre = 'Pais Test A2', @pbi = 62;
GO
IF NOT EXISTS (SELECT 1 FROM equipos.Pais WHERE NOMBRE = 'Pais Test A3')
	EXEC SP.uspPais_Registrar @nombre = 'Pais Test A3', @pbi = 63;
GO

DECLARE @aPais1 INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test A1');

-- Esperado: se crea el mundial (minimo de jugadores 0 para que la limpieza pueda borrarlos).
IF NOT EXISTS (SELECT 1 FROM sedes.Mundial WHERE IdPais = @aPais1)
	EXEC SP.uspMundial_Registrar @idPais = @aPais1, @fechaInicio = '2026-06-01', @fechaFin = '2026-07-30',
		@tamMin = 0, @tamMax = 23, @ventanas = 3, @cantidad = 5, @suspMax = 2, @suspTiempo = 1;
GO

-- Esperado: se crea el grupo.
IF NOT EXISTS (SELECT 1 FROM equipos.Grupo WHERE NOMBRE = 'Grupo T')
	EXEC SP.uspGrupo_Registrar @nombre = 'Grupo T';
GO

DECLARE @aPais1b INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test A1');
DECLARE @aPais2  INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test A2');
DECLARE @aPais3  INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test A3');
DECLARE @aMundial INT = (SELECT MIN(IdMundial) FROM sedes.Mundial WHERE IdPais = @aPais1b);
DECLARE @aGrupo  INT = (SELECT MIN(IdGrupo) FROM equipos.Grupo WHERE NOMBRE = 'Grupo T');

-- Esperado: se crean las 3 selecciones del mundial.
IF NOT EXISTS (SELECT 1 FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF A1')
	EXEC SP.uspSeleccion_Registrar @idPais = @aPais1b, @idMundial = @aMundial, @idGrupo = @aGrupo, @confederacion = 'CONF A1';
GO

DECLARE @aPais1c INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test A1');
DECLARE @aPais2b INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test A2');
DECLARE @aMundial2 INT = (SELECT MIN(IdMundial) FROM sedes.Mundial WHERE IdPais = @aPais1c);
DECLARE @aGrupo2  INT = (SELECT MIN(IdGrupo) FROM equipos.Grupo WHERE NOMBRE = 'Grupo T');

IF NOT EXISTS (SELECT 1 FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF A2')
	EXEC SP.uspSeleccion_Registrar @idPais = @aPais2b, @idMundial = @aMundial2, @idGrupo = @aGrupo2, @confederacion = 'CONF A2';
GO

DECLARE @aPais1d INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test A1');
DECLARE @aPais3b INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test A3');
DECLARE @aMundial3 INT = (SELECT MIN(IdMundial) FROM sedes.Mundial WHERE IdPais = @aPais1d);
DECLARE @aGrupo3  INT = (SELECT MIN(IdGrupo) FROM equipos.Grupo WHERE NOMBRE = 'Grupo T');

IF NOT EXISTS (SELECT 1 FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF A3')
	EXEC SP.uspSeleccion_Registrar @idPais = @aPais3b, @idMundial = @aMundial3, @idGrupo = @aGrupo3, @confederacion = 'CONF A3';
GO

DECLARE @aPais1e INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test A1');

-- Esperado: se crea el huso horario y la sede.
IF NOT EXISTS (SELECT 1 FROM sedes.HusoHorario WHERE Nombre = 'UTC-3 (A)')
	EXEC SP.uspHusoHorario_Registrar @nombre = 'UTC-3 (A)', @idPais = @aPais1e;
GO

DECLARE @aHuso   INT = (SELECT MIN(IdHuso) FROM sedes.HusoHorario WHERE Nombre = 'UTC-3 (A)');
DECLARE @aPais1f INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test A1');

IF NOT EXISTS (SELECT 1 FROM sedes.Sede WHERE Nombre = 'Sede Test A')
	EXEC SP.uspSede_Registrar @nombre = 'Sede Test A', @ciudad = 'Ciudad Test A', @capacidad = 50000, @pais = @aPais1f, @huso = @aHuso;
GO

-- Esperado: se crea la fase.
IF NOT EXISTS (SELECT 1 FROM partidos.Fase WHERE Descripcion = 'Grupos')
	EXEC SP.uspFase_Registrar @Descripcion = 'Grupos';
GO

DECLARE @aSede     INT = (SELECT MIN(IdSede) FROM sedes.Sede WHERE Nombre = 'Sede Test A');
DECLARE @aFase     INT = (SELECT MIN(IdFase) FROM partidos.Fase WHERE Descripcion = 'Grupos');
DECLARE @aPais1g   INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test A1');
DECLARE @aMundial4 INT = (SELECT MIN(IdMundial) FROM sedes.Mundial WHERE IdPais = @aPais1g);
DECLARE @aSel1     INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF A1');
DECLARE @aSel2     INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF A2');

-- Esperado: se crea el partido entre CONF A1 y CONF A2 (A3 no juega).
IF NOT EXISTS (SELECT 1 FROM partidos.Partido WHERE IdFase = @aFase AND Eq1 = @aSel1 AND Eq2 = @aSel2)
	EXEC SP.uspPartido_Registrar @IdFase = @aFase, @IdSede = @aSede, @IdMundial = @aMundial4,
		@Eq1 = @aSel1, @Eq2 = @aSel2, @Fecha = '2026-06-15', @HoraUTC = '16:00', @HoraLocal = '13:00';
GO

-- Esperado: se registran 3 jugadores (T1 y T2 juegan, A3 no).
DECLARE @aJugPais1 INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test A1');
DECLARE @aJugSel1  INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF A1');

IF NOT EXISTS (SELECT 1 FROM equipos.Persona WHERE Nombre = 'Ali Test T1')
	EXEC SPTRANS.uspJugador_Registrar @nombre = 'Ali Test T1', @fnac = '2003-01-01', @pais = @aJugPais1, @posicion = 'DEL', @numero = 8, @seleccion = @aJugSel1;
GO

DECLARE @aJugPais1b INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test A1');
DECLARE @aJugSel1b  INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF A1');

IF NOT EXISTS (SELECT 1 FROM equipos.Persona WHERE Nombre = 'Ali Test T2')
	EXEC SPTRANS.uspJugador_Registrar @nombre = 'Ali Test T2', @fnac = '2003-01-02', @pais = @aJugPais1b, @posicion = 'MED', @numero = 10, @seleccion = @aJugSel1b;
GO

DECLARE @aJugPais3 INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test A3');
DECLARE @aJugSel3  INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF A3');

IF NOT EXISTS (SELECT 1 FROM equipos.Persona WHERE Nombre = 'Ali Test NA')
	EXEC SPTRANS.uspJugador_Registrar @nombre = 'Ali Test NA', @fnac = '2003-01-03', @pais = @aJugPais3, @posicion = 'DEL', @numero = 11, @seleccion = @aJugSel3;
GO

--/ALTA

-- Esperado: alinea a T1 como titular, 1 fila en Alineacion
DECLARE @aP1 INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
DECLARE @aT1 INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Ali Test T1');
EXEC SP.uspAlineacion_Registrar @IdPartido = @aP1, @IdJugador = @aT1, @Rol = 'Titular', @PosicionCancha = 'DEL', @Esquema = '4-3-3'
GO
SELECT * FROM partidos.Alineacion
GO

-- Esperado: ya cargo el jugador en ese partido, 0 filas nuevas
DECLARE @aP2 INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
DECLARE @aT1b INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Ali Test T1');
EXEC SP.uspAlineacion_Registrar @IdPartido = @aP2, @IdJugador = @aT1b, @Rol = 'Titular'
GO
SELECT * FROM partidos.Alineacion
GO

-- Esperado: rol invalido (solo Titular o Suplente), 0 filas nuevas
DECLARE @aP3 INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
DECLARE @aT2 INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Ali Test T2');
EXEC SP.uspAlineacion_Registrar @IdPartido = @aP3, @IdJugador = @aT2, @Rol = 'Arquero'
GO
SELECT * FROM partidos.Alineacion
GO

-- Esperado: partido inexistente (99), 0 filas nuevas
DECLARE @aT2b INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Ali Test T2');
EXEC SP.uspAlineacion_Registrar @IdPartido = 99, @IdJugador = @aT2b, @Rol = 'Suplente'
GO
SELECT * FROM partidos.Alineacion
GO

-- Esperado: jugador inexistente (99), 0 filas nuevas
DECLARE @aP4 INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
EXEC SP.uspAlineacion_Registrar @IdPartido = @aP4, @IdJugador = 99, @Rol = 'Suplente'
GO
SELECT * FROM partidos.Alineacion
GO

-- Esperado: la seleccion del jugador (CONF A3) no juega este partido, 0 filas nuevas
DECLARE @aP5 INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
DECLARE @aNA INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Ali Test NA');
EXEC SP.uspAlineacion_Registrar @IdPartido = @aP5, @IdJugador = @aNA, @Rol = 'Suplente'
GO
SELECT * FROM partidos.Alineacion
GO

-- Esperado: alinea a T2 como suplente, 2 filas
DECLARE @aP6 INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
DECLARE @aT2c INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Ali Test T2');
EXEC SP.uspAlineacion_Registrar @IdPartido = @aP6, @IdJugador = @aT2c, @Rol = 'Suplente'
GO
SELECT * FROM partidos.Alineacion
GO

--/BAJA

-- Esperado: borra la alineacion de T1, queda 1 fila
DECLARE @aPb INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
DECLARE @aT1c INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Ali Test T1');
EXEC SP.uspAlineacion_Bajar @IdPartido = @aPb, @IdJugador = @aT1c
GO
SELECT * FROM partidos.Alineacion
GO

-- Esperado: inexistente, 0 borradas
DECLARE @aPc INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
EXEC SP.uspAlineacion_Bajar @IdPartido = @aPc, @IdJugador = 99
GO
SELECT * FROM partidos.Alineacion
GO

--/Limpieza de lo que genera el test (en orden, por las claves foraneas)
--Todo en un solo bloque para no perder las variables. Cada loop tiene su propio contador y tope.

DECLARE @aId INT, @aAux1 INT, @aAux2 INT, @i INT = 0;

--1) Las alineaciones de los jugadores del test.
WHILE @i < 10
BEGIN
	SELECT TOP (1) @aAux1 = A.IdPartido, @aAux2 = A.IdJugador
		FROM partidos.Alineacion A
		INNER JOIN equipos.Persona P ON P.IdPersona = A.IdJugador
		WHERE P.Nombre LIKE 'Ali Test%';
	IF @aAux1 IS NULL BREAK;
	EXEC SP.uspAlineacion_Bajar @IdPartido = @aAux1, @IdJugador = @aAux2;
	SET @i = @i + 1;
END

--2) Los jugadores del test.
SET @i = 0;
WHILE @i < 10
BEGIN
	SET @aId = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre LIKE 'Ali Test%');
	IF @aId IS NULL BREAK;
	EXEC SPTRANS.uspJugador_Bajar @id = @aId;
	SET @i = @i + 1;
END

--3) El partido y la fase.
DECLARE @aPartB INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
IF @aPartB IS NOT NULL
	EXEC SP.uspPartido_Bajar @Id = @aPartB;

DECLARE @aFaseB INT = (SELECT MIN(IdFase) FROM partidos.Fase WHERE Descripcion = 'Grupos');
IF @aFaseB IS NOT NULL
	EXEC SP.uspFase_Bajar @Id = @aFaseB;

--4) La sede, el huso horario, las selecciones, el grupo, el mundial y los paises.
DECLARE @aSedeB INT = (SELECT MIN(IdSede) FROM sedes.Sede WHERE Nombre = 'Sede Test A');
IF @aSedeB IS NOT NULL
	EXEC SP.uspSede_Bajar @idSede = @aSedeB;

DECLARE @aHusoB INT = (SELECT MIN(IdHuso) FROM sedes.HusoHorario WHERE Nombre = 'UTC-3 (A)');
IF @aHusoB IS NOT NULL
	EXEC SP.uspHusoHorario_Bajar @idHuso = @aHusoB;

SET @i = 0;
WHILE @i < 5
BEGIN
	SET @aId = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION LIKE 'CONF A%');
	IF @aId IS NULL BREAK;
	EXEC SP.uspSeleccion_Bajar @idSeleccion = @aId;
	SET @i = @i + 1;
END

DECLARE @aGrupoB INT = (SELECT MIN(IdGrupo) FROM equipos.Grupo WHERE NOMBRE = 'Grupo T');
IF @aGrupoB IS NOT NULL
	EXEC SP.uspGrupo_Bajar @id = @aGrupoB;

DECLARE @aPaisE INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test A1');
DECLARE @aMundialB INT = (SELECT MIN(IdMundial) FROM sedes.Mundial WHERE IdPais = @aPaisE);
IF @aMundialB IS NOT NULL
	EXEC SP.uspMundial_Bajar @id = @aMundialB;

SET @i = 0;
WHILE @i < 5
BEGIN
	SET @aId = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE LIKE 'Pais Test A%');
	IF @aId IS NULL BREAK;
	EXEC SP.uspPais_Bajar @idPais = @aId;
	SET @i = @i + 1;
END

-- Esperado: no queda nada del test.
SELECT * FROM partidos.Alineacion;
SELECT * FROM equipos.Jugador;
GO
