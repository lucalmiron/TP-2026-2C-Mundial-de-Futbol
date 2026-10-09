--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 08/10/2026

--Test de los SP de HusoHorario (se ejecutan los SP reales de MUNDIAL)

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

--/Requisito: el HusoHorario pertenece a un Pais, por eso el test usa IdPais = 1.
--Si la tabla de paises esta vacia, se carga uno de prueba.
IF NOT EXISTS (SELECT 1 FROM equipos.Pais)
	INSERT INTO equipos.Pais(NOMBRE) VALUES ('Pais Test');
GO

SELECT * FROM equipos.Pais;
GO

--/ALTA

-- Esperado: imprime 'Error/es: - Valor invalido: Nombre.'
EXEC SP.uspHusoHorario_Registrar @nombre = '', @idPais = 1;
GO

-- Esperado: imprime 'Error/es: - Valor invalido: Pais.'
EXEC SP.uspHusoHorario_Registrar @nombre = 'UTC-3', @idPais = 0;
GO

-- Esperado: imprime 'Error/es: - Valor inexistente: Pais.'
EXEC SP.uspHusoHorario_Registrar @nombre = 'UTC-3', @idPais = 999;
GO

-- Esperado: no imprime nada, se insertan 2 filas.
EXEC SP.uspHusoHorario_Registrar @nombre = 'UTC-3', @idPais = 1;
GO

EXEC SP.uspHusoHorario_Registrar @nombre = 'UTC+1', @idPais = 1;
GO

-- Esperado: 2 filas.
SELECT * FROM sedes.HusoHorario;
GO

-- Esperado: imprime 'Error/es: - Valor duplicado: Nombre.'
EXEC SP.uspHusoHorario_Registrar @nombre = 'UTC-3', @idPais = 1;
GO

--/UPDATE

-- Esperado: el UTC-3 pasa a Nombre = UTC-3 (America/Argentina).
EXEC SP.uspHusoHorario_Update @idHuso = 1, @nombre = 'UTC-3 (America/Argentina)';
GO

-- Esperado: 1 fila con el nombre nuevo.
SELECT * FROM sedes.HusoHorario WHERE IdHuso = 1;
GO

-- Esperado: imprime 'Error/es: - Valor inexistente: ID HusoHorario.'
EXEC SP.uspHusoHorario_Update @idHuso = 99, @nombre = 'UTC-9';
GO

-- Esperado: imprime 'Error/es: - Valor inexistente: Pais.'
EXEC SP.uspHusoHorario_Update @idHuso = 1, @idPais = 999;
GO

-- Esperado: imprime 'Error/es: - Valor duplicado: Nombre.'
EXEC SP.uspHusoHorario_Update @idHuso = 1, @nombre = 'UTC+1';
GO

--/BAJA

-- Esperado: imprime 'Error/es: - Valor inexistente: ID HusoHorario.'
EXEC SP.uspHusoHorario_Bajar @idHuso = 99;
GO

-- Esperado: se borra la fila, queda 1 fila.
EXEC SP.uspHusoHorario_Bajar @idHuso = 1;
GO

SELECT * FROM sedes.HusoHorario;
GO

--/Limpieza de lo que genera el test
DELETE FROM sedes.HusoHorario;
GO