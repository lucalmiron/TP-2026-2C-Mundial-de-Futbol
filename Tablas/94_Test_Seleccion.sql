--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 08/10/2026

--Test de los SP de Seleccion (se ejecutan los SP reales de MUNDIAL)
--Nota: cada bloque vuelve a declarar sus variables porque un GO corta el ambito.

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

--/Datos de prueba: 5 paises (para probar el cupo de 4 selecciones por grupo)

IF NOT EXISTS (SELECT 1 FROM equipos.Pais WHERE NOMBRE = 'Pais Test S1')
	EXEC SP.uspPais_Registrar @nombre = 'Pais Test S1', @pbi = 1;
GO
IF NOT EXISTS (SELECT 1 FROM equipos.Pais WHERE NOMBRE = 'Pais Test S2')
	EXEC SP.uspPais_Registrar @nombre = 'Pais Test S2', @pbi = 2;
GO
IF NOT EXISTS (SELECT 1 FROM equipos.Pais WHERE NOMBRE = 'Pais Test S3')
	EXEC SP.uspPais_Registrar @nombre = 'Pais Test S3', @pbi = 3;
GO
IF NOT EXISTS (SELECT 1 FROM equipos.Pais WHERE NOMBRE = 'Pais Test S4')
	EXEC SP.uspPais_Registrar @nombre = 'Pais Test S4', @pbi = 4;
GO
IF NOT EXISTS (SELECT 1 FROM equipos.Pais WHERE NOMBRE = 'Pais Test S5')
	EXEC SP.uspPais_Registrar @nombre = 'Pais Test S5', @pbi = 5;
GO

DECLARE @idPaisS1 INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test S1');

-- Esperado: no imprime nada, se inserta 1 mundial.
IF NOT EXISTS (SELECT 1 FROM sedes.Mundial)
	EXEC SP.uspMundial_Registrar @idPais = @idPaisS1, @fechaInicio = '2026-06-01', @fechaFin = '2026-07-30',
		@tamMin = 11, @tamMax = 23, @ventanas = 3, @cantidad = 5, @suspMax = 2, @suspTiempo = 1;
GO

DECLARE @idPaisS1b INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test S1');
IF NOT EXISTS (SELECT 1 FROM equipos.Grupo WHERE NOMBRE = 'Grupo S')
	EXEC SP.uspGrupo_Registrar @nombre = 'Grupo S';
GO

-- Esperado: 5 paises, 1 mundial y 1 grupo creados por el test.
SELECT * FROM equipos.Pais WHERE NOMBRE LIKE 'Pais Test S%';
SELECT * FROM sedes.Mundial;
SELECT * FROM equipos.Grupo WHERE NOMBRE = 'Grupo S';
GO

--/ALTA

-- Esperado: imprime 'Error/es: - Valor inexistente: Pais.'
DECLARE @idMundialA INT = (SELECT MIN(IdMundial) FROM sedes.Mundial);
DECLARE @idGrupoA   INT = (SELECT MIN(IdGrupo) FROM equipos.Grupo WHERE NOMBRE = 'Grupo S');
EXEC SP.uspSeleccion_Registrar @idPais = 999999, @idMundial = @idMundialA, @idGrupo = @idGrupoA, @confederacion = 'CONF';
GO

-- Esperado: imprime 'Error/es: - Valor inexistente: Mundial.'
DECLARE @idGrupoB   INT = (SELECT MIN(IdGrupo) FROM equipos.Grupo WHERE NOMBRE = 'Grupo S');
DECLARE @idPaisS1c  INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test S1');
EXEC SP.uspSeleccion_Registrar @idPais = @idPaisS1c, @idMundial = 999999, @idGrupo = @idGrupoB, @confederacion = 'CONF';
GO

-- Esperado: imprime 'Error/es: - Valor inexistente: Grupo.'
DECLARE @idMundialB INT = (SELECT MIN(IdMundial) FROM sedes.Mundial);
DECLARE @idPaisS1d  INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test S1');
EXEC SP.uspSeleccion_Registrar @idPais = @idPaisS1d, @idMundial = @idMundialB, @idGrupo = 999999, @confederacion = 'CONF';
GO

-- Esperado: imprime 'Error/es: - Valor invalido: Confederacion.'
DECLARE @idMundialC INT = (SELECT MIN(IdMundial) FROM sedes.Mundial);
DECLARE @idGrupoC   INT = (SELECT MIN(IdGrupo) FROM equipos.Grupo WHERE NOMBRE = 'Grupo S');
DECLARE @idPaisS1e  INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test S1');
EXEC SP.uspSeleccion_Registrar @idPais = @idPaisS1e, @idMundial = @idMundialC, @idGrupo = @idGrupoC, @confederacion = '';
GO

-- Esperado: no imprime nada, se inserta la seleccion 1.
DECLARE @idMundialD INT = (SELECT MIN(IdMundial) FROM sedes.Mundial);
DECLARE @idGrupoD   INT = (SELECT MIN(IdGrupo) FROM equipos.Grupo WHERE NOMBRE = 'Grupo S');
DECLARE @idPaisS1f  INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test S1');
EXEC SP.uspSeleccion_Registrar @idPais = @idPaisS1f, @idMundial = @idMundialD, @idGrupo = @idGrupoD, @confederacion = 'CONF S1';
GO

-- Esperado: imprime 'Error/es: - Valor duplicado: Seleccion (pais y mundial).'
DECLARE @idMundialE INT = (SELECT MIN(IdMundial) FROM sedes.Mundial);
DECLARE @idGrupoE   INT = (SELECT MIN(IdGrupo) FROM equipos.Grupo WHERE NOMBRE = 'Grupo S');
DECLARE @idPaisS1g  INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test S1');
EXEC SP.uspSeleccion_Registrar @idPais = @idPaisS1g, @idMundial = @idMundialE, @idGrupo = @idGrupoE, @confederacion = 'CONF OTRA';
GO

--/Cupo: se completan las 4 selecciones del grupo y la 5ta debe rebotar

-- Esperado: no imprime nada, se inserta la seleccion 2.
DECLARE @idMundialF INT = (SELECT MIN(IdMundial) FROM sedes.Mundial);
DECLARE @idGrupoF   INT = (SELECT MIN(IdGrupo) FROM equipos.Grupo WHERE NOMBRE = 'Grupo S');
DECLARE @idPaisS2   INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test S2');
EXEC SP.uspSeleccion_Registrar @idPais = @idPaisS2, @idMundial = @idMundialF, @idGrupo = @idGrupoF, @confederacion = 'CONF S2';
GO

-- Esperado: no imprime nada, se inserta la seleccion 3.
DECLARE @idMundialG INT = (SELECT MIN(IdMundial) FROM sedes.Mundial);
DECLARE @idGrupoG   INT = (SELECT MIN(IdGrupo) FROM equipos.Grupo WHERE NOMBRE = 'Grupo S');
DECLARE @idPaisS3   INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test S3');
EXEC SP.uspSeleccion_Registrar @idPais = @idPaisS3, @idMundial = @idMundialG, @idGrupo = @idGrupoG, @confederacion = 'CONF S3';
GO

-- Esperado: no imprime nada, se inserta la seleccion 4.
DECLARE @idMundialH INT = (SELECT MIN(IdMundial) FROM sedes.Mundial);
DECLARE @idGrupoH   INT = (SELECT MIN(IdGrupo) FROM equipos.Grupo WHERE NOMBRE = 'Grupo S');
DECLARE @idPaisS4   INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test S4');
EXEC SP.uspSeleccion_Registrar @idPais = @idPaisS4, @idMundial = @idMundialH, @idGrupo = @idGrupoH, @confederacion = 'CONF S4';
GO

-- Esperado: imprime 'Error/es: - Cupo excedido: el grupo ya tiene 4 selecciones en el mundial.'
DECLARE @idMundialI INT = (SELECT MIN(IdMundial) FROM sedes.Mundial);
DECLARE @idGrupoI   INT = (SELECT MIN(IdGrupo) FROM equipos.Grupo WHERE NOMBRE = 'Grupo S');
DECLARE @idPaisS5   INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test S5');
EXEC SP.uspSeleccion_Registrar @idPais = @idPaisS5, @idMundial = @idMundialI, @idGrupo = @idGrupoI, @confederacion = 'CONF S5';
GO

-- Esperado: 4 filas (el cupo del grupo en el mundial es 4).
SELECT * FROM equipos.Seleccion;
GO

--/UPDATE

-- Esperado: la CONF S1 pasa a 'CONF S1 Modificada'.
DECLARE @idSel1 INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF S1');
EXEC SP.uspSeleccion_Update @idSeleccion = @idSel1, @confederacion = 'CONF S1 Modificada';
GO

-- Esperado: 1 fila con CONFEDERACION = CONF S1 Modificada.
SELECT * FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF S1 Modificada';
GO

-- Esperado: imprime 'Error/es: - Valor inexistente: ID Seleccion.'
EXEC SP.uspSeleccion_Update @idSeleccion = 999999, @confederacion = 'NO EXISTE';
GO

-- Esperado: imprime 'Error/es: - Valor duplicado: Seleccion (pais y mundial).'
DECLARE @idSel1b    INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF S1 Modificada');
DECLARE @idPaisS2b  INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test S2');
DECLARE @idMundialJ INT = (SELECT MIN(IdMundial) FROM sedes.Mundial);
EXEC SP.uspSeleccion_Update @idSeleccion = @idSel1b, @idPais = @idPaisS2b, @idMundial = @idMundialJ;
GO

--/BAJA

-- Esperado: imprime 'Error/es: - Valor inexistente: ID Seleccion.'
EXEC SP.uspSeleccion_Bajar @idSeleccion = 999999;
GO

-- Esperado: se borra la seleccion 4.
DECLARE @idSel4 INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF S4');
EXEC SP.uspSeleccion_Bajar @idSeleccion = @idSel4;
GO

-- Esperado: 3 filas.
SELECT * FROM equipos.Seleccion;
GO

--/Limpieza de lo que genera el test (todo en un solo bloque para no perder variables)

DECLARE @vSel INT, @vGrupo INT, @vMundial INT, @vPais INT, @i INT = 0;

WHILE @i < 10
BEGIN
	SET @vSel = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION LIKE 'CONF S%');
	IF @vSel IS NULL BREAK;
	EXEC SP.uspSeleccion_Bajar @idSeleccion = @vSel;
	SET @i = @i + 1;
END

SET @i = 0;
WHILE @i < 5
BEGIN
	SET @vGrupo = (SELECT MIN(IdGrupo) FROM equipos.Grupo WHERE NOMBRE = 'Grupo S');
	IF @vGrupo IS NULL BREAK;
	EXEC SP.uspGrupo_Bajar @id = @vGrupo;
	SET @i = @i + 1;
END

SET @i = 0;
WHILE @i < 5
BEGIN
	SET @vMundial = (SELECT MIN(IdMundial) FROM sedes.Mundial);
	IF @vMundial IS NULL BREAK;
	EXEC SP.uspMundial_Bajar @id = @vMundial;
	SET @i = @i + 1;
END

SET @i = 0;
WHILE @i < 10
BEGIN
	SET @vPais = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE LIKE 'Pais Test S%');
	IF @vPais IS NULL BREAK;
	EXEC SP.uspPais_Bajar @idPais = @vPais;
	SET @i = @i + 1;
END

-- Esperado: no quedan selecciones ni paises del test.
SELECT * FROM equipos.Seleccion;
SELECT * FROM equipos.Pais WHERE NOMBRE LIKE 'Pais Test%';
GO