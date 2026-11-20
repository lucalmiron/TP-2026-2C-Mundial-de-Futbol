-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Comision 02
-- Grupo 7: Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 19/11/2026.
-- Objetivo: cargar el historial publicitario por partido (que campania ocupa
-- que espacio, en que franja y por cuanto) con la metodologia de tres fases.
--
-- DATOS DE EJEMPLO: no hay fuente que publique la pauta contratada. El archivo
-- sale de Datos\Publicidad\script_generar_publicidad_seed.py y NO son datos
-- oficiales (ver Datos\Fuentes.txt, seccion 9). El .xlsx es la planilla de
-- entrega; el .csv es el que se importa porque BULK INSERT no lee xlsx.
--
-- Cada fila trae fecha, equipos y sede, pero no identificadores: se resuelven
--   - el partido, por el par de selecciones y la fecha (el GameId de Promiedos
--     no coincide con IdPartido);
--   - el espacio, por (sede, numero)   -> carga 26;
--   - la franja,  por (sede, tipo)     -> carga 27;
--   - la campania, por publicidad.Publicidad.Nombre (titulo) -> carga 20.
--
--   FASE 1 STAGING     : se baja TODO el CSV y se resuelven las claves.
--   FASE 2 DEPURACION  : reglas de conjunto (UPDATE) sobre la staging.
--   FASE 3 PERSISTENCIA: solo las filas validas pasan por
--                        SP.uspHistorialPublicidad_Registrar o _Update.
--
-- Es idempotente: la fila se identifica por (partido, espacio). Si ya existe
-- con la misma campania, franja y costo queda 'SinCambios'; si cambia algo se
-- actualiza con _Update.
--
-- Requiere ejecutar antes las cargas 11 (partidos), 20 (publicidad),
-- 26 (espacios) y 27 (costos por franja).
-- SSMS: Consulta -> Modo SQLCMD. Ajustar las rutas del servidor SQL.
-- IMPORTANTE: cada integrante debe poner las rutas de su propia PC.
-- :setvar RutaHistorial "C:\ruta\proyecto\Datos\Publicidad\historial_publicidad.csv"

--L
--:setvar RutaHistorial "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Datos\Publicidad\historial_publicidad.csv"

--Fidel
:setvar RutaHistorial "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Datos\Publicidad\historial_publicidad.csv"

USE MUNDIAL;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF @@TRANCOUNT <> 0 OR (2 & @@OPTIONS) = 2
    THROW 52400, 'Ejecute sin transaccion externa y con IMPLICIT_TRANSACTIONS OFF.', 1;
IF OBJECT_ID(N'partidos.Partido', N'U') IS NULL
   OR OBJECT_ID(N'publicidad.Publicidad', N'U') IS NULL
   OR OBJECT_ID(N'publicidad.EspacioPublicitario', N'U') IS NULL
   OR OBJECT_ID(N'publicidad.CostoFranja', N'U') IS NULL
   OR OBJECT_ID(N'publicidad.HistorialPublicidad', N'U') IS NULL
   OR OBJECT_ID(N'SP.uspHistorialPublicidad_Registrar', N'P') IS NULL
   OR OBJECT_ID(N'SP.uspHistorialPublicidad_Update', N'P') IS NULL
    THROW 52400, 'Faltan tablas o SP ABM. Ejecute primero el instalador.', 1;

IF OBJECT_ID(N'tempdb..#HistorialCrudo') IS NOT NULL DROP TABLE #HistorialCrudo;
IF OBJECT_ID(N'tempdb..#HistorialStaging') IS NOT NULL DROP TABLE #HistorialStaging;

---------------------------------------------------------------------------------------
-- FASE 1 - STAGING
---------------------------------------------------------------------------------------

CREATE TABLE #HistorialCrudo (
    Fecha NVARCHAR(10) COLLATE DATABASE_DEFAULT,
    EquipoLocal NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    EquipoVisitante NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Sede NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    NumeroEspacio NVARCHAR(10) COLLATE DATABASE_DEFAULT,
    TipoFranja NVARCHAR(60) COLLATE DATABASE_DEFAULT,
    Publicidad NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    CostoFinal NVARCHAR(30) COLLATE DATABASE_DEFAULT
);

BEGIN TRY
    BULK INSERT #HistorialCrudo FROM '$(RutaHistorial)'
    WITH (FORMAT='CSV', FIRSTROW=2, FIELDTERMINATOR=',',
          ROWTERMINATOR='0x0d0a', CODEPAGE='65001', MAXERRORS=0);
END TRY
BEGIN CATCH
    DECLARE @mensaje NVARCHAR(2048) = LEFT(N'No se pudo leer historial_publicidad.csv. '
                                           + ERROR_MESSAGE(), 2048);
    THROW 52401, @mensaje, 1;
END CATCH;

CREATE TABLE #HistorialStaging (
    Fila INT IDENTITY(1,1) PRIMARY KEY,
    Fecha DATE,
    EquipoLocal NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    EquipoVisitante NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Sede NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    NumeroEspacio INT,
    TipoFranja NVARCHAR(60) COLLATE DATABASE_DEFAULT,
    Publicidad NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    CostoFinal DECIMAL(10,2),
    IdSede INT,
    IdPartido INT,
    IdSedePartido INT,
    IdEP INT,
    IdCF INT,
    IdPublicidad INT,
    CostoCalculado DECIMAL(10,2),
    IdHistorial INT,
    PublicidadActual NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    IdCFActual INT,
    CostoActual DECIMAL(10,2),
    Estado VARCHAR(20) COLLATE DATABASE_DEFAULT NOT NULL DEFAULT 'Pendiente',
    Detalle NVARCHAR(2048) COLLATE DATABASE_DEFAULT
);

INSERT #HistorialStaging (Fecha, EquipoLocal, EquipoVisitante, Sede, NumeroEspacio,
                          TipoFranja, Publicidad, CostoFinal)
SELECT TRY_CONVERT(DATE, LTRIM(RTRIM(Fecha)), 23),
       LTRIM(RTRIM(EquipoLocal)),
       LTRIM(RTRIM(EquipoVisitante)),
       LTRIM(RTRIM(Sede)),
       TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(NumeroEspacio)), N'')),
       LTRIM(RTRIM(TipoFranja)),
       LTRIM(RTRIM(Publicidad)),
       TRY_CONVERT(DECIMAL(10,2), NULLIF(LTRIM(RTRIM(CostoFinal)), N''))
FROM #HistorialCrudo;

DROP TABLE #HistorialCrudo;

IF NOT EXISTS (SELECT 1 FROM #HistorialStaging)
    THROW 52402, 'El CSV del historial publicitario quedo vacio; revise la ruta y el formato.', 1;

-- Sede del CSV.
UPDATE s SET IdSede = se.IdSede
FROM #HistorialStaging AS s
JOIN sedes.Sede AS se ON se.Nombre = s.Sede;

-- Partido: se cruza por el par de selecciones (en cualquier orden) y luego se
-- controla la fecha. Si el mismo cruce aparece dos veces, no se puede elegir.
IF EXISTS (SELECT 1 FROM partidos.Partido WHERE IdMundial = 1
           GROUP BY CASE WHEN Eq1 < Eq2 THEN Eq1 ELSE Eq2 END,
                    CASE WHEN Eq1 < Eq2 THEN Eq2 ELSE Eq1 END
           HAVING COUNT(*) > 1)
    THROW 52403, 'Hay pares de selecciones repetidos en partidos.Partido: no se puede cruzar por equipos.', 1;

UPDATE s SET IdPartido = m.IdPartido, IdSedePartido = m.IdSede
FROM #HistorialStaging AS s
JOIN equipos.Pais AS p1 ON p1.NOMBRE = s.EquipoLocal
JOIN equipos.Seleccion AS e1 ON e1.IdPais = p1.IdPais AND e1.IdMundial = 1
JOIN equipos.Pais AS p2 ON p2.NOMBRE = s.EquipoVisitante
JOIN equipos.Seleccion AS e2 ON e2.IdPais = p2.IdPais AND e2.IdMundial = 1
JOIN partidos.Partido AS m ON m.IdMundial = 1
                          AND ((m.Eq1 = e1.IdSeleccion AND m.Eq2 = e2.IdSeleccion)
                            OR (m.Eq1 = e2.IdSeleccion AND m.Eq2 = e1.IdSeleccion));

-- Espacio, franja y campania.
UPDATE s SET IdEP = e.IdEP, CostoCalculado = e.Costo
FROM #HistorialStaging AS s
JOIN publicidad.EspacioPublicitario AS e
  ON e.IdSede = s.IdSede AND e.Numero = s.NumeroEspacio;

UPDATE s SET IdCF = c.IdCF
FROM #HistorialStaging AS s
JOIN publicidad.CostoFranja AS c
  ON c.IdSede = s.IdSede AND c.TipoFranja = s.TipoFranja;

UPDATE s SET CostoCalculado = s.CostoCalculado + c.Costo
FROM #HistorialStaging AS s
JOIN publicidad.CostoFranja AS c ON c.IdCF = s.IdCF;

-- Campania: se resuelve solo si el nombre identifica una unica fila (D9 avisa
-- si no existe o si es ambiguo).
UPDATE s SET IdPublicidad = p.IdPublicidad
FROM #HistorialStaging AS s
JOIN publicidad.Publicidad AS p ON p.Nombre = s.Publicidad
WHERE (SELECT COUNT(*) FROM publicidad.Publicidad AS p2
       WHERE p2.Nombre = s.Publicidad) = 1;

---------------------------------------------------------------------------------------
-- FASE 2 - DEPURACION
---------------------------------------------------------------------------------------

-- D1: la fecha del CSV no es una fecha valida.
UPDATE #HistorialStaging SET Estado='Error',
    Detalle=N'La fecha del CSV no es una fecha valida.'
WHERE Estado='Pendiente' AND Fecha IS NULL;

-- D2: la sede del CSV no existe en el modelo (carga 08).
UPDATE #HistorialStaging SET Estado='Error',
    Detalle=N'La sede '+ISNULL(Sede, N'(vacia)')
            +N' no existe en sedes.Sede: revise la carga 08.'
WHERE Estado='Pendiente' AND IdSede IS NULL;

-- D3: no se pudo resolver el partido.
UPDATE #HistorialStaging SET Estado='Error',
    Detalle=N'No se pudo resolver el partido '+ISNULL(EquipoLocal, N'?')+N' vs '
            +ISNULL(EquipoVisitante, N'?')+N': revise la carga 11 y los nombres en equipos.Pais.'
WHERE Estado='Pendiente' AND IdPartido IS NULL;

-- D4: la fecha del CSV no coincide con la del fixture.
UPDATE s SET Estado='Error',
    Detalle=N'La fecha no coincide con la del partido en el fixture.'
FROM #HistorialStaging AS s
JOIN partidos.Partido AS m ON m.IdPartido = s.IdPartido
WHERE s.Estado='Pendiente' AND s.Fecha <> m.Fecha;

-- D5: la sede del CSV no es la del partido.
UPDATE #HistorialStaging SET Estado='Error',
    Detalle=N'La sede del CSV no es la sede del partido.'
WHERE Estado='Pendiente' AND IdPartido IS NOT NULL AND IdSede <> IdSedePartido;

-- D6: numero de espacio fuera del rango que admite el modelo (1 a 4).
UPDATE #HistorialStaging SET Estado='Error',
    Detalle=N'El numero de espacio debe estar entre 1 y 4.'
WHERE Estado='Pendiente' AND (NumeroEspacio IS NULL OR NumeroEspacio NOT BETWEEN 1 AND 4);

-- D7: el espacio no existe en esa sede.
UPDATE #HistorialStaging SET Estado='Error',
    Detalle=N'El espacio '+ISNULL(CONVERT(NVARCHAR(10), NumeroEspacio), N'?')
            +N' no existe en la sede: ejecute la carga 26.'
WHERE Estado='Pendiente' AND NumeroEspacio BETWEEN 1 AND 4 AND IdEP IS NULL;

-- D8: la franja no existe en esa sede.
UPDATE #HistorialStaging SET Estado='Error',
    Detalle=N'La franja '+ISNULL(TipoFranja, N'(vacia)')
            +N' no tiene costo en la sede: ejecute la carga 27.'
WHERE Estado='Pendiente' AND IdCF IS NULL;

-- D9: la campania no esta en publicidad.Publicidad (o el nombre es ambiguo).
UPDATE s SET Estado='Error',
    Detalle=CASE WHEN (SELECT COUNT(*) FROM publicidad.Publicidad AS p
                       WHERE p.Nombre = s.Publicidad) = 0
                 THEN N'La campania '+ISNULL(s.Publicidad, N'(vacia)')
                      +N' no existe en publicidad.Publicidad: ejecute la carga 20.'
                 ELSE N'El nombre de la campania es ambiguo en publicidad.Publicidad.'
            END
FROM #HistorialStaging AS s
WHERE s.Estado='Pendiente' AND s.IdPublicidad IS NULL;

-- D10: costo final ausente o negativo.
UPDATE #HistorialStaging SET Estado='Error',
    Detalle=N'La fuente no trae un costo final valido (no nulo y no negativo).'
WHERE Estado='Pendiente' AND (CostoFinal IS NULL OR CostoFinal < 0);

-- D11: el partido y el espacio se repiten dentro del CSV.
UPDATE s SET Estado='Error',
    Detalle=N'El partido y el espacio se repiten en el CSV.'
FROM #HistorialStaging AS s
JOIN (SELECT IdPartido, IdEP FROM #HistorialStaging
      WHERE Estado='Pendiente' GROUP BY IdPartido, IdEP HAVING COUNT(*) > 1) AS d
  ON d.IdPartido = s.IdPartido AND d.IdEP = s.IdEP
WHERE s.Estado='Pendiente';

-- D12 (aviso): el costo final no coincide con espacio + franja. Se registra el
--      valor del archivo, que es el que se informa en la planilla.
UPDATE #HistorialStaging SET Detalle = N'El costo final no coincide con espacio + franja ('
        + CONVERT(NVARCHAR(20), CostoCalculado) + N'); se registra el del archivo.'
WHERE Estado='Pendiente' AND CostoFinal <> CostoCalculado;

-- D13: un partido admite como maximo cuatro espacios. Se contempla el total
--      ya persistido y las nuevas filas del CSV para no aceptar, por ejemplo,
--      dos altas cuando al partido solo le queda un lugar disponible.
;WITH NuevasAsignaciones AS (
    SELECT s.Fila, s.IdPartido,
           COUNT(*) OVER (PARTITION BY s.IdPartido ORDER BY s.Fila
                          ROWS UNBOUNDED PRECEDING) AS OrdenNueva,
           (SELECT COUNT(*) FROM publicidad.HistorialPublicidad AS h
            WHERE h.IdPartido=s.IdPartido) AS YaExistentes
    FROM #HistorialStaging AS s
    WHERE s.Estado='Pendiente'
      AND NOT EXISTS (
          SELECT 1 FROM publicidad.HistorialPublicidad AS h
          WHERE h.IdPartido=s.IdPartido AND h.IdEP=s.IdEP
      )
)
UPDATE s SET Estado='Error',
    Detalle=N'El partido ya tiene cuatro espacios asignados o supera el maximo de cuatro.'
FROM #HistorialStaging AS s
JOIN NuevasAsignaciones AS n ON n.Fila=s.Fila
WHERE n.YaExistentes + n.OrdenNueva > 4;

-- D14: la asignacion ya existe; se compara con lo cargado.
UPDATE s SET IdHistorial = h.IdHistorial, PublicidadActual = p.Nombre,
             IdCFActual = h.IdCF, CostoActual = h.CostoFinal
FROM #HistorialStaging AS s
JOIN publicidad.HistorialPublicidad AS h
  ON h.IdPartido = s.IdPartido AND h.IdEP = s.IdEP
JOIN publicidad.Publicidad AS p ON p.IdPublicidad = h.IdPublicidad
WHERE s.Estado='Pendiente';

UPDATE #HistorialStaging SET Estado='SinCambios',
    Detalle=N'La asignacion ya estaba cargada con la misma campania, franja y costo.'
WHERE Estado='Pendiente' AND IdHistorial IS NOT NULL
  AND PublicidadActual = Publicidad AND IdCFActual = IdCF AND CostoActual = CostoFinal;

-- D15 (aviso): la asignacion existe y cambia la campania, la franja o el costo.
UPDATE #HistorialStaging SET Detalle = N'Se actualiza la asignacion cargada (campania/franja/costo).'
WHERE Estado='Pendiente' AND IdHistorial IS NOT NULL;

-- Reporte de la depuracion: se informa ANTES de escribir en la tabla real.
SELECT 'FASE 2 - Depuracion del historial publicitario (antes de la persistencia)' AS Fase;
SELECT Estado, COUNT(*) AS Cantidad FROM #HistorialStaging GROUP BY Estado ORDER BY Estado;
SELECT Fila, Fecha, EquipoLocal, EquipoVisitante, Sede, NumeroEspacio, TipoFranja,
       Publicidad, CostoFinal, Estado, Detalle
FROM #HistorialStaging WHERE Estado IN ('Error') OR Detalle IS NOT NULL ORDER BY Fila;

---------------------------------------------------------------------------------------
-- FASE 3 - PERSISTENCIA
---------------------------------------------------------------------------------------

DECLARE @fila INT, @idPublicidad INT, @idPartido INT, @idEP INT,
        @costoFinal DECIMAL(10,2), @idCF INT, @idHistorial INT, @estado VARCHAR(20);
DECLARE crsHistorial CURSOR LOCAL FAST_FORWARD FOR
    SELECT Fila, IdPublicidad, IdPartido, IdEP, CostoFinal, IdCF, IdHistorial
    FROM #HistorialStaging WHERE Estado='Pendiente' ORDER BY Fila;
OPEN crsHistorial;
FETCH NEXT FROM crsHistorial
    INTO @fila, @idPublicidad, @idPartido, @idEP, @costoFinal, @idCF, @idHistorial;
WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @idHistorial IS NULL
        BEGIN
            -- Se pasa el costo del archivo: el SP solo lo calcula si viene NULL.
            EXEC SP.uspHistorialPublicidad_Registrar
                 @idPublicidad=@idPublicidad, @idPartido=@idPartido, @idEP=@idEP,
                 @costoFinal=@costoFinal, @idCF=@idCF;
            SELECT @idHistorial=IdHistorial
            FROM publicidad.HistorialPublicidad
            WHERE IdPartido=@idPartido AND IdEP=@idEP;
            SET @estado='Insertada';
        END
        ELSE
        BEGIN
            EXEC SP.uspHistorialPublicidad_Update
                 @id=@idHistorial, @idPublicidad=@idPublicidad, @idPartido=@idPartido,
                 @idEP=@idEP, @costoFinal=@costoFinal, @idCF=@idCF;
            SET @estado='Actualizada';
        END;
        COMMIT TRANSACTION;
        UPDATE #HistorialStaging SET IdHistorial=@idHistorial WHERE Fila=@fila;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        SET @estado='Error';
        UPDATE #HistorialStaging SET Detalle=ERROR_MESSAGE() WHERE Fila=@fila;
    END CATCH;
    UPDATE #HistorialStaging SET Estado=@estado WHERE Fila=@fila;
    FETCH NEXT FROM crsHistorial
        INTO @fila, @idPublicidad, @idPartido, @idEP, @costoFinal, @idCF, @idHistorial;
END;
CLOSE crsHistorial;
DEALLOCATE crsHistorial;

-- Reporte final.
SELECT 'FASE 3 - Persistencia del historial publicitario' AS Fase;
SELECT Estado, COUNT(*) AS Cantidad FROM #HistorialStaging GROUP BY Estado ORDER BY Estado;
SELECT Fila, Fecha, EquipoLocal, EquipoVisitante, Sede, NumeroEspacio, TipoFranja,
       Publicidad, CostoFinal, IdHistorial, Estado, Detalle
FROM #HistorialStaging ORDER BY Fila;

-- Cobertura: el juego de ejemplo asigna 2 o 3 espacios a cada partido.
SELECT 'Cobertura del historial publicitario' AS Fase,
       COUNT(*) AS Asignaciones,
       COUNT(DISTINCT IdPartido) AS Partidos,
       COUNT(DISTINCT IdPublicidad) AS Campanias,
       COUNT(DISTINCT IdEP) AS EspaciosUsados,
       SUM(CostoFinal) AS CostoTotal,
       MIN(CostoFinal) AS CostoMinimo,
       MAX(CostoFinal) AS CostoMaximo
FROM publicidad.HistorialPublicidad;

SELECT 'Partidos sin historial publicitario' AS Fase, m.IdPartido, m.Fecha
FROM partidos.Partido AS m
WHERE m.IdMundial = 1
  AND NOT EXISTS (SELECT 1 FROM publicidad.HistorialPublicidad AS h WHERE h.IdPartido = m.IdPartido)
ORDER BY m.Fecha, m.IdPartido;

DECLARE @fallos INT = (SELECT COUNT(*) FROM #HistorialStaging WHERE Estado='Error');
DROP TABLE #HistorialStaging;
IF @fallos > 0
    THROW 52404, 'Importacion parcial: se conservaron las asignaciones correctas. Revise el detalle.', 1;
GO
