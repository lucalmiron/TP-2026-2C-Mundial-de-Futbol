--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 08/10/2026

--Creacion de Tablas

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'equipos' AND TABLE_NAME = 'Seleccion')
BEGIN
	CREATE TABLE equipos.Seleccion
	(
		IdSeleccion INT IDENTITY(1,1),
		IdPais INT NOT NULL,
		IdMundial INT NOT NULL,
		IdGrupo INT NOT NULL,
		CONFEDERACION VARCHAR(45) NOT NULL,
		CONSTRAINT PK_Seleccion PRIMARY KEY (IdSeleccion),
		CONSTRAINT FK_Seleccion_Pais FOREIGN KEY (IdPais) REFERENCES equipos.Pais(IdPais),
		CONSTRAINT FK_Seleccion_Mundial FOREIGN KEY (IdMundial) REFERENCES sedes.Mundial(IdMundial),
		CONSTRAINT FK_Seleccion_Grupo FOREIGN KEY (IdGrupo) REFERENCES equipos.Grupo(IdGrupo),
		CONSTRAINT UQ_Seleccion_IdPais_IdMundial UNIQUE (IdPais, IdMundial)
	);
END;
GO
