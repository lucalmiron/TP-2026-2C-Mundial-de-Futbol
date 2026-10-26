-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Grupo 7
-- Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 26/10/26.
-- Objetivo: comprobar jugadores y cambios de convocatoria.
-- Ejecutar en una base vacia MUNDIAL_Grupo3_Test*, con las tablas y SP reales instalados.
-- Los datos son exclusivos de esta base de prueba. No ejecutar en MUNDIAL.

SET NOCOUNT ON;

IF DB_NAME() NOT LIKE 'MUNDIAL[_]Grupo3[_]Test%'
    THROW 51000, 'Seleccionar una base MUNDIAL_Grupo3_Test para estas pruebas.', 1;

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

DECLARE @reemplazo INT,
        @cambio    INT,
        @segundo   INT;

UPDATE sedes.Mundial
SET TAMANIO_SELECCION_MAXIMO = 16
WHERE IdMundial = @mundial;


-- rechaza alta activa sin cupo.
BEGIN TRY
    EXEC SPTRANS.uspJugador_Registrar 'Activo sin lugar', '20000101', @pais1, 'MED', 30, NULL, @s1;

    THROW 51999, 'La operacion debio rechazarse.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51999 OR ERROR_MESSAGE() NOT LIKE '%Cupo maximo%'
        THROW;
END CATCH;

PRINT 'OK 1: rechaza alta activa sin cupo';


-- carga reemplazante con convocatoria completa.
EXEC SPTRANS.uspJugador_Registrar 'Reemplazante', '20000101', @pais1, 'MED', 30, NULL, @s1, 'Inactivo';

SELECT @reemplazo = IdPersona
FROM equipos.Persona
WHERE Nombre = 'Reemplazante';

IF NOT EXISTS (SELECT 1 FROM equipos.Jugador WHERE IdJugador = @reemplazo AND Estado = 'Inactivo')
   OR (SELECT COUNT(*) FROM equipos.Jugador WHERE Seleccion = @s1 AND Estado <> 'Inactivo') <> 16
    THROW 51000, 'Fallo: carga reemplazante con convocatoria completa.', 1;

PRINT 'OK 2: carga reemplazante con convocatoria completa';


-- no permite alta suspendida.
BEGIN TRY
    EXEC SPTRANS.uspJugador_Registrar 'Estado invalido', '20000101', @pais1, 'MED', 31, NULL, @s1, 'Suspendido';

    THROW 51999, 'La operacion debio rechazarse.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51999 OR ERROR_MESSAGE() NOT LIKE '%Estado inicial invalido%'
        THROW;
END CATCH;

PRINT 'OK 3: no permite alta suspendida';


-- controla dorsal del reemplazante.
BEGIN TRY
    EXEC SPTRANS.uspJugador_Registrar 'Dorsal repetido', '20000101', @pais1, 'MED', 1, NULL, @s1, 'Inactivo';

    THROW 51999, 'La operacion debio rechazarse.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51999 OR ERROR_MESSAGE() NOT LIKE '%Valor duplicado: Numero%'
        THROW;
END CATCH;

PRINT 'OK 4: controla dorsal del reemplazante';


-- conserva alta activa por defecto.
EXEC SPTRANS.uspJugador_Registrar 'Jugador destino', '20000101', @pais2, 'MED', 1, NULL, @s2;

IF NOT EXISTS (SELECT 1 FROM equipos.Jugador WHERE Seleccion = @s2 AND Estado = 'Activo' AND Numero = 1)
    THROW 51000, 'Fallo: conserva alta activa por defecto.', 1;

PRINT 'OK 5: conserva alta activa por defecto';


-- valida dorsal al cambiar solo seleccion.
BEGIN TRY
    EXEC SPTRANS.uspJugador_Update @id = @j1, @seleccion = @s2;

    THROW 51999, 'La operacion debio rechazarse.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51999 OR ERROR_MESSAGE() NOT LIKE '%Valor duplicado: Numero%'
        THROW;
END CATCH;

PRINT 'OK 6: valida dorsal al cambiar solo seleccion';

INSERT partidos.Alineacion (IdPartido, IdJugador, Rol, PosicionCancha)
VALUES (@p1, @j2, 'Titular', 'MED');


-- protege seleccion con alineaciones.
BEGIN TRY
    EXEC SPTRANS.uspJugador_Update @id = @j2, @seleccion = @s2;

    THROW 51999, 'La operacion debio rechazarse.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51999 OR ERROR_MESSAGE() NOT LIKE '%con historial%'
        THROW;
END CATCH;

PRINT 'OK 7: protege seleccion con alineaciones';


-- permite corregir datos sin cambiar seleccion.
EXEC SPTRANS.uspJugador_Update @id = @j2, @nombre = 'Jugador corregido';

IF NOT EXISTS (SELECT 1 FROM equipos.Persona WHERE IdPersona = @j2 AND Nombre = 'Jugador corregido')
    THROW 51000, 'Fallo: permite corregir datos sin cambiar seleccion.', 1;

PRINT 'OK 8: permite corregir datos sin cambiar seleccion';

UPDATE sedes.Mundial
SET TAMANIO_SELECCION_MINIMO = 16
WHERE IdMundial = @mundial;


-- controla minimo de origen.
BEGIN TRY
    EXEC SPTRANS.uspJugador_Update @id = @j12, @seleccion = @s2;

    THROW 51999, 'La operacion debio rechazarse.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51999 OR ERROR_MESSAGE() NOT LIKE '%Cupo minimo%'
        THROW;
END CATCH;

PRINT 'OK 9: controla minimo de origen';

UPDATE sedes.Mundial
SET TAMANIO_SELECCION_MINIMO = 0,
    TAMANIO_SELECCION_MAXIMO = 1
WHERE IdMundial = @mundial;


-- controla maximo de destino.
BEGIN TRY
    EXEC SPTRANS.uspJugador_Update @id = @j12, @seleccion = @s2;

    THROW 51999, 'La operacion debio rechazarse.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51999 OR ERROR_MESSAGE() NOT LIKE '%Cupo maximo%'
        THROW;
END CATCH;

PRINT 'OK 10: controla maximo de destino';

UPDATE sedes.Mundial
SET TAMANIO_SELECCION_MAXIMO = 16
WHERE IdMundial = @mundial;


-- permite cambio de seleccion sin historial y con cupo.
EXEC SPTRANS.uspJugador_Update @id = @j12, @seleccion = @s2;

IF (SELECT Seleccion FROM equipos.Jugador WHERE IdJugador = @j12) <> @s2
    THROW 51000, 'Fallo: permite cambio de seleccion sin historial y con cupo.', 1;

PRINT 'OK 11: permite cambio de seleccion sin historial y con cupo';

EXEC SPTRANS.uspJugador_Update @id = @j12, @seleccion = @s1;

UPDATE equipos.Jugador
SET Estado = 'Suspendido'
WHERE IdJugador = @j16;

UPDATE sedes.Mundial
SET TAMANIO_SELECCION_MINIMO = 16
WHERE IdMundial = @mundial;


-- no reactiva suspendidos como reemplazantes.
BEGIN TRY
    EXEC SPTRANS.uspCambioConvocatoria_Registrar @s1, @j1, @j16, '20260615', 'Reemplazo';

    THROW 51999, 'La operacion debio rechazarse.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51999 OR ERROR_MESSAGE() NOT LIKE '%debe ser un jugador inactivo%'
        THROW;
END CATCH;

PRINT 'OK 12: no reactiva suspendidos como reemplazantes';


-- protege alineaciones posteriores del egreso.
BEGIN TRY
    EXEC SPTRANS.uspCambioConvocatoria_Registrar @s1, @j2, @reemplazo, '20260615', 'Reemplazo';

    THROW 51999, 'La operacion debio rechazarse.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51999 OR ERROR_MESSAGE() NOT LIKE '%egreso tiene alineaciones%'
        THROW;
END CATCH;

PRINT 'OK 13: protege alineaciones posteriores del egreso';


-- reemplaza convocado contando suspendidos en el cupo.
EXEC SPTRANS.uspCambioConvocatoria_Registrar @s1, @j1, @reemplazo, '20260615', 'Lesion';

SELECT @cambio = MAX(IdCambio)
FROM equipos.CambioConvocatoria;

IF (SELECT Estado FROM equipos.Jugador WHERE IdJugador = @j1) <> 'Inactivo'
   OR (SELECT Estado FROM equipos.Jugador WHERE IdJugador = @reemplazo) <> 'Activo'
   OR (SELECT COUNT(*) FROM equipos.Jugador WHERE Seleccion = @s1 AND Estado <> 'Inactivo') <> 16
    THROW 51000, 'Fallo: reemplaza convocado contando suspendidos en el cupo.', 1;

PRINT 'OK 14: reemplaza convocado contando suspendidos en el cupo';


-- protege seleccion con cambios de convocatoria.
BEGIN TRY
    EXEC SPTRANS.uspJugador_Update @id = @reemplazo, @seleccion = @s2;

    THROW 51999, 'La operacion debio rechazarse.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51999 OR ERROR_MESSAGE() NOT LIKE '%con historial%'
        THROW;
END CATCH;

PRINT 'OK 15: protege seleccion con cambios de convocatoria';

INSERT partidos.Alineacion (IdPartido, IdJugador, Rol, PosicionCancha)
VALUES (@p1, @reemplazo, 'Titular', 'MED');


-- no anula reemplazo con participacion posterior.
BEGIN TRY
    EXEC SPTRANS.uspCambioConvocatoria_Bajar @cambio;

    THROW 51999, 'La operacion debio rechazarse.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51999 OR ERROR_MESSAGE() NOT LIKE '%ingreso tiene alineaciones%'
        THROW;
END CATCH;

PRINT 'OK 16: no anula reemplazo con participacion posterior';


-- rechazo conserva cambio y cierra transaccion.

IF NOT EXISTS (SELECT 1 FROM equipos.CambioConvocatoria WHERE IdCambio = @cambio)
   OR (SELECT Estado FROM equipos.Jugador WHERE IdJugador = @reemplazo) <> 'Activo'
   OR @@TRANCOUNT <> 0
    THROW 51000, 'Fallo: rechazo conserva cambio y cierra transaccion.', 1;

PRINT 'OK 17: rechazo conserva cambio y cierra transaccion';

DELETE partidos.Alineacion
WHERE IdPartido = @p1
  AND IdJugador = @reemplazo;

UPDATE equipos.Jugador
SET Estado = 'Suspendido'
WHERE IdJugador = @reemplazo;


-- no anula con estados alterados.
BEGIN TRY
    EXEC SPTRANS.uspCambioConvocatoria_Bajar @cambio;

    THROW 51999, 'La operacion debio rechazarse.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51999 OR ERROR_MESSAGE() NOT LIKE '%estados actuales%'
        THROW;
END CATCH;

PRINT 'OK 18: no anula con estados alterados';

UPDATE equipos.Jugador
SET Estado = 'Activo'
WHERE IdJugador = @reemplazo;


-- rechaza cambio anterior al historial.
BEGIN TRY
    EXEC SPTRANS.uspCambioConvocatoria_Registrar @s1, @reemplazo, @j1, '20260614', 'Anterior';

    THROW 51999, 'La operacion debio rechazarse.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51999 OR ERROR_MESSAGE() NOT LIKE '%posteriores%'
        THROW;
END CATCH;

PRINT 'OK 19: rechaza cambio anterior al historial';


-- registra segundo cambio el mismo dia.
EXEC SPTRANS.uspCambioConvocatoria_Registrar @s1, @reemplazo, @j1, '20260615', 'Retorno';

SELECT @segundo = MAX(IdCambio)
FROM equipos.CambioConvocatoria;

IF (SELECT Estado FROM equipos.Jugador WHERE IdJugador = @j1) <> 'Activo'
    THROW 51000, 'Fallo: registra segundo cambio el mismo dia.', 1;

PRINT 'OK 20: registra segundo cambio el mismo dia';


-- anula cambios del mismo dia en orden inverso.
BEGIN TRY
    EXEC SPTRANS.uspCambioConvocatoria_Bajar @cambio;

    THROW 51999, 'La operacion debio rechazarse.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51999 OR ERROR_MESSAGE() NOT LIKE '%Anule primero%'
        THROW;
END CATCH;

PRINT 'OK 21: anula cambios del mismo dia en orden inverso';


-- anula en orden y restituye estados.
EXEC SPTRANS.uspCambioConvocatoria_Bajar @segundo;
EXEC SPTRANS.uspCambioConvocatoria_Bajar @cambio;

IF EXISTS (SELECT 1 FROM equipos.CambioConvocatoria WHERE IdCambio IN (@segundo, @cambio))
   OR (SELECT Estado FROM equipos.Jugador WHERE IdJugador = @j1) <> 'Activo'
   OR (SELECT Estado FROM equipos.Jugador WHERE IdJugador = @reemplazo) <> 'Inactivo'
   OR @@TRANCOUNT <> 0
    THROW 51000, 'Fallo: anula en orden y restituye estados.', 1;

PRINT 'OK 22: anula en orden y restituye estados';


-- informa error al anular registro inexistente.
BEGIN TRY
    EXEC SPTRANS.uspCambioConvocatoria_Bajar @cambio;

    THROW 51999, 'La operacion debio rechazarse.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51999 OR ERROR_MESSAGE() NOT LIKE '%Registro inexistente%'
        THROW;
END CATCH;

PRINT 'OK 23: informa error al anular registro inexistente';


-- altas rechazadas no dejan personas huerfanas.

IF EXISTS (SELECT 1 FROM equipos.Persona WHERE Nombre IN ('Activo sin lugar', 'Estado invalido', 'Dorsal repetido'))
    THROW 51000, 'Fallo: altas rechazadas no dejan personas huerfanas.', 1;

PRINT 'OK 24: altas rechazadas no dejan personas huerfanas';


PRINT 'Grupo 3: 24 comprobaciones correctas.';