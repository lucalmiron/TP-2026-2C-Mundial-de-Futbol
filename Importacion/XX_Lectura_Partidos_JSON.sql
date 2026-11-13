-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Comision 02
-- Grupo 7: Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 13/11/2026.
-- Objetivo: lector compartido por los importadores de datos deportivos
-- (13 a 18). NO EJECUTAR SOLO: se incluye con :r desde un importador.
--
-- Prepara la FASE 1 (staging) comun:
--   #ArchivosPartidos : los 104 JSON originales, sin modificar.
--   #ErroresArchivos  : los archivos que no se pudieron leer o interpretar.
--   #FasesPartidos    : equivalencias tipo/valor -> fase de la base.
--   #EquiposPartidos  : equivalencias equipo de Promiedos -> pais de la base.
--   #SedesPartidos    : equivalencias nombre_json -> sede de la base.
--   #PartidosJson     : una fila por JSON con el partido resuelto.
--
-- El importador que lo incluye debe definir antes estas variables y usar
-- :r $(RutaLecturaPartidos) dentro del mismo lote (sin GO):
--   CarpetaPartidos, RutaLecturaJSON, RutaEquipos, RutaSedes, RutaFases

IF OBJECT_ID(N'tempdb..#ArchivosPartidos') IS NOT NULL DROP TABLE #ArchivosPartidos;
IF OBJECT_ID(N'tempdb..#ErroresArchivos') IS NOT NULL DROP TABLE #ErroresArchivos;
IF OBJECT_ID(N'tempdb..#FasesPartidos') IS NOT NULL DROP TABLE #FasesPartidos;
IF OBJECT_ID(N'tempdb..#EquiposPartidos') IS NOT NULL DROP TABLE #EquiposPartidos;
IF OBJECT_ID(N'tempdb..#SedesPartidos') IS NOT NULL DROP TABLE #SedesPartidos;
IF OBJECT_ID(N'tempdb..#AliasJugadores') IS NOT NULL DROP TABLE #AliasJugadores;
IF OBJECT_ID(N'tempdb..#PartidosJson') IS NOT NULL DROP TABLE #PartidosJson;

-- El contenido se guarda como VARCHAR con collation UTF8 porque SINGLE_BLOB
-- entrega los bytes crudos del archivo; luego se convierte a NVARCHAR al leerlo.
CREATE TABLE #ArchivosPartidos (
    Archivo NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Contenido VARCHAR(MAX) COLLATE Latin1_General_100_CI_AS_SC_UTF8
);
CREATE TABLE #ErroresArchivos (
    Archivo NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Detalle NVARCHAR(2048) COLLATE DATABASE_DEFAULT
);
CREATE TABLE #FasesPartidos (
    Tipo NVARCHAR(20) COLLATE DATABASE_DEFAULT,
    Valor NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Fase NVARCHAR(50) COLLATE DATABASE_DEFAULT
);
CREATE TABLE #EquiposPartidos (
    SeleccionCsv NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Slug NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Pais NVARCHAR(100) COLLATE DATABASE_DEFAULT
);
CREATE TABLE #SedesPartidos (
    NombreJson NVARCHAR(150) COLLATE DATABASE_DEFAULT,
    NombreSede NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Ciudad NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Pais NVARCHAR(100) COLLATE DATABASE_DEFAULT
);
-- Equivalencias de nombres de jugadores: la fuente Promiedos y el CSV de
-- jugadores (Kaggle) no siempre usan el mismo nombre. Habilitado='1' marca
-- las equivalencias aprobadas por el grupo.
CREATE TABLE #AliasJugadores (
    Seleccion NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    NombreCsv NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    NombrePromiedos NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    Habilitado VARCHAR(10) COLLATE DATABASE_DEFAULT,
    Criterio NVARCHAR(500) COLLATE DATABASE_DEFAULT
);
CREATE TABLE #PartidosJson (
    Fila INT IDENTITY(1,1) PRIMARY KEY,
    Archivo NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    GameId NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Etapa NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    IdFase INT,
    Eq1 INT,
    Eq2 INT,
    IdSede INT,
    IdPartido INT,
    Estado VARCHAR(20) COLLATE DATABASE_DEFAULT NOT NULL DEFAULT 'Pendiente',
    Detalle NVARCHAR(2048) COLLATE DATABASE_DEFAULT
);

BEGIN TRY
    BULK INSERT #FasesPartidos FROM '$(RutaFases)'
    WITH (FORMAT='CSV', FIRSTROW=2, FIELDTERMINATOR=',',
          ROWTERMINATOR='0x0a', CODEPAGE='65001', MAXERRORS=0);
    BULK INSERT #EquiposPartidos FROM '$(RutaEquipos)'
    WITH (FORMAT='CSV', FIRSTROW=2, FIELDTERMINATOR=',',
          ROWTERMINATOR='0x0a', CODEPAGE='65001', MAXERRORS=0);
    BULK INSERT #SedesPartidos FROM '$(RutaSedes)'
    WITH (FORMAT='CSV', FIRSTROW=2, FIELDTERMINATOR=',',
          ROWTERMINATOR='0x0a', CODEPAGE='65001', MAXERRORS=0);
    -- El CSV de equivalencias de jugadores usa fin de linea CRLF.
    BULK INSERT #AliasJugadores FROM '$(RutaAliasJugadores)'
    WITH (FORMAT='CSV', FIRSTROW=2, FIELDTERMINATOR=',',
          ROWTERMINATOR='0x0d0a', CODEPAGE='65001', MAXERRORS=0);
END TRY
BEGIN CATCH
    DECLARE @mensaje NVARCHAR(2048) = LEFT(N'No se pudieron leer las tablas de equivalencias. '
                                           + ERROR_MESSAGE(), 2048);
    THROW 51990, @mensaje, 1;
END CATCH;

UPDATE #FasesPartidos SET Tipo=LTRIM(RTRIM(Tipo)), Valor=LTRIM(RTRIM(Valor)),
    Fase=LTRIM(RTRIM(REPLACE(Fase,NCHAR(13),N'')));
UPDATE #EquiposPartidos SET SeleccionCsv=LTRIM(RTRIM(SeleccionCsv)), Slug=LTRIM(RTRIM(Slug)),
    Pais=LTRIM(RTRIM(REPLACE(Pais,NCHAR(13),N'')));
UPDATE #SedesPartidos SET NombreJson=LTRIM(RTRIM(NombreJson)), NombreSede=LTRIM(RTRIM(NombreSede)),
    Ciudad=LTRIM(RTRIM(Ciudad)), Pais=LTRIM(RTRIM(REPLACE(Pais,NCHAR(13),N'')));
UPDATE #AliasJugadores SET Seleccion=LTRIM(RTRIM(Seleccion)), NombreCsv=LTRIM(RTRIM(NombreCsv)),
    NombrePromiedos=LTRIM(RTRIM(NombrePromiedos)), Habilitado=LTRIM(RTRIM(Habilitado)),
    Criterio=LTRIM(RTRIM(REPLACE(Criterio,NCHAR(13),N'')));

-- Los 104 JSON originales se leen con el lector de la carga 11.
:r $(RutaLecturaJSON)

-- JSON_VALUE solo se aplica a documentos validos; los invalidos se informan aparte.
INSERT #ErroresArchivos
SELECT Archivo, N'JSON invalido.' FROM #ArchivosPartidos WHERE ISNULL(ISJSON(Contenido),0)<>1;
DELETE FROM #ArchivosPartidos WHERE ISNULL(ISJSON(Contenido),0)<>1;

-- Resolucion del partido de cada JSON: Mundial 1, fase, Eq1 y Eq2.
INSERT #PartidosJson (Archivo, GameId, Etapa, IdFase, Eq1, Eq2, IdSede)
SELECT a.Archivo,
       JSON_VALUE(a.Contenido,'$.game.id'),
       JSON_VALUE(a.Contenido,'$.game.stage_round_name'),
       r.IdFase, e1.IdSeleccion, e2.IdSeleccion, sd.IdSede
FROM #ArchivosPartidos AS a
OUTER APPLY (
    -- La fase sale de la etapa; si el JSON no la trae, de la equivalencia del partido.
    SELECT MIN(f.IdFase) AS IdFase
    FROM #FasesPartidos AS fp
    JOIN partidos.Fase AS f ON f.Descripcion = fp.Fase
    WHERE (fp.Tipo='etapa' AND fp.Valor = JSON_VALUE(a.Contenido,'$.game.stage_round_name'))
       OR (fp.Tipo='partido' AND fp.Valor = JSON_VALUE(a.Contenido,'$.game.id')
           AND NULLIF(JSON_VALUE(a.Contenido,'$.game.stage_round_name'),N'') IS NULL)
) AS r
OUTER APPLY (
    SELECT MIN(s.IdSeleccion) AS IdSeleccion
    FROM #EquiposPartidos AS eq
    JOIN equipos.Pais AS p ON p.NOMBRE = eq.Pais
    JOIN equipos.Seleccion AS s ON s.IdPais=p.IdPais AND s.IdMundial=1
    WHERE eq.Slug = JSON_VALUE(a.Contenido,'$.game.teams[0].url_name')
) AS e1
OUTER APPLY (
    SELECT MIN(s.IdSeleccion) AS IdSeleccion
    FROM #EquiposPartidos AS eq
    JOIN equipos.Pais AS p ON p.NOMBRE = eq.Pais
    JOIN equipos.Seleccion AS s ON s.IdPais=p.IdPais AND s.IdMundial=1
    WHERE eq.Slug = JSON_VALUE(a.Contenido,'$.game.teams[1].url_name')
) AS e2
OUTER APPLY (
    SELECT MIN(sd2.IdSede) AS IdSede
    FROM #SedesPartidos AS sp
    JOIN equipos.Pais AS p ON p.NOMBRE = sp.Pais
    JOIN sedes.Sede AS sd2 ON sd2.Nombre=sp.NombreSede AND sd2.Ciudad=sp.Ciudad AND sd2.IdPais=p.IdPais
    WHERE sp.NombreJson = (SELECT MIN(g.value) FROM OPENJSON(a.Contenido,'$.game.game_info')
                            WITH (name NVARCHAR(100) '$.name', value NVARCHAR(150) '$.value') AS g
                            WHERE g.name=N'Estadio')
) AS sd;

-- Depuracion de la resolucion del partido. Estas reglas se copian al staging
-- de cada importador: una fila cuyo JSON no se pudo resolver queda rechazada
-- con el motivo, y no se pierde ninguna fila del archivo.
UPDATE #PartidosJson SET Estado='Error',
    Detalle=N'El JSON no tiene identificador de partido.'
WHERE Estado='Pendiente' AND NULLIF(GameId,N'') IS NULL;

UPDATE #PartidosJson SET Estado='Error',
    Detalle=N'No se pudo determinar la fase del partido: revise equivalencias_fases_partidos.csv.'
WHERE Estado='Pendiente' AND IdFase IS NULL;

UPDATE #PartidosJson SET Estado='Error',
    Detalle=N'No se pudo determinar una seleccion para los dos equipos: revise equivalencias_equipos_jugadores.csv.'
WHERE Estado='Pendiente' AND (Eq1 IS NULL OR Eq2 IS NULL);

UPDATE #PartidosJson SET Estado='Error',
    Detalle=N'No se pudo determinar la sede del partido: revise equivalencias_sedes_partidos.csv.'
WHERE Estado='Pendiente' AND IdSede IS NULL;

UPDATE p SET Estado='Error',
    Detalle=N'El partido no esta cargado: ejecute la carga 11.'
FROM #PartidosJson AS p
WHERE p.Estado='Pendiente' AND NOT EXISTS (
    SELECT 1 FROM partidos.Partido AS m
    WHERE m.IdMundial=1 AND m.IdFase=p.IdFase AND m.Eq1=p.Eq1 AND m.Eq2=p.Eq2
);

UPDATE p SET IdPartido = m.IdPartido
FROM #PartidosJson AS p
JOIN partidos.Partido AS m
  ON m.IdMundial=1 AND m.IdFase=p.IdFase AND m.Eq1=p.Eq1 AND m.Eq2=p.Eq2
WHERE p.Estado='Pendiente';
