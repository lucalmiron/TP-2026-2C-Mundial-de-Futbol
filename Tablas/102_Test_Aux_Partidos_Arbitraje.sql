-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Grupo 7
-- Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 26/10/26.
-- Objetivo: comprobar partidos y arbitrajes.
-- Ejecutar en una base vacia MUNDIAL_Grupo4_Test*, con las tablas y SP reales instalados.
-- Los datos son exclusivos de esta base de prueba. No ejecutar en MUNDIAL.
SET NOCOUNT ON;
IF DB_NAME() NOT LIKE 'MUNDIAL[_]Grupo4[_]Test%'
    THROW 51000, 'Seleccionar una base MUNDIAL_Grupo4_Test para estas pruebas.', 1;
IF EXISTS(SELECT 1 FROM equipos.Pais)
    THROW 51000, 'La base de prueba debe estar vacia.', 1;

DECLARE @idioma INT, @pais1 INT,@pais2 INT,@grupo INT,@mundial INT,@s1 INT,@s2 INT,@huso INT,@sede INT,
        @fase INT,@p1 INT,@p2 INT,@arbitro INT,@motivo INT,@i INT=1,@persona INT;
INSERT sedes.HusoHorario(Nombre) VALUES('UTC'); SET @huso=SCOPE_IDENTITY();
INSERT arbitros.Idioma(Descripcion) VALUES('Idioma'); SET @idioma = SCOPE_IDENTITY();
INSERT equipos.Pais(NOMBRE, Idioma, HusoHorario, PtIni, PtFin, PBI) VALUES('Prueba G1 A', @idioma, @huso, '17:00', '23:00', 1); SET @pais1=SCOPE_IDENTITY();
INSERT equipos.Pais(NOMBRE, Idioma, HusoHorario, PtIni, PtFin, PBI) VALUES('Prueba G1 B', @idioma, @huso, '17:00', '23:00', 1); SET @pais2=SCOPE_IDENTITY();
INSERT equipos.Grupo(NOMBRE) VALUES('Prueba G1'); SET @grupo=SCOPE_IDENTITY();
INSERT sedes.Mundial(IdPais,ACTIVIDAD_FECHA_INICIO,ACTIVIDAD_FECHA_FIN,TAMANIO_SELECCION_MINIMO,TAMANIO_SELECCION_MAXIMO,
 CAMBIOS_VENTANAS,CAMBIOS_CANTIDAD,SUSPENSION_TARJETAS_MAXIMAS,SUSPENSION_TIEMPO)
 VALUES(@pais1,'20260601','20260731',0,26,10,10,2,1); SET @mundial=SCOPE_IDENTITY();
INSERT equipos.Seleccion(IdPais,IdMundial,IdGrupo,CONFEDERACION) VALUES(@pais1,@mundial,@grupo,'Prueba'); SET @s1=SCOPE_IDENTITY();
INSERT equipos.Seleccion(IdPais,IdMundial,IdGrupo,CONFEDERACION) VALUES(@pais2,@mundial,@grupo,'Prueba'); SET @s2=SCOPE_IDENTITY();
INSERT sedes.Sede(Nombre,Ciudad,Capacidad,IdPais,IdHuso) VALUES('Prueba G1','Prueba',50000,@pais1,@huso); SET @sede=SCOPE_IDENTITY();
INSERT partidos.Fase(Descripcion) VALUES('Final'); SET @fase=SCOPE_IDENTITY();
INSERT partidos.Partido(IdFase,IdSede,IdMundial,Eq1,Eq2,Fecha,HoraUTC,HoraLocal)
 VALUES(@fase,@sede,@mundial,@s1,@s2,'20260701','18:00','18:00'); SET @p1=SCOPE_IDENTITY();
INSERT partidos.Partido(IdFase,IdSede,IdMundial,Eq1,Eq2,Fecha,HoraUTC,HoraLocal)
 VALUES(@fase,@sede,@mundial,@s1,@s2,'20260708','18:00','18:00'); SET @p2=SCOPE_IDENTITY();
INSERT partidos.Periodo(IdPeriodo,Descripcion,Inicio,Fin,EsPenales) VALUES(901,'Juego',0,120,0),(902,'Penales',NULL,NULL,1);
INSERT publicidad.Motivo(Descripcion) VALUES('Lesion'); SET @motivo=SCOPE_IDENTITY();
DECLARE @jugadores TABLE(Numero INT,Id INT);
WHILE @i<=16
BEGIN
 INSERT equipos.Persona(Nombre,Fnac,Rol,Pais) VALUES(CONCAT('Prueba G1 jugador ',@i),'20000101','Jugador',@pais1);
 SET @persona=SCOPE_IDENTITY();
 INSERT equipos.Jugador(IdJugador,Estado,Posicion,Numero,Seleccion) VALUES(@persona,'Activo','MED',@i,@s1);
 INSERT @jugadores VALUES(@i,@persona);
 SET @i+=1;
END;
INSERT equipos.Persona(Nombre,Fnac,Rol,Pais) VALUES('Prueba G1 arbitro','19800101','Arbitro',@pais2); SET @arbitro=SCOPE_IDENTITY();
INSERT arbitros.Arbitro(IdArbitro,Categoria) VALUES(@arbitro,'FIFA');
INSERT arbitros.Arbitraje(Arbitro,Funcion,Partido) VALUES(@arbitro,'Principal',@p1),(@arbitro,'Principal',@p2);
DECLARE @j1 INT=(SELECT Id FROM @jugadores WHERE Numero=1),@j2 INT=(SELECT Id FROM @jugadores WHERE Numero=2),
 @j12 INT=(SELECT Id FROM @jugadores WHERE Numero=12),@j13 INT=(SELECT Id FROM @jugadores WHERE Numero=13),
 @j14 INT=(SELECT Id FROM @jugadores WHERE Numero=14),@j15 INT=(SELECT Id FROM @jugadores WHERE Numero=15),
 @j16 INT=(SELECT Id FROM @jugadores WHERE Numero=16),@gol INT,@evento INT,@cantidad INT;
DECLARE @p3 INT,@sedeChica INT,@pais3 INT,@s3 INT,@faseOctavos INT;

-- alta con sede inexistente.
BEGIN TRY
 EXEC SP.uspPartido_Registrar @fase,2147483647,@mundial,@s1,@s2,'20260715','18:00','18:00';
 THROW 51999, 'La operacion debio rechazarse.', 1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()=51999 OR ERROR_MESSAGE() NOT LIKE '%Valor inexistente: Sede%' THROW;
END CATCH;
PRINT 'OK 1: alta con sede inexistente';

-- alta con exceso de asistencia.
BEGIN TRY
 EXEC SP.uspPartido_Registrar @fase,@sede,@mundial,@s1,@s2,'20260715','18:00','18:00',50001;
 THROW 51999, 'La operacion debio rechazarse.', 1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()=51999 OR ERROR_MESSAGE() NOT LIKE '%supera la capacidad%' THROW;
END CATCH;
PRINT 'OK 2: alta con exceso de asistencia';

-- admite capacidad exacta.
EXEC SP.uspPartido_Registrar @fase,@sede,@mundial,@s1,@s2,'20260715','18:00','18:00',50000; SELECT @p3=MAX(IdPartido) FROM partidos.Partido;
IF (SELECT Asistencia FROM partidos.Partido WHERE IdPartido=@p3)<>50000
 THROW 51000, 'Fallo: admite capacidad exacta.', 1;
PRINT 'OK 3: admite capacidad exacta';

-- edicion con sede inexistente.
BEGIN TRY
 EXEC SP.uspPartido_Update @Id=@p3,@IdSede=2147483647;
 THROW 51999, 'La operacion debio rechazarse.', 1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()=51999 OR ERROR_MESSAGE() NOT LIKE '%Valor inexistente: Sede%' THROW;
END CATCH;
PRINT 'OK 4: edicion con sede inexistente';

-- edicion con exceso de asistencia.
BEGIN TRY
 EXEC SP.uspPartido_Update @Id=@p3,@Asistencia=50001;
 THROW 51999, 'La operacion debio rechazarse.', 1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()=51999 OR ERROR_MESSAGE() NOT LIKE '%supera la capacidad%' THROW;
END CATCH;
PRINT 'OK 5: edicion con exceso de asistencia';
INSERT sedes.Sede(Nombre,Ciudad,Capacidad,IdPais,IdHuso) VALUES('Sede chica','Prueba',100,@pais1,@huso); SET @sedeChica=SCOPE_IDENTITY();

-- cambio de sede conserva control de asistencia previa.
BEGIN TRY
 EXEC SP.uspPartido_Update @Id=@p3,@IdSede=@sedeChica;
 THROW 51999, 'La operacion debio rechazarse.', 1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()=51999 OR ERROR_MESSAGE() NOT LIKE '%supera la capacidad%' THROW;
END CATCH;
PRINT 'OK 6: cambio de sede conserva control de asistencia previa';

-- permite cambiar sede y asistencia juntas.
EXEC SP.uspPartido_Update @Id=@p3,@IdSede=@sedeChica,@Asistencia=100;
IF (SELECT IdSede FROM partidos.Partido WHERE IdPartido=@p3)<>@sedeChica OR (SELECT Asistencia FROM partidos.Partido WHERE IdPartido=@p3)<>100
 THROW 51000, 'Fallo: permite cambiar sede y asistencia juntas.', 1;
PRINT 'OK 7: permite cambiar sede y asistencia juntas';
INSERT equipos.Pais(NOMBRE) VALUES('Pais tercero'); SET @pais3=SCOPE_IDENTITY();
INSERT equipos.Seleccion(IdPais,IdMundial,IdGrupo,CONFEDERACION) VALUES(@pais3,@mundial,@grupo,'Prueba'); SET @s3=SCOPE_IDENTITY();

-- protege equipos con arbitros asignados.
BEGIN TRY
 EXEC SP.uspPartido_Update @Id=@p1,@Eq2=@s3;
 THROW 51999, 'La operacion debio rechazarse.', 1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()=51999 OR ERROR_MESSAGE() NOT LIKE '%arbitrajes registrados%' THROW;
END CATCH;
PRINT 'OK 8: protege equipos con arbitros asignados';
INSERT partidos.Alineacion(IdPartido,IdJugador,Rol) VALUES(@p3,@j1,'Titular');

-- protege equipos con alineaciones.
BEGIN TRY
 EXEC SP.uspPartido_Update @Id=@p3,@Eq1=@s3;
 THROW 51999, 'La operacion debio rechazarse.', 1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()=51999 OR ERROR_MESSAGE() NOT LIKE '%alineaciones%' THROW;
END CATCH;
PRINT 'OK 9: protege equipos con alineaciones';

-- permite editar asistencia manteniendo equipos.
EXEC SP.uspPartido_Update @Id=@p3,@Eq1=@s1,@Asistencia=50;
IF (SELECT Asistencia FROM partidos.Partido WHERE IdPartido=@p3)<>50
 THROW 51000, 'Fallo: permite editar asistencia manteniendo equipos.', 1;
PRINT 'OK 10: permite editar asistencia manteniendo equipos';
DELETE partidos.Alineacion WHERE IdPartido=@p3;

-- permite cambiar equipo sin registros vinculados.
EXEC SP.uspPartido_Update @Id=@p3,@Eq2=@s3;
IF (SELECT Eq2 FROM partidos.Partido WHERE IdPartido=@p3)<>@s3
 THROW 51000, 'Fallo: permite cambiar equipo sin registros vinculados.', 1;
PRINT 'OK 11: permite cambiar equipo sin registros vinculados';
INSERT partidos.Evento(Minuto,Tipo,Partido,Periodo) VALUES(1,'Gol',@p3,901);

-- protege equipos con eventos.
BEGIN TRY
 EXEC SP.uspPartido_Update @Id=@p3,@Eq2=@s2;
 THROW 51999, 'La operacion debio rechazarse.', 1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()=51999 OR ERROR_MESSAGE() NOT LIKE '%eventos%' THROW;
END CATCH;
PRINT 'OK 12: protege equipos con eventos';
DELETE partidos.Evento WHERE Partido=@p3;

-- edicion revalida nacionalidad.
BEGIN TRY
 EXEC SPTRANS.uspArbitraje_Update @arbitro,'VAR',@p1;
 THROW 51999, 'La operacion debio rechazarse.', 1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()=51999 OR ERROR_MESSAGE() NOT LIKE '%pais al que pertenece%' THROW;
END CATCH;
PRINT 'OK 13: edicion revalida nacionalidad';

-- permite editar funcion sin conflicto nacional.
UPDATE equipos.Persona SET Pais=@pais3 WHERE IdPersona=@arbitro; EXEC SPTRANS.uspArbitraje_Update @arbitro,'VAR',@p1;
IF NOT EXISTS(SELECT 1 FROM arbitros.Arbitraje WHERE Arbitro=@arbitro AND Partido=@p1 AND Funcion='VAR')
 THROW 51000, 'Fallo: permite editar funcion sin conflicto nacional.', 1;
PRINT 'OK 14: permite editar funcion sin conflicto nacional';
INSERT partidos.Fase(Descripcion) VALUES('Octavos'); SET @faseOctavos=SCOPE_IDENTITY();
UPDATE partidos.Partido SET IdFase=@faseOctavos WHERE IdPartido IN (@p1,@p3);
PRINT 'INICIO AVISO: debe aparecer una advertencia';
EXEC SPTRANS.uspArbitraje_Update @arbitro,'Asistente',@p1;
PRINT 'FIN AVISO';
PRINT 'INICIO SIN AVISO: final';
EXEC SPTRANS.uspArbitraje_Update @arbitro,'VAR',@p2;
PRINT 'FIN SIN AVISO';
UPDATE partidos.Partido SET Fecha='20260601' WHERE IdPartido=@p3;
PRINT 'INICIO SIN AVISO: partido anterior';
EXEC SPTRANS.uspArbitraje_Update @arbitro,'Principal',@p1;
PRINT 'FIN SIN AVISO';

-- advertencias no bloquean asignacion.

IF @@TRANCOUNT<>0 OR NOT EXISTS(SELECT 1 FROM arbitros.Arbitraje WHERE Arbitro=@arbitro AND Partido=@p1 AND Funcion='Principal')
 THROW 51000, 'Fallo: advertencias no bloquean asignacion.', 1;
PRINT 'OK 15: advertencias no bloquean asignacion';
PRINT 'Partidos y arbitraje: 15 comprobaciones correctas.';
