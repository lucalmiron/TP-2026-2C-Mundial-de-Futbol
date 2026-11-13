-- Pruebas de una tabla y luego multitabla, en una base exclusiva por corrida.
--L
:setvar ScriptPath "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Tablas"
--Santutu
--:setvar ScriptPath "C:\Users\Administrator\Desktop\tp_bdda\TP-2026-2C-Mundial-de-Futbol\Tablas"
:ON ERROR EXIT
USE master;
GO
GO
GO
USE [MUNDIALtesting];
GO
IF NOT EXISTS (SELECT name FROM sys.schemas WHERE name=N'equipos') EXECUTE('CREATE SCHEMA equipos');
GO
IF NOT EXISTS (SELECT name FROM sys.schemas WHERE name=N'sedes') EXECUTE('CREATE SCHEMA sedes');
GO
IF NOT EXISTS (SELECT name FROM sys.schemas WHERE name=N'partidos') EXECUTE('CREATE SCHEMA partidos');
GO
IF NOT EXISTS (SELECT name FROM sys.schemas WHERE name=N'arbitros') EXECUTE('CREATE SCHEMA arbitros');
GO
IF NOT EXISTS (SELECT name FROM sys.schemas WHERE name=N'publicidad') EXECUTE('CREATE SCHEMA publicidad');
GO
IF NOT EXISTS (SELECT name FROM sys.schemas WHERE name=N'SP') EXECUTE('CREATE SCHEMA SP');
GO
IF NOT EXISTS (SELECT name FROM sys.schemas WHERE name=N'SPTRANS') EXECUTE('CREATE SCHEMA SPTRANS');
GO
:r $(ScriptPath)\03_Tabla_Idioma.sql
:r $(ScriptPath)\04_Tabla_HusoHorario.sql
:r $(ScriptPath)\05_Tabla_Pais.sql
:r $(ScriptPath)\06_Tabla_Grupo.sql
:r $(ScriptPath)\07_Tabla_Club.sql
:r $(ScriptPath)\08_Tabla_Fase.sql
:r $(ScriptPath)\09_Tabla_Periodo.sql
:r $(ScriptPath)\10_Tabla_EspacioPublicitario.sql
:r $(ScriptPath)\11_Tabla_CostoFranja.sql
:r $(ScriptPath)\12_Tabla_Motivo.sql
:r $(ScriptPath)\13_Tabla_Campania.sql
:r $(ScriptPath)\14_Tabla_Mundial.sql
:r $(ScriptPath)\15_Tabla_Sede.sql
:r $(ScriptPath)\16_Tabla_Persona.sql
:r $(ScriptPath)\17_Tabla_Seleccion.sql
:r $(ScriptPath)\18_Tabla_Arbitro.sql
:r $(ScriptPath)\19_Tabla_Jugador.sql
:r $(ScriptPath)\20_Tabla_Tecnico.sql
:r $(ScriptPath)\21_Tabla_Anunciante.sql
:r $(ScriptPath)\22_Tabla_Publicidad.sql
:r $(ScriptPath)\23_Tabla_HablaIdioma.sql
:r $(ScriptPath)\24_Tabla_Partido.sql
:r $(ScriptPath)\25_Tabla_Alineacion.sql
:r $(ScriptPath)\26_Tabla_Arbitraje.sql
:r $(ScriptPath)\27_Tabla_Reporte.sql
:r $(ScriptPath)\28_Tabla_Evento.sql
:r $(ScriptPath)\29_Tabla_Amonestacion.sql
:r $(ScriptPath)\30_Tabla_Gol.sql
:r $(ScriptPath)\31_Tabla_Sustitucion.sql
:r $(ScriptPath)\32_Tabla_HistorialPublicidad.sql
:r $(ScriptPath)\33_Tabla_PublicidadPais.sql
:r $(ScriptPath)\34_Tabla_AnuncianteCampania.sql
:r $(ScriptPath)\35_Tabla_CambioConvocatoria.sql
:r $(ScriptPath)\36_Restricciones_Publicidad.sql
:r $(ScriptPath)\37_Sp_Pais.sql
:r $(ScriptPath)\38_Sp_Grupo.sql
:r $(ScriptPath)\39_Sp_Club.sql
:r $(ScriptPath)\40_Sp_Idioma.sql
:r $(ScriptPath)\41_Sp_Fase.sql
:r $(ScriptPath)\42_Sp_Periodo.sql
:r $(ScriptPath)\43_Sp_EspacioPublicitario.sql
:r $(ScriptPath)\44_Sp_CostoFranja.sql
:r $(ScriptPath)\45_Sp_Motivo.sql
:r $(ScriptPath)\46_Sp_Campania.sql
:r $(ScriptPath)\47_Sp_Mundial.sql
:r $(ScriptPath)\48_Sp_HusoHorario.sql
:r $(ScriptPath)\49_Sp_Sede.sql
:r $(ScriptPath)\50_Sp_Seleccion.sql
:r $(ScriptPath)\51_Sp_Anunciante.sql
:r $(ScriptPath)\52_Sp_Publicidad.sql
:r $(ScriptPath)\53_Sp_HablaIdioma.sql
:r $(ScriptPath)\54_Sp_Reporte.sql
:r $(ScriptPath)\55_Sp_Partido.sql
:r $(ScriptPath)\56_Sp_Alineacion.sql
:r $(ScriptPath)\57_Sp_PublicidadPais.sql
:r $(ScriptPath)\58_Sp_AnuncianteCampania.sql
:r $(ScriptPath)\59_Sp_Jugador_ClubUpdate.sql
:r $(ScriptPath)\60_Sp_HistorialPublicidad.sql
:r $(ScriptPath)\61_Sp_Trans_Jugador.sql
:r $(ScriptPath)\62_Sp_Trans_Arbitro.sql
:r $(ScriptPath)\63_Sp_Trans_Tecnico.sql
:r $(ScriptPath)\64_Sp_Trans_Arbitraje.sql
:r $(ScriptPath)\65_Sp_Amonestacion.sql
:r $(ScriptPath)\66_Sp_Gol.sql
:r $(ScriptPath)\67_Sp_Sustitucion.sql
:r $(ScriptPath)\68_Sp_Evento.sql
:r $(ScriptPath)\69_Sp_CambioConvocatoria.sql

-- Entre pruebas se vacian las tablas hijas antes que sus padres.
CREATE PROCEDURE SP.uspLimpiarDatosDePrueba AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF DB_NAME() <> N'MUNDIALtesting' OR @@TRANCOUNT <> 0
        THROW 51000, 'Se requiere la base exclusiva de la suite sin transacciones abiertas.', 1;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM equipos.CambioConvocatoria;
        DELETE FROM publicidad.AnuncianteCampania;
        DELETE FROM publicidad.PublicidadPais;
        DELETE FROM publicidad.HistorialPublicidad;
        DELETE FROM partidos.Sustitucion;
        DELETE FROM partidos.Gol;
        DELETE FROM partidos.Amonestacion;
        DELETE FROM partidos.Evento;
        DELETE FROM arbitros.Reporte;
        DELETE FROM arbitros.Arbitraje;
        DELETE FROM partidos.Alineacion;
        DELETE FROM partidos.Partido;
        DELETE FROM arbitros.HablaIdioma;
        DELETE FROM publicidad.Publicidad;
        DELETE FROM publicidad.Anunciante;
        DELETE FROM equipos.Tecnico;
        DELETE FROM equipos.Jugador;
        DELETE FROM arbitros.Arbitro;
        DELETE FROM equipos.Seleccion;
        DELETE FROM equipos.Persona;
        DELETE FROM sedes.Mundial;
        DELETE FROM publicidad.Campania;
        DELETE FROM publicidad.Motivo;
        DELETE FROM publicidad.CostoFranja;
        DELETE FROM publicidad.EspacioPublicitario;
        DELETE FROM sedes.Sede;
        DELETE FROM partidos.Periodo;
        DELETE FROM partidos.Fase;
        DELETE FROM equipos.Club;
        DELETE FROM equipos.Grupo;
        DELETE FROM equipos.Pais;
        DELETE FROM sedes.HusoHorario;
        DELETE FROM arbitros.Idioma;

        -- Reiniciar solo identidades que ya generaron valores.
        IF EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID(N'arbitros.Idioma') AND last_value IS NOT NULL)
            DBCC CHECKIDENT ('arbitros.Idioma', RESEED, 0) WITH NO_INFOMSGS;
        IF EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID(N'sedes.HusoHorario') AND last_value IS NOT NULL)
            DBCC CHECKIDENT ('sedes.HusoHorario', RESEED, 0) WITH NO_INFOMSGS;
        IF EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID(N'equipos.Pais') AND last_value IS NOT NULL)
            DBCC CHECKIDENT ('equipos.Pais', RESEED, 0) WITH NO_INFOMSGS;
        IF EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID(N'equipos.Grupo') AND last_value IS NOT NULL)
            DBCC CHECKIDENT ('equipos.Grupo', RESEED, 0) WITH NO_INFOMSGS;
        IF EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID(N'equipos.Club') AND last_value IS NOT NULL)
            DBCC CHECKIDENT ('equipos.Club', RESEED, 0) WITH NO_INFOMSGS;
        IF EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID(N'partidos.Fase') AND last_value IS NOT NULL)
            DBCC CHECKIDENT ('partidos.Fase', RESEED, 0) WITH NO_INFOMSGS;
        IF EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID(N'publicidad.EspacioPublicitario') AND last_value IS NOT NULL)
            DBCC CHECKIDENT ('publicidad.EspacioPublicitario', RESEED, 0) WITH NO_INFOMSGS;
        IF EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID(N'publicidad.CostoFranja') AND last_value IS NOT NULL)
            DBCC CHECKIDENT ('publicidad.CostoFranja', RESEED, 0) WITH NO_INFOMSGS;
        IF EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID(N'publicidad.Motivo') AND last_value IS NOT NULL)
            DBCC CHECKIDENT ('publicidad.Motivo', RESEED, 0) WITH NO_INFOMSGS;
        IF EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID(N'publicidad.Campania') AND last_value IS NOT NULL)
            DBCC CHECKIDENT ('publicidad.Campania', RESEED, 0) WITH NO_INFOMSGS;
        IF EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID(N'sedes.Mundial') AND last_value IS NOT NULL)
            DBCC CHECKIDENT ('sedes.Mundial', RESEED, 0) WITH NO_INFOMSGS;
        IF EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID(N'sedes.Sede') AND last_value IS NOT NULL)
            DBCC CHECKIDENT ('sedes.Sede', RESEED, 0) WITH NO_INFOMSGS;
        IF EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID(N'equipos.Persona') AND last_value IS NOT NULL)
            DBCC CHECKIDENT ('equipos.Persona', RESEED, 0) WITH NO_INFOMSGS;
        IF EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID(N'equipos.Seleccion') AND last_value IS NOT NULL)
            DBCC CHECKIDENT ('equipos.Seleccion', RESEED, 0) WITH NO_INFOMSGS;
        IF EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID(N'publicidad.Anunciante') AND last_value IS NOT NULL)
            DBCC CHECKIDENT ('publicidad.Anunciante', RESEED, 0) WITH NO_INFOMSGS;
        IF EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID(N'publicidad.Publicidad') AND last_value IS NOT NULL)
            DBCC CHECKIDENT ('publicidad.Publicidad', RESEED, 0) WITH NO_INFOMSGS;
        IF EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID(N'partidos.Partido') AND last_value IS NOT NULL)
            DBCC CHECKIDENT ('partidos.Partido', RESEED, 0) WITH NO_INFOMSGS;
        IF EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID(N'arbitros.Reporte') AND last_value IS NOT NULL)
            DBCC CHECKIDENT ('arbitros.Reporte', RESEED, 0) WITH NO_INFOMSGS;
        IF EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID(N'partidos.Evento') AND last_value IS NOT NULL)
            DBCC CHECKIDENT ('partidos.Evento', RESEED, 0) WITH NO_INFOMSGS;
        IF EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID(N'publicidad.HistorialPublicidad') AND last_value IS NOT NULL)
            DBCC CHECKIDENT ('publicidad.HistorialPublicidad', RESEED, 0) WITH NO_INFOMSGS;
        IF EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID(N'equipos.CambioConvocatoria') AND last_value IS NOT NULL)
            DBCC CHECKIDENT ('equipos.CambioConvocatoria', RESEED, 0) WITH NO_INFOMSGS;
        COMMIT;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        THROW;
    END CATCH;
END;
GO
PRINT 'Ejecutando 73_Test_Fase.sql';
GO
:r $(ScriptPath)\73_Test_Fase.sql
EXEC SP.uspLimpiarDatosDePrueba;
GO
PRINT 'Ejecutando 76_Test_Motivo.sql';
GO
:r $(ScriptPath)\76_Test_Motivo.sql
EXEC SP.uspLimpiarDatosDePrueba;
GO
PRINT 'Ejecutando 77_Test_Campania.sql';
GO
:r $(ScriptPath)\77_Test_Campania.sql
EXEC SP.uspLimpiarDatosDePrueba;
GO
PRINT 'Ejecutando 79_Test_Sp_HusoHorario.sql';
GO
:r $(ScriptPath)\79_Test_Sp_HusoHorario.sql
EXEC SP.uspLimpiarDatosDePrueba;
GO
PRINT 'Ejecutando 71_Test_Pais.sql';
GO
:r $(ScriptPath)\71_Test_Pais.sql
EXEC SP.uspLimpiarDatosDePrueba;
GO
PRINT 'Ejecutando 72_Test_Grupo.sql';
GO
:r $(ScriptPath)\72_Test_Grupo.sql
EXEC SP.uspLimpiarDatosDePrueba;
GO
GO
GO
EXEC SP.uspLimpiarDatosDePrueba;
GO
GO
GO
EXEC SP.uspLimpiarDatosDePrueba;
GO
GO
GO
EXEC SP.uspLimpiarDatosDePrueba;
GO
PRINT 'Ejecutando 74_Test_Sp_EspacioPublicitario.sql';
GO
:r $(ScriptPath)\74_Test_Sp_EspacioPublicitario.sql
EXEC SP.uspLimpiarDatosDePrueba;
GO
PRINT 'Ejecutando 75_Test_Sp_CostoFranja.sql';
GO
:r $(ScriptPath)\75_Test_Sp_CostoFranja.sql
EXEC SP.uspLimpiarDatosDePrueba;
GO
PRINT 'Ejecutando 78_Test_Mundial.sql';
GO
:r $(ScriptPath)\78_Test_Mundial.sql
EXEC SP.uspLimpiarDatosDePrueba;
GO
PRINT 'Ejecutando 80_Test_Sp_Sede.sql';
GO
:r $(ScriptPath)\80_Test_Sp_Sede.sql
GO
EXEC SP.uspLimpiarDatosDePrueba;
GO
PRINT 'Ejecutando 81_Test_Seleccion.sql';
GO
:r $(ScriptPath)\81_Test_Seleccion.sql
EXEC SP.uspLimpiarDatosDePrueba;
GO
PRINT 'Ejecutando 82_Test_Anunciante.sql';
GO
:r $(ScriptPath)\82_Test_Anunciante.sql
EXEC SP.uspLimpiarDatosDePrueba;
GO
PRINT 'Ejecutando 83_Test_Publicidad.sql';
GO
:r $(ScriptPath)\83_Test_Publicidad.sql
EXEC SP.uspLimpiarDatosDePrueba;
GO
GO
GO
EXEC SP.uspLimpiarDatosDePrueba;
GO
PRINT 'Ejecutando 84_Test_Partido.sql';
GO
:r $(ScriptPath)\84_Test_Partido.sql
EXEC SP.uspLimpiarDatosDePrueba;
GO
PRINT 'Ejecutando 85_Test_Alineacion.sql';
GO
:r $(ScriptPath)\85_Test_Alineacion.sql
EXEC SP.uspLimpiarDatosDePrueba;
GO
PRINT 'Ejecutando 86_Test_PublicidadPais.sql';
GO
:r $(ScriptPath)\86_Test_PublicidadPais.sql
EXEC SP.uspLimpiarDatosDePrueba;
GO
PRINT 'Ejecutando 87_Test_AnuncianteCampania.sql';
GO
:r $(ScriptPath)\87_Test_AnuncianteCampania.sql
EXEC SP.uspLimpiarDatosDePrueba;
GO
PRINT 'Ejecutando 88_Test_HistorialPublicidad.sql';
GO
:r $(ScriptPath)\88_Test_HistorialPublicidad.sql
EXEC SP.uspLimpiarDatosDePrueba;
GO
GO
GO
EXEC SP.uspLimpiarDatosDePrueba;
GO
PRINT 'Ejecutando 89_Test_Gol.sql';
GO
:r $(ScriptPath)\89_Test_Gol.sql
EXEC SP.uspLimpiarDatosDePrueba;
GO
PRINT 'Ejecutando 90_Test_Sustitucion.sql';
GO
:r $(ScriptPath)\90_Test_Sustitucion.sql
EXEC SP.uspLimpiarDatosDePrueba;
GO
PRINT 'Ejecutando 91_Test_CambioConvocatoria.sql';
GO
:r $(ScriptPath)\91_Test_CambioConvocatoria.sql
EXEC SP.uspLimpiarDatosDePrueba;
GO
PRINT 'Ejecutando 92_Test_Trans_Arbitraje.sql';
GO
:r $(ScriptPath)\92_Test_Trans_Arbitraje.sql
EXEC SP.uspLimpiarDatosDePrueba;
GO
GO
GO
EXEC SP.uspLimpiarDatosDePrueba;
GO
GO
GO
EXEC SP.uspLimpiarDatosDePrueba;
GO
GO
GO
EXEC SP.uspLimpiarDatosDePrueba;
GO
GO
GO
EXEC SP.uspLimpiarDatosDePrueba;
GO
GO
GO
EXEC SP.uspLimpiarDatosDePrueba;
GO
GO
GO
EXEC SP.uspLimpiarDatosDePrueba;
GO
GO
GO
EXEC SP.uspLimpiarDatosDePrueba;
GO
GO
GO
EXEC SP.uspLimpiarDatosDePrueba;
GO
GO
GO
EXEC SP.uspLimpiarDatosDePrueba;
GO
GO
GO
IF @@TRANCOUNT <> 0 THROW 51000, 'La ultima prueba dejo una transaccion abierta.', 1;
GO
USE master;
GO
PRINT 'Suite finalizada: se ejecutaron las pruebas.';
GO
