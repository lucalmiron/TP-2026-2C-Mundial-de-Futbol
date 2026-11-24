-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Comision 02
-- Grupo 7: Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 18/11/2026.
-- Objetivo: cargar la asistencia de publico de los 104 partidos del Mundial con
-- la metodologia de tres fases, usando el calendario de la API publica de FIFA
-- (asistencia_partidos.csv, generado por Datos\Datos_Partidos\script_descargar_fifa_oficiales_API.py).
--
-- La carga 11 no toma la asistencia. Se importa aparte porque es un atributo
-- del partido que se actualiza con SP.uspPartido_Update y no participa del alta
-- del fixture. Los 104 valores coinciden con openfootball (fuente independiente).
--
-- El partido se resuelve por el par de selecciones: el nro_partido de FIFA no
-- coincide con el orden de openfootball ni con el GameId de Promiedos.
--
--   FASE 1 STAGING     : se baja TODO el CSV y se resuelve el partido.
--   FASE 2 DEPURACION  : reglas de conjunto (UPDATE) sobre la staging.
--   FASE 3 PERSISTENCIA: solo las filas validas pasan por SP.uspPartido_Update.
--
-- Requiere ejecutar antes las cargas 06 (paises) y 11 (partidos).
-- SSMS: Consulta -> Modo SQLCMD. TP_BDDA se define en los archivos 00_Importar_Todo_Parte*.sql.
-- IMPORTANTE: no editar rutas aca; TP_BDDA se define en los archivos 00_Importar_Todo_Parte*.sql.




USE MUNDIAL;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF @@TRANCOUNT <> 0 OR (2 & @@OPTIONS) = 2
    THROW 52100, 'Ejecute sin transaccion externa y con IMPLICIT_TRANSACTIONS OFF.', 1;
IF OBJECT_ID(N'partidos.Partido', N'U') IS NULL
   OR OBJECT_ID(N'equipos.Seleccion', N'U') IS NULL
   OR OBJECT_ID(N'SP.uspPartido_Update', N'P') IS NULL
    THROW 52100, 'Faltan tablas o SP ABM. Ejecute primero el instalador.', 1;

IF OBJECT_ID(N'tempdb..#AsistenciaCrudo') IS NOT NULL DROP TABLE #AsistenciaCrudo;
IF OBJECT_ID(N'tempdb..#AsistenciaStaging') IS NOT NULL DROP TABLE #AsistenciaStaging;

---------------------------------------------------------------------------------------
-- FASE 1 - STAGING
---------------------------------------------------------------------------------------

CREATE TABLE #AsistenciaCrudo (
    Fecha NVARCHAR(10) COLLATE DATABASE_DEFAULT,
    EquipoLocal NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    EquipoVisitante NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Asistencia NVARCHAR(20) COLLATE DATABASE_DEFAULT
);

BEGIN TRY
    -- Con FORMAT='CSV' el terminador de fila debe coincidir con el fin de linea
    -- real del archivo: LF o CRLF segun como quedo el CSV en el disco (con
    -- core.autocrlf=true, Git lo deja en CRLF). Un terminador equivocado falla
    -- con el error 7301 al compilar el BULK INSERT, y TRY/CATCH no lo puede
    -- capturar: por eso se detecta leyendo el archivo y se elige el correcto.
    DECLARE @asistenciaBytes VARBINARY(MAX) =
        (SELECT BulkColumn FROM OPENROWSET(BULK '$(TP_BDDA)\Datos\Datos_Partidos\asistencia_partidos.csv', SINGLE_BLOB) AS f);
    IF CHARINDEX(0x0D0A, @asistenciaBytes) > 0
        BULK INSERT #AsistenciaCrudo FROM '$(TP_BDDA)\Datos\Datos_Partidos\asistencia_partidos.csv'
        WITH (FORMAT='CSV', FIRSTROW=2, FIELDTERMINATOR=',',
              ROWTERMINATOR='0x0d0a', CODEPAGE='65001', MAXERRORS=0);
    ELSE
        BULK INSERT #AsistenciaCrudo FROM '$(TP_BDDA)\Datos\Datos_Partidos\asistencia_partidos.csv'
        WITH (FORMAT='CSV', FIRSTROW=2, FIELDTERMINATOR=',',
              ROWTERMINATOR='0x0a', CODEPAGE='65001', MAXERRORS=0);
END TRY
BEGIN CATCH
    DECLARE @mensaje NVARCHAR(2048) = LEFT(N'No se pudo leer asistencia_partidos.csv. '
                                           + ERROR_MESSAGE(), 2048);
    THROW 52101, @mensaje, 1;
END CATCH;

CREATE TABLE #AsistenciaStaging (
    Fila INT IDENTITY(1,1) PRIMARY KEY,
    Fecha DATE,
    EquipoLocal NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    EquipoVisitante NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Asistencia INT,
    IdPartido INT,
    AsistenciaActual INT,
    Estado VARCHAR(20) COLLATE DATABASE_DEFAULT NOT NULL DEFAULT 'Pendiente',
    Detalle NVARCHAR(2048) COLLATE DATABASE_DEFAULT
);

INSERT #AsistenciaStaging (Fecha, EquipoLocal, EquipoVisitante, Asistencia)
SELECT TRY_CONVERT(DATE, LTRIM(RTRIM(Fecha)), 23),
       LTRIM(RTRIM(EquipoLocal)),
       LTRIM(RTRIM(EquipoVisitante)),
       TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(Asistencia)), N''))
FROM #AsistenciaCrudo;

DROP TABLE #AsistenciaCrudo;

IF NOT EXISTS (SELECT 1 FROM #AsistenciaStaging)
    THROW 52102, 'El CSV de asistencia quedo vacio; revise la ruta y el formato.', 1;

-- Si el fixture tuviera el mismo cruce dos veces, el UPDATE elegiria uno al azar.
IF EXISTS (SELECT 1 FROM partidos.Partido WHERE IdMundial = 1
           GROUP BY Eq1, Eq2 HAVING COUNT(*) > 1)
    THROW 52103, 'Hay pares de selecciones repetidos en partidos.Partido: no se puede cruzar por equipos.', 1;

UPDATE s SET IdPartido = m.IdPartido
FROM #AsistenciaStaging AS s
JOIN equipos.Pais AS p1 ON p1.NOMBRE = s.EquipoLocal
JOIN equipos.Seleccion AS e1 ON e1.IdPais = p1.IdPais AND e1.IdMundial = 1
JOIN equipos.Pais AS p2 ON p2.NOMBRE = s.EquipoVisitante
JOIN equipos.Seleccion AS e2 ON e2.IdPais = p2.IdPais AND e2.IdMundial = 1
JOIN partidos.Partido AS m ON m.IdMundial = 1
                          AND m.Eq1 = e1.IdSeleccion
                          AND m.Eq2 = e2.IdSeleccion;

UPDATE s SET AsistenciaActual = m.Asistencia
FROM #AsistenciaStaging AS s
JOIN partidos.Partido AS m ON m.IdPartido = s.IdPartido;

---------------------------------------------------------------------------------------
-- FASE 2 - DEPURACION
---------------------------------------------------------------------------------------

-- D1: el partido no se pudo resolver por el par de selecciones.
UPDATE #AsistenciaStaging SET Estado='Error',
    Detalle=N'No se pudo resolver el partido con '+EquipoLocal+N' vs '+EquipoVisitante
            +N': revise que la carga 11 tenga ese cruce y los nombres en equipos.Pais.'
WHERE Estado='Pendiente' AND IdPartido IS NULL;

-- D2: asistencia ausente o no positiva.
UPDATE #AsistenciaStaging SET Estado='Error',
    Detalle=N'La fuente no trae una asistencia valida para el partido.'
WHERE Estado='Pendiente' AND (Asistencia IS NULL OR Asistencia <= 0);

-- D3: el partido ya tiene esa asistencia.
UPDATE #AsistenciaStaging SET Estado='SinCambios',
    Detalle=N'El partido ya tenia esa asistencia.'
WHERE Estado='Pendiente' AND AsistenciaActual = Asistencia;

-- D4 (aviso): el partido ya tenia otra asistencia cargada y se actualiza.
UPDATE #AsistenciaStaging SET Detalle = N'Se reemplaza la asistencia cargada ('
        + CONVERT(NVARCHAR(20), AsistenciaActual) + N') por la de la fuente.'
WHERE Estado='Pendiente' AND AsistenciaActual IS NOT NULL AND AsistenciaActual <> Asistencia;

-- Reporte de la depuracion.
SELECT 'FASE 2 - Depuracion de asistencia (antes de la persistencia)' AS Fase;
SELECT Estado, COUNT(*) AS Cantidad FROM #AsistenciaStaging GROUP BY Estado ORDER BY Estado;
SELECT Fila, Fecha, EquipoLocal, EquipoVisitante, Asistencia, AsistenciaActual, Estado, Detalle
FROM #AsistenciaStaging WHERE Estado IN ('Error') OR Detalle IS NOT NULL ORDER BY Fila;

---------------------------------------------------------------------------------------
-- FASE 3 - PERSISTENCIA
---------------------------------------------------------------------------------------

DECLARE @fila INT, @idPartido INT, @asistencia INT, @estado VARCHAR(20);
DECLARE crsAsistencia CURSOR LOCAL FAST_FORWARD FOR
    SELECT Fila, IdPartido, Asistencia
    FROM #AsistenciaStaging WHERE Estado='Pendiente' ORDER BY Fila;
OPEN crsAsistencia;
FETCH NEXT FROM crsAsistencia INTO @fila, @idPartido, @asistencia;
WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        -- El SP usa COALESCE: se pasa solo el id y la asistencia; el resto de los
        -- campos del partido quedan como estaban.
        EXEC SP.uspPartido_Update @Id=@idPartido, @Asistencia=@asistencia;
        COMMIT TRANSACTION;
        SET @estado='Actualizada';
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        SET @estado='Error';
        UPDATE #AsistenciaStaging SET Detalle=ERROR_MESSAGE() WHERE Fila=@fila;
    END CATCH;
    UPDATE #AsistenciaStaging SET Estado=@estado WHERE Fila=@fila;
    FETCH NEXT FROM crsAsistencia INTO @fila, @idPartido, @asistencia;
END;
CLOSE crsAsistencia;
DEALLOCATE crsAsistencia;

-- Reporte final.
SELECT 'FASE 3 - Persistencia de asistencia' AS Fase;
SELECT Estado, COUNT(*) AS Cantidad FROM #AsistenciaStaging GROUP BY Estado ORDER BY Estado;
SELECT Fila, Fecha, EquipoLocal, EquipoVisitante, IdPartido, Asistencia, Estado, Detalle
FROM #AsistenciaStaging ORDER BY Fila;

-- Cobertura sobre el fixture completo.
SELECT 'Cobertura de asistencia' AS Fase,
       COUNT(*) AS Partidos,
       SUM(CASE WHEN Asistencia IS NOT NULL THEN 1 ELSE 0 END) AS ConAsistencia,
       SUM(CASE WHEN Asistencia IS NULL THEN 1 ELSE 0 END) AS SinAsistencia
FROM partidos.Partido WHERE IdMundial = 1;

DECLARE @fallos INT = (SELECT COUNT(*) FROM #AsistenciaStaging WHERE Estado='Error');
DROP TABLE #AsistenciaStaging;
IF @fallos > 0
    THROW 52104, 'Importacion parcial: se conservaron las asistencias correctas. Revise el detalle.', 1;
GO
