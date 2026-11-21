-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Comision 02
-- Grupo 7: Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba Leandro.
-- Fecha: 21/11/2026.
-- Objetivo: importacion por partes - PARTE 1 de 3.
--   Instalacion de la Entrega 5 + catalogos y cargas 01 a 12.
--   Es el primer bloque de 00_Importar_Todo.sql, ejecutable por separado.
--   Correr ANTES que la Parte 2 y la Parte 3: esta crea la base y las tablas.
-- SSMS: activar Modo SQLCMD (Consulta -> Modo SQLCMD).
-- Cada integrante debe ajustar el bloque :setvar de abajo a su ruta de proyecto.
-- Ojo: el instalador (Tablas\00_Ejecutar_Todo.sql) trae su propia variable
-- ScriptPath, que hay que ajustar ahi tambien (cada integrante tiene su linea).
--
-- Incluye: 00_Ejecutar_Todo, 01 Grupos, 02 Fases, 03 Periodos, 04 Husos,
--          05 Idioma, 06 Pais, 06b Mundial, 07 Selecciones, 08 Sedes,
--          09 Clubes, 10 Jugadores, 11 Partidos, 12 PBI_Pais.
--
-- Dependencias con las otras partes:
--   03 y 10 (aqui) antes de 21 (Parte 3).
--   08 (aqui) antes de 26 y 27 (Parte 2).
--   11 (aqui) antes de 25 (Parte 3).
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
PRINT 'INICIO IMPORTACION ENTREGA 6 - PARTE 1/3 - ' + CONVERT(VARCHAR(19), GETDATE(), 120);
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

PRINT '=====================================================';
PRINT 'PARTE 1/3 finalizada - ' + CONVERT(VARCHAR(19), GETDATE(), 120);
PRINT 'Siguiente: 00_Importar_Todo_Parte2.sql';
PRINT '=====================================================';
GO
