--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 08/10/2026

--Objetivo: Crear Tabla Gol

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'partidos' AND TABLE_NAME = 'Gol')
BEGIN
	CREATE TABLE partidos.Gol
	(
		IdGol INT NOT NULL,
		Autor INT NOT NULL,
		Asistencia INT NULL,
		Tipo VARCHAR(20) NOT NULL,
		CONSTRAINT PK_Gol PRIMARY KEY (IdGol),
		CONSTRAINT FK_Gol_Evento FOREIGN KEY (IdGol) REFERENCES partidos.Evento(IdEvento),
		CONSTRAINT FK_Gol_Autor FOREIGN KEY (Autor) REFERENCES equipos.Jugador(IdJugador),
		CONSTRAINT FK_Gol_Asistencia FOREIGN KEY (Asistencia) REFERENCES equipos.Jugador(IdJugador),
		CONSTRAINT CK_Gol_Tipo CHECK (Tipo IN ('Jugada','Penal','Tiro libre','Corner','En contra')),
		CONSTRAINT CK_Gol_Autor_Asistencia CHECK (Autor <> Asistencia)
	)
END
GO