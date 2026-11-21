-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Comision 02
-- Grupo 7: Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 19/11/2026.
-- Objetivo: cargar los espacios publicitarios de cada sede con la metodologia de
-- tres fases (4 espacios por sede: 1 Banda LED perimetral, 2 Cartel de fondo,
-- 3 Videoboard y 4 Mencion en transmision).
--
-- DATOS DE EJEMPLO: ninguna fuente publica los espacios ni sus precios. Los
-- valores salen de Datos\Publicidad\script_generar_publicidad_seed.py y NO son
-- datos oficiales (ver Datos\Fuentes.txt, seccion 9). El .xlsx es la planilla de
-- entrega; el .csv es el que se importa porque BULK INSERT no lee xlsx.
--
--   FASE 1 STAGING     : se baja TODO el CSV y se resuelve la sede.
--   FASE 2 DEPURACION  : reglas de conjunto (UPDATE) sobre la staging.
--   FASE 3 PERSISTENCIA: solo las filas validas pasan por
--                        SP.EspacioPublicitario_Registrar o _Update.
--
-- Es idempotente: si el espacio ya existe con el mismo tipo y costo queda
-- 'SinCambios'; si cambio el tipo o el costo se actualiza con _Update (la sede
-- y el numero identifican la fila y no se mueven).
--
-- Requiere ejecutar antes la carga 08 (sedes).
-- SSMS: Consulta -> Modo SQLCMD. Ajustar las rutas del servidor SQL.
-- IMPORTANTE: cada integrante debe poner las rutas de su propia PC.
-- :setvar RutaEspacios "C:\ruta\proyecto\Datos\Publicidad\espacios_publicitarios.csv"

--L
--:setvar RutaEspacios "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Datos\Publicidad\espacios_publicitarios.csv"

--Fidel
--:setvar RutaEspacios "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Datos\Publicidad\espacios_publicitarios.csv"

--Santutu
:setvar RutaEspacios "C:\Users\Administrator\Desktop\tp_bdda\TP-2026-2C-Mundial-de-Futbol\Datos\Publicidad\espacios_publicitarios.csv"

USE MUNDIAL;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF @@TRANCOUNT <> 0 OR (2 & @@OPTIONS) = 2
    THROW 52200, 'Ejecute sin transaccion externa y con IMPLICIT_TRANSACTIONS OFF.', 1;
IF OBJECT_ID(N'sedes.Sede', N'U') IS NULL
   OR OBJECT_ID(N'publicidad.EspacioPublicitario', N'U') IS NULL
   OR OBJECT_ID(N'SP.EspacioPublicitario_Registrar', N'P') IS NULL
   OR OBJECT_ID(N'SP.EspacioPublicitario_Update', N'P') IS NULL
    THROW 52200, 'Faltan tablas o SP ABM. Ejecute primero el instalador.', 1;

IF OBJECT_ID(N'tempdb..#EspacioCrudo') IS NOT NULL DROP TABLE #EspacioCrudo;
IF OBJECT_ID(N'tempdb..#EspacioStaging') IS NOT NULL DROP TABLE #EspacioStaging;

---------------------------------------------------------------------------------------
-- FASE 1 - STAGING
---------------------------------------------------------------------------------------

CREATE TABLE #EspacioCrudo (
    Sede NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Numero NVARCHAR(10) COLLATE DATABASE_DEFAULT,
    Tipo NVARCHAR(60) COLLATE DATABASE_DEFAULT,
    Costo NVARCHAR(30) COLLATE DATABASE_DEFAULT
);

BEGIN TRY
    -- Con FORMAT='CSV' el terminador de fila debe coincidir con el fin de linea
    -- real del archivo: LF o CRLF segun como quedo el CSV en el disco (con
    -- core.autocrlf=true, Git lo deja en CRLF). Un terminador equivocado falla
    -- con el error 7301 al compilar el BULK INSERT, y TRY/CATCH no lo puede
    -- capturar: por eso se detecta leyendo el archivo y se elige el correcto.
    DECLARE @espaciosBytes VARBINARY(MAX) =
        (SELECT BulkColumn FROM OPENROWSET(BULK '$(RutaEspacios)', SINGLE_BLOB) AS f);
    IF CHARINDEX(0x0D0A, @espaciosBytes) > 0
        BULK INSERT #EspacioCrudo FROM '$(RutaEspacios)'
        WITH (FORMAT='CSV', FIRSTROW=2, FIELDTERMINATOR=',',
              ROWTERMINATOR='0x0d0a', CODEPAGE='65001', MAXERRORS=0);
    ELSE
        BULK INSERT #EspacioCrudo FROM '$(RutaEspacios)'
        WITH (FORMAT='CSV', FIRSTROW=2, FIELDTERMINATOR=',',
              ROWTERMINATOR='0x0a', CODEPAGE='65001', MAXERRORS=0);
END TRY
BEGIN CATCH
    DECLARE @mensaje NVARCHAR(2048) = LEFT(N'No se pudo leer espacios_publicitarios.csv. '
                                           + ERROR_MESSAGE(), 2048);
    THROW 52201, @mensaje, 1;
END CATCH;

CREATE TABLE #EspacioStaging (
    Fila INT IDENTITY(1,1) PRIMARY KEY,
    Sede NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Numero INT,
    Tipo NVARCHAR(60) COLLATE DATABASE_DEFAULT,
    Costo DECIMAL(10,2),
    IdSede INT,
    IdEP INT,
    TipoActual VARCHAR(30) COLLATE DATABASE_DEFAULT,
    CostoActual DECIMAL(10,2),
    Estado VARCHAR(20) COLLATE DATABASE_DEFAULT NOT NULL DEFAULT 'Pendiente',
    Detalle NVARCHAR(2048) COLLATE DATABASE_DEFAULT
);

INSERT #EspacioStaging (Sede, Numero, Tipo, Costo)
SELECT LTRIM(RTRIM(Sede)),
       TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(Numero)), N'')),
       LTRIM(RTRIM(Tipo)),
       TRY_CONVERT(DECIMAL(10,2), NULLIF(LTRIM(RTRIM(Costo)), N''))
FROM #EspacioCrudo;

DROP TABLE #EspacioCrudo;

IF NOT EXISTS (SELECT 1 FROM #EspacioStaging)
    THROW 52202, 'El CSV de espacios publicitarios quedo vacio; revise la ruta y el formato.', 1;

-- La sede se resuelve por nombre: es unica en sedes.Sede.
UPDATE s SET IdSede = se.IdSede
FROM #EspacioStaging AS s
JOIN sedes.Sede AS se ON se.Nombre = s.Sede;

---------------------------------------------------------------------------------------
-- FASE 2 - DEPURACION
---------------------------------------------------------------------------------------

-- D1: la sede del CSV no existe en el modelo (carga 08).
UPDATE #EspacioStaging SET Estado='Error',
    Detalle=N'La sede '+ISNULL(Sede, N'(vacia)')
            +N' no existe en sedes.Sede: revise la carga 08.'
WHERE Estado='Pendiente' AND IdSede IS NULL;

-- D2: numero fuera del rango que admite el modelo (1 a 4).
UPDATE #EspacioStaging SET Estado='Error',
    Detalle=N'El numero de espacio debe estar entre 1 y 4.'
WHERE Estado='Pendiente' AND (Numero IS NULL OR Numero NOT BETWEEN 1 AND 4);

-- D3: tipo vacio o mas largo que la columna (VARCHAR(30)).
UPDATE #EspacioStaging SET Estado='Error',
    Detalle=N'El tipo de espacio es obligatorio y admite hasta 30 caracteres.'
WHERE Estado='Pendiente' AND (Tipo IS NULL OR Tipo = N'' OR LEN(Tipo) > 30);

-- D4: costo ausente o negativo.
UPDATE #EspacioStaging SET Estado='Error',
    Detalle=N'La fuente no trae un costo valido (no nulo y no negativo).'
WHERE Estado='Pendiente' AND (Costo IS NULL OR Costo < 0);

-- D5: la sede y el numero se repiten dentro del CSV.
UPDATE s SET Estado='Error',
    Detalle=N'La sede y el numero de espacio se repiten en el CSV.'
FROM #EspacioStaging AS s
JOIN (SELECT IdSede, Numero FROM #EspacioStaging
      WHERE Estado='Pendiente' GROUP BY IdSede, Numero HAVING COUNT(*) > 1) AS d
  ON d.IdSede = s.IdSede AND d.Numero = s.Numero
WHERE s.Estado='Pendiente';

-- D6: el espacio ya existe. Se compara con lo cargado para decidir entre
--     'SinCambios' y actualizacion.
UPDATE s SET IdEP = e.IdEP, TipoActual = e.Tipo, CostoActual = e.Costo
FROM #EspacioStaging AS s
JOIN publicidad.EspacioPublicitario AS e
  ON e.IdSede = s.IdSede AND e.Numero = s.Numero
WHERE s.Estado='Pendiente';

UPDATE #EspacioStaging SET Estado='SinCambios',
    Detalle=N'El espacio ya estaba cargado con el mismo tipo y costo.'
WHERE Estado='Pendiente' AND IdEP IS NOT NULL
  AND TipoActual = Tipo AND CostoActual = Costo;

-- D7 (aviso): el espacio existe y cambia el tipo, el costo o ambos.
UPDATE #EspacioStaging SET Detalle = N'Se actualiza el espacio cargado (tipo/costo).'
WHERE Estado='Pendiente' AND IdEP IS NOT NULL;

-- Reporte de la depuracion: se informa ANTES de escribir en la tabla real.
SELECT 'FASE 2 - Depuracion de espacios publicitarios (antes de la persistencia)' AS Fase;
SELECT Estado, COUNT(*) AS Cantidad FROM #EspacioStaging GROUP BY Estado ORDER BY Estado;
SELECT Fila, Sede, Numero, Tipo, Costo, TipoActual, CostoActual, Estado, Detalle
FROM #EspacioStaging WHERE Estado IN ('Error') OR Detalle IS NOT NULL ORDER BY Fila;

---------------------------------------------------------------------------------------
-- FASE 3 - PERSISTENCIA
---------------------------------------------------------------------------------------

DECLARE @fila INT, @idSede INT, @numero INT, @tipo NVARCHAR(60),
        @costo DECIMAL(10,2), @idEP INT, @estado VARCHAR(20);
DECLARE crsEspacios CURSOR LOCAL FAST_FORWARD FOR
    SELECT Fila, IdSede, Numero, Tipo, Costo, IdEP
    FROM #EspacioStaging WHERE Estado='Pendiente' ORDER BY Fila;
OPEN crsEspacios;
FETCH NEXT FROM crsEspacios INTO @fila, @idSede, @numero, @tipo, @costo, @idEP;
WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @idEP IS NULL
        BEGIN
            EXEC SP.EspacioPublicitario_Registrar
                 @tipo=@tipo, @costo=@costo, @idSede=@idSede, @numero=@numero;
            SELECT @idEP=IdEP
            FROM publicidad.EspacioPublicitario
            WHERE IdSede=@idSede AND Numero=@numero;
            SET @estado='Insertada';
        END
        ELSE
        BEGIN
            EXEC SP.EspacioPublicitario_Update
                 @idEP=@idEP, @tipo=@tipo, @costo=@costo;
            SET @estado='Actualizada';
        END;
        COMMIT TRANSACTION;
        UPDATE #EspacioStaging SET IdEP=@idEP WHERE Fila=@fila;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        SET @estado='Error';
        UPDATE #EspacioStaging SET Detalle=ERROR_MESSAGE() WHERE Fila=@fila;
    END CATCH;
    UPDATE #EspacioStaging SET Estado=@estado WHERE Fila=@fila;
    FETCH NEXT FROM crsEspacios INTO @fila, @idSede, @numero, @tipo, @costo, @idEP;
END;
CLOSE crsEspacios;
DEALLOCATE crsEspacios;

-- Reporte final.
SELECT 'FASE 3 - Persistencia de espacios publicitarios' AS Fase;
SELECT Estado, COUNT(*) AS Cantidad FROM #EspacioStaging GROUP BY Estado ORDER BY Estado;
SELECT Fila, Sede, Numero, Tipo, Costo, IdEP, Estado, Detalle
FROM #EspacioStaging ORDER BY Fila;

-- Cobertura por sede: el juego de ejemplo tiene 4 espacios en cada una.
SELECT 'Cobertura de espacios publicitarios' AS Fase,
       COUNT(*) AS Espacios,
       COUNT(DISTINCT IdSede) AS Sedes,
       MIN(Costo) AS CostoMinimo,
       MAX(Costo) AS CostoMaximo
FROM publicidad.EspacioPublicitario;

SELECT 'Sedes sin espacios publicitarios' AS Fase, s.IdSede, s.Nombre
FROM sedes.Sede AS s
WHERE NOT EXISTS (SELECT 1 FROM publicidad.EspacioPublicitario AS e WHERE e.IdSede = s.IdSede)
ORDER BY s.Nombre;

DECLARE @fallos INT = (SELECT COUNT(*) FROM #EspacioStaging WHERE Estado='Error');
DROP TABLE #EspacioStaging;
IF @fallos > 0
    THROW 52204, 'Importacion parcial: se conservaron los espacios correctos. Revise el detalle.', 1;
GO
