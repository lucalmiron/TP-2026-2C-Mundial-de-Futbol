--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Test de los SP de Pais

IF DB_NAME() NOT LIKE 'MUNDIAL[_]Final[_]Test%'
    THROW 51000, 'Seleccionar la base aislada de pruebas.', 1;
GO

--/Datos de prueba: 
--2 idiomas
IF NOT EXISTS (SELECT 1 FROM arbitros.Idioma WHERE Descripcion = 'Idioma_Test_SpPais1')
	EXEC SP.uspIdioma_Registrar @descripcion = 'Idioma_Test_SpPais1';
GO
IF NOT EXISTS (SELECT 1 FROM arbitros.Idioma WHERE Descripcion = 'Idioma_Test_SpPais2')
	EXEC SP.uspIdioma_Registrar @descripcion = 'Idioma_Test_SpPais2';
GO
--2 husos horarios
IF NOT EXISTS (SELECT 1 FROM sedes.HusoHorario WHERE NOMBRE = 'Huso_Test_SpPais1')
	EXEC SP.uspHusoHorario_Registrar @nombre = 'Huso_Test_SpPais1';
GO
IF NOT EXISTS (SELECT 1 FROM sedes.HusoHorario WHERE NOMBRE = 'Huso_Test_SpPais2')
	EXEC SP.uspHusoHorario_Registrar @nombre = 'Huso_Test_SpPais2';
GO

--/ALTA

-- Esperado: imprime 'Error/es: - Valor invalido: Nombre.'
BEGIN TRY
    EXEC SP.uspPais_Registrar @nombre = '', @idioma = 1, @huso = 1, @ptIni = '17:00', @ptFin = '23:00', @pbi = 1000;
    THROW 51999, 'Se esperaba que el procedimiento rechazara los datos.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() NOT IN (50000, 51000) THROW;
END CATCH;
GO

-- Esperado: imprime 'Error/es: - Valor invalido: PBI.'
BEGIN TRY
    EXEC SP.uspPais_Registrar @nombre = 'Pais Test Negativo', @idioma = 1, @huso = 1, @ptIni = '17:00', @ptFin = '23:00', @pbi = -5;
    THROW 51999, 'Se esperaba que el procedimiento rechazara los datos.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() NOT IN (50000, 51000) THROW;
END CATCH;
GO

-- Esperado: imprime 'Error/es: - Valor invalido: Idioma.'
BEGIN TRY
    EXEC SP.uspPais_Registrar @nombre = 'Pais Test Negativo', @idioma = -1, @huso = 1, @ptIni = '17:00', @ptFin = '23:00', @pbi = 1000;
    THROW 51999, 'Se esperaba que el procedimiento rechazara los datos.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() NOT IN (50000, 51000) THROW;
END CATCH;
GO

-- Esperado: imprime 'Error/es: - Valor invalido: Huso Horario.'
BEGIN TRY
    EXEC SP.uspPais_Registrar @nombre = 'Pais Test Negativo', @idioma = 1, @huso = 0, @ptIni = '17:00', @ptFin = '23:00', @pbi = 1000;
    THROW 51999, 'Se esperaba que el procedimiento rechazara los datos.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() NOT IN (50000, 51000) THROW;
END CATCH;
GO

-- Esperado: imprime 'Error/es: - Valores invalidos: Inicio y Fin de Primetime.'
BEGIN TRY
    EXEC SP.uspPais_Registrar @nombre = 'Pais Test Negativo', @idioma = 1, @huso = 1, @ptIni = '23:30', @ptFin = '23:00', @pbi = 1000;
    THROW 51999, 'Se esperaba que el procedimiento rechazara los datos.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() NOT IN (50000, 51000) THROW;
END CATCH;
GO

-- Esperado: no imprime nada, se insertan 2 filas.
IF NOT EXISTS (SELECT 1 FROM equipos.Pais WHERE NOMBRE = 'Pais Test 1')
	EXEC SP.uspPais_Registrar @nombre = 'Pais Test 1', @idioma = 1, @huso = 1, @ptIni = '17:00', @ptFin = '23:00', @pbi = 1000;
GO

IF NOT EXISTS (SELECT 1 FROM equipos.Pais WHERE NOMBRE = 'Pais Test 2')
	EXEC SP.uspPais_Registrar @nombre = 'Pais Test 2', @idioma = 1, @huso = 1, @ptIni = '17:00', @ptFin = '23:00', @pbi = 2000;
GO

-- Esperado: 2 filas con NOMBRE = Pais Test 1 y Pais Test 2.
SELECT * FROM equipos.Pais WHERE NOMBRE LIKE 'Pais Test%';
GO

-- Esperado: imprime 'Error/es: - Valor duplicado: Pais (nombre).'
BEGIN TRY
    EXEC SP.uspPais_Registrar @nombre = 'Pais Test 1', @idioma = 1, @huso = 1, @ptIni = '17:00', @ptFin = '23:00', @pbi = 3000;
    THROW 51999, 'Se esperaba que el procedimiento rechazara los datos.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() NOT IN (50000, 51000) THROW;
END CATCH;
GO

--/UPDATE

DECLARE @idPais1 INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test 1');
DECLARE @idPais2 INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test 2');

-- Esperado: el Pais Test 1 pasa a PBI = 1500.
EXEC SP.uspPais_Update @idPais = @idPais1, @pbi = 1500;
GO

-- Esperado: 1 fila con PBI = 1500.
SELECT * FROM equipos.Pais WHERE NOMBRE = 'Pais Test 1';
GO

-- Esperado: imprime 'Error/es: - Valor invalido: ID Pais.'
BEGIN TRY
    EXEC SP.uspPais_Update @idPais = 0, @pbi = 1500;
    THROW 51999, 'Se esperaba que el procedimiento rechazara los datos.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() NOT IN (50000, 51000) THROW;
END CATCH;
GO

-- Esperado: imprime 'Error/es: - Valor inexistente: ID Pais.'
BEGIN TRY
    EXEC SP.uspPais_Update @idPais = 999999, @pbi = 1500;
    THROW 51999, 'Se esperaba que el procedimiento rechazara los datos.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() NOT IN (50000, 51000) THROW;
END CATCH;
GO

-- Esperado: imprime 'Error/es: - Valor duplicado: Pais (nombre).'
DECLARE @idPais1b INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test 1');
BEGIN TRY
    EXEC SP.uspPais_Update @idPais = @idPais1b, @nombre = 'Pais Test 2';
    THROW 51999, 'Se esperaba que el procedimiento rechazara los datos.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() NOT IN (50000, 51000) THROW;
END CATCH;
GO

-- Esperado: Pais Test 1 pasa a usar Idioma 2 y Huso Horario 2
DECLARE @idPais1 INT = (SELECT IdPais FROM equipos.Pais WHERE NOMBRE = 'Pais Test 1');
EXEC SP.uspPais_Update @idPais = @idPais1, @idioma = 2, @huso = 2;

SELECT * FROM equipos.Pais;
GO

--Esperado: Pais Test 2 pasa a tener franja Primetime (17-18 HS)
DECLARE @idPais2 INT = (SELECT IdPais FROM equipos.Pais WHERE NOMBRE = 'Pais Test 2');
EXEC SP.uspPais_Update @idPais = @idPais2, @ptIni = '17:00', @ptFin = '18:00';

SELECT * FROM equipos.Pais;
GO

--/BAJA

-- Esperado: imprime 'Error/es: - Valor inexistente: ID Pais.'
BEGIN TRY
    EXEC SP.uspPais_Bajar @idPais = 999999;
    THROW 51999, 'Se esperaba que el procedimiento rechazara los datos.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() NOT IN (50000, 51000) THROW;
END CATCH;
GO

-- Esperado: se borra la fila.
DECLARE @idPais2b INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test 2');
EXEC SP.uspPais_Bajar @idPais = @idPais2b;
GO

SELECT * FROM equipos.Pais WHERE NOMBRE LIKE 'Pais Test%';
GO

--/Limpieza de lo que genera el test
DELETE FROM equipos.Pais
WHERE NOMBRE LIKE 'Pais Test%';
GO

DELETE FROM arbitros.Idioma
WHERE Descripcion LIKE 'Idioma_Test_SpPais%';
DELETE FROM sedes.HusoHorario
WHERE NOMBRE LIKE 'Huso_Test_SpPais%';
GO

SELECT * FROM equipos.Pais WHERE NOMBRE LIKE 'Pais Test%';
GO
