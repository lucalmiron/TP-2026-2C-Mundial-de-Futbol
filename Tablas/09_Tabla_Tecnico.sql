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

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'equipos' AND TABLE_NAME = 'Tecnico')
BEGIN
	CREATE TABLE equipos.Tecnico
	(
		IdTecnico INT,
		Funcion VARCHAR(40) NOT NULL,
		Seleccion INT NOT NULL,
		TarjetasAcum INT NOT NULL CONSTRAINT DF_Tecnico_TarjetasAcum DEFAULT 0,
		Estado VARCHAR(10) NOT NULL,
		CONSTRAINT PK_Tecnico PRIMARY KEY (IdTecnico),
		CONSTRAINT FK_Tecnico_Persona FOREIGN KEY (IdTecnico) REFERENCES equipos.Persona(IdPersona),
		CONSTRAINT FK_Tecnico_Seleccion FOREIGN KEY (Seleccion) REFERENCES equipos.Seleccion(IdSeleccion)
	);
END;
GO
