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
		Nombre NVARCHAR(30) NOT NULL,
		Fnac DATE NOT NULL,
		Rol VARCHAR(10) NOT NULL,
		Pais INT NOT NULL,
		CONSTRAINT PK_Persona PRIMARY KEY (IdPersona),
		CONSTRAINT FK_Persona_Pais FOREIGN KEY (Pais) REFERENCES equipos.Pais(IdPais)
	);
END;
GO

-- Bases creadas con la version anterior tenian VARCHAR(30): se migra a NVARCHAR(30).
-- El ALTER es idempotente: si ya es NVARCHAR(30) no hace nada.
IF EXISTS (
	SELECT 1
	FROM sys.columns c
	JOIN sys.types t ON t.user_type_id = c.user_type_id
	WHERE c.object_id = OBJECT_ID(N'equipos.Persona')
	  AND c.name = N'Nombre'
	  AND (t.name <> N'nvarchar' OR c.max_length <> 60)
)
	ALTER TABLE equipos.Persona ALTER COLUMN Nombre NVARCHAR(30) NOT NULL;
GO
