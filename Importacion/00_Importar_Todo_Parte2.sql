-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Comision 02
-- Grupo 7: Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba Leandro.
-- Fecha: 21/11/2026.
-- Objetivo: importacion por partes - PARTE 2 de 3.
--   Cargas deportivas 13 a 20 y publicidad 26 a 28.
--   Es el segundo bloque de 00_Importar_Todo.sql, ejecutable por separado.
--   Requiere haber corrido antes la Parte 1 (base instalada y catalogos).
-- SSMS: activar Modo SQLCMD (Consulta -> Modo SQLCMD).
-- Cada integrante debe ajustar el bloque :setvar de abajo a su ruta de proyecto.
--
-- Incluye: 13 Motivos, 14 Alineaciones, 15 Arbitrajes, 16 Sustituciones,
--          17 Goles, 18 Tecnicos, 19 Amonestaciones, 20 Publicidad,
--          26 Espacios_Publicitarios, 27 Costo_Franja, 28 Historial_Publicidad.
--
-- Dependencias:
--   08 (Parte 1) antes de 26 y 27 (aqui) -> espacios y franjas por sede.
--   20, 26 y 27 (aqui) antes de 28 -> el historial usa el espacio, la franja
--                                    y el nombre de campania de la carga 20.
--   15 (aqui) antes de 24 (Parte 3) -> el arbitraje FIFA no duplica al
--                                      arbitro principal que ya cargo la 15.
--   16 (aqui) antes de 21 (Parte 3) -> la tanda solo se carga si el marcador
--                                      quedo empatado.
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
PRINT 'INICIO IMPORTACION ENTREGA 6 - PARTE 2/3 - ' + CONVERT(VARCHAR(19), GETDATE(), 120);
PRINT '=====================================================';
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

PRINT '=====================================================';
PRINT 'PARTE 2/3 finalizada - ' + CONVERT(VARCHAR(19), GETDATE(), 120);
PRINT 'Siguiente: 00_Importar_Todo_Parte3.sql';
PRINT '=====================================================';
GO
