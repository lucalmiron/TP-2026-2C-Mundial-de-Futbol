--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 08/10/2026

--Test de los SP de Espacio Publicitario (se ejecutan los SP reales de MUNDIAL)

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

--/ALTA

-- Esperado: imprime 'Error/es: - Valor invalido: Tipo.'
EXEC SP.EspacioPublicitario_Registrar @tipo = '', @costo = 5000;
GO

-- Esperado: imprime 'Error/es: - Valor invalido: Costo.'
EXEC SP.EspacioPublicitario_Registrar @tipo = 'Panel Perimetral', @costo = 0;
GO

-- Esperado: imprime 'Error/es: - Valor invalido: Costo.'
EXEC SP.EspacioPublicitario_Registrar @tipo = 'Panel Perimetral', @costo = -100;
GO

-- Esperado: no imprime nada, se insertan 4 filas (los 4 tipos de espacio del torneo).
EXEC SP.EspacioPublicitario_Registrar @tipo = 'Panel Perimetral', @costo = 5000;
GO

EXEC SP.EspacioPublicitario_Registrar @tipo = 'Cubo LED', @costo = 7000;
GO

EXEC SP.EspacioPublicitario_Registrar @tipo = 'Tunnel de Acceso', @costo = 6500;
GO

EXEC SP.EspacioPublicitario_Registrar @tipo = 'Pantalla Principal', @costo = 9000;
GO

-- Esperado: 4 filas.
SELECT * FROM publicidad.EspacioPublicitario;
GO

-- Esperado: imprime 'Error/es: - Valor duplicado: Tipo de espacio.'
EXEC SP.EspacioPublicitario_Registrar @tipo = 'Cubo LED', @costo = 7000;
GO

--/UPDATE
--Los ids se resuelven por nombre para que el test se pueda ejecutar mas de una vez.

-- Esperado: el Cubo LED pasa a Costo = 7500.
DECLARE @idCubo INT = (SELECT MIN(IdEP) FROM publicidad.EspacioPublicitario WHERE Tipo = 'Cubo LED');
EXEC SP.EspacioPublicitario_Update @idEP = @idCubo, @costo = 7500;
GO

-- Esperado: 1 fila con Tipo = Cubo LED y Costo = 7500.
SELECT * FROM publicidad.EspacioPublicitario WHERE Tipo = 'Cubo LED';
GO

-- Esperado: imprime 'Error/es: - Valor inexistente: IdEP.'
EXEC SP.EspacioPublicitario_Update @idEP = 999999, @costo = 7500;
GO

-- Esperado: imprime 'Error/es: - Valor invalido: Costo.'
DECLARE @idCubo2 INT = (SELECT MIN(IdEP) FROM publicidad.EspacioPublicitario WHERE Tipo = 'Cubo LED');
EXEC SP.EspacioPublicitario_Update @idEP = @idCubo2, @costo = -1;
GO

-- Esperado: imprime 'Error/es: - Valor duplicado: Tipo de espacio.'
DECLARE @idCubo3 INT = (SELECT MIN(IdEP) FROM publicidad.EspacioPublicitario WHERE Tipo = 'Cubo LED');
EXEC SP.EspacioPublicitario_Update @idEP = @idCubo3, @tipo = 'Panel Perimetral';
GO

--/BAJA

-- Esperado: imprime 'Error/es: - Valor inexistente: IdEP.'
EXEC SP.EspacioPublicitario_Bajar @idEP = 999999;
GO

-- Esperado: se borra la fila, quedan 3 filas.
DECLARE @idCubo4 INT = (SELECT MIN(IdEP) FROM publicidad.EspacioPublicitario WHERE Tipo = 'Cubo LED');
EXEC SP.EspacioPublicitario_Bajar @idEP = @idCubo4;
GO

SELECT * FROM publicidad.EspacioPublicitario;
GO

--/Limpieza de lo que genera el test
DELETE FROM publicidad.EspacioPublicitario;
GO