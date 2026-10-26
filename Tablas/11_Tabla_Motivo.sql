--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Creacion de Tabla Motivo

-- Ejecutar en la base seleccionada por el instalador.
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'publicidad' AND TABLE_NAME = 'Motivo')
BEGIN
	CREATE TABLE publicidad.Motivo
	(
		IdMotivo INT PRIMARY KEY IDENTITY(1, 1),
		Descripcion VARCHAR(100) NOT NULL
	)
END;
GO