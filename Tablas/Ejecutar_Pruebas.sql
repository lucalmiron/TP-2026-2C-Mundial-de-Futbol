-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Grupo 7
-- Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 25/10/26.
-- Objetivo: ejecutar las pruebas existentes de la entrega 5.
-- Ejecutar despues de 00_Ejecutar_Todo.sql en una instancia de pruebas.
-- Los scripts incluidos modifican MUNDIAL: usar una instancia exclusiva de pruebas.
-- Se continua ante errores porque hay rechazos esperados sin TRY/CATCH.
-- Revisar cada resultado: llegar al final no significa que todas las pruebas pasaron.
-- Ejecutar con sqlcmd desde la carpeta Tablas.
-- En SSMS, activar modo SQLCMD y cambiar ScriptPath por la ruta de Tablas.
-- Mantener las comillas si la ruta contiene espacios.
:setvar ScriptPath "."

:ON ERROR IGNORE

-- 70_Test_Club.sql: ejecutar por separado en una base vacia MUNDIAL_Final_Test*.
GO
-- 71_Test_IdiomaReporte.sql: ejecutar por separado en una base vacia MUNDIAL_Final_Test*.
GO
-- 72_Test_Persona.sql: ejecutar por separado en una base vacia MUNDIAL_Final_Test*.
GO
:r $(ScriptPath)\73_Test_Fase.sql
GO
:r $(ScriptPath)\74_Test_Partido.sql
GO
:r $(ScriptPath)\75_Test_Alineacion.sql
GO
-- 76_Test_Sp_Amonestacion.sql: ejecutar por separado en una base vacia MUNDIAL_Final_Test*.
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

-- Pruebas independientes: 70, 71, 72, 76 y 96_Test_Publicidad_Automatica,
-- 96_Test_Periodo y 96_Test_Evento requieren cada una una base vacia MUNDIAL_Final_Test*.
-- Instalar las tablas y SP reales (03 a 69) apuntando a esa base antes de ejecutarlas.
-- No contienen copias de los SP. Su preparacion se detiene si la base contiene datos.
-- 96_Test_Validaciones comprueba entradas invalidas sobre esos mismos SP.
-- Los restantes 96_Test_* conservan el nombre de base de prueba indicado en su encabezado.
