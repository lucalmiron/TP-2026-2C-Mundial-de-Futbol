--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: xx/xx/2026

--Creacion de Tabla Amonestacion

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

CREATE TABLE TABLAS.Amonestacion
(
	IdAmonestacion INT,
	Amonestado INT,
	Arbitro INT,
	Tarjeta VARCHAR(8),
	Motivo VARCHAR(300),
	FOREIGN KEY(IdAmonestacion) REFERENCES TABLAS.Evento,
	FOREIGN KEY(Amonestado) REFERENCES TABLAS.Persona,
	FOREIGN KEY(Arbitro) REFERENCES TABLAS.Arbitro,
	PRIMARY KEY(IdAmonestacion)
);