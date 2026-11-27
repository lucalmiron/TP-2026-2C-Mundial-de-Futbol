-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Comision 02
-- Grupo 7: Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 27/11/2026.
-- Objetivo: cargar los jugadores RESERVA de cada seleccion (los que todavia no
-- son convocados activos) desde un CSV, con la metodologia de tres fases.
--   FASE 1 STAGING     : se baja TODO a tablas temporales. #ReservasCrudo guarda
--                        el CSV original sin modificar y #ReservasStaging una
--                        fila por reserva, con las columnas Estado y Detalle.
--   FASE 2 DEPURACION  : reglas de conjunto (UPDATE) sobre la staging.
--   FASE 3 PERSISTENCIA : solo las filas validas pasan por
--                        SPTRANS.uspJugador_Registrar con @estado='Inactivo'.
-- Los reservas se dan de alta Inactivos: no ocupan lugar en la convocatoria
-- (el control de cupo del SP solo se aplica a los Activos), pero quedan
-- disponibles para ingresar en un cambio de convocatoria (carga 29).
-- Fecha de nacimiento: 1 de enero de anio_nacimiento, como en la carga 10.
-- Dorsal: unico por seleccion (UQ_Jugador_Dorsal); del 1 al 26 ya estan
-- ocupados, por eso los reservas usan 27 y 28.
-- Requiere ejecutar antes las cargas 06 (paises), 06b (mundial), 07
-- (selecciones), 09 (clubes) y 10 (jugadores).
-- SSMS: Consulta -> Modo SQLCMD. TP_BDDA se define en los archivos 00_Importar_Todo_Parte*.sql.
-- IMPORTANTE: no editar rutas aca; TP_BDDA se define en los archivos 00_Importar_Todo_Parte*.sql.

USE MUNDIAL;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF @@TRANCOUNT <> 0 OR (2 & @@OPTIONS) = 2
    THROW 51700, 'Ejecute sin transaccion externa y con IMPLICIT_TRANSACTIONS OFF.', 1;
IF OBJECT_ID(N'SPTRANS.uspJugador_Registrar', N'P') IS NULL
   OR OBJECT_ID(N'equipos.Jugador', N'U') IS NULL
   OR OBJECT_ID(N'equipos.Seleccion', N'U') IS NULL
   OR OBJECT_ID(N'equipos.Pais', N'U') IS NULL
   OR OBJECT_ID(N'equipos.Club', N'U') IS NULL
    THROW 51700, 'Faltan tablas o SP ABM. Ejecute primero el instalador y las cargas 06/06b/07/09/10.', 1;

IF OBJECT_ID(N'tempdb..#ReservasCrudo') IS NOT NULL DROP TABLE #ReservasCrudo;
IF OBJECT_ID(N'tempdb..#ReservasStaging') IS NOT NULL DROP TABLE #ReservasStaging;

---------------------------------------------------------------------------------------
-- FASE 1 - STAGING
-- Todavia no se descarta nada: primero baja todo a tablas temporales.
---------------------------------------------------------------------------------------

CREATE TABLE #ReservasCrudo (
    Archivo NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Contenido VARCHAR(MAX) COLLATE Latin1_General_100_CI_AS_SC_UTF8
);
CREATE TABLE #ReservasStaging (
    Fila INT IDENTITY(1,1) PRIMARY KEY,
    Archivo NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    NumeroLinea INT,
    LineaOriginal NVARCHAR(MAX) COLLATE DATABASE_DEFAULT,
    CantidadCampos INT,
    SeleccionTexto NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    NombreTexto NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    PosicionTexto NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    DorsalTexto NVARCHAR(20) COLLATE DATABASE_DEFAULT,
    AnioTexto NVARCHAR(20) COLLATE DATABASE_DEFAULT,
    ClubTexto NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    IdSeleccion INT,
    IdPais INT,
    IdClub INT,
    Dorsal INT,
    Anio INT,
    Estado VARCHAR(20) COLLATE DATABASE_DEFAULT NOT NULL DEFAULT 'Pendiente',
    Detalle NVARCHAR(2048) COLLATE DATABASE_DEFAULT
);

BEGIN TRY
    INSERT #ReservasCrudo (Archivo, Contenido)
    SELECT N'reservas_convocatoria.csv', BulkColumn
    FROM OPENROWSET(BULK '$(TP_BDDA)\Datos\reservas_convocatoria.csv', SINGLE_BLOB) AS archivo;
END TRY
BEGIN CATCH
    DECLARE @mensaje NVARCHAR(2048) = LEFT(N'No se pudo leer el CSV de reservas de convocatoria: ' + ERROR_MESSAGE(), 2048);
    THROW 51701, @mensaje, 1;
END CATCH;

DECLARE @texto NVARCHAR(MAX) =
    (SELECT CONVERT(NVARCHAR(MAX), Contenido) FROM #ReservasCrudo);

;WITH Lineas AS (
    SELECT ordinal AS Ordinal, REPLACE(value, NCHAR(13), N'') AS Linea
    FROM STRING_SPLIT(@texto, NCHAR(10), 1)
), Numeradas AS (
    SELECT ROW_NUMBER() OVER (ORDER BY Ordinal) AS Numero, Linea
    FROM Lineas WHERE LTRIM(RTRIM(Linea)) <> ''
)
INSERT #ReservasStaging
    (Archivo, NumeroLinea, LineaOriginal, CantidadCampos,
     SeleccionTexto, NombreTexto, PosicionTexto, DorsalTexto, AnioTexto, ClubTexto)
SELECT N'reservas_convocatoria.csv', n.Numero, n.Linea,
       (SELECT COUNT(*) FROM STRING_SPLIT(n.Linea, N',', 1)),
       (SELECT MAX(v.value) FROM STRING_SPLIT(n.Linea, N',', 1) AS v WHERE v.ordinal=1),
       (SELECT MAX(v.value) FROM STRING_SPLIT(n.Linea, N',', 1) AS v WHERE v.ordinal=2),
       (SELECT MAX(v.value) FROM STRING_SPLIT(n.Linea, N',', 1) AS v WHERE v.ordinal=3),
       (SELECT MAX(v.value) FROM STRING_SPLIT(n.Linea, N',', 1) AS v WHERE v.ordinal=4),
       (SELECT MAX(v.value) FROM STRING_SPLIT(n.Linea, N',', 1) AS v WHERE v.ordinal=5),
       (SELECT MAX(v.value) FROM STRING_SPLIT(n.Linea, N',', 1) AS v WHERE v.ordinal=6)
FROM Numeradas AS n
WHERE n.Numero > 1;

DECLARE @cabecera NVARCHAR(200);
SELECT TOP (1) @cabecera = LTRIM(RTRIM(REPLACE(v.value, NCHAR(13), N'')))
FROM STRING_SPLIT(@texto, NCHAR(10), 1) AS v
WHERE LTRIM(RTRIM(REPLACE(v.value, NCHAR(13), N''))) <> '';
IF @cabecera IS NULL OR @cabecera <> N'seleccion,nombre,posicion,dorsal,anio_nacimiento,club'
    THROW 51701, N'La cabecera de reservas_convocatoria.csv no es la esperada.', 1;

IF NOT EXISTS (SELECT 1 FROM #ReservasStaging)
    THROW 51701, 'El CSV de reservas de convocatoria esta vacio.', 1;

UPDATE #ReservasStaging SET
    SeleccionTexto = LTRIM(RTRIM(SeleccionTexto)),
    NombreTexto = LTRIM(RTRIM(NombreTexto)),
    PosicionTexto = LTRIM(RTRIM(PosicionTexto)),
    DorsalTexto = LTRIM(RTRIM(DorsalTexto)),
    AnioTexto = LTRIM(RTRIM(AnioTexto)),
    ClubTexto = LTRIM(RTRIM(ClubTexto));

---------------------------------------------------------------------------------------
-- FASE 2 - DEPURACION
-- Reglas de conjunto: cada UPDATE marca las filas invalidas y su motivo.
-- No se borra nada; las filas validas quedan en Estado = 'Pendiente'.
---------------------------------------------------------------------------------------

-- D1: la linea no tiene 6 campos.
UPDATE #ReservasStaging SET Estado='Error',
    Detalle=N'La linea del archivo no tiene 6 campos.'
WHERE Estado='Pendiente' AND CantidadCampos <> 6;

-- D2: algun campo obligatorio vacio (el club es opcional).
UPDATE #ReservasStaging SET Estado='Error',
    Detalle=N'Hay campos vacios (seleccion, nombre, posicion, dorsal o anio).'
WHERE Estado='Pendiente' AND (
    NULLIF(SeleccionTexto,N'') IS NULL OR NULLIF(NombreTexto,N'') IS NULL
    OR NULLIF(PosicionTexto,N'') IS NULL OR NULLIF(DorsalTexto,N'') IS NULL
    OR NULLIF(AnioTexto,N'') IS NULL);

-- D3: el dorsal no es un entero valido.
UPDATE #ReservasStaging SET Estado='Error',
    Detalle=N'El dorsal no es un numero entero valido.'
WHERE Estado='Pendiente'
  AND (TRY_CONVERT(INT, DorsalTexto) IS NULL OR TRY_CONVERT(INT, DorsalTexto) <= 0);

-- D4: el anio de nacimiento no es valido.
UPDATE #ReservasStaging SET Estado='Error',
    Detalle=N'El anio de nacimiento no es valido.'
WHERE Estado='Pendiente'
  AND (TRY_CONVERT(INT, AnioTexto) IS NULL OR TRY_CONVERT(INT, AnioTexto) < 1900
       OR TRY_CONVERT(INT, AnioTexto) > YEAR(GETDATE()));

-- D5: el nombre o la posicion exceden el largo del modelo.
UPDATE #ReservasStaging SET Estado='Error',
    Detalle=N'Nombre o posicion exceden el largo permitido (30/20).'
WHERE Estado='Pendiente' AND (LEN(NombreTexto) > 30 OR LEN(PosicionTexto) > 20);

-- Resolver el pais y la seleccion por nombre de pais (Mundial 1).
UPDATE s SET IdPais = (SELECT MIN(p.IdPais) FROM equipos.Pais p
                       WHERE p.NOMBRE = s.SeleccionTexto)
FROM #ReservasStaging s
WHERE s.Estado = 'Pendiente';

UPDATE s SET IdSeleccion = (SELECT MIN(sel.IdSeleccion) FROM equipos.Seleccion sel
                            WHERE sel.IdPais = s.IdPais AND sel.IdMundial = 1)
FROM #ReservasStaging s
WHERE s.Estado = 'Pendiente';

-- D6: la seleccion no existe o no esta cargada.
UPDATE #ReservasStaging SET Estado='Error',
    Detalle=N'La seleccion no existe o no esta cargada.'
WHERE Estado='Pendiente' AND (IdPais IS NULL OR IdSeleccion IS NULL);

-- Resolver el club por nombre (opcional).
UPDATE s SET IdClub = (SELECT MIN(c.IdClub) FROM equipos.Club c
                       WHERE c.Nombre = s.ClubTexto)
FROM #ReservasStaging s
WHERE s.Estado = 'Pendiente' AND NULLIF(s.ClubTexto,N'') IS NOT NULL;

-- D7: el club informado no existe (carga 09).
UPDATE #ReservasStaging SET Estado='Error',
    Detalle=N'El club informado no existe. Revisar errores del importador 09.'
WHERE Estado='Pendiente' AND NULLIF(ClubTexto,N'') IS NOT NULL AND IdClub IS NULL;

-- D8: el nombre se repite en la misma seleccion del archivo.
UPDATE f SET Estado='Error',
    Detalle=N'El nombre se repite en la misma seleccion del archivo.'
FROM #ReservasStaging f
WHERE f.Estado='Pendiente' AND EXISTS (
    SELECT 1 FROM #ReservasStaging o
    WHERE o.IdSeleccion = f.IdSeleccion AND o.NombreTexto = f.NombreTexto AND o.Fila < f.Fila);

-- D9: ya existe un jugador con ese nombre en la seleccion.
UPDATE s SET Estado='Error',
    Detalle=N'Ya existe un jugador con ese nombre en la seleccion.'
FROM #ReservasStaging s
WHERE s.Estado='Pendiente' AND EXISTS (
    SELECT 1 FROM equipos.Persona p
    JOIN equipos.Jugador j ON j.IdJugador = p.IdPersona
    WHERE j.Seleccion = s.IdSeleccion AND p.Nombre = s.NombreTexto);

-- D10: el dorsal ya esta ocupado en la seleccion.
UPDATE s SET Estado='Error',
    Detalle=N'El dorsal ya esta ocupado en la seleccion.'
FROM #ReservasStaging s
WHERE s.Estado='Pendiente' AND EXISTS (
    SELECT 1 FROM equipos.Jugador j
    WHERE j.Seleccion = s.IdSeleccion AND j.Numero = TRY_CONVERT(INT, s.DorsalTexto));

-- D11: el dorsal se repite en la misma seleccion del archivo.
UPDATE f SET Estado='Error',
    Detalle=N'El dorsal se repite en la misma seleccion del archivo.'
FROM #ReservasStaging f
WHERE f.Estado='Pendiente' AND EXISTS (
    SELECT 1 FROM #ReservasStaging o
    WHERE o.IdSeleccion = f.IdSeleccion AND o.DorsalTexto = f.DorsalTexto AND o.Fila < f.Fila);

-- Valores ya validados para la persistencia.
UPDATE #ReservasStaging
SET Dorsal = TRY_CONVERT(INT, DorsalTexto),
    Anio = TRY_CONVERT(INT, AnioTexto)
WHERE Estado = 'Pendiente';

-- Reporte de la depuracion: se informa ANTES de escribir en la tabla real.
SELECT 'FASE 2 - Depuracion de reservas (antes de la persistencia)' AS Fase;
SELECT Estado, COUNT(*) AS Cantidad FROM #ReservasStaging GROUP BY Estado ORDER BY Estado;
SELECT Fila, NumeroLinea, SeleccionTexto AS Seleccion, NombreTexto AS Nombre,
       PosicionTexto AS Posicion, DorsalTexto AS Dorsal, AnioTexto AS Anio,
       ClubTexto AS Club, Estado, Detalle
FROM #ReservasStaging WHERE Estado IN ('Error','Duplicada') ORDER BY Fila;

---------------------------------------------------------------------------------------
-- FASE 3 - PERSISTENCIA
-- Solo las filas que quedaron en 'Pendiente' llegan a la tabla real, siempre
-- a traves del SP de ABM, con Estado = 'Inactivo'.
---------------------------------------------------------------------------------------

DECLARE @fila INT, @nombre NVARCHAR(30), @pos NVARCHAR(20), @dorsal INT, @anio INT,
        @idPais INT, @idSel INT, @idClub INT, @estado VARCHAR(20), @fnac DATE;
DECLARE crsReservas CURSOR LOCAL FAST_FORWARD FOR
    SELECT Fila, CONVERT(NVARCHAR(30), NombreTexto), CONVERT(NVARCHAR(20), PosicionTexto),
           Dorsal, Anio, IdPais, IdSeleccion, IdClub
    FROM #ReservasStaging WHERE Estado='Pendiente' ORDER BY Fila;
OPEN crsReservas;
FETCH NEXT FROM crsReservas INTO @fila,@nombre,@pos,@dorsal,@anio,@idPais,@idSel,@idClub;
WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        SET @fnac = DATEFROMPARTS(@anio,1,1);
        BEGIN TRANSACTION;
        EXEC SPTRANS.uspJugador_Registrar
            @nombre = @nombre, @fnac = @fnac, @pais = @idPais,
            @posicion = @pos, @numero = @dorsal, @club = @idClub,
            @seleccion = @idSel, @estado = 'Inactivo';
        COMMIT TRANSACTION;
        SET @estado = 'Insertada';
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        SET @estado = 'Error';
        UPDATE #ReservasStaging SET Detalle = ERROR_MESSAGE() WHERE Fila = @fila;
    END CATCH;
    UPDATE #ReservasStaging SET Estado = @estado WHERE Fila = @fila;
    FETCH NEXT FROM crsReservas INTO @fila,@nombre,@pos,@dorsal,@anio,@idPais,@idSel,@idClub;
END;
CLOSE crsReservas;
DEALLOCATE crsReservas;

-- Reporte final de la persistencia.
SELECT 'FASE 3 - Persistencia de reservas' AS Fase;
SELECT Estado, COUNT(*) AS Cantidad FROM #ReservasStaging GROUP BY Estado ORDER BY Estado;
SELECT Fila, SeleccionTexto AS Seleccion, NombreTexto AS Nombre, PosicionTexto AS Posicion,
       Dorsal, Anio AS AnioNacimiento, ClubTexto AS Club, Estado, Detalle
FROM #ReservasStaging ORDER BY Fila;

DECLARE @fallos INT = (SELECT COUNT(*) FROM #ReservasStaging WHERE Estado='Error');
DROP TABLE #ReservasCrudo;
DROP TABLE #ReservasStaging;
IF @fallos > 0
    THROW 51704, 'Importacion parcial: se conservaron las reservas correctas. Revise el detalle.', 1;
GO