-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Comision 02
-- Grupo 7: Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 02/11/2026.
-- Objetivo: importar sedes.csv original.
-- Requiere las cargas 04 (husos) y 06 (paises).
-- SSMS: Consulta -> Modo SQLCMD. Ajustar ambas rutas del servidor SQL.
--L
--:setvar RutaSedes "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Datos\Sedes\sedes.csv"
--Santutu
:setvar RutaSedes "C:\Users\Administrator\Desktop\tp_bdda\TP-2026-2C-Mundial-de-Futbol\Datos\Sedes\sedes.csv"
--L
--:setvar RutaEquivalencias "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Datos\equivalencias_ubicacion_sedes.csv"
--Santutu
:setvar RutaEquivalencias "C:\Users\Administrator\Desktop\tp_bdda\TP-2026-2C-Mundial-de-Futbol\Datos\equivalencias_ubicacion_sedes.csv"

USE MUNDIAL;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF @@TRANCOUNT <> 0 OR (2 & @@OPTIONS) = 2
    THROW 51400, 'Ejecute sin transaccion externa y con IMPLICIT_TRANSACTIONS OFF.', 1;
IF OBJECT_ID(N'sedes.Sede',N'U') IS NULL
   OR OBJECT_ID(N'equipos.Pais',N'U') IS NULL
   OR OBJECT_ID(N'sedes.HusoHorario',N'U') IS NULL
   OR OBJECT_ID(N'SP.uspSede_Registrar',N'P') IS NULL
   OR OBJECT_ID(N'SP.uspSede_Update',N'P') IS NULL
    THROW 51400, 'Faltan tablas o SP ABM. Ejecute primero el instalador.', 1;

IF OBJECT_ID(N'tempdb..#SedesCsv') IS NOT NULL DROP TABLE #SedesCsv;
IF OBJECT_ID(N'tempdb..#UbicacionesCsv') IS NOT NULL DROP TABLE #UbicacionesCsv;
CREATE TABLE #SedesCsv (
    Nombre NVARCHAR(MAX) COLLATE DATABASE_DEFAULT,
    Ciudad NVARCHAR(MAX) COLLATE DATABASE_DEFAULT,
    Capacidad NVARCHAR(MAX) COLLATE DATABASE_DEFAULT,
    Pais NVARCHAR(MAX) COLLATE DATABASE_DEFAULT,
    ZonaOriginal NVARCHAR(MAX) COLLATE DATABASE_DEFAULT
);
CREATE TABLE #UbicacionesCsv (
    PaisCsv NVARCHAR(MAX) COLLATE DATABASE_DEFAULT,
    CiudadCsv NVARCHAR(MAX) COLLATE DATABASE_DEFAULT,
    PaisBd NVARCHAR(MAX) COLLATE DATABASE_DEFAULT,
    ZonaIana NVARCHAR(MAX) COLLATE DATABASE_DEFAULT
);
BEGIN TRY
    BULK INSERT #SedesCsv FROM '$(RutaSedes)'
    WITH (FORMAT='CSV', FIRSTROW=2, FIELDTERMINATOR=',',
          ROWTERMINATOR='0x0a', CODEPAGE='65001', MAXERRORS=0);
    BULK INSERT #UbicacionesCsv FROM '$(RutaEquivalencias)'
    WITH (FORMAT='CSV', FIRSTROW=2, FIELDTERMINATOR=',',
          ROWTERMINATOR='0x0a', CODEPAGE='65001', MAXERRORS=0);
END TRY
BEGIN CATCH
    DROP TABLE #SedesCsv;
    DROP TABLE #UbicacionesCsv;
    DECLARE @mensaje NVARCHAR(2048) = LEFT(N'No se pudieron leer los CSV; no se modificaron sedes. '
                                           + ERROR_MESSAGE(),2048);
    THROW 51401, @mensaje, 1;
END CATCH;
UPDATE #SedesCsv SET Nombre=LTRIM(RTRIM(Nombre)), Ciudad=LTRIM(RTRIM(Ciudad)),
    Capacidad=LTRIM(RTRIM(Capacidad)), Pais=LTRIM(RTRIM(Pais)),
    ZonaOriginal=LTRIM(RTRIM(REPLACE(ZonaOriginal,NCHAR(13),N'')));
UPDATE #UbicacionesCsv SET PaisCsv=LTRIM(RTRIM(PaisCsv)), CiudadCsv=LTRIM(RTRIM(CiudadCsv)),
    PaisBd=LTRIM(RTRIM(PaisBd)), ZonaIana=LTRIM(RTRIM(REPLACE(ZonaIana,NCHAR(13),N'')));

DECLARE @Resultado TABLE (
    Fila INT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(MAX), Ciudad NVARCHAR(MAX), CapacidadTexto NVARCHAR(MAX),
    PaisOriginal NVARCHAR(MAX), ZonaOriginal NVARCHAR(MAX),
    PaisBd NVARCHAR(MAX), ZonaIana NVARCHAR(MAX),
    Estado VARCHAR(20) NOT NULL DEFAULT 'Pendiente', Detalle NVARCHAR(2048)
);
INSERT @Resultado (Nombre,Ciudad,CapacidadTexto,PaisOriginal,ZonaOriginal)
SELECT Nombre,Ciudad,Capacidad,Pais,ZonaOriginal FROM #SedesCsv;
DROP TABLE #SedesCsv;
IF NOT EXISTS (SELECT 1 FROM @Resultado)
BEGIN
    DROP TABLE #UbicacionesCsv;
    THROW 51402, 'El CSV de sedes esta vacio.', 1;
END;
-- Si una misma sede trae valores incompatibles, rechazar todas sus versiones.
UPDATE r SET Estado='Error', Detalle=N'La misma sede tiene datos contradictorios en el CSV.'
FROM @Resultado r
WHERE EXISTS (SELECT 1 FROM @Resultado o WHERE o.Nombre=r.Nombre AND o.Ciudad=r.Ciudad
              AND (ISNULL(o.PaisOriginal,N'')<>ISNULL(r.PaisOriginal,N'')
                OR ISNULL(o.CapacidadTexto,N'')<>ISNULL(r.CapacidadTexto,N'')
                OR ISNULL(o.ZonaOriginal,N'')<>ISNULL(r.ZonaOriginal,N'')));

DECLARE @fila INT, @nombre NVARCHAR(MAX), @ciudad NVARCHAR(MAX), @capTexto NVARCHAR(MAX),
        @paisOriginal NVARCHAR(MAX), @pais NVARCHAR(MAX), @zona NVARCHAR(MAX),
        @cantidad INT, @capacidad INT, @idPais INT, @idHuso INT, @idSede INT,
        @nombreSp VARCHAR(30), @ciudadSp VARCHAR(30), @estado VARCHAR(20);
DECLARE crsSedes CURSOR LOCAL FAST_FORWARD FOR
    SELECT Fila,Nombre,Ciudad,CapacidadTexto,PaisOriginal FROM @Resultado
    WHERE Estado='Pendiente' ORDER BY Fila;
OPEN crsSedes;
FETCH NEXT FROM crsSedes INTO @fila,@nombre,@ciudad,@capTexto,@paisOriginal;
WHILE @@FETCH_STATUS=0
BEGIN
    BEGIN TRY
        SET @capacidad=TRY_CONVERT(INT,@capTexto);
        IF NULLIF(@nombre,N'') IS NULL OR NULLIF(@ciudad,N'') IS NULL
           OR NULLIF(@paisOriginal,N'') IS NULL OR @capacidad IS NULL OR @capacidad<=0
            THROW 51403, 'Nombre, ciudad o pais vacio; o capacidad entera positiva invalida.', 1;
        IF DATALENGTH(CONVERT(VARCHAR(MAX),@nombre))>30 OR DATALENGTH(CONVERT(VARCHAR(MAX),@ciudad))>30
           OR CONVERT(NVARCHAR(MAX),CONVERT(VARCHAR(MAX),@nombre)) COLLATE Latin1_General_100_BIN2
                <> @nombre COLLATE Latin1_General_100_BIN2
           OR CONVERT(NVARCHAR(MAX),CONVERT(VARCHAR(MAX),@ciudad)) COLLATE Latin1_General_100_BIN2
                <> @ciudad COLLATE Latin1_General_100_BIN2
            THROW 51403, 'Nombre o ciudad no caben fielmente en VARCHAR(30).', 1;
        IF EXISTS (SELECT 1 FROM @Resultado WHERE Fila<@fila AND Nombre=@nombre AND Ciudad=@ciudad
                   AND Estado IN ('Insertada','Actualizada','SinCambios'))
        BEGIN
            UPDATE @Resultado SET Estado='Duplicada',Detalle=N'Sede ya procesada en este CSV.' WHERE Fila=@fila;
        END
        ELSE
        BEGIN
            SELECT @cantidad=COUNT(*),@pais=MIN(PaisBd),@zona=MIN(ZonaIana)
            FROM (SELECT DISTINCT PaisBd,ZonaIana FROM #UbicacionesCsv
                  WHERE PaisCsv=@paisOriginal AND CiudadCsv=@ciudad) u;
            IF @cantidad<>1 OR NULLIF(@pais,N'') IS NULL OR NULLIF(@zona,N'') IS NULL
                THROW 51403, 'Falta una equivalencia unica y completa para el pais y la ciudad.', 1;
            UPDATE @Resultado SET PaisBd=@pais,ZonaIana=@zona WHERE Fila=@fila;
            SET @nombreSp=CONVERT(VARCHAR(30),@nombre);
            SET @ciudadSp=CONVERT(VARCHAR(30),@ciudad);
            BEGIN TRANSACTION;
            SELECT @cantidad=COUNT(*),@idPais=MIN(IdPais)
            FROM equipos.Pais WITH (HOLDLOCK) WHERE NOMBRE=@pais;
            IF @cantidad<>1 THROW 51403, 'Pais inexistente o ambiguo: revise la carga 06.', 1;
            SELECT @cantidad=COUNT(*),@idHuso=MIN(IdHuso)
            FROM sedes.HusoHorario WITH (HOLDLOCK) WHERE Nombre=@zona;
            IF @cantidad<>1 THROW 51403, 'Huso inexistente o ambiguo: revise la carga 04.', 1;
            SELECT @cantidad=COUNT(*),@idSede=MIN(IdSede)
            FROM sedes.Sede WITH (UPDLOCK,HOLDLOCK) WHERE Nombre=@nombreSp AND Ciudad=@ciudadSp;
            IF @cantidad>1 THROW 51403, 'Existen sedes duplicadas en la base.', 1;
            IF @cantidad=0
            BEGIN
                EXEC SP.uspSede_Registrar @nombre=@nombreSp,@ciudad=@ciudadSp,
                    @capacidad=@capacidad,@pais=@idPais,@huso=@idHuso;
                SET @estado='Insertada';
            END
            ELSE IF EXISTS (SELECT 1 FROM sedes.Sede WHERE IdSede=@idSede
                            AND (Capacidad<>@capacidad OR IdPais<>@idPais OR IdHuso<>@idHuso))
            BEGIN
                EXEC SP.uspSede_Update @idSede=@idSede,
                    @capacidad=@capacidad,@pais=@idPais,@huso=@idHuso;
                SET @estado='Actualizada';
            END
            ELSE SET @estado='SinCambios';
            COMMIT TRANSACTION;
            UPDATE @Resultado SET Estado=@estado WHERE Fila=@fila;
        END;
    END TRY
    BEGIN CATCH
        IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
        UPDATE @Resultado SET Estado='Error',Detalle=ERROR_MESSAGE() WHERE Fila=@fila;
    END CATCH;
    FETCH NEXT FROM crsSedes INTO @fila,@nombre,@ciudad,@capTexto,@paisOriginal;
END;
CLOSE crsSedes;
DEALLOCATE crsSedes;
DROP TABLE #UbicacionesCsv;
SELECT Estado,COUNT(*) AS Cantidad FROM @Resultado GROUP BY Estado ORDER BY Estado;
SELECT Fila,Nombre,Ciudad,CapacidadTexto AS Capacidad,PaisOriginal,ZonaOriginal,
       PaisBd,ZonaIana,Estado,Detalle FROM @Resultado ORDER BY Fila;
IF EXISTS (SELECT 1 FROM @Resultado WHERE Estado='Error')
    THROW 51404, 'Importacion parcial: se conservaron las sedes correctas. Revise el detalle.', 1;
GO
