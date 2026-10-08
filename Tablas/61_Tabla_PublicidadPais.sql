--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 08/10/2026

--Creacion de Tabla PublicidadPais

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'TABLAS' AND TABLE_NAME = 'PublicidadPais')
BEGIN
	CREATE TABLE TABLAS.PublicidadPais
	(
		IdPublicidad INT NOT NULL,
		IdPais INT NOT NULL,
		PRIMARY KEY(IdPublicidad, IdPais),
		FOREIGN KEY(IdPublicidad) REFERENCES TABLAS.Publicidad(IdPublicidad),
		FOREIGN KEY(IdPais) REFERENCES TABLAS.Pais(IdPais)
	)
END;
GO
