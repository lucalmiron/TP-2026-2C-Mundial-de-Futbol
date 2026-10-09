-- Universidad Nacional de La Matanza
-- Bases de datos aplicada
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 08/10/2026
-- Objetivo: Testear Registro y Baja de CambioConvocatoria

--Los objetos de negocio viven en MUNDIAL, el test se ejecuta contra ellos.
--Requiere Seleccion 1 con Jugador 1 Activo (egreso) y Jugador 2 Inactivo (ingreso).
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END
GO

-- Esperado: registra el cambio, egreso Inactivo e ingreso Activo
EXEC SPTRANS.uspCambioConvocatoria_Registrar 1, 1, 2, '2026-06-01', 'Lesion muscular'
GO
SELECT * FROM TABLAS.CambioConvocatoria
GO
SELECT IdJugador, Estado FROM TABLAS.Jugador WHERE IdJugador IN (1, 2)
GO

-- Esperado: PRINT egreso e ingreso iguales, 0 filas nuevas
EXEC SPTRANS.uspCambioConvocatoria_Registrar 1, 1, 1, '2026-06-01', 'Lesion muscular'
GO
SELECT * FROM TABLAS.CambioConvocatoria
GO

-- Esperado: PRINT motivo nulo, 0 filas nuevas
EXEC SPTRANS.uspCambioConvocatoria_Registrar 1, 1, 2, '2026-06-01', NULL
GO
SELECT * FROM TABLAS.CambioConvocatoria
GO

-- Esperado: PRINT egreso no activo (ya salio), 0 filas nuevas
EXEC SPTRANS.uspCambioConvocatoria_Registrar 1, 1, 2, '2026-06-02', 'Recaida'
GO
SELECT * FROM TABLAS.CambioConvocatoria
GO

-- Esperado: PRINT inexistente Seleccion (99), 0 filas nuevas
EXEC SPTRANS.uspCambioConvocatoria_Registrar 99, 1, 2, '2026-06-01', 'Lesion muscular'
GO
SELECT * FROM TABLAS.CambioConvocatoria
GO

-- Esperado: revierte estados y borra Id 1
EXEC SPTRANS.uspCambioConvocatoria_Bajar 1
GO
SELECT * FROM TABLAS.CambioConvocatoria
GO
SELECT IdJugador, Estado FROM TABLAS.Jugador WHERE IdJugador IN (1, 2)
GO

-- Esperado: PRINT inexistente (99), 0 borradas
EXEC SPTRANS.uspCambioConvocatoria_Bajar 99
GO
SELECT * FROM TABLAS.CambioConvocatoria
GO