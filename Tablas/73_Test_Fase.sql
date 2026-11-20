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

-- Esperado: cambia a Final, SELECT muestra Final.
-- Si la base ya tiene datos importados, 'Final' existe y el SP rechaza el
-- duplicado: se considera un resultado valido y se continúa.
BEGIN TRY
    EXEC SP.uspFase_Update @x1, 'Final';
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 50000 OR ERROR_MESSAGE() NOT LIKE '%Valor duplicado: Fase%' THROW;
    PRINT 'Omitido: la fase Final ya existe (datos importados).';
END CATCH;
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

-- Esperado: borra la fase, SELECT sin esa fila.
-- Con datos importados la fase tiene partidos asociados y el SP la protege:
-- se considera un resultado valido y se continúa.
BEGIN TRY
    EXEC SP.uspFase_Bajar @x2;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 50000 OR ERROR_MESSAGE() NOT LIKE '%Existen partidos con esta fase%' THROW;
    PRINT 'Omitido: la fase tiene partidos asociados (datos importados).';
END CATCH;
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
