-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Grupo 7
-- Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 26/10/26.
-- Objetivo: instalar la base, tablas y procedimientos de la entrega 5.
-- Orden: 01-02 bases y esquemas; 03-36 tablas y restricciones; 37-69 SP;
-- 70-96 entregas 6/7; 97-100 seguridad y cifrado.
-- En SSMS, activar modo SQLCMD. TP_BDDA se define en los archivos 00_Importar_Todo_Parte*.sql.
-- Mantener las comillas si la ruta contiene espacios.

--L
:setvar TP_BDDA "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol"

:ON ERROR EXIT

:r $(TP_BDDA)\Tablas\01_Base_Mundial.sql
GO
:r $(TP_BDDA)\Tablas\02_Base_MundialTesting.sql
GO
USE MUNDIAL;
GO
:r $(TP_BDDA)\Tablas\03_Tabla_Idioma.sql
GO
:r $(TP_BDDA)\Tablas\04_Tabla_HusoHorario.sql
GO
:r $(TP_BDDA)\Tablas\05_Tabla_Pais.sql
GO
:r $(TP_BDDA)\Tablas\06_Tabla_Grupo.sql
GO
:r $(TP_BDDA)\Tablas\07_Tabla_Club.sql
GO
:r $(TP_BDDA)\Tablas\08_Tabla_Fase.sql
GO
:r $(TP_BDDA)\Tablas\09_Tabla_Periodo.sql
GO
:r $(TP_BDDA)\Tablas\10_Tabla_EspacioPublicitario.sql
GO
:r $(TP_BDDA)\Tablas\11_Tabla_CostoFranja.sql
GO
:r $(TP_BDDA)\Tablas\12_Tabla_Motivo.sql
GO
:r $(TP_BDDA)\Tablas\13_Tabla_Campania.sql
GO
:r $(TP_BDDA)\Tablas\14_Tabla_Mundial.sql
GO
:r $(TP_BDDA)\Tablas\15_Tabla_Sede.sql
GO
:r $(TP_BDDA)\Tablas\16_Tabla_Persona.sql
GO
:r $(TP_BDDA)\Tablas\17_Tabla_Seleccion.sql
GO
:r $(TP_BDDA)\Tablas\18_Tabla_Arbitro.sql
GO
:r $(TP_BDDA)\Tablas\19_Tabla_Jugador.sql
GO
:r $(TP_BDDA)\Tablas\20_Tabla_Tecnico.sql
GO
:r $(TP_BDDA)\Tablas\21_Tabla_Anunciante.sql
GO
:r $(TP_BDDA)\Tablas\22_Tabla_Publicidad.sql
GO
:r $(TP_BDDA)\Tablas\23_Tabla_HablaIdioma.sql
GO
:r $(TP_BDDA)\Tablas\24_Tabla_Partido.sql
GO
:r $(TP_BDDA)\Tablas\25_Tabla_Alineacion.sql
GO
:r $(TP_BDDA)\Tablas\26_Tabla_Arbitraje.sql
GO
:r $(TP_BDDA)\Tablas\27_Tabla_Reporte.sql
GO
:r $(TP_BDDA)\Tablas\28_Tabla_Evento.sql
GO
:r $(TP_BDDA)\Tablas\29_Tabla_Amonestacion.sql
GO
:r $(TP_BDDA)\Tablas\30_Tabla_Gol.sql
GO
:r $(TP_BDDA)\Tablas\31_Tabla_Sustitucion.sql
GO
:r $(TP_BDDA)\Tablas\32_Tabla_HistorialPublicidad.sql
GO
:r $(TP_BDDA)\Tablas\33_Tabla_PublicidadPais.sql
GO
:r $(TP_BDDA)\Tablas\34_Tabla_AnuncianteCampania.sql
GO
:r $(TP_BDDA)\Tablas\35_Tabla_CambioConvocatoria.sql
GO
:r $(TP_BDDA)\Tablas\36_Restricciones_Publicidad.sql
GO
:r $(TP_BDDA)\Tablas\37_Sp_Pais.sql
GO
:r $(TP_BDDA)\Tablas\38_Sp_Grupo.sql
GO
:r $(TP_BDDA)\Tablas\39_Sp_Club.sql
GO
:r $(TP_BDDA)\Tablas\40_Sp_Idioma.sql
GO
:r $(TP_BDDA)\Tablas\41_Sp_Fase.sql
GO
:r $(TP_BDDA)\Tablas\42_Sp_Periodo.sql
GO
:r $(TP_BDDA)\Tablas\43_Sp_EspacioPublicitario.sql
GO
:r $(TP_BDDA)\Tablas\44_Sp_CostoFranja.sql
GO
:r $(TP_BDDA)\Tablas\45_Sp_Motivo.sql
GO
:r $(TP_BDDA)\Tablas\46_Sp_Campania.sql
GO
:r $(TP_BDDA)\Tablas\47_Sp_Mundial.sql
GO
:r $(TP_BDDA)\Tablas\48_Sp_HusoHorario.sql
GO
:r $(TP_BDDA)\Tablas\49_Sp_Sede.sql
GO
:r $(TP_BDDA)\Tablas\50_Sp_Seleccion.sql
GO
:r $(TP_BDDA)\Tablas\51_Sp_Anunciante.sql
GO
:r $(TP_BDDA)\Tablas\52_Sp_Publicidad.sql
GO
:r $(TP_BDDA)\Tablas\53_Sp_HablaIdioma.sql
GO
:r $(TP_BDDA)\Tablas\54_Sp_Reporte.sql
GO
:r $(TP_BDDA)\Tablas\55_Sp_Partido.sql
GO
:r $(TP_BDDA)\Tablas\56_Sp_Alineacion.sql
GO
:r $(TP_BDDA)\Tablas\57_Sp_PublicidadPais.sql
GO
:r $(TP_BDDA)\Tablas\58_Sp_AnuncianteCampania.sql
GO
:r $(TP_BDDA)\Tablas\59_Sp_Jugador_ClubUpdate.sql
GO
:r $(TP_BDDA)\Tablas\60_Sp_HistorialPublicidad.sql
GO
:r $(TP_BDDA)\Tablas\61_Sp_Trans_Jugador.sql
GO
:r $(TP_BDDA)\Tablas\62_Sp_Trans_Arbitro.sql
GO
:r $(TP_BDDA)\Tablas\63_Sp_Trans_Tecnico.sql
GO
:r $(TP_BDDA)\Tablas\64_Sp_Trans_Arbitraje.sql
GO
:r $(TP_BDDA)\Tablas\65_Sp_Amonestacion.sql
GO
:r $(TP_BDDA)\Tablas\66_Sp_Gol.sql
GO
:r $(TP_BDDA)\Tablas\67_Sp_Sustitucion.sql
GO
:r $(TP_BDDA)\Tablas\68_Sp_Evento.sql
GO
:r $(TP_BDDA)\Tablas\69_Sp_CambioConvocatoria.sql
GO
-- Entrega 7: SP de conversion horaria y reportes (necesarios para los permisos de roles)
:r $(TP_BDDA)\Tablas\93_SP_APIconversionHora.sql
GO
:r $(TP_BDDA)\Tablas\94_Sp_Reportes.sql
GO
-- Entrega 8: Crear claves de cifrado y aplicar cifrado a datos sensibles (MUNDIAL)
:r $(TP_BDDA)\Tablas\97_Seguridad_Cifrado_Claves.sql
GO
:r $(TP_BDDA)\Tablas\98_Seguridad_Cifrado_Aplicar.sql
GO
USE MUNDIAL;
GO
-- Entrega 8: Roles de seguridad y usuarios (MUNDIAL)
:r $(TP_BDDA)\Tablas\99_Seguridad_Roles.sql
GO
:r $(TP_BDDA)\Tablas\100_Seguridad_Usuarios.sql
GO

USE [MUNDIALtesting];
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
GO
-- Entrega 7: SP de conversion horaria y reportes (necesarios para los permisos de roles)
:r $(TP_BDDA)\Tablas\93_SP_APIconversionHora.sql
GO
:r $(TP_BDDA)\Tablas\94_Sp_Reportes.sql
GO
-- Entrega 8: Crear claves de cifrado y aplicar cifrado a datos sensibles (MUNDIALtesting)
:r $(TP_BDDA)\Tablas\97_Seguridad_Cifrado_Claves.sql
GO
:r $(TP_BDDA)\Tablas\98_Seguridad_Cifrado_Aplicar.sql
GO
USE MUNDIALtesting;
GO
-- Entrega 8: Roles de seguridad y usuarios (MUNDIALtesting)
:r $(TP_BDDA)\Tablas\99_Seguridad_Roles.sql
GO
:r $(TP_BDDA)\Tablas\100_Seguridad_Usuarios.sql
GO
PRINT 'Instalacion de entrega 5 finalizada en MUNDIALtesting.';
GO
GO

PRINT 'Instalacion de entrega 5 finalizada.';
