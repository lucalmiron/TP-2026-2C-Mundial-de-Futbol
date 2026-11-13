-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Comision 02
-- Grupo 7: Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 13/11/2026.
-- Objetivo: cargar los cuerpos tecnicos (DT) de los 104 JSON de Promiedos con
-- la metodologia de tres fases. Los datos vienen en
-- $.game.players.lineups.teams[*].staff[*].
-- La fuente no trae la fecha de nacimiento, que el modelo exige: se carga con
-- el valor por defecto 1900-01-01 y queda SENALADO en el reporte con la
-- columna DatoPorDefecto.
--   FASE 1 STAGING     : una fila por miembro del cuerpo tecnico.
--   FASE 2 DEPURACION  : reglas de conjunto (UPDATE) sobre la staging.
--   FASE 3 PERSISTENCIA : solo las filas validas pasan por
--                         SPTRANS.uspTecnico_Registrar.
-- Requiere ejecutar antes las cargas 06 (paises) y 07 (selecciones).
-- SSMS: Consulta -> Modo SQLCMD. Ajustar las rutas del servidor SQL.
-- IMPORTANTE: cada integrante debe poner las rutas de su propia PC.
-- :setvar CarpetaPartidos "C:\ruta\proyecto\Datos\Datos_Partidos\partidos"
-- :setvar RutaLecturaJSON "C:\ruta\proyecto\Importacion\11_Lectura_JSON_Partidos.sql"
-- :setvar RutaLecturaPartidos "C:\ruta\proyecto\Importacion\XX_Lectura_Partidos_JSON.sql"
-- :setvar RutaEquipos "C:\ruta\proyecto\Datos\equivalencias_equipos_jugadores.csv"
-- :setvar RutaSedes "C:\ruta\proyecto\Datos\equivalencias_sedes_partidos.csv"
-- :setvar RutaFases "C:\ruta\proyecto\Datos\equivalencias_fases_partidos.csv"
:setvar RutaAliasJugadores "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Datos\Jugadores\equivalencias_jugadores.csv"
-- :setvar RutaAliasJugadores "C:\ruta\proyecto\Datos\Jugadores\equivalencias_jugadores.csv"

:setvar CarpetaPartidos "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Datos\Datos_Partidos\partidos"
:setvar RutaLecturaJSON "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Importacion\11_Lectura_JSON_Partidos.sql"
:setvar RutaLecturaPartidos "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Importacion\XX_Lectura_Partidos_JSON.sql"
:setvar RutaEquipos "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Datos\equivalencias_equipos_jugadores.csv"
:setvar RutaSedes "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Datos\equivalencias_sedes_partidos.csv"
:setvar RutaFases "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Datos\equivalencias_fases_partidos.csv"

USE [MUNDIAL];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF @@TRANCOUNT <> 0 OR (2 & @@OPTIONS) = 2
    THROW 51900, 'Ejecute sin transaccion externa y con IMPLICIT_TRANSACTIONS OFF.', 1;
IF OBJECT_ID(N'equipos.Tecnico', N'U') IS NULL
   OR OBJECT_ID(N'SPTRANS.uspTecnico_Registrar', N'P') IS NULL
    THROW 51900, 'Faltan tablas o SP ABM. Ejecute primero el instalador.', 1;

IF OBJECT_ID(N'tempdb..#TecnicosStaging') IS NOT NULL DROP TABLE #TecnicosStaging;

-- Lector compartido: deja los JSON crudos, las equivalencias y el partido resuelto.
:r $(RutaLecturaPartidos)

---------------------------------------------------------------------------------------
-- FASE 1 - STAGING
-- Una fila por miembro del cuerpo tecnico.
---------------------------------------------------------------------------------------

CREATE TABLE #TecnicosStaging (
    Fila INT IDENTITY(1,1) PRIMARY KEY,
    Archivo NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    GameId NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    TeamNum INT,
    Nombre NVARCHAR(60) COLLATE DATABASE_DEFAULT,
    Posicion NVARCHAR(60) COLLATE DATABASE_DEFAULT,
    FormacionPosicion NVARCHAR(60) COLLATE DATABASE_DEFAULT,
    Funcion VARCHAR(40) COLLATE DATABASE_DEFAULT,
    IdSeleccion INT,
    IdPais INT,
    DatoPorDefecto NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    IdTecnico INT,
    DetallePartido NVARCHAR(2048) COLLATE DATABASE_DEFAULT,
    Estado VARCHAR(20) COLLATE DATABASE_DEFAULT NOT NULL DEFAULT 'Pendiente',
    Detalle NVARCHAR(2048) COLLATE DATABASE_DEFAULT
);

INSERT #TecnicosStaging
    (Archivo, GameId, TeamNum, Nombre, Posicion, FormacionPosicion, Funcion,
     IdSeleccion, IdPais, DatoPorDefecto, DetallePartido)
SELECT a.Archivo, p.GameId, t.TeamNum, s.Nombre, s.Posicion, s.FormationPosition,
       CASE WHEN s.Posicion=N'Direcci'+NCHAR(243)+'n' OR s.FormationPosition=N'Entrenador'
            THEN N'Direcci'+NCHAR(243)+'n T'+NCHAR(233)+'cnica' ELSE s.Posicion END,
       CASE WHEN t.TeamNum=1 THEN p.Eq1 ELSE p.Eq2 END,
       NULL,
       N'Fecha de nacimiento no disponible en la fuente: se carga 1900-01-01.', p.Detalle
FROM #ArchivosPartidos AS a
LEFT JOIN #PartidosJson AS p ON p.Archivo=a.Archivo
CROSS APPLY OPENJSON(a.Contenido, '$.game.players.lineups.teams') WITH (
    TeamNum INT '$.team_num',
    Staff NVARCHAR(MAX) '$.staff' AS JSON
) AS t
CROSS APPLY OPENJSON(ISNULL(t.Staff,N'[]')) WITH (
    Nombre NVARCHAR(60) '$.name',
    Posicion NVARCHAR(60) '$.position',
    FormationPosition NVARCHAR(60) '$.formation_position'
) AS s;

IF NOT EXISTS (SELECT 1 FROM #TecnicosStaging)
    THROW 51901, 'No se encontraron cuerpos tecnicos en los JSON; revise la lectura de archivos.', 1;

---------------------------------------------------------------------------------------
-- FASE 2 - DEPURACION
-- Reglas de conjunto: cada UPDATE marca las filas invalidas y su motivo.
-- No se borra nada; las filas validas quedan en Estado = 'Pendiente'.
---------------------------------------------------------------------------------------

-- D1: el JSON del partido no se pudo resolver.
UPDATE #TecnicosStaging SET Estado='Error',
    Detalle=ISNULL(DetallePartido, N'El JSON del partido no se pudo resolver.')
WHERE Estado='Pendiente' AND IdSeleccion IS NULL;

-- D2: falta el nombre del tecnico.
UPDATE #TecnicosStaging SET Estado='Error',
    Detalle=N'El miembro del cuerpo tecnico no tiene nombre.'
WHERE Estado='Pendiente' AND NULLIF(Nombre,N'') IS NULL;

-- D3: el nombre no cabe en Persona.NOMBRE NVARCHAR(30).
--     La columna es NVARCHAR: no hay perdida de caracteres, solo cuenta longitud.
UPDATE #TecnicosStaging SET Estado='Error',
    Detalle=N'El nombre excede los 30 caracteres de Persona.NOMBRE.'
WHERE Estado='Pendiente' AND Nombre IS NOT NULL AND LEN(Nombre) > 30;

-- D4: la funcion no cabe en VARCHAR(40).
UPDATE #TecnicosStaging SET Estado='Error',
    Detalle=N'La funcion no cabe fielmente en VARCHAR(40).'
WHERE Estado='Pendiente' AND Funcion IS NOT NULL
  AND (DATALENGTH(CONVERT(VARCHAR(MAX),Funcion)) > 40
    OR CONVERT(NVARCHAR(MAX),CONVERT(VARCHAR(MAX),Funcion)) COLLATE Latin1_General_100_BIN2
         <> Funcion COLLATE Latin1_General_100_BIN2);

-- D5: ya existe una persona con ese nombre y no es tecnico (el SP lo rechazaria).
UPDATE #TecnicosStaging SET Estado='Error',
    Detalle=N'Ya existe una persona con ese nombre y no es tecnico: revise la carga 10.'
WHERE Estado='Pendiente'
  AND EXISTS (SELECT 1 FROM equipos.Persona AS pe
              WHERE pe.Nombre = #TecnicosStaging.Nombre
                AND NOT EXISTS (SELECT 1 FROM equipos.Tecnico AS te WHERE te.IdTecnico = pe.IdPersona));

-- Se resuelve el pais de la seleccion (el DT es de la seleccion que dirige).
UPDATE s SET IdPais = p.IdPais
FROM #TecnicosStaging AS s
JOIN equipos.Seleccion AS se ON se.IdSeleccion = s.IdSeleccion
JOIN equipos.Pais AS p ON p.IdPais = se.IdPais
WHERE s.Estado='Pendiente';

-- D6: el pais de la seleccion no se pudo resolver.
UPDATE #TecnicosStaging SET Estado='Error',
    Detalle=N'No se pudo determinar el pais de la seleccion.'
WHERE Estado='Pendiente' AND IdPais IS NULL;

-- D7: el mismo tecnico aparece en dos JSON del mismo equipo.
UPDATE f SET Estado='Duplicada', Detalle=N'El tecnico ya aparece para esa seleccion.'
FROM #TecnicosStaging AS f
WHERE f.Estado='Pendiente' AND EXISTS (
    SELECT 1 FROM #TecnicosStaging AS o
    WHERE o.Nombre=f.Nombre AND o.IdSeleccion=f.IdSeleccion AND o.Fila<f.Fila
);

-- Reporte de la depuracion: se informa ANTES de escribir en la tabla real.
SELECT 'FASE 2 - Depuracion de cuerpos tecnicos (antes de la persistencia)' AS Fase;
SELECT Estado, COUNT(*) AS Cantidad FROM #TecnicosStaging GROUP BY Estado ORDER BY Estado;
SELECT Fila, GameId, Nombre, Posicion, Funcion, IdSeleccion, IdPais, DatoPorDefecto, Estado, Detalle
FROM #TecnicosStaging WHERE Estado IN ('Error','Duplicada') ORDER BY Fila;

---------------------------------------------------------------------------------------
-- FASE 3 - PERSISTENCIA
-- Solo las filas que quedaron en 'Pendiente' llegan a la tabla real, siempre
-- a traves de los SP de ABM de la entrega 5.
---------------------------------------------------------------------------------------

DECLARE @fila INT, @nombre NVARCHAR(30), @idPais INT, @funcion VARCHAR(40),
        @idSeleccion INT, @idTecnico INT, @estado VARCHAR(20);
-- La fecha de nacimiento no viene en la fuente: se usa un valor por defecto.
-- El valor por defecto de un parametro de EXEC debe ser una constante o una
-- variable, nunca una expresion CONVERT.
DECLARE @fnac DATE = CONVERT(DATE,'1900-01-01',23);
DECLARE crsTecnicos CURSOR LOCAL FAST_FORWARD FOR
    SELECT Fila, CONVERT(NVARCHAR(30), Nombre), IdPais, Funcion, IdSeleccion
    FROM #TecnicosStaging WHERE Estado='Pendiente' ORDER BY Fila;
OPEN crsTecnicos;
FETCH NEXT FROM crsTecnicos INTO @fila, @nombre, @idPais, @funcion, @idSeleccion;
WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        -- El tecnico puede haberse creado al procesar otro JSON: se busca de
        -- nuevo antes de darlo de alta, para que la carga sea idempotente.
        SET @idTecnico = NULL;
        SELECT @idTecnico = te.IdTecnico
        FROM equipos.Persona AS pe
        JOIN equipos.Tecnico AS te ON te.IdTecnico = pe.IdPersona
        WHERE pe.Nombre = @nombre;
        IF @idTecnico IS NULL
        BEGIN
            EXEC SPTRANS.uspTecnico_Registrar @nombre=@nombre,
                @fnac=@fnac,
                @pais=@idPais, @funcion=@funcion, @seleccion=@idSeleccion;
            SET @idTecnico = NULL;
            SELECT @idTecnico = te.IdTecnico
            FROM equipos.Persona AS pe
            JOIN equipos.Tecnico AS te ON te.IdTecnico = pe.IdPersona
            WHERE pe.Nombre = @nombre;
            SET @estado='Insertada';
        END
        ELSE SET @estado='SinCambios';
        UPDATE #TecnicosStaging SET IdTecnico=@idTecnico, Estado=@estado WHERE Fila=@fila;
    END TRY
    BEGIN CATCH
        SET @estado='Error';
        UPDATE #TecnicosStaging SET Estado='Error', Detalle=ERROR_MESSAGE() WHERE Fila=@fila;
    END CATCH;
    IF @estado <> 'Error'
        UPDATE #TecnicosStaging SET Estado=@estado WHERE Fila=@fila;
    FETCH NEXT FROM crsTecnicos INTO @fila, @nombre, @idPais, @funcion, @idSeleccion;
END;
CLOSE crsTecnicos;
DEALLOCATE crsTecnicos;

-- Reporte final de la persistencia.
SELECT 'FASE 3 - Persistencia de cuerpos tecnicos' AS Fase;
SELECT Estado, COUNT(*) AS Cantidad FROM #TecnicosStaging GROUP BY Estado ORDER BY Estado;
SELECT Fila, GameId, Nombre, Funcion, IdSeleccion, IdPais, IdTecnico, DatoPorDefecto, Estado, Detalle
FROM #TecnicosStaging ORDER BY Fila;

DECLARE @fallos INT = (SELECT COUNT(*) FROM #TecnicosStaging WHERE Estado='Error');
DROP TABLE #TecnicosStaging;
IF @fallos > 0
    THROW 51904, 'Importacion parcial: se conservaron los cuerpos tecnicos correctos. Revise el detalle.', 1;
GO

