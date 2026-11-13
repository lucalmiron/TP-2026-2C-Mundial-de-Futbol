-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Comision 02
-- Grupo 7: Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba Leandro.
-- Fecha: 13/11/2026.
-- Objetivo: Script maestro de importacion de la Entrega 6.
-- Ejecuta en orden: instalacion de la Entrega 5 + todos los importadores (01-19).
-- SSMS: activar Modo SQLCMD (Consulta -> Modo SQLCMD).
-- Cada integrante debe revisar y ajustar las rutas de archivo en cada importador
-- individual si su ruta de proyecto es diferente.

:setvar ScriptPath "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Tablas"
:ON ERROR EXIT

:r $(ScriptPath)\00_Ejecutar_Todo.sql
GO
:r $(ScriptPath)\01_Importacion_Carga_Grupos.sql
GO
:r $(ScriptPath)\02_Importacion_Carga_Fases.sql
GO
:r $(ScriptPath)\03_Importacion_Carga_Periodos.sql
GO
:r $(ScriptPath)\04_Importacion_Carga_Husos.sql
GO
:r $(ScriptPath)\05_Importacion_Carga_Idioma.sql
GO
:r $(ScriptPath)\06_Importacion_Carga_Pais.sql
GO
:r $(ScriptPath)\06b_Importacion_Carga_Mundial.sql
GO
:r $(ScriptPath)\07_Importacion_Carga_Selecciones.sql
GO
:r $(ScriptPath)\08_Importacion_Carga_Sedes.sql
GO
:r $(ScriptPath)\09_Importacion_Carga_Clubes.sql
GO
:r $(ScriptPath)\10_Importacion_Carga_Jugadores.sql
GO
:r $(ScriptPath)\11_Importacion_Carga_Partidos.sql
GO
:r $(ScriptPath)\12_Importacion_Carga_PBI_Pais.sql
GO
:r $(ScriptPath)\13_Importacion_Carga_Motivos.sql
GO
:r $(ScriptPath)\14_Importacion_Carga_Alineaciones.sql
GO
:r $(ScriptPath)\15_Importacion_Carga_Arbitrajes.sql
GO
:r $(ScriptPath)\16_Importacion_Carga_Goles.sql
GO
:r $(ScriptPath)\17_Importacion_Carga_Amonestaciones.sql
GO
:r $(ScriptPath)\18_Importacion_Carga_Sustituciones.sql
GO
:r $(ScriptPath)\19_Importacion_Carga_Tecnicos.sql
GO

PRINT 'Importacion de la Entrega 6 finalizada.';
