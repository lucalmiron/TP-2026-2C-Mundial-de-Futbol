-- Universidad Nacional de La Matanza
-- Bases de datos aplicada
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 08/10/2026
-- Objetivo: Testear Registro, Update y Baja de partido

--Los objetos de negocio (TABLAS y SP) viven en MUNDIAL, el test se ejecuta contra ellos.
--Requiere datos minimos cargados: un Pais, un Mundial (Id 1), un Grupo, dos Selecciones (Id 1 y 2 del Mundial 1), una Fase (Id 1) y una Sede (Id 1).
--El script borra al final el partido y la fase que crea, el resto de los datos son compartidos con los demas tests.
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END
GO

-- Esperado: inserta 1 fila (Fase 1, Mundial 1, Sel 1 vs 2) con marcador 0-0 (el marcador lo mueve Gol)
EXEC SP.uspPartido_Registrar @IdFase=1, @IdSede=1, @IdMundial=1, @Eq1=1, @Eq2=2, @Fecha='2026-06-11', @HoraUTC='16:00', @HoraLocal='13:00', @Asistencia=60000
GO
SELECT IdPartido, IdFase, IdSede, IdMundial, Eq1, Eq2, GolesEq1, GolesEq2, Asistencia FROM partidos.Partido
GO

-- Esperado: PRINT rival propio, 0 filas nuevas
EXEC SP.uspPartido_Registrar @IdFase=1, @IdSede=1, @IdMundial=1, @Eq1=1, @Eq2=1, @Fecha='2026-06-11', @HoraUTC='16:00', @HoraLocal='13:00'
GO
SELECT IdPartido, IdFase, IdSede, IdMundial, Eq1, Eq2, GolesEq1, GolesEq2, Asistencia FROM partidos.Partido
GO

-- Esperado: PRINT inexistente Mundial (99), 0 filas nuevas
EXEC SP.uspPartido_Registrar @IdFase=1, @IdSede=1, @IdMundial=99, @Eq1=1, @Eq2=2, @Fecha='2026-06-11', @HoraUTC='16:00', @HoraLocal='13:00'
GO
SELECT IdPartido, IdFase, IdSede, IdMundial, Eq1, Eq2, GolesEq1, GolesEq2, Asistencia FROM partidos.Partido
GO

-- Esperado: PRINT Eq2 no pertenece al Mundial (99), 0 filas nuevas
EXEC SP.uspPartido_Registrar @IdFase=1, @IdSede=1, @IdMundial=1, @Eq1=1, @Eq2=99, @Fecha='2026-06-11', @HoraUTC='16:00', @HoraLocal='13:00'
GO
SELECT IdPartido, IdFase, IdSede, IdMundial, Eq1, Eq2, GolesEq1, GolesEq2, Asistencia FROM partidos.Partido
GO

-- Esperado: PRINT inexistente Fase (99)
EXEC SP.uspPartido_Registrar @IdFase=99, @IdSede=1, @IdMundial=1, @Eq1=1, @Eq2=2, @Fecha='2026-06-11', @HoraUTC='16:00', @HoraLocal='13:00'
GO
SELECT IdPartido, IdFase, IdSede, IdMundial, Eq1, Eq2, GolesEq1, GolesEq2, Asistencia FROM partidos.Partido
GO

-- Esperado: PRINT duplicado (repite el primero)
EXEC SP.uspPartido_Registrar @IdFase=1, @IdSede=1, @IdMundial=1, @Eq1=1, @Eq2=2, @Fecha='2026-06-11', @HoraUTC='16:00', @HoraLocal='13:00'
GO
SELECT IdPartido, IdFase, IdSede, IdMundial, Eq1, Eq2, GolesEq1, GolesEq2, Asistencia FROM partidos.Partido
GO

-- Esperado: update asistencia a 65000 en Id 1
EXEC SP.uspPartido_Update @Id=1, @Asistencia=65000
GO
SELECT IdPartido, IdFase, IdSede, IdMundial, Eq1, Eq2, GolesEq1, GolesEq2, Asistencia FROM partidos.Partido
GO

-- Esperado: PRINT inexistente Mundial (99), 0 filas modificadas
EXEC SP.uspPartido_Update @Id=1, @IdMundial=99
GO
SELECT IdPartido, IdFase, IdSede, IdMundial, Eq1, Eq2, GolesEq1, GolesEq2, Asistencia FROM partidos.Partido
GO

-- Esperado: PRINT invalido Id (0)
EXEC SP.uspPartido_Update @Id=0, @Asistencia=65000
GO
SELECT IdPartido, IdFase, IdSede, IdMundial, Eq1, Eq2, GolesEq1, GolesEq2, Asistencia FROM partidos.Partido
GO

-- Esperado: PRINT inexistente Partido (99)
EXEC SP.uspPartido_Update @Id=99, @Asistencia=65000
GO
SELECT IdPartido, IdFase, IdSede, IdMundial, Eq1, Eq2, GolesEq1, GolesEq2, Asistencia FROM partidos.Partido
GO

-- Esperado: borra Id 1
EXEC SP.uspPartido_Bajar @Id=1
GO
SELECT IdPartido, IdFase, IdSede, IdMundial, Eq1, Eq2, GolesEq1, GolesEq2, Asistencia FROM partidos.Partido
GO

-- Esperado: PRINT inexistente (99)
EXEC SP.uspPartido_Bajar @Id=99
GO
SELECT IdPartido, IdFase, IdSede, IdMundial, Eq1, Eq2, GolesEq1, GolesEq2, Asistencia FROM partidos.Partido
GO
