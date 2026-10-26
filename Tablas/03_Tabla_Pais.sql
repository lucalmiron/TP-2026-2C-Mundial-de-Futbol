--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Creacion de Tablas

-- Ejecutar en la base seleccionada por el instalador.
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'equipos' AND TABLE_NAME = 'Pais')
BEGIN
	CREATE TABLE equipos.Pais(
		IdPais INT IDENTITY(1,1),
		NOMBRE VARCHAR(50) NOT NULL,
		PBI BIGINT,
		CONSTRAINT PK_Pais PRIMARY KEY (IdPais),
		CONSTRAINT UQ_Pais_NOMBRE UNIQUE (NOMBRE)
	);
END;
GO
