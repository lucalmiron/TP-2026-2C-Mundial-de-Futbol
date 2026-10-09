--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 08/10/2026

--Test de los SP de Espacio Publicitario (se ejecutan los SP reales de MUNDIAL)

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

--/ALTA

-- Esperado: imprime 'Error/es: - Valor invalido: Tipo.'
EXEC SP.EspacioPublicitario_Registrar @tipo = '', @costo = 5000;
GO

-- Esperado: imprime 'Error/es: - Valor invalido: Costo.'
EXEC SP.EspacioPublicitario_Registrar @tipo = 'Panel Perimetral', @costo = 0;
GO

-- Esperado: imprime 'Error/es: - Valor invalido: Costo.'
EXEC SP.EspacioPublicitario_Registrar @tipo = 'Panel Perimetral', @costo = -100;
GO

-- Esperado: no imprime nada, se insertan 4 filas (los 4 tipos de espacio del torneo).
EXEC SP.EspacioPublicitario_Registrar @tipo = 'Panel Perimetral', @costo = 5000;
GO

EXEC SP.EspacioPublicitario_Registrar @tipo = 'Cubo LED', @costo = 7000;
GO

EXEC SP.EspacioPublicitario_Registrar @tipo = 'Tunnel de Acceso', @costo = 6500;
GO

EXEC SP.EspacioPublicitario_Registrar @tipo = 'Pantalla Principal', @costo = 9000;
GO

-- Esperado: 4 filas.
SELECT * FROM publicidad.EspacioPublicitario;
GO

-- Esperado: imprime 'Error/es: - Valor duplicado: Tipo de espacio.'
EXEC SP.EspacioPublicitario_Registrar @tipo = 'Cubo LED', @costo = 7000;
GO

--/UPDATE
--Los ids se resuelven por nombre para que el test se pueda ejecutar mas de una vez.

-- Esperado: el Cubo LED pasa a Costo = 7500.
DECLARE @idCubo INT = (SELECT MIN(IdEP) FROM publicidad.EspacioPublicitario WHERE Tipo = 'Cubo LED');
EXEC SP.EspacioPublicitario_Update @idEP = @idCubo, @costo = 7500;
GO

-- Esperado: 1 fila con Tipo = Cubo LED y Costo = 7500.
SELECT * FROM publicidad.EspacioPublicitario WHERE Tipo = 'Cubo LED';
GO

-- Esperado: imprime 'Error/es: - Valor inexistente: IdEP.'
EXEC SP.EspacioPublicitario_Update @idEP = 999999, @costo = 7500;
GO

-- Esperado: imprime 'Error/es: - Valor invalido: Costo.'
DECLARE @idCubo2 INT = (SELECT MIN(IdEP) FROM publicidad.EspacioPublicitario WHERE Tipo = 'Cubo LED');
EXEC SP.EspacioPublicitario_Update @idEP = @idCubo2, @costo = -1;
GO

-- Esperado: imprime 'Error/es: - Valor duplicado: Tipo de espacio.'
DECLARE @idCubo3 INT = (SELECT MIN(IdEP) FROM publicidad.EspacioPublicitario WHERE Tipo = 'Cubo LED');
EXEC SP.EspacioPublicitario_Update @idEP = @idCubo3, @tipo = 'Panel Perimetral';
GO

--/BAJA

-- Esperado: imprime 'Error/es: - Valor inexistente: IdEP.'
EXEC SP.EspacioPublicitario_Bajar @idEP = 999999;
GO

-- Esperado: se borra la fila, quedan 3 filas.
DECLARE @idCubo4 INT = (SELECT MIN(IdEP) FROM publicidad.EspacioPublicitario WHERE Tipo = 'Cubo LED');
EXEC SP.EspacioPublicitario_Bajar @idEP = @idCubo4;
GO

SELECT * FROM publicidad.EspacioPublicitario;
GO

--/BAJA CON REGISTROS RELACIONADOS
--Para bloquear la baja hace falta una publicidad exhibida en ese espacio,
--y para registrarla hace falta la cadena Pais > Mundial > Selecciones > Sede > Fase > Partido.

-- Esperado: se crean 2 paises.
IF NOT EXISTS (SELECT 1 FROM equipos.Pais WHERE NOMBRE = 'Pais Test EP1')
	EXEC SP.uspPais_Registrar @nombre = 'Pais Test EP1', @pbi = 21;
GO
IF NOT EXISTS (SELECT 1 FROM equipos.Pais WHERE NOMBRE = 'Pais Test EP2')
	EXEC SP.uspPais_Registrar @nombre = 'Pais Test EP2', @pbi = 22;
GO

DECLARE @epPais1 INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test EP1');

-- Esperado: se crea el mundial.
IF NOT EXISTS (SELECT 1 FROM sedes.Mundial WHERE IdPais = @epPais1)
	EXEC SP.uspMundial_Registrar @idPais = @epPais1, @fechaInicio = '2026-06-01', @fechaFin = '2026-07-30',
		@tamMin = 11, @tamMax = 23, @ventanas = 3, @cantidad = 5, @suspMax = 2, @suspTiempo = 1;
GO

-- Esperado: se crea el grupo.
IF NOT EXISTS (SELECT 1 FROM equipos.Grupo WHERE NOMBRE = 'Grupo EP')
	EXEC SP.uspGrupo_Registrar @nombre = 'Grupo EP';
GO

DECLARE @epPais1b  INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test EP1');
DECLARE @epMundial INT = (SELECT MIN(IdMundial) FROM sedes.Mundial WHERE IdPais = @epPais1b);
DECLARE @epGrupo   INT = (SELECT MIN(IdGrupo) FROM equipos.Grupo WHERE NOMBRE = 'Grupo EP');

-- Esperado: se crea la seleccion del primer pais.
IF NOT EXISTS (SELECT 1 FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF EP1')
	EXEC SP.uspSeleccion_Registrar @idPais = @epPais1b, @idMundial = @epMundial, @idGrupo = @epGrupo, @confederacion = 'CONF EP1';
GO

DECLARE @epPais2    INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test EP2');
DECLARE @epPais1b   INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test EP1');
DECLARE @epMundial2 INT = (SELECT MIN(IdMundial) FROM sedes.Mundial WHERE IdPais = @epPais1b);
DECLARE @epGrupo2   INT = (SELECT MIN(IdGrupo) FROM equipos.Grupo WHERE NOMBRE = 'Grupo EP');

-- Esperado: se crea la seleccion del segundo pais.
IF NOT EXISTS (SELECT 1 FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF EP2')
	EXEC SP.uspSeleccion_Registrar @idPais = @epPais2, @idMundial = @epMundial2, @idGrupo = @epGrupo2, @confederacion = 'CONF EP2';
GO

DECLARE @epPais3 INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test EP1');

-- Esperado: se crea el huso horario y la sede.
IF NOT EXISTS (SELECT 1 FROM sedes.HusoHorario WHERE Nombre = 'UTC-3 (EP)')
	EXEC SP.uspHusoHorario_Registrar @nombre = 'UTC-3 (EP)', @idPais = @epPais3;
GO

DECLARE @epHuso   INT = (SELECT MIN(IdHuso) FROM sedes.HusoHorario WHERE Nombre = 'UTC-3 (EP)');
DECLARE @epPais4  INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test EP1');

IF NOT EXISTS (SELECT 1 FROM sedes.Sede WHERE Nombre = 'Sede Test EP')
	EXEC SP.uspSede_Registrar @nombre = 'Sede Test EP', @ciudad = 'Ciudad Test EP', @capacidad = 50000, @pais = @epPais4, @huso = @epHuso;
GO

-- Esperado: se crea la fase.
IF NOT EXISTS (SELECT 1 FROM partidos.Fase WHERE Descripcion = 'Grupos')
	EXEC SP.uspFase_Registrar @Descripcion = 'Grupos';
GO

DECLARE @epSede     INT = (SELECT MIN(IdSede) FROM sedes.Sede WHERE Nombre = 'Sede Test EP');
DECLARE @epFase     INT = (SELECT MIN(IdFase) FROM partidos.Fase WHERE Descripcion = 'Grupos');
DECLARE @epPais1c   INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test EP1');
DECLARE @epMundial3 INT = (SELECT MIN(IdMundial) FROM sedes.Mundial WHERE IdPais = @epPais1c);
DECLARE @epSel1     INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF EP1');
DECLARE @epSel2     INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF EP2');

-- Esperado: se crea el partido.
IF NOT EXISTS (SELECT 1 FROM partidos.Partido WHERE IdFase = @epFase AND Eq1 = @epSel1 AND Eq2 = @epSel2)
	EXEC SP.uspPartido_Registrar @IdFase = @epFase, @IdSede = @epSede, @IdMundial = @epMundial3,
		@Eq1 = @epSel1, @Eq2 = @epSel2, @Fecha = '2026-06-15', @HoraUTC = '16:00', @HoraLocal = '13:00';
GO

-- Esperado: se crea el idioma, la campana y la publicidad.
IF NOT EXISTS (SELECT 1 FROM arbitros.Idioma WHERE Descripcion = 'Espanol EP')
	EXEC SP.uspIdioma_Registrar @descripcion = 'Espanol EP';
GO

IF NOT EXISTS (SELECT 1 FROM publicidad.Campania WHERE Nombre = 'Campana Test EP')
	EXEC SP.uspCampania_Registrar @nombre = 'Campana Test EP', @descripcion = 'Campana del test de espacio';
GO

DECLARE @epCamp INT = (SELECT MIN(IdCampania) FROM publicidad.Campania WHERE Nombre = 'Campana Test EP');
DECLARE @epIdioma2 INT = COALESCE((SELECT MIN(IdIdioma) FROM arbitros.Idioma WHERE Descripcion = 'Espanol EP'),
								  (SELECT MIN(IdIdioma) FROM arbitros.Idioma));

IF NOT EXISTS (SELECT 1 FROM publicidad.Publicidad WHERE Nombre = 'Publicidad Test EP')
	EXEC SP.uspPublicidad_Registrar @nombre = 'Publicidad Test EP', @idCampania = @epCamp, @idIdioma = @epIdioma2;
GO

DECLARE @epPub     INT = (SELECT MIN(IdPublicidad) FROM publicidad.Publicidad WHERE Nombre = 'Publicidad Test EP');
DECLARE @epPartido INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
DECLARE @epEspacio INT = (SELECT MIN(IdEP) FROM publicidad.EspacioPublicitario WHERE Tipo = 'Panel Perimetral');

-- Esperado: se crea el historial de exhibicion de esa publicidad en el Panel Perimetral.
IF NOT EXISTS (SELECT 1 FROM publicidad.HistorialPublicidad WHERE IdPublicidad = @epPub AND IdEP = @epEspacio)
	EXEC SP.uspHistorialPublicidad_Registrar @idPublicidad = @epPub, @idPartido = @epPartido, @idEP = @epEspacio, @costoFinal = 5000;
GO

-- Esperado: imprime 'Error/es: - Existen 1 o mas registros relacionados: Historial Publicidad. Elimine dichos registros para continuar.'
DECLARE @epEspacio2 INT = (SELECT MIN(IdEP) FROM publicidad.EspacioPublicitario WHERE Tipo = 'Panel Perimetral');
EXEC SP.EspacioPublicitario_Bajar @idEP = @epEspacio2;
GO

-- Esperado: la fila sigue existiendo.
SELECT * FROM publicidad.EspacioPublicitario WHERE Tipo = 'Panel Perimetral';
GO

--/Limpieza de lo que genera el test
--Todo en un solo bloque para no perder las variables. Cada loop tiene su propio contador y tope.

--1) El historial de publicidad, la publicidad, la campana y el idioma.
DECLARE @epId INT, @i INT = 0;

WHILE @i < 5
BEGIN
	SET @epId = (SELECT MIN(IdHistorial) FROM publicidad.HistorialPublicidad WHERE IdEP IN (SELECT IdEP FROM publicidad.EspacioPublicitario WHERE Tipo IN ('Panel Perimetral','Cubo LED','Tunnel de Acceso','Pantalla Principal')));
	IF @epId IS NULL BREAK;
	EXEC SP.uspHistorialPublicidad_Bajar @id = @epId;
	SET @i = @i + 1;
END

SET @i = 0;
WHILE @i < 5
BEGIN
	SET @epId = (SELECT MIN(IdPublicidad) FROM publicidad.Publicidad WHERE Nombre = 'Publicidad Test EP');
	IF @epId IS NULL BREAK;
	EXEC SP.uspPublicidad_Bajar @id = @epId;
	SET @i = @i + 1;
END

SET @i = 0;
WHILE @i < 5
BEGIN
	SET @epId = (SELECT MIN(IdCampania) FROM publicidad.Campania WHERE Nombre = 'Campana Test EP');
	IF @epId IS NULL BREAK;
	EXEC SP.uspCampania_Bajar @id = @epId;
	SET @i = @i + 1;
END

--2) El partido, la fase, la sede y el huso horario.
DECLARE @epPartidoB INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
IF @epPartidoB IS NOT NULL
	EXEC SP.uspPartido_Bajar @Id = @epPartidoB;

DECLARE @epFaseB INT = (SELECT MIN(IdFase) FROM partidos.Fase WHERE Descripcion = 'Grupos');
IF @epFaseB IS NOT NULL
	EXEC SP.uspFase_Bajar @Id = @epFaseB;

DECLARE @epSedeB INT = (SELECT MIN(IdSede) FROM sedes.Sede WHERE Nombre = 'Sede Test EP');
IF @epSedeB IS NOT NULL
	EXEC SP.uspSede_Bajar @idSede = @epSedeB;

DECLARE @epHusoB INT = (SELECT MIN(IdHuso) FROM sedes.HusoHorario WHERE Nombre = 'UTC-3 (EP)');
IF @epHusoB IS NOT NULL
	EXEC SP.uspHusoHorario_Bajar @idHuso = @epHusoB;

--3) Las selecciones, el grupo, el mundial y los paises.
DECLARE @epSelB INT;
SET @i = 0;
WHILE @i < 5
BEGIN
	SET @epSelB = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION LIKE 'CONF EP%');
	IF @epSelB IS NULL BREAK;
	EXEC SP.uspSeleccion_Bajar @idSeleccion = @epSelB;
	SET @i = @i + 1;
END

DECLARE @epGrupoB INT = (SELECT MIN(IdGrupo) FROM equipos.Grupo WHERE NOMBRE = 'Grupo EP');
IF @epGrupoB IS NOT NULL
	EXEC SP.uspGrupo_Bajar @id = @epGrupoB;

DECLARE @epPaisE INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test EP1');
DECLARE @epMundialB INT = (SELECT MIN(IdMundial) FROM sedes.Mundial WHERE IdPais = @epPaisE);
IF @epMundialB IS NOT NULL
	EXEC SP.uspMundial_Bajar @id = @epMundialB;

DECLARE @epPaisB INT;
SET @i = 0;
WHILE @i < 5
BEGIN
	SET @epPaisB = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE LIKE 'Pais Test EP%');
	IF @epPaisB IS NULL BREAK;
	EXEC SP.uspPais_Bajar @idPais = @epPaisB;
	SET @i = @i + 1;
END

DECLARE @epIdiomaB INT = (SELECT MIN(IdIdioma) FROM arbitros.Idioma WHERE Descripcion = 'Espanol EP');
IF @epIdiomaB IS NOT NULL
	EXEC SP.uspIdioma_Bajar @id = @epIdiomaB;

-- Esperado: no queda nada del test.
SELECT * FROM publicidad.HistorialPublicidad;
SELECT * FROM publicidad.EspacioPublicitario WHERE Tipo = 'Panel Perimetral';
GO

DELETE FROM publicidad.EspacioPublicitario WHERE Tipo IN ('Panel Perimetral','Cubo LED','Tunnel de Acceso','Pantalla Principal');
GO