-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Comision 02
-- Grupo 7: Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 02/11/2026.
-- Objetivo: cargar clubes desde la columna club del CSV original de jugadores.
-- SSMS: Consulta > Modo SQLCMD. Ajustar la ruta del servidor SQL.
--L
--:setvar RutaJugadores "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Datos\Jugadores\jugadores.csv"
-- Santutu
 :setvar RutaJugadores "C:\Users\Administrator\Desktop\tp_bdda\TP-2026-2C-Mundial-de-Futbol\Datos\Jugadores\jugadores.csv"

USE MUNDIAL;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF @@TRANCOUNT<>0 OR (2 & @@OPTIONS)=2
    THROW 51500, 'Ejecute sin transaccion externa y con IMPLICIT_TRANSACTIONS OFF.', 1;
IF OBJECT_ID(N'equipos.Club',N'U') IS NULL
   OR OBJECT_ID(N'SP.uspClub_Registrar',N'P') IS NULL
    THROW 51500, 'Falta la tabla Club o su SP de alta.', 1;
IF OBJECT_ID(N'tempdb..#JugadoresCsv') IS NOT NULL DROP TABLE #JugadoresCsv;
-- Tabla temporal con el orden original de las 72 columnas del CSV.
-- Se recibe texto para no exigir conversiones numericas de campos que no usamos.
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
BEGIN TRY
    BULK INSERT #JugadoresCsv FROM '$(RutaJugadores)'
    WITH (FORMAT='CSV', FIRSTROW=2, FIELDTERMINATOR=',', ROWTERMINATOR='0x0a',
          CODEPAGE='65001', MAXERRORS=0);
END TRY
BEGIN CATCH
    DROP TABLE #JugadoresCsv;
    THROW;
END CATCH;
DECLARE @filas INT=(SELECT COUNT(*) FROM #JugadoresCsv), @sinClub INT;
UPDATE #JugadoresCsv SET club=LTRIM(RTRIM(club));
SELECT @sinClub=COUNT(*) FROM #JugadoresCsv WHERE NULLIF(club,N'') IS NULL;
DECLARE @Resultado TABLE (
    Fila INT IDENTITY(1,1) PRIMARY KEY, Nombre NVARCHAR(100),
    IdClub INT, Estado VARCHAR(20) DEFAULT 'Pendiente', Detalle NVARCHAR(2048)
);
INSERT @Resultado (Nombre)
SELECT DISTINCT club FROM #JugadoresCsv WHERE NULLIF(club,N'') IS NOT NULL;
DROP TABLE #JugadoresCsv;
IF @filas=0 THROW 51501, 'El CSV no contiene jugadores.', 1;
DECLARE @fila INT,@nombre NVARCHAR(100),@nombreSp NVARCHAR(40),@id INT,@cantidad INT,@estado VARCHAR(20);
DECLARE crsClubes CURSOR LOCAL FAST_FORWARD FOR SELECT Fila,Nombre FROM @Resultado ORDER BY Fila;
OPEN crsClubes;
FETCH NEXT FROM crsClubes INTO @fila,@nombre;
WHILE @@FETCH_STATUS=0
BEGIN
    BEGIN TRY
        IF DATALENGTH(@nombre) > 80
            THROW 51502, 'El nombre del club excede NVARCHAR(40).', 1;
            
        SET @nombreSp = @nombre;
        BEGIN TRANSACTION;
        SELECT @cantidad=COUNT(*),@id=MIN(IdClub)
        FROM equipos.Club WITH (UPDLOCK,HOLDLOCK) WHERE Nombre=@nombreSp;
        IF @cantidad>1 THROW 51502, 'Nombre de club duplicado en la base.', 1;
        IF @cantidad=0
        BEGIN
            EXEC SP.uspClub_Registrar @nombre=@nombreSp;
            SELECT @id=IdClub FROM equipos.Club WHERE Nombre=@nombreSp;
            SET @estado='Insertada';
        END
        ELSE SET @estado='SinCambios';
        COMMIT TRANSACTION;
        UPDATE @Resultado SET IdClub=@id,Estado=@estado WHERE Fila=@fila;
    END TRY
    BEGIN CATCH
        IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
        UPDATE @Resultado SET Estado='Error',Detalle=ERROR_MESSAGE() WHERE Fila=@fila;
    END CATCH;
    FETCH NEXT FROM crsClubes INTO @fila,@nombre;
END;
CLOSE crsClubes;
DEALLOCATE crsClubes;
SELECT @filas AS FilasJugadores,@sinClub AS JugadoresSinClubInformado;
SELECT Estado,COUNT(*) AS Cantidad FROM @Resultado GROUP BY Estado;
SELECT Nombre,IdClub,Estado,Detalle FROM @Resultado ORDER BY Nombre;
IF EXISTS (SELECT 1 FROM @Resultado WHERE Estado='Error')
    THROW 51503, 'Hubo clubes rechazados. Los correctos se conservaron; revise el detalle.', 1;
GO
