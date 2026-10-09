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

--/Requisito: la Sede necesita un Pais y un HusoHorario, por eso el test usa IdPais = 1 e IdHuso = 1.
--Si la tabla de paises esta vacia, se carga uno de prueba.
IF NOT EXISTS (SELECT 1 FROM equipos.Pais)
	INSERT INTO equipos.Pais(NOMBRE) VALUES ('Pais Test');
GO

--Si no hay husos horarios cargados, se crea uno de prueba.
IF NOT EXISTS (SELECT 1 FROM sedes.HusoHorario)
	INSERT INTO sedes.HusoHorario(Nombre, IdPais) VALUES ('UTC-3', 1);
GO

SELECT * FROM equipos.Pais;
GO

SELECT * FROM sedes.HusoHorario;
GO

--/ALTA

-- Esperado: imprime 'Error/es: - Valor invalido: Nombre.'
EXEC SP.uspSede_Registrar @nombre = '', @ciudad = 'Ciudad Test', @capacidad = 50000, @pais = 1, @huso = 1;
GO

-- Esperado: imprime 'Error/es: - Valor invalido: Ciudad.'
EXEC SP.uspSede_Registrar @nombre = 'Sede Test', @ciudad = NULL, @capacidad = 50000, @pais = 1, @huso = 1;
GO

-- Esperado: imprime 'Error/es: - Valor invalido: Capacidad.'
EXEC SP.uspSede_Registrar @nombre = 'Sede Test', @ciudad = 'Ciudad Test', @capacidad = 0, @pais = 1, @huso = 1;
GO

-- Esperado: imprime 'Error/es: - Valor inexistente: Pais.'
EXEC SP.uspSede_Registrar @nombre = 'Sede Test', @ciudad = 'Ciudad Test', @capacidad = 50000, @pais = 999, @huso = 1;
GO

-- Esperado: imprime 'Error/es: - Valor inexistente: Huso horario.'
EXEC SP.uspSede_Registrar @nombre = 'Sede Test', @ciudad = 'Ciudad Test', @capacidad = 50000, @pais = 1, @huso = 99;
GO

-- Esperado: no imprime nada, se inserta 1 fila (Sede Test / Ciudad Test).
EXEC SP.uspSede_Registrar @nombre = 'Sede Test', @ciudad = 'Ciudad Test', @capacidad = 50000, @pais = 1, @huso = 1;
GO

-- Esperado: 1 fila con Nombre = Sede Test, Capacidad = 50000.
SELECT * FROM sedes.Sede;
GO

-- Esperado: imprime 'Error/es: - Valor duplicado: Sede (nombre y ciudad).'
EXEC SP.uspSede_Registrar @nombre = 'Sede Test', @ciudad = 'Ciudad Test', @capacidad = 50000, @pais = 1, @huso = 1;
GO

--/UPDATE
--Los ids se resuelven por nombre para que el test se pueda ejecutar mas de una vez.

-- Esperado: la fila pasa a Capacidad = 60000.
DECLARE @idSede INT = (SELECT MIN(IdSede) FROM sedes.Sede WHERE Nombre = 'Sede Test');
EXEC SP.uspSede_Update @idSede = @idSede, @capacidad = 60000;
GO

-- Esperado: 1 fila con Capacidad = 60000.
SELECT * FROM sedes.Sede;
GO

-- Esperado: imprime 'Error/es: - Valor inexistente: IdSede.'
EXEC SP.uspSede_Update @idSede = 999999, @capacidad = 60000;
GO

-- Esperado: imprime 'Error/es: - Valor invalido: Capacidad.'
DECLARE @idSede2 INT = (SELECT MIN(IdSede) FROM sedes.Sede WHERE Nombre = 'Sede Test');
EXEC SP.uspSede_Update @idSede = @idSede2, @capacidad = -1;
GO

-- Esperado: imprime 'Error/es: - Valor inexistente: Pais.'
DECLARE @idSede3 INT = (SELECT MIN(IdSede) FROM sedes.Sede WHERE Nombre = 'Sede Test');
EXEC SP.uspSede_Update @idSede = @idSede3, @pais = 999;
GO

-- Esperado: imprime 'Error/es: - Valor inexistente: Huso horario.'
DECLARE @idSede4 INT = (SELECT MIN(IdSede) FROM sedes.Sede WHERE Nombre = 'Sede Test');
EXEC SP.uspSede_Update @idSede = @idSede4, @huso = 999999;
GO

--/BAJA

-- Esperado: imprime 'Error/es: - Valor inexistente: IdSede.'
EXEC SP.uspSede_Bajar @idSede = 999999;
GO

-- Esperado: se borra la fila, la tabla queda vacia.
DECLARE @idSede5 INT = (SELECT MIN(IdSede) FROM sedes.Sede WHERE Nombre = 'Sede Test');
EXEC SP.uspSede_Bajar @idSede = @idSede5;
GO

SELECT * FROM sedes.Sede;
GO

--/Limpieza de lo que genera el test
DELETE FROM sedes.Sede;
GO