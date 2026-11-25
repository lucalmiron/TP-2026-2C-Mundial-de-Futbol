-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Comision 02
-- Grupo 7: Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba Leandro.
-- Fecha: 21/11/2026.
-- Objetivo: importacion por partes - PARTE 3 de 3.
--   Cargas finales: goles de penal, rojas directas, tanda de penales,
--   arbitraje FIFA y asistencia.
--   Se ejecuta por separado; requiere haber corrido antes la Parte 1 y la Parte 2.
-- SSMS: activar Modo SQLCMD (Consulta -> Modo SQLCMD). La ruta raiz se define mas abajo, en este archivo.
--
-- Incluye (en este orden): 22 Goles_Penal, 23 Rojas_Directas,
--                          21 Tanda_Penales, 24 Arbitraje_FIFA,
--                          25 Asistencia, 29 CambioConvocatoria.
--
-- Dependencias (por eso el orden no es el numerico):
--   16 (Parte 2) y 22 (aqui) antes de 21 -> la tanda solo se carga si el
--                                          marcador quedo empatado.
--   03 y 10 (Parte 1) antes de 21 -> periodos y jugadores de la tanda.
--   15 (Parte 2) antes de 24 -> la planilla FIFA completa sin duplicar al
--                              arbitro principal que ya cargo la 15.
--   11 (Parte 1) antes de 25 -> la asistencia actualiza un partido del fixture.
--   07, 06b y 10 (Parte 1) antes de 29 -> el cambio de convocatoria usa
--                                        selecciones, mundial y jugadores.
--
-- Cada importador esta precedido por un PRINT con la hora: si algo falla, el
-- ultimo ">>>" que aparece en la pestania Mensajes es el importador culpable.

-- UNICO LUGAR A EDITAR: cada integrante pone aqui la ruta de su carpeta del proyecto.
-- No hay que definir variables de Windows ni tocar ningun otro archivo.
-- santutu
--:setvar TP_BDDA "C:\Users\Administrator\Desktop\tp_bdda\TP-2026-2C-Mundial-de-Futbol"
-- fidel

--L
:setvar TP_BDDA "C:\Users\Luca\Documents\TP_Mundial\TP-2026-2C-Mundial-de-Futbol"

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
:r $(TP_BDDA)\Importacion\22_Importacion_Carga_Goles_Penal.sql
GO

PRINT '>>> ' + CONVERT(VARCHAR(19), GETDATE(), 120) + ' - 23_Carga_Rojas_Directas';
GO
:r $(TP_BDDA)\Importacion\23_Importacion_Carga_Rojas_Directas.sql
GO

PRINT '>>> ' + CONVERT(VARCHAR(19), GETDATE(), 120) + ' - 21_Carga_Tanda_Penales';
GO
:r $(TP_BDDA)\Importacion\21_Importacion_Carga_Tanda_Penales.sql
GO

PRINT '>>> ' + CONVERT(VARCHAR(19), GETDATE(), 120) + ' - 24_Carga_Arbitraje_FIFA';
GO
:r $(TP_BDDA)\Importacion\24_Importacion_Carga_Arbitraje_FIFA.sql
GO

PRINT '>>> ' + CONVERT(VARCHAR(19), GETDATE(), 120) + ' - 25_Carga_Asistencia';
GO
:r $(TP_BDDA)\Importacion\25_Importacion_Carga_Asistencia.sql
GO

PRINT '>>> ' + CONVERT(VARCHAR(19), GETDATE(), 120) + ' - 29_Carga_CambioConvocatoria';
GO
:r $(TP_BDDA)\Importacion\29_Importacion_Carga_CambioConvocatoria.sql
GO

PRINT '=====================================================';
PRINT 'PARTE 3/3 finalizada - ' + CONVERT(VARCHAR(19), GETDATE(), 120);
PRINT 'Importacion de la Entrega 6 completada.';
PRINT '=====================================================';
GO
