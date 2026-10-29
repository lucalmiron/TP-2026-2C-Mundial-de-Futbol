-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Grupo 7
-- Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 26/10/26.
-- Objetivo: comprobar conversiones de horarios.
-- Ejecutar en una base vacia MUNDIAL_Horarios_Test*, con las tablas y SP reales instalados.
-- Los datos son exclusivos de esta base de prueba. No ejecutar en MUNDIAL.

SET NOCOUNT ON;

IF DB_NAME() NOT LIKE 'MUNDIAL[_]Horarios[_]Test%'
    THROW 51000, 'Seleccionar una base MUNDIAL_Horarios_Test para estas pruebas.', 1;

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
VALUES (@pais1, '20260601', '20260731', 0, 26, 10, 10, 2, 1);
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


-- convierte al dia anterior y admite etiqueta.

IF CAST(sedes.fnFechaHoraLocal('20260701', '01:00', 'UTC-3 (G)') AS DATE) <> '20260630'
   OR CAST(sedes.fnFechaHoraLocal('20260701', '01:00', 'UTC-3 (G)') AS TIME) <> '22:00'
    THROW 51000, 'Fallo: convierte al dia anterior y admite etiqueta.', 1;

PRINT 'OK 1: convierte al dia anterior y admite etiqueta';


-- convierte al dia siguiente con minutos.

IF CAST(sedes.fnFechaHoraLocal('20260701', '23:00', 'UTC+05:30') AS DATE) <> '20260702'
   OR CAST(sedes.fnFechaHoraLocal('20260701', '23:00', 'UTC+05:30') AS TIME) <> '04:30'
    THROW 51000, 'Fallo: convierte al dia siguiente con minutos.', 1;

PRINT 'OK 2: convierte al dia siguiente con minutos';


-- rechaza husos invalidos.

IF sedes.fnFechaHoraLocal('20260701', '12:00', 'UTC+14:30') IS NOT NULL
   OR sedes.fnFechaHoraLocal('20260701', '12:00', 'UTC-3x') IS NOT NULL
   OR sedes.fnFechaHoraLocal('20260701', '12:00', 'Desconocido') IS NOT NULL
    THROW 51000, 'Fallo: rechaza husos invalidos.', 1;

PRINT 'OK 3: rechaza husos invalidos';


-- aplica horario estacional de una zona de Windows.

IF CAST(sedes.fnFechaHoraLocal('20260115', '18:00', 'Eastern Standard Time') AS TIME) <> '13:00'
   OR CAST(sedes.fnFechaHoraLocal('20260715', '18:00', 'Eastern Standard Time') AS TIME) <> '14:00'
    THROW 51000, 'Fallo: aplica horario estacional de una zona de Windows.', 1;

PRINT 'OK 4: aplica horario estacional de una zona de Windows';

UPDATE sedes.HusoHorario
SET Nombre = 'UTC-3 (G)'
WHERE IdHuso = @huso;

DECLARE @nuevo INT,
        @huso2 INT,
        @sede2 INT;


-- rechaza alta con hora local incorrecta.
BEGIN TRY
    EXEC SP.uspPartido_Registrar @fase, @sede, @mundial, @s1, @s2, '20260715', '01:00', '01:00';

    THROW 51999, 'La operacion debio rechazarse.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51999 OR ERROR_MESSAGE() NOT LIKE '%hora local no coincide%'
        THROW;
END CATCH;

PRINT 'OK 5: rechaza alta con hora local incorrecta';


-- consulta ambas fechas al cruzar medianoche.
EXEC SP.uspPartido_Registrar @fase, @sede, @mundial, @s1, @s2, '20260715', '01:00', '22:00';

SELECT @nuevo = MAX(IdPartido)
FROM partidos.Partido;

IF NOT EXISTS (
    SELECT 1
    FROM partidos.vHorarioPartido
    WHERE IdPartido = @nuevo
      AND FechaUTC = '20260715'
      AND FechaLocal = '20260714'
      AND HoraLocal = '22:00'
)
    THROW 51000, 'Fallo: consulta ambas fechas al cruzar medianoche.', 1;

PRINT 'OK 6: consulta ambas fechas al cruzar medianoche';


-- recalcula hora local al modificar UTC.
EXEC SP.uspPartido_Update @Id = @nuevo, @HoraUTC = '18:00';

IF (SELECT HoraLocal FROM partidos.Partido WHERE IdPartido = @nuevo) <> '15:00'
    THROW 51000, 'Fallo: recalcula hora local al modificar UTC.', 1;

PRINT 'OK 7: recalcula hora local al modificar UTC';


-- rechaza edicion local contradictoria.
BEGIN TRY
    EXEC SP.uspPartido_Update @Id = @nuevo, @HoraLocal = '16:00';

    THROW 51999, 'La operacion debio rechazarse.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51999 OR ERROR_MESSAGE() NOT LIKE '%hora local no coincide%'
        THROW;
END CATCH;

PRINT 'OK 8: rechaza edicion local contradictoria';

INSERT sedes.HusoHorario (Nombre, IdPais)
VALUES ('Eastern Standard Time', @pais1);
SET @huso2 = SCOPE_IDENTITY();

INSERT sedes.Sede (Nombre, Ciudad, Capacidad, IdPais, IdHuso)
VALUES ('Sede horaria', 'Prueba', 50000, @pais1, @huso2);
SET @sede2 = SCOPE_IDENTITY();


-- recalcula al cambiar sede.
EXEC SP.uspPartido_Update @Id = @nuevo, @IdSede = @sede2;

IF (SELECT HoraLocal FROM partidos.Partido WHERE IdPartido = @nuevo) <> '14:00'
    THROW 51000, 'Fallo: recalcula al cambiar sede.', 1;

PRINT 'OK 9: recalcula al cambiar sede';


-- recalcula al cambiar fecha y horario estacional.
EXEC SP.uspPartido_Update @Id = @nuevo, @Fecha = '20260115';

IF (SELECT HoraLocal FROM partidos.Partido WHERE IdPartido = @nuevo) <> '13:00'
    THROW 51000, 'Fallo: recalcula al cambiar fecha y horario estacional.', 1;

PRINT 'OK 10: recalcula al cambiar fecha y horario estacional';

UPDATE sedes.HusoHorario
SET Nombre = 'Desconocido'
WHERE IdHuso = @huso2;


-- rechaza edicion con huso desconocido.
BEGIN TRY
    EXEC SP.uspPartido_Update @Id = @nuevo, @HoraUTC = '20:00';

    THROW 51999, 'La operacion debio rechazarse.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51999 OR ERROR_MESSAGE() NOT LIKE '%Huso horario no reconocido%'
        THROW;
END CATCH;

PRINT 'OK 11: rechaza edicion con huso desconocido';


-- rechaza alta con huso desconocido.
BEGIN TRY
    EXEC SP.uspPartido_Registrar @fase, @sede2, @mundial, @s1, @s2, '20260716', '18:00', '18:00';

    THROW 51999, 'La operacion debio rechazarse.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51999 OR ERROR_MESSAGE() NOT LIKE '%Huso horario no reconocido%'
        THROW;
END CATCH;

PRINT 'OK 12: rechaza alta con huso desconocido';


-- rechazos conservan horario anterior.

IF (SELECT HoraUTC FROM partidos.Partido WHERE IdPartido = @nuevo) <> '18:00'
   OR (SELECT HoraLocal FROM partidos.Partido WHERE IdPartido = @nuevo) <> '13:00'
    THROW 51000, 'Fallo: rechazos conservan horario anterior.', 1;

PRINT 'OK 13: rechazos conservan horario anterior';


PRINT 'Horarios: 13 comprobaciones correctas.';
