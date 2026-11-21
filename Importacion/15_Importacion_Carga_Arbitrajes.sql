-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Comision 02
-- Grupo 7: Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 13/11/2026.
-- Objetivo: cargar los arbitros y sus designaciones en los partidos de los 104
-- JSON de Promiedos con la metodologia de tres fases. El arbitro del partido
-- viene en game_info con el nombre 'Arbitro'.
-- La fuente no trae la fecha de nacimiento, que el modelo exige: se carga el
-- valor por defecto 1900-01-01.
-- Nacionalidad: Promiedos informa algunos arbitros como "Nombre (Pais)". El
-- "(Pais)" se separa del nombre (asi entra en Persona.NOMBRE, 30 caracteres) y
-- se usa como nacionalidad, tomandola de cualquier partido del mismo arbitro.
-- Si ninguna aparicion trae pais, o el pais no esta cargado en equipos.Pais,
-- se usa el pais anfitrion (USA) y queda SENALADO en el reporte con la columna
-- DatoPorDefecto.
--   FASE 1 STAGING     : una fila por partido con arbitro asignado.
--   FASE 2 DEPURACION  : reglas de conjunto (UPDATE) sobre la staging.
--   FASE 3 PERSISTENCIA : primero se da de alta el arbitro (si no existe) con
--                         SPTRANS.uspArbitro_Registrar y luego su designacion
--                         con SPTRANS.uspArbitraje_Registrar.
-- Requiere ejecutar antes las cargas 06 (paises) y 11 (partidos).
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
IF OBJECT_ID(N'arbitros.Arbitro', N'U') IS NULL
   OR OBJECT_ID(N'arbitros.Arbitraje', N'U') IS NULL
   OR OBJECT_ID(N'SPTRANS.uspArbitro_Registrar', N'P') IS NULL
   OR OBJECT_ID(N'SPTRANS.uspArbitraje_Registrar', N'P') IS NULL
    THROW 51900, 'Faltan tablas o SP ABM. Ejecute primero el instalador.', 1;

IF OBJECT_ID(N'tempdb..#ArbitrajesStaging') IS NOT NULL DROP TABLE #ArbitrajesStaging;

-- Lector compartido: deja los JSON crudos, las equivalencias y el partido resuelto.
:r $(TP_BDDA)\Importacion\XX_Lectura_Partidos_JSON.sql

---------------------------------------------------------------------------------------
-- FASE 1 - STAGING
-- Una fila por partido con arbitro principal.
---------------------------------------------------------------------------------------

CREATE TABLE #ArbitrajesStaging (
    Fila INT IDENTITY(1,1) PRIMARY KEY,
    Archivo NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    GameId NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    IdPartido INT,
    NombreOriginal NVARCHAR(150) COLLATE DATABASE_DEFAULT,
    NombreArbitro NVARCHAR(60) COLLATE DATABASE_DEFAULT,
    PaisTexto NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Funcion VARCHAR(20) COLLATE DATABASE_DEFAULT,
    IdArbitro INT,
    IdPaisAnfitrion INT,
    IdPaisArbitro INT,
    NacionalidadFuente BIT NOT NULL DEFAULT 0,
    DatoPorDefecto NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    DetallePartido NVARCHAR(2048) COLLATE DATABASE_DEFAULT,
    Estado VARCHAR(20) COLLATE DATABASE_DEFAULT NOT NULL DEFAULT 'Pendiente',
    Detalle NVARCHAR(2048) COLLATE DATABASE_DEFAULT
);

INSERT #ArbitrajesStaging
    (Archivo, GameId, IdPartido, NombreOriginal, Funcion, IdPaisAnfitrion, DatoPorDefecto, DetallePartido)
SELECT a.Archivo, p.GameId, p.IdPartido,
       (SELECT MIN(g.value) FROM OPENJSON(a.Contenido,'$.game.game_info')
        WITH (name NVARCHAR(100) '$.name', value NVARCHAR(150) '$.value') AS g
        WHERE g.name=NCHAR(193)+'rbitro'),
       N'Principal',
       (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE=N'USA'),
       N'Fecha de nacimiento no disponible en la fuente (se carga 1900-01-01) y sin nacionalidad en la fuente o pais no cargado: se usa el pais anfitrion (USA).',
       p.Detalle
FROM #ArchivosPartidos AS a
LEFT JOIN #PartidosJson AS p ON p.Archivo=a.Archivo;

IF NOT EXISTS (SELECT 1 FROM #ArbitrajesStaging)
    THROW 51901, 'No se encontraron arbitros en los JSON; revise la lectura de archivos.', 1;

-- Separa "Nombre (Pais)": el nombre queda sin el parentesis y el pais aparte.
UPDATE #ArbitrajesStaging SET
    NombreArbitro = NULLIF(LTRIM(RTRIM(CASE WHEN CHARINDEX(N'(', NombreOriginal) > 0
                          THEN LEFT(NombreOriginal, CHARINDEX(N'(', NombreOriginal) - 1)
                          ELSE NombreOriginal END)), N''),
    PaisTexto = CASE WHEN CHARINDEX(N'(', NombreOriginal) > 0 AND CHARINDEX(N')', NombreOriginal) > CHARINDEX(N'(', NombreOriginal)
                     THEN NULLIF(LTRIM(RTRIM(SUBSTRING(NombreOriginal, CHARINDEX(N'(', NombreOriginal) + 1,
                              CHARINDEX(N')', NombreOriginal) - CHARINDEX(N'(', NombreOriginal) - 1))), N'')
                END;

-- Equivalencia de nombres: Promiedos escribe a un mismo arbitro de varias
-- formas segun el partido (inicial en vez de nombre, con o sin tilde). Se
-- unifican en el nombre completo para no cargarlo como dos arbitros distintos.
CREATE TABLE #EquivalenciaArbitros (
    Variante NVARCHAR(60) COLLATE Latin1_General_100_CI_AI,
    Canonico NVARCHAR(60) COLLATE Latin1_General_100_CI_AS
);
INSERT #EquivalenciaArbitros (Variante, Canonico) VALUES
    (N'I. Barton', N'Iván Barton'),
    (N'Clement Turpin', N'Clément Turpin');
UPDATE s SET NombreArbitro = e.Canonico
FROM #ArbitrajesStaging AS s
JOIN #EquivalenciaArbitros AS e ON e.Variante = s.NombreArbitro COLLATE Latin1_General_100_CI_AI;
DROP TABLE #EquivalenciaArbitros;

-- El mismo arbitro aparece con pais en unos partidos y sin pais en otros
-- (ej. Danny Makkelie): se toma el pais informado en cualquiera de ellos.
UPDATE s SET PaisTexto = (
    SELECT MIN(o.PaisTexto) FROM #ArbitrajesStaging AS o
    WHERE o.PaisTexto IS NOT NULL
      AND o.NombreArbitro COLLATE Latin1_General_100_CI_AI = s.NombreArbitro COLLATE Latin1_General_100_CI_AI)
FROM #ArbitrajesStaging AS s
WHERE s.PaisTexto IS NULL AND s.NombreArbitro IS NOT NULL;

-- DATO COMPLEMENTARIO (no esta en la fuente): nacionalidad real de los arbitros
-- que dirigen partidos de USA y cuyo pais Promiedos no informa en ningun
-- partido. Sin esto se les asigna USA por defecto y el SP rechaza la designacion.
CREATE TABLE #NacionalidadComplemento (
    Nombre NVARCHAR(60) COLLATE Latin1_General_100_CI_AI,
    Pais NVARCHAR(100) COLLATE Latin1_General_100_CI_AI
);
INSERT #NacionalidadComplemento (Nombre, Pais) VALUES
    (N'Felix Zwayer', N'Germany'),
    (N'Mustapha Ghorbal', N'Algeria'),
    (N'Raphael Claus', N'Brazil');
UPDATE s SET PaisTexto = c.Pais
FROM #ArbitrajesStaging AS s
JOIN #NacionalidadComplemento AS c ON c.Nombre = s.NombreArbitro COLLATE Latin1_General_100_CI_AI
WHERE s.PaisTexto IS NULL;
DROP TABLE #NacionalidadComplemento;

-- Nombre del pais en la fuente (espanol) -> nombre en equipos.Pais. Los que se
-- llaman igual en ambos lados (Canada, Argentina, Paraguay, etc.) coinciden solos.
-- Los paises que no estan cargados en equipos.Pais no se pueden asignar.
CREATE TABLE #PaisesFuente (
    Texto NVARCHAR(100) COLLATE Latin1_General_100_CI_AI,
    Nombre NVARCHAR(100) COLLATE Latin1_General_100_CI_AI
);
INSERT #PaisesFuente (Texto, Nombre) VALUES
    (N'Estados Unidos', N'USA'), (N'Paises Bajos', N'Netherlands'), (N'Inglaterra', N'England'),
    (N'Marruecos', N'Morocco'), (N'Francia', N'France'), (N'Brasil', N'Brazil'),
    (N'Noruega', N'Norway'), (N'Mexico', N'Mexico');

UPDATE s SET IdPaisArbitro = (
    SELECT MIN(p.IdPais) FROM equipos.Pais AS p
    WHERE p.NOMBRE COLLATE Latin1_General_100_CI_AI = s.PaisTexto COLLATE Latin1_General_100_CI_AI
       OR p.NOMBRE COLLATE Latin1_General_100_CI_AI = (
            SELECT MIN(f.Nombre) FROM #PaisesFuente AS f
            WHERE f.Texto = s.PaisTexto COLLATE Latin1_General_100_CI_AI))
FROM #ArbitrajesStaging AS s
WHERE s.PaisTexto IS NOT NULL;
DROP TABLE #PaisesFuente;

-- Con nacionalidad resuelta no corresponde el aviso de dato por defecto; sin
-- ella se usa el pais anfitrion, como antes.
UPDATE #ArbitrajesStaging SET NacionalidadFuente = 1,
    DatoPorDefecto = N'Fecha de nacimiento no disponible en la fuente: se carga 1900-01-01. Nacionalidad tomada de la fuente.'
WHERE IdPaisArbitro IS NOT NULL;
UPDATE #ArbitrajesStaging SET IdPaisArbitro = IdPaisAnfitrion
WHERE IdPaisArbitro IS NULL;

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
              WHERE CONVERT(NVARCHAR(30), DECRYPTBYKEYAUTOCERT(CERT_ID(N'CertificadoCifradoMundial'), N'ClaveMaestra_Mundial_2026!', pe.Nombre)) = #ArbitrajesStaging.NombreArbitro
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
JOIN equipos.Persona AS pe ON CONVERT(NVARCHAR(30), DECRYPTBYKEYAUTOCERT(CERT_ID(N'CertificadoCifradoMundial'), N'ClaveMaestra_Mundial_2026!', pe.Nombre)) = s.NombreArbitro
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
        @idArbitro INT, @idPais INT, @nacFuente BIT, @estado VARCHAR(20), @estadoArbitro VARCHAR(20);
-- La fecha de nacimiento no viene en la fuente: se usa un valor por defecto.
-- El valor por defecto de un parametro de EXEC debe ser una constante o una
-- variable, nunca una expresion CONVERT.
DECLARE @fnac DATE = CONVERT(DATE,'1900-01-01',23);
DECLARE crsArbitrajes CURSOR LOCAL FAST_FORWARD FOR
    SELECT Fila, CONVERT(NVARCHAR(30), NombreArbitro), IdPartido, Funcion, IdArbitro, IdPaisArbitro, NacionalidadFuente
    FROM #ArbitrajesStaging WHERE Estado='Pendiente' ORDER BY Fila;
OPEN crsArbitrajes;
FETCH NEXT FROM crsArbitrajes INTO @fila, @nombre, @idPartido, @funcion, @idArbitro, @idPais, @nacFuente;
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
            WHERE pe.NombreHash = HASHBYTES('SHA2_256', @nombre);
            -- Cargas anteriores guardaban el nombre con el "(Pais)": se
            -- reutiliza ese arbitro y se corrige su nombre.
            IF @idArbitro IS NULL
            BEGIN
                -- Busqueda por hash (Nombre esta cifrado, no se puede usar LIKE)
                SELECT @idArbitro = MIN(ar.IdArbitro)
                FROM equipos.Persona AS pe
                JOIN arbitros.Arbitro AS ar ON ar.IdArbitro = pe.IdPersona
                WHERE pe.NombreHash = HASHBYTES('SHA2_256', @nombre);
                IF @idArbitro IS NOT NULL
                    EXEC SPTRANS.uspArbitro_Update @id=@idArbitro, @nombre=@nombre;
            END;
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
            WHERE CONVERT(NVARCHAR(30), DECRYPTBYKEYAUTOCERT(CERT_ID(N'CertificadoCifradoMundial'), N'ClaveMaestra_Mundial_2026!', pe.Nombre))=@nombre;
            SET @estadoArbitro='Insertado';
        END
        ELSE
        BEGIN
            SET @estadoArbitro='SinCambios';
            -- Si la fuente informa su nacionalidad y la persona quedo cargada
            -- con otro pais (cargas anteriores usaban el anfitrion), se corrige.
            IF @nacFuente = 1 AND EXISTS (SELECT 1 FROM equipos.Persona
                                          WHERE IdPersona=@idArbitro AND Pais<>@idPais)
            BEGIN
                EXEC SPTRANS.uspArbitro_Update @id=@idArbitro, @pais=@idPais;
                SET @estadoArbitro='Actualizado';
            END;
        END;

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
    FETCH NEXT FROM crsArbitrajes INTO @fila, @nombre, @idPartido, @funcion, @idArbitro, @idPais, @nacFuente;
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

