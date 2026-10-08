--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 08/10/2026

--Creacion de Tabla Evento

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'partidos' AND TABLE_NAME = 'Evento')
BEGIN
	CREATE TABLE partidos.Evento
	(
		IdEvento INT IDENTITY(1, 1),
		Minuto INT NULL,
		Tipo VARCHAR(12) NOT NULL,
		Partido INT NOT NULL,
		Periodo INT NOT NULL,
		CONSTRAINT PK_Evento PRIMARY KEY (IdEvento),
		CONSTRAINT FK_Evento_Partido FOREIGN KEY (Partido) REFERENCES partidos.Partido(IdPartido),
		CONSTRAINT FK_Evento_Periodo FOREIGN KEY (Periodo) REFERENCES partidos.Periodo(IdPeriodo)
	);
END;
GO
