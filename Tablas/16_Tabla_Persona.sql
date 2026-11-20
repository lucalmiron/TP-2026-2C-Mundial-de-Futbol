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

-- Entrega 8: Nombre se almacena cifrado (VARBINARY) y se agrega NombreHash para búsquedas.
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'equipos' AND TABLE_NAME = 'Persona')
BEGIN
	CREATE TABLE equipos.Persona
	(
		IdPersona INT IDENTITY(1, 1),
		Nombre VARBINARY(256) NOT NULL,      -- Cifrado con AES_128 (ver 97_Seguridad_Cifrado_Claves.sql)
		NombreHash VARBINARY(32) NULL,        -- HASHBYTES('SHA2_256', Nombre) para busquedas sin descifrar
		Fnac DATE NOT NULL,
		Rol VARCHAR(10) NOT NULL,
		Pais INT NOT NULL,
		CONSTRAINT PK_Persona PRIMARY KEY (IdPersona),
		CONSTRAINT FK_Persona_Pais FOREIGN KEY (Pais) REFERENCES equipos.Pais(IdPais)
	);
END;
GO

-- Si la tabla ya existia pero no tiene NombreHash (bases creadas antes de la E8), se agrega.
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('equipos.Persona') AND name = 'NombreHash')
BEGIN
	ALTER TABLE equipos.Persona ADD NombreHash VARBINARY(32) NULL;
END
GO
