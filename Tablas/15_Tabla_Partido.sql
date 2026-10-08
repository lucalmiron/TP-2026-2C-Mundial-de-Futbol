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

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'TABLAS' AND TABLE_NAME = 'Partido')
BEGIN 
	CREATE TABLE TABLAS.Partido(
	IdPartido INT IDENTITY(1, 1) PRIMARY KEY,
	IdFase INT NOT NULL FOREIGN KEY REFERENCES TABLAS.Fase(IdFase),
	IdSede INT NOT NULL FOREIGN KEY REFERENCES TABLAS.Sede(IdSede),
	Eq1 INT NOT NULL FOREIGN KEY REFERENCES TABLAS.Seleccion(IdSeleccion),
	Eq2 INT NOT NULL FOREIGN KEY REFERENCES TABLAS.Seleccion(IdSeleccion),
	Fecha DATE NOT NULL,
	HoraUTC TIME NOT NULL,
	HoraLocal TIME NOT NULL,
	GolesEq1 INT NOT NULL DEFAULT 0 CHECK(GolesEq1 >= 0),
	GolesEq2 INT NOT NULL DEFAULT 0 CHECK(GolesEq2 >= 0),
	Asistencia INT CHECK(Asistencia >= 0),
	CHECK (Eq1 <> Eq2))
END
GO

