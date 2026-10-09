-- Universidad Nacional de La Matanza
-- Bases de datos aplicada 
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 08/10/2026
-- Objetivo: Crear Tabla Partido

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'partidos' AND TABLE_NAME = 'Partido')
BEGIN
	CREATE TABLE partidos.Partido
	(
		IdPartido INT IDENTITY(1, 1),
		IdFase INT NOT NULL,
		IdSede INT NOT NULL,
		Eq1 INT NOT NULL,
		Eq2 INT NOT NULL,
		Fecha DATE NOT NULL,
		HoraUTC TIME NOT NULL,
		HoraLocal TIME NOT NULL,
		GolesEq1 INT NOT NULL CONSTRAINT DF_Partido_GolesEq1 DEFAULT 0 CONSTRAINT CK_Partido_GolesEq1 CHECK (GolesEq1 >= 0),
		GolesEq2 INT NOT NULL CONSTRAINT DF_Partido_GolesEq2 DEFAULT 0 CONSTRAINT CK_Partido_GolesEq2 CHECK (GolesEq2 >= 0),
		Asistencia INT CONSTRAINT CK_Partido_Asistencia CHECK (Asistencia >= 0),
		CONSTRAINT PK_Partido PRIMARY KEY (IdPartido),
		CONSTRAINT FK_Partido_Fase FOREIGN KEY (IdFase) REFERENCES partidos.Fase(IdFase),
		CONSTRAINT FK_Partido_Sede FOREIGN KEY (IdSede) REFERENCES sedes.Sede(IdSede),
		CONSTRAINT FK_Partido_Seleccion_Eq1 FOREIGN KEY (Eq1) REFERENCES equipos.Seleccion(IdSeleccion),
		CONSTRAINT FK_Partido_Seleccion_Eq2 FOREIGN KEY (Eq2) REFERENCES equipos.Seleccion(IdSeleccion),
		CONSTRAINT CK_Partido_Equipos CHECK (Eq1 <> Eq2)
	);
END;
GO
