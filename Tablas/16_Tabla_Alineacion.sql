-- Universidad Nacional de La Matanza
-- Bases de datos aplicada 
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 08/10/2026
---- Objetivo: Crear Tabla alineacion

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'partidos' AND TABLE_NAME = 'Alineacion')
BEGIN
	CREATE TABLE partidos.Alineacion
	(
		IdPartido INT NOT NULL,
		IdJugador INT NOT NULL,
		IdSeleccion INT NOT NULL,
		Rol VARCHAR(10) NOT NULL CONSTRAINT CK_Alineacion_Rol CHECK (Rol IN ('Titular', 'Suplente')),
		PosicionCancha VARCHAR(20) NULL,
		Esquema VARCHAR(10) NULL,
		CONSTRAINT PK_Alineacion PRIMARY KEY (IdPartido, IdJugador),
		CONSTRAINT FK_Alineacion_Partido FOREIGN KEY (IdPartido) REFERENCES partidos.Partido(IdPartido),
		CONSTRAINT FK_Alineacion_Jugador FOREIGN KEY (IdJugador) REFERENCES equipos.Jugador(IdJugador),
		CONSTRAINT FK_Alineacion_Seleccion FOREIGN KEY (IdSeleccion) REFERENCES equipos.Seleccion(IdSeleccion)
	);
END;
GO
