--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 21/10/2026

--Objetivo: Testear Registro, Update y Baja de Grupo

--Los objetos de negocio (TABLAS y SP) viven en MUNDIAL, el test se ejecuta contra ellos.
--El test arma su propio juego de datos y lo borra al final, asi se puede ejecutar mas de una vez.
--El grupo Q queda con una seleccion para probar que la baja se bloquea.
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END
GO

--/Datos de prueba

-- Esperado: se crea el pais.
IF NOT EXISTS (SELECT 1 FROM equipos.Pais WHERE NOMBRE = 'Pais Test G1')
	EXEC SP.uspPais_Registrar @nombre = 'Pais Test G1', @pbi = 81;
GO

DECLARE @gPais INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test G1');

-- Esperado: se crea el mundial (minimo de jugadores 0 para poder limpiar).
IF NOT EXISTS (SELECT 1 FROM sedes.Mundial WHERE IdPais = @gPais)
	EXEC SP.uspMundial_Registrar @idPais = @gPais, @fechaInicio = '2026-06-01', @fechaFin = '2026-07-30',
		@tamMin = 0, @tamMax = 23, @ventanas = 3, @cantidad = 5, @suspMax = 2, @suspTiempo = 1;
GO

-- Esperado: se crea el grupo Q.
IF NOT EXISTS (SELECT 1 FROM equipos.Grupo WHERE NOMBRE = 'Grupo Q')
	EXEC SP.uspGrupo_Registrar @nombre = 'Grupo Q';
GO

DECLARE @gPais2 INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test G1');
DECLARE @gMund  INT = (SELECT MIN(IdMundial) FROM sedes.Mundial WHERE IdPais = @gPais2);
DECLARE @gGrupo INT = (SELECT MIN(IdGrupo) FROM equipos.Grupo WHERE NOMBRE = 'Grupo Q');

-- Esperado: se crea una seleccion que usa el grupo Q.
IF NOT EXISTS (SELECT 1 FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF GQ')
	EXEC SP.uspSeleccion_Registrar @idPais = @gPais2, @idMundial = @gMund, @idGrupo = @gGrupo, @confederacion = 'CONF GQ';
GO

--/ALTA

-- Esperado: inserta Grupo R, 1 fila nueva
EXEC SP.uspGrupo_Registrar 'Grupo R'
GO
SELECT * FROM equipos.Grupo
GO

-- Esperado: nombre nulo, 0 filas nuevas
EXEC SP.uspGrupo_Registrar NULL
GO
SELECT * FROM equipos.Grupo
GO

-- Esperado: duplicado, 0 filas nuevas
EXEC SP.uspGrupo_Registrar 'Grupo Q'
GO
SELECT * FROM equipos.Grupo
GO

--/UPDATE

DECLARE @gQ INT = (SELECT MIN(IdGrupo) FROM equipos.Grupo WHERE NOMBRE = 'Grupo Q');
DECLARE @gR INT = (SELECT MIN(IdGrupo) FROM equipos.Grupo WHERE NOMBRE = 'Grupo R');

-- Esperado: cambia Q a Q2, SELECT muestra Grupo Q2
EXEC SP.uspGrupo_Update @gQ, 'Grupo Q2'
GO
SELECT * FROM equipos.Grupo
GO

-- Esperado: duplicado (R ya existe), 0 filas modificadas
DECLARE @gQ INT = (SELECT MIN(IdGrupo) FROM equipos.Grupo WHERE NOMBRE = 'Grupo Q2');
EXEC SP.uspGrupo_Update @gQ, 'Grupo R'
GO
SELECT * FROM equipos.Grupo
GO

-- Esperado: id invalido (0)
EXEC SP.uspGrupo_Update 0, 'Grupo Q2'
GO
SELECT * FROM equipos.Grupo
GO

-- Esperado: id inexistente (99)
EXEC SP.uspGrupo_Update 99, 'Grupo Q2'
GO
SELECT * FROM equipos.Grupo
GO

--/BAJA

-- Esperado: el grupo Q2 tiene una seleccion, no se puede borrar
DECLARE @gQ INT = (SELECT MIN(IdGrupo) FROM equipos.Grupo WHERE NOMBRE = 'Grupo Q2');
EXEC SP.uspGrupo_Bajar @gQ
GO
SELECT * FROM equipos.Grupo
GO

-- Esperado: borra el grupo R
DECLARE @gR INT = (SELECT MIN(IdGrupo) FROM equipos.Grupo WHERE NOMBRE = 'Grupo R');
EXEC SP.uspGrupo_Bajar @gR
GO
SELECT * FROM equipos.Grupo
GO

-- Esperado: id inexistente (99), 0 borradas
EXEC SP.uspGrupo_Bajar 99
GO
SELECT * FROM equipos.Grupo
GO

--/Limpieza de lo que genera el test (en orden, por las claves foraneas)

DECLARE @gId INT, @gSel INT, @i INT = 0;

WHILE @i < 5
BEGIN
	SET @gSel = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF GQ');
	IF @gSel IS NULL BREAK;
	EXEC SP.uspSeleccion_Bajar @idSeleccion = @gSel;
	SET @i = @i + 1;
END

DECLARE @gQB INT = (SELECT MIN(IdGrupo) FROM equipos.Grupo WHERE NOMBRE = 'Grupo Q2');
IF @gQB IS NOT NULL
	EXEC SP.uspGrupo_Bajar @id = @gQB;

DECLARE @gMundB INT = (SELECT MIN(IdMundial) FROM sedes.Mundial WHERE IdPais = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test G1'));
IF @gMundB IS NOT NULL
	EXEC SP.uspMundial_Bajar @id = @gMundB;

DECLARE @gPaisB INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test G1');
IF @gPaisB IS NOT NULL
	EXEC SP.uspPais_Bajar @idPais = @gPaisB;

-- Esperado: no queda nada del test.
SELECT * FROM equipos.Grupo;
GO
