-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Grupo 7
-- Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 26/10/26.
-- Objetivo: comprobar ABM real de clubes.
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

-- alta y modificacion de club.
EXEC SP.uspClub_Registrar 'Club prueba'; SELECT @persona=IdClub FROM equipos.Club WHERE Nombre='Club prueba'; EXEC SP.uspClub_Update @persona,'Club editado';
IF NOT EXISTS(SELECT 1 FROM equipos.Club WHERE IdClub=@persona AND Nombre='Club editado')
 THROW 51998,'Fallo: alta y modificacion de club.',1;
PRINT 'OK 1: alta y modificacion de club';

BEGIN TRY
 EXEC SP.uspClub_Update -1,NULL;
 THROW 51999,'La operacion debio rechazarse.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) OR ERROR_MESSAGE() NOT LIKE '%ID Club%' OR ERROR_MESSAGE() NOT LIKE '%Nombre%' THROW;
END CATCH;
PRINT 'OK 2: agrupa errores de club';

-- asigna club real.
EXEC SP.uspJugador_ClubUpdate @j1,@persona;
IF (SELECT Club FROM equipos.Jugador WHERE IdJugador=@j1)<>@persona
 THROW 51998,'Fallo: asigna club real.',1;
PRINT 'OK 3: asigna club real';

BEGIN TRY
 EXEC SP.uspClub_Bajar @persona;
 THROW 51999,'La operacion debio rechazarse.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) OR ERROR_MESSAGE() NOT LIKE '%Jugador%' THROW;
END CATCH;
PRINT 'OK 4: protege club relacionado';

-- baja de club libre.
EXEC SP.uspJugador_ClubUpdate @j1,NULL; EXEC SP.uspClub_Bajar @persona;
IF EXISTS(SELECT 1 FROM equipos.Club WHERE IdClub=@persona)
 THROW 51998,'Fallo: baja de club libre.',1;
PRINT 'OK 5: baja de club libre';

PRINT '74_Test_Club.sql: 5 comprobaciones correctas.';
