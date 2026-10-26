-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Grupo 7
-- Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 26/10/26.
-- Objetivo: ejecutar las pruebas antiguas, despues de 00_Ejecutar_Todo.sql.
-- Usar una instancia de pruebas: estos archivos trabajan sobre MUNDIAL.
-- Los errores esperados no detienen el recorrido; revisar los resultados.
-- Las pruebas independientes se preparan con 71_Preparar_Pruebas.sql.
-- Ejecutar con sqlcmd desde Tablas o ajustar ScriptPath en modo SQLCMD de SSMS.
:setvar ScriptPath "."
:ON ERROR IGNORE

:r $(ScriptPath)\72_Test_Pais.sql
GO
:r $(ScriptPath)\73_Test_Grupo.sql
GO
:r $(ScriptPath)\76_Test_Fase.sql
GO
:r $(ScriptPath)\78_Test_Sp_EspacioPublicitario.sql
GO
:r $(ScriptPath)\79_Test_Sp_CostoFranja.sql
GO
:r $(ScriptPath)\80_Test_Motivo.sql
GO
:r $(ScriptPath)\81_Test_Campania.sql
GO
:r $(ScriptPath)\82_Test_Mundial.sql
GO
:r $(ScriptPath)\83_Test_Sp_HusoHorario.sql
GO
:r $(ScriptPath)\84_Test_Sp_Sede.sql
GO
:r $(ScriptPath)\85_Test_Seleccion.sql
GO
:r $(ScriptPath)\86_Test_Anunciante.sql
GO
:r $(ScriptPath)\87_Test_Publicidad.sql
GO
:r $(ScriptPath)\89_Test_Partido.sql
GO
:r $(ScriptPath)\90_Test_Alineacion.sql
GO
:r $(ScriptPath)\91_Test_PublicidadPais.sql
GO
:r $(ScriptPath)\92_Test_AnuncianteCampania.sql
GO
:r $(ScriptPath)\93_Test_HistorialPublicidad.sql
GO
:r $(ScriptPath)\95_Test_Gol.sql
GO
:r $(ScriptPath)\96_Test_Sustitucion.sql
GO
:r $(ScriptPath)\97_Test_CambioConvocatoria.sql
GO
:r $(ScriptPath)\98_Test_Trans_Arbitraje.sql
GO
PRINT 'Pruebas antiguas finalizadas. Revisar resultados y errores esperados.';
