-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Comision 02
-- Grupo 7: Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 02/11/2026.
-- Objetivo: importar jugadores mediante SP existentes, CSV original y JSON originales.
-- Fecha de nacimiento APROXIMADA autorizada para el TP: 1 de enero de birth_year.
-- Se aplica solo a altas; no reemplaza fechas de nacimiento ya registradas.
-- Nombre y club: CSV. Posicion y dorsal: Promiedos. Pais: seleccion representada.
-- Cruce por seleccion y nombre (ignora mayusculas/acentos, no adivina abreviaturas).
-- Si no hay coincidencia directa, consultar el CSV de equivalencias habilitadas.
-- Las propuestas habilitado=0 NO se aplican. No se inventan dorsales.
-- Dependencias: paises, selecciones del Mundial 1, clubes y SP de entrega 5.
-- SSMS: activar Consulta > Modo SQLCMD y ejecutar el archivo completo.
:setvar RutaJugadores "C:\ruta\proyecto\Datos\jugadores.csv"
:setvar RutaAliasJugadores "C:\ruta\proyecto\Datos\equivalencias_jugadores.csv"
:setvar RutaEquipos "C:\ruta\proyecto\Datos\equivalencias_equipos_jugadores.csv"
:setvar CarpetaPartidos "C:\ruta\proyecto\Datos\Datos_Partidos\partidos"
:setvar RutaLectura "C:\ruta\proyecto\Importacion\10_Lectura_JSON_Jugadores.sql"

USE MUNDIAL;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @idMundial INT=1;
IF @@TRANCOUNT<>0 OR (2 & @@OPTIONS)=2
    THROW 51600,'Ejecute sin transaccion externa y con IMPLICIT_TRANSACTIONS OFF.',1;
IF OBJECT_ID(N'SPTRANS.uspJugador_Registrar',N'P') IS NULL
 OR OBJECT_ID(N'SPTRANS.uspJugador_Update',N'P') IS NULL
 OR OBJECT_ID(N'SP.uspJugador_ClubUpdate',N'P') IS NULL
    THROW 51600,'Faltan SP de jugador. Ejecute el instalador.',1;
IF NOT EXISTS (SELECT 1 FROM sedes.Mundial WHERE IdMundial=@idMundial)
    THROW 51600,'No existe el Mundial 1.',1;
IF OBJECT_ID(N'tempdb..#JugadoresCsv') IS NOT NULL DROP TABLE #JugadoresCsv;
IF OBJECT_ID(N'tempdb..#EquiposCsv') IS NOT NULL DROP TABLE #EquiposCsv;
IF OBJECT_ID(N'tempdb..#ArchivosJugadores') IS NOT NULL DROP TABLE #ArchivosJugadores;
IF OBJECT_ID(N'tempdb..#ErroresArchivos') IS NOT NULL DROP TABLE #ErroresArchivos;
CREATE TABLE #JugadoresCsv (
    [player] NVARCHAR(100) COLLATE DATABASE_DEFAULT NULL,
    [team] NVARCHAR(60) COLLATE DATABASE_DEFAULT NULL,
    [team_country] NVARCHAR(60) COLLATE DATABASE_DEFAULT NULL,
    [position] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [age] NVARCHAR(10) COLLATE DATABASE_DEFAULT NULL,
    [birth_year] NVARCHAR(10) COLLATE DATABASE_DEFAULT NULL,
    [club] NVARCHAR(100) COLLATE DATABASE_DEFAULT NULL,
    [games] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [games_starts] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [minutes] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [minutes_90s] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [goals] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [assists] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [goals_assists] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [goals_pens] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [pens_made] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [pens_att] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [cards_yellow] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [cards_red] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [goals_per90] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [assists_per90] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [goals_assists_per90] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [goals_pens_per90] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [goals_assists_pens_per90] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [shots] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [shots_on_target] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [shots_on_target_pct] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [shots_per90] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [shots_on_target_per90] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [goals_per_shot] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [goals_per_shot_on_target] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [minutes_per_game] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [minutes_pct] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [minutes_per_start] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [games_complete] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [games_subs] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [minutes_per_sub] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [unused_subs] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [points_per_game] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [on_goals_for] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [on_goals_against] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [plus_minus] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [plus_minus_per90] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [plus_minus_wowy] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [cards_yellow_red] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [fouls] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [fouled] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [offsides] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [crosses] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [interceptions] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [tackles_won] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [pens_won] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [pens_conceded] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [own_goals] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [gk_games] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [gk_games_starts] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [gk_minutes] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [gk_goals_against] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [gk_goals_against_per90] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [gk_shots_on_target_against] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [gk_saves] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [gk_save_pct] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [gk_wins] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [gk_ties] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [gk_losses] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [gk_clean_sheets] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [gk_clean_sheets_pct] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [gk_pens_att] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [gk_pens_allowed] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [gk_pens_saved] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [gk_pens_missed] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
    [gk_pens_save_pct] NVARCHAR(20) COLLATE DATABASE_DEFAULT NULL
);
IF OBJECT_ID(N'tempdb..#AliasJugadores') IS NOT NULL DROP TABLE #AliasJugadores;
CREATE TABLE #AliasJugadores (
    Seleccion NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    NombreCsv NVARCHAR(200) COLLATE Latin1_General_100_CI_AI,
    NombrePromiedos NVARCHAR(200) COLLATE Latin1_General_100_CI_AI,
    Habilitado VARCHAR(10), Criterio NVARCHAR(500)
);
CREATE TABLE #EquiposCsv (
    SeleccionCsv NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Slug NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Pais NVARCHAR(100) COLLATE DATABASE_DEFAULT
);
CREATE TABLE #ArchivosJugadores (Archivo NVARCHAR(100),Contenido NVARCHAR(MAX));
CREATE TABLE #ErroresArchivos (Archivo NVARCHAR(100),Detalle NVARCHAR(2048));
BEGIN TRY
    BULK INSERT #JugadoresCsv FROM '$(RutaJugadores)'
    WITH (FORMAT='CSV',FIRSTROW=2,FIELDTERMINATOR=',',ROWTERMINATOR='0x0a',CODEPAGE='65001',MAXERRORS=0);
    BULK INSERT #AliasJugadores FROM '$(RutaAliasJugadores)'
    WITH (FORMAT='CSV',FIRSTROW=2,FIELDTERMINATOR=',',ROWTERMINATOR='0x0a',CODEPAGE='65001',MAXERRORS=0);
    BULK INSERT #EquiposCsv FROM '$(RutaEquipos)'
    WITH (FORMAT='CSV',FIRSTROW=2,FIELDTERMINATOR=',',ROWTERMINATOR='0x0a',CODEPAGE='65001',MAXERRORS=0);
END TRY
BEGIN CATCH
    THROW;
END CATCH;
UPDATE #EquiposCsv SET SeleccionCsv=LTRIM(RTRIM(SeleccionCsv)),Slug=LTRIM(RTRIM(Slug)),
    Pais=LTRIM(RTRIM(REPLACE(Pais,NCHAR(13),N'')));
IF EXISTS (SELECT SeleccionCsv FROM #EquiposCsv GROUP BY SeleccionCsv HAVING COUNT(*)>1)
 OR EXISTS (SELECT Slug FROM #EquiposCsv GROUP BY Slug HAVING COUNT(*)>1)
 OR EXISTS (SELECT 1 FROM #EquiposCsv WHERE NULLIF(SeleccionCsv,N'') IS NULL
             OR NULLIF(Slug,N'') IS NULL OR NULLIF(Pais,N'') IS NULL)
    THROW 51600,'Equivalencias de equipos vacias o duplicadas.',1;

UPDATE #AliasJugadores SET Seleccion=LTRIM(RTRIM(Seleccion)),NombreCsv=LTRIM(RTRIM(NombreCsv)),
    NombrePromiedos=LTRIM(RTRIM(NombrePromiedos)),Habilitado=LTRIM(RTRIM(Habilitado)),
    Criterio=LTRIM(RTRIM(REPLACE(Criterio,NCHAR(13),N'')));
IF EXISTS (SELECT 1 FROM #AliasJugadores WHERE Habilitado IS NULL OR Habilitado NOT IN ('0','1'))
 OR EXISTS (SELECT 1 FROM #AliasJugadores WHERE Habilitado='1' AND
           (NULLIF(Seleccion,N'') IS NULL OR NULLIF(NombreCsv,N'') IS NULL OR NULLIF(NombrePromiedos,N'') IS NULL))
 OR EXISTS (SELECT Seleccion,NombreCsv FROM #AliasJugadores WHERE Habilitado='1'
            GROUP BY Seleccion,NombreCsv HAVING COUNT(*)>1)
 OR EXISTS (SELECT Seleccion,NombrePromiedos FROM #AliasJugadores WHERE Habilitado='1'
            GROUP BY Seleccion,NombrePromiedos HAVING COUNT(*)>1)
    THROW 51600,'Equivalencias de jugadores invalidas o ambiguas. Revisar habilitado y nombres duplicados.',1;
-- Un nombre de Promiedos no puede adjudicarse a otro jugador que ya coincide directamente.
IF EXISTS (
    SELECT 1 FROM #AliasJugadores a JOIN #JugadoresCsv c ON c.team=a.Seleccion
    WHERE a.Habilitado='1' AND c.player COLLATE Latin1_General_100_CI_AI=a.NombrePromiedos
      AND c.player COLLATE Latin1_General_100_CI_AI<>a.NombreCsv
)
    THROW 51600,'Una equivalencia apunta al nombre de otro jugador del CSV. Revisar identidad.',1;

-- Lecturas estaticas. Para incorporar archivos nuevos, agregar bloques al auxiliar.
:r "$(RutaLectura)"

DECLARE @Dorsales TABLE (Slug NVARCHAR(100),Nombre NVARCHAR(200),Numero INT,Posicion NVARCHAR(100));
DECLARE @archivo NVARCHAR(100),@json NVARCHAR(MAX);
DECLARE crsArchivos CURSOR LOCAL FAST_FORWARD FOR SELECT Archivo,Contenido FROM #ArchivosJugadores;
OPEN crsArchivos;
FETCH NEXT FROM crsArchivos INTO @archivo,@json;
WHILE @@FETCH_STATUS=0
BEGIN
    BEGIN TRY
        IF LEFT(@json,1)=NCHAR(65279) SET @json=SUBSTRING(@json,2,LEN(@json));
        IF ISNULL(ISJSON(@json),0)<>1 THROW 51601,'JSON invalido.',1;
        IF JSON_QUERY(@json,'$.game.players.lineups.teams') IS NULL
            THROW 51601,'JSON sin alineaciones de jugadores.',1;
        INSERT @Dorsales
        SELECT t.Slug,LTRIM(RTRIM(p.Nombre)),p.Numero,LTRIM(RTRIM(p.Posicion))
        FROM OPENJSON(@json,'$.game.players.lineups.teams')
        WITH (Equipo INT '$.team_num',Titulares NVARCHAR(MAX) '$.starting' AS JSON,
              Suplentes NVARCHAR(MAX) '$.bench' AS JSON) l
        JOIN (
            SELECT CONVERT(INT,j.[key])+1 AS Equipo,JSON_VALUE(j.value,'$.url_name') AS Slug
            FROM OPENJSON(@json,'$.game.teams') j
        ) t ON t.Equipo=l.Equipo
        CROSS APPLY (SELECT l.Titulares AS Plantel UNION ALL SELECT l.Suplentes) a
        CROSS APPLY OPENJSON(a.Plantel)
        WITH (Nombre NVARCHAR(200) '$.name',Numero INT '$.jersey_num',Posicion NVARCHAR(100) '$.position') p;
    END TRY
    BEGIN CATCH
        INSERT #ErroresArchivos VALUES (@archivo,ERROR_MESSAGE());
    END CATCH;
    FETCH NEXT FROM crsArchivos INTO @archivo,@json;
END;
CLOSE crsArchivos;
DEALLOCATE crsArchivos;
DECLARE @Resultado TABLE (
    Fila INT IDENTITY PRIMARY KEY,Nombre NVARCHAR(100),Equipo NVARCHAR(60),Anio NVARCHAR(10),Club NVARCHAR(100),
    NombrePromiedos NVARCHAR(200),TipoCruce VARCHAR(20),
    Estado VARCHAR(20) DEFAULT 'Pendiente',Detalle NVARCHAR(2048)
);
INSERT @Resultado (Nombre,Equipo,Anio,Club)
SELECT LTRIM(RTRIM(player)),LTRIM(RTRIM(team)),LTRIM(RTRIM(birth_year)),NULLIF(LTRIM(RTRIM(club)),N'')
FROM #JugadoresCsv;
DROP TABLE #JugadoresCsv;
IF NOT EXISTS (SELECT 1 FROM @Resultado) THROW 51600,'CSV de jugadores vacio.',1;
UPDATE r SET Estado='Error',Detalle=N'Nombre repetido en la misma seleccion del CSV; revisar identidad.'
FROM @Resultado r WHERE EXISTS (SELECT 1 FROM @Resultado o WHERE o.Fila<>r.Fila AND o.Equipo=r.Equipo
 AND o.Nombre COLLATE Latin1_General_100_CI_AI=r.Nombre COLLATE Latin1_General_100_CI_AI);
DECLARE @fila INT,@nombre NVARCHAR(100),@equipo NVARCHAR(60),@anioTxt NVARCHAR(10),@club NVARCHAR(100),
 @anio INT,@fnac DATE,@slug NVARCHAR(100),@pais NVARCHAR(100),@numero INT,@pos NVARCHAR(100),
 @idPais INT,@idSeleccion INT,@idClub INT,@idJugador INT,@cantidad INT,@estado VARCHAR(20),
 @nombreSp VARCHAR(30),@posSp VARCHAR(20),@nombreJson NVARCHAR(200),@tipoCruce VARCHAR(20);
DECLARE crsJugadores CURSOR LOCAL FAST_FORWARD FOR
 SELECT Fila,Nombre,Equipo,Anio,Club FROM @Resultado WHERE Estado='Pendiente' ORDER BY Fila;
OPEN crsJugadores;
FETCH NEXT FROM crsJugadores INTO @fila,@nombre,@equipo,@anioTxt,@club;
WHILE @@FETCH_STATUS=0
BEGIN
 BEGIN TRY
    SET @anio=TRY_CONVERT(INT,@anioTxt);
    IF NULLIF(@nombre,N'') IS NULL OR @anio IS NULL OR @anio<1900 OR @anio>YEAR(GETDATE())
        THROW 51602,'Nombre vacio o anio de nacimiento invalido.',1;
    SET @fnac=DATEFROMPARTS(@anio,1,1);
    SELECT @cantidad=COUNT(*),@slug=MIN(Slug),@pais=MIN(Pais) FROM #EquiposCsv WHERE SeleccionCsv=@equipo;
    IF @cantidad<>1 THROW 51602,'No existe equivalencia unica para la seleccion del CSV.',1;
    SET @nombreJson=@nombre;
    SET @tipoCruce='Directo';
    IF NOT EXISTS (SELECT 1 FROM @Dorsales WHERE Slug=@slug
                   AND Nombre COLLATE Latin1_General_100_CI_AI=@nombre COLLATE Latin1_General_100_CI_AI)
    BEGIN
        SELECT @cantidad=COUNT(*),@nombreJson=MIN(NombrePromiedos)
        FROM #AliasJugadores WHERE Habilitado='1' AND Seleccion=@equipo
          AND NombreCsv=@nombre COLLATE Latin1_General_100_CI_AI;
        IF @cantidad<>1
            THROW 51602,'Sin coincidencia directa ni equivalencia habilitada. Revisar equivalencias_jugadores.csv.',1;
        SET @tipoCruce='Equivalencia';
    END;
    UPDATE @Resultado SET NombrePromiedos=@nombreJson,TipoCruce=@tipoCruce WHERE Fila=@fila;
    SELECT @cantidad=COUNT(*),@numero=MIN(Numero),@pos=MIN(Posicion)
    FROM (SELECT DISTINCT Numero,Posicion FROM @Dorsales WHERE Slug=@slug
          AND Nombre COLLATE Latin1_General_100_CI_AI=@nombreJson COLLATE Latin1_General_100_CI_AI) d;
    IF @cantidad<>1 OR @numero IS NULL OR @numero<=0 OR NULLIF(@pos,N'') IS NULL
        THROW 51602,'Sin dorsal y posicion unicos en Promiedos para el nombre resuelto.',1;
    IF EXISTS (SELECT 1 FROM @Dorsales WHERE Slug=@slug AND Numero=@numero
               AND Nombre COLLATE Latin1_General_100_CI_AI<>@nombreJson COLLATE Latin1_General_100_CI_AI)
        THROW 51602,'El dorsal aparece asociado a otro nombre en Promiedos. Revisar identidad.',1;
    IF DATALENGTH(CONVERT(VARCHAR(400),@nombre))>30 OR DATALENGTH(CONVERT(VARCHAR(400),@pos))>20
       OR CONVERT(NVARCHAR(100),CONVERT(VARCHAR(400),@nombre)) COLLATE Latin1_General_100_BIN2
          <>@nombre COLLATE Latin1_General_100_BIN2
       OR CONVERT(NVARCHAR(100),CONVERT(VARCHAR(400),@pos)) COLLATE Latin1_General_100_BIN2
          <>@pos COLLATE Latin1_General_100_BIN2
        THROW 51602,'Nombre o posicion no se pueden guardar fielmente en los VARCHAR actuales.',1;
    SET @nombreSp=CONVERT(VARCHAR(30),@nombre);SET @posSp=CONVERT(VARCHAR(20),@pos);
    BEGIN TRANSACTION;
    SELECT @cantidad=COUNT(*),@idPais=MIN(IdPais) FROM equipos.Pais WITH (HOLDLOCK) WHERE NOMBRE=@pais;
    IF @cantidad<>1 THROW 51602,'Pais no cargado o ambiguo.',1;
    SELECT @cantidad=COUNT(*),@idSeleccion=MIN(IdSeleccion) FROM equipos.Seleccion WITH (UPDLOCK,HOLDLOCK)
    WHERE IdPais=@idPais AND IdMundial=@idMundial;
    IF @cantidad<>1 THROW 51602,'Seleccion no cargada para Mundial 1.',1;
    SET @idClub=NULL;
    IF @club IS NOT NULL
    BEGIN
        SELECT @cantidad=COUNT(*),@idClub=MIN(IdClub) FROM equipos.Club WITH (HOLDLOCK) WHERE Nombre=@club;
        IF @cantidad<>1 THROW 51602,'Club informado no cargado. Revisar errores del importador 09.',1;
    END;
    SELECT @cantidad=COUNT(*),@idJugador=MIN(j.IdJugador)
    FROM equipos.Jugador j WITH (UPDLOCK,HOLDLOCK) JOIN equipos.Persona p ON p.IdPersona=j.IdJugador
    WHERE j.Seleccion=@idSeleccion AND p.Nombre=@nombreSp;
    IF @cantidad>1 THROW 51602,'Identidad ambigua: varios jugadores con ese nombre en la seleccion.',1;
    IF @cantidad=0
    BEGIN
        EXEC SPTRANS.uspJugador_Registrar @nombre=@nombreSp,@fnac=@fnac,@pais=@idPais,
          @posicion=@posSp,@numero=@numero,@club=@idClub,@seleccion=@idSeleccion,@estado='Activo';
        SET @estado='Insertada';
    END
    ELSE
    BEGIN
        SET @estado='SinCambios';
        IF EXISTS (SELECT 1 FROM equipos.Jugador WHERE IdJugador=@idJugador
                   AND (Posicion<>@posSp OR Numero<>@numero))
        BEGIN
            EXEC SPTRANS.uspJugador_Update @id=@idJugador,@posicion=@posSp,@numero=@numero;
            SET @estado='Actualizada';
        END;
        IF @idClub IS NOT NULL AND EXISTS (SELECT 1 FROM equipos.Jugador WHERE IdJugador=@idJugador
                                           AND (Club IS NULL OR Club<>@idClub))
        BEGIN
            EXEC SP.uspJugador_ClubUpdate @id=@idJugador,@club=@idClub;
            SET @estado='Actualizada';
        END;
    END;
    COMMIT TRANSACTION;
    UPDATE @Resultado SET Estado=@estado WHERE Fila=@fila;
 END TRY
 BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
    UPDATE @Resultado SET Estado='Error',Detalle=ERROR_MESSAGE() WHERE Fila=@fila;
 END CATCH;
 FETCH NEXT FROM crsJugadores INTO @fila,@nombre,@equipo,@anioTxt,@club;
END;
CLOSE crsJugadores;
DEALLOCATE crsJugadores;
SELECT Estado,COUNT(*) AS Cantidad FROM @Resultado GROUP BY Estado;
SELECT Fila,Nombre,Equipo,NombrePromiedos,TipoCruce,Anio AS AnioNacimiento,Club,Estado,Detalle FROM @Resultado ORDER BY Equipo,Nombre;
SELECT Archivo,Detalle FROM #ErroresArchivos;
DECLARE @hayErrores BIT=CASE WHEN EXISTS (SELECT 1 FROM @Resultado WHERE Estado='Error')
 OR EXISTS (SELECT 1 FROM #ErroresArchivos) THEN 1 ELSE 0 END;
DROP TABLE #AliasJugadores;DROP TABLE #EquiposCsv;DROP TABLE #ArchivosJugadores;DROP TABLE #ErroresArchivos;
IF @hayErrores=1 THROW 51603,'Importacion parcial: se conservaron los jugadores validos. Revise el detalle.',1;
GO
