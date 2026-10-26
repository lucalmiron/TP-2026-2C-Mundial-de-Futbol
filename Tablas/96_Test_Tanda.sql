-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Grupo 7
-- Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 26/10/26.
-- Objetivo: comprobar inicio y anulacion de tandas con los SP reales.
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

-- inicia tanda empatada.
EXEC SP.uspPartido_Tanda @p1,1;
IF NOT EXISTS(SELECT 1 FROM partidos.Partido WHERE IdPartido=@p1 AND PenalesEq1=0 AND PenalesEq2=0)
 THROW 51998,'Fallo: inicia tanda empatada.',1;
PRINT 'OK 1: inicia tanda empatada';

-- anula tanda sin conversiones.
EXEC SP.uspPartido_Tanda @p1,0;
IF NOT EXISTS(SELECT 1 FROM partidos.Partido WHERE IdPartido=@p1 AND PenalesEq1 IS NULL AND PenalesEq2 IS NULL)
 THROW 51998,'Fallo: anula tanda sin conversiones.',1;
PRINT 'OK 2: anula tanda sin conversiones';
INSERT partidos.Fase(Descripcion) VALUES('Grupos'); DECLARE @grupos INT=SCOPE_IDENTITY(); UPDATE partidos.Partido SET IdFase=@grupos,GolesEq1=1 WHERE IdPartido=@p2;

BEGIN TRY
 EXEC SP.uspPartido_Tanda @p2,1;
 THROW 51999,'La operacion debio rechazarse.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) OR ERROR_MESSAGE() NOT LIKE '%fase de grupos%' OR ERROR_MESSAGE() NOT LIKE '%empate%' THROW;
END CATCH;
PRINT 'OK 3: agrupa fase invalida y marcador desigual';

-- rechazo no inicia tanda.

IF EXISTS(SELECT 1 FROM partidos.Partido WHERE IdPartido=@p2 AND PenalesEq1 IS NOT NULL)
 THROW 51998,'Fallo: rechazo no inicia tanda.',1;
PRINT 'OK 4: rechazo no inicia tanda';
EXEC SP.uspAlineacion_Registrar @p1,@j1,'Titular'; EXEC SP.uspPartido_Tanda @p1,1;

-- reiniciar no borra conversiones ni cambia marcador de juego.
EXEC SPTRANS.uspGol_Registrar NULL,@p1,902,@j1,NULL,'Penal',@gol OUTPUT; EXEC SP.uspPartido_Tanda @p1,1;
IF NOT EXISTS(SELECT 1 FROM partidos.Partido WHERE IdPartido=@p1 AND PenalesEq1=1 AND PenalesEq2=0 AND GolesEq1=0)
 THROW 51998,'Fallo: reiniciar no borra conversiones ni cambia marcador de juego.',1;
PRINT 'OK 5: reiniciar no borra conversiones ni cambia marcador de juego';

BEGIN TRY
 EXEC SP.uspPartido_Tanda @p1,0;
 THROW 51999,'La operacion debio rechazarse.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) OR ERROR_MESSAGE() NOT LIKE '%Eliminar primero%' THROW;
END CATCH;
PRINT 'OK 6: protege conversiones existentes';

-- permite anular despues de retirar conversiones.
EXEC SPTRANS.uspGol_Bajar @gol; EXEC SP.uspPartido_Tanda @p1,0;
IF NOT EXISTS(SELECT 1 FROM partidos.Partido WHERE IdPartido=@p1 AND PenalesEq1 IS NULL AND PenalesEq2 IS NULL)
 THROW 51998,'Fallo: permite anular despues de retirar conversiones.',1;
PRINT 'OK 7: permite anular despues de retirar conversiones';

BEGIN TRY
 EXEC SP.uspPartido_Tanda -1,NULL;
 THROW 51999,'La operacion debio rechazarse.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) OR ERROR_MESSAGE() NOT LIKE '%Iniciar%' OR ERROR_MESSAGE() NOT LIKE '%Partido inexistente%' THROW;
END CATCH;
PRINT 'OK 8: agrupa parametros invalidos';

-- no quedan transacciones abiertas.

IF @@TRANCOUNT<>0
 THROW 51998,'Fallo: no quedan transacciones abiertas.',1;
PRINT 'OK 9: no quedan transacciones abiertas';

PRINT '96_Test_Tanda.sql: 9 comprobaciones correctas.';
