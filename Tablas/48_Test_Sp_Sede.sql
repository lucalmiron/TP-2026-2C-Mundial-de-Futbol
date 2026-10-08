--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 08/10/2026

--Test de los SP de Sede (se ejecutan los SP reales de MUNDIAL)

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

--/Requisito: la Sede necesita un Pais, por eso el test usa IdPais = 1.
--Si la tabla de paises esta vacia, se carga uno de prueba.
IF NOT EXISTS (SELECT 1 FROM TABLAS.Pais)
	INSERT INTO TABLAS.Pais(NOMBRE) VALUES ('Pais Test');
GO

SELECT * FROM TABLAS.Pais;
GO

--/ALTA

-- Esperado: imprime 'Error/es: - Valor invalido: Nombre.'
EXEC SP.uspSede_Registrar @nombre = '', @ciudad = 'Ciudad Test', @capacidad = 50000, @pais = 1;
GO

-- Esperado: imprime 'Error/es: - Valor invalido: Ciudad.'
EXEC SP.uspSede_Registrar @nombre = 'Sede Test', @ciudad = NULL, @capacidad = 50000, @pais = 1;
GO

-- Esperado: imprime 'Error/es: - Valor invalido: Capacidad.'
EXEC SP.uspSede_Registrar @nombre = 'Sede Test', @ciudad = 'Ciudad Test', @capacidad = 0, @pais = 1;
GO

-- Esperado: imprime 'Error/es: - Valor inexistente: Pais.'
EXEC SP.uspSede_Registrar @nombre = 'Sede Test', @ciudad = 'Ciudad Test', @capacidad = 50000, @pais = 999;
GO

-- Esperado: no imprime nada, se inserta 1 fila (Sede Test / Ciudad Test).
EXEC SP.uspSede_Registrar @nombre = 'Sede Test', @ciudad = 'Ciudad Test', @capacidad = 50000, @pais = 1;
GO

-- Esperado: 1 fila con Nombre = Sede Test, Capacidad = 50000.
SELECT * FROM TABLAS.Sede;
GO

-- Esperado: imprime 'Error/es: - Valor duplicado: Sede (nombre y ciudad).'
EXEC SP.uspSede_Registrar @nombre = 'Sede Test', @ciudad = 'Ciudad Test', @capacidad = 50000, @pais = 1;
GO

--/UPDATE

-- Esperado: la fila pasa a Capacidad = 60000.
EXEC SP.uspSede_Update @idSede = 1, @capacidad = 60000;
GO

-- Esperado: 1 fila con Capacidad = 60000.
SELECT * FROM TABLAS.Sede;
GO

-- Esperado: imprime 'Error/es: - Valor inexistente: IdSede.'
EXEC SP.uspSede_Update @idSede = 999, @capacidad = 60000;
GO

-- Esperado: imprime 'Error/es: - Valor invalido: Capacidad.'
EXEC SP.uspSede_Update @idSede = 1, @capacidad = -1;
GO

--/BAJA

-- Esperado: imprime 'Error/es: - Valor inexistente: IdSede.'
EXEC SP.uspSede_Bajar @idSede = 999;
GO

-- Esperado: se borra la fila, la tabla queda vacia.
EXEC SP.uspSede_Bajar @idSede = 1;
GO

SELECT * FROM TABLAS.Sede;
GO

--/Limpieza de lo que genera el test
DELETE FROM TABLAS.Sede;
GO