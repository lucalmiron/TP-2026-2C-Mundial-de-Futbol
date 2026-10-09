-- Universidad Nacional de La Matanza
-- Bases de datos aplicada
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 08/10/2026
-- Objetivo: Testear Registro y Baja de Gol

--Los objetos de negocio (TABLAS y SP) viven en MUNDIAL, el test se ejecuta contra ellos.
--Requiere Partido 1 (Eq1 1, Eq2 2, GolesEq1 0, GolesEq2 0), Periodo 1 (1erTiempo) y Jugador 1 de Seleccion 1 y Jugador 2 de Seleccion 2.
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END
GO

-- Esperado: inserta gol de jugada con asistencia, 1 fila en Evento y Gol, GolesEq1 = 1 (autor de Sel 1)
EXEC SPTRANS.uspGol_Registrar @minuto = 23, @partido = 1, @periodo = 1, @autor = 1, @asistencia = 2, @tipo = 'Jugada'
GO
SELECT * FROM partidos.Evento WHERE Tipo = 'Gol'
GO
SELECT * FROM partidos.Gol
GO
SELECT IdPartido, Eq1, Eq2, GolesEq1, GolesEq2 FROM partidos.Partido WHERE IdPartido = 1
GO

-- Esperado: PRINT autor y asistencia iguales, 0 filas nuevas, marcador sin cambios
EXEC SPTRANS.uspGol_Registrar @minuto = 30, @partido = 1, @periodo = 1, @autor = 1, @asistencia = 1, @tipo = 'Jugada'
GO
SELECT * FROM partidos.Gol
GO
SELECT IdPartido, Eq1, Eq2, GolesEq1, GolesEq2 FROM partidos.Partido WHERE IdPartido = 1
GO

-- Esperado: PRINT en contra con asistencia, 0 filas nuevas, marcador sin cambios
EXEC SPTRANS.uspGol_Registrar @minuto = 40, @partido = 1, @periodo = 1, @autor = 1, @asistencia = 2, @tipo = 'En contra'
GO
SELECT * FROM partidos.Gol
GO
SELECT IdPartido, Eq1, Eq2, GolesEq1, GolesEq2 FROM partidos.Partido WHERE IdPartido = 1
GO

-- Esperado: inserta gol en contra sin asistencia del autor de Sel 2, GolesEq1 = 2 (suma al rival)
EXEC SPTRANS.uspGol_Registrar @minuto = 45, @partido = 1, @periodo = 1, @autor = 2, @asistencia = NULL, @tipo = 'En contra'
GO
SELECT * FROM partidos.Gol
GO
SELECT IdPartido, Eq1, Eq2, GolesEq1, GolesEq2 FROM partidos.Partido WHERE IdPartido = 1
GO

-- Esperado: PRINT tipo invalido (Chilena es tecnica, no situacion), 0 filas nuevas, marcador sin cambios
EXEC SPTRANS.uspGol_Registrar @minuto = 50, @partido = 1, @periodo = 1, @autor = 1, @asistencia = NULL, @tipo = 'Chilena'
GO
SELECT * FROM partidos.Gol
GO
SELECT IdPartido, Eq1, Eq2, GolesEq1, GolesEq2 FROM partidos.Partido WHERE IdPartido = 1
GO

-- Esperado: PRINT inexistente Autor (99), 0 filas nuevas, marcador sin cambios
EXEC SPTRANS.uspGol_Registrar @minuto = 60, @partido = 1, @periodo = 1, @autor = 99, @asistencia = NULL, @tipo = 'Penal'
GO
SELECT * FROM partidos.Gol
GO
SELECT IdPartido, Eq1, Eq2, GolesEq1, GolesEq2 FROM partidos.Partido WHERE IdPartido = 1
GO

-- Esperado: borra el gol en contra y descuenta 1 del rival, GolesEq1 = 1
EXEC SPTRANS.uspGol_Bajar @id = 2
GO
SELECT * FROM partidos.Gol
GO
SELECT IdPartido, Eq1, Eq2, GolesEq1, GolesEq2 FROM partidos.Partido WHERE IdPartido = 1
GO

-- Esperado: borra Id 1 de Gol y Evento y descuenta 1, GolesEq1 = 0
EXEC SPTRANS.uspGol_Bajar @id = 1
GO
SELECT * FROM partidos.Gol
GO
SELECT IdPartido, Eq1, Eq2, GolesEq1, GolesEq2 FROM partidos.Partido WHERE IdPartido = 1
GO

-- Esperado: PRINT inexistente (99), 0 borradas, marcador sin cambios
EXEC SPTRANS.uspGol_Bajar @id = 99
GO
SELECT * FROM partidos.Gol
GO
SELECT IdPartido, Eq1, Eq2, GolesEq1, GolesEq2 FROM partidos.Partido WHERE IdPartido = 1
GO
