-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Comision 02
-- Grupo 7: Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 25/11/2026.
-- Objetivo: cargar los cambios de convocatoria (reemplazos en la lista de
-- convocados entre partidos) desde un CSV. Se usa la metodologia de tres fases.
--   FASE 1 STAGING     : las lineas del CSV, tal cual.
--   FASE 2 DEPURACION  : reglas de conjunto sobre la staging.
--   FASE 3 PERSISTENCIA : solo los cambios validos pasan por
--                         SPTRANS.uspCambioConvocatoria_Registrar.
-- Los jugadores que ingresan (ingreso) son los RESERVAS cargados por 10b, que
-- ya estan Inactivos; por eso no hace falta ningun paso previo de baja logica.
-- Requiere ejecutar antes las cargas 06 (paises), 06b (mundial), 07 (selecciones),
-- 10 (jugadores) y 10b (reservas).
-- SSMS: Consulta -> Modo SQLCMD. TP_BDDA se define en los archivos 00_Importar_Todo_Parte*.sql.
-- IMPORTANTE: no editar rutas aca; TP_BDDA se define en los archivos 00_Importar_Todo_Parte*.sql.

USE MUNDIAL;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF @@TRANCOUNT <> 0 OR (2 & @@OPTIONS) = 2
    THROW 51900, 'Ejecute sin transaccion externa y con IMPLICIT_TRANSACTIONS OFF.', 1;
IF OBJECT_ID(N'equipos.CambioConvocatoria', N'U') IS NULL
   OR OBJECT_ID(N'SPTRANS.uspCambioConvocatoria_Registrar', N'P') IS NULL
    THROW 51900, 'Faltan tablas o SP ABM. Ejecute primero el instalador.', 1;

IF OBJECT_ID(N'tempdb..#CambiosCrudo') IS NOT NULL DROP TABLE #CambiosCrudo;
IF OBJECT_ID(N'tempdb..#CambiosStaging') IS NOT NULL DROP TABLE #CambiosStaging;

---------------------------------------------------------------------------------------
-- FASE 1 - STAGING
---------------------------------------------------------------------------------------

CREATE TABLE #CambiosCrudo (
    Archivo NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Contenido VARCHAR(MAX) COLLATE Latin1_General_100_CI_AS_SC_UTF8
);
CREATE TABLE #CambiosStaging (
    Fila INT IDENTITY(1,1) PRIMARY KEY,
    Archivo NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    NumeroLinea INT,
    LineaOriginal NVARCHAR(MAX) COLLATE DATABASE_DEFAULT,
    CantidadCampos INT,
    SeleccionTexto NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    EgresoTexto NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    IngresoTexto NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    FechaTexto NVARCHAR(20) COLLATE DATABASE_DEFAULT,
    MotivoTexto NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    IdSeleccion INT,
    IdEgreso INT,
    IdIngreso INT,
    Fecha DATE,
    Estado VARCHAR(20) COLLATE DATABASE_DEFAULT NOT NULL DEFAULT 'Pendiente',
    Detalle NVARCHAR(2048) COLLATE DATABASE_DEFAULT
);

BEGIN TRY
    INSERT #CambiosCrudo (Archivo, Contenido)
    SELECT N'cambios_convocatoria.csv', BulkColumn
    FROM OPENROWSET(BULK '$(TP_BDDA)\Datos\cambios_convocatoria.csv', SINGLE_BLOB) AS archivo;
END TRY
BEGIN CATCH
    DECLARE @mensaje NVARCHAR(2048) = LEFT(N'No se pudo leer el CSV de cambios de convocatoria: ' + ERROR_MESSAGE(), 2048);
    THROW 51901, @mensaje, 1;
END CATCH;

DECLARE @texto NVARCHAR(MAX) =
    (SELECT CONVERT(NVARCHAR(MAX), Contenido) FROM #CambiosCrudo);

;WITH Lineas AS (
    SELECT ordinal AS Ordinal, REPLACE(value, NCHAR(13), N'') AS Linea
    FROM STRING_SPLIT(@texto, NCHAR(10), 1)
), Numeradas AS (
    SELECT ROW_NUMBER() OVER (ORDER BY Ordinal) AS Numero, Linea
    FROM Lineas WHERE LTRIM(RTRIM(Linea)) <> ''
)
INSERT #CambiosStaging
    (Archivo, NumeroLinea, LineaOriginal, CantidadCampos,
     SeleccionTexto, EgresoTexto, IngresoTexto, FechaTexto, MotivoTexto)
SELECT N'cambios_convocatoria.csv', n.Numero, n.Linea,
       (SELECT COUNT(*) FROM STRING_SPLIT(n.Linea, N',', 1)),
       (SELECT MAX(v.value) FROM STRING_SPLIT(n.Linea, N',', 1) AS v WHERE v.ordinal=1),
       (SELECT MAX(v.value) FROM STRING_SPLIT(n.Linea, N',', 1) AS v WHERE v.ordinal=2),
       (SELECT MAX(v.value) FROM STRING_SPLIT(n.Linea, N',', 1) AS v WHERE v.ordinal=3),
       (SELECT MAX(v.value) FROM STRING_SPLIT(n.Linea, N',', 1) AS v WHERE v.ordinal=4),
       (SELECT MAX(v.value) FROM STRING_SPLIT(n.Linea, N',', 1) AS v WHERE v.ordinal=5)
FROM Numeradas AS n
WHERE n.Numero > 1;

DECLARE @cabecera NVARCHAR(200);
SELECT TOP (1) @cabecera = LTRIM(RTRIM(REPLACE(v.value, NCHAR(13), N'')))
FROM STRING_SPLIT(@texto, NCHAR(10), 1) AS v
WHERE LTRIM(RTRIM(REPLACE(v.value, NCHAR(13), N''))) <> '';
IF @cabecera IS NULL OR @cabecera <> N'seleccion,egreso,ingreso,fecha,motivo'
    THROW 51901, N'La cabecera de cambios_convocatoria.csv no es la esperada.', 1;

IF NOT EXISTS (SELECT 1 FROM #CambiosStaging)
    THROW 51901, 'El CSV de cambios de convocatoria esta vacio.', 1;

UPDATE #CambiosStaging SET
    SeleccionTexto = LTRIM(RTRIM(SeleccionTexto)),
    EgresoTexto = LTRIM(RTRIM(EgresoTexto)),
    IngresoTexto = LTRIM(RTRIM(IngresoTexto)),
    FechaTexto = LTRIM(RTRIM(FechaTexto)),
    MotivoTexto = LTRIM(RTRIM(MotivoTexto));

---------------------------------------------------------------------------------------
-- Resolver el IdJugador del ingreso por nombre (los ingresos son los reservas
-- cargados por 10b, ya Inactivos; no hace falta ninguna baja logica previa).
---------------------------------------------------------------------------------------
UPDATE s SET IdIngreso = (
    SELECT MIN(j.IdJugador)
    FROM equipos.Persona p
    JOIN equipos.Jugador j ON j.IdJugador = p.IdPersona
    WHERE p.Nombre = s.IngresoTexto
)
FROM #CambiosStaging s
WHERE s.Estado = 'Pendiente';

---------------------------------------------------------------------------------------
-- FASE 2 - DEPURACION
---------------------------------------------------------------------------------------

-- D1: la linea no tiene 5 campos.
UPDATE #CambiosStaging SET Estado='Error',
    Detalle=N'La linea del archivo no tiene 5 campos.'
WHERE Estado='Pendiente' AND CantidadCampos <> 5;

-- D2: algun campo vacio.
UPDATE #CambiosStaging SET Estado='Error',
    Detalle=N'Hay campos vacios (seleccion, egreso, ingreso, fecha o motivo).'
WHERE Estado='Pendiente' AND (
    NULLIF(SeleccionTexto,N'') IS NULL OR NULLIF(EgresoTexto,N'') IS NULL
    OR NULLIF(IngresoTexto,N'') IS NULL OR NULLIF(FechaTexto,N'') IS NULL
    OR NULLIF(MotivoTexto,N'') IS NULL);

-- D3: la fecha no es valida.
UPDATE #CambiosStaging SET Estado='Error',
    Detalle=N'La fecha no es valida.'
WHERE Estado='Pendiente' AND TRY_CONVERT(DATE, FechaTexto) IS NULL;

-- Resolver la seleccion por nombre de pais.
UPDATE s SET IdSeleccion = (
    SELECT MIN(sel.IdSeleccion)
    FROM equipos.Seleccion sel
    JOIN equipos.Pais p ON p.IdPais = sel.IdPais
    WHERE p.NOMBRE = s.SeleccionTexto
)
FROM #CambiosStaging s
WHERE s.Estado = 'Pendiente';

-- D4: la seleccion no existe o no esta cargada.
UPDATE #CambiosStaging SET Estado='Error',
    Detalle=N'La seleccion no existe o no esta cargada.'
WHERE Estado='Pendiente' AND IdSeleccion IS NULL;

-- Resolver el egreso por nombre.
UPDATE s SET IdEgreso = (
    SELECT MIN(j.IdJugador)
    FROM equipos.Persona p
    JOIN equipos.Jugador j ON j.IdJugador = p.IdPersona
    WHERE p.Nombre = s.EgresoTexto AND j.Seleccion = s.IdSeleccion
)
FROM #CambiosStaging s
WHERE s.Estado = 'Pendiente';

-- D5: el egreso no existe o no pertenece a la seleccion.
UPDATE #CambiosStaging SET Estado='Error',
    Detalle=N'El egreso no existe o no pertenece a la seleccion.'
WHERE Estado='Pendiente' AND IdEgreso IS NULL;

-- D6: el ingreso no existe o no pertenece a la seleccion.
UPDATE #CambiosStaging SET Estado='Error',
    Detalle=N'El ingreso no existe o no pertenece a la seleccion.'
WHERE Estado='Pendiente' AND IdIngreso IS NULL;

-- D7: egreso e ingreso son el mismo jugador.
UPDATE #CambiosStaging SET Estado='Error',
    Detalle=N'Egreso e ingreso no pueden ser el mismo jugador.'
WHERE Estado='Pendiente' AND IdEgreso = IdIngreso;

-- D8: el egreso no es convocado (Activo o Suspendido).
UPDATE #CambiosStaging SET Estado='Error',
    Detalle=N'El egreso no es un convocado activo o suspendido de la seleccion.'
WHERE Estado='Pendiente' AND NOT EXISTS (
    SELECT 1 FROM equipos.Jugador WHERE IdJugador = IdEgreso AND Estado IN ('Activo','Suspendido'));

-- D9: el ingreso no esta Inactivo (debe ser un reserva cargado por 10b).
UPDATE #CambiosStaging SET Estado='Error',
    Detalle=N'El ingreso no esta inactivo (debe ser un reserva cargado por 10b).'
WHERE Estado='Pendiente' AND EXISTS (
    SELECT 1 FROM equipos.Jugador WHERE IdJugador = IdIngreso AND Estado <> 'Inactivo');

-- D10: el egreso tiene alineaciones desde la fecha del cambio.
UPDATE s SET Estado='Error',
    Detalle=N'El egreso tiene alineaciones desde la fecha del cambio.'
FROM #CambiosStaging s
WHERE s.Estado='Pendiente' AND EXISTS (
    SELECT 1 FROM partidos.Alineacion A
    JOIN partidos.Partido P ON P.IdPartido = A.IdPartido
    WHERE A.IdJugador = s.IdEgreso AND P.Fecha >= TRY_CONVERT(DATE, s.FechaTexto));

-- D11: ya existe un cambio posterior para estos jugadores.
UPDATE s SET Estado='Error',
    Detalle=N'Existen cambios de convocatoria posteriores para estos jugadores.'
FROM #CambiosStaging s
WHERE s.Estado='Pendiente' AND EXISTS (
    SELECT 1 FROM equipos.CambioConvocatoria
    WHERE (Ingreso IN (s.IdIngreso, s.IdEgreso) OR Egreso IN (s.IdIngreso, s.IdEgreso))
      AND Fecha > TRY_CONVERT(DATE, s.FechaTexto));

-- D12: duplicado en el archivo.
UPDATE f SET Estado='Duplicada', Detalle=N'El cambio ya aparece en otra fila del archivo.'
FROM #CambiosStaging f
WHERE f.Estado='Pendiente' AND EXISTS (
    SELECT 1 FROM #CambiosStaging o
    WHERE o.IdSeleccion=f.IdSeleccion AND o.IdEgreso=f.IdEgreso AND o.IdIngreso=f.IdIngreso AND o.Fila<f.Fila
);

-- Reporte de la depuracion.
SELECT 'FASE 2 - Depuracion de cambios de convocatoria (antes de la persistencia)' AS Fase;
SELECT Estado, COUNT(*) AS Cantidad FROM #CambiosStaging GROUP BY Estado ORDER BY Estado;
SELECT Fila, NumeroLinea, SeleccionTexto AS Seleccion, EgresoTexto AS Egreso, IngresoTexto AS Ingreso, FechaTexto AS Fecha, MotivoTexto AS Motivo, Estado, Detalle
FROM #CambiosStaging WHERE Estado IN ('Error','Duplicada') ORDER BY Fila;

---------------------------------------------------------------------------------------
-- FASE 3 - PERSISTENCIA
---------------------------------------------------------------------------------------

DECLARE @fila INT, @estado VARCHAR(20);
DECLARE @idSel INT, @idEgr INT, @idIng INT, @fecha DATE, @motivo VARCHAR(200);
DECLARE crsCambios CURSOR LOCAL FAST_FORWARD FOR
    SELECT Fila, IdSeleccion, IdEgreso, IdIngreso, TRY_CONVERT(DATE, FechaTexto), CONVERT(VARCHAR(200), MotivoTexto)
    FROM #CambiosStaging WHERE Estado='Pendiente' ORDER BY Fila;
OPEN crsCambios;
FETCH NEXT FROM crsCambios INTO @fila, @idSel, @idEgr, @idIng, @fecha, @motivo;
WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        EXEC SPTRANS.uspCambioConvocatoria_Registrar
            @seleccion = @idSel, @egreso = @idEgr, @ingreso = @idIng,
            @fecha = @fecha, @motivo = @motivo;
        COMMIT TRANSACTION;
        SET @estado = 'Insertado';
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        SET @estado = 'Error';
        UPDATE #CambiosStaging SET Detalle = ERROR_MESSAGE() WHERE Fila = @fila;
    END CATCH;
    UPDATE #CambiosStaging SET Estado = @estado WHERE Fila = @fila;
    FETCH NEXT FROM crsCambios INTO @fila, @idSel, @idEgr, @idIng, @fecha, @motivo;
END;
CLOSE crsCambios;
DEALLOCATE crsCambios;

-- Reporte final.
SELECT 'FASE 3 - Persistencia de cambios de convocatoria' AS Fase;
SELECT Estado, COUNT(*) AS Cantidad FROM #CambiosStaging GROUP BY Estado ORDER BY Estado;
SELECT Fila, NumeroLinea, SeleccionTexto AS Seleccion, EgresoTexto AS Egreso, IngresoTexto AS Ingreso, FechaTexto AS Fecha, MotivoTexto AS Motivo, Estado, Detalle
FROM #CambiosStaging ORDER BY Fila;

DECLARE @fallos INT = (SELECT COUNT(*) FROM #CambiosStaging WHERE Estado='Error');
DROP TABLE #CambiosCrudo;
DROP TABLE #CambiosStaging;
IF @fallos > 0
    THROW 51904, 'Importacion parcial: se conservaron los cambios correctos. Revise el detalle.', 1;
GO