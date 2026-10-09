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

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'arbitros' AND TABLE_NAME = 'Reporte')
BEGIN
	CREATE TABLE arbitros.Reporte
	(
		IdReporte INT IDENTITY(1, 1),
		Razon VARCHAR(20) NOT NULL,
		Descripcion VARCHAR(300) NULL,
		Arbitro INT NOT NULL,
		Partido INT NOT NULL,
		CONSTRAINT PK_Reporte PRIMARY KEY (IdReporte),
		CONSTRAINT FK_Reporte_Arbitro FOREIGN KEY (Arbitro) REFERENCES arbitros.Arbitro(IdArbitro),
		CONSTRAINT FK_Reporte_Partido FOREIGN KEY (Partido) REFERENCES partidos.Partido(IdPartido)
	);
END;
GO
