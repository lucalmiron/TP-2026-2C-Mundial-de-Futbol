-- Modo SQLCMD. Las cuatro pruebas usan tablas distintas en una base nueva.
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
:r $(TP_BDDA)\Tablas\73_Test_Fase.sql
:r $(TP_BDDA)\Tablas\76_Test_Motivo.sql
:r $(TP_BDDA)\Tablas\77_Test_Campania.sql
:r $(TP_BDDA)\Tablas\79_Test_Sp_HusoHorario.sql
PRINT 'MUNDIALtesting queda lista para las pruebas.';
GO
PRINT 'Etapa 3 finalizada.';
GO
