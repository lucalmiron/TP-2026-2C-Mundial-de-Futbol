-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Comision 02
-- Grupo 7: Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 19/11/2026.
-- Objetivo: cargar el costo de cada franja horaria por sede (Manana, Tarde y
-- Prime time) con la metodologia de tres fases.
--
-- DATOS DE EJEMPLO: ninguna fuente publica las tarifas. Los valores salen de
-- Datos\Publicidad\script_generar_publicidad_seed.py y NO son datos oficiales
-- (ver Datos\Fuentes.txt, seccion 9). El .xlsx es la planilla de entrega; el
-- .csv es el que se importa porque BULK INSERT no lee xlsx.
--
--   FASE 1 STAGING     : se baja TODO el CSV y se resuelve la sede.
--   FASE 2 DEPURACION  : reglas de conjunto (UPDATE) sobre la staging.
--   FASE 3 PERSISTENCIA: solo las filas validas pasan por
--                        SP.CostoFranja_Registrar o _Update.
--
-- Es idempotente: la franja se identifica por (sede, tipo). Si ya existe con el
-- mismo costo queda 'SinCambios'; si cambia el costo se actualiza con _Update.
-- Ojo: _Update rechaza renombrar una franja ya usada en HistorialPublicidad.
--
-- Requiere ejecutar antes la carga 08 (sedes).
-- SSMS: Consulta -> Modo SQLCMD. Ajustar las rutas del servidor SQL.
-- IMPORTANTE: cada integrante debe poner las rutas de su propia PC.
-- :setvar RutaCostoFranja "C:\ruta\proyecto\Datos\Publicidad\costo_franja.csv"

--L
--:setvar RutaCostoFranja "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Datos\Publicidad\costo_franja.csv"

--Fidel
--:setvar RutaCostoFranja "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Datos\Publicidad\costo_franja.csv"

--santutu
:setvar RutaCostoFranja "C:\Users\Administrator\Desktop\tp_bdda\TP-2026-2C-Mundial-de-Futbol\Datos\Publicidad\costo_franja.csv"

USE MUNDIAL;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF @@TRANCOUNT <> 0 OR (2 & @@OPTIONS) = 2
    THROW 52300, 'Ejecute sin transaccion externa y con IMPLICIT_TRANSACTIONS OFF.', 1;
IF OBJECT_ID(N'sedes.Sede', N'U') IS NULL
   OR OBJECT_ID(N'publicidad.CostoFranja', N'U') IS NULL
   OR OBJECT_ID(N'SP.CostoFranja_Registrar', N'P') IS NULL
   OR OBJECT_ID(N'SP.CostoFranja_Update', N'P') IS NULL
   OR OBJECT_ID(N'publicidad.HistorialPublicidad', N'U') IS NULL
    THROW 52300, 'Faltan tablas o SP ABM. Ejecute primero el instalador.', 1;

IF OBJECT_ID(N'tempdb..#FranjaCrudo') IS NOT NULL DROP TABLE #FranjaCrudo;
IF OBJECT_ID(N'tempdb..#FranjaStaging') IS NOT NULL DROP TABLE #FranjaStaging;

---------------------------------------------------------------------------------------
-- FASE 1 - STAGING
---------------------------------------------------------------------------------------

CREATE TABLE #FranjaCrudo (
    Sede NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    TipoFranja NVARCHAR(60) COLLATE DATABASE_DEFAULT,
    Costo NVARCHAR(30) COLLATE DATABASE_DEFAULT
);

BEGIN TRY
    BULK INSERT #FranjaCrudo FROM '$(RutaCostoFranja)'
    WITH (FORMAT='CSV', FIRSTROW=2, FIELDTERMINATOR=',',
          ROWTERMINATOR='0x0d0a', CODEPAGE='65001', MAXERRORS=0);
END TRY
BEGIN CATCH
    DECLARE @mensaje NVARCHAR(2048) = LEFT(N'No se pudo leer costo_franja.csv. '
                                           + ERROR_MESSAGE(), 2048);
    THROW 52301, @mensaje, 1;
END CATCH;

CREATE TABLE #FranjaStaging (
    Fila INT IDENTITY(1,1) PRIMARY KEY,
    Sede NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    TipoFranja NVARCHAR(60) COLLATE DATABASE_DEFAULT,
    Costo DECIMAL(10,2),
    IdSede INT,
    IdCF INT,
    CostoActual DECIMAL(10,2),
    Estado VARCHAR(20) COLLATE DATABASE_DEFAULT NOT NULL DEFAULT 'Pendiente',
    Detalle NVARCHAR(2048) COLLATE DATABASE_DEFAULT
);

INSERT #FranjaStaging (Sede, TipoFranja, Costo)
SELECT LTRIM(RTRIM(Sede)),
       LTRIM(RTRIM(TipoFranja)),
       TRY_CONVERT(DECIMAL(10,2), NULLIF(LTRIM(RTRIM(Costo)), N''))
FROM #FranjaCrudo;

DROP TABLE #FranjaCrudo;

IF NOT EXISTS (SELECT 1 FROM #FranjaStaging)
    THROW 52302, 'El CSV de costos por franja quedo vacio; revise la ruta y el formato.', 1;

-- La sede se resuelve por nombre: es unica en sedes.Sede.
UPDATE s SET IdSede = se.IdSede
FROM #FranjaStaging AS s
JOIN sedes.Sede AS se ON se.Nombre = s.Sede;

---------------------------------------------------------------------------------------
-- FASE 2 - DEPURACION
---------------------------------------------------------------------------------------

-- D1: la sede del CSV no existe en el modelo (carga 08).
UPDATE #FranjaStaging SET Estado='Error',
    Detalle=N'La sede '+ISNULL(Sede, N'(vacia)')
            +N' no existe en sedes.Sede: revise la carga 08.'
WHERE Estado='Pendiente' AND IdSede IS NULL;

-- D2: tipo de franja vacio o mas largo que la columna (VARCHAR(30)).
UPDATE #FranjaStaging SET Estado='Error',
    Detalle=N'El tipo de franja es obligatorio y admite hasta 30 caracteres.'
WHERE Estado='Pendiente'
  AND (TipoFranja IS NULL OR TipoFranja = N'' OR LEN(TipoFranja) > 30);

-- D3: costo ausente o negativo.
UPDATE #FranjaStaging SET Estado='Error',
    Detalle=N'La fuente no trae un costo valido (no nulo y no negativo).'
WHERE Estado='Pendiente' AND (Costo IS NULL OR Costo < 0);

-- D4: la sede y la franja se repiten dentro del CSV.
UPDATE s SET Estado='Error',
    Detalle=N'La sede y el tipo de franja se repiten en el CSV.'
FROM #FranjaStaging AS s
JOIN (SELECT IdSede, TipoFranja FROM #FranjaStaging
      WHERE Estado='Pendiente'
      GROUP BY IdSede, TipoFranja HAVING COUNT(*) > 1) AS d
  ON d.IdSede = s.IdSede AND d.TipoFranja = s.TipoFranja
WHERE s.Estado='Pendiente';

-- D5: la franja ya existe; se compara el costo con el cargado.
UPDATE s SET IdCF = c.IdCF, CostoActual = c.Costo
FROM #FranjaStaging AS s
JOIN publicidad.CostoFranja AS c
  ON c.IdSede = s.IdSede AND c.TipoFranja = s.TipoFranja
WHERE s.Estado='Pendiente';

UPDATE #FranjaStaging SET Estado='SinCambios',
    Detalle=N'La franja ya estaba cargada con el mismo costo.'
WHERE Estado='Pendiente' AND IdCF IS NOT NULL AND CostoActual = Costo;

-- D6 (aviso): la franja existe y cambia el costo.
UPDATE #FranjaStaging SET Detalle = N'Se actualiza el costo de la franja cargada.'
WHERE Estado='Pendiente' AND IdCF IS NOT NULL;

-- Reporte de la depuracion: se informa ANTES de escribir en la tabla real.
SELECT 'FASE 2 - Depuracion de costos por franja (antes de la persistencia)' AS Fase;
SELECT Estado, COUNT(*) AS Cantidad FROM #FranjaStaging GROUP BY Estado ORDER BY Estado;
SELECT Fila, Sede, TipoFranja, Costo, CostoActual, Estado, Detalle
FROM #FranjaStaging WHERE Estado IN ('Error') OR Detalle IS NOT NULL ORDER BY Fila;

---------------------------------------------------------------------------------------
-- FASE 3 - PERSISTENCIA
---------------------------------------------------------------------------------------

DECLARE @fila INT, @idSede INT, @tipoFranja NVARCHAR(60), @costo DECIMAL(10,2),
        @idCF INT, @estado VARCHAR(20);
DECLARE crsFranjas CURSOR LOCAL FAST_FORWARD FOR
    SELECT Fila, IdSede, TipoFranja, Costo, IdCF
    FROM #FranjaStaging WHERE Estado='Pendiente' ORDER BY Fila;
OPEN crsFranjas;
FETCH NEXT FROM crsFranjas INTO @fila, @idSede, @tipoFranja, @costo, @idCF;
WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @idCF IS NULL
        BEGIN
            EXEC SP.CostoFranja_Registrar
                 @tipoFranja=@tipoFranja, @costo=@costo, @idSede=@idSede;
            SELECT @idCF=IdCF
            FROM publicidad.CostoFranja
            WHERE IdSede=@idSede AND TipoFranja=@tipoFranja;
            SET @estado='Insertada';
        END
        ELSE
        BEGIN
            EXEC SP.CostoFranja_Update
                 @idCF=@idCF, @tipoFranja=@tipoFranja, @costo=@costo;
            SET @estado='Actualizada';
        END;
        COMMIT TRANSACTION;
        UPDATE #FranjaStaging SET IdCF=@idCF WHERE Fila=@fila;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        SET @estado='Error';
        UPDATE #FranjaStaging SET Detalle=ERROR_MESSAGE() WHERE Fila=@fila;
    END CATCH;
    UPDATE #FranjaStaging SET Estado=@estado WHERE Fila=@fila;
    FETCH NEXT FROM crsFranjas INTO @fila, @idSede, @tipoFranja, @costo, @idCF;
END;
CLOSE crsFranjas;
DEALLOCATE crsFranjas;

-- Reporte final.
SELECT 'FASE 3 - Persistencia de costos por franja' AS Fase;
SELECT Estado, COUNT(*) AS Cantidad FROM #FranjaStaging GROUP BY Estado ORDER BY Estado;
SELECT Fila, Sede, TipoFranja, Costo, IdCF, Estado, Detalle
FROM #FranjaStaging ORDER BY Fila;

-- Cobertura por sede: el juego de ejemplo tiene las 3 franjas en cada una.
SELECT 'Cobertura de costos por franja' AS Fase,
       COUNT(*) AS Franjas,
       COUNT(DISTINCT IdSede) AS Sedes,
       MIN(Costo) AS CostoMinimo,
       MAX(Costo) AS CostoMaximo
FROM publicidad.CostoFranja;

SELECT 'Sedes sin costos por franja' AS Fase, s.IdSede, s.Nombre
FROM sedes.Sede AS s
WHERE NOT EXISTS (SELECT 1 FROM publicidad.CostoFranja AS c WHERE c.IdSede = s.IdSede)
ORDER BY s.Nombre;

DECLARE @fallos INT = (SELECT COUNT(*) FROM #FranjaStaging WHERE Estado='Error');
DROP TABLE #FranjaStaging;
IF @fallos > 0
    THROW 52304, 'Importacion parcial: se conservaron las franjas correctas. Revise el detalle.', 1;
GO
