--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: xx/xx/2026

--Creacion de Tabla Evento

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

CREATE TABLE TABLAS.Evento
(
	IdEvento INT PRIMARY KEY IDENTITY(1, 1),
	Minuto INT NULL,
	Tipo VARCHAR(12),
	Partido INT,
	Periodo INT,
	FOREIGN KEY(Partido) REFERENCES TABLAS.Partido(IdPartido),
	FOREIGN KEY(Periodo) REFERENCES TABLAS.Periodo(IdPeriodo)
);