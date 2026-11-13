-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Comision 02
-- Grupo 7: Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 13/11/2026.
-- Objetivo: cargar los arbitros y sus designaciones en los partidos de los 104
-- JSON de Promiedos con la metodologia de tres fases. El arbitro del partido
-- viene en game_info con el nombre 'Arbitro'.
-- La fuente no trae la fecha de nacimiento ni la nacionalidad del arbitro, que
-- el modelo exige: se cargan con los valores por defecto 1900-01-01 y el pais
-- anfitrion, y quedan SENALADOS en el reporte con la columna DatoPorDefecto.
--   FASE 1 STAGING     : una fila por partido con arbitro asignado.
--   FASE 2 DEPURACION  : reglas de conjunto (UPDATE) sobre la staging.
--   FASE 3 PERSISTENCIA : primero se da de alta el arbitro (si no existe) con
--                         SPTRANS.uspArbitro_Registrar y luego su designacion
--                         con SPTRANS.uspArbitraje_Registrar.
-- Requiere ejecutar antes las cargas 06 (paises) y 11 (partidos).
-- SSMS: Consulta -> Modo SQLCMD. Ajustar las rutas del servidor SQL.
-- IMPORTANTE: cada integrante debe poner las rutas de su propia PC.
-- :setvar CarpetaPartidos "C:\ruta\proyecto\Datos\Datos_Partidos\partidos"
-- :setvar RutaLecturaJSON "C:\ruta\proyecto\Importacion\11_Lectura_JSON_Partidos.sql"
-- :setvar RutaLecturaPartidos "C:\ruta\proyecto\Importacion\XX_Lectura_Partidos_JSON.sql"
-- :setvar RutaEquipos "C:\ruta\proyecto\Datos\equivalencias_equipos_jugadores.csv"
-- :setvar RutaSedes "C:\ruta\proyecto\Datos\equivalencias_sedes_partidos.csv"
-- :setvar RutaFases "C:\ruta\proyecto\Datos\equivalencias_fases_partidos.csv"
-- :setvar RutaAliasJugadores "C:\ruta\proyecto\Datos\Jugadores\equivalencias_jugadores.csv"

--L
:setvar CarpetaPartidos "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Datos\Datos_Partidos\partidos"
:setvar RutaLecturaJSON "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Importacion\11_Lectura_JSON_Partidos.sql"
:setvar RutaLecturaPartidos "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Importacion\XX_Lectura_Partidos_JSON.sql"
:setvar RutaEquipos "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Datos\equivalencias_equipos_jugadores.csv"
:setvar RutaSedes "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Datos\equivalencias_sedes_partidos.csv"
:setvar RutaFases "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Datos\equivalencias_fases_partidos.csv"
:setvar RutaAliasJugadores "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Datos\Jugadores\equivalencias_jugadores.csv"

--Fidel
--:setvar CarpetaPartidos "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Datos\Datos_Partidos\partidos"
--:setvar RutaLecturaJSON "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Importacion\11_Lectura_JSON_Partidos.sql"
--:setvar RutaLecturaPartidos "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Importacion\XX_Lectura_Partidos_JSON.sql"
--:setvar RutaEquipos "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Datos\equivalencias_equipos_jugadores.csv"
--:setvar RutaSedes "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Datos\equivalencias_sedes_partidos.csv"
--:setvar RutaFases "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Datos\equivalencias_fases_partidos.csv"
--:setvar RutaAliasJugadores "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Datos\Jugadores\equivalencias_jugadores.csv"


USE [MUNDIALtesting];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF @@TRANCOUNT <> 0 OR (2 & @@OPTIONS) = 2
    THROW 51900, 'Ejecute sin transaccion externa y con IMPLICIT_TRANSACTIONS OFF.', 1;
IF OBJECT_ID(N'arbitros.Arbitro', N'U') IS NULL
   OR OBJECT_ID(N'arbitros.Arbitraje', N'U') IS NULL
   OR OBJECT_ID(N'SPTRANS.uspArbitro_Registrar', N'P') IS NULL
   OR OBJECT_ID(N'SPTRANS.uspArbitraje_Registrar', N'P') IS NULL
    THROW 51900, 'Faltan tablas o SP ABM. Ejecute primero el instalador.', 1;

IF OBJECT_ID(N'tempdb..#ArbitrajesStaging') IS NOT NULL DROP TABLE #ArbitrajesStaging;

-- Lector compartido: deja los JSON crudos, las equivalencias y el partido resuelto.
:r $(RutaLecturaPartidos)

---------------------------------------------------------------------------------------
-- FASE 1 - STAGING
-- Una fila por partido con arbitro principal.
---------------------------------------------------------------------------------------

CREATE TABLE #ArbitrajesStaging (
    Fila INT IDENTITY(1,1) PRIMARY KEY,
    Archivo NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    GameId NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    IdPartido INT,
    NombreArbitro NVARCHAR(60) COLLATE DATABASE_DEFAULT,
    Funcion VARCHAR(20) COLLATE DATABASE_DEFAULT,
    IdArbitro INT,
    IdPaisAnfitrion INT,
    DatoPorDefecto NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    DetallePartido NVARCHAR(2048) COLLATE DATABASE_DEFAULT,
    Estado VARCHAR(20) COLLATE DATABASE_DEFAULT NOT NULL DEFAULT 'Pendiente',
    Detalle NVARCHAR(2048) COLLATE DATABASE_DEFAULT
);

INSERT #ArbitrajesStaging
    (Archivo, GameId, IdPartido, NombreArbitro, Funcion, IdPaisAnfitrion, DatoPorDefecto, DetallePartido)
SELECT a.Archivo, p.GameId, p.IdPartido,
       (SELECT MIN(g.value) FROM OPENJSON(a.Contenido,'$.game.game_info')
        WITH (name NVARCHAR(100) '$.name', value NVARCHAR(150) '$.value') AS g
        WHERE g.name=NCHAR(193)+'rbitro'),
       N'Principal',
       (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE=N'USA'),
       N'Fecha de nacimiento y nacionalidad no disponibles en la fuente: se carga 1900-01-01 y el pais anfitrion (USA).',
       p.Detalle
FROM #ArchivosPartidos AS a
LEFT JOIN #PartidosJson AS p ON p.Archivo=a.Archivo;

IF NOT EXISTS (SELECT 1 FROM #ArbitrajesStaging)
    THROW 51901, 'No se encontraron arbitros en los JSON; revise la lectura de archivos.', 1;

---------------------------------------------------------------------------------------
-- FASE 2 - DEPURACION
-- Reglas de conjunto: cada UPDATE marca las filas invalidas y su motivo.
-- No se borra nada; las filas validas quedan en Estado = 'Pendiente'.
---------------------------------------------------------------------------------------

-- D1: el JSON del partido no se pudo resolver.
UPDATE #ArbitrajesStaging SET Estado='Error',
    Detalle=ISNULL(DetallePartido, N'El JSON del partido no se pudo resolver.')
WHERE Estado='Pendiente' AND IdPartido IS NULL;

-- D2: el partido no indica arbitro.
UPDATE #ArbitrajesStaging SET Estado='Error',
    Detalle=N'El partido no indica arbitro.'
WHERE Estado='Pendiente' AND NULLIF(NombreArbitro,N'') IS NULL;

-- D3: el nombre no cabe en Persona.NOMBRE NVARCHAR(30).
--     La columna es NVARCHAR: no hay perdida de caracteres, solo cuenta longitud.
UPDATE #ArbitrajesStaging SET Estado='Error',
    Detalle=N'El nombre del arbitro excede los 30 caracteres de Persona.NOMBRE.'
WHERE Estado='Pendiente' AND NombreArbitro IS NOT NULL AND LEN(NombreArbitro) > 30;

-- D4: no se pudo determinar el pais anfitrion.
UPDATE #ArbitrajesStaging SET Estado='Error',
    Detalle=N'No se pudo determinar el pais anfitrion: revise la carga 06.'
WHERE Estado='Pendiente' AND IdPaisAnfitrion IS NULL;

-- D5: ya existe una persona con ese nombre que no es arbitro.
UPDATE #ArbitrajesStaging SET Estado='Error',
    Detalle=N'Ya existe una persona con ese nombre y no es arbitro: revise la carga 10.'
WHERE Estado='Pendiente'
  AND EXISTS (SELECT 1 FROM equipos.Persona AS pe
              WHERE pe.Nombre = #ArbitrajesStaging.NombreArbitro
                AND NOT EXISTS (SELECT 1 FROM arbitros.Arbitro AS ar WHERE ar.IdArbitro=pe.IdPersona));

-- D6: el arbitro ya fue designado en ese partido.
UPDATE f SET Estado='Duplicada', Detalle=N'El arbitro ya fue designado en este partido.'
FROM #ArbitrajesStaging AS f
WHERE f.Estado='Pendiente' AND EXISTS (
    SELECT 1 FROM #ArbitrajesStaging AS o
    WHERE o.IdPartido=f.IdPartido AND o.NombreArbitro=f.NombreArbitro AND o.Fila<f.Fila
);

-- Se resuelve el arbitro si ya estaba cargado.
UPDATE s SET IdArbitro = ar.IdArbitro
FROM #ArbitrajesStaging AS s
JOIN equipos.Persona AS pe ON pe.Nombre = s.NombreArbitro
JOIN arbitros.Arbitro AS ar ON ar.IdArbitro = pe.IdPersona
WHERE s.Estado='Pendiente';

-- Reporte de la depuracion: se informa ANTES de escribir en la tabla real.
SELECT 'FASE 2 - Depuracion de designaciones arbitrales (antes de la persistencia)' AS Fase;
SELECT Estado, COUNT(*) AS Cantidad FROM #ArbitrajesStaging GROUP BY Estado ORDER BY Estado;
SELECT Fila, GameId, IdPartido, NombreArbitro, Funcion, IdArbitro, DatoPorDefecto, Estado, Detalle
FROM #ArbitrajesStaging WHERE Estado IN ('Error','Duplicada') ORDER BY Fila;

---------------------------------------------------------------------------------------
-- FASE 3 - PERSISTENCIA
-- Primero se da de alta el arbitro si no existia y luego su designacion.
---------------------------------------------------------------------------------------

DECLARE @fila INT, @nombre NVARCHAR(30), @idPartido INT, @funcion VARCHAR(20),
        @idArbitro INT, @idPais INT, @estado VARCHAR(20), @estadoArbitro VARCHAR(20);
-- La fecha de nacimiento no viene en la fuente: se usa un valor por defecto.
-- El valor por defecto de un parametro de EXEC debe ser una constante o una
-- variable, nunca una expresion CONVERT.
DECLARE @fnac DATE = CONVERT(DATE,'1900-01-01',23);
DECLARE crsArbitrajes CURSOR LOCAL FAST_FORWARD FOR
    SELECT Fila, CONVERT(NVARCHAR(30), NombreArbitro), IdPartido, Funcion, IdArbitro, IdPaisAnfitrion
    FROM #ArbitrajesStaging WHERE Estado='Pendiente' ORDER BY Fila;
OPEN crsArbitrajes;
FETCH NEXT FROM crsArbitrajes INTO @fila, @nombre, @idPartido, @funcion, @idArbitro, @idPais;
WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @idArbitro IS NULL
        BEGIN
            -- El arbitro puede haberse creado al procesar otro partido: se
            -- busca de nuevo antes de darlo de alta, para que la carga sea
            -- idempotente.
            SET @idArbitro = NULL;
            SELECT @idArbitro = ar.IdArbitro
            FROM equipos.Persona AS pe
            JOIN arbitros.Arbitro AS ar ON ar.IdArbitro = pe.IdPersona
            WHERE pe.Nombre = @nombre;
        END;
        IF @idArbitro IS NULL
        BEGIN
            -- Alta del arbitro. La persona se crea con rol 'Arbitro'.
            EXEC SPTRANS.uspArbitro_Registrar @nombre=@nombre,
                @fnac=@fnac,
                @pais=@idPais, @categoria=N'FIFA';
            SET @idArbitro = NULL;
            SELECT @idArbitro = IdArbitro
            FROM arbitros.Arbitro AS ar
            JOIN equipos.Persona AS pe ON pe.IdPersona=ar.IdArbitro
            WHERE pe.Nombre=@nombre;
            SET @estadoArbitro='Insertado';
        END
        ELSE SET @estadoArbitro='SinCambios';

        IF EXISTS (SELECT 1 FROM arbitros.Arbitraje WHERE Arbitro=@idArbitro AND Partido=@idPartido)
            SET @estado='SinCambios';
        ELSE
        BEGIN
            EXEC SPTRANS.uspArbitraje_Registrar @arbitro=@idArbitro, @funcion=@funcion, @partido=@idPartido;
            SET @estado='Insertada';
        END;
        COMMIT TRANSACTION;
        UPDATE #ArbitrajesStaging SET IdArbitro=@idArbitro, Estado=@estado,
            Detalle=N'Arbitro: '+@estadoArbitro WHERE Fila=@fila;
    END TRY
    BEGIN CATCH
        IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
        UPDATE #ArbitrajesStaging SET Estado='Error', Detalle=ERROR_MESSAGE() WHERE Fila=@fila;
    END CATCH;
    FETCH NEXT FROM crsArbitrajes INTO @fila, @nombre, @idPartido, @funcion, @idArbitro, @idPais;
END;
CLOSE crsArbitrajes;
DEALLOCATE crsArbitrajes;

-- Reporte final de la persistencia.
SELECT 'FASE 3 - Persistencia de designaciones arbitrales' AS Fase;
SELECT Estado, COUNT(*) AS Cantidad FROM #ArbitrajesStaging GROUP BY Estado ORDER BY Estado;
SELECT Fila, GameId, IdPartido, NombreArbitro, IdArbitro, Funcion, DatoPorDefecto, Estado, Detalle
FROM #ArbitrajesStaging ORDER BY Fila;

DECLARE @fallos INT = (SELECT COUNT(*) FROM #ArbitrajesStaging WHERE Estado='Error');
DROP TABLE #ArbitrajesStaging;
IF @fallos > 0
    THROW 51904, 'Importacion parcial: se conservaron las designaciones correctas. Revise el detalle.', 1;
GO

