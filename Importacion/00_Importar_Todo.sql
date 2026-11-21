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
--
-- Cada importador esta precedido por un PRINT con la hora: si algo falla, el
-- ultimo ">>>" que aparece en la pestania Mensajes es el importador culpable.

--Santutu
:setvar RutaTablas "C:\Users\Administrator\Desktop\tp_bdda\TP-2026-2C-Mundial-de-Futbol\Tablas"
:setvar RutaImportacion "C:\Users\Administrator\Desktop\tp_bdda\TP-2026-2C-Mundial-de-Futbol\Importacion"
--L
--:setvar RutaTablas "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Tablas"
--:setvar RutaImportacion "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Importacion"
--Fidel
--:setvar RutaTablas "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Tablas"
--:setvar RutaImportacion "C:\Users\Usuario\Documents\proyecto BDDA\TP-2026-2C-Mundial-de-Futbol\Importacion"

-- IGNORE: sigue ejecutando aunque un importador marque errores permisibles.
-- Para cortar ante el primer error, cambiar por :ON ERROR EXIT
:ON ERROR IGNORE

-- Los metodos XML (.nodes/.value) y las vistas indexadas requieren
-- QUOTED_IDENTIFIER ON. SQLCMD lo deja en OFF por defecto, asi que se activa
-- para toda la sesion antes de incluir los demas scripts.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT '=====================================================';
PRINT 'INICIO IMPORTACION ENTREGA 6 - ' + CONVERT(VARCHAR(19), GETDATE(), 120);
PRINT '=====================================================';
GO

PRINT '>>> ' + CONVERT(VARCHAR(19), GETDATE(), 120) + ' - 00_Ejecutar_Todo (instalador Entrega 5)';
GO
:r $(RutaTablas)\00_Ejecutar_Todo.sql
GO

PRINT '>>> ' + CONVERT(VARCHAR(19), GETDATE(), 120) + ' - 01_Carga_Grupos';
GO
:r $(RutaImportacion)\01_Importacion_Carga_Grupos.sql
GO

PRINT '>>> ' + CONVERT(VARCHAR(19), GETDATE(), 120) + ' - 02_Carga_Fases';
GO
:r $(RutaImportacion)\02_Importacion_Carga_Fases.sql
GO

PRINT '>>> ' + CONVERT(VARCHAR(19), GETDATE(), 120) + ' - 03_Carga_Periodos';
GO
:r $(RutaImportacion)\03_Importacion_Carga_Periodos.sql
GO

PRINT '>>> ' + CONVERT(VARCHAR(19), GETDATE(), 120) + ' - 04_Carga_Husos';
GO
:r $(RutaImportacion)\04_Importacion_Carga_Husos.sql
GO

PRINT '>>> ' + CONVERT(VARCHAR(19), GETDATE(), 120) + ' - 05_Carga_Idioma';
GO
:r $(RutaImportacion)\05_Importacion_Carga_Idioma.sql
GO

PRINT '>>> ' + CONVERT(VARCHAR(19), GETDATE(), 120) + ' - 06_Carga_Pais';
GO
:r $(RutaImportacion)\06_Importacion_Carga_Pais.sql
GO

PRINT '>>> ' + CONVERT(VARCHAR(19), GETDATE(), 120) + ' - 06b_Carga_Mundial';
GO
:r $(RutaImportacion)\06b_Importacion_Carga_Mundial.sql
GO

PRINT '>>> ' + CONVERT(VARCHAR(19), GETDATE(), 120) + ' - 07_Carga_Selecciones';
GO
:r $(RutaImportacion)\07_Importacion_Carga_Selecciones.sql
GO

PRINT '>>> ' + CONVERT(VARCHAR(19), GETDATE(), 120) + ' - 08_Carga_Sedes';
GO
:r $(RutaImportacion)\08_Importacion_Carga_Sedes.sql
GO

PRINT '>>> ' + CONVERT(VARCHAR(19), GETDATE(), 120) + ' - 09_Carga_Clubes';
GO
:r $(RutaImportacion)\09_Importacion_Carga_Clubes.sql
GO

PRINT '>>> ' + CONVERT(VARCHAR(19), GETDATE(), 120) + ' - 10_Carga_Jugadores';
GO
:r $(RutaImportacion)\10_Importacion_Carga_Jugadores.sql
GO

PRINT '>>> ' + CONVERT(VARCHAR(19), GETDATE(), 120) + ' - 11_Carga_Partidos';
GO
:r $(RutaImportacion)\11_Importacion_Carga_Partidos.sql
GO

PRINT '>>> ' + CONVERT(VARCHAR(19), GETDATE(), 120) + ' - 12_Carga_PBI_Pais';
GO
:r $(RutaImportacion)\12_Importacion_Carga_PBI_Pais.sql
GO

PRINT '>>> ' + CONVERT(VARCHAR(19), GETDATE(), 120) + ' - 13_Carga_Motivos';
GO
:r $(RutaImportacion)\13_Importacion_Carga_Motivos.sql
GO

PRINT '>>> ' + CONVERT(VARCHAR(19), GETDATE(), 120) + ' - 14_Carga_Alineaciones';
GO
:r $(RutaImportacion)\14_Importacion_Carga_Alineaciones.sql
GO

PRINT '>>> ' + CONVERT(VARCHAR(19), GETDATE(), 120) + ' - 15_Carga_Arbitrajes';
GO
:r $(RutaImportacion)\15_Importacion_Carga_Arbitrajes.sql
GO

PRINT '>>> ' + CONVERT(VARCHAR(19), GETDATE(), 120) + ' - 16_Carga_Sustituciones';
GO
:r $(RutaImportacion)\16_Importacion_Carga_Sustituciones.sql
GO

PRINT '>>> ' + CONVERT(VARCHAR(19), GETDATE(), 120) + ' - 17_Carga_Goles';
GO
:r $(RutaImportacion)\17_Importacion_Carga_Goles.sql
GO

PRINT '>>> ' + CONVERT(VARCHAR(19), GETDATE(), 120) + ' - 18_Carga_Tecnicos';
GO
:r $(RutaImportacion)\18_Importacion_Carga_Tecnicos.sql
GO

PRINT '>>> ' + CONVERT(VARCHAR(19), GETDATE(), 120) + ' - 19_Carga_Amonestaciones';
GO
:r $(RutaImportacion)\19_Importacion_Carga_Amonestaciones.sql
GO

PRINT '>>> ' + CONVERT(VARCHAR(19), GETDATE(), 120) + ' - 20_Carga_Publicidad';
GO
:r $(RutaImportacion)\20_Importacion_Carga_Publicidad.sql
GO

PRINT '>>> ' + CONVERT(VARCHAR(19), GETDATE(), 120) + ' - 26_Carga_Espacios_Publicitarios';
GO
:r $(RutaImportacion)\26_Importacion_Carga_Espacios_Publicitarios.sql
GO

PRINT '>>> ' + CONVERT(VARCHAR(19), GETDATE(), 120) + ' - 27_Carga_Costo_Franja';
GO
:r $(RutaImportacion)\27_Importacion_Carga_Costo_Franja.sql
GO

PRINT '>>> ' + CONVERT(VARCHAR(19), GETDATE(), 120) + ' - 28_Carga_Historial_Publicidad';
GO
:r $(RutaImportacion)\28_Importacion_Carga_Historial_Publicidad.sql
GO

PRINT '>>> ' + CONVERT(VARCHAR(19), GETDATE(), 120) + ' - 22_Carga_Goles_Penal';
GO
:r $(RutaImportacion)\22_Importacion_Carga_Goles_Penal.sql
GO

PRINT '>>> ' + CONVERT(VARCHAR(19), GETDATE(), 120) + ' - 23_Carga_Rojas_Directas';
GO
:r $(RutaImportacion)\23_Importacion_Carga_Rojas_Directas.sql
GO

PRINT '>>> ' + CONVERT(VARCHAR(19), GETDATE(), 120) + ' - 21_Carga_Tanda_Penales';
GO
:r $(RutaImportacion)\21_Importacion_Carga_Tanda_Penales.sql
GO

PRINT '>>> ' + CONVERT(VARCHAR(19), GETDATE(), 120) + ' - 24_Carga_Arbitraje_FIFA';
GO
:r $(RutaImportacion)\24_Importacion_Carga_Arbitraje_FIFA.sql
GO

PRINT '>>> ' + CONVERT(VARCHAR(19), GETDATE(), 120) + ' - 25_Carga_Asistencia';
GO
:r $(RutaImportacion)\25_Importacion_Carga_Asistencia.sql
GO

PRINT '=====================================================';
PRINT 'Importacion de la Entrega 6 finalizada - ' + CONVERT(VARCHAR(19), GETDATE(), 120);
PRINT '=====================================================';
GO

-- Verificacion final: tablas ordenadas por cantidad de filas (las vacias primero).
USE MUNDIAL;
GO
SELECT s.name AS esquema, t.name AS tabla, SUM(p.rows) AS filas
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.partitions AS p ON p.object_id = t.object_id AND p.index_id IN (0,1)
GROUP BY s.name, t.name
ORDER BY filas, s.name, t.name;
GO