-- Universidad Nacional de La Matanza
-- Bases de datos aplicada
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 08/10/2026
-- Objetivo: Testear Registro y Baja de Sustitucion

--Los objetos de negocio (TABLAS y SP) viven en MUNDIAL, el test se ejecuta contra ellos.
--El test arma su propio juego de datos y lo borra al final, asi se puede ejecutar mas de una vez.
--Mundial del test: 5 cambios y 2 ventanas de cambios por partido (los topes del reglamento).
--El minimo de jugadores del Mundial es 0 para que la limpieza al final pueda borrar a todos.
--Alineacion: 6 titulares (T1 a T6), 6 suplentes (S1 a S6) y 1 jugador que no fue alineado (NA).

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

--/Datos de prueba

-- Esperado: se crean los 2 paises del partido.
IF NOT EXISTS (SELECT 1 FROM equipos.Pais WHERE NOMBRE = 'Pais Test X1')
	EXEC SP.uspPais_Registrar @nombre = 'Pais Test X1', @pbi = 41;
GO
IF NOT EXISTS (SELECT 1 FROM equipos.Pais WHERE NOMBRE = 'Pais Test X2')
	EXEC SP.uspPais_Registrar @nombre = 'Pais Test X2', @pbi = 42;
GO

DECLARE @xPais1 INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test X1');

-- Esperado: se crea el mundial (5 cambios, 2 ventanas).
IF NOT EXISTS (SELECT 1 FROM sedes.Mundial WHERE IdPais = @xPais1)
	EXEC SP.uspMundial_Registrar @idPais = @xPais1, @fechaInicio = '2026-06-01', @fechaFin = '2026-07-30',
		@tamMin = 0, @tamMax = 23, @ventanas = 2, @cantidad = 5, @suspMax = 2, @suspTiempo = 1;
GO

-- Esperado: se crea el grupo.
IF NOT EXISTS (SELECT 1 FROM equipos.Grupo WHERE NOMBRE = 'Grupo X')
	EXEC SP.uspGrupo_Registrar @nombre = 'Grupo X';
GO

DECLARE @xPais1b  INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test X1');
DECLARE @xPais2   INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test X2');
DECLARE @xMundial INT = (SELECT MIN(IdMundial) FROM sedes.Mundial WHERE IdPais = @xPais1b);
DECLARE @xGrupo   INT = (SELECT MIN(IdGrupo) FROM equipos.Grupo WHERE NOMBRE = 'Grupo X');

-- Esperado: se crean las 2 selecciones que juegan el partido.
IF NOT EXISTS (SELECT 1 FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF X1')
	EXEC SP.uspSeleccion_Registrar @idPais = @xPais1b, @idMundial = @xMundial, @idGrupo = @xGrupo, @confederacion = 'CONF X1';
GO

DECLARE @xPais1c  INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test X1');
DECLARE @xPais2b  INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test X2');
DECLARE @xMundial2 INT = (SELECT MIN(IdMundial) FROM sedes.Mundial WHERE IdPais = @xPais1c);
DECLARE @xGrupo2   INT = (SELECT MIN(IdGrupo) FROM equipos.Grupo WHERE NOMBRE = 'Grupo X');

IF NOT EXISTS (SELECT 1 FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF X2')
	EXEC SP.uspSeleccion_Registrar @idPais = @xPais2b, @idMundial = @xMundial2, @idGrupo = @xGrupo2, @confederacion = 'CONF X2';
GO

DECLARE @xPais1d INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test X1');

-- Esperado: se crea el huso horario y la sede.
IF NOT EXISTS (SELECT 1 FROM sedes.HusoHorario WHERE Nombre = 'UTC-3 (X)')
	EXEC SP.uspHusoHorario_Registrar @nombre = 'UTC-3 (X)', @idPais = @xPais1d;
GO

DECLARE @xHuso  INT = (SELECT MIN(IdHuso) FROM sedes.HusoHorario WHERE Nombre = 'UTC-3 (X)');
DECLARE @xPais1e INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test X1');

IF NOT EXISTS (SELECT 1 FROM sedes.Sede WHERE Nombre = 'Sede Test X')
	EXEC SP.uspSede_Registrar @nombre = 'Sede Test X', @ciudad = 'Ciudad Test X', @capacidad = 50000, @pais = @xPais1e, @huso = @xHuso;
GO

-- Esperado: se crea la fase y el periodo.
IF NOT EXISTS (SELECT 1 FROM partidos.Fase WHERE Descripcion = 'Grupos')
	EXEC SP.uspFase_Registrar @Descripcion = 'Grupos';
GO

IF NOT EXISTS (SELECT 1 FROM partidos.Periodo WHERE IdPeriodo = 900)
	EXEC partidos.Periodo_Alta @idPeriodo = 900, @descripcion = 'Tiempo Test', @inicio = 0, @fin = 45;
GO

DECLARE @xSede     INT = (SELECT MIN(IdSede) FROM sedes.Sede WHERE Nombre = 'Sede Test X');
DECLARE @xFase     INT = (SELECT MIN(IdFase) FROM partidos.Fase WHERE Descripcion = 'Grupos');
DECLARE @xPais1f   INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test X1');
DECLARE @xMundial3 INT = (SELECT MIN(IdMundial) FROM sedes.Mundial WHERE IdPais = @xPais1f);
DECLARE @xSel1     INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF X1');
DECLARE @xSel2     INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF X2');

-- Esperado: se crea el partido entre las dos selecciones.
IF NOT EXISTS (SELECT 1 FROM partidos.Partido WHERE IdFase = @xFase AND Eq1 = @xSel1 AND Eq2 = @xSel2)
	EXEC SP.uspPartido_Registrar @IdFase = @xFase, @IdSede = @xSede, @IdMundial = @xMundial3,
		@Eq1 = @xSel1, @Eq2 = @xSel2, @Fecha = '2026-06-15', @HoraUTC = '16:00', @HoraLocal = '13:00';
GO

-- Esperado: se crea el motivo de la sustitucion.
IF NOT EXISTS (SELECT 1 FROM publicidad.Motivo WHERE Descripcion = 'Lesion Test')
	EXEC SP.uspMotivo_Registrar @descripcion = 'Lesion Test';
GO

-- Esperado: se registran 13 jugadores de la seleccion CONF X1.
DECLARE @xJugPais   INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test X1');
DECLARE @xJugSel    INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF X1');

IF NOT EXISTS (SELECT 1 FROM equipos.Persona WHERE Nombre = 'Jugador Test T1')
	EXEC SPTRANS.uspJugador_Registrar @nombre = 'Jugador Test T1', @fnac = '2000-01-01', @pais = @xJugPais, @posicion = 'DEL', @numero = 1, @seleccion = @xJugSel;
GO

DECLARE @xJugPais2 INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test X1');
DECLARE @xJugSel2  INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF X1');

IF NOT EXISTS (SELECT 1 FROM equipos.Persona WHERE Nombre = 'Jugador Test T2')
	EXEC SPTRANS.uspJugador_Registrar @nombre = 'Jugador Test T2', @fnac = '2000-01-02', @pais = @xJugPais2, @posicion = 'DEL', @numero = 2, @seleccion = @xJugSel2;
GO

DECLARE @xJugPais3 INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test X1');
DECLARE @xJugSel3  INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF X1');

IF NOT EXISTS (SELECT 1 FROM equipos.Persona WHERE Nombre = 'Jugador Test T3')
	EXEC SPTRANS.uspJugador_Registrar @nombre = 'Jugador Test T3', @fnac = '2000-01-03', @pais = @xJugPais3, @posicion = 'DEL', @numero = 3, @seleccion = @xJugSel3;
GO

DECLARE @xJugPais4 INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test X1');
DECLARE @xJugSel4  INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF X1');

IF NOT EXISTS (SELECT 1 FROM equipos.Persona WHERE Nombre = 'Jugador Test T4')
	EXEC SPTRANS.uspJugador_Registrar @nombre = 'Jugador Test T4', @fnac = '2000-01-04', @pais = @xJugPais4, @posicion = 'DEL', @numero = 4, @seleccion = @xJugSel4;
GO

DECLARE @xJugPais5 INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test X1');
DECLARE @xJugSel5  INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF X1');

IF NOT EXISTS (SELECT 1 FROM equipos.Persona WHERE Nombre = 'Jugador Test T5')
	EXEC SPTRANS.uspJugador_Registrar @nombre = 'Jugador Test T5', @fnac = '2000-01-05', @pais = @xJugPais5, @posicion = 'DEL', @numero = 5, @seleccion = @xJugSel5;
GO

DECLARE @xJugPais6 INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test X1');
DECLARE @xJugSel6  INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF X1');

IF NOT EXISTS (SELECT 1 FROM equipos.Persona WHERE Nombre = 'Jugador Test T6')
	EXEC SPTRANS.uspJugador_Registrar @nombre = 'Jugador Test T6', @fnac = '2000-01-06', @pais = @xJugPais6, @posicion = 'DEL', @numero = 6, @seleccion = @xJugSel6;
GO

DECLARE @xJugPaisS1 INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test X1');
DECLARE @xJugSelS1  INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF X1');

IF NOT EXISTS (SELECT 1 FROM equipos.Persona WHERE Nombre = 'Jugador Test S1')
	EXEC SPTRANS.uspJugador_Registrar @nombre = 'Jugador Test S1', @fnac = '2001-01-01', @pais = @xJugPaisS1, @posicion = 'DEL', @numero = 11, @seleccion = @xJugSelS1;
GO

DECLARE @xJugPaisS2 INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test X1');
DECLARE @xJugSelS2  INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF X1');

IF NOT EXISTS (SELECT 1 FROM equipos.Persona WHERE Nombre = 'Jugador Test S2')
	EXEC SPTRANS.uspJugador_Registrar @nombre = 'Jugador Test S2', @fnac = '2001-01-02', @pais = @xJugPaisS2, @posicion = 'DEL', @numero = 12, @seleccion = @xJugSelS2;
GO

DECLARE @xJugPaisS3 INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test X1');
DECLARE @xJugSelS3  INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF X1');

IF NOT EXISTS (SELECT 1 FROM equipos.Persona WHERE Nombre = 'Jugador Test S3')
	EXEC SPTRANS.uspJugador_Registrar @nombre = 'Jugador Test S3', @fnac = '2001-01-03', @pais = @xJugPaisS3, @posicion = 'DEL', @numero = 13, @seleccion = @xJugSelS3;
GO

DECLARE @xJugPaisS4 INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test X1');
DECLARE @xJugSelS4  INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF X1');

IF NOT EXISTS (SELECT 1 FROM equipos.Persona WHERE Nombre = 'Jugador Test S4')
	EXEC SPTRANS.uspJugador_Registrar @nombre = 'Jugador Test S4', @fnac = '2001-01-04', @pais = @xJugPaisS4, @posicion = 'DEL', @numero = 14, @seleccion = @xJugSelS4;
GO

DECLARE @xJugPaisS5 INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test X1');
DECLARE @xJugSelS5  INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF X1');

IF NOT EXISTS (SELECT 1 FROM equipos.Persona WHERE Nombre = 'Jugador Test S5')
	EXEC SPTRANS.uspJugador_Registrar @nombre = 'Jugador Test S5', @fnac = '2001-01-05', @pais = @xJugPaisS5, @posicion = 'DEL', @numero = 15, @seleccion = @xJugSelS5;
GO

DECLARE @xJugPaisS6 INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test X1');
DECLARE @xJugSelS6  INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF X1');

IF NOT EXISTS (SELECT 1 FROM equipos.Persona WHERE Nombre = 'Jugador Test S6')
	EXEC SPTRANS.uspJugador_Registrar @nombre = 'Jugador Test S6', @fnac = '2001-01-06', @pais = @xJugPaisS6, @posicion = 'DEL', @numero = 16, @seleccion = @xJugSelS6;
GO

DECLARE @xJugPaisNA INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test X1');
DECLARE @xJugSelNA  INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF X1');

--NA no se alinea en el partido: sirve para los casos de egreso e ingreso que no jugaron.
IF NOT EXISTS (SELECT 1 FROM equipos.Persona WHERE Nombre = 'Jugador Test NA')
	EXEC SPTRANS.uspJugador_Registrar @nombre = 'Jugador Test NA', @fnac = '2002-01-01', @pais = @xJugPaisNA, @posicion = 'DEL', @numero = 17, @seleccion = @xJugSelNA;
GO

-- Esperado: se alinean 6 titulares y 6 suplentes (NA queda fuera de la alineacion).
DECLARE @xPart INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
DECLARE @xSel  INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF X1');

DECLARE @t1 INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Jugador Test T1');
DECLARE @t2 INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Jugador Test T2');
DECLARE @t3 INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Jugador Test T3');
DECLARE @t4 INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Jugador Test T4');
DECLARE @t5 INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Jugador Test T5');
DECLARE @t6 INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Jugador Test T6');
DECLARE @s1 INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Jugador Test S1');
DECLARE @s2 INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Jugador Test S2');
DECLARE @s3 INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Jugador Test S3');
DECLARE @s4 INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Jugador Test S4');
DECLARE @s5 INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Jugador Test S5');
DECLARE @s6 INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Jugador Test S6');

EXEC SP.uspAlineacion_Registrar @IdPartido = @xPart, @IdJugador = @t1, @IdSeleccion = @xSel, @Rol = 'Titular', @PosicionCancha = 'DEL', @Esquema = '4-3-3';
EXEC SP.uspAlineacion_Registrar @IdPartido = @xPart, @IdJugador = @t2, @IdSeleccion = @xSel, @Rol = 'Titular', @PosicionCancha = 'DEL', @Esquema = '4-3-3';
EXEC SP.uspAlineacion_Registrar @IdPartido = @xPart, @IdJugador = @t3, @IdSeleccion = @xSel, @Rol = 'Titular', @PosicionCancha = 'DEL', @Esquema = '4-3-3';
EXEC SP.uspAlineacion_Registrar @IdPartido = @xPart, @IdJugador = @t4, @IdSeleccion = @xSel, @Rol = 'Titular', @PosicionCancha = 'DEL', @Esquema = '4-3-3';
EXEC SP.uspAlineacion_Registrar @IdPartido = @xPart, @IdJugador = @t5, @IdSeleccion = @xSel, @Rol = 'Titular', @PosicionCancha = 'DEL', @Esquema = '4-3-3';
EXEC SP.uspAlineacion_Registrar @IdPartido = @xPart, @IdJugador = @t6, @IdSeleccion = @xSel, @Rol = 'Titular', @PosicionCancha = 'DEL', @Esquema = '4-3-3';
EXEC SP.uspAlineacion_Registrar @IdPartido = @xPart, @IdJugador = @s1, @IdSeleccion = @xSel, @Rol = 'Suplente';
EXEC SP.uspAlineacion_Registrar @IdPartido = @xPart, @IdJugador = @s2, @IdSeleccion = @xSel, @Rol = 'Suplente';
EXEC SP.uspAlineacion_Registrar @IdPartido = @xPart, @IdJugador = @s3, @IdSeleccion = @xSel, @Rol = 'Suplente';
EXEC SP.uspAlineacion_Registrar @IdPartido = @xPart, @IdJugador = @s4, @IdSeleccion = @xSel, @Rol = 'Suplente';
EXEC SP.uspAlineacion_Registrar @IdPartido = @xPart, @IdJugador = @s5, @IdSeleccion = @xSel, @Rol = 'Suplente';
EXEC SP.uspAlineacion_Registrar @IdPartido = @xPart, @IdJugador = @s6, @IdSeleccion = @xSel, @Rol = 'Suplente';
GO

-- Esperado: 12 filas de alineacion (6 titulares y 6 suplentes).
SELECT IdJugador, Rol FROM partidos.Alineacion ORDER BY Rol, IdJugador;
GO

--/ALTA

-- Esperado: imprime 'Error/es: - Valor inexistente: Periodo.' (999999)
DECLARE @xP1 INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
DECLARE @xT1 INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Jugador Test T1');
DECLARE @xS1 INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Jugador Test S1');
DECLARE @xM1 INT = (SELECT MIN(IdMotivo) FROM publicidad.Motivo WHERE Descripcion = 'Lesion Test');
EXEC SPTRANS.uspSustitucion_Registrar @minuto = 46, @partido = @xP1, @periodo = 999999, @ingreso = @xS1, @egreso = @xT1, @motivo = @xM1;
GO

-- Esperado: imprime 'Error/es: - Ingreso y egreso no pueden ser el mismo jugador.', 0 filas nuevas
DECLARE @xP2 INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
DECLARE @xT1b INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Jugador Test T1');
DECLARE @xM2 INT = (SELECT MIN(IdMotivo) FROM publicidad.Motivo WHERE Descripcion = 'Lesion Test');
EXEC SPTRANS.uspSustitucion_Registrar @minuto = 46, @partido = @xP2, @periodo = 900, @ingreso = @xT1b, @egreso = @xT1b, @motivo = @xM2;
GO
SELECT * FROM partidos.Sustitucion;
GO

-- Esperado: imprime 'Error/es: - Valor inexistente: Partido.', 0 filas nuevas
DECLARE @xT1c INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Jugador Test T1');
DECLARE @xS1b INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Jugador Test S1');
DECLARE @xM3 INT = (SELECT MIN(IdMotivo) FROM publicidad.Motivo WHERE Descripcion = 'Lesion Test');
EXEC SPTRANS.uspSustitucion_Registrar @minuto = 46, @partido = 999999, @periodo = 900, @ingreso = @xS1b, @egreso = @xT1c, @motivo = @xM3;
GO
SELECT * FROM partidos.Sustitucion;
GO

-- Esperado: imprime 'Error/es: - Valor inexistente: Ingreso.', 0 filas nuevas
DECLARE @xP3 INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
DECLARE @xT1d INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Jugador Test T1');
DECLARE @xM4 INT = (SELECT MIN(IdMotivo) FROM publicidad.Motivo WHERE Descripcion = 'Lesion Test');
EXEC SPTRANS.uspSustitucion_Registrar @minuto = 46, @partido = @xP3, @periodo = 900, @ingreso = 999999, @egreso = @xT1d, @motivo = @xM4;
GO
SELECT * FROM partidos.Sustitucion;
GO

-- Esperado: imprime 'Error/es: - Valor inexistente: Egreso.', 0 filas nuevas
DECLARE @xP4 INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
DECLARE @xS1c INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Jugador Test S1');
DECLARE @xM5 INT = (SELECT MIN(IdMotivo) FROM publicidad.Motivo WHERE Descripcion = 'Lesion Test');
EXEC SPTRANS.uspSustitucion_Registrar @minuto = 46, @partido = @xP4, @periodo = 900, @ingreso = @xS1c, @egreso = 999999, @motivo = @xM5;
GO
SELECT * FROM partidos.Sustitucion;
GO

-- Esperado: imprime 'Error/es: - Valor inexistente: Motivo.', 0 filas nuevas
DECLARE @xP5 INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
DECLARE @xT1e INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Jugador Test T1');
DECLARE @xS1d INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Jugador Test S1');
EXEC SPTRANS.uspSustitucion_Registrar @minuto = 46, @partido = @xP5, @periodo = 900, @ingreso = @xS1d, @egreso = @xT1e, @motivo = 999999;
GO
SELECT * FROM partidos.Sustitucion;
GO

--/ALTA: CASOS DE CANCHA Y BANCO

-- Esperado: imprime 'Error/es: - El egreso no estaba en cancha.' (NA no esta en la alineacion), 0 filas nuevas
DECLARE @xP6 INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
DECLARE @xNA INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Jugador Test NA');
DECLARE @xS2a INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Jugador Test S2');
DECLARE @xM6 INT = (SELECT MIN(IdMotivo) FROM publicidad.Motivo WHERE Descripcion = 'Lesion Test');
EXEC SPTRANS.uspSustitucion_Registrar @minuto = 46, @partido = @xP6, @periodo = 900, @ingreso = @xS2a, @egreso = @xNA, @motivo = @xM6;
GO
SELECT * FROM partidos.Sustitucion;
GO

-- Esperado: imprime 'Error/es: - El ingreso no estaba en el banco.' (NA no esta en la alineacion), 0 filas nuevas
DECLARE @xP7 INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
DECLARE @xNA2 INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Jugador Test NA');
DECLARE @xT2a INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Jugador Test T2');
DECLARE @xM7 INT = (SELECT MIN(IdMotivo) FROM publicidad.Motivo WHERE Descripcion = 'Lesion Test');
EXEC SPTRANS.uspSustitucion_Registrar @minuto = 46, @partido = @xP7, @periodo = 900, @ingreso = @xNA2, @egreso = @xT2a, @motivo = @xM7;
GO
SELECT * FROM partidos.Sustitucion;
GO

--/ALTA: TOPES DEL REGLAMENTO
--El Mundial del test permite 5 cambios y 2 ventanas (minutos distintos).

-- Esperado: 1er cambio, 1 fila en Evento y Sustitucion (minuto 46, abre la 1era ventana)
DECLARE @xP8 INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
DECLARE @xT1f INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Jugador Test T1');
DECLARE @xS1e INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Jugador Test S1');
DECLARE @xM8 INT = (SELECT MIN(IdMotivo) FROM publicidad.Motivo WHERE Descripcion = 'Lesion Test');
EXEC SPTRANS.uspSustitucion_Registrar @minuto = 46, @partido = @xP8, @periodo = 900, @ingreso = @xS1e, @egreso = @xT1f, @motivo = @xM8;
GO
SELECT * FROM partidos.Evento WHERE Tipo = 'Sustitucion';
SELECT * FROM partidos.Sustitucion;
GO

-- Esperado: 2do cambio (minuto 47, abre la 2da ventana)
DECLARE @xP9 INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
DECLARE @xT2b INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Jugador Test T2');
DECLARE @xS2b INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Jugador Test S2');
DECLARE @xM9 INT = (SELECT MIN(IdMotivo) FROM publicidad.Motivo WHERE Descripcion = 'Lesion Test');
EXEC SPTRANS.uspSustitucion_Registrar @minuto = 47, @partido = @xP9, @periodo = 900, @ingreso = @xS2b, @egreso = @xT2b, @motivo = @xM9;
GO
SELECT COUNT(*) AS Sustituciones FROM partidos.Sustitucion;
GO

-- Esperado: 3er cambio en el minuto 46 (misma ventana), 3 filas en total
DECLARE @xP10 INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
DECLARE @xT3 INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Jugador Test T3');
DECLARE @xS3 INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Jugador Test S3');
DECLARE @xM10 INT = (SELECT MIN(IdMotivo) FROM publicidad.Motivo WHERE Descripcion = 'Lesion Test');
EXEC SPTRANS.uspSustitucion_Registrar @minuto = 46, @partido = @xP10, @periodo = 900, @ingreso = @xS3, @egreso = @xT3, @motivo = @xM10;
GO
SELECT COUNT(*) AS Sustituciones FROM partidos.Sustitucion;
GO

-- Esperado: imprime 'Error/es: - Tope de ventanas del reglamento excedido.' (el minuto 60 seria una 3era ventana), 3 filas
DECLARE @xP11 INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
DECLARE @xT4 INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Jugador Test T4');
DECLARE @xS4 INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Jugador Test S4');
DECLARE @xM11 INT = (SELECT MIN(IdMotivo) FROM publicidad.Motivo WHERE Descripcion = 'Lesion Test');
EXEC SPTRANS.uspSustitucion_Registrar @minuto = 60, @partido = @xP11, @periodo = 900, @ingreso = @xS4, @egreso = @xT4, @motivo = @xM11;
GO
SELECT COUNT(*) AS Sustituciones FROM partidos.Sustitucion;
GO

-- Esperado: 4to cambio en el minuto 47 (ventana ya abierta), 4 filas en total
DECLARE @xP12 INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
DECLARE @xT4b INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Jugador Test T4');
DECLARE @xS4b INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Jugador Test S4');
DECLARE @xM12 INT = (SELECT MIN(IdMotivo) FROM publicidad.Motivo WHERE Descripcion = 'Lesion Test');
EXEC SPTRANS.uspSustitucion_Registrar @minuto = 47, @partido = @xP12, @periodo = 900, @ingreso = @xS4b, @egreso = @xT4b, @motivo = @xM12;
GO
SELECT COUNT(*) AS Sustituciones FROM partidos.Sustitucion;
GO

-- Esperado: 5to cambio en el minuto 46 (ventana ya abierta), 5 filas en total
DECLARE @xP13 INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
DECLARE @xT5 INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Jugador Test T5');
DECLARE @xS5 INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Jugador Test S5');
DECLARE @xM13 INT = (SELECT MIN(IdMotivo) FROM publicidad.Motivo WHERE Descripcion = 'Lesion Test');
EXEC SPTRANS.uspSustitucion_Registrar @minuto = 46, @partido = @xP13, @periodo = 900, @ingreso = @xS5, @egreso = @xT5, @motivo = @xM13;
GO
SELECT COUNT(*) AS Sustituciones FROM partidos.Sustitucion;
GO

-- Esperado: imprime 'Error/es: - Tope de cambios del reglamento excedido.' (seria el 6to cambio), 5 filas
DECLARE @xP14 INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
DECLARE @xT6 INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Jugador Test T6');
DECLARE @xS6 INT = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre = 'Jugador Test S6');
DECLARE @xM14 INT = (SELECT MIN(IdMotivo) FROM publicidad.Motivo WHERE Descripcion = 'Lesion Test');
EXEC SPTRANS.uspSustitucion_Registrar @minuto = 46, @partido = @xP14, @periodo = 900, @ingreso = @xS6, @egreso = @xT6, @motivo = @xM14;
GO
SELECT COUNT(*) AS Sustituciones FROM partidos.Sustitucion;
GO

--/BAJA

-- Esperado: borra la primera sustitucion y su evento, quedan 4 filas
DECLARE @xSust INT = (SELECT MIN(S.IdSustitucion) FROM partidos.Sustitucion S
					   INNER JOIN equipos.Jugador J ON S.Egreso = J.IdJugador
					   INNER JOIN equipos.Persona P ON P.IdPersona = J.IdJugador
					   WHERE P.Nombre = 'Jugador Test T1');
EXEC SPTRANS.uspSustitucion_Bajar @id = @xSust;
GO
SELECT * FROM partidos.Sustitucion;
GO

-- Esperado: imprime 'Error/es: - Valor inexistente: IdSustitucion.', 0 borradas
EXEC SPTRANS.uspSustitucion_Bajar @id = 999999;
GO
SELECT * FROM partidos.Sustitucion;
GO

--/Limpieza de lo que genera el test (en orden, por las claves foraneas)
--Todo en un solo bloque para no perder las variables. Cada loop tiene su propio contador y tope.

DECLARE @xId INT, @i INT = 0;

--1) Las sustituciones que quedaron.
WHILE @i < 10
BEGIN
	SET @xId = (SELECT MIN(IdSustitucion) FROM partidos.Sustitucion);
	IF @xId IS NULL BREAK;
	EXEC SPTRANS.uspSustitucion_Bajar @id = @xId;
	SET @i = @i + 1;
END

--2) Las alineaciones del partido del test.
DECLARE @xPartB INT = (SELECT MIN(IdPartido) FROM partidos.Partido);
DECLARE @xSelB  INT = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION = 'CONF X1');

SET @i = 0;
WHILE @i < 20
BEGIN
	SET @xId = (SELECT MIN(IdJugador) FROM partidos.Alineacion WHERE IdPartido = @xPartB);
	IF @xId IS NULL BREAK;
	EXEC SP.uspAlineacion_Bajar @IdPartido = @xPartB, @IdJugador = @xId;
	SET @i = @i + 1;
END

--3) Los jugadores del test.
SET @i = 0;
WHILE @i < 20
BEGIN
	SET @xId = (SELECT MIN(IdJugador) FROM equipos.Jugador INNER JOIN equipos.Persona ON IdPersona = IdJugador WHERE Nombre LIKE 'Jugador Test %');
	IF @xId IS NULL BREAK;
	EXEC SPTRANS.uspJugador_Bajar @id = @xId;
	SET @i = @i + 1;
END

--4) El partido, el periodo y la fase.
IF @xPartB IS NOT NULL
	EXEC SP.uspPartido_Bajar @Id = @xPartB;

IF EXISTS (SELECT 1 FROM partidos.Periodo WHERE IdPeriodo = 900)
	EXEC partidos.Periodo_Baja @idPeriodo = 900;

DECLARE @xFaseB INT = (SELECT MIN(IdFase) FROM partidos.Fase WHERE Descripcion = 'Grupos');
IF @xFaseB IS NOT NULL
	EXEC SP.uspFase_Bajar @Id = @xFaseB;

--5) La sede, el huso horario, las selecciones, el grupo, el mundial y los paises.
DECLARE @xSedeB INT = (SELECT MIN(IdSede) FROM sedes.Sede WHERE Nombre = 'Sede Test X');
IF @xSedeB IS NOT NULL
	EXEC SP.uspSede_Bajar @idSede = @xSedeB;

DECLARE @xHusoB INT = (SELECT MIN(IdHuso) FROM sedes.HusoHorario WHERE Nombre = 'UTC-3 (X)');
IF @xHusoB IS NOT NULL
	EXEC SP.uspHusoHorario_Bajar @idHuso = @xHusoB;

SET @i = 0;
WHILE @i < 5
BEGIN
	SET @xId = (SELECT MIN(IdSeleccion) FROM equipos.Seleccion WHERE CONFEDERACION LIKE 'CONF X%');
	IF @xId IS NULL BREAK;
	EXEC SP.uspSeleccion_Bajar @idSeleccion = @xId;
	SET @i = @i + 1;
END

DECLARE @xGrupoB INT = (SELECT MIN(IdGrupo) FROM equipos.Grupo WHERE NOMBRE = 'Grupo X');
IF @xGrupoB IS NOT NULL
	EXEC SP.uspGrupo_Bajar @id = @xGrupoB;

DECLARE @xPaisE INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test X1');
DECLARE @xMundialB INT = (SELECT MIN(IdMundial) FROM sedes.Mundial WHERE IdPais = @xPaisE);
IF @xMundialB IS NOT NULL
	EXEC SP.uspMundial_Bajar @id = @xMundialB;

SET @i = 0;
WHILE @i < 5
BEGIN
	SET @xId = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE LIKE 'Pais Test X%');
	IF @xId IS NULL BREAK;
	EXEC SP.uspPais_Bajar @idPais = @xId;
	SET @i = @i + 1;
END

--6) El motivo de la sustitucion.
DECLARE @xMotivoB INT = (SELECT MIN(IdMotivo) FROM publicidad.Motivo WHERE Descripcion = 'Lesion Test');
IF @xMotivoB IS NOT NULL
	EXEC SP.uspMotivo_Bajar @id = @xMotivoB;

-- Esperado: no queda nada del test.
SELECT * FROM partidos.Sustitucion;
SELECT * FROM partidos.Evento;
SELECT * FROM partidos.Alineacion;
SELECT * FROM equipos.Jugador;
GO