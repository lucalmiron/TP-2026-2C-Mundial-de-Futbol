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


IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'TABLAS' AND TABLE_NAME = 'Tecnico')
BEGIN
	CREATE TABLE TABLAS.Tecnico
	(
		IdTecnico INT,
		Funcion VARCHAR(40),
		Seleccion INT,
		TarjetasAcum INT,
		Estado VARCHAR(10),
		FOREIGN KEY(Seleccion) REFERENCES TABLAS.Seleccion(IdSeleccion),
		FOREIGN KEY(IdTecnico) REFERENCES TABLAS.Persona(IdPersona),
		PRIMARY KEY(IdTecnico)
	);
END;
GO
