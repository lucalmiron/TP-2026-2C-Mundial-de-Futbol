--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 08/10/2026

--Test de los SP transaccionales de Arbitraje (se ejecutan los SP reales de MUNDIAL)

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

--/Datos de prueba: 3 paises (dos que juegan el partido y uno neutral)

IF NOT EXISTS (SELECT 1 FROM equipos.Pais WHERE NOMBRE = 'Pais Test A1')
	EXEC SP.uspPais_Registrar @nombre = 'Pais Test A1', @pbi = 11;
GO
IF NOT EXISTS (SELECT 1 FROM equipos.Pais WHERE NOMBRE = 'Pais Test A2')
	EXEC SP.uspPais_Registrar @nombre = 'Pais Test A2', @pbi = 12;
GO
IF NOT EXISTS (SELECT 1 FROM equipos.Pais WHERE NOMBRE = 'Pais Test A3')
	EXEC SP.uspPais_Registrar @nombre = 'Pais Test A3', @pbi = 13;
GO

-- Esperado: no imprime nada, se inserta 1 mundial.
DECLARE @idPaisA1m INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test A1');

IF NOT EXISTS (SELECT 1 FROM sedes.Mundial WHERE IdPais = @idPaisA1m)
	EXEC SP.uspMundial_Registrar @idPais = @idPaisA1m, @fechaInicio = '2026-06-01', @fechaFin = '2026-07-30',
		@tamMin = 11, @tamMax = 23, @ventanas = 3, @cantidad = 5, @suspMax = 2, @suspTiempo = 1;
GO

-- Esperado: no imprime nada, se inserta 1 grupo.
IF NOT EXISTS (SELECT 1 FROM equipos.Grupo WHERE NOMBRE = 'Grupo A')
	EXEC SP.uspGrupo_Registrar @nombre = 'Grupo A';
GO

DECLARE @idPaisA1s INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test A1');
DECLARE @idMundialA INT = (SELECT MIN(IdMundial) FROM sedes.Mundial WHERE IdPais = @idPaisA1s);
DECLARE @idGrupoA INT = (SELECT MIN(IdGrupo) FROM equipos.Grupo WHERE NOMBRE = 'Grupo A');
DECLARE @idPaisA1b INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test A1');

-- Esperado: no imprime nada, se insertan 2 selecciones (los dos paises que juegan).
IF NOT EXISTS (SELECT 1 FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF A1')
	EXEC SP.uspSeleccion_Registrar @idPais = @idPaisA1b, @idMundial = @idMundialA, @idGrupo = @idGrupoA, @confederacion = 'CONF A1';
GO

DECLARE @idPaisA1t INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test A1');
DECLARE @idMundialA2 INT = (SELECT MIN(IdMundial) FROM sedes.Mundial WHERE IdPais = @idPaisA1t);
DECLARE @idGrupoA2 INT = (SELECT MIN(IdGrupo) FROM equipos.Grupo WHERE NOMBRE = 'Grupo A');
DECLARE @idPaisA2c INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test A2');

IF NOT EXISTS (SELECT 1 FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF A2')
	EXEC SP.uspSeleccion_Registrar @idPais = @idPaisA2c, @idMundial = @idMundialA2, @idGrupo = @idGrupoA2, @confederacion = 'CONF A2';
GO

-- Esperado: no imprime nada, se inserta 1 huso horario y 1 sede.
DECLARE @idPaisA1c INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test A1');

IF NOT EXISTS (SELECT 1 FROM sedes.HusoHorario WHERE Nombre = 'UTC-3 (A)')
	EXEC SP.uspHusoHorario_Registrar @nombre = 'UTC-3 (A)', @idPais = @idPaisA1c;
GO

DECLARE @idHusoA INT = (SELECT MIN(IdHuso) FROM sedes.HusoHorario WHERE Nombre = 'UTC-3 (A)');
DECLARE @idPaisA1d INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test A1');

IF NOT EXISTS (SELECT 1 FROM sedes.Sede WHERE Nombre = 'Sede Test A')
	EXEC SP.uspSede_Registrar @nombre = 'Sede Test A', @ciudad = 'Ciudad Test A', @capacidad = 50000, @pais = @idPaisA1d, @huso = @idHusoA;
GO

-- Esperado: no imprime nada, se inserta 1 fase.
IF NOT EXISTS (SELECT 1 FROM partidos.Fase WHERE Descripcion = 'Grupos')
	EXEC SP.uspFase_Registrar @Descripcion = 'Grupos';
GO

DECLARE @idSedeA INT = (SELECT MIN(IdSede) FROM sedes.Sede WHERE Nombre = 'Sede Test A');
DECLARE @idFaseA INT = (SELECT MIN(IdFase) FROM partidos.Fase WHERE Descripcion = 'Grupos');
DECLARE @idPaisA1u INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test A1');
DECLARE @idMundialA3 INT = (SELECT MIN(IdMundial) FROM sedes.Mundial WHERE IdPais = @idPaisA1u);
DECLARE @idSelA1 INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF A1');
DECLARE @idSelA2 INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF A2');

-- Esperado: no imprime nada, se inserta 1 partido.
IF NOT EXISTS (SELECT 1 FROM partidos.Partido WHERE IdFase = @idFaseA AND Eq1 = @idSelA1 AND Eq2 = @idSelA2)
	EXEC SP.uspPartido_Registrar @IdFase = @idFaseA, @IdSede = @idSedeA, @IdMundial = @idMundialA3,
		@Eq1 = @idSelA1, @Eq2 = @idSelA2, @Fecha = '2026-06-15', @HoraUTC = '16:00', @HoraLocal = '13:00';
GO

-- Esperado: no imprime nada, se registran 3 arbitros (2 neutros y 1 del pais que juega).
DECLARE @idPaisA3b INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test A3');

IF NOT EXISTS (SELECT 1 FROM equipos.Persona WHERE Nombre = 'Arbitro Test Neutral 1')
	EXEC SPTRANS.uspArbitro_Registrar @nombre = 'Arbitro Test Neutral 1', @fnac = '1980-01-01', @pais = @idPaisA3b, @categoria = 'FIFA';
GO

DECLARE @idPaisA3c INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test A3');

IF NOT EXISTS (SELECT 1 FROM equipos.Persona WHERE Nombre = 'Arbitro Test Neutral 2')
	EXEC SPTRANS.uspArbitro_Registrar @nombre = 'Arbitro Test Neutral 2', @fnac = '1985-02-02', @pais = @idPaisA3c, @categoria = 'FIFA';
GO

DECLARE @idPaisA1f INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test A1');

IF NOT EXISTS (SELECT 1 FROM equipos.Persona WHERE Nombre = 'Arbitro Test Local')
	EXEC SPTRANS.uspArbitro_Registrar @nombre = 'Arbitro Test Local', @fnac = '1975-03-03', @pais = @idPaisA1f, @categoria = 'FIFA';
GO

SELECT * FROM arbitros.Arbitro;
GO

--/ALTA

DECLARE @idArbNeutro1 INT = (SELECT MIN(IdArbitro) FROM arbitros.Arbitro INNER JOIN equipos.Persona ON IdPersona = IdArbitro WHERE Nombre = 'Arbitro Test Neutral 1');
DECLARE @idArbNeutro2 INT = (SELECT MIN(IdArbitro) FROM arbitros.Arbitro INNER JOIN equipos.Persona ON IdPersona = IdArbitro WHERE Nombre = 'Arbitro Test Neutral 2');
DECLARE @idArbLocal   INT = (SELECT MIN(IdArbitro) FROM arbitros.Arbitro INNER JOIN equipos.Persona ON IdPersona = IdArbitro WHERE Nombre = 'Arbitro Test Local');
DECLARE @idPartidoA   INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
SELECT @idArbNeutro1 AS Neutro1, @idArbNeutro2 AS Neutro2, @idArbLocal AS Local, @idPartidoA AS Partido;
GO

-- Esperado: imprime 'Error/es: - Valor invalido: Funcion.'
DECLARE @idArbN1 INT = (SELECT MIN(IdArbitro) FROM arbitros.Arbitro INNER JOIN equipos.Persona ON IdPersona = IdArbitro WHERE Nombre = 'Arbitro Test Neutral 1');
DECLARE @idPartA1 INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
EXEC SPTRANS.uspArbitraje_Registrar @arbitro = @idArbN1, @funcion = 'Cuarto Arbitro', @partido = @idPartA1;
GO

-- Esperado: imprime 'Error/es: - Valor inexistente: ID Arbitro.'
DECLARE @idPartA2 INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
EXEC SPTRANS.uspArbitraje_Registrar @arbitro = 999999, @funcion = 'Principal', @partido = @idPartA2;
GO

-- Esperado: imprime 'Error/es: - Valor inexistente: ID Partido.'
DECLARE @idArbN1c INT = (SELECT MIN(IdArbitro) FROM arbitros.Arbitro INNER JOIN equipos.Persona ON IdPersona = IdArbitro WHERE Nombre = 'Arbitro Test Neutral 1');
EXEC SPTRANS.uspArbitraje_Registrar @arbitro = @idArbN1c, @funcion = 'Principal', @partido = 999999;
GO

-- Esperado: imprime 'Error/es: - No se puede asignar este arbitro, el pais al que pertenece disputa este partido.'
DECLARE @idArbLoc INT = (SELECT MIN(IdArbitro) FROM arbitros.Arbitro INNER JOIN equipos.Persona ON IdPersona = IdArbitro WHERE Nombre = 'Arbitro Test Local');
DECLARE @idPartA3 INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
EXEC SPTRANS.uspArbitraje_Registrar @arbitro = @idArbLoc, @funcion = 'VAR', @partido = @idPartA3;
GO

-- Esperado: no imprime nada, se asigna el Principal.
DECLARE @idArbN1d INT = (SELECT MIN(IdArbitro) FROM arbitros.Arbitro INNER JOIN equipos.Persona ON IdPersona = IdArbitro WHERE Nombre = 'Arbitro Test Neutral 1');
DECLARE @idPartA4 INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
EXEC SPTRANS.uspArbitraje_Registrar @arbitro = @idArbN1d, @funcion = 'Principal', @partido = @idPartA4;
GO

-- Esperado: 1 fila con Funcion = Principal.
SELECT * FROM arbitros.Arbitraje;
GO

-- Esperado: imprime 'Error/es: - Valor duplicado: Arbitro. Se encuentra ya asignado a alguna funcion de ese partido.'
DECLARE @idArbN1e INT = (SELECT MIN(IdArbitro) FROM arbitros.Arbitro INNER JOIN equipos.Persona ON IdPersona = IdArbitro WHERE Nombre = 'Arbitro Test Neutral 1');
DECLARE @idPartA5 INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
EXEC SPTRANS.uspArbitraje_Registrar @arbitro = @idArbN1e, @funcion = 'VAR', @partido = @idPartA5;
GO

--/Cupo por funcion

-- Esperado: imprime 'Error/es: - Cupo excedido para esa funcion.' (ya hay 1 Principal)
DECLARE @idArbN2a INT = (SELECT MIN(IdArbitro) FROM arbitros.Arbitro INNER JOIN equipos.Persona ON IdPersona = IdArbitro WHERE Nombre = 'Arbitro Test Neutral 2');
DECLARE @idPartA6 INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
EXEC SPTRANS.uspArbitraje_Registrar @arbitro = @idArbN2a, @funcion = 'Principal', @partido = @idPartA6;
GO

-- Esperado: no imprime nada, se asigna el Asistente.
DECLARE @idArbN2b INT = (SELECT MIN(IdArbitro) FROM arbitros.Arbitro INNER JOIN equipos.Persona ON IdPersona = IdArbitro WHERE Nombre = 'Arbitro Test Neutral 2');
DECLARE @idPartA7 INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
EXEC SPTRANS.uspArbitraje_Registrar @arbitro = @idArbN2b, @funcion = 'Asistente', @partido = @idPartA7;
GO

-- Esperado: 2 filas (Principal y Asistente).
SELECT * FROM arbitros.Arbitraje;
GO

--/UPDATE

-- Esperado: el Principal pasa a Asistente.
DECLARE @idArbN1f INT = (SELECT MIN(IdArbitro) FROM arbitros.Arbitro INNER JOIN equipos.Persona ON IdPersona = IdArbitro WHERE Nombre = 'Arbitro Test Neutral 1');
DECLARE @idPartA8 INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
EXEC SPTRANS.uspArbitraje_Update @arbitro = @idArbN1f, @funcion = 'Asistente', @partido = @idPartA8;
GO

-- Esperado: 2 filas, ambos con Funcion = Asistente.
SELECT * FROM arbitros.Arbitraje;
GO

--/BAJA

-- Esperado: imprime 'Error/es: - Registro inexistente.'
DECLARE @idPartA9 INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
EXEC SPTRANS.uspArbitraje_Bajar @arbitro = 999999, @partido = @idPartA9;
GO

-- Esperado: se borra la fila del arbitro neutral 2.
DECLARE @idArbN2c INT = (SELECT MIN(IdArbitro) FROM arbitros.Arbitro INNER JOIN equipos.Persona ON IdPersona = IdArbitro WHERE Nombre = 'Arbitro Test Neutral 2');
DECLARE @idPartA10 INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
EXEC SPTRANS.uspArbitraje_Bajar @arbitro = @idArbN2c, @partido = @idPartA10;
GO

-- Esperado: 1 fila.
SELECT * FROM arbitros.Arbitraje;
GO

--/Limpieza de lo que genera el test (en orden, por las claves foraneas)
--Todo en un solo bloque para no perder las variables. Cada loop tiene su propio contador y tope.

--1) Las asignaciones de arbitraje del test.
DECLARE @vArb INT, @vPart INT, @i INT = 0;

WHILE @i < 10
BEGIN
	SET @vArb = (SELECT MIN(IdArbitro) FROM arbitros.Arbitro INNER JOIN equipos.Persona ON IdPersona = IdArbitro
		WHERE Nombre LIKE 'Arbitro Test%' AND EXISTS (SELECT 1 FROM arbitros.Arbitraje WHERE Arbitro = IdArbitro));
	IF @vArb IS NULL BREAK;

	SET @vPart = (SELECT MIN(Partido) FROM arbitros.Arbitraje WHERE Arbitro = @vArb);
	EXEC SPTRANS.uspArbitraje_Bajar @arbitro = @vArb, @partido = @vPart;
	SET @i = @i + 1;
END

--2) Los arbitros del test.
SET @i = 0;
WHILE @i < 5
BEGIN
	SET @vArb = (SELECT MIN(IdArbitro) FROM arbitros.Arbitro INNER JOIN equipos.Persona ON IdPersona = IdArbitro WHERE Nombre LIKE 'Arbitro Test%');
	IF @vArb IS NULL BREAK;
	EXEC SPTRANS.uspArbitro_Bajar @id = @vArb;
	SET @i = @i + 1;
END

--3) El partido, la fase, la sede y el huso horario.
DECLARE @vPartido INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
IF @vPartido IS NOT NULL
	EXEC SP.uspPartido_Bajar @Id = @vPartido;

DECLARE @vFase INT = (SELECT MIN(IdFase) FROM partidos.Fase WHERE Descripcion = 'Grupos');
IF @vFase IS NOT NULL
	EXEC SP.uspFase_Bajar @Id = @vFase;

DECLARE @vSede INT = (SELECT MIN(IdSede) FROM sedes.Sede WHERE Nombre = 'Sede Test A');
IF @vSede IS NOT NULL
	EXEC SP.uspSede_Bajar @idSede = @vSede;

DECLARE @vHuso INT = (SELECT MIN(IdHuso) FROM sedes.HusoHorario WHERE Nombre = 'UTC-3 (A)');
IF @vHuso IS NOT NULL
	EXEC SP.uspHusoHorario_Bajar @idHuso = @vHuso;

--4) Las selecciones del test.
DECLARE @vSel INT;
SET @i = 0;
WHILE @i < 5
BEGIN
	SET @vSel = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION LIKE 'CONF A%');
	IF @vSel IS NULL BREAK;
	EXEC SP.uspSeleccion_Bajar @idSeleccion = @vSel;
	SET @i = @i + 1;
END

--5) El grupo, el mundial y los paises.
DECLARE @vGrupo INT = (SELECT MIN(IdGrupo) FROM equipos.Grupo WHERE NOMBRE = 'Grupo A');
IF @vGrupo IS NOT NULL
	EXEC SP.uspGrupo_Bajar @id = @vGrupo;

DECLARE @vPais INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test A1');
DECLARE @vMundial INT = (SELECT MIN(IdMundial) FROM sedes.Mundial WHERE IdPais = @vPais);
IF @vMundial IS NOT NULL
	EXEC SP.uspMundial_Bajar @id = @vMundial;

DECLARE @vPaisB INT;
SET @i = 0;
WHILE @i < 5
BEGIN
	SET @vPaisB = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE LIKE 'Pais Test A%');
	IF @vPaisB IS NULL BREAK;
	EXEC SP.uspPais_Bajar @idPais = @vPaisB;
	SET @i = @i + 1;
END

SELECT * FROM arbitros.Arbitraje;
SELECT * FROM partidos.Partido;
SELECT * FROM equipos.Pais WHERE NOMBRE LIKE 'Pais Test%';
GO