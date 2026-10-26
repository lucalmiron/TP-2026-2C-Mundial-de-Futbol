-- Universidad Nacional de La Matanza
-- Bases de datos aplicada
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 26/10/26
-- Objetivo: Testear Registro y Baja de CambioConvocatoria

--Los objetos de negocio (TABLAS y SP) viven en MUNDIAL, el test se ejecuta contra ellos.
--El test arma su propio juego de datos y lo borra al final, asi se puede ejecutar mas de una vez.
--ATENCION: el caso valido (egreso activo + ingreso inactivo) NO se puede probar todavia.
--uspCambioConvocatoria_Registrar exige un ingreso con Estado 'Inactivo', pero
--uspJugador_Registrar siempre da de alta como 'Activo' y ningun SP deja uno inactivo
--(solo lo hace el propio cambio de convocatoria). Queda pendiente, ver el punto 4.2 del
--listado de la Entrega 6.
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END
GO

--/Datos de prueba

-- Esperado: se crea el pais.
IF NOT EXISTS (SELECT 1 FROM equipos.Pais WHERE NOMBRE = 'Pais Test 86')
	EXEC SP.uspPais_Registrar @nombre = 'Pais Test 86', @pbi = 88;
GO

DECLARE @ccPais INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test 86');

-- Esperado: se crea el mundial (minimo de jugadores 0 para poder limpiar).
IF NOT EXISTS (SELECT 1 FROM sedes.Mundial WHERE IdPais = @ccPais)
	EXEC SP.uspMundial_Registrar @idPais = @ccPais, @fechaInicio = '2026-06-01', @fechaFin = '2026-07-30',
		@tamMin = 0, @tamMax = 23, @ventanas = 3, @cantidad = 5, @suspMax = 2, @suspTiempo = 1;
GO

-- Esperado: se crea el grupo.
IF NOT EXISTS (SELECT 1 FROM equipos.Grupo WHERE NOMBRE = 'Grupo 86')
	EXEC SP.uspGrupo_Registrar @nombre = 'Grupo 86';
GO

DECLARE @ccPais2 INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test 86');
DECLARE @ccMund  INT = (SELECT MIN(IdMundial) FROM sedes.Mundial WHERE IdPais = @ccPais2);
DECLARE @ccGrup  INT = (SELECT MIN(IdGrupo) FROM equipos.Grupo WHERE NOMBRE = 'Grupo 86');

-- Esperado: se crea la seleccion.
IF NOT EXISTS (SELECT 1 FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF 86')
	EXEC SP.uspSeleccion_Registrar @idPais = @ccPais2, @idMundial = @ccMund, @idGrupo = @ccGrup, @confederacion = 'CONF 86';
GO

DECLARE @ccSel1 INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF 86');
DECLARE @ccP3   INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test 86');

-- Esperado: se registra el jugador que saldria (egreso).
IF NOT EXISTS (SELECT 1 FROM equipos.Persona WHERE Nombre = 'Jug Test 86 E')
	EXEC SPTRANS.uspJugador_Registrar @nombre = 'Jug Test 86 E', @fnac = '2003-02-01', @pais = @ccP3, @posicion = 'DEL', @numero = 4, @seleccion = @ccSel1;
GO

DECLARE @ccSel2 INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF 86');
DECLARE @ccP4   INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test 86');

-- Esperado: se registra el jugador que entraria (ingreso).
IF NOT EXISTS (SELECT 1 FROM equipos.Persona WHERE Nombre = 'Jug Test 86 I')
	EXEC SPTRANS.uspJugador_Registrar @nombre = 'Jug Test 86 I', @fnac = '2003-02-02', @pais = @ccP4, @posicion = 'MED', @numero = 5, @seleccion = @ccSel2;
GO

--/ALTA

DECLARE @ccSel3 INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF 86');
DECLARE @ccE INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Jug Test 86 E');
DECLARE @ccI INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Jug Test 86 I');

-- Esperado: egreso e ingreso iguales, 0 filas nuevas
EXEC SPTRANS.uspCambioConvocatoria_Registrar @ccSel3, @ccE, @ccE, '2026-06-01', 'Lesion muscular'
GO
SELECT * FROM equipos.CambioConvocatoria
GO

DECLARE @ccSel4 INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF 86');
DECLARE @ccE2 INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Jug Test 86 E');
DECLARE @ccI2 INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Jug Test 86 I');

-- Esperado: motivo nulo, 0 filas nuevas
EXEC SPTRANS.uspCambioConvocatoria_Registrar @ccSel4, @ccE2, @ccI2, '2026-06-01', NULL
GO
SELECT * FROM equipos.CambioConvocatoria
GO

DECLARE @ccSel5 INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF 86');
DECLARE @ccE3 INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Jug Test 86 E');
DECLARE @ccI3 INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Jug Test 86 I');

-- Esperado: el ingreso ya es un convocado activo, 0 filas nuevas
EXEC SPTRANS.uspCambioConvocatoria_Registrar @ccSel5, @ccE3, @ccI3, '2026-06-01', 'Lesion muscular'
GO
SELECT * FROM equipos.CambioConvocatoria
GO

DECLARE @ccSel6 INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF 86');
DECLARE @ccE4 INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Jug Test 86 E');
DECLARE @ccI4 INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Jug Test 86 I');

-- Esperado: seleccion inexistente (99), 0 filas nuevas
EXEC SPTRANS.uspCambioConvocatoria_Registrar 99, @ccE4, @ccI4, '2026-06-01', 'Lesion muscular'
GO
SELECT * FROM equipos.CambioConvocatoria
GO

DECLARE @ccSel7 INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF 86');
DECLARE @ccI5 INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Jug Test 86 I');

-- Esperado: el egreso no es un convocado activo (99), 0 filas nuevas
EXEC SPTRANS.uspCambioConvocatoria_Registrar @ccSel7, 99, @ccI5, '2026-06-01', 'Lesion muscular'
GO
SELECT * FROM equipos.CambioConvocatoria
GO

--/BAJA

-- Esperado: registro inexistente (99), 0 borradas
EXEC SPTRANS.uspCambioConvocatoria_Bajar 99
GO
SELECT * FROM equipos.CambioConvocatoria
GO

--/Limpieza de lo que genera el test (en orden, por las claves foraneas)

DECLARE @ccJ INT, @ci INT = 0;
WHILE @ci < 10
BEGIN
	SET @ccJ = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre LIKE 'Jug Test 86%');
	IF @ccJ IS NULL BREAK;
	EXEC SPTRANS.uspJugador_Bajar @id = @ccJ;
	SET @ci = @ci + 1;
END

DECLARE @ccId INT, @ccSelL INT, @cl INT = 0;
WHILE @cl < 5
BEGIN
	SET @ccSelL = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF 86');
	IF @ccSelL IS NULL BREAK;
	EXEC SP.uspSeleccion_Bajar @idSeleccion = @ccSelL;
	SET @cl = @cl + 1;
END

DECLARE @ccGrupB INT = (SELECT MIN(IdGrupo) FROM equipos.Grupo WHERE NOMBRE = 'Grupo 86');
IF @ccGrupB IS NOT NULL
	EXEC SP.uspGrupo_Bajar @id = @ccGrupB;

DECLARE @ccMundB INT = (SELECT MIN(IdMundial) FROM sedes.Mundial WHERE IdPais = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test 86'));
IF @ccMundB IS NOT NULL
	EXEC SP.uspMundial_Bajar @id = @ccMundB;

DECLARE @ccPaisB INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test 86');
IF @ccPaisB IS NOT NULL
	EXEC SP.uspPais_Bajar @idPais = @ccPaisB;

-- Esperado: no queda nada del test.
SELECT * FROM equipos.CambioConvocatoria;
GO
