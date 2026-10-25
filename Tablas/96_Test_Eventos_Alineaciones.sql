--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 08/10/2026
-- Objetivo: comprobar alineaciones, expulsiones, sustituciones y goles.
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
        @sede    INT,
        @fase    INT,
        @p1      INT,
        @p2      INT,
        @arbitro INT,
        @motivo  INT,
        @i       INT = 1,
        @persona INT;

INSERT equipos.Pais (NOMBRE)
VALUES ('Prueba G1 A');
SET @pais1 = SCOPE_IDENTITY();

INSERT equipos.Pais (NOMBRE)
VALUES ('Prueba G1 B');
SET @pais2 = SCOPE_IDENTITY();

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
VALUES (@pais1, '20260601', '20260731', 0, 26, 10, 10, 2, 1);
SET @mundial = SCOPE_IDENTITY();

INSERT equipos.Seleccion (IdPais, IdMundial, IdGrupo, CONFEDERACION)
VALUES (@pais1, @mundial, @grupo, 'Prueba');
SET @s1 = SCOPE_IDENTITY();

INSERT equipos.Seleccion (IdPais, IdMundial, IdGrupo, CONFEDERACION)
VALUES (@pais2, @mundial, @grupo, 'Prueba');
SET @s2 = SCOPE_IDENTITY();

INSERT sedes.HusoHorario (Nombre, IdPais)
VALUES ('UTC', @pais1);
SET @huso = SCOPE_IDENTITY();

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
VALUES (901, 'Juego', 0, 120, 0),
       (902, 'Penales', NULL, NULL, 1);

INSERT publicidad.Motivo (Descripcion)
VALUES ('Lesion');
SET @motivo = SCOPE_IDENTITY();

DECLARE @jugadores TABLE (Numero INT, Id INT);

WHILE @i <= 16
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


-- Esperado: registra once titulares.
SET @i = 1;

WHILE @i <= 11
BEGIN
    SELECT @persona = Id
    FROM @jugadores
    WHERE Numero = @i;

    EXEC SP.uspAlineacion_Registrar @p1, @persona, 'Titular', 'MED', '4-4-2';

    SET @i += 1;
END;

IF (SELECT COUNT(*) FROM partidos.Alineacion WHERE IdPartido = @p1 AND Rol = 'Titular') <> 11
    THROW 51000, 'Fallo: registra once titulares.', 1;

PRINT 'OK 1: registra once titulares';


-- Esperado: rechaza al duodecimo titular.
BEGIN TRY
    EXEC SP.uspAlineacion_Registrar @p1, @j12, 'Titular', 'MED', '4-4-2';

    THROW 51999, 'La operacion debio rechazarse.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51999 OR ERROR_MESSAGE() NOT LIKE '%once titulares%'
        THROW;
END CATCH;

IF EXISTS (SELECT 1 FROM partidos.Alineacion WHERE IdPartido = @p1 AND IdJugador = @j12)
    THROW 51000, 'Fallo: rechaza al duodecimo titular.', 1;

PRINT 'OK 2: rechaza al duodecimo titular';


-- Esperado: rechaza al suspendido.
BEGIN TRY
    UPDATE equipos.Jugador
    SET Estado = 'Suspendido'
    WHERE IdJugador = @j12;

    EXEC SP.uspAlineacion_Registrar @p1, @j12, 'Suplente';

    THROW 51999, 'La operacion debio rechazarse.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51999 OR ERROR_MESSAGE() NOT LIKE '%no esta habilitado%'
        THROW;
END CATCH;

IF EXISTS (SELECT 1 FROM partidos.Alineacion WHERE IdPartido = @p1 AND IdJugador = @j12)
    THROW 51000, 'Fallo: rechaza al suspendido.', 1;

PRINT 'OK 3: rechaza al suspendido';


-- Esperado: rechaza al inactivo.
BEGIN TRY
    UPDATE equipos.Jugador
    SET Estado = 'Inactivo'
    WHERE IdJugador = @j12;

    EXEC SP.uspAlineacion_Registrar @p1, @j12, 'Suplente';

    THROW 51999, 'La operacion debio rechazarse.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51999 OR ERROR_MESSAGE() NOT LIKE '%no esta habilitado%'
        THROW;
END CATCH;

IF EXISTS (SELECT 1 FROM partidos.Alineacion WHERE IdPartido = @p1 AND IdJugador = @j12)
    THROW 51000, 'Fallo: rechaza al inactivo.', 1;

PRINT 'OK 4: rechaza al inactivo';


-- Esperado: rechaza esquemas diferentes.
BEGIN TRY
    UPDATE equipos.Jugador
    SET Estado = 'Activo'
    WHERE IdJugador = @j12;

    EXEC SP.uspAlineacion_Registrar @p1, @j12, 'Suplente', 'MED', '4-3-3';

    THROW 51999, 'La operacion debio rechazarse.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51999 OR ERROR_MESSAGE() NOT LIKE '%esquema debe coincidir%'
        THROW;
END CATCH;

IF EXISTS (SELECT 1 FROM partidos.Alineacion WHERE IdPartido = @p1 AND IdJugador = @j12)
    THROW 51000, 'Fallo: rechaza esquemas diferentes.', 1;

PRINT 'OK 5: rechaza esquemas diferentes';


-- Esperado: registra suplentes habilitados.
EXEC SP.uspAlineacion_Registrar @p1, @j12, 'Suplente', 'MED', '4-4-2';
EXEC SP.uspAlineacion_Registrar @p1, @j13, 'Suplente';
EXEC SP.uspAlineacion_Registrar @p1, @j14, 'Suplente';
EXEC SP.uspAlineacion_Registrar @p1, @j15, 'Suplente';

IF (SELECT COUNT(*) FROM partidos.Alineacion WHERE IdPartido = @p1 AND Rol = 'Suplente') <> 4
    THROW 51000, 'Fallo: registra suplentes habilitados.', 1;

PRINT 'OK 6: registra suplentes habilitados';


-- Esperado: rechaza la operacion por minuto obligatorio.
BEGIN TRY
    EXEC SPTRANS.uspGol_Registrar NULL, @p1, 901, @j1, NULL, 'Jugada';

    THROW 51999, 'La operacion debio rechazarse.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51999 OR ERROR_MESSAGE() NOT LIKE '%minuto es obligatorio%'
        THROW;
END CATCH;

PRINT 'OK 7: minuto obligatorio';


-- Esperado: rechaza la operacion por autor fuera de alineacion.
BEGIN TRY
    EXEC SPTRANS.uspGol_Registrar 5, @p1, 901, @j16, NULL, 'Jugada';

    THROW 51999, 'La operacion debio rechazarse.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51999 OR ERROR_MESSAGE() NOT LIKE '%autor no estaba%'
        THROW;
END CATCH;

PRINT 'OK 8: autor fuera de alineacion';


-- Esperado: rechaza la operacion por asistente que no ingreso.
BEGIN TRY
    EXEC SPTRANS.uspGol_Registrar 5, @p1, 901, @j1, @j12, 'Jugada';

    THROW 51999, 'La operacion debio rechazarse.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51999 OR ERROR_MESSAGE() NOT LIKE '%asistente no estaba%'
        THROW;
END CATCH;

PRINT 'OK 9: asistente que no ingreso';


-- Esperado: registra gol y marcador.
EXEC SPTRANS.uspGol_Registrar 5, @p1, 901, @j1, @j2, 'Jugada', @gol OUTPUT;

IF NOT EXISTS (SELECT 1 FROM partidos.Gol WHERE IdGol = @gol)
   OR (SELECT GolesEq1 FROM partidos.Partido WHERE IdPartido = @p1) <> 1
    THROW 51000, 'Fallo: registra gol y marcador.', 1;

PRINT 'OK 10: registra gol y marcador';


-- Esperado: rechaza la operacion por protege la edicion del gol.
BEGIN TRY
    EXEC partidos.Evento_Modificacion @gol, 6, 'Gol', @p1, 901;

    THROW 51999, 'La operacion debio rechazarse.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51999 OR ERROR_MESSAGE() NOT LIKE '%corregir un gol%'
        THROW;
END CATCH;

PRINT 'OK 11: protege la edicion del gol';


-- Esperado: reemplaza un titular por un suplente.
EXEC SPTRANS.uspSustitucion_Registrar 10, @p1, 901, @j12, @j1, @motivo;

IF partidos.fnJugadorEnCancha(@p1, @j12, 10) <> 1
   OR partidos.fnJugadorEnCancha(@p1, @j1, 10) <> 0
    THROW 51000, 'Fallo: reemplaza un titular por un suplente.', 1;

PRINT 'OK 12: reemplaza un titular por un suplente';


-- Esperado: rechaza una segunda salida.
BEGIN TRY
    SELECT @cantidad = COUNT(*)
    FROM partidos.Sustitucion;

    EXEC SPTRANS.uspSustitucion_Registrar 11, @p1, 901, @j13, @j1, @motivo;

    THROW 51999, 'La operacion debio rechazarse.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51999 OR ERROR_MESSAGE() NOT LIKE '%egreso no estaba%'
        THROW;
END CATCH;

IF (SELECT COUNT(*) FROM partidos.Sustitucion) <> @cantidad
    THROW 51000, 'Fallo: rechaza una segunda salida.', 1;

PRINT 'OK 13: rechaza una segunda salida';


-- Esperado: rechaza un segundo ingreso.
BEGIN TRY
    SELECT @cantidad = COUNT(*)
    FROM partidos.Sustitucion;

    EXEC SPTRANS.uspSustitucion_Registrar 11, @p1, 901, @j12, @j2, @motivo;

    THROW 51999, 'La operacion debio rechazarse.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51999 OR ERROR_MESSAGE() NOT LIKE '%ingreso ya participo%'
        THROW;
END CATCH;

IF (SELECT COUNT(*) FROM partidos.Sustitucion) <> @cantidad
    THROW 51000, 'Fallo: rechaza un segundo ingreso.', 1;

PRINT 'OK 14: rechaza un segundo ingreso';


-- Esperado: rechaza la operacion por gol anterior al ingreso.
BEGIN TRY
    EXEC SPTRANS.uspGol_Registrar 9, @p1, 901, @j12, NULL, 'Jugada';

    THROW 51999, 'La operacion debio rechazarse.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51999 OR ERROR_MESSAGE() NOT LIKE '%autor no estaba%'
        THROW;
END CATCH;

PRINT 'OK 15: gol anterior al ingreso';


-- Esperado: rechaza la operacion por gol posterior a la salida.
BEGIN TRY
    EXEC SPTRANS.uspGol_Registrar 11, @p1, 901, @j1, NULL, 'Jugada';

    THROW 51999, 'La operacion debio rechazarse.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51999 OR ERROR_MESSAGE() NOT LIKE '%autor no estaba%'
        THROW;
END CATCH;

PRINT 'OK 16: gol posterior a la salida';


-- Esperado: gol del suplente que ingreso.
EXEC SPTRANS.uspGol_Registrar 12, @p1, 901, @j12, NULL, 'Jugada', @gol OUTPUT;

IF NOT EXISTS (SELECT 1 FROM partidos.Gol WHERE IdGol = @gol)
    THROW 51000, 'Fallo: gol del suplente que ingreso.', 1;

PRINT 'OK 17: gol del suplente que ingreso';


-- Esperado: no altera eventos posteriores con un cambio retroactivo.
BEGIN TRY
    SELECT @cantidad = COUNT(*)
    FROM partidos.Sustitucion;

    EXEC SPTRANS.uspSustitucion_Registrar 11, @p1, 901, @j13, @j12, @motivo;

    THROW 51999, 'La operacion debio rechazarse.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51999 OR ERROR_MESSAGE() NOT LIKE '%orden de minuto%'
        THROW;
END CATCH;

IF (SELECT COUNT(*) FROM partidos.Sustitucion) <> @cantidad
    THROW 51000, 'Fallo: no altera eventos posteriores con un cambio retroactivo.', 1;

PRINT 'OK 18: no altera eventos posteriores con un cambio retroactivo';


-- Esperado: permite reemplazar al suplente que ingreso.
EXEC SPTRANS.uspSustitucion_Registrar 20, @p1, 901, @j13, @j12, @motivo;

IF partidos.fnJugadorEnCancha(@p1, @j12, 20) <> 0
   OR partidos.fnJugadorEnCancha(@p1, @j13, 20) <> 1
    THROW 51000, 'Fallo: permite reemplazar al suplente que ingreso.', 1;

PRINT 'OK 19: permite reemplazar al suplente que ingreso';

SELECT @evento = MAX(IdSustitucion)
FROM partidos.Sustitucion;


-- Esperado: rechaza la operacion por protege la edicion del cambio.
BEGIN TRY
    EXEC partidos.Evento_Modificacion @evento, 21, 'Gol', @p2, 901;

    THROW 51999, 'La operacion debio rechazarse.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51999 OR ERROR_MESSAGE() NOT LIKE '%corregir una sustitucion%'
        THROW;
END CATCH;

PRINT 'OK 20: protege la edicion del cambio';


-- Esperado: rechaza la operacion por protege la baja del evento de cambio.
BEGIN TRY
    EXEC partidos.Evento_Baja @evento;

    THROW 51999, 'La operacion debio rechazarse.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51999 OR ERROR_MESSAGE() NOT LIKE '%uspSustitucion_Bajar%'
        THROW;
END CATCH;

PRINT 'OK 21: protege la baja del evento de cambio';


-- Esperado: registra roja en el partido.
EXEC SPTRANS.uspAmonestacion_Registrar 30, @p1, 901, @j2, @arbitro, 'Roja', 'Falta';

IF NOT EXISTS (
    SELECT 1
    FROM partidos.Amonestacion A
    JOIN partidos.Evento E ON E.IdEvento = A.IdAmonestacion
    WHERE E.Partido = @p1
      AND A.Amonestado = @j2
      AND A.Tarjeta = 'Roja'
)
    THROW 51000, 'Fallo: registra roja en el partido.', 1;

PRINT 'OK 22: registra roja en el partido';

SELECT @evento = MAX(IdAmonestacion)
FROM partidos.Amonestacion;


-- Esperado: rechaza la operacion por protege la edicion de tarjeta.
BEGIN TRY
    EXEC partidos.Evento_Modificacion @evento, 31, 'Gol', @p2, 901;

    THROW 51999, 'La operacion debio rechazarse.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51999 OR ERROR_MESSAGE() NOT LIKE '%amonestacion debe modificarse%'
        THROW;
END CATCH;

PRINT 'OK 23: protege la edicion de tarjeta';


-- Esperado: rechaza la operacion por gol posterior a expulsion.
BEGIN TRY
    EXEC SPTRANS.uspGol_Registrar 31, @p1, 901, @j2, NULL, 'Jugada';

    THROW 51999, 'La operacion debio rechazarse.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51999 OR ERROR_MESSAGE() NOT LIKE '%autor no estaba%'
        THROW;
END CATCH;

PRINT 'OK 24: gol posterior a expulsion';


-- Esperado: no reemplaza a un expulsado.
BEGIN TRY
    SELECT @cantidad = COUNT(*)
    FROM partidos.Sustitucion;

    EXEC SPTRANS.uspSustitucion_Registrar 31, @p1, 901, @j14, @j2, @motivo;

    THROW 51999, 'La operacion debio rechazarse.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51999 OR ERROR_MESSAGE() NOT LIKE '%egreso no estaba%'
        THROW;
END CATCH;

IF (SELECT COUNT(*) FROM partidos.Sustitucion) <> @cantidad
    THROW 51000, 'Fallo: no reemplaza a un expulsado.', 1;

PRINT 'OK 25: no reemplaza a un expulsado';


-- Esperado: no ingresa un suplente expulsado.
BEGIN TRY
    EXEC SPTRANS.uspAmonestacion_Registrar 32, @p1, 901, @j14, @arbitro, 'Roja', 'Falta en banco';

    SELECT @cantidad = COUNT(*)
    FROM partidos.Sustitucion;

    EXEC SPTRANS.uspSustitucion_Registrar 33, @p1, 901, @j14, @j13, @motivo;

    THROW 51999, 'La operacion debio rechazarse.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51999 OR ERROR_MESSAGE() NOT LIKE '%ingresar un jugador expulsado%'
        THROW;
END CATCH;

IF (SELECT COUNT(*) FROM partidos.Sustitucion) <> @cantidad
    THROW 51000, 'Fallo: no ingresa un suplente expulsado.', 1;

PRINT 'OK 26: no ingresa un suplente expulsado';


-- Esperado: una roja anterior no bloquea otro partido.
EXEC SPTRANS.uspAmonestacion_Registrar 10, @p2, 901, @j2, @arbitro, 'Amarilla', 'Falta';

IF NOT EXISTS (
    SELECT 1
    FROM partidos.Amonestacion A
    JOIN partidos.Evento E ON E.IdEvento = A.IdAmonestacion
    WHERE E.Partido = @p2
      AND A.Amonestado = @j2
      AND A.Tarjeta = 'Amarilla'
)
    THROW 51000, 'Fallo: una roja anterior no bloquea otro partido.', 1;

PRINT 'OK 27: una roja anterior no bloquea otro partido';


SELECT IdPartido, GolesEq1, GolesEq2
FROM partidos.Partido;

SELECT *
FROM partidos.Sustitucion;

SELECT *
FROM partidos.Amonestacion;

PRINT 'Grupo 2: 27 comprobaciones correctas.';