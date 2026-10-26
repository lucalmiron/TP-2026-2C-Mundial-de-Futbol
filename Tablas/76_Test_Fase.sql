-- Universidad Nacional de La Matanza
-- Bases de datos aplicada 
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 26/10/26
-- Objetivo: Testear Registro, Update y Baja de Fase

--Los objetos de negocio (TABLAS y SP) viven en MUNDIAL, el test se ejecuta contra ellos.
--El test arma su propio juego de datos y lo borra al final, asi se puede ejecutar mas de una vez.
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

--/ALTA

-- Esperado: registra la fase Grupos, 1 fila
IF NOT EXISTS (SELECT 1 FROM partidos.Fase WHERE Descripcion = 'Grupos')
	EXEC SP.uspFase_Registrar 'Grupos';
GO
SELECT * FROM partidos.Fase;
GO

-- Esperado: descripcion invalida (solo las del catalogo), 0 filas nuevas
EXEC SP.uspFase_Registrar 'Amistoso';
GO
SELECT * FROM partidos.Fase;
GO

-- Esperado: descripcion nula, 0 filas nuevas
EXEC SP.uspFase_Registrar NULL;
GO
SELECT * FROM partidos.Fase;
GO

-- Esperado: fase duplicada, 0 filas nuevas
EXEC SP.uspFase_Registrar 'Grupos';
GO
SELECT * FROM partidos.Fase;
GO

--/UPDATE

DECLARE @x1 INT = (SELECT MIN(IdFase) FROM partidos.Fase WHERE Descripcion = 'Grupos');

-- Esperado: cambia a Final, SELECT muestra Final
EXEC SP.uspFase_Update @x1, 'Final';
GO
SELECT * FROM partidos.Fase;
GO

-- Esperado: id invalido (0), 0 filas modificadas
EXEC SP.uspFase_Update 0, 'Grupos';
GO
SELECT * FROM partidos.Fase;
GO

-- Esperado: id inexistente (99), 0 filas modificadas
EXEC SP.uspFase_Update 99, 'Grupos';
GO
SELECT * FROM partidos.Fase;
GO

--/BAJA

DECLARE @x2 INT = (SELECT MIN(IdFase) FROM partidos.Fase WHERE Descripcion = 'Final');

-- Esperado: borra la fase, SELECT sin esa fila
EXEC SP.uspFase_Bajar @x2;
GO
SELECT * FROM partidos.Fase;
GO

-- Esperado: id inexistente (99), 0 borradas
EXEC SP.uspFase_Bajar 99;
GO
SELECT * FROM partidos.Fase;
GO

-- Esperado: no queda ninguna fase del test.
SELECT * FROM partidos.Fase;
GO
