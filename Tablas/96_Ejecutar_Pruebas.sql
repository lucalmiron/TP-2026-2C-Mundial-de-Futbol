-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Grupo 7
-- Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 25/10/2026.
-- Objetivo: ejecutar las pruebas existentes de la entrega 5.
-- Ejecutar despues de 00_Ejecutar_Todo.sql en una instancia de pruebas.
-- Algunos scripts modifican MUNDIAL y otros MUNDIALtesting.
-- Se continua ante errores porque hay rechazos esperados sin TRY/CATCH.
-- Revisar cada resultado: llegar al final no significa que todas las pruebas pasaron.
-- Ejecutar con sqlcmd desde la carpeta Tablas.
-- En SSMS, activar modo SQLCMD y cambiar ScriptPath por la ruta de Tablas.
-- Mantener las comillas si la ruta contiene espacios.
:setvar ScriptPath "."

:ON ERROR IGNORE

:r $(ScriptPath)\70_Test_Club.sql
GO
:r $(ScriptPath)\71_Test_IdiomaReporte.sql
GO
:r $(ScriptPath)\72_Test_Persona.sql
GO
:r $(ScriptPath)\73_Test_Fase.sql
GO
:r $(ScriptPath)\74_Test_Partido.sql
GO
:r $(ScriptPath)\75_Test_Alineacion.sql
GO
:r $(ScriptPath)\76_Test_Sp_Amonestacion.sql
GO
:r $(ScriptPath)\77_Test_Sp_Sede.sql
GO
:r $(ScriptPath)\78_Test_Sp_EspacioPublicitario.sql
GO
:r $(ScriptPath)\79_Test_Sp_HusoHorario.sql
GO
:r $(ScriptPath)\80_Test_Motivo.sql
GO
:r $(ScriptPath)\81_Test_Campania.sql
GO
:r $(ScriptPath)\82_Test_Anunciante.sql
GO
:r $(ScriptPath)\83_Test_Publicidad.sql
GO
:r $(ScriptPath)\84_Test_HistorialPublicidad.sql
GO
:r $(ScriptPath)\85_Test_Gol.sql
GO
:r $(ScriptPath)\86_Test_Sustitucion.sql
GO
:r $(ScriptPath)\87_Test_CambioConvocatoria.sql
GO
:r $(ScriptPath)\88_Test_Grupo.sql
GO
:r $(ScriptPath)\89_Test_Mundial.sql
GO
:r $(ScriptPath)\90_Test_PublicidadPais.sql
GO
:r $(ScriptPath)\91_Test_AnuncianteCampania.sql
GO
:r $(ScriptPath)\92_Test_Sp_CostoFranja.sql
GO
:r $(ScriptPath)\93_Test_Pais.sql
GO
:r $(ScriptPath)\94_Test_Seleccion.sql
GO
:r $(ScriptPath)\95_Test_Trans_Arbitraje.sql
GO

PRINT 'Ejecucion de pruebas finalizada. Revisar resultados y errores esperados.';
