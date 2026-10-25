--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 08/10/2026

--Test de los SP de Pais (se ejecutan los SP reales de MUNDIAL)

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

--/ALTA

-- Esperado: imprime 'Error/es: - Valor invalido: Nombre.'
EXEC SP.uspPais_Registrar @nombre = '', @pbi = 1000;
GO

-- Esperado: imprime 'Error/es: - Valor invalido: PBI.'
EXEC SP.uspPais_Registrar @nombre = 'Pais Test Negativo', @pbi = -5;
GO

-- Esperado: no imprime nada, se insertan 2 filas.
IF NOT EXISTS (SELECT 1 FROM equipos.Pais WHERE NOMBRE = 'Pais Test 1')
	EXEC SP.uspPais_Registrar @nombre = 'Pais Test 1', @pbi = 1000;
GO

IF NOT EXISTS (SELECT 1 FROM equipos.Pais WHERE NOMBRE = 'Pais Test 2')
	EXEC SP.uspPais_Registrar @nombre = 'Pais Test 2', @pbi = 2000;
GO

-- Esperado: 2 filas con NOMBRE = Pais Test 1 y Pais Test 2.
SELECT * FROM equipos.Pais WHERE NOMBRE LIKE 'Pais Test%';
GO

-- Esperado: imprime 'Error/es: - Valor duplicado: Pais (nombre).'
EXEC SP.uspPais_Registrar @nombre = 'Pais Test 1', @pbi = 3000;
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
EXEC SP.uspPais_Update @idPais = 0, @pbi = 1500;
GO

-- Esperado: imprime 'Error/es: - Valor inexistente: ID Pais.'
EXEC SP.uspPais_Update @idPais = 999999, @pbi = 1500;
GO

-- Esperado: imprime 'Error/es: - Valor duplicado: Pais (nombre).'
DECLARE @idPais1b INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test 1');
EXEC SP.uspPais_Update @idPais = @idPais1b, @nombre = 'Pais Test 2';
GO

--/BAJA

-- Esperado: imprime 'Error/es: - Valor inexistente: ID Pais.'
EXEC SP.uspPais_Bajar @idPais = 999999;
GO

-- Esperado: se borra la fila.
DECLARE @idPais2b INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test 2');
EXEC SP.uspPais_Bajar @idPais = @idPais2b;
GO

SELECT * FROM equipos.Pais WHERE NOMBRE LIKE 'Pais Test%';
GO

--/BAJA CON REGISTROS RELACIONADOS

-- Esperado: se inserta un HusoHorario del Pais Test 1.
DECLARE @idPais1c INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test 1');

IF NOT EXISTS (SELECT 1 FROM sedes.HusoHorario WHERE Nombre = 'UTC-3 (Pais Test)')
	EXEC SP.uspHusoHorario_Registrar @nombre = 'UTC-3 (Pais Test)', @idPais = @idPais1c;
GO

-- Esperado: imprime 'Error/es: - Existen 1 o mas registros relacionados: HusoHorario. Elimine dichos registros para continuar.'
DECLARE @idPais1d INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test 1');
EXEC SP.uspPais_Bajar @idPais = @idPais1d;
GO

--/Limpieza de lo que genera el test (en orden, por las claves foraneas)
DECLARE @idHusoL INT = (SELECT MIN(IdHuso) FROM sedes.HusoHorario WHERE Nombre = 'UTC-3 (Pais Test)');

IF @idHusoL IS NOT NULL
	EXEC SP.uspHusoHorario_Bajar @idHuso = @idHusoL;
GO

DECLARE @idPaisL INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test 1');

IF @idPaisL IS NOT NULL
	EXEC SP.uspPais_Bajar @idPais = @idPaisL;
GO

SELECT * FROM equipos.Pais WHERE NOMBRE LIKE 'Pais Test%';
GO