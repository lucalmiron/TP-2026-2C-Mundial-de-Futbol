-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Comision 02
-- Grupo 7: Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba Leandro.
-- Fecha: 21/11/2026.
-- Objetivo: importacion por partes - PARTE 3 de 3.
--   Cargas finales: goles de penal, rojas directas, tanda de penales,
--   arbitraje FIFA y asistencia.
--   Es el ultimo bloque de 00_Importar_Todo.sql, ejecutable por separado.
--   Requiere haber corrido antes la Parte 1 y la Parte 2.
-- SSMS: activar Modo SQLCMD (Consulta -> Modo SQLCMD).
-- Cada integrante debe ajustar el bloque :setvar de abajo a su ruta de proyecto.
--
-- Incluye (en este orden): 22 Goles_Penal, 23 Rojas_Directas,
--                          21 Tanda_Penales, 24 Arbitraje_FIFA,
--                          25 Asistencia.
--
-- Dependencias (por eso el orden no es el numerico):
--   16 (Parte 2) y 22 (aqui) antes de 21 -> la tanda solo se carga si el
--                                          marcador quedo empatado.
--   03 y 10 (Parte 1) antes de 21 -> periodos y jugadores de la tanda.
--   15 (Parte 2) antes de 24 -> la planilla FIFA completa sin duplicar al
--                              arbitro principal que ya cargo la 15.
--   11 (Parte 1) antes de 25 -> la asistencia actualiza un partido del fixture.
--
-- Cada importador esta precedido por un PRINT con la hora: si algo falla, el
-- ultimo ">>>" que aparece en la pestania Mensajes es el importador culpable.

--Santutu
:setvar RutaImportacion "C:\Users\Administrator\Desktop\tp_bdda\TP-2026-2C-Mundial-de-Futbol\Importacion"
--L
--:setvar RutaImportacion "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol\Importacion"
--Fidel
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
PRINT 'INICIO IMPORTACION ENTREGA 6 - PARTE 3/3 - ' + CONVERT(VARCHAR(19), GETDATE(), 120);
PRINT '=====================================================';
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
PRINT 'PARTE 3/3 finalizada - ' + CONVERT(VARCHAR(19), GETDATE(), 120);
PRINT 'Importacion de la Entrega 6 completada.';
PRINT '=====================================================';
GO
