-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Comision 02
-- Grupo 7: Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba Leandro.
-- Fecha: 18/11/2026.
-- Objetivo: Script maestro de importacion de la Entrega 6.
-- Ejecuta en orden: instalacion de la Entrega 5 + todos los importadores (01-28).
-- SSMS: activar Modo SQLCMD (Consulta -> Modo SQLCMD).
-- Cada integrante debe revisar y ajustar las rutas de archivo en cada importador
-- individual si su ruta de proyecto es diferente.
-- Ojo: el instalador (Tablas\00_Ejecutar_Todo.sql) trae su propia variable
-- ScriptPath, que hay que ajustar ahi tambien (cada integrante tiene su linea).
--
-- Orden de las cargas que dependen entre si:
--   16 y 22 antes de 21 -> la tanda solo se carga si el marcador quedo empatado.
--   15 antes de 24      -> el arbitraje FIFA completa la planilla sin duplicar al
--                          arbitro principal que ya cargo la 15.
--   11 antes de 25      -> la asistencia actualiza un partido del fixture.
--   03 y 10 antes de 21 -> periodos y jugadores de la tanda.
--   08 antes de 26 y 27 -> los espacios y las franjas se cargan por sede.
--   26 y 27 antes de 28 -> el historial usa el espacio y la franja de la sede,
--                          y la 20 le da el nombre de la campania.
--Santutu
:setvar RutaTablas "C:\Users\Administrator\Desktop\tp_bdda\TP-2026-2C-Mundial-de-Futbol\Tablas"
:setvar RutaImportacion "C:\Users\Administrator\Desktop\tp_bdda\TP-2026-2C-Mundial-de-Futbol\Importacion"
--L
--:setvar RutaTablas "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Tablas"
--:setvar RutaImportacion "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Importacion"
--Fidel
--:setvar RutaTablas "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Tablas"
--:setvar RutaImportacion "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Importacion"
:ON ERROR EXIT

:r $(RutaTablas)\00_Ejecutar_Todo.sql
GO
:r $(RutaImportacion)\01_Importacion_Carga_Grupos.sql
GO
:r $(RutaImportacion)\02_Importacion_Carga_Fases.sql
GO
:r $(RutaImportacion)\03_Importacion_Carga_Periodos.sql
GO
:r $(RutaImportacion)\04_Importacion_Carga_Husos.sql
GO
:r $(RutaImportacion)\05_Importacion_Carga_Idioma.sql
GO
:r $(RutaImportacion)\06_Importacion_Carga_Pais.sql
GO
:r $(RutaImportacion)\06b_Importacion_Carga_Mundial.sql
GO
:r $(RutaImportacion)\07_Importacion_Carga_Selecciones.sql
GO
:r $(RutaImportacion)\08_Importacion_Carga_Sedes.sql
GO
:r $(RutaImportacion)\09_Importacion_Carga_Clubes.sql
GO
:r $(RutaImportacion)\10_Importacion_Carga_Jugadores.sql
GO
:r $(RutaImportacion)\11_Importacion_Carga_Partidos.sql
GO
:r $(RutaImportacion)\12_Importacion_Carga_PBI_Pais.sql
GO
:r $(RutaImportacion)\13_Importacion_Carga_Motivos.sql
GO
:r $(RutaImportacion)\14_Importacion_Carga_Alineaciones.sql
GO
:r $(RutaImportacion)\15_Importacion_Carga_Arbitrajes.sql
GO
:r $(RutaImportacion)\16_Importacion_Carga_Sustituciones.sql
GO
:r $(RutaImportacion)\17_Importacion_Carga_Goles.sql
GO
:r $(RutaImportacion)\18_Importacion_Carga_Tecnicos.sql
GO
:r $(RutaImportacion)\19_Importacion_Carga_Amonestaciones.sql
GO
:r $(RutaImportacion)\20_Importacion_Carga_Publicidad.sql
GO
:r $(RutaImportacion)\26_Importacion_Carga_Espacios_Publicitarios.sql
GO
:r $(RutaImportacion)\27_Importacion_Carga_Costo_Franja.sql
GO
:r $(RutaImportacion)\28_Importacion_Carga_Historial_Publicidad.sql
GO
:r $(RutaImportacion)\22_Importacion_Carga_Goles_Penal.sql
GO
:r $(RutaImportacion)\23_Importacion_Carga_Rojas_Directas.sql
GO
:r $(RutaImportacion)\21_Importacion_Carga_Tanda_Penales.sql
GO
:r $(RutaImportacion)\24_Importacion_Carga_Arbitraje_FIFA.sql
GO
:r $(RutaImportacion)\25_Importacion_Carga_Asistencia.sql
GO

PRINT 'Importacion de la Entrega 6 finalizada.';
