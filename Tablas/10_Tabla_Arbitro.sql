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


IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'TABLAS' AND TABLE_NAME = 'Arbitro')
BEGIN
	CREATE TABLE TABLAS.Arbitro
	(
		IdArbitro INT,
		Categoria VARCHAR(20),
		FOREIGN KEY(IdArbitro) REFERENCES TABLAS.Persona(IdPersona),
		PRIMARY KEY(IdArbitro)
	);
END;
GO
