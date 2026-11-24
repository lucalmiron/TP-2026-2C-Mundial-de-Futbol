--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Test de los SP de HusoHorario

IF DB_NAME() <> N'MUNDIALtesting'
    THROW 51000, 'Seleccionar la base MUNDIALtesting para estas pruebas.', 1;
GO

--/ALTA

-- Esperado: imprime 'Error/es: - Valor invalido: Nombre.'
BEGIN TRY
    EXEC SP.uspHusoHorario_Registrar @nombre = '';
    THROW 51999, 'Se esperaba que el procedimiento rechazara los datos.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() NOT IN (50000, 51000) THROW;
END CATCH;
GO

-- Esperado: no imprime nada, se insertan 2 filas.
EXEC SP.uspHusoHorario_Registrar @nombre = 'UTC-3';
GO

EXEC SP.uspHusoHorario_Registrar @nombre = 'UTC+1';
GO

-- Esperado: 2 filas.
SELECT * FROM sedes.HusoHorario;
GO

-- Esperado: imprime 'Error/es: - Valor duplicado: Nombre.'
BEGIN TRY
    EXEC SP.uspHusoHorario_Registrar @nombre = 'UTC-3';
    THROW 51999, 'Se esperaba que el procedimiento rechazara los datos.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() NOT IN (50000, 51000) THROW;
END CATCH;
GO

--/UPDATE

-- Esperado: el UTC-3 pasa a Nombre = UTC-3 (America/Argentina).
DECLARE @idPrueba INT = (SELECT IdHuso FROM sedes.HusoHorario WHERE Nombre = 'UTC-3');
EXEC SP.uspHusoHorario_Update @idHuso = @idPrueba, @nombre = 'UTC-3 (America/Argentina)';
GO

-- Esperado: 1 fila con el nombre nuevo.
SELECT * FROM sedes.HusoHorario WHERE Nombre = 'UTC-3 (America/Argentina)';
GO

-- Esperado: imprime 'Error/es: - Valor inexistente: ID HusoHorario.'
BEGIN TRY
    EXEC SP.uspHusoHorario_Update @idHuso = 99, @nombre = 'UTC-9';
    THROW 51999, 'Se esperaba que el procedimiento rechazara los datos.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() NOT IN (50000, 51000) THROW;
END CATCH;
GO

-- Esperado: imprime 'Error/es: - Valor duplicado: Nombre.'
DECLARE @idPrueba INT = (SELECT IdHuso FROM sedes.HusoHorario WHERE Nombre = 'UTC-3 (America/Argentina)');
BEGIN TRY
    EXEC SP.uspHusoHorario_Update @idHuso = @idPrueba, @nombre = 'UTC+1';
    THROW 51999, 'Se esperaba que el procedimiento rechazara los datos.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() NOT IN (50000, 51000) THROW;
END CATCH;
GO

--/BAJA

-- Esperado: imprime 'Error/es: - Valor inexistente: ID HusoHorario.'
BEGIN TRY
    EXEC SP.uspHusoHorario_Bajar @idHuso = 99;
    THROW 51999, 'Se esperaba que el procedimiento rechazara los datos.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() NOT IN (50000, 51000) THROW;
END CATCH;
GO

-- Esperado: se borra la fila, queda 1 fila.
DECLARE @idPrueba INT = (SELECT IdHuso FROM sedes.HusoHorario WHERE Nombre = 'UTC-3 (America/Argentina)');
EXEC SP.uspHusoHorario_Bajar @idHuso = @idPrueba;
GO

SELECT * FROM sedes.HusoHorario;
GO

--/Limpieza de lo que genera el test
DELETE FROM sedes.HusoHorario WHERE Nombre IN ('UTC-3','UTC+1');
GO
