--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 08/10/2026

--Test de los SP de Costo Franja (se ejecutan los SP reales de MUNDIAL)

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

--/ALTA

-- Esperado: imprime 'Error/es: - Valor invalido: Tipo de franja.'
EXEC SP.CostoFranja_Registrar @tipoFranja = '', @costo = 12000;
GO

-- Esperado: imprime 'Error/es: - Valor invalido: Costo.'
EXEC SP.CostoFranja_Registrar @tipoFranja = 'Prime Time', @costo = 0;
GO

-- Esperado: imprime 'Error/es: - Valor invalido: Costo.'
EXEC SP.CostoFranja_Registrar @tipoFranja = 'Prime Time', @costo = -500;
GO

-- Esperado: no imprime nada, se insertan 3 filas.
EXEC SP.CostoFranja_Registrar @tipoFranja = 'Prime Time', @costo = 25000;
GO

EXEC SP.CostoFranja_Registrar @tipoFranja = 'Pre Prime Time', @costo = 15000;
GO

EXEC SP.CostoFranja_Registrar @tipoFranja = 'Off Prime Time', @costo = 8000;
GO

-- Esperado: 3 filas.
SELECT * FROM publicidad.CostoFranja;
GO

-- Esperado: imprime 'Error/es: - Valor duplicado: Tipo de franja.'
EXEC SP.CostoFranja_Registrar @tipoFranja = 'Prime Time', @costo = 25000;
GO

--/UPDATE
--Los ids se resuelven por nombre para que el test se pueda ejecutar mas de una vez.

-- Esperado: Prime Time pasa a Costo = 27000.
DECLARE @idPrime INT = (SELECT MIN(IdCF) FROM publicidad.CostoFranja WHERE TipoFranja = 'Prime Time');
EXEC SP.CostoFranja_Update @idCF = @idPrime, @costo = 27000;
GO

-- Esperado: 1 fila con TipoFranja = Prime Time y Costo = 27000.
SELECT * FROM publicidad.CostoFranja WHERE TipoFranja = 'Prime Time';
GO

-- Esperado: imprime 'Error/es: - Valor inexistente: IdCF.'
EXEC SP.CostoFranja_Update @idCF = 999999, @costo = 27000;
GO

-- Esperado: imprime 'Error/es: - Valor invalido: Costo.'
DECLARE @idPrime2 INT = (SELECT MIN(IdCF) FROM publicidad.CostoFranja WHERE TipoFranja = 'Prime Time');
EXEC SP.CostoFranja_Update @idCF = @idPrime2, @costo = -1;
GO

-- Esperado: imprime 'Error/es: - Valor duplicado: Tipo de franja.'
DECLARE @idPrime3 INT = (SELECT MIN(IdCF) FROM publicidad.CostoFranja WHERE TipoFranja = 'Prime Time');
EXEC SP.CostoFranja_Update @idCF = @idPrime3, @tipoFranja = 'Off Prime Time';
GO

--/BAJA

-- Esperado: imprime 'Error/es: - Valor inexistente: IdCF.'
EXEC SP.CostoFranja_Bajar @idCF = 999999;
GO

-- Esperado: se borra la fila, quedan 2 filas.
DECLARE @idPrime4 INT = (SELECT MIN(IdCF) FROM publicidad.CostoFranja WHERE TipoFranja = 'Prime Time');
EXEC SP.CostoFranja_Bajar @idCF = @idPrime4;
GO

SELECT * FROM publicidad.CostoFranja;
GO

--/Limpieza de lo que genera el test
DELETE FROM publicidad.CostoFranja WHERE TipoFranja IN ('Prime Time','Pre Prime Time','Off Prime Time');
GO