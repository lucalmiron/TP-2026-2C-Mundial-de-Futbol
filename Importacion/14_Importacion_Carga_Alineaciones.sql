-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Comision 02
-- Grupo 7: Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 13/11/2026.
-- Objetivo: cargar las alineaciones (titulares y suplentes) de los 104 JSON de
-- Promiedos con la metodologia de tres fases.
--   FASE 1 STAGING     : el lector compartido deja los JSON crudos y el
--                         partido resuelto. Cada jugador de cada formacion
--                         queda como una fila de #AlineacionesStaging.
--   FASE 2 DEPURACION  : reglas de conjunto (UPDATE) sobre la staging.
--   FASE 3 PERSISTENCIA : solo las filas validas pasan por
--                         SP.uspAlineacion_Registrar.
-- Criterio de dorsal: si un jugador cambia de dorsal entre partidos, se toma
-- como suyo el que quedo registrado en equipos.Jugador (el primero, carga 10)
-- y no se validan los cambios. El jugador se resuelve primero por NOMBRE;
-- el dorsal solo se usa como fallback.
-- Requiere ejecutar antes las cargas 07 (selecciones), 10 (jugadores) y
-- 11 (partidos).
-- SSMS: Consulta -> Modo SQLCMD. TP_BDDA se define en los archivos 00_Importar_Todo_Parte*.sql.
-- IMPORTANTE: no editar rutas aca; TP_BDDA se define en los archivos 00_Importar_Todo_Parte*.sql.





USE MUNDIAL;
GO
-- Entrega 8: equipos.Persona.Nombre esta cifrado; se lee con DECRYPTBYKEYAUTOCERT.
-- No depende de que la clave este abierta en la sesion (los SP de ABM la cierran).
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF @@TRANCOUNT <> 0 OR (2 & @@OPTIONS) = 2
    THROW 51900, 'Ejecute sin transaccion externa y con IMPLICIT_TRANSACTIONS OFF.', 1;
IF OBJECT_ID(N'partidos.Alineacion', N'U') IS NULL
   OR OBJECT_ID(N'equipos.Jugador', N'U') IS NULL
   OR OBJECT_ID(N'SP.uspAlineacion_Registrar', N'P') IS NULL
    THROW 51900, 'Faltan tablas o SP ABM. Ejecute primero el instalador.', 1;

IF OBJECT_ID(N'tempdb..#AlineacionesStaging') IS NOT NULL DROP TABLE #AlineacionesStaging;
IF OBJECT_ID(N'tempdb..#JugReg') IS NOT NULL DROP TABLE #JugReg;
IF OBJECT_ID(N'tempdb..#Cand') IS NOT NULL DROP TABLE #Cand;

-- Lector compartido: deja los JSON crudos, las equivalencias y el partido resuelto.
:r $(TP_BDDA)\Importacion\XX_Lectura_Partidos_JSON.sql

---------------------------------------------------------------------------------------
-- FASE 1 - STAGING
-- Una fila por jugador de cada formacion (titular o suplente).
---------------------------------------------------------------------------------------

CREATE TABLE #AlineacionesStaging (
    Fila INT IDENTITY(1,1) PRIMARY KEY,
    Archivo NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    GameId NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    IdPartido INT,
    Seleccion INT,
    Rol VARCHAR(10) COLLATE DATABASE_DEFAULT,
    Nombre NVARCHAR(60) COLLATE DATABASE_DEFAULT,
    Numero INT,
    PosicionCancha NVARCHAR(40) COLLATE DATABASE_DEFAULT,
    Esquema NVARCHAR(20) COLLATE DATABASE_DEFAULT,
    IdJugador INT,
    DetallePartido NVARCHAR(2048) COLLATE DATABASE_DEFAULT,
    Estado VARCHAR(20) COLLATE DATABASE_DEFAULT NOT NULL DEFAULT 'Pendiente',
    Detalle NVARCHAR(2048) COLLATE DATABASE_DEFAULT
);

INSERT #AlineacionesStaging
    (Archivo, GameId, IdPartido, Seleccion, Rol, Nombre, Numero, PosicionCancha, Esquema, DetallePartido)
SELECT a.Archivo, p.GameId, p.IdPartido,
       CASE WHEN t.TeamNum=1 THEN p.Eq1 ELSE p.Eq2 END,
       'Titular', j.Nombre, j.JerseyNum, j.Posicion, t.Formacion, p.Detalle
FROM #ArchivosPartidos AS a
LEFT JOIN #PartidosJson AS p ON p.Archivo=a.Archivo
CROSS APPLY OPENJSON(a.Contenido, '$.game.players.lineups.teams') WITH (
    TeamNum INT '$.team_num',
    Formacion NVARCHAR(20) '$.formation',
    Starting NVARCHAR(MAX) '$.starting' AS JSON
) AS t
CROSS APPLY OPENJSON(ISNULL(t.Starting,N'[]')) WITH (
    JerseyNum INT '$.jersey_num',
    Nombre NVARCHAR(60) '$.name',
    Posicion NVARCHAR(40) '$.position'
) AS j

UNION ALL

SELECT a.Archivo, p.GameId, p.IdPartido,
       CASE WHEN t.TeamNum=1 THEN p.Eq1 ELSE p.Eq2 END,
       'Suplente', j.Nombre, j.JerseyNum, j.Posicion, t.Formacion, p.Detalle
FROM #ArchivosPartidos AS a
LEFT JOIN #PartidosJson AS p ON p.Archivo=a.Archivo
CROSS APPLY OPENJSON(a.Contenido, '$.game.players.lineups.teams') WITH (
    TeamNum INT '$.team_num',
    Formacion NVARCHAR(20) '$.formation',
    Bench NVARCHAR(MAX) '$.bench' AS JSON
) AS t
CROSS APPLY OPENJSON(ISNULL(t.Bench,N'[]')) WITH (
    JerseyNum INT '$.jersey_num',
    Nombre NVARCHAR(60) '$.name',
    Posicion NVARCHAR(40) '$.position'
) AS j;

IF NOT EXISTS (SELECT 1 FROM #AlineacionesStaging)
    THROW 51901, 'No se encontraron alineaciones en los JSON; revise la lectura de archivos.', 1;

---------------------------------------------------------------------------------------
-- FASE 2 - DEPURACION
-- Reglas de conjunto: cada UPDATE marca las filas invalidas y su motivo.
-- No se borra nada; las filas validas quedan en Estado = 'Pendiente'.
---------------------------------------------------------------------------------------

-- D1: el JSON del partido no se pudo resolver.
UPDATE #AlineacionesStaging SET Estado='Error',
    Detalle=ISNULL(DetallePartido, N'El JSON del partido no se pudo resolver.')
WHERE Estado='Pendiente' AND IdPartido IS NULL;

-- D2: falta el nombre o el dorsal del jugador.
UPDATE #AlineacionesStaging SET Estado='Error',
    Detalle=N'El jugador no tiene nombre o dorsal.'
WHERE Estado='Pendiente' AND (NULLIF(Nombre,N'') IS NULL OR Numero IS NULL);

-- D3: el dorsal no es un entero positivo.
UPDATE #AlineacionesStaging SET Estado='Error',
    Detalle=N'El dorsal del jugador no es un entero positivo.'
WHERE Estado='Pendiente' AND Numero IS NOT NULL AND Numero <= 0;

-- D4: la posicion no cabe en VARCHAR(20).
UPDATE #AlineacionesStaging SET Estado='Error',
    Detalle=N'La posicion no cabe fielmente en VARCHAR(20).'
WHERE Estado='Pendiente' AND PosicionCancha IS NOT NULL
  AND (DATALENGTH(CONVERT(VARCHAR(MAX),PosicionCancha)) > 20
    OR CONVERT(NVARCHAR(MAX),CONVERT(VARCHAR(MAX),PosicionCancha)) COLLATE Latin1_General_100_BIN2
         <> PosicionCancha COLLATE Latin1_General_100_BIN2);

-- D5: el esquema no cabe en VARCHAR(10).
UPDATE #AlineacionesStaging SET Estado='Error',
    Detalle=N'El esquema no cabe fielmente en VARCHAR(10).'
WHERE Estado='Pendiente' AND Esquema IS NOT NULL
  AND (DATALENGTH(CONVERT(VARCHAR(MAX),Esquema)) > 10
    OR CONVERT(NVARCHAR(MAX),CONVERT(VARCHAR(MAX),Esquema)) COLLATE Latin1_General_100_BIN2
         <> Esquema COLLATE Latin1_General_100_BIN2);

-- D6: la seleccion del equipo no se pudo determinar.
UPDATE #AlineacionesStaging SET Estado='Error',
    Detalle=N'No se pudo determinar la seleccion del equipo.'
WHERE Estado='Pendiente' AND Seleccion IS NULL;

-- N1: jugadores registrados con el nombre descifrado una sola vez
--     (evita descifrar fila por fila en cada regla).
CREATE TABLE #JugReg (
    IdJugador INT PRIMARY KEY,
    Seleccion INT,
    Numero INT,
    NombreReg NVARCHAR(30) COLLATE DATABASE_DEFAULT
);
INSERT #JugReg (IdJugador, Seleccion, Numero, NombreReg)
SELECT j.IdJugador, j.Seleccion, j.Numero,
       CONVERT(NVARCHAR(30), DECRYPTBYKEYAUTOCERT(CERT_ID(N'CertificadoCifradoMundial'),
               N'ClaveMaestra_Mundial_2026!', p.Nombre))
FROM equipos.Jugador AS j
JOIN equipos.Persona AS p ON p.IdPersona = j.IdJugador;

-- N2: candidatos por nombre. Exacto=1 (nombre directo o alias), Exacto=0 (abreviado).
CREATE TABLE #Cand (Fila INT, IdJugador INT, Exacto BIT);

INSERT #Cand (Fila, IdJugador, Exacto)
SELECT s.Fila, r.IdJugador, 1
FROM #AlineacionesStaging AS s
JOIN #JugReg AS r ON r.Seleccion = s.Seleccion
WHERE s.Estado = 'Pendiente'
  AND (r.NombreReg COLLATE Latin1_General_100_CI_AI = s.Nombre COLLATE Latin1_General_100_CI_AI
       OR EXISTS (SELECT 1 FROM #AliasJugadores AS a
                  WHERE a.Habilitado = '1'
                    AND a.NombreCsv COLLATE Latin1_General_100_CI_AI = r.NombreReg COLLATE Latin1_General_100_CI_AI
                    AND a.NombrePromiedos COLLATE Latin1_General_100_CI_AI = s.Nombre COLLATE Latin1_General_100_CI_AI));

INSERT #Cand (Fila, IdJugador, Exacto)
SELECT s.Fila, r.IdJugador, 0
FROM #AlineacionesStaging AS s
JOIN #JugReg AS r ON r.Seleccion = s.Seleccion
WHERE s.Estado = 'Pendiente'
  AND s.Nombre LIKE N'_. %'
  AND LEFT(r.NombreReg COLLATE Latin1_General_100_CI_AI, 1) = LEFT(s.Nombre COLLATE Latin1_General_100_CI_AI, 1)
  AND r.NombreReg COLLATE Latin1_General_100_CI_AI LIKE N'% ' + SUBSTRING(s.Nombre, 4, 100) COLLATE Latin1_General_100_CI_AI;

-- N3: se resuelve por nombre solo si hay UN unico jugador candidato.
--     El dorsal del JSON NO se valida: vale el que quedo registrado (el primero).
UPDATE s SET IdJugador = c.IdJugador
FROM #AlineacionesStaging AS s
JOIN (SELECT Fila, MIN(IdJugador) AS IdJugador
      FROM #Cand WHERE Exacto = 1
      GROUP BY Fila HAVING COUNT(DISTINCT IdJugador) = 1) AS c ON c.Fila = s.Fila
WHERE s.Estado = 'Pendiente';

UPDATE s SET IdJugador = c.IdJugador
FROM #AlineacionesStaging AS s
JOIN (SELECT Fila, MIN(IdJugador) AS IdJugador
      FROM #Cand WHERE Exacto = 0
      GROUP BY Fila HAVING COUNT(DISTINCT IdJugador) = 1) AS c ON c.Fila = s.Fila
WHERE s.Estado = 'Pendiente' AND s.IdJugador IS NULL
  AND NOT EXISTS (SELECT 1 FROM #Cand AS e WHERE e.Fila = s.Fila AND e.Exacto = 1);

-- D7: sin match por nombre y el dorsal tampoco existe en la seleccion.
UPDATE s SET Estado='Error',
    Detalle=N'El jugador no esta cargado para esa seleccion: ejecute la carga 10.'
FROM #AlineacionesStaging AS s
WHERE s.Estado='Pendiente' AND s.IdJugador IS NULL
  AND NOT EXISTS (SELECT 1 FROM #JugReg AS r
                  WHERE r.Seleccion = s.Seleccion AND r.Numero = s.Numero);

-- D8b: dorsal compartido (solo para filas que NO se resolvieron por nombre).
--      La carga 10 conserva solo el primero que aparece (UNIQUE (Seleccion, Numero)).
UPDATE s SET Estado='Omitida',
    Detalle=N'Dorsal compartido en la seleccion: se tomo el primer jugador que aparece y este se omite.'
FROM #AlineacionesStaging AS s
WHERE s.Estado='Pendiente' AND s.IdJugador IS NULL
  AND EXISTS (SELECT 1 FROM #AlineacionesStaging o
              WHERE o.Seleccion=s.Seleccion AND o.Numero=s.Numero
                AND o.Nombre COLLATE Latin1_General_100_CI_AI <> s.Nombre COLLATE Latin1_General_100_CI_AI);

-- Fallback por dorsal para lo que no se resolvio por nombre.
UPDATE s SET IdJugador = r.IdJugador
FROM #AlineacionesStaging AS s
JOIN #JugReg AS r ON r.Seleccion = s.Seleccion AND r.Numero = s.Numero
WHERE s.Estado = 'Pendiente' AND s.IdJugador IS NULL;

-- D9: el mismo jugador aparece dos veces en el mismo partido (por IdJugador,
--     ya que el dorsal puede variar entre partidos).
UPDATE f SET Estado='Duplicada', Detalle=N'El jugador ya aparece en este partido.'
FROM #AlineacionesStaging AS f
WHERE f.Estado='Pendiente' AND EXISTS (
    SELECT 1 FROM #AlineacionesStaging AS o
    WHERE o.IdPartido = f.IdPartido AND o.IdJugador = f.IdJugador
      AND o.Estado = 'Pendiente' AND o.Fila < f.Fila
);

-- Reporte de la depuracion: se informa ANTES de escribir en la tabla real.
SELECT 'FASE 2 - Depuracion de alineaciones (antes de la persistencia)' AS Fase;
SELECT Estado, COUNT(*) AS Cantidad FROM #AlineacionesStaging GROUP BY Estado ORDER BY Estado;
SELECT Fila, GameId, Rol, Nombre, Numero, PosicionCancha, Esquema, Estado, Detalle
FROM #AlineacionesStaging WHERE Estado IN ('Error','Duplicada','Omitida') ORDER BY Fila;

---------------------------------------------------------------------------------------
-- FASE 3 - PERSISTENCIA
-- Solo las filas que quedaron en 'Pendiente' llegan a la tabla real, siempre
-- a traves de los SP de ABM de la entrega 5.
---------------------------------------------------------------------------------------

DECLARE @fila INT, @idPartido INT, @idJugador INT, @rol VARCHAR(10),
        @posicion VARCHAR(20), @esquema VARCHAR(10), @estado VARCHAR(20);
DECLARE crsAlineaciones CURSOR LOCAL FAST_FORWARD FOR
    SELECT Fila, IdPartido, IdJugador, Rol, PosicionCancha, Esquema
    FROM #AlineacionesStaging WHERE Estado='Pendiente' ORDER BY Fila;
OPEN crsAlineaciones;
FETCH NEXT FROM crsAlineaciones INTO @fila, @idPartido, @idJugador, @rol, @posicion, @esquema;
WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        SET @posicion = CONVERT(VARCHAR(20), @posicion);
        SET @esquema = CONVERT(VARCHAR(10), @esquema);
        BEGIN TRANSACTION;
        -- No existe SP de actualizacion para Alineacion: si la fila ya esta, no
        -- se toca y se informa como SinCambios.
        IF EXISTS (SELECT 1 FROM partidos.Alineacion WITH (UPDLOCK, HOLDLOCK)
                   WHERE IdPartido=@idPartido AND IdJugador=@idJugador)
            SET @estado='SinCambios';
        ELSE
        BEGIN
            EXEC SP.uspAlineacion_Registrar @IdPartido=@idPartido, @IdJugador=@idJugador,
                @Rol=@rol, @PosicionCancha=@posicion, @Esquema=@esquema;
            SET @estado='Insertada';
        END;
        COMMIT TRANSACTION;
        UPDATE #AlineacionesStaging SET Estado=@estado WHERE Fila=@fila;
    END TRY
    BEGIN CATCH
        IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
        UPDATE #AlineacionesStaging SET Estado='Error', Detalle=ERROR_MESSAGE() WHERE Fila=@fila;
    END CATCH;
    FETCH NEXT FROM crsAlineaciones INTO @fila, @idPartido, @idJugador, @rol, @posicion, @esquema;
END;
CLOSE crsAlineaciones;
DEALLOCATE crsAlineaciones;

-- Reporte final de la persistencia.
SELECT 'FASE 3 - Persistencia de alineaciones' AS Fase;
SELECT Estado, COUNT(*) AS Cantidad FROM #AlineacionesStaging GROUP BY Estado ORDER BY Estado;
SELECT Fila, GameId, IdPartido, Rol, Nombre, Numero, PosicionCancha, Esquema, IdJugador, Estado, Detalle
FROM #AlineacionesStaging ORDER BY Fila;

DECLARE @fallos INT = (SELECT COUNT(*) FROM #AlineacionesStaging WHERE Estado='Error');
DROP TABLE #AlineacionesStaging;
DROP TABLE #JugReg;
DROP TABLE #Cand;
IF @fallos > 0
    THROW 51904, 'Importacion parcial: se conservaron las alineaciones correctas. Revise el detalle.', 1;
GO