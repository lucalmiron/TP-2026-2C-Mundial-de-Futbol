-- Ejecutar en modo SQLCMD. Cada prueba corre en una base nueva.
:setvar ScriptPath "C:\Users\Administrator\Desktop\tp_bdda\TP-2026-2C-Mundial-de-Futbol\Tablas"
:ON ERROR EXIT

:setvar BasePrueba "MUNDIAL_Final_Test_E5"
PRINT 'Ejecutando 72_Test_Pais.sql';
GO
:r $(ScriptPath)\Auxiliar\Preparar.sql
:r $(ScriptPath)\72_Test_Pais.sql
GO
:r $(ScriptPath)\Auxiliar\Finalizar.sql

:setvar BasePrueba "MUNDIAL_Final_Test_E5"
PRINT 'Ejecutando 73_Test_Grupo.sql';
GO
:r $(ScriptPath)\Auxiliar\Preparar.sql
:r $(ScriptPath)\73_Test_Grupo.sql
GO
:r $(ScriptPath)\Auxiliar\Finalizar.sql

:setvar BasePrueba "MUNDIAL_Final_Test_E5"
PRINT 'Ejecutando 74_Test_Aux_Club.sql';
GO
:r $(ScriptPath)\Auxiliar\Preparar.sql
:r $(ScriptPath)\74_Test_Aux_Club.sql
GO
:r $(ScriptPath)\Auxiliar\Finalizar.sql

:setvar BasePrueba "MUNDIAL_Final_Test_E5"
PRINT 'Ejecutando 75_Test_Aux_IdiomaReporte.sql';
GO
:r $(ScriptPath)\Auxiliar\Preparar.sql
:r $(ScriptPath)\75_Test_Aux_IdiomaReporte.sql
GO
:r $(ScriptPath)\Auxiliar\Finalizar.sql

:setvar BasePrueba "MUNDIAL_Final_Test_E5"
PRINT 'Ejecutando 77_Test_Aux_Periodo.sql';
GO
:r $(ScriptPath)\Auxiliar\Preparar.sql
:r $(ScriptPath)\77_Test_Aux_Periodo.sql
GO
:r $(ScriptPath)\Auxiliar\Finalizar.sql

:setvar BasePrueba "MUNDIAL_Final_Test_E5"
PRINT 'Ejecutando 78_Test_Sp_EspacioPublicitario.sql';
GO
:r $(ScriptPath)\Auxiliar\Preparar.sql
:r $(ScriptPath)\78_Test_Sp_EspacioPublicitario.sql
GO
:r $(ScriptPath)\Auxiliar\Finalizar.sql

:setvar BasePrueba "MUNDIAL_Final_Test_E5"
PRINT 'Ejecutando 79_Test_Sp_CostoFranja.sql';
GO
:r $(ScriptPath)\Auxiliar\Preparar.sql
:r $(ScriptPath)\79_Test_Sp_CostoFranja.sql
GO
:r $(ScriptPath)\Auxiliar\Finalizar.sql

:setvar BasePrueba "MUNDIAL_Final_Test_E5"
PRINT 'Ejecutando 82_Test_Mundial.sql';
GO
:r $(ScriptPath)\Auxiliar\Preparar.sql
:r $(ScriptPath)\82_Test_Mundial.sql
GO
:r $(ScriptPath)\Auxiliar\Finalizar.sql

:setvar BasePrueba "MUNDIAL_Final_Test_E5"
PRINT 'Ejecutando 84_Test_Sp_Sede.sql';
GO
:r $(ScriptPath)\Auxiliar\Preparar.sql
:r $(ScriptPath)\84_Test_Sp_Sede.sql
GO
:r $(ScriptPath)\Auxiliar\Finalizar.sql

:setvar BasePrueba "MUNDIAL_Final_Test_E5"
PRINT 'Ejecutando 85_Test_Seleccion.sql';
GO
:r $(ScriptPath)\Auxiliar\Preparar.sql
:r $(ScriptPath)\85_Test_Seleccion.sql
GO
:r $(ScriptPath)\Auxiliar\Finalizar.sql

:setvar BasePrueba "MUNDIAL_Final_Test_E5"
PRINT 'Ejecutando 86_Test_Anunciante.sql';
GO
:r $(ScriptPath)\Auxiliar\Preparar.sql
:r $(ScriptPath)\86_Test_Anunciante.sql
GO
:r $(ScriptPath)\Auxiliar\Finalizar.sql

:setvar BasePrueba "MUNDIAL_Final_Test_E5"
PRINT 'Ejecutando 87_Test_Publicidad.sql';
GO
:r $(ScriptPath)\Auxiliar\Preparar.sql
:r $(ScriptPath)\87_Test_Publicidad.sql
GO
:r $(ScriptPath)\Auxiliar\Finalizar.sql

:setvar BasePrueba "MUNDIAL_Final_Test_E5"
PRINT 'Ejecutando 88_Test_Aux_Persona.sql';
GO
:r $(ScriptPath)\Auxiliar\Preparar.sql
:r $(ScriptPath)\88_Test_Aux_Persona.sql
GO
:r $(ScriptPath)\Auxiliar\Finalizar.sql

:setvar BasePrueba "MUNDIAL_Final_Test_E5"
PRINT 'Ejecutando 89_Test_Partido.sql';
GO
:r $(ScriptPath)\Auxiliar\Preparar.sql
:r $(ScriptPath)\89_Test_Partido.sql
GO
:r $(ScriptPath)\Auxiliar\Finalizar.sql

:setvar BasePrueba "MUNDIAL_Final_Test_E5"
PRINT 'Ejecutando 90_Test_Alineacion.sql';
GO
:r $(ScriptPath)\Auxiliar\Preparar.sql
:r $(ScriptPath)\90_Test_Alineacion.sql
GO
:r $(ScriptPath)\Auxiliar\Finalizar.sql

:setvar BasePrueba "MUNDIAL_Final_Test_E5"
PRINT 'Ejecutando 91_Test_PublicidadPais.sql';
GO
:r $(ScriptPath)\Auxiliar\Preparar.sql
:r $(ScriptPath)\91_Test_PublicidadPais.sql
GO
:r $(ScriptPath)\Auxiliar\Finalizar.sql

:setvar BasePrueba "MUNDIAL_Final_Test_E5"
PRINT 'Ejecutando 92_Test_AnuncianteCampania.sql';
GO
:r $(ScriptPath)\Auxiliar\Preparar.sql
:r $(ScriptPath)\92_Test_AnuncianteCampania.sql
GO
:r $(ScriptPath)\Auxiliar\Finalizar.sql

:setvar BasePrueba "MUNDIAL_Final_Test_E5"
PRINT 'Ejecutando 93_Test_HistorialPublicidad.sql';
GO
:r $(ScriptPath)\Auxiliar\Preparar.sql
:r $(ScriptPath)\93_Test_HistorialPublicidad.sql
GO
:r $(ScriptPath)\Auxiliar\Finalizar.sql

:setvar BasePrueba "MUNDIAL_Final_Test_E5"
PRINT 'Ejecutando 94_Test_Aux_Sp_Amonestacion.sql';
GO
:r $(ScriptPath)\Auxiliar\Preparar.sql
:r $(ScriptPath)\94_Test_Aux_Sp_Amonestacion.sql
GO
:r $(ScriptPath)\Auxiliar\Finalizar.sql

:setvar BasePrueba "MUNDIAL_Final_Test_E5"
PRINT 'Ejecutando 95_Test_Gol.sql';
GO
:r $(ScriptPath)\Auxiliar\Preparar.sql
:r $(ScriptPath)\95_Test_Gol.sql
GO
:r $(ScriptPath)\Auxiliar\Finalizar.sql

:setvar BasePrueba "MUNDIAL_Final_Test_E5"
PRINT 'Ejecutando 96_Test_Sustitucion.sql';
GO
:r $(ScriptPath)\Auxiliar\Preparar.sql
:r $(ScriptPath)\96_Test_Sustitucion.sql
GO
:r $(ScriptPath)\Auxiliar\Finalizar.sql

:setvar BasePrueba "MUNDIAL_Final_Test_E5"
PRINT 'Ejecutando 97_Test_CambioConvocatoria.sql';
GO
:r $(ScriptPath)\Auxiliar\Preparar.sql
:r $(ScriptPath)\97_Test_CambioConvocatoria.sql
GO
:r $(ScriptPath)\Auxiliar\Finalizar.sql

:setvar BasePrueba "MUNDIAL_Final_Test_E5"
PRINT 'Ejecutando 98_Test_Trans_Arbitraje.sql';
GO
:r $(ScriptPath)\Auxiliar\Preparar.sql
:r $(ScriptPath)\98_Test_Trans_Arbitraje.sql
GO
:r $(ScriptPath)\Auxiliar\Finalizar.sql

:setvar BasePrueba "MUNDIAL_Final_Test_E5"
PRINT 'Ejecutando 99_Test_Aux_Evento.sql';
GO
:r $(ScriptPath)\Auxiliar\Preparar.sql
:r $(ScriptPath)\99_Test_Aux_Evento.sql
GO
:r $(ScriptPath)\Auxiliar\Finalizar.sql

:setvar BasePrueba "MUNDIAL_Grupo2_Test_E5"
PRINT 'Ejecutando 100_Test_Aux_Eventos_Alineaciones.sql';
GO
:r $(ScriptPath)\Auxiliar\Preparar.sql
:r $(ScriptPath)\100_Test_Aux_Eventos_Alineaciones.sql
GO
:r $(ScriptPath)\Auxiliar\Finalizar.sql

:setvar BasePrueba "MUNDIAL_Grupo3_Test_E5"
PRINT 'Ejecutando 101_Test_Aux_Jugadores_Convocatorias.sql';
GO
:r $(ScriptPath)\Auxiliar\Preparar.sql
:r $(ScriptPath)\101_Test_Aux_Jugadores_Convocatorias.sql
GO
:r $(ScriptPath)\Auxiliar\Finalizar.sql

:setvar BasePrueba "MUNDIAL_Grupo4_Test_E5"
PRINT 'Ejecutando 102_Test_Aux_Partidos_Arbitraje.sql';
GO
:r $(ScriptPath)\Auxiliar\Preparar.sql
:r $(ScriptPath)\102_Test_Aux_Partidos_Arbitraje.sql
GO
:r $(ScriptPath)\Auxiliar\Finalizar.sql

:setvar BasePrueba "MUNDIAL_Horarios_Test_E5"
PRINT 'Ejecutando 103_Test_Aux_Horarios.sql';
GO
:r $(ScriptPath)\Auxiliar\Preparar.sql
:r $(ScriptPath)\103_Test_Aux_Horarios.sql
GO
:r $(ScriptPath)\Auxiliar\Finalizar.sql

:setvar BasePrueba "MUNDIAL_Final_Test_E5"
PRINT 'Ejecutando 104_Test_Aux_Publicidad_Automatica.sql';
GO
:r $(ScriptPath)\Auxiliar\Preparar.sql
:r $(ScriptPath)\104_Test_Aux_Publicidad_Automatica.sql
GO
:r $(ScriptPath)\Auxiliar\Finalizar.sql

:setvar BasePrueba "MUNDIAL_Final_Test_E5"
PRINT 'Ejecutando 105_Test_Aux_Sede_Capacidad.sql';
GO
:r $(ScriptPath)\Auxiliar\Preparar.sql
:r $(ScriptPath)\105_Test_Aux_Sede_Capacidad.sql
GO
:r $(ScriptPath)\Auxiliar\Finalizar.sql

:setvar BasePrueba "MUNDIAL_Final_Test_E5"
PRINT 'Ejecutando 106_Test_Aux_Tanda.sql';
GO
:r $(ScriptPath)\Auxiliar\Preparar.sql
:r $(ScriptPath)\106_Test_Aux_Tanda.sql
GO
:r $(ScriptPath)\Auxiliar\Finalizar.sql

:setvar BasePrueba "MUNDIAL_Final_Test_E5"
PRINT 'Ejecutando 107_Test_Aux_Validaciones.sql';
GO
:r $(ScriptPath)\Auxiliar\Preparar.sql
:r $(ScriptPath)\107_Test_Aux_Validaciones.sql
GO
:r $(ScriptPath)\Auxiliar\Finalizar.sql

:setvar BasePrueba "MUNDIAL_Grupo2_Test_E5"
PRINT 'Ejecutando 108_Test_Aux_Descanso.sql';
GO
:r $(ScriptPath)\Auxiliar\Preparar.sql
:r $(ScriptPath)\108_Test_Aux_Descanso.sql
GO
:r $(ScriptPath)\Auxiliar\Finalizar.sql

PRINT 'Etapa 4 finalizada.';
GO
