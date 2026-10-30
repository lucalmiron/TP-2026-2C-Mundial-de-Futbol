--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26
-- Objetivo: comprobar sustituciones, ventanas, goles y tarjetas en el descanso.
-- Ejecutar en una base vacia MUNDIAL_Grupo2_Test*, con las tablas y SP reales instalados.
-- Los datos son exclusivos de esta base de prueba. No ejecutar en MUNDIAL.

SET NOCOUNT ON;

IF DB_NAME() NOT LIKE 'MUNDIAL[_]Grupo2[_]Test%'
    THROW 51000, 'Seleccionar una base MUNDIAL_Grupo2_Test para estas pruebas.', 1;

IF EXISTS (SELECT 1 FROM equipos.Pais)
    THROW 51000, 'La base de prueba debe estar vacia.', 1;

DECLARE @pais1   INT,
        @pais2   INT,
        @grupo   INT,
        @mundial INT,
        @s1      INT,
        @s2      INT,
        @huso    INT,
        @idioma  INT,
        @sede    INT,
        @fase    INT,
        @p1      INT,
        @p2      INT,
        @arbitro INT,
        @motivo  INT,
        @i       INT = 1,
        @persona INT;

INSERT sedes.HusoHorario (Nombre)
VALUES ('UTC');
SET @huso = SCOPE_IDENTITY();

INSERT arbitros.Idioma(Descripcion) 
VALUES('Idioma'); 
SET @idioma = SCOPE_IDENTITY();

INSERT equipos.Pais(NOMBRE, Idioma, HusoHorario, PtIni, PtFin, PBI) 
VALUES('Prueba G1 A', @idioma, @huso, '17:00', '23:00', 1); 
SET @pais1=SCOPE_IDENTITY();

INSERT equipos.Pais(NOMBRE, Idioma, HusoHorario, PtIni, PtFin, PBI) 
VALUES('Prueba G1 B', @idioma, @huso, '17:00', '23:00', 1); 
SET @pais2=SCOPE_IDENTITY();

INSERT equipos.Grupo (NOMBRE)
VALUES ('Prueba G1');
SET @grupo = SCOPE_IDENTITY();

INSERT sedes.Mundial (
    IdPais,
    ACTIVIDAD_FECHA_INICIO,
    ACTIVIDAD_FECHA_FIN,
    TAMANIO_SELECCION_MINIMO,
    TAMANIO_SELECCION_MAXIMO,
    CAMBIOS_VENTANAS,
    CAMBIOS_CANTIDAD,
    SUSPENSION_TARJETAS_MAXIMAS,
    SUSPENSION_TIEMPO
)
VALUES (@pais1, '20260601', '20260731', 0, 26, 3, 5, 2, 1);
SET @mundial = SCOPE_IDENTITY();

INSERT equipos.Seleccion (IdPais, IdMundial, IdGrupo, CONFEDERACION)
VALUES (@pais1, @mundial, @grupo, 'Prueba');
SET @s1 = SCOPE_IDENTITY();

INSERT equipos.Seleccion (IdPais, IdMundial, IdGrupo, CONFEDERACION)
VALUES (@pais2, @mundial, @grupo, 'Prueba');
SET @s2 = SCOPE_IDENTITY();

INSERT sedes.Sede (Nombre, Ciudad, Capacidad, IdPais, IdHuso)
VALUES ('Prueba G1', 'Prueba', 50000, @pais1, @huso);
SET @sede = SCOPE_IDENTITY();

INSERT partidos.Fase (Descripcion)
VALUES ('Final');
SET @fase = SCOPE_IDENTITY();

INSERT partidos.Partido (IdFase, IdSede, IdMundial, Eq1, Eq2, Fecha, HoraUTC, HoraLocal)
VALUES (@fase, @sede, @mundial, @s1, @s2, '20260701', '18:00', '18:00');
SET @p1 = SCOPE_IDENTITY();

INSERT partidos.Partido (IdFase, IdSede, IdMundial, Eq1, Eq2, Fecha, HoraUTC, HoraLocal)
VALUES (@fase, @sede, @mundial, @s1, @s2, '20260708', '18:00', '18:00');
SET @p2 = SCOPE_IDENTITY();

INSERT partidos.Periodo (IdPeriodo, Descripcion, Inicio, Fin, EsPenales)
VALUES (901, '1er tiempo', 0, 45, 0),
       (902, 'Descanso', 45, 45, 0),
       (903, '2do tiempo', 45, 90, 0),
       (904, 'Penales', NULL, NULL, 1);

INSERT publicidad.Motivo (Descripcion)
VALUES ('Lesion');
SET @motivo = SCOPE_IDENTITY();

DECLARE @jugadores TABLE (Numero INT, Id INT);

WHILE @i <= 18
BEGIN
    INSERT equipos.Persona (Nombre, Fnac, Rol, Pais)
    VALUES (CONCAT('Prueba G1 jugador ', @i), '20000101', 'Jugador', @pais1);

    SET @persona = SCOPE_IDENTITY();

    INSERT equipos.Jugador (IdJugador, Estado, Posicion, Numero, Seleccion)
    VALUES (@persona, 'Activo', 'MED', @i, @s1);

    INSERT @jugadores
    VALUES (@i, @persona);

    SET @i += 1;
END;

INSERT equipos.Persona (Nombre, Fnac, Rol, Pais)
VALUES ('Prueba G1 arbitro', '19800101', 'Arbitro', @pais2);
SET @arbitro = SCOPE_IDENTITY();

INSERT arbitros.Arbitro (IdArbitro, Categoria)
VALUES (@arbitro, 'FIFA');

INSERT arbitros.Arbitraje (Arbitro, Funcion, Partido)
VALUES (@arbitro, 'Principal', @p1),
       (@arbitro, 'Principal', @p2);

DECLARE @j1       INT = (SELECT Id FROM @jugadores WHERE Numero = 1),
        @j2       INT = (SELECT Id FROM @jugadores WHERE Numero = 2),
        @j12      INT = (SELECT Id FROM @jugadores WHERE Numero = 12),
        @j13      INT = (SELECT Id FROM @jugadores WHERE Numero = 13),
        @j14      INT = (SELECT Id FROM @jugadores WHERE Numero = 14),
        @j15      INT = (SELECT Id FROM @jugadores WHERE Numero = 15),
        @j16      INT = (SELECT Id FROM @jugadores WHERE Numero = 16),
        @gol      INT,
        @evento   INT,
        @cantidad INT;


-- Preparacion exclusiva del test: dos alineaciones con titulares y banco.
INSERT partidos.Alineacion(IdPartido,IdJugador,Rol,PosicionCancha,Esquema)
SELECT P.Id, J.Id, CASE WHEN J.Numero<=11 THEN 'Titular' ELSE 'Suplente' END, 'MED', '4-4-2'
FROM @jugadores J CROSS JOIN (VALUES (@p1),(@p2)) P(Id);

DECLARE @j3 INT=(SELECT Id FROM @jugadores WHERE Numero=3),
        @j4 INT=(SELECT Id FROM @jugadores WHERE Numero=4),
        @j5 INT=(SELECT Id FROM @jugadores WHERE Numero=5),
        @j6 INT=(SELECT Id FROM @jugadores WHERE Numero=6),
        @j17 INT=(SELECT Id FROM @jugadores WHERE Numero=17);

-- Esperado: tres ventanas de juego; el cuarto y quinto cambio en descanso se aceptan.
EXEC SPTRANS.uspSustitucion_Registrar 10,@p1,901,@j12,@j1,@motivo;
EXEC SPTRANS.uspSustitucion_Registrar 20,@p1,901,@j13,@j2,@motivo;
EXEC SPTRANS.uspSustitucion_Registrar 30,@p1,901,@j14,@j3,@motivo;
EXEC SPTRANS.uspSustitucion_Registrar 45,@p1,902,@j15,@j4,@motivo;
EXEC SPTRANS.uspSustitucion_Registrar 45,@p1,902,@j16,@j5,@motivo;
IF (SELECT COUNT(*) FROM partidos.Sustitucion S JOIN partidos.Evento E ON E.IdEvento=S.IdSustitucion WHERE E.Partido=@p1)<>5
    THROW 51998,'Fallo: deben existir cinco cambios.',1;
PRINT 'OK: descanso no consume ventanas aunque ya se agotaron las tres.';

-- Esperado: rechaza sexto cambio incluso en descanso.
BEGIN TRY
    EXEC SPTRANS.uspSustitucion_Registrar 45,@p1,902,@j17,@j6,@motivo;
    THROW 51999,'La operacion debio rechazarse.',1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER()=51999 OR ERROR_MESSAGE() NOT LIKE '%Tope de cambios%'
        THROW;
END CATCH;
PRINT 'OK: rechaza sexto cambio incluso en descanso';

-- Esperado: distingue tres momentos que comparten minuto 45.
EXEC SPTRANS.uspSustitucion_Registrar 45,@p2,902,@j12,@j1,@motivo;
IF partidos.fnJugadorEnCanchaPeriodo(@p2,@j1,45,901)<>1
 OR partidos.fnJugadorEnCanchaPeriodo(@p2,@j12,45,901)<>0
 OR partidos.fnJugadorEnCanchaPeriodo(@p2,@j1,45,902)<>0
 OR partidos.fnJugadorEnCanchaPeriodo(@p2,@j12,45,902)<>1
 OR partidos.fnJugadorEnCanchaPeriodo(@p2,@j12,45,903)<>1
    THROW 51998,'Fallo: estado del equipo antes/despues del descanso.',1;
PRINT 'OK: reconstruccion de cancha por minuto y periodo.';

-- Esperado: sigue siendo valido el gol del titular al 45 del primer tiempo.
EXEC SPTRANS.uspGol_Registrar 45,@p2,901,@j1,NULL,'Jugada',@gol OUTPUT;

-- Esperado: rechaza gol previo al ingreso del suplente.
BEGIN TRY
    EXEC SPTRANS.uspGol_Registrar 45,@p2,901,@j12,NULL,'Jugada';
    THROW 51999,'La operacion debio rechazarse.',1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER()=51999 OR ERROR_MESSAGE() NOT LIKE '%autor no estaba%'
        THROW;
END CATCH;
PRINT 'OK: rechaza gol previo al ingreso del suplente';

-- Esperado: rechaza gol en descanso.
BEGIN TRY
    EXEC SPTRANS.uspGol_Registrar 45,@p2,902,@j12,NULL,'Jugada';
    THROW 51999,'La operacion debio rechazarse.',1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER()=51999 OR ERROR_MESSAGE() NOT LIKE '%No se permiten goles durante el descanso%'
        THROW;
END CATCH;
PRINT 'OK: rechaza gol en descanso';

-- Esperado: alta generica tambien rechaza gol en descanso.
BEGIN TRY
    EXEC partidos.Evento_Alta 45,'Gol',@p2,902,@evento OUTPUT;
    THROW 51999,'La operacion debio rechazarse.',1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER()=51999 OR ERROR_MESSAGE() NOT LIKE '%No se permiten goles durante el descanso%'
        THROW;
END CATCH;
PRINT 'OK: alta generica tambien rechaza gol en descanso';

-- Esperado: modificacion generica no mueve un gol a descanso.
BEGIN TRY
    EXEC partidos.Evento_Modificacion @gol,45,'Gol',@p2,902;
    THROW 51999,'La operacion debio rechazarse.',1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER()=51999 OR ERROR_MESSAGE() NOT LIKE '%No se permiten goles durante el descanso%'
        THROW;
END CATCH;
PRINT 'OK: modificacion generica no mueve un gol a descanso';

-- Esperado: rechaza minuto incorrecto para descanso.
BEGIN TRY
    EXEC SPTRANS.uspSustitucion_Registrar 46,@p2,902,@j13,@j2,@motivo;
    THROW 51999,'La operacion debio rechazarse.',1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER()=51999 OR ERROR_MESSAGE() NOT LIKE '%fuera del rango%'
        THROW;
END CATCH;
PRINT 'OK: rechaza minuto incorrecto para descanso';

-- Esperado: tarjetas de descanso aceptadas, incluida roja por segunda amarilla.
EXEC SPTRANS.uspAmonestacion_Registrar 45,@p2,902,@j2,@arbitro,'Amarilla','Prueba descanso';
EXEC SPTRANS.uspAmonestacion_Registrar 45,@p2,902,@j2,@arbitro,'Amarilla','Segunda amarilla';
IF NOT EXISTS(SELECT 1 FROM partidos.Amonestacion A JOIN partidos.Evento E ON E.IdEvento=A.IdAmonestacion
              WHERE E.Partido=@p2 AND E.Periodo=902 AND A.Amonestado=@j2 AND A.Tarjeta='Roja')
    THROW 51998,'Fallo: segunda amarilla debe generar roja.',1;
IF partidos.fnJugadorEnCanchaPeriodo(@p2,@j2,45,901)<>1
 OR partidos.fnJugadorEnCanchaPeriodo(@p2,@j2,45,903)<>0
    THROW 51998,'Fallo: orden de expulsion en descanso.',1;
PRINT 'OK: tarjetas en descanso y efecto de expulsion en segundo tiempo.';

-- Esperado: no permite reemplazar al expulsado en descanso.
BEGIN TRY
    EXEC SPTRANS.uspSustitucion_Registrar 45,@p2,902,@j13,@j2,@motivo;
    THROW 51999,'La operacion debio rechazarse.',1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER()=51999 OR ERROR_MESSAGE() NOT LIKE '%egreso no estaba%'
        THROW;
END CATCH;
PRINT 'OK: no permite reemplazar al expulsado en descanso';

-- Esperado: dos cambios en el mismo momento de juego consumen una sola ventana.
EXEC SPTRANS.uspSustitucion_Registrar 45,@p2,903,@j13,@j3,@motivo;
EXEC SPTRANS.uspSustitucion_Registrar 45,@p2,903,@j14,@j4,@motivo;
-- Esperado: no vuelve al primer tiempo aunque comparte el minuto 45.
BEGIN TRY
    EXEC SPTRANS.uspSustitucion_Registrar 45,@p2,901,@j15,@j5,@motivo;
    THROW 51999,'La operacion debio rechazarse.',1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER()=51999 OR ERROR_MESSAGE() NOT LIKE '%orden de minuto%'
        THROW;
END CATCH;
PRINT 'OK: orden entre periodos que comparten el minuto 45.';

EXEC SPTRANS.uspSustitucion_Registrar 60,@p2,903,@j15,@j5,@motivo;
EXEC SPTRANS.uspSustitucion_Registrar 70,@p2,903,@j16,@j6,@motivo;
IF (SELECT COUNT(*) FROM partidos.Sustitucion S JOIN partidos.Evento E ON E.IdEvento=S.IdSustitucion WHERE E.Partido=@p2)<>5
    THROW 51998,'Fallo: descanso y tres ventanas deben permitir cinco cambios.',1;
PRINT 'OK: descanso no se suma a las tres ventanas de juego.';

-- Esperado: rechaza sustitucion retroactiva al primer tiempo.
BEGIN TRY
    EXEC SPTRANS.uspSustitucion_Registrar 45,@p2,901,@j17,@j12,@motivo;
    THROW 51999,'La operacion debio rechazarse.',1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER()=51999 OR ERROR_MESSAGE() NOT LIKE '%orden de minuto%'
        THROW;
END CATCH;
PRINT 'OK: rechaza sustitucion retroactiva al primer tiempo';

-- Esperado: un cuarto minuto de juego se rechaza aun con cupo de cambios libre.
-- Ajuste SOLO en la base de test, para aislar la validacion de ventanas.
UPDATE sedes.Mundial SET CAMBIOS_CANTIDAD=6 WHERE IdMundial=@mundial;

-- Esperado: rechaza cuarta ventana de juego.
BEGIN TRY
    EXEC SPTRANS.uspSustitucion_Registrar 80,@p2,903,@j17,@j12,@motivo;
    THROW 51999,'La operacion debio rechazarse.',1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER()=51999 OR ERROR_MESSAGE() NOT LIKE '%Tope de ventanas%'
        THROW;
END CATCH;
PRINT 'OK: rechaza cuarta ventana de juego';

PRINT 'Pruebas de descanso finalizadas. Los datos quedan en la base de prueba para inspeccion.';
