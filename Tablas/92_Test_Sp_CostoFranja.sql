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

--/Datos de prueba
--CostoFranja tiene clave foranea a Sede (@idSede), asi que el test crea su propia sede.
--Los ids se resuelven por nombre en cada lote (los DECLARE no sobreviven a los GO).

IF NOT EXISTS (SELECT 1 FROM equipos.Pais WHERE NOMBRE = 'Pais Test 91')
	EXEC SP.uspPais_Registrar @nombre = 'Pais Test 91', @pbi = 91;
GO
DECLARE @cfPais INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test 91');
IF NOT EXISTS (SELECT 1 FROM sedes.HusoHorario WHERE Nombre = 'UTC-3 (91)')
	EXEC SP.uspHusoHorario_Registrar @nombre = 'UTC-3 (91)', @idPais = @cfPais;
GO
DECLARE @cfPais2 INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test 91');
DECLARE @cfHuso INT = (SELECT MIN(IdHuso) FROM sedes.HusoHorario WHERE Nombre = 'UTC-3 (91)');
IF NOT EXISTS (SELECT 1 FROM sedes.Sede WHERE Nombre = 'Sede Test 91')
	EXEC SP.uspSede_Registrar @nombre = 'Sede Test 91', @ciudad = 'Ciudad Test 91', @capacidad = 40000, @pais = @cfPais2, @huso = @cfHuso;
GO
SELECT * FROM sedes.Sede;
GO

--/ALTA

-- Esperado: imprime 'Error/es: - Valor invalido: Tipo de franja.'
DECLARE @cfSede1 INT = (SELECT MIN(IdSede) FROM sedes.Sede WHERE Nombre = 'Sede Test 91');
BEGIN TRY
	EXEC SP.CostoFranja_Registrar @tipoFranja = '', @costo = 12000, @idSede = @cfSede1;
END TRY
BEGIN CATCH
	PRINT 'Esperado: ' + ERROR_MESSAGE()
END CATCH
GO

-- Esperado: imprime 'Error/es: - Valor invalido: Costo.'
DECLARE @cfSede2 INT = (SELECT MIN(IdSede) FROM sedes.Sede WHERE Nombre = 'Sede Test 91');
BEGIN TRY
	EXEC SP.CostoFranja_Registrar @tipoFranja = 'Prime Time', @costo = 0, @idSede = @cfSede2;
END TRY
BEGIN CATCH
	PRINT 'Esperado: ' + ERROR_MESSAGE()
END CATCH
GO

-- Esperado: imprime 'Error/es: - Valor invalido: Costo.'
DECLARE @cfSede3 INT = (SELECT MIN(IdSede) FROM sedes.Sede WHERE Nombre = 'Sede Test 91');
BEGIN TRY
	EXEC SP.CostoFranja_Registrar @tipoFranja = 'Prime Time', @costo = -500, @idSede = @cfSede3;
END TRY
BEGIN CATCH
	PRINT 'Esperado: ' + ERROR_MESSAGE()
END CATCH
GO

-- Esperado: no imprime nada, se insertan 3 filas.
DECLARE @cfSede4 INT = (SELECT MIN(IdSede) FROM sedes.Sede WHERE Nombre = 'Sede Test 91');
EXEC SP.CostoFranja_Registrar @tipoFranja = 'Prime Time', @costo = 25000, @idSede = @cfSede4;
GO

DECLARE @cfSede5 INT = (SELECT MIN(IdSede) FROM sedes.Sede WHERE Nombre = 'Sede Test 91');
EXEC SP.CostoFranja_Registrar @tipoFranja = 'Pre Prime Time', @costo = 15000, @idSede = @cfSede5;
GO

DECLARE @cfSede6 INT = (SELECT MIN(IdSede) FROM sedes.Sede WHERE Nombre = 'Sede Test 91');
EXEC SP.CostoFranja_Registrar @tipoFranja = 'Off Prime Time', @costo = 8000, @idSede = @cfSede6;
GO

-- Esperado: 3 filas.
SELECT * FROM publicidad.CostoFranja;
GO

-- Esperado: imprime 'Error/es: - Valor duplicado: Tipo de franja.'
DECLARE @cfSede7 INT = (SELECT MIN(IdSede) FROM sedes.Sede WHERE Nombre = 'Sede Test 91');
BEGIN TRY
	EXEC SP.CostoFranja_Registrar @tipoFranja = 'Prime Time', @costo = 25000, @idSede = @cfSede7;
END TRY
BEGIN CATCH
	PRINT 'Esperado: ' + ERROR_MESSAGE()
END CATCH
GO

--/UPDATE
--Los ids se resuelven por nombre en cada lote (los DECLARE no sobreviven a los GO).

-- Esperado: Prime Time pasa a Costo = 27000.
DECLARE @cfPrime1 INT = (SELECT MIN(IdCF) FROM publicidad.CostoFranja WHERE TipoFranja = 'Prime Time');
EXEC SP.CostoFranja_Update @idCF = @cfPrime1, @costo = 27000;
GO

-- Esperado: 1 fila con TipoFranja = Prime Time y Costo = 27000.
SELECT * FROM publicidad.CostoFranja WHERE TipoFranja = 'Prime Time';
GO

-- Esperado: imprime 'Error/es: - Valor inexistente: IdCF.'
BEGIN TRY
	EXEC SP.CostoFranja_Update @idCF = 999999, @costo = 27000;
END TRY
BEGIN CATCH
	PRINT 'Esperado: ' + ERROR_MESSAGE()
END CATCH
GO

-- Esperado: imprime 'Error/es: - Valor invalido: Costo.'
DECLARE @cfPrime2 INT = (SELECT MIN(IdCF) FROM publicidad.CostoFranja WHERE TipoFranja = 'Prime Time');
BEGIN TRY
	EXEC SP.CostoFranja_Update @idCF = @cfPrime2, @costo = -1;
END TRY
BEGIN CATCH
	PRINT 'Esperado: ' + ERROR_MESSAGE()
END CATCH
GO

-- Esperado: imprime 'Error/es: - Valor duplicado: Tipo de franja.'
DECLARE @cfPrime3 INT = (SELECT MIN(IdCF) FROM publicidad.CostoFranja WHERE TipoFranja = 'Prime Time');
BEGIN TRY
	EXEC SP.CostoFranja_Update @idCF = @cfPrime3, @tipoFranja = 'Off Prime Time';
END TRY
BEGIN CATCH
	PRINT 'Esperado: ' + ERROR_MESSAGE()
END CATCH
GO

--/BAJA

-- Esperado: imprime 'Error/es: - Valor inexistente: IdCF.'
BEGIN TRY
	EXEC SP.CostoFranja_Bajar @idCF = 999999;
END TRY
BEGIN CATCH
	PRINT 'Esperado: ' + ERROR_MESSAGE()
END CATCH
GO

-- Esperado: se borra la fila, quedan 2 filas.
DECLARE @cfPrime4 INT = (SELECT MIN(IdCF) FROM publicidad.CostoFranja WHERE TipoFranja = 'Prime Time');
EXEC SP.CostoFranja_Bajar @idCF = @cfPrime4;
GO

SELECT * FROM publicidad.CostoFranja;
GO

--/Limpieza de lo que genera el test (en orden, por las claves foraneas)

DECLARE @cfId INT, @cfI INT = 0;
WHILE @cfI < 10
BEGIN
	SET @cfId = (SELECT MIN(IdCF) FROM publicidad.CostoFranja WHERE TipoFranja IN ('Prime Time', 'Pre Prime Time', 'Off Prime Time'));
	IF @cfId IS NULL BREAK;
	BEGIN TRY
		EXEC SP.CostoFranja_Bajar @idCF = @cfId;
	END TRY
	BEGIN CATCH
		PRINT 'Aviso limpieza: ' + ERROR_MESSAGE()
	END CATCH
	SET @cfI = @cfI + 1;
END

DECLARE @cfSedeB INT = (SELECT MIN(IdSede) FROM sedes.Sede WHERE Nombre = 'Sede Test 91');
IF @cfSedeB IS NOT NULL
	BEGIN TRY
		EXEC SP.uspSede_Bajar @idSede = @cfSedeB;
	END TRY
	BEGIN CATCH
		PRINT 'Aviso limpieza: ' + ERROR_MESSAGE()
	END CATCH

IF EXISTS (SELECT 1 FROM sedes.HusoHorario WHERE Nombre = 'UTC-3 (91)')
	DELETE FROM sedes.HusoHorario WHERE Nombre = 'UTC-3 (91)';

DECLARE @cfPaisB INT = (SELECT MIN(IdPais) FROM equipos.Pais WHERE NOMBRE = 'Pais Test 91');
IF @cfPaisB IS NOT NULL
	BEGIN TRY
		EXEC SP.uspPais_Bajar @idPais = @cfPaisB;
	END TRY
	BEGIN CATCH
		PRINT 'Aviso limpieza: ' + ERROR_MESSAGE()
	END CATCH

-- Esperado: no queda nada del test.
SELECT * FROM publicidad.CostoFranja;
GO
