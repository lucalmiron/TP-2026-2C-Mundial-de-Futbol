--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 08/10/2026

--Creacion de Tabla AnuncianteCampania

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'TABLAS' AND TABLE_NAME = 'AnuncianteCampania')
BEGIN
	CREATE TABLE TABLAS.AnuncianteCampania
	(
		IdAnunciante INT NOT NULL,
		IdCampania INT NOT NULL,
		PRIMARY KEY(IdAnunciante, IdCampania),
		FOREIGN KEY(IdAnunciante) REFERENCES TABLAS.Anunciante(IdAnunciante),
		FOREIGN KEY(IdCampania) REFERENCES TABLAS.Campania(IdCampania)
	)
END;
GO
