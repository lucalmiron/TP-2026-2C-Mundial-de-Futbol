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

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'equipos' AND TABLE_NAME = 'Persona')
BEGIN
	CREATE TABLE equipos.Persona
	(
		IdPersona INT IDENTITY(1, 1),
		Nombre VARCHAR(30) NOT NULL,
		Fnac DATE NOT NULL,
		Rol VARCHAR(10) NOT NULL,
		Pais INT NOT NULL,
		CONSTRAINT PK_Persona PRIMARY KEY (IdPersona),
		CONSTRAINT FK_Persona_Pais FOREIGN KEY (Pais) REFERENCES equipos.Pais(IdPais)
	);
END;
GO
