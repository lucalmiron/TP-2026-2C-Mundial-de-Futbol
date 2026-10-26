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

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'arbitros' AND TABLE_NAME = 'Idioma')
BEGIN
	CREATE TABLE arbitros.Idioma
	(
		IdIdioma INT IDENTITY(1, 1),
		Descripcion VARCHAR(20) NOT NULL,
		CONSTRAINT PK_Idioma PRIMARY KEY (IdIdioma),
		CONSTRAINT UQ_Idioma_Descripcion UNIQUE (Descripcion)
	);
END;
GO
