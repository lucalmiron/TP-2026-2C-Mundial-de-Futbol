-- Universidad Nacional de La Matanza
-- Bases de datos aplicada
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 26/10/26
-- Objetivo: Testear Registro, Update y Baja de Campania

--Sin prerrequisitos.
IF DB_NAME() <> N'MUNDIALtesting'
    THROW 51000, 'Seleccionar la base MUNDIALtesting para estas pruebas.', 1;
GO

-- Esperado: inserta 1 fila
EXEC SP.uspCampania_Registrar 'Qatar 2026', 'Campania mundialista'
GO
SELECT * FROM publicidad.Campania
GO

-- Esperado: PRINT nulo, 0 filas nuevas
BEGIN TRY
    EXEC SP.uspCampania_Registrar NULL, 'Campania mundialista';
    THROW 51999, 'Se esperaba que el procedimiento rechazara los datos.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() NOT IN (50000, 51000) THROW;
END CATCH;
GO
SELECT * FROM publicidad.Campania
GO

-- Esperado: update 1
DECLARE @idPrueba INT = (SELECT IdCampania FROM publicidad.Campania WHERE Nombre = 'Qatar 2026');
EXEC SP.uspCampania_Update @idPrueba, 'Qatar 2026', 'Descripcion nueva'
GO
SELECT * FROM publicidad.Campania
GO

-- Esperado: PRINT inexistente Id (99)
BEGIN TRY
    EXEC SP.uspCampania_Update 99, 'Qatar 2026', 'Descripcion nueva';
    THROW 51999, 'Se esperaba que el procedimiento rechazara los datos.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() NOT IN (50000, 51000) THROW;
END CATCH;
GO
SELECT * FROM publicidad.Campania
GO

-- Esperado: borra Id 1
DECLARE @idPrueba INT = (SELECT IdCampania FROM publicidad.Campania WHERE Nombre = 'Qatar 2026');
EXEC SP.uspCampania_Bajar @idPrueba
GO
SELECT * FROM publicidad.Campania
GO

-- Esperado: PRINT inexistente (99), 0 borradas
BEGIN TRY
    EXEC SP.uspCampania_Bajar 99;
    THROW 51999, 'Se esperaba que el procedimiento rechazara los datos.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() NOT IN (50000, 51000) THROW;
END CATCH;
GO
SELECT * FROM publicidad.Campania
GO