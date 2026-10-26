-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Grupo 7
-- Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 26/10/26.
-- Objetivo: comprobar personas mediante SP reales de jugador, arbitro y tecnico.
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

-- alta y edicion de jugador.
EXEC SPTRANS.uspJugador_Registrar 'Jugador nuevo','20000101',@pais1,'MED',30,NULL,@s1,'Inactivo'; SELECT @persona=IdPersona FROM equipos.Persona WHERE Nombre='Jugador nuevo'; EXEC SPTRANS.uspJugador_Update @persona,@nombre='Jugador editado';
IF NOT EXISTS(SELECT 1 FROM equipos.Persona WHERE IdPersona=@persona AND Nombre='Jugador editado')
 THROW 51998,'Fallo: alta y edicion de jugador.',1;
PRINT 'OK 1: alta y edicion de jugador';

BEGIN TRY
 EXEC SPTRANS.uspJugador_Registrar NULL,NULL,-1,NULL,-1,NULL,-1;
 THROW 51999,'La operacion debio rechazarse.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) OR ERROR_MESSAGE() NOT LIKE '%Nombre%' OR ERROR_MESSAGE() NOT LIKE '%Nacimiento%' OR ERROR_MESSAGE() NOT LIKE '%Pais%' OR ERROR_MESSAGE() NOT LIKE '%Numero%' THROW;
END CATCH;
PRINT 'OK 2: agrupa errores del jugador';

-- baja de jugador y alta y edicion de arbitro.
EXEC SPTRANS.uspJugador_Bajar @persona; EXEC SPTRANS.uspArbitro_Registrar 'Arbitro nuevo','19800101',@pais1,'FIFA'; SELECT @persona=IdPersona FROM equipos.Persona WHERE Nombre='Arbitro nuevo'; EXEC SPTRANS.uspArbitro_Update @persona,@nombre='Arbitro editado';
IF NOT EXISTS(SELECT 1 FROM equipos.Persona WHERE IdPersona=@persona AND Nombre='Arbitro editado')
 THROW 51998,'Fallo: baja de jugador y alta y edicion de arbitro.',1;
PRINT 'OK 3: baja de jugador y alta y edicion de arbitro';

BEGIN TRY
 EXEC SPTRANS.uspArbitro_Registrar NULL,NULL,-1,NULL;
 THROW 51999,'La operacion debio rechazarse.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) OR ERROR_MESSAGE() NOT LIKE '%Nombre%' OR ERROR_MESSAGE() NOT LIKE '%Nacimiento%' OR ERROR_MESSAGE() NOT LIKE '%Pais%' THROW;
END CATCH;
PRINT 'OK 4: agrupa errores del arbitro';

-- baja de arbitro y alta y edicion de tecnico.
EXEC SPTRANS.uspArbitro_Bajar @persona; EXEC SPTRANS.uspTecnico_Registrar 'Tecnico nuevo','19800101',@pais1,'Director Tecnico',@s1; SELECT @persona=IdPersona FROM equipos.Persona WHERE Nombre='Tecnico nuevo'; EXEC SPTRANS.uspTecnico_Update @persona,@nombre='Tecnico editado';
IF NOT EXISTS(SELECT 1 FROM equipos.Persona WHERE IdPersona=@persona AND Nombre='Tecnico editado')
 THROW 51998,'Fallo: baja de arbitro y alta y edicion de tecnico.',1;
PRINT 'OK 5: baja de arbitro y alta y edicion de tecnico';

BEGIN TRY
 EXEC SPTRANS.uspTecnico_Registrar NULL,NULL,-1,NULL,-1;
 THROW 51999,'La operacion debio rechazarse.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) OR ERROR_MESSAGE() NOT LIKE '%Nombre%' OR ERROR_MESSAGE() NOT LIKE '%Nacimiento%' OR ERROR_MESSAGE() NOT LIKE '%Seleccion%' THROW;
END CATCH;
PRINT 'OK 6: agrupa errores del tecnico';

-- baja de tecnico.
EXEC SPTRANS.uspTecnico_Bajar @persona;
IF EXISTS(SELECT 1 FROM equipos.Tecnico WHERE IdTecnico=@persona)
 THROW 51998,'Fallo: baja de tecnico.',1;
PRINT 'OK 7: baja de tecnico';

PRINT '88_Test_Persona.sql: 7 comprobaciones correctas.';
