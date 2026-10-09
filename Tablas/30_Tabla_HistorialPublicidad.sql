--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 08/10/2026

--Creacion de Tabla HistorialPublicidad

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'publicidad' AND TABLE_NAME = 'HistorialPublicidad')
BEGIN
	CREATE TABLE publicidad.HistorialPublicidad
	(
		IdHistorial INT PRIMARY KEY IDENTITY(1, 1),
		IdPublicidad INT NOT NULL,
		IdPartido INT NOT NULL,
		IdEP INT NOT NULL,
		CostoFinal DECIMAL(10,2) NOT NULL,
		FOREIGN KEY(IdPublicidad) REFERENCES publicidad.Publicidad(IdPublicidad),
		FOREIGN KEY(IdPartido) REFERENCES partidos.Partido(IdPartido),
		FOREIGN KEY(IdEP) REFERENCES publicidad.EspacioPublicitario(IdEP)
	)
END;
GO