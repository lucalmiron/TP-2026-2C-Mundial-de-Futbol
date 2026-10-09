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
END
GO

-- Si la tabla ya existe se libera el CHECK que referencia a la funcion: mientras
-- ese CHECK este puesto, SQL Server no permite alterar la funcion. Al final del
-- script el CHECK se vuelve a agregar (ver CK_Partido_MismoMundial mas abajo).
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Partido_MismoMundial')
	ALTER TABLE partidos.Partido DROP CONSTRAINT CK_Partido_MismoMundial
GO

-- Funcion de apoyo al CHECK de mismo Mundial via equipos.Seleccion
-- Se usa CREATE OR ALTER (y no DROP + CREATE) porque el CHECK la referencia:
-- dropearla dejaria de ser re-ejecutable una vez creado el CHECK
CREATE OR ALTER FUNCTION partidos.fnPartido_MismoMundial(@Eq1 INT, @Eq2 INT, @IdMundial INT)
RETURNS BIT
AS
BEGIN
	DECLARE @vOk BIT = 0
	IF EXISTS (SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @Eq1 AND IdMundial = @IdMundial)
	AND EXISTS (SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @Eq2 AND IdMundial = @IdMundial)
		SET @vOk = 1
	RETURN @vOk
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'partidos' AND TABLE_NAME = 'Partido')
BEGIN
	CREATE TABLE partidos.Partido
	(
		IdPartido INT IDENTITY(1, 1),
		IdFase INT NOT NULL,
		IdSede INT NOT NULL,
		IdMundial INT NOT NULL,
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
		CONSTRAINT FK_Partido_Mundial FOREIGN KEY (IdMundial) REFERENCES sedes.Mundial(IdMundial),
		CONSTRAINT FK_Partido_Seleccion_Eq1 FOREIGN KEY (Eq1) REFERENCES equipos.Seleccion(IdSeleccion),
		CONSTRAINT FK_Partido_Seleccion_Eq2 FOREIGN KEY (Eq2) REFERENCES equipos.Seleccion(IdSeleccion),
		CONSTRAINT CK_Partido_Equipos CHECK (Eq1 <> Eq2),
		CONSTRAINT CK_Partido_MismoMundial CHECK (partidos.fnPartido_MismoMundial(Eq1, Eq2, IdMundial) = 1)
	)
END
GO

-- Migracion re-ejecutable para tablas existentes creadas sin IdMundial
IF COL_LENGTH('partidos.Partido', 'IdMundial') IS NULL
	ALTER TABLE partidos.Partido ADD IdMundial INT NULL
GO

-- Backfill con el IdMundial de Eq1 via equipos.Seleccion
IF COL_LENGTH('partidos.Partido', 'IdMundial') IS NOT NULL
AND EXISTS (SELECT 1 FROM partidos.Partido WHERE IdMundial IS NULL)
	UPDATE P SET P.IdMundial = S.IdMundial FROM partidos.Partido P INNER JOIN equipos.Seleccion S ON S.IdSeleccion = P.Eq1 WHERE P.IdMundial IS NULL
GO

-- Endurece a NOT NULL solo cuando ya no quedan nulos (re-ejecutable)
IF COL_LENGTH('partidos.Partido', 'IdMundial') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM partidos.Partido WHERE IdMundial IS NULL)
	ALTER TABLE partidos.Partido ALTER COLUMN IdMundial INT NOT NULL
GO

-- FK a sedes.Mundial solo cuando los datos ya estan saneados (re-ejecutable)
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Partido_Mundial')
AND COL_LENGTH('partidos.Partido', 'IdMundial') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM partidos.Partido WHERE IdMundial IS NULL)
	ALTER TABLE partidos.Partido ADD CONSTRAINT FK_Partido_Mundial FOREIGN KEY (IdMundial) REFERENCES sedes.Mundial(IdMundial)
GO

-- CHECK de mismo Mundial via equipos.Seleccion, solo con datos saneados (re-ejecutable)
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Partido_MismoMundial')
AND COL_LENGTH('partidos.Partido', 'IdMundial') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM partidos.Partido WHERE IdMundial IS NULL)
	ALTER TABLE partidos.Partido ADD CONSTRAINT CK_Partido_MismoMundial CHECK (partidos.fnPartido_MismoMundial(Eq1, Eq2, IdMundial) = 1)
GO
