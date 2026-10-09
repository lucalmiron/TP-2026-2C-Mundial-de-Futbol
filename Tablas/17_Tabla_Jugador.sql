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

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'equipos' AND TABLE_NAME = 'Jugador')
BEGIN
	CREATE TABLE equipos.Jugador
	(
		IdJugador INT,
		Estado VARCHAR(10) NOT NULL,
		Posicion VARCHAR(20) NOT NULL,
		Numero INT NOT NULL,
		Club INT NULL,
		Seleccion INT NOT NULL,
		TarjetasAcum INT NOT NULL CONSTRAINT DF_Jugador_TarjetasAcum DEFAULT 0,
		CONSTRAINT PK_Jugador PRIMARY KEY (IdJugador),
		CONSTRAINT FK_Jugador_Persona FOREIGN KEY (IdJugador) REFERENCES equipos.Persona(IdPersona),
		CONSTRAINT FK_Jugador_Club FOREIGN KEY (Club) REFERENCES equipos.Club(IdClub),
		CONSTRAINT FK_Jugador_Seleccion FOREIGN KEY (Seleccion) REFERENCES equipos.Seleccion(IdSeleccion),
		CONSTRAINT UQ_Jugador_Dorsal UNIQUE (Seleccion, Numero)
	);
END;
GO
