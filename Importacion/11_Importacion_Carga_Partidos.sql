-- UNLaM - Bases de Datos Aplicadas - Grupo 7. Fecha: 04/11/2026.
-- Almiron, Luca;
-- Figueroa, Santiago;
-- Ruarte, Fidel;
-- Villalba, Leandro.
-- Importa los 104 JSON originales usando los SP existentes .
-- Requiere cargas 02, 04, 06, 07 y 08. Mundial = 1.
-- SSMS: Consulta > Modo SQLCMD.;
:on error exit
--L
:setvar CarpetaPartidos "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Datos\Datos_Partidos\partidos"
-- :setvar CarpetaPartidos "C:\ruta\proyecto\Datos\Datos_Partidos\partidos"
--L
:setvar RutaEquipos "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Datos\equivalencias_equipos_jugadores.csv"
-- :setvar RutaEquipos "C:\ruta\proyecto\Datos\equivalencias_equipos_jugadores.csv"
--L
:setvar RutaSedes "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Datos\equivalencias_sedes_partidos.csv"
-- :setvar RutaSedes "C:\ruta\proyecto\Datos\equivalencias_sedes_partidos.csv"
--L
:setvar RutaFases "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Datos\equivalencias_fases_partidos.csv"
-- :setvar RutaFases "C:\ruta\proyecto\Datos\equivalencias_fases_partidos.csv"
--L
:setvar RutaLectura "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Importacion\11_Lectura_JSON_Partidos.sql"
-- :setvar RutaLectura "C:\ruta\proyecto\Importacion\11_Lectura_JSON_Partidos.sql"

USE MUNDIAL;
GO
IF @@TRANCOUNT <> 0 OR (2 & @@OPTIONS) = 2
    THROW 51700,'Ejecute sin transaccion externa y con IMPLICIT_TRANSACTIONS OFF.',1;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @IdMundial INT = 1;
DECLARE @OffsetOrigen VARCHAR(6) = '-03:00';
IF TRY_CONVERT(DATETIMEOFFSET,'2026-01-01T00:00:00'+@OffsetOrigen,127) IS NULL
    THROW 51700,'Offset de origen invalido.',1;
IF OBJECT_ID(N'SP.uspPartido_Registrar',N'P') IS NULL
 OR OBJECT_ID(N'SP.uspPartido_Update',N'P') IS NULL
    THROW 51700,'Faltan los SP de partidos. Ejecute el instalador.',1;
IF NOT EXISTS (SELECT 1 FROM sedes.Mundial WHERE IdMundial=@IdMundial)
    THROW 51700,'No existe el mundial 1.',1;

IF OBJECT_ID(N'tempdb..#ArchivosPartidos') IS NOT NULL DROP TABLE #ArchivosPartidos;
IF OBJECT_ID(N'tempdb..#ErroresArchivos') IS NOT NULL DROP TABLE #ErroresArchivos;
IF OBJECT_ID(N'tempdb..#EquiposPartidos') IS NOT NULL DROP TABLE #EquiposPartidos;
IF OBJECT_ID(N'tempdb..#SedesPartidos') IS NOT NULL DROP TABLE #SedesPartidos;
IF OBJECT_ID(N'tempdb..#FasesPartidos') IS NOT NULL DROP TABLE #FasesPartidos;
CREATE TABLE #ArchivosPartidos (Archivo NVARCHAR(100),Contenido NVARCHAR(MAX));
CREATE TABLE #ErroresArchivos (Archivo NVARCHAR(100),Detalle NVARCHAR(2048));
CREATE TABLE #EquiposPartidos (SeleccionCsv NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Slug NVARCHAR(100) COLLATE DATABASE_DEFAULT,Pais NVARCHAR(100) COLLATE DATABASE_DEFAULT);
CREATE TABLE #SedesPartidos (NombreJson NVARCHAR(150) COLLATE DATABASE_DEFAULT,
    NombreSede NVARCHAR(100) COLLATE DATABASE_DEFAULT,Ciudad NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    Pais NVARCHAR(100) COLLATE DATABASE_DEFAULT);
CREATE TABLE #FasesPartidos (Tipo VARCHAR(10) COLLATE DATABASE_DEFAULT,
    Valor NVARCHAR(100) COLLATE DATABASE_DEFAULT,Fase NVARCHAR(50) COLLATE DATABASE_DEFAULT);
BULK INSERT #EquiposPartidos FROM '$(RutaEquipos)'
 WITH (FORMAT='CSV',FIRSTROW=2,FIELDTERMINATOR=',',ROWTERMINATOR='0x0a',CODEPAGE='65001',MAXERRORS=0);
BULK INSERT #SedesPartidos FROM '$(RutaSedes)'
 WITH (FORMAT='CSV',FIRSTROW=2,FIELDTERMINATOR=',',ROWTERMINATOR='0x0a',CODEPAGE='65001',MAXERRORS=0);
BULK INSERT #FasesPartidos FROM '$(RutaFases)'
 WITH (FORMAT='CSV',FIRSTROW=2,FIELDTERMINATOR=',',ROWTERMINATOR='0x0a',CODEPAGE='65001',MAXERRORS=0);
UPDATE #EquiposPartidos SET Slug=LTRIM(RTRIM(Slug)),Pais=LTRIM(RTRIM(REPLACE(Pais,NCHAR(13),N'')));
UPDATE #SedesPartidos SET NombreJson=LTRIM(RTRIM(NombreJson)),NombreSede=LTRIM(RTRIM(NombreSede)),
 Ciudad=LTRIM(RTRIM(Ciudad)),Pais=LTRIM(RTRIM(REPLACE(Pais,NCHAR(13),N'')));
UPDATE #FasesPartidos SET Tipo=LTRIM(RTRIM(Tipo)),Valor=LTRIM(RTRIM(Valor)),
 Fase=LTRIM(RTRIM(REPLACE(Fase,NCHAR(13),N'')));
IF EXISTS (SELECT Slug FROM #EquiposPartidos GROUP BY Slug HAVING COUNT(*)>1)
 OR EXISTS (SELECT NombreJson FROM #SedesPartidos GROUP BY NombreJson HAVING COUNT(*)>1)
 OR EXISTS (SELECT Tipo,Valor FROM #FasesPartidos GROUP BY Tipo,Valor HAVING COUNT(*)>1)
 OR EXISTS (SELECT 1 FROM #FasesPartidos WHERE Tipo NOT IN ('etapa','partido') OR Tipo IS NULL)
    THROW 51700,'Equivalencias duplicadas o tipo de fase invalido.',1;
:r "$(RutaLectura)"

DECLARE @Resultado TABLE (
 Fila INT IDENTITY PRIMARY KEY,Archivo NVARCHAR(100),IdFuente NVARCHAR(100),
 Equipo1 NVARCHAR(100),Equipo2 NVARCHAR(100),Etapa NVARCHAR(100),Fase NVARCHAR(50),
 SedeOrigen NVARCHAR(150),FechaOrigen NVARCHAR(30),FechaUTC DATE,HoraUTC TIME(0),HoraLocal TIME(0),
 MarcadorOrigen NVARCHAR(100),IdPartido INT,Estado VARCHAR(20) DEFAULT 'Pendiente',Detalle NVARCHAR(2048)
);
-- JSON_VALUE solo se aplica a documentos validos; los invalidos se informan aparte.
INSERT #ErroresArchivos SELECT Archivo,N'JSON invalido.' FROM #ArchivosPartidos WHERE ISNULL(ISJSON(Contenido),0)<>1;
DELETE FROM #ArchivosPartidos WHERE ISNULL(ISJSON(Contenido),0)<>1;
INSERT @Resultado (Archivo,IdFuente,Equipo1,Equipo2,Etapa,FechaOrigen,MarcadorOrigen)
SELECT Archivo,JSON_VALUE(Contenido,'$.game.id'),JSON_VALUE(Contenido,'$.game.teams[0].url_name'),
 JSON_VALUE(Contenido,'$.game.teams[1].url_name'),JSON_VALUE(Contenido,'$.game.stage_round_name'),
 JSON_VALUE(Contenido,'$.game.start_time'),JSON_QUERY(Contenido,'$.game.scores')
FROM #ArchivosPartidos;
UPDATE r SET Estado='Error',Detalle=N'ID fuente vacio, repetido o diferente del archivo.'
FROM @Resultado r WHERE NULLIF(r.IdFuente,N'') IS NULL OR r.Archivo<>r.IdFuente+N'.json'
 OR EXISTS (SELECT 1 FROM @Resultado o WHERE o.Fila<>r.Fila AND o.IdFuente=r.IdFuente);
UPDATE r SET Fase=f.Fase FROM @Resultado r JOIN #FasesPartidos f
 ON (f.Tipo='etapa' AND f.Valor=r.Etapa)
 OR (f.Tipo='partido' AND f.Valor=r.IdFuente AND NULLIF(r.Etapa,N'') IS NULL);
UPDATE r SET Estado='Error',Detalle=N'Misma fase y equipos repetidos en la fuente; revisar identidad.'
FROM @Resultado r WHERE EXISTS (SELECT 1 FROM @Resultado o WHERE o.Fila<>r.Fila
 AND o.Fase=r.Fase AND o.Equipo1=r.Equipo1 AND o.Equipo2=r.Equipo2);

DECLARE @fila INT,@archivo NVARCHAR(100),@idFuente NVARCHAR(100),@slug1 NVARCHAR(100),@slug2 NVARCHAR(100),
 @fase NVARCHAR(50),@fechaTexto NVARCHAR(30),@json NVARCHAR(MAX),@estadio NVARCHAR(150),
 @fechaOrigen DATETIME2(0),@fechaUtcCompleta DATETIMEOFFSET,@fecha DATE,@hora TIME(0),@local TIME(0),
 @idFase INT,@idSede INT,@eq1 INT,@eq2 INT,@idPartido INT,@n INT,@estado VARCHAR(20);
DECLARE crsPartidos CURSOR LOCAL FAST_FORWARD FOR
 SELECT Fila,Archivo,IdFuente,Equipo1,Equipo2,Fase,FechaOrigen FROM @Resultado WHERE Estado='Pendiente' ORDER BY Fila;
OPEN crsPartidos;
FETCH NEXT FROM crsPartidos INTO @fila,@archivo,@idFuente,@slug1,@slug2,@fase,@fechaTexto;
WHILE @@FETCH_STATUS=0
BEGIN
 BEGIN TRY
    SELECT @json=Contenido FROM #ArchivosPartidos WHERE Archivo=@archivo;
    IF JSON_VALUE(@json,'$.game.league.id') IS NULL OR JSON_VALUE(@json,'$.game.league.id')<>'fjda'
        THROW 51701,'El JSON no corresponde al torneo Mundial esperado.',1;
    IF (SELECT COUNT(*) FROM OPENJSON(@json,'$.game.teams'))<>2
       OR NULLIF(@slug1,N'') IS NULL OR NULLIF(@slug2,N'') IS NULL OR @slug1=@slug2
        THROW 51701,'Deben existir exactamente dos equipos diferentes.',1;
    SET @fechaOrigen=TRY_CONVERT(DATETIME2(0),@fechaTexto,105);
    IF @fechaOrigen IS NULL OR LEN(@fechaTexto)<>16
        THROW 51701,'Fecha/hora invalida: se espera dd-mm-aaaa hh:mm.',1;
    SET @fechaUtcCompleta=SWITCHOFFSET(TODATETIMEOFFSET(@fechaOrigen,@OffsetOrigen),'+00:00');
    SET @fecha=CONVERT(DATE,@fechaUtcCompleta); SET @hora=CONVERT(TIME(0),@fechaUtcCompleta);
    SELECT @n=COUNT(*),@estadio=MIN(Valor) FROM OPENJSON(@json,'$.game.game_info')
      WITH (Nombre NVARCHAR(100) '$.name',Valor NVARCHAR(150) '$.value') WHERE Nombre=N'Estadio';
    IF @n<>1 OR NULLIF(@estadio,N'') IS NULL THROW 51701,'Falta un estadio unico en game_info.',1;
    UPDATE @Resultado SET SedeOrigen=@estadio,FechaUTC=@fecha,HoraUTC=@hora WHERE Fila=@fila;
    BEGIN TRANSACTION;
    SELECT @n=COUNT(*),@idFase=MIN(IdFase) FROM partidos.Fase WITH (HOLDLOCK) WHERE Descripcion=@fase;
    IF @n<>1 THROW 51701,'Fase inexistente o ambigua: revise carga 02 y equivalencias.',1;
    SELECT @n=COUNT(*),@eq1=MIN(s.IdSeleccion) FROM #EquiposPartidos e
      JOIN equipos.Pais p WITH (HOLDLOCK) ON p.Nombre=e.Pais
      JOIN equipos.Seleccion s WITH (HOLDLOCK) ON s.IdPais=p.IdPais AND s.IdMundial=@IdMundial WHERE e.Slug=@slug1;
    IF @n<>1 THROW 51701,'Seleccion del primer equipo inexistente o ambigua.',1;
    SELECT @n=COUNT(*),@eq2=MIN(s.IdSeleccion) FROM #EquiposPartidos e
      JOIN equipos.Pais p WITH (HOLDLOCK) ON p.Nombre=e.Pais
      JOIN equipos.Seleccion s WITH (HOLDLOCK) ON s.IdPais=p.IdPais AND s.IdMundial=@IdMundial WHERE e.Slug=@slug2;
    IF @n<>1 THROW 51701,'Seleccion del segundo equipo inexistente o ambigua.',1;
    SELECT @n=COUNT(*),@idSede=MIN(s.IdSede) FROM #SedesPartidos e
      JOIN equipos.Pais p WITH (HOLDLOCK) ON p.Nombre=e.Pais
      JOIN sedes.Sede s WITH (HOLDLOCK) ON s.Nombre=e.NombreSede AND s.Ciudad=e.Ciudad AND s.IdPais=p.IdPais
      WHERE e.NombreJson=@estadio;
    IF @n<>1 THROW 51701,'Sede inexistente o ambigua: revise carga 08 y equivalencias.',1;
    SELECT @local=CONVERT(TIME(0),sedes.fnFechaHoraLocal(@fecha,@hora,h.Nombre))
      FROM sedes.Sede s JOIN sedes.HusoHorario h ON h.IdHuso=s.IdHuso WHERE s.IdSede=@idSede;
    IF @local IS NULL THROW 51701,'La funcion de horarios no reconoce el huso de la sede.',1;
    SELECT @n=COUNT(*),@idPartido=MIN(IdPartido) FROM partidos.Partido WITH (UPDLOCK,HOLDLOCK)
      WHERE IdMundial=@IdMundial AND IdFase=@idFase AND Eq1=@eq1 AND Eq2=@eq2;
    IF @n>1 THROW 51701,'Hay varios partidos con la misma fase y equipos; no se puede decidir cual actualizar.',1;
    IF @n=0
    BEGIN
        -- Una fase diferente podria ser una correccion o un nuevo cruce: no adivinar.
        IF EXISTS (SELECT 1 FROM partidos.Partido WITH (UPDLOCK,HOLDLOCK)
          WHERE IdMundial=@IdMundial AND Eq1=@eq1 AND Eq2=@eq2 AND Fecha=@fecha)
            THROW 51701,'Ya existe este cruce y fecha con otra fase; revisar antes de insertar.',1;
        EXEC SP.uspPartido_Registrar @IdFase=@idFase,@IdSede=@idSede,@IdMundial=@IdMundial,
          @Eq1=@eq1,@Eq2=@eq2,@Fecha=@fecha,@HoraUTC=@hora,@HoraLocal=@local,@Asistencia=NULL;
        SELECT @idPartido=IdPartido FROM partidos.Partido
          WHERE IdMundial=@IdMundial AND IdFase=@idFase AND Eq1=@eq1 AND Eq2=@eq2;
        SET @estado='Insertado';
    END
    ELSE IF EXISTS (SELECT 1 FROM partidos.Partido WHERE IdPartido=@idPartido
         AND (IdSede<>@idSede OR Fecha<>@fecha OR HoraUTC<>@hora OR HoraLocal<>@local))
    BEGIN
        EXEC SP.uspPartido_Update @Id=@idPartido,@IdSede=@idSede,
          @Fecha=@fecha,@HoraUTC=@hora,@HoraLocal=@local;
        SET @estado='Actualizado';
    END
    ELSE SET @estado='SinCambios';
    COMMIT TRANSACTION;
    UPDATE @Resultado SET IdPartido=@idPartido,HoraLocal=@local,Estado=@estado WHERE Fila=@fila;
 END TRY
 BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
    UPDATE @Resultado SET Estado='Error',Detalle=ERROR_MESSAGE() WHERE Fila=@fila;
 END CATCH;
 FETCH NEXT FROM crsPartidos INTO @fila,@archivo,@idFuente,@slug1,@slug2,@fase,@fechaTexto;
END;
CLOSE crsPartidos; DEALLOCATE crsPartidos;
SELECT Estado,COUNT(*) AS Cantidad FROM @Resultado GROUP BY Estado ORDER BY Estado;
SELECT IdFuente,IdPartido,Equipo1,Equipo2,Fase,SedeOrigen,FechaOrigen,@OffsetOrigen AS OffsetOrigenAsumido,
 FechaUTC,HoraUTC,HoraLocal,MarcadorOrigen,Estado,Detalle FROM @Resultado ORDER BY FechaUTC,HoraUTC,IdFuente;
SELECT Archivo,Detalle FROM #ErroresArchivos ORDER BY Archivo;
DECLARE @fallos INT=(SELECT COUNT(*) FROM @Resultado WHERE Estado='Error')+(SELECT COUNT(*) FROM #ErroresArchivos);
DECLARE @cantidadTotal INT=(SELECT COUNT(*) FROM @Resultado);
DROP TABLE #ArchivosPartidos; DROP TABLE #ErroresArchivos; DROP TABLE #EquiposPartidos;
DROP TABLE #SedesPartidos; DROP TABLE #FasesPartidos;
IF @cantidadTotal=0 THROW 51702,'No se pudo procesar ningun partido.',1;
IF @fallos>0 THROW 51702,'Importacion parcial: se conservaron los partidos correctos. Revise el detalle.',1;
GO
