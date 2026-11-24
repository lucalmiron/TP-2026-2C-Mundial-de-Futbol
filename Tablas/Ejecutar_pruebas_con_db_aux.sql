-- Pruebas de una tabla y luego multitabla, en una base exclusiva por corrida.
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
:r $(TP_BDDA)\Tablas\03_Tabla_Idioma.sql
:r $(TP_BDDA)\Tablas\04_Tabla_HusoHorario.sql
:r $(TP_BDDA)\Tablas\05_Tabla_Pais.sql
:r $(TP_BDDA)\Tablas\06_Tabla_Grupo.sql
:r $(TP_BDDA)\Tablas\07_Tabla_Club.sql
:r $(TP_BDDA)\Tablas\08_Tabla_Fase.sql
:r $(TP_BDDA)\Tablas\09_Tabla_Periodo.sql
:r $(TP_BDDA)\Tablas\10_Tabla_EspacioPublicitario.sql
:r $(TP_BDDA)\Tablas\11_Tabla_CostoFranja.sql
:r $(TP_BDDA)\Tablas\12_Tabla_Motivo.sql
:r $(TP_BDDA)\Tablas\13_Tabla_Campania.sql
:r $(TP_BDDA)\Tablas\14_Tabla_Mundial.sql
:r $(TP_BDDA)\Tablas\15_Tabla_Sede.sql
:r $(TP_BDDA)\Tablas\16_Tabla_Persona.sql
:r $(TP_BDDA)\Tablas\17_Tabla_Seleccion.sql
:r $(TP_BDDA)\Tablas\18_Tabla_Arbitro.sql
:r $(TP_BDDA)\Tablas\19_Tabla_Jugador.sql
:r $(TP_BDDA)\Tablas\20_Tabla_Tecnico.sql
:r $(TP_BDDA)\Tablas\21_Tabla_Anunciante.sql
:r $(TP_BDDA)\Tablas\22_Tabla_Publicidad.sql
:r $(TP_BDDA)\Tablas\23_Tabla_HablaIdioma.sql
:r $(TP_BDDA)\Tablas\24_Tabla_Partido.sql
:r $(TP_BDDA)\Tablas\25_Tabla_Alineacion.sql
:r $(TP_BDDA)\Tablas\26_Tabla_Arbitraje.sql
:r $(TP_BDDA)\Tablas\27_Tabla_Reporte.sql
:r $(TP_BDDA)\Tablas\28_Tabla_Evento.sql
:r $(TP_BDDA)\Tablas\29_Tabla_Amonestacion.sql
:r $(TP_BDDA)\Tablas\30_Tabla_Gol.sql
:r $(TP_BDDA)\Tablas\31_Tabla_Sustitucion.sql
:r $(TP_BDDA)\Tablas\32_Tabla_HistorialPublicidad.sql
:r $(TP_BDDA)\Tablas\33_Tabla_PublicidadPais.sql
:r $(TP_BDDA)\Tablas\34_Tabla_AnuncianteCampania.sql
:r $(TP_BDDA)\Tablas\35_Tabla_CambioConvocatoria.sql
:r $(TP_BDDA)\Tablas\36_Restricciones_Publicidad.sql
:r $(TP_BDDA)\Tablas\37_Sp_Pais.sql
:r $(TP_BDDA)\Tablas\38_Sp_Grupo.sql
:r $(TP_BDDA)\Tablas\39_Sp_Club.sql
:r $(TP_BDDA)\Tablas\40_Sp_Idioma.sql
:r $(TP_BDDA)\Tablas\41_Sp_Fase.sql
:r $(TP_BDDA)\Tablas\42_Sp_Periodo.sql
:r $(TP_BDDA)\Tablas\43_Sp_EspacioPublicitario.sql
:r $(TP_BDDA)\Tablas\44_Sp_CostoFranja.sql
:r $(TP_BDDA)\Tablas\45_Sp_Motivo.sql
:r $(TP_BDDA)\Tablas\46_Sp_Campania.sql
:r $(TP_BDDA)\Tablas\47_Sp_Mundial.sql
:r $(TP_BDDA)\Tablas\48_Sp_HusoHorario.sql
:r $(TP_BDDA)\Tablas\49_Sp_Sede.sql
:r $(TP_BDDA)\Tablas\50_Sp_Seleccion.sql
:r $(TP_BDDA)\Tablas\51_Sp_Anunciante.sql
:r $(TP_BDDA)\Tablas\52_Sp_Publicidad.sql
:r $(TP_BDDA)\Tablas\53_Sp_HablaIdioma.sql
:r $(TP_BDDA)\Tablas\54_Sp_Reporte.sql
:r $(TP_BDDA)\Tablas\55_Sp_Partido.sql
:r $(TP_BDDA)\Tablas\56_Sp_Alineacion.sql
:r $(TP_BDDA)\Tablas\57_Sp_PublicidadPais.sql
:r $(TP_BDDA)\Tablas\58_Sp_AnuncianteCampania.sql
:r $(TP_BDDA)\Tablas\59_Sp_Jugador_ClubUpdate.sql
:r $(TP_BDDA)\Tablas\60_Sp_HistorialPublicidad.sql
:r $(TP_BDDA)\Tablas\61_Sp_Trans_Jugador.sql
:r $(TP_BDDA)\Tablas\62_Sp_Trans_Arbitro.sql
:r $(TP_BDDA)\Tablas\63_Sp_Trans_Tecnico.sql
:r $(TP_BDDA)\Tablas\64_Sp_Trans_Arbitraje.sql
:r $(TP_BDDA)\Tablas\65_Sp_Amonestacion.sql
:r $(TP_BDDA)\Tablas\66_Sp_Gol.sql
:r $(TP_BDDA)\Tablas\67_Sp_Sustitucion.sql
:r $(TP_BDDA)\Tablas\68_Sp_Evento.sql
:r $(TP_BDDA)\Tablas\69_Sp_CambioConvocatoria.sql

-- Entre pruebas se vacian las tablas hijas antes que sus padres.
IF OBJECT_ID('SP.uspLimpiarDatosDePrueba', 'P') IS NOT NULL
    DROP PROCEDURE SP.uspLimpiarDatosDePrueba;
GO
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
:r $(TP_BDDA)\Tablas\73_Test_Fase.sql
EXEC SP.uspLimpiarDatosDePrueba;
GO
PRINT 'Ejecutando 76_Test_Motivo.sql';
GO
:r $(TP_BDDA)\Tablas\76_Test_Motivo.sql
EXEC SP.uspLimpiarDatosDePrueba;
GO
PRINT 'Ejecutando 77_Test_Campania.sql';
GO
:r $(TP_BDDA)\Tablas\77_Test_Campania.sql
EXEC SP.uspLimpiarDatosDePrueba;
GO
PRINT 'Ejecutando 79_Test_Sp_HusoHorario.sql';
GO
:r $(TP_BDDA)\Tablas\79_Test_Sp_HusoHorario.sql
EXEC SP.uspLimpiarDatosDePrueba;
GO
PRINT 'Ejecutando 71_Test_Pais.sql';
GO
:r $(TP_BDDA)\Tablas\71_Test_Pais.sql
EXEC SP.uspLimpiarDatosDePrueba;
GO
PRINT 'Ejecutando 72_Test_Grupo.sql';
GO
:r $(TP_BDDA)\Tablas\72_Test_Grupo.sql
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
:r $(TP_BDDA)\Tablas\74_Test_Sp_EspacioPublicitario.sql
EXEC SP.uspLimpiarDatosDePrueba;
GO
PRINT 'Ejecutando 75_Test_Sp_CostoFranja.sql';
GO
:r $(TP_BDDA)\Tablas\75_Test_Sp_CostoFranja.sql
EXEC SP.uspLimpiarDatosDePrueba;
GO
PRINT 'Ejecutando 78_Test_Mundial.sql';
GO
:r $(TP_BDDA)\Tablas\78_Test_Mundial.sql
EXEC SP.uspLimpiarDatosDePrueba;
GO
PRINT 'Ejecutando 80_Test_Sp_Sede.sql';
GO
:r $(TP_BDDA)\Tablas\80_Test_Sp_Sede.sql
GO
EXEC SP.uspLimpiarDatosDePrueba;
GO
PRINT 'Ejecutando 81_Test_Seleccion.sql';
GO
:r $(TP_BDDA)\Tablas\81_Test_Seleccion.sql
EXEC SP.uspLimpiarDatosDePrueba;
GO
PRINT 'Ejecutando 82_Test_Anunciante.sql';
GO
:r $(TP_BDDA)\Tablas\82_Test_Anunciante.sql
EXEC SP.uspLimpiarDatosDePrueba;
GO
PRINT 'Ejecutando 83_Test_Publicidad.sql';
GO
:r $(TP_BDDA)\Tablas\83_Test_Publicidad.sql
EXEC SP.uspLimpiarDatosDePrueba;
GO
GO
GO
EXEC SP.uspLimpiarDatosDePrueba;
GO
PRINT 'Ejecutando 84_Test_Partido.sql';
GO
:r $(TP_BDDA)\Tablas\84_Test_Partido.sql
EXEC SP.uspLimpiarDatosDePrueba;
GO
PRINT 'Ejecutando 85_Test_Alineacion.sql';
GO
:r $(TP_BDDA)\Tablas\85_Test_Alineacion.sql
EXEC SP.uspLimpiarDatosDePrueba;
GO
PRINT 'Ejecutando 86_Test_PublicidadPais.sql';
GO
:r $(TP_BDDA)\Tablas\86_Test_PublicidadPais.sql
EXEC SP.uspLimpiarDatosDePrueba;
GO
PRINT 'Ejecutando 87_Test_AnuncianteCampania.sql';
GO
:r $(TP_BDDA)\Tablas\87_Test_AnuncianteCampania.sql
EXEC SP.uspLimpiarDatosDePrueba;
GO
PRINT 'Ejecutando 88_Test_HistorialPublicidad.sql';
GO
:r $(TP_BDDA)\Tablas\88_Test_HistorialPublicidad.sql
EXEC SP.uspLimpiarDatosDePrueba;
GO
GO
GO
EXEC SP.uspLimpiarDatosDePrueba;
GO
PRINT 'Ejecutando 89_Test_Gol.sql';
GO
:r $(TP_BDDA)\Tablas\89_Test_Gol.sql
EXEC SP.uspLimpiarDatosDePrueba;
GO
PRINT 'Ejecutando 90_Test_Sustitucion.sql';
GO
:r $(TP_BDDA)\Tablas\90_Test_Sustitucion.sql
EXEC SP.uspLimpiarDatosDePrueba;
GO
PRINT 'Ejecutando 91_Test_CambioConvocatoria.sql';
GO
:r $(TP_BDDA)\Tablas\91_Test_CambioConvocatoria.sql
EXEC SP.uspLimpiarDatosDePrueba;
GO
PRINT 'Ejecutando 92_Test_Trans_Arbitraje.sql';
GO
:r $(TP_BDDA)\Tablas\92_Test_Trans_Arbitraje.sql
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
