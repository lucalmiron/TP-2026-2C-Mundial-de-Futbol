-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Grupo 7
-- Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 26/10/26.
-- Objetivo: instalar los objetos reales en una base nueva de pruebas (modo SQLCMD).
-- 1. Ajustar ScriptPath y BasePrueba antes de ejecutar este archivo.
-- 2. Seleccionar esa misma base al abrir el test en otra ventana de SSMS.
-- 3. Ejecutar un solo test con datos iniciales en cada base vacia.
-- Para pruebas independientes, usar el nombre de base indicado en su encabezado.
-- Club, IdiomaReporte, Persona, Amonestacion, Periodo, Evento, Publicidad_Automatica,
-- Sede_Capacidad, Tanda y Validaciones usan MUNDIAL_Final_Test_E5.
-- Excepciones: Eventos_Alineaciones usa MUNDIAL_Grupo2_Test_E5;
-- Jugadores_Convocatorias usa MUNDIAL_Grupo3_Test_E5;
-- Partidos_Arbitraje usa MUNDIAL_Grupo4_Test_E5; Horarios usa MUNDIAL_Horarios_Test_E5.
-- Revisar y eliminar manualmente la base de prueba antes de reutilizar su nombre.
-- Este archivo no elimina bases existentes ni ejecuta los tests.
:setvar ScriptPath "."
:setvar BasePrueba "MUNDIAL_Final_Test_E5"
:ON ERROR EXIT
USE master;
GO
IF '$(BasePrueba)' NOT LIKE 'MUNDIAL[_]%[_]Test[_]E5'
 THROW 51000,'Nombre de base de pruebas no permitido.',1;
IF DB_ID('$(BasePrueba)') IS NOT NULL
 THROW 51000,'La base de pruebas ya existe. Revisarla antes de repetir la ejecucion.',1;
GO
CREATE DATABASE [$(BasePrueba)] COLLATE Latin1_General_100_CI_AS_SC;
GO
USE [$(BasePrueba)];
GO
CREATE SCHEMA equipos;
GO
CREATE SCHEMA sedes;
GO
CREATE SCHEMA partidos;
GO
CREATE SCHEMA arbitros;
GO
CREATE SCHEMA publicidad;
GO
CREATE SCHEMA SP;
GO
CREATE SCHEMA SPTRANS;
GO
:r $(ScriptPath)\03_Tabla_Pais.sql
GO
:r $(ScriptPath)\04_Tabla_Grupo.sql
GO
:r $(ScriptPath)\05_Tabla_Club.sql
GO
:r $(ScriptPath)\06_Tabla_Idioma.sql
GO
:r $(ScriptPath)\07_Tabla_Fase.sql
GO
:r $(ScriptPath)\08_Tabla_Periodo.sql
GO
:r $(ScriptPath)\09_Tabla_EspacioPublicitario.sql
GO
:r $(ScriptPath)\10_Tabla_CostoFranja.sql
GO
:r $(ScriptPath)\11_Tabla_Motivo.sql
GO
:r $(ScriptPath)\12_Tabla_Campania.sql
GO
:r $(ScriptPath)\13_Tabla_Mundial.sql
GO
:r $(ScriptPath)\14_Tabla_HusoHorario.sql
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
GO
