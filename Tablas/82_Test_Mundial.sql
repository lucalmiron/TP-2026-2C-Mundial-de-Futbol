--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Objetivo: Testear Registro, Update y Baja de Mundial

--Los objetos de negocio (TABLAS y SP) viven en MUNDIAL, el test se ejecuta contra ellos.
--El test arma su propio juego de datos y lo borra al final, asi se puede ejecutar mas de una vez.
--El segundo mundial queda con una seleccion para probar que la baja se bloquea.
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END
GO

--/Datos de prueba

-- Esperado: se crean los dos paises.
IF NOT EXISTS (SELECT 1 FROM equipos.Pais WHERE NOMBRE = 'Pais Test M1')
	EXEC SP.uspPais_Registrar @nombre = 'Pais Test M1', @pbi = 82;
GO
IF NOT EXISTS (SELECT 1 FROM equipos.Pais WHERE NOMBRE = 'Pais Test M2')
	EXEC SP.uspPais_Registrar @nombre = 'Pais Test M2', @pbi = 83;
GO

-- Esperado: se crea el grupo.
IF NOT EXISTS (SELECT 1 FROM equipos.Grupo WHERE NOMBRE = 'Grupo M')
	EXEC SP.uspGrupo_Registrar @nombre = 'Grupo M';
GO

--/ALTA

DECLARE @mPais1 INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test M1');

-- Esperado: inserta 1 fila (Pais M1, 2026-06-11 a 2026-07-19)
IF NOT EXISTS (SELECT 1 FROM sedes.Mundial WHERE IdPais = @mPais1)
	EXEC SP.uspMundial_Registrar @idPais = @mPais1, @fechaInicio = '2026-06-11', @fechaFin = '2026-07-19',
		@tamMin = 23, @tamMax = 26, @ventanas = 5, @cantidad = 5, @suspMax = 2, @suspTiempo = 1
GO
SELECT * FROM sedes.Mundial
GO

-- Esperado: pais inexistente (99), 0 filas nuevas
EXEC SP.uspMundial_Registrar @idPais = 99, @fechaInicio = '2026-06-11', @fechaFin = '2026-07-19',
	@tamMin = 23, @tamMax = 26, @ventanas = 5, @cantidad = 5, @suspMax = 2, @suspTiempo = 1
GO
SELECT * FROM sedes.Mundial
GO

DECLARE @mPais1b INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test M1');

-- Esperado: fin anterior a inicio, 0 filas nuevas
EXEC SP.uspMundial_Registrar @idPais = @mPais1b, @fechaInicio = '2026-07-19', @fechaFin = '2026-06-11',
	@tamMin = 23, @tamMax = 26, @ventanas = 5, @cantidad = 5, @suspMax = 2, @suspTiempo = 1
GO
SELECT * FROM sedes.Mundial
GO

DECLARE @mPais1c INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test M1');

-- Esperado: minimo mayor que maximo, 0 filas nuevas
EXEC SP.uspMundial_Registrar @idPais = @mPais1c, @fechaInicio = '2026-06-11', @fechaFin = '2026-07-19',
	@tamMin = 26, @tamMax = 23, @ventanas = 5, @cantidad = 5, @suspMax = 2, @suspTiempo = 1
GO
SELECT * FROM sedes.Mundial
GO

DECLARE @mPais1d INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test M1');

-- Esperado: ventanas invalido (0), 0 filas nuevas
EXEC SP.uspMundial_Registrar @idPais = @mPais1d, @fechaInicio = '2026-06-11', @fechaFin = '2026-07-19',
	@tamMin = 23, @tamMax = 26, @ventanas = 0, @cantidad = 5, @suspMax = 2, @suspTiempo = 1
GO
SELECT * FROM sedes.Mundial
GO

DECLARE @mPais2 INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test M2');
DECLARE @mGrup  INT = (SELECT MIN(IdGrupo) FROM equipos.Grupo WHERE NOMBRE = 'Grupo M');

-- Esperado: inserta el segundo mundial (minimo de jugadores 0 para poder limpiar).
IF NOT EXISTS (SELECT 1 FROM sedes.Mundial WHERE IdPais = @mPais2)
	EXEC SP.uspMundial_Registrar @idPais = @mPais2, @fechaInicio = '2026-06-01', @fechaFin = '2026-07-30',
		@tamMin = 0, @tamMax = 23, @ventanas = 3, @cantidad = 5, @suspMax = 2, @suspTiempo = 1
GO
SELECT * FROM sedes.Mundial
GO

DECLARE @mPais2b INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test M2');
DECLARE @mMund2  INT = (SELECT MIN(IdMundial) FROM sedes.Mundial WHERE IdPais = @mPais2b);
DECLARE @mGrup2  INT = (SELECT MIN(IdGrupo) FROM equipos.Grupo WHERE NOMBRE = 'Grupo M');

-- Esperado: se crea una seleccion que usa el segundo mundial.
IF NOT EXISTS (SELECT 1 FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF GM')
	EXEC SP.uspSeleccion_Registrar @idPais = @mPais2b, @idMundial = @mMund2, @idGrupo = @mGrup2, @confederacion = 'CONF GM';
GO

--/UPDATE

DECLARE @mMund1 INT = (SELECT MIN(IdMundial) FROM sedes.Mundial WHERE IdPais = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test M1'));

-- Esperado: update parcial (tiempo de suspension a 2), SELECT muestra 2
EXEC SP.uspMundial_Update @id = @mMund1, @suspTiempo = 2
GO
SELECT * FROM sedes.Mundial
GO

-- Esperado: fin anterior a inicio en update, 0 filas modificadas
DECLARE @mMund1 INT = (SELECT MIN(IdMundial) FROM sedes.Mundial WHERE IdPais = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test M1'));
EXEC SP.uspMundial_Update @id = @mMund1, @fechaFin = '2026-01-01'
GO
SELECT * FROM sedes.Mundial
GO

-- Esperado: id invalido (0)
EXEC SP.uspMundial_Update @id = 0, @suspTiempo = 2
GO
SELECT * FROM sedes.Mundial
GO

-- Esperado: id inexistente (99)
EXEC SP.uspMundial_Update @id = 99, @suspTiempo = 2
GO
SELECT * FROM sedes.Mundial
GO

--/BAJA

-- Esperado: el segundo mundial tiene una seleccion, no se puede borrar
DECLARE @mMund2 INT = (SELECT MIN(IdMundial) FROM sedes.Mundial WHERE IdPais = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test M2'));
EXEC SP.uspMundial_Bajar @id = @mMund2
GO
SELECT * FROM sedes.Mundial
GO

-- Esperado: borra el primer mundial
DECLARE @mMund1 INT = (SELECT MIN(IdMundial) FROM sedes.Mundial WHERE IdPais = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test M1'));
EXEC SP.uspMundial_Bajar @id = @mMund1
GO
SELECT * FROM sedes.Mundial
GO

-- Esperado: id inexistente (99), 0 borradas
EXEC SP.uspMundial_Bajar 99
GO
SELECT * FROM sedes.Mundial
GO

--/Limpieza de lo que genera el test (en orden, por las claves foraneas)

DECLARE @mId INT, @mSel INT, @i INT = 0;

WHILE @i < 5
BEGIN
	SET @mSel = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF GM');
	IF @mSel IS NULL BREAK;
	EXEC SP.uspSeleccion_Bajar @idSeleccion = @mSel;
	SET @i = @i + 1;
END

DECLARE @mMundB INT = (SELECT MIN(IdMundial) FROM sedes.Mundial WHERE IdPais IN (SELECT IdPais FROM equipos.Pais WHERE NOMBRE IN ('Pais Test M1','Pais Test M2')));
IF @mMundB IS NOT NULL
	EXEC SP.uspMundial_Bajar @id = @mMundB;

DECLARE @mGrupB INT = (SELECT MIN(IdGrupo) FROM equipos.Grupo WHERE NOMBRE = 'Grupo M');
IF @mGrupB IS NOT NULL
	EXEC SP.uspGrupo_Bajar @id = @mGrupB;

SET @i = 0;
WHILE @i < 5
BEGIN
	SET @mId = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE IN ('Pais Test M1','Pais Test M2'));
	IF @mId IS NULL BREAK;
	EXEC SP.uspPais_Bajar @idPais = @mId;
	SET @i = @i + 1;
END

-- Esperado: no queda nada del test.
SELECT * FROM sedes.Mundial;
GO
