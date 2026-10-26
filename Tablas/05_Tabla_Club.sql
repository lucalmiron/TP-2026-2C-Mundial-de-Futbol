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

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'equipos' AND TABLE_NAME = 'Club')
BEGIN
	CREATE TABLE equipos.Club
	(
		IdClub INT IDENTITY(1, 1),
		Nombre VARCHAR(20) NOT NULL,
		CONSTRAINT PK_Club PRIMARY KEY (IdClub),
		CONSTRAINT UQ_Club_Nombre UNIQUE (Nombre)
	);
END;
GO
