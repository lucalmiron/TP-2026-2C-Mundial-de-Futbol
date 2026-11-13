-- Universidad Nacional de La Matanza
-- Bases de datos aplicada 
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 26/10/26
-- Objetivo: Testear Registro, Update y Baja de Fase

--El test arma su propio juego de datos y lo borra al final, asi se puede ejecutar mas de una vez.
IF DB_NAME() <> N'MUNDIALtesting'
    THROW 51000, 'Seleccionar la base MUNDIALtesting para estas pruebas.', 1;
GO

--/ALTA

-- Esperado: registra la fase Grupos, 1 fila
IF NOT EXISTS (SELECT 1 FROM partidos.Fase WHERE Descripcion = 'Grupos')
	EXEC SP.uspFase_Registrar 'Grupos';
GO
SELECT * FROM partidos.Fase;
GO

-- Esperado: descripcion invalida (solo las del catalogo), 0 filas nuevas
BEGIN TRY
    EXEC SP.uspFase_Registrar 'Amistoso';
    THROW 51999, 'Se esperaba que el procedimiento rechazara los datos.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() NOT IN (50000, 51000) THROW;
END CATCH;
GO
SELECT * FROM partidos.Fase;
GO

-- Esperado: descripcion nula, 0 filas nuevas
BEGIN TRY
    EXEC SP.uspFase_Registrar NULL;
    THROW 51999, 'Se esperaba que el procedimiento rechazara los datos.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() NOT IN (50000, 51000) THROW;
END CATCH;
GO
SELECT * FROM partidos.Fase;
GO

-- Esperado: fase duplicada, 0 filas nuevas
BEGIN TRY
    EXEC SP.uspFase_Registrar 'Grupos';
    THROW 51999, 'Se esperaba que el procedimiento rechazara los datos.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() NOT IN (50000, 51000) THROW;
END CATCH;
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
BEGIN TRY
    EXEC SP.uspFase_Update 0, 'Grupos';
    THROW 51999, 'Se esperaba que el procedimiento rechazara los datos.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() NOT IN (50000, 51000) THROW;
END CATCH;
GO
SELECT * FROM partidos.Fase;
GO

-- Esperado: id inexistente (99), 0 filas modificadas
BEGIN TRY
    EXEC SP.uspFase_Update 99, 'Grupos';
    THROW 51999, 'Se esperaba que el procedimiento rechazara los datos.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() NOT IN (50000, 51000) THROW;
END CATCH;
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
BEGIN TRY
    EXEC SP.uspFase_Bajar 99;
    THROW 51999, 'Se esperaba que el procedimiento rechazara los datos.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() NOT IN (50000, 51000) THROW;
END CATCH;
GO
SELECT * FROM partidos.Fase;
GO

-- Esperado: no queda ninguna fase del test.
SELECT * FROM partidos.Fase;
GO
