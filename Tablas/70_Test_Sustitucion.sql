-- Universidad Nacional de La Matanza
-- Bases de datos aplicada
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 08/10/2026
-- Objetivo: Testear Registro y Baja de Sustitucion

--Los objetos de negocio (TABLAS y SP) viven en MUNDIAL, el test se ejecuta contra ellos.
--Requiere Partido 1, Periodo 1, Jugadores 1 (titular) y 2 (suplente) de la misma seleccion, Motivo 1.
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

-- Esperado: inserta sustitucion, 1 fila en Evento y Sustitucion
EXEC SPTRANS.uspSustitucion_Registrar @minuto = 60, @partido = 1, @periodo = 1, @ingreso = 2, @egreso = 1, @motivo = 1
GO
SELECT * FROM partidos.Evento WHERE Tipo = 'Sustitucion'
GO
SELECT * FROM partidos.Sustitucion
GO

-- Esperado: PRINT ingreso igual a egreso, 0 filas nuevas
EXEC SPTRANS.uspSustitucion_Registrar @minuto = 65, @partido = 1, @periodo = 1, @ingreso = 2, @egreso = 2, @motivo = 1
GO
SELECT * FROM partidos.Sustitucion
GO

-- Esperado: PRINT inexistente Motivo (99), 0 filas nuevas
EXEC SPTRANS.uspSustitucion_Registrar @minuto = 70, @partido = 1, @periodo = 1, @ingreso = 2, @egreso = 1, @motivo = 99
GO
SELECT * FROM partidos.Sustitucion
GO

-- Esperado: PRINT inexistente Partido (99), 0 filas nuevas
EXEC SPTRANS.uspSustitucion_Registrar @minuto = 70, @partido = 99, @periodo = 1, @ingreso = 2, @egreso = 1, @motivo = 1
GO
SELECT * FROM partidos.Sustitucion
GO

-- Esperado: borra Id 1 de Sustitucion y Evento
EXEC SPTRANS.uspSustitucion_Bajar @id = 1
GO
SELECT * FROM partidos.Sustitucion
GO

-- Esperado: PRINT inexistente (99), 0 borradas
EXEC SPTRANS.uspSustitucion_Bajar @id = 99
GO
SELECT * FROM partidos.Sustitucion
GO