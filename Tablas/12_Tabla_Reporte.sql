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


IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'TABLAS' AND TABLE_NAME = 'Reporte')
BEGIN
	CREATE TABLE TABLAS.Reporte
	(
		IdReporte INT PRIMARY KEY IDENTITY(1, 1),
		Razon VARCHAR(20),
		Descripcion VARCHAR(300),
		Arbitro INT,
		Partido INT,
		FOREIGN KEY(Arbitro) REFERENCES TABLAS.Arbitro(IdArbitro),
		FOREIGN KEY(Partido) REFERENCES TABLAS.Partido(IdPartido)
	)
END;
GO
