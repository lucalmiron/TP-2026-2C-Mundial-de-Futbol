-- Universidad Nacional de La Matanza
-- Bases de datos aplicada 
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 26/10/26
---- Objetivo: Crear Tabla alineacion

-- Ejecutar en la base seleccionada por el instalador.
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'partidos' AND TABLE_NAME = 'Alineacion')
BEGIN
	CREATE TABLE partidos.Alineacion
	(
		IdPartido INT NOT NULL,
		IdJugador INT NOT NULL,
		Rol VARCHAR(10) NOT NULL CONSTRAINT CK_Alineacion_Rol CHECK (Rol IN ('Titular', 'Suplente')),
		PosicionCancha VARCHAR(20) NULL,
		Esquema VARCHAR(10) NULL,
		CONSTRAINT PK_Alineacion PRIMARY KEY (IdPartido, IdJugador),
		CONSTRAINT FK_Alineacion_Partido FOREIGN KEY (IdPartido) REFERENCES partidos.Partido(IdPartido),
		CONSTRAINT FK_Alineacion_Jugador FOREIGN KEY (IdJugador) REFERENCES equipos.Jugador(IdJugador)
	);
END;
GO
