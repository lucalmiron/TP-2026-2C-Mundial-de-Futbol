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

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'arbitros' AND TABLE_NAME = 'HablaIdioma')
BEGIN
	CREATE TABLE arbitros.HablaIdioma
	(
		Arbitro INT NOT NULL,
		Idioma INT NOT NULL,
		CONSTRAINT PK_HablaIdioma PRIMARY KEY (Arbitro, Idioma),
		CONSTRAINT FK_HablaIdioma_Arbitro FOREIGN KEY (Arbitro) REFERENCES arbitros.Arbitro(IdArbitro),
		CONSTRAINT FK_HablaIdioma_Idioma FOREIGN KEY (Idioma) REFERENCES arbitros.Idioma(IdIdioma)
	);
END;
GO
