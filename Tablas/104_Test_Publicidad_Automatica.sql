-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Grupo 7
-- Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 26/10/26.
-- Objetivo: comprobar publicidad automatica, prioridad y prime time.
-- Ejecutar en una base vacia MUNDIAL_Final_Test*, con las tablas y SP reales instalados.
-- Los datos son exclusivos de esta base de prueba. No ejecutar en MUNDIAL.
SET NOCOUNT ON;
IF DB_NAME() NOT LIKE 'MUNDIAL[_]Final[_]Test%'
    THROW 51000, 'Seleccionar una base MUNDIAL_Final_Test para estas pruebas.', 1;
IF EXISTS(SELECT 1 FROM equipos.Pais)
    THROW 51000, 'La base de prueba debe estar vacia.', 1;

DECLARE @pais1 INT,@pais2 INT,@grupo INT,@mundial INT,@s1 INT,@s2 INT,@huso INT,@sede INT,
        @fase INT,@p1 INT,@p2 INT,@arbitro INT,@motivo INT,@i INT=1,@persona INT;
INSERT equipos.Pais(NOMBRE) VALUES('Prueba G1 A'); SET @pais1=SCOPE_IDENTITY();
INSERT equipos.Pais(NOMBRE) VALUES('Prueba G1 B'); SET @pais2=SCOPE_IDENTITY();
INSERT equipos.Grupo(NOMBRE) VALUES('Prueba G1'); SET @grupo=SCOPE_IDENTITY();
INSERT sedes.Mundial(IdPais,ACTIVIDAD_FECHA_INICIO,ACTIVIDAD_FECHA_FIN,TAMANIO_SELECCION_MINIMO,TAMANIO_SELECCION_MAXIMO,
 CAMBIOS_VENTANAS,CAMBIOS_CANTIDAD,SUSPENSION_TARJETAS_MAXIMAS,SUSPENSION_TIEMPO)
 VALUES(@pais1,'20260601','20260731',0,26,10,10,2,1); SET @mundial=SCOPE_IDENTITY();
INSERT equipos.Seleccion(IdPais,IdMundial,IdGrupo,CONFEDERACION) VALUES(@pais1,@mundial,@grupo,'Prueba'); SET @s1=SCOPE_IDENTITY();
INSERT equipos.Seleccion(IdPais,IdMundial,IdGrupo,CONFEDERACION) VALUES(@pais2,@mundial,@grupo,'Prueba'); SET @s2=SCOPE_IDENTITY();
INSERT sedes.HusoHorario(Nombre,IdPais) VALUES('UTC',@pais1); SET @huso=SCOPE_IDENTITY();
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

DECLARE @camp INT,@idioma INT,@cf INT,@pub INT,@mercado INT,@ep INT;
INSERT publicidad.Campania(Nombre,Descripcion) VALUES('Campania prueba','Prueba'); SET @camp=SCOPE_IDENTITY();
INSERT arbitros.Idioma(Descripcion) VALUES('Idioma publicidad'); SET @idioma=SCOPE_IDENTITY();
INSERT publicidad.CostoFranja(IdSede,TipoFranja,Costo) VALUES(@sede,'General',50); SET @cf=SCOPE_IDENTITY();
SET @i=1;
WHILE @i<=4 BEGIN INSERT publicidad.EspacioPublicitario(IdSede,Numero,Tipo,Costo) VALUES(@sede,@i,'Panel',100); SET @i+=1; END;
DECLARE @candidatas TABLE(Numero INT,IdPublicidad INT,IdPais INT);
SET @i=1;
WHILE @i<=6 BEGIN
 INSERT equipos.Pais(NOMBRE,PBI) VALUES(CONCAT('Mercado ',@i),700-@i*100); SET @mercado=SCOPE_IDENTITY();
 INSERT sedes.HusoHorario(Nombre,IdPais) VALUES('UTC+2',@mercado);
 INSERT publicidad.Publicidad(Nombre,IdCampania,IdIdioma) VALUES(CONCAT('Pieza ',@i),@camp,@idioma); SET @pub=SCOPE_IDENTITY();
 INSERT publicidad.PublicidadPais VALUES(@pub,@mercado);
 INSERT @candidatas VALUES(@i,@pub,@mercado);
 SET @i+=1;
END;
-- La sexta pieza interesa tambien a un participante, aun con PBI menor.
INSERT publicidad.PublicidadPais SELECT IdPublicidad,@pais1 FROM @candidatas WHERE Numero=6;
DECLARE @propuesta TABLE(IdPublicidad INT,IdPais INT,EsParticipante INT,PBI BIGINT,EsPrimeTime INT);
DECLARE @simulacion TABLE(IdPais INT,Nombre VARCHAR(50),IdHuso INT,Huso VARCHAR(50),FechaHoraLocal DATETIMEOFFSET,EsPrimeTime BIT);

-- simula mas de cuatro mercados en prime time.
INSERT @simulacion EXEC SP.uspPublicidad_PrimeTime @p1;
IF (SELECT COUNT(*) FROM @simulacion WHERE EsPrimeTime=1)<>6
 THROW 51998,'Fallo: simula mas de cuatro mercados en prime time.',1;
PRINT 'OK 1: simula mas de cuatro mercados en prime time';

-- prioriza participante y luego PBI sin duplicar piezas.
INSERT @propuesta EXEC SP.uspPublicidad_Proponer @p1;
IF (SELECT COUNT(*) FROM @propuesta)<>4 OR (SELECT COUNT(DISTINCT IdPublicidad) FROM @propuesta)<>4 OR NOT EXISTS(SELECT 1 FROM @propuesta WHERE EsParticipante=1) OR EXISTS(SELECT 1 FROM @propuesta P JOIN @candidatas C ON C.IdPublicidad=P.IdPublicidad WHERE C.Numero IN (4,5))
 THROW 51998,'Fallo: prioriza participante y luego PBI sin duplicar piezas.',1;
PRINT 'OK 2: prioriza participante y luego PBI sin duplicar piezas';

-- asigna cuatro piezas y conserva costo.
EXEC SPTRANS.uspPublicidad_AsignarAutomaticamente @p1,@cf;
IF (SELECT COUNT(*) FROM publicidad.HistorialPublicidad WHERE IdPartido=@p1)<>4 OR EXISTS(SELECT 1 FROM publicidad.HistorialPublicidad WHERE IdPartido=@p1 AND CostoFinal<>150)
 THROW 51998,'Fallo: asigna cuatro piezas y conserva costo.',1;
PRINT 'OK 3: asigna cuatro piezas y conserva costo';

BEGIN TRY
 EXEC SPTRANS.uspPublicidad_AsignarAutomaticamente @p1,@cf;
 THROW 51999,'La operacion debio rechazarse.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) OR ERROR_MESSAGE() NOT LIKE '%ya tiene asignaciones%' THROW;
END CATCH;
PRINT 'OK 4: rechaza segunda asignacion';

BEGIN TRY
 EXEC SPTRANS.uspPublicidad_AsignarAutomaticamente -1,-1;
 THROW 51999,'La operacion debio rechazarse.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) OR ERROR_MESSAGE() NOT LIKE '%Partido%' OR ERROR_MESSAGE() NOT LIKE '%Tarifa%' OR ERROR_MESSAGE() NOT LIKE '%cuatro espacios%' THROW;
END CATCH;
PRINT 'OK 5: agrupa errores de asignacion';
DELETE publicidad.PublicidadPais WHERE IdPublicidad IN (SELECT IdPublicidad FROM @candidatas WHERE Numero>=3);

BEGIN TRY
 EXEC SPTRANS.uspPublicidad_AsignarAutomaticamente @p2,@cf;
 THROW 51999,'La operacion debio rechazarse.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) OR ERROR_MESSAGE() NOT LIKE '%No hay cuatro piezas%' THROW;
END CATCH;
PRINT 'OK 6: rechaza candidatos insuficientes';

-- rechazo no guarda asignaciones parciales.

IF EXISTS(SELECT 1 FROM publicidad.HistorialPublicidad WHERE IdPartido=@p2)
 THROW 51998,'Fallo: rechazo no guarda asignaciones parciales.',1;
PRINT 'OK 7: rechazo no guarda asignaciones parciales';
DELETE @simulacion; UPDATE partidos.Partido SET HoraUTC='17:00' WHERE IdPartido=@p2;

-- incluye las 19 locales.
INSERT @simulacion EXEC SP.uspPublicidad_PrimeTime @p2;
IF (SELECT COUNT(*) FROM @simulacion WHERE EsPrimeTime=1)<>6
 THROW 51998,'Fallo: incluye las 19 locales.',1;
PRINT 'OK 8: incluye las 19 locales';
DELETE @simulacion; UPDATE partidos.Partido SET HoraUTC='21:00' WHERE IdPartido=@p2;

-- excluye las 23 locales.
INSERT @simulacion EXEC SP.uspPublicidad_PrimeTime @p2;
IF EXISTS(SELECT 1 FROM @simulacion S JOIN @candidatas C ON C.IdPais=S.IdPais WHERE EsPrimeTime=1)
 THROW 51998,'Fallo: excluye las 23 locales.',1;
PRINT 'OK 9: excluye las 23 locales';

INSERT publicidad.PublicidadPais SELECT C.IdPublicidad,C.IdPais FROM @candidatas C WHERE NOT EXISTS(SELECT 1 FROM publicidad.PublicidadPais PP WHERE PP.IdPublicidad=C.IdPublicidad AND PP.IdPais=C.IdPais);
INSERT publicidad.PublicidadPais SELECT IdPublicidad,@pais1 FROM @candidatas WHERE Numero=6;
UPDATE equipos.Pais SET PBI=100 WHERE IdPais IN (SELECT IdPais FROM @candidatas);
UPDATE sedes.HusoHorario SET Nombre='UTC' WHERE IdPais=(SELECT IdPais FROM @candidatas WHERE Numero=1);
DELETE @propuesta;

-- prime time desempata PBI y luego desempata el identificador.
INSERT @propuesta EXEC SP.uspPublicidad_Proponer @p1;
IF EXISTS(SELECT 1 FROM @propuesta P JOIN @candidatas C ON C.IdPublicidad=P.IdPublicidad WHERE C.Numero IN (1,5))
 THROW 51998,'Fallo: prime time desempata PBI y luego desempata el identificador.',1;
PRINT 'OK 10: prime time desempata PBI y luego desempata el identificador';
UPDATE publicidad.EspacioPublicitario SET Costo=200 WHERE IdSede=@sede; UPDATE publicidad.CostoFranja SET Costo=75 WHERE IdCF=@cf;

-- conserva tarifa historica aunque cambien precios.

IF EXISTS(SELECT 1 FROM publicidad.HistorialPublicidad WHERE IdPartido=@p1 AND CostoFinal<>150)
 THROW 51998,'Fallo: conserva tarifa historica aunque cambien precios.',1;
PRINT 'OK 11: conserva tarifa historica aunque cambien precios';
DELETE sedes.HusoHorario WHERE IdPais=(SELECT IdPais FROM @candidatas WHERE Numero=5); DELETE @simulacion;

-- mercado sin huso queda sin dato de prime time.
INSERT @simulacion EXEC SP.uspPublicidad_PrimeTime @p1;
IF NOT EXISTS(SELECT 1 FROM @simulacion WHERE IdPais=(SELECT IdPais FROM @candidatas WHERE Numero=5) AND EsPrimeTime IS NULL)
 THROW 51998,'Fallo: mercado sin huso queda sin dato de prime time.',1;
PRINT 'OK 12: mercado sin huso queda sin dato de prime time';
DECLARE @malas publicidad.AsignacionesPartido; INSERT @malas(IdEP,IdPublicidad,IdCF,CostoFinal) SELECT IdEP,-1,-1,-10 FROM publicidad.EspacioPublicitario WHERE IdSede=@sede;

BEGIN TRY
 EXEC SPTRANS.uspPublicidad_AsignarCuatro @p2,@malas;
 THROW 51999,'La operacion debio rechazarse.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) OR ERROR_MESSAGE() NOT LIKE '%Franjas%' OR ERROR_MESSAGE() NOT LIKE '%Publicidades%' OR ERROR_MESSAGE() NOT LIKE '%Costos%' THROW;
END CATCH;
PRINT 'OK 13: agrupa errores de las cuatro piezas';

-- asignacion invalida se revierte completa.

IF EXISTS(SELECT 1 FROM publicidad.HistorialPublicidad WHERE IdPartido=@p2) OR @@TRANCOUNT<>0
 THROW 51998,'Fallo: asignacion invalida se revierte completa.',1;
PRINT 'OK 14: asignacion invalida se revierte completa';

PRINT '104_Test_Publicidad_Automatica.sql: 14 comprobaciones correctas.';
