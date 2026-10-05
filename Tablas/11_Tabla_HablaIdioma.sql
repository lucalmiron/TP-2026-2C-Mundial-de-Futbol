--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: xx/xx/2026

--Creacion de Tablas

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO


IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'TABLAS' AND TABLE_NAME = 'HablaIdioma')
BEGIN
	CREATE TABLE TABLAS.HablaIdioma
	(
		Arbitro INT,
		Idioma INT,
		FOREIGN KEY(Arbitro) REFERENCES TABLAS.Arbitro(IdArbitro),
		FOREIGN KEY(Idioma) REFERENCES TABLAS.Idioma(IdIdioma),
		PRIMARY KEY(Arbitro, Idioma)
	)
END;
GO
