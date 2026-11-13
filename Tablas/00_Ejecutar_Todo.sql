-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Grupo 7
-- Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 26/10/26.
-- Objetivo: instalar la base, tablas y procedimientos de la entrega 5.
-- Orden: 01-02 bases y esquemas; 03-36 tablas y restricciones; 37-69 SP.
-- En SSMS, activar modo SQLCMD y cambiar ScriptPath por la ruta de Tablas.
-- Mantener las comillas si la ruta contiene espacios.

--L
:setvar ScriptPath "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Tablas"

--Santutu
--:setvar ScriptPath "C:\Users\Administrator\Desktop\tp_bdda\TP-2026-2C-Mundial-de-Futbol\Tablas"

:ON ERROR EXIT

:r $(ScriptPath)\01_Base_Mundial.sql
GO
:r $(ScriptPath)\02_Base_MundialTesting.sql
GO
USE MUNDIAL;
GO
:r $(ScriptPath)\03_Tabla_Idioma.sql
GO
:r $(ScriptPath)\04_Tabla_HusoHorario.sql
GO
:r $(ScriptPath)\05_Tabla_Pais.sql
GO
:r $(ScriptPath)\06_Tabla_Grupo.sql
GO
:r $(ScriptPath)\07_Tabla_Club.sql
GO
:r $(ScriptPath)\08_Tabla_Fase.sql
GO
:r $(ScriptPath)\09_Tabla_Periodo.sql
GO
:r $(ScriptPath)\10_Tabla_EspacioPublicitario.sql
GO
:r $(ScriptPath)\11_Tabla_CostoFranja.sql
GO
:r $(ScriptPath)\12_Tabla_Motivo.sql
GO
:r $(ScriptPath)\13_Tabla_Campania.sql
GO
:r $(ScriptPath)\14_Tabla_Mundial.sql
GO
:r $(ScriptPath)\15_Tabla_Sede.sql
GO
:r $(ScriptPath)\16_Tabla_Persona.sql
GO
:r $(ScriptPath)\17_Tabla_Seleccion.sql
GO
:r $(ScriptPath)\18_Tabla_Arbitro.sql
GO
:r $(ScriptPath)\19_Tabla_Jugador.sql
GO
:r $(ScriptPath)\20_Tabla_Tecnico.sql
GO
:r $(ScriptPath)\21_Tabla_Anunciante.sql
GO
:r $(ScriptPath)\22_Tabla_Publicidad.sql
GO
:r $(ScriptPath)\23_Tabla_HablaIdioma.sql
GO
:r $(ScriptPath)\24_Tabla_Partido.sql
GO
:r $(ScriptPath)\25_Tabla_Alineacion.sql
GO
:r $(ScriptPath)\26_Tabla_Arbitraje.sql
GO
:r $(ScriptPath)\27_Tabla_Reporte.sql
GO
:r $(ScriptPath)\28_Tabla_Evento.sql
GO
:r $(ScriptPath)\29_Tabla_Amonestacion.sql
GO
:r $(ScriptPath)\30_Tabla_Gol.sql
GO
:r $(ScriptPath)\31_Tabla_Sustitucion.sql
GO
:r $(ScriptPath)\32_Tabla_HistorialPublicidad.sql
GO
:r $(ScriptPath)\33_Tabla_PublicidadPais.sql
GO
:r $(ScriptPath)\34_Tabla_AnuncianteCampania.sql
GO
:r $(ScriptPath)\35_Tabla_CambioConvocatoria.sql
GO
:r $(ScriptPath)\36_Restricciones_Publicidad.sql
GO
:r $(ScriptPath)\37_Sp_Pais.sql
GO
:r $(ScriptPath)\38_Sp_Grupo.sql
GO
:r $(ScriptPath)\39_Sp_Club.sql
GO
:r $(ScriptPath)\40_Sp_Idioma.sql
GO
:r $(ScriptPath)\41_Sp_Fase.sql
GO
:r $(ScriptPath)\42_Sp_Periodo.sql
GO
:r $(ScriptPath)\43_Sp_EspacioPublicitario.sql
GO
:r $(ScriptPath)\44_Sp_CostoFranja.sql
GO
:r $(ScriptPath)\45_Sp_Motivo.sql
GO
:r $(ScriptPath)\46_Sp_Campania.sql
GO
:r $(ScriptPath)\47_Sp_Mundial.sql
GO
:r $(ScriptPath)\48_Sp_HusoHorario.sql
GO
:r $(ScriptPath)\49_Sp_Sede.sql
GO
:r $(ScriptPath)\50_Sp_Seleccion.sql
GO
:r $(ScriptPath)\51_Sp_Anunciante.sql
GO
:r $(ScriptPath)\52_Sp_Publicidad.sql
GO
:r $(ScriptPath)\53_Sp_HablaIdioma.sql
GO
:r $(ScriptPath)\54_Sp_Reporte.sql
GO
:r $(ScriptPath)\55_Sp_Partido.sql
GO
:r $(ScriptPath)\56_Sp_Alineacion.sql
GO
:r $(ScriptPath)\57_Sp_PublicidadPais.sql
GO
:r $(ScriptPath)\58_Sp_AnuncianteCampania.sql
GO
:r $(ScriptPath)\59_Sp_Jugador_ClubUpdate.sql
GO
:r $(ScriptPath)\60_Sp_HistorialPublicidad.sql
GO
:r $(ScriptPath)\61_Sp_Trans_Jugador.sql
GO
:r $(ScriptPath)\62_Sp_Trans_Arbitro.sql
GO
:r $(ScriptPath)\63_Sp_Trans_Tecnico.sql
GO
:r $(ScriptPath)\64_Sp_Trans_Arbitraje.sql
GO
:r $(ScriptPath)\65_Sp_Amonestacion.sql
GO
:r $(ScriptPath)\66_Sp_Gol.sql
GO
:r $(ScriptPath)\67_Sp_Sustitucion.sql
GO
:r $(ScriptPath)\68_Sp_Evento.sql
GO
:r $(ScriptPath)\69_Sp_CambioConvocatoria.sql

USE [MUNDIALtesting];
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
GO
PRINT 'Instalacion de entrega 5 finalizada en MUNDIALtesting.';
GO
GO

PRINT 'Instalacion de entrega 5 finalizada.';
