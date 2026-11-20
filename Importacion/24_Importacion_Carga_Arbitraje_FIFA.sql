-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Comision 02
-- Grupo 7: Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 18/11/2026.
-- Objetivo: cargar la planilla arbitral completa de los 104 partidos del Mundial
-- con la metodologia de tres fases, usando como fuente el calendario de la API
-- publica de FIFA (generado por Datos\Datos_Partidos\script_descargar_fifa_oficiales_API.py).
--
-- La carga 15 trae de Promiedos solo el arbitro principal, con nombre abreviado
-- y sin nacionalidad. FIFA da por partido arbitro, asistentes, cuarto, VAR,
-- reserva, AVAR y support VAR, cada uno con pais e id.
--
-- El modelo solo admite cuatro funciones en arbitros.Arbitraje:
--   Principal (cupo 1), Asistente (cupo 2), 4to (cupo 1) y VAR (cupo 1).
-- Por eso las funciones Reserva, Asistente VAR y Support VAR se informan como
-- Omitidas: no existe lugar en el modelo para guardarlas.
--
-- Nacionalidad: se carga el pais real del oficial cuando ya existe en
-- equipos.Pais (los 48 participantes). Si el pais no esta cargado (por ejemplo
-- HON, CHI, ITA) se usa USA, el mismo criterio que la carga 15, y la fila queda
-- senalada en el reporte con el codigo ISO3 que no se pudo resolver.
--
-- Relacion con la carga 15: si la 15 ya corrio, cada partido tiene su Principal.
-- Este importador NO lo reemplaza: conserva el existente, informa la diferencia
-- de nombre y completa asistentes, cuarto y VAR. Si se ejecuta sobre una base
-- sin la carga 15, da de alta tambien el Principal con el nombre completo.
--
--   FASE 1 STAGING     : se baja TODO el CSV a #OficialesCrudo y se resuelve
--                        partido, pais y arbitro sin descartar ninguna fila.
--   FASE 2 DEPURACION  : reglas de conjunto (UPDATE) sobre la staging.
--   FASE 3 PERSISTENCIA: alta del arbitro si no existe y designacion con
--                        SPTRANS.uspArbitro_Registrar / uspArbitraje_Registrar.
--
-- Requiere ejecutar antes las cargas 06 (paises), 10 (jugadores), 11 (partidos)
-- y, para el flujo normal, 15 (arbitro principal de Promiedos).
-- SSMS: Consulta -> Modo SQLCMD. Ajustar las rutas del servidor SQL.
-- IMPORTANTE: cada integrante debe poner las rutas de su propia PC.
-- :setvar RutaFifaOficiales "C:\ruta\proyecto\Datos\Datos_Partidos\fifa_oficiales.csv"

--L
:setvar RutaFifaOficiales "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Datos\Datos_Partidos\fifa_oficiales.csv"

--Fidel
--:setvar RutaFifaOficiales "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Datos\Datos_Partidos\fifa_oficiales.csv"

USE [MUNDIALtesting];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF @@TRANCOUNT <> 0 OR (2 & @@OPTIONS) = 2
    THROW 52000, 'Ejecute sin transaccion externa y con IMPLICIT_TRANSACTIONS OFF.', 1;
IF OBJECT_ID(N'arbitros.Arbitro', N'U') IS NULL
   OR OBJECT_ID(N'arbitros.Arbitraje', N'U') IS NULL
   OR OBJECT_ID(N'equipos.Persona', N'U') IS NULL
   OR OBJECT_ID(N'equipos.Seleccion', N'U') IS NULL
   OR OBJECT_ID(N'partidos.Partido', N'U') IS NULL
   OR OBJECT_ID(N'SPTRANS.uspArbitro_Registrar', N'P') IS NULL
   OR OBJECT_ID(N'SPTRANS.uspArbitraje_Registrar', N'P') IS NULL
    THROW 52000, 'Faltan tablas o SP ABM. Ejecute primero el instalador.', 1;

IF OBJECT_ID(N'tempdb..#OficialesCrudo') IS NOT NULL DROP TABLE #OficialesCrudo;
IF OBJECT_ID(N'tempdb..#OficialesStaging') IS NOT NULL DROP TABLE #OficialesStaging;

---------------------------------------------------------------------------------------
-- FASE 1 - STAGING
-- El CSV se copia tal cual llega: ninguna fila se descarta en esta fase.
---------------------------------------------------------------------------------------

CREATE TABLE #OficialesCrudo (
    NroPartidoFifa NVARCHAR(10) COLLATE DATABASE_DEFAULT,
    Fecha NVARCHAR(10) COLLATE DATABASE_DEFAULT,
    EquipoLocal NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    EquipoVisitante NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Asistencia NVARCHAR(20) COLLATE DATABASE_DEFAULT,
    TipoCodigo NVARCHAR(10) COLLATE DATABASE_DEFAULT,
    Rol NVARCHAR(30) COLLATE DATABASE_DEFAULT,
    Nombre NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    NombreCorto NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    PaisIso3 NVARCHAR(3) COLLATE DATABASE_DEFAULT,
    PaisBd NVARCHAR(60) COLLATE DATABASE_DEFAULT,
    OfficialId NVARCHAR(20) COLLATE DATABASE_DEFAULT
);

BEGIN TRY
    BULK INSERT #OficialesCrudo FROM '$(RutaFifaOficiales)'
    WITH (FORMAT='CSV', FIRSTROW=2, FIELDTERMINATOR=',',
          ROWTERMINATOR='0x0d0a', CODEPAGE='65001', MAXERRORS=0);
END TRY
BEGIN CATCH
    DECLARE @mensaje NVARCHAR(2048) = LEFT(N'No se pudo leer fifa_oficiales.csv. '
                                           + ERROR_MESSAGE(), 2048);
    THROW 52001, @mensaje, 1;
END CATCH;

CREATE TABLE #OficialesStaging (
    Fila INT IDENTITY(1,1) PRIMARY KEY,
    NroPartidoFifa INT,
    Fecha DATE,
    EquipoLocal NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    EquipoVisitante NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Asistencia INT,
    TipoCodigo INT,
    Rol VARCHAR(20) COLLATE DATABASE_DEFAULT,
    Nombre NVARCHAR(60) COLLATE DATABASE_DEFAULT,
    PaisIso3 CHAR(3) COLLATE DATABASE_DEFAULT,
    PaisBd NVARCHAR(60) COLLATE DATABASE_DEFAULT,
    OfficialId NVARCHAR(20) COLLATE DATABASE_DEFAULT,
    IdPartido INT,
    IdArbitro INT,
    IdPais INT,
    Estado VARCHAR(20) COLLATE DATABASE_DEFAULT NOT NULL DEFAULT 'Pendiente',
    Detalle NVARCHAR(2048) COLLATE DATABASE_DEFAULT
);

INSERT #OficialesStaging
    (NroPartidoFifa, Fecha, EquipoLocal, EquipoVisitante, Asistencia, TipoCodigo,
     Rol, Nombre, PaisIso3, PaisBd, OfficialId)
SELECT TRY_CONVERT(INT, LTRIM(RTRIM(NroPartidoFifa))),
       TRY_CONVERT(DATE, LTRIM(RTRIM(Fecha)), 23),
       LTRIM(RTRIM(EquipoLocal)),
       LTRIM(RTRIM(EquipoVisitante)),
       TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(Asistencia)), N'')),
       TRY_CONVERT(INT, LTRIM(RTRIM(TipoCodigo))),
       LTRIM(RTRIM(Rol)),
       -- Persona.Nombre es NVARCHAR(30): el generador ya recorto con NameShort.
       -- Se guarda hasta 60 para poder informar el nombre completo si no entra.
       CONVERT(NVARCHAR(60), LTRIM(RTRIM(Nombre))),
       LTRIM(RTRIM(PaisIso3)),
       LTRIM(RTRIM(PaisBd)),
       LTRIM(RTRIM(OfficialId))
FROM #OficialesCrudo;

DROP TABLE #OficialesCrudo;

IF NOT EXISTS (SELECT 1 FROM #OficialesStaging)
    THROW 52002, 'El CSV de oficiales quedo vacio; revise la ruta y el formato.', 1;

-- Un partido se identifica por el par de selecciones: el nro_partido de FIFA NO
-- coincide con el orden de openfootball ni con el GameId de Promiedos.
-- Si el fixture tuviera el mismo cruce dos veces, el UPDATE elegiria uno al azar.
IF EXISTS (SELECT 1 FROM partidos.Partido WHERE IdMundial = 1
           GROUP BY Eq1, Eq2 HAVING COUNT(*) > 1)
    THROW 52004, 'Hay pares de selecciones repetidos en partidos.Partido: no se puede cruzar por equipos.', 1;

UPDATE s SET IdPartido = m.IdPartido
FROM #OficialesStaging AS s
JOIN equipos.Pais AS p1 ON p1.NOMBRE = s.EquipoLocal
JOIN equipos.Seleccion AS e1 ON e1.IdPais = p1.IdPais AND e1.IdMundial = 1
JOIN equipos.Pais AS p2 ON p2.NOMBRE = s.EquipoVisitante
JOIN equipos.Seleccion AS e2 ON e2.IdPais = p2.IdPais AND e2.IdMundial = 1
JOIN partidos.Partido AS m ON m.IdMundial = 1
                          AND m.Eq1 = e1.IdSeleccion
                          AND m.Eq2 = e2.IdSeleccion;

-- Pais real del oficial, solo si ya esta cargado en equipos.Pais.
UPDATE s SET IdPais = p.IdPais
FROM #OficialesStaging AS s
JOIN equipos.Pais AS p ON p.NOMBRE = s.PaisBd;

---------------------------------------------------------------------------------------
-- FASE 2 - DEPURACION
-- Reglas de conjunto: cada UPDATE marca la fila y su motivo. No se borra nada.
---------------------------------------------------------------------------------------

-- D1: el partido no se pudo resolver por el par de selecciones.
UPDATE #OficialesStaging SET Estado='Error',
    Detalle=N'No se pudo resolver el partido con '+EquipoLocal+N' vs '+EquipoVisitante
            +N': revise que la carga 11 tenga ese cruce y los nombres en equipos.Pais.'
WHERE Estado='Pendiente' AND IdPartido IS NULL;

-- D2: rol que el modelo no puede guardar. No es un error: se informa y se omite.
UPDATE #OficialesStaging SET Estado='Omitida',
    Detalle=N'El modelo solo admite Principal, Asistente, 4to y VAR: '+Rol+N' no tiene lugar en arbitros.Arbitraje.'
WHERE Estado='Pendiente' AND Rol NOT IN ('Principal','Asistente','4to','VAR');

-- D3: oficial sin nombre.
UPDATE #OficialesStaging SET Estado='Error',
    Detalle=N'El oficial no tiene nombre.'
WHERE Estado='Pendiente' AND NULLIF(Nombre,N'') IS NULL;

-- D4: el nombre no entra en Persona.Nombre.
UPDATE #OficialesStaging SET Estado='Error',
    Detalle=N'El nombre del oficial excede los 30 caracteres de Persona.Nombre.'
WHERE Estado='Pendiente' AND Nombre IS NOT NULL AND LEN(Nombre) > 30;

-- D5: ya existe una persona con ese nombre que no es arbitro.
UPDATE #OficialesStaging SET Estado='Error',
    Detalle=N'Ya existe una persona con ese nombre y no es arbitro: revise las cargas 10 y 15.'
WHERE Estado='Pendiente'
  AND EXISTS (SELECT 1 FROM equipos.Persona AS pe
              WHERE pe.Nombre = #OficialesStaging.Nombre
                AND NOT EXISTS (SELECT 1 FROM arbitros.Arbitro AS ar
                                WHERE ar.IdArbitro = pe.IdPersona));

-- D6: el mismo oficial dos veces en el mismo partido.
UPDATE f SET Estado='Duplicada',
    Detalle=N'El oficial figura dos veces en el mismo partido.'
FROM #OficialesStaging AS f
WHERE f.Estado='Pendiente' AND EXISTS (
    SELECT 1 FROM #OficialesStaging AS o
    WHERE o.IdPartido = f.IdPartido AND o.Nombre = f.Nombre AND o.Fila < f.Fila
);

-- D7: pais no cargado en equipos.Pais: se usa USA y se senala el codigo real.
--     Es el mismo criterio de la carga 15 (que usa USA para todos los arbitros),
--     pero aca queda documentado que el dato real existe y no se pudo cargar.
UPDATE s SET IdPais = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = N'USA'),
    Detalle = N'Nacionalidad no disponible en equipos.Pais (' + ISNULL(s.PaisIso3, N'??')
            + N'): se usa USA, igual que la carga 15.'
FROM #OficialesStaging AS s
WHERE s.Estado='Pendiente' AND s.IdPais IS NULL;

-- D7b: sin pais no hay alta posible (faltaria la carga 06).
UPDATE #OficialesStaging SET Estado='Error',
    Detalle=N'No se pudo determinar el pais del oficial: falta USA en equipos.Pais (carga 06).'
WHERE Estado='Pendiente' AND IdPais IS NULL;

-- D8: conflicto de nacionalidad. El SP lo rechazaria igual, pero se detecta antes
--     para poder informarlo como designacion descartada y no como fallo tecnico.
UPDATE s SET Estado='Omitida',
    Detalle = N'Designacion descartada por conflicto de nacionalidad: el oficial es de '
            + ISNULL(s.PaisIso3, N'??') + N' y se asigno el pais '
            + ISNULL(pc.NOMBRE, N'(sin dato)') + N', que disputa el partido.'
FROM #OficialesStaging AS s
JOIN equipos.Pais AS pc ON pc.IdPais = s.IdPais
WHERE s.Estado='Pendiente'
  AND EXISTS (
        SELECT 1
        FROM partidos.Partido AS m
        JOIN equipos.Seleccion AS e1 ON e1.IdSeleccion = m.Eq1
        JOIN equipos.Seleccion AS e2 ON e2.IdSeleccion = m.Eq2
        WHERE m.IdPartido = s.IdPartido
          AND s.IdPais IN (e1.IdPais, e2.IdPais)
  );

-- D8b: la misma persona ya tiene esa funcion en ese partido: no hay nada que hacer.
UPDATE s SET Estado='SinCambios', Detalle=N'La designacion ya existia.'
FROM #OficialesStaging AS s
WHERE s.Estado='Pendiente'
  AND EXISTS (SELECT 1
              FROM arbitros.Arbitraje AS a
              JOIN equipos.Persona AS pe ON pe.IdPersona = a.Arbitro
              WHERE a.Partido = s.IdPartido AND a.Funcion = s.Rol AND pe.Nombre = s.Nombre);

-- D9: ya hay una designacion para esa funcion en ese partido.
--     Puede venir de la carga 15 (Principal) o de una ejecucion anterior.
--     Se informa si el designado es otra persona: es una divergencia de fuentes.
UPDATE s SET Estado='Omitida',
    Detalle = N'Ya hay un '+Rol+N' designado en el partido: '
            + ISNULL((SELECT MIN(pe.Nombre)
                      FROM arbitros.Arbitraje AS a
                      JOIN equipos.Persona AS pe ON pe.IdPersona = a.Arbitro
                      WHERE a.Partido = s.IdPartido AND a.Funcion = s.Rol), N'(sin dato)')
            + N'. Se conserva el existente.'
FROM #OficialesStaging AS s
WHERE s.Estado='Pendiente'
  AND (SELECT COUNT(*) FROM arbitros.Arbitraje AS a
       WHERE a.Partido = s.IdPartido AND a.Funcion = s.Rol)
      >= CASE s.Rol WHEN 'Asistente' THEN 2 ELSE 1 END;

-- Se resuelve el arbitro si ya estaba cargado (idempotencia entre partidos).
UPDATE s SET IdArbitro = ar.IdArbitro
FROM #OficialesStaging AS s
JOIN equipos.Persona AS pe ON pe.Nombre = s.Nombre
JOIN arbitros.Arbitro AS ar ON ar.IdArbitro = pe.IdPersona
WHERE s.Estado='Pendiente';

-- Reporte de la depuracion: se informa ANTES de escribir en las tablas reales.
SELECT 'FASE 2 - Depuracion de la planilla arbitral FIFA (antes de la persistencia)' AS Fase;
SELECT Estado, COUNT(*) AS Cantidad FROM #OficialesStaging GROUP BY Estado ORDER BY Estado;
SELECT Rol, COUNT(*) AS Cantidad FROM #OficialesStaging GROUP BY Rol ORDER BY Rol;
SELECT Fila, NroPartidoFifa, IdPartido, Rol, Nombre, PaisIso3, Estado, Detalle
FROM #OficialesStaging WHERE Estado IN ('Error','Duplicada','Omitida') ORDER BY Fila;

---------------------------------------------------------------------------------------
-- FASE 3 - PERSISTENCIA
-- Primero se da de alta el oficial si no existia y luego su designacion.
---------------------------------------------------------------------------------------

DECLARE @fila INT, @nombre NVARCHAR(30), @idPartido INT, @funcion VARCHAR(20),
        @idArbitro INT, @idPais INT, @estado VARCHAR(20),
        @estadoArbitro VARCHAR(20), @existente NVARCHAR(30);
-- La fecha de nacimiento no viene en la fuente: se usa un valor por defecto,
-- igual que en la carga 15. El default de un parametro de EXEC debe ser una
-- constante o una variable, nunca una expresion CONVERT.
DECLARE @fnac DATE = CONVERT(DATE,'1900-01-01',23);
DECLARE crsOficiales CURSOR LOCAL FAST_FORWARD FOR
    SELECT Fila, Nombre, IdPartido, Rol, IdArbitro, IdPais
    FROM #OficialesStaging WHERE Estado='Pendiente' ORDER BY IdPartido, Fila;
OPEN crsOficiales;
FETCH NEXT FROM crsOficiales INTO @fila, @nombre, @idPartido, @funcion, @idArbitro, @idPais;
WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        -- El oficial puede haberse creado al procesar otro partido.
        IF @idArbitro IS NULL
        BEGIN
            SELECT @idArbitro = ar.IdArbitro
            FROM equipos.Persona AS pe
            JOIN arbitros.Arbitro AS ar ON ar.IdArbitro = pe.IdPersona
            WHERE pe.NombreHash = HASHBYTES('SHA2_256', @nombre);
        END;

        IF @idArbitro IS NULL
        BEGIN
            EXEC SPTRANS.uspArbitro_Registrar @nombre=@nombre,
                @fnac=@fnac,
                @pais=@idPais, @categoria=N'FIFA';
            SET @idArbitro = NULL;
            SELECT @idArbitro = ar.IdArbitro
            FROM arbitros.Arbitro AS ar
            JOIN equipos.Persona AS pe ON pe.IdPersona = ar.IdArbitro
            WHERE pe.NombreHash = HASHBYTES('SHA2_256', @nombre);
            SET @estadoArbitro = 'Insertado';
        END
        ELSE SET @estadoArbitro = 'SinCambios';

        -- Cupo de la funcion: se vuelve a controlar porque el cursor procesa el
        -- partido completo y el SP rechaza el exceso.
        SET @existente = NULL;
        SELECT @existente = MIN(pe.Nombre)
        FROM arbitros.Arbitraje AS a
        JOIN equipos.Persona AS pe ON pe.IdPersona = a.Arbitro
        WHERE a.Partido = @idPartido AND a.Funcion = @funcion;

        IF EXISTS (SELECT 1 FROM arbitros.Arbitraje
                   WHERE Arbitro = @idArbitro AND Partido = @idPartido)
            SET @estado = 'SinCambios';
        ELSE IF @existente IS NOT NULL
                 AND (SELECT COUNT(*) FROM arbitros.Arbitraje
                      WHERE Partido = @idPartido AND Funcion = @funcion)
                     >= CASE @funcion WHEN 'Asistente' THEN 2 ELSE 1 END
        BEGIN
            SET @estado = 'Omitida';
            UPDATE #OficialesStaging
            SET Detalle = N'Ya hay un ' + @funcion + N' designado en el partido: '
                          + ISNULL(@existente, N'(sin dato)') + N'. Se conserva el existente.'
            WHERE Fila = @fila;
        END
        ELSE
        BEGIN
            EXEC SPTRANS.uspArbitraje_Registrar @arbitro=@idArbitro,
                @funcion=@funcion, @partido=@idPartido;
            SET @estado = 'Insertada';
        END;

        COMMIT TRANSACTION;
        UPDATE #OficialesStaging SET IdArbitro=@idArbitro, Estado=@estado,
            Detalle = ISNULL(Detalle, N'Oficial: ' + @estadoArbitro)
        WHERE Fila=@fila;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        UPDATE #OficialesStaging SET Estado='Error', Detalle=ERROR_MESSAGE() WHERE Fila=@fila;
    END CATCH;
    FETCH NEXT FROM crsOficiales INTO @fila, @nombre, @idPartido, @funcion, @idArbitro, @idPais;
END;
CLOSE crsOficiales;
DEALLOCATE crsOficiales;

-- Reporte final de la persistencia.
SELECT 'FASE 3 - Persistencia de la planilla arbitral' AS Fase;
SELECT Estado, COUNT(*) AS Cantidad FROM #OficialesStaging GROUP BY Estado ORDER BY Estado;
SELECT Fila, NroPartidoFifa, IdPartido, Rol, Nombre, PaisIso3, IdArbitro, Estado, Detalle
FROM #OficialesStaging ORDER BY Fila;

-- Control de cobertura: partidos con los cuatro roles completos.
SELECT 'Cobertura por partido' AS Fase,
       SUM(CASE WHEN Principal = 1 AND Asistentes = 2 AND Cuarto = 1 AND Var = 1 THEN 1 ELSE 0 END)
           AS PartidosConPlanillaCompleta,
       COUNT(*) AS Partidos
FROM (
    SELECT m.IdPartido,
           SUM(CASE WHEN a.Funcion='Principal' THEN 1 ELSE 0 END) AS Principal,
           SUM(CASE WHEN a.Funcion='Asistente' THEN 1 ELSE 0 END) AS Asistentes,
           SUM(CASE WHEN a.Funcion='4to'       THEN 1 ELSE 0 END) AS Cuarto,
           SUM(CASE WHEN a.Funcion='VAR'       THEN 1 ELSE 0 END) AS Var
    FROM partidos.Partido AS m
    LEFT JOIN arbitros.Arbitraje AS a ON a.Partido = m.IdPartido
    WHERE m.IdMundial = 1
    GROUP BY m.IdPartido
) AS x;

-- Divergencias con la carga 15: Principal de Promiedos vs Principal de FIFA.
SELECT 'Divergencias de arbitro principal (carga 15 vs FIFA)' AS Fase,
       s.IdPartido, s.Nombre AS PrincipalFifa,
       (SELECT MIN(pe.Nombre)
        FROM arbitros.Arbitraje AS a
        JOIN equipos.Persona AS pe ON pe.IdPersona = a.Arbitro
        WHERE a.Partido = s.IdPartido AND a.Funcion = 'Principal') AS PrincipalCargado
FROM #OficialesStaging AS s
WHERE s.Rol='Principal' AND s.Estado IN ('Omitida','Insertada')
  AND s.Nombre <> ISNULL((SELECT MIN(pe.Nombre)
                          FROM arbitros.Arbitraje AS a
                          JOIN equipos.Persona AS pe ON pe.IdPersona = a.Arbitro
                          WHERE a.Partido = s.IdPartido AND a.Funcion = 'Principal'), N'')
ORDER BY s.IdPartido;

DECLARE @fallos INT = (SELECT COUNT(*) FROM #OficialesStaging WHERE Estado='Error');
DECLARE @omitidas INT = (SELECT COUNT(*) FROM #OficialesStaging WHERE Estado='Omitida');
DROP TABLE #OficialesStaging;
IF @fallos > 0
    THROW 52003, 'Importacion parcial: se conservaron las designaciones correctas. Revise el detalle.', 1;
IF @omitidas > 0
    PRINT 'Aviso: hay designaciones omitidas (roles no modelados o conflicto de nacionalidad). No es un fallo de la carga.';
GO
