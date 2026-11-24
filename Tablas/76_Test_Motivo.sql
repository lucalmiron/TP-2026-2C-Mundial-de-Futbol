-- Universidad Nacional de La Matanza
-- Bases de datos aplicada
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 26/10/26
-- Objetivo: Testear Registro, Update y Baja de Motivo

--Sin prerrequisitos.
IF DB_NAME() <> N'MUNDIALtesting'
    THROW 51000, 'Seleccionar la base MUNDIALtesting para estas pruebas.', 1;
GO

-- Esperado: inserta 1 fila
EXEC SP.uspMotivo_Registrar 'Tactico'
GO
SELECT * FROM publicidad.Motivo
GO

-- Esperado: PRINT nulo, 0 filas nuevas
BEGIN TRY
    EXEC SP.uspMotivo_Registrar NULL;
    THROW 51999, 'Se esperaba que el procedimiento rechazara los datos.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() NOT IN (50000, 51000) THROW;
END CATCH;
GO
SELECT * FROM publicidad.Motivo
GO

-- Esperado: PRINT duplicado, 0 filas nuevas
BEGIN TRY
    EXEC SP.uspMotivo_Registrar 'Tactico';
    THROW 51999, 'Se esperaba que el procedimiento rechazara los datos.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() NOT IN (50000, 51000) THROW;
END CATCH;
GO
SELECT * FROM publicidad.Motivo
GO

-- Esperado: update a Lesion
DECLARE @idPrueba INT = (SELECT IdMotivo FROM publicidad.Motivo WHERE Descripcion = 'Tactico');
EXEC SP.uspMotivo_Update @idPrueba, 'Lesion'
GO
SELECT * FROM publicidad.Motivo
GO

-- Esperado: PRINT inexistente Id (99)
BEGIN TRY
    EXEC SP.uspMotivo_Update 99, 'Lesion';
    THROW 51999, 'Se esperaba que el procedimiento rechazara los datos.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() NOT IN (50000, 51000) THROW;
END CATCH;
GO
SELECT * FROM publicidad.Motivo
GO

-- Esperado: borra Id 1
DECLARE @idPrueba INT = (SELECT IdMotivo FROM publicidad.Motivo WHERE Descripcion = 'Lesion');
EXEC SP.uspMotivo_Bajar @idPrueba
GO
SELECT * FROM publicidad.Motivo
GO

-- Esperado: PRINT inexistente (99), 0 borradas
BEGIN TRY
    EXEC SP.uspMotivo_Bajar 99;
    THROW 51999, 'Se esperaba que el procedimiento rechazara los datos.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() NOT IN (50000, 51000) THROW;
END CATCH;
GO
SELECT * FROM publicidad.Motivo
GO