-- Universidad Nacional de La Matanza
-- Bases de datos aplicada 
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 03/10/2026
---- Objetivo: Crear Tabla alineacion

USE MUNDIALtesting
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'TABLAS' AND TABLE_NAME = 'Alineacion')
BEGIN 
	CREATE TABLE TABLAS.Alineacion(
	IdPartido INT NOT NULL FOREIGN KEY REFERENCES TABLAS.Partido (IdPartido),
	IdJugador INT NOT NULL FOREIGN KEY REFERENCES TABLAS.Jugador (IdJugador),
	IdSeleccion INT NOT NULL FOREIGN KEY REFERENCES TABLAS.Seleccion (IdSeleccion),
	Rol VARCHAR (10) NOT NULL CHECK(Rol IN('Titular', 'Suplente')),
	PosicionCancha VARCHAR (20) NULL,
	Esquema VARCHAR (10) NULL,
	PRIMARY KEY (IdPartido, IdJugador))
END
GO

