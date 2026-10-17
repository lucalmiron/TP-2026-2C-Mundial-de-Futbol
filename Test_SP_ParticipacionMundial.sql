--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: xx/xx/2026

--Testing de StoredProcedures asociados a la entidad ParticipacionMundial

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIALtesting')
BEGIN
	USE MUNDIALtesting
END;
GO

--esquemas
CREATE SCHEMA sedes;
GO
CREATE SCHEMA equipos;
GO

--tablas auxiliares de testing
CREATE TABLE sedes.Mundial
(
	IdMundial INT PRIMARY KEY
);
CREATE TABLE equipos.Seleccion
(
	IdSeleccion INT PRIMARY KEY
);
GO

--llenado de tablas aux
INSERT INTO sedes.Mundial VALUES (1);
INSERT INTO equipos.Seleccion VALUES (1), (2);

SELECT * FROM sedes.Mundial;
SELECT * FROM equipos.Seleccion;
GO

--tablas a testear
CREATE TABLE equipos.ParticipacionMundial
(
	Mundial INT,
	Seleccion INT,
	FOREIGN KEY(Mundial) REFERENCES sedes.Mundial(IdMundial),
	FOREIGN KEY(Seleccion) REFERENCES equipos.Seleccion(IdSeleccion),
	PRIMARY KEY(Mundial, Seleccion)
)
GO

--SPs a testear
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspParticipacionMundial_Registrar'))
    DROP PROCEDURE SP.uspParticipacionMundial_Registrar
GO
CREATE PROCEDURE SP.uspParticipacionMundial_Registrar
@mundial INT,
@seleccion INT
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine varchar(300)
	
	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	--chequeo validez
	IF(@mundial IS NULL) OR (@mundial <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Mundial.'
	END

	IF(@seleccion IS NULL) OR (@seleccion <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Seleccion.'
	END

	--chequeo existencia
	IF(@errorCount = 0)
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM sedes.Mundial WHERE IdMundial = @mundial)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Mundial.'
		END

		IF NOT EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @seleccion)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Seleccion.'
		END
	END

	--chequeo duplicidad
	IF(@errorCount = 0) AND EXISTS(SELECT 1 FROM equipos.ParticipacionMundial WHERE Mundial = @mundial AND Seleccion = @seleccion)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Relacion ya existente.'
	END

	IF(@errorCount = 0)
	BEGIN
		INSERT INTO equipos.ParticipacionMundial
		VALUES (@mundial, @seleccion)
	END
	ELSE
		PRINT @errorLine
END;
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspParticipacionMundial_Bajar'))
    DROP PROCEDURE SP.uspParticipacionMundial_Bajar
GO
CREATE PROCEDURE SP.uspParticipacionMundial_Bajar
@mundial INT,
@seleccion INT
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine varchar(300)
	
	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	--chequeo validez
	IF(@mundial IS NULL) OR (@mundial <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Mundial.'
	END

	IF(@seleccion IS NULL) OR (@seleccion <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Seleccion.'
	END

	--chequeo existencia
	IF(@errorCount = 0)
	AND
	NOT EXISTS(SELECT 1 FROM equipos.ParticipacionMundial WHERE Mundial = @mundial AND Seleccion = @seleccion)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Relacion inexistente.'
	END

	IF(@errorCount = 0)
	BEGIN
		DELETE FROM equipos.ParticipacionMundial
		WHERE Mundial = @mundial AND Seleccion = @seleccion
	END
	ELSE
		PRINT @errorLine
END;
GO

--////Testing de Registro exitoso
EXECUTE SP.uspParticipacionMundial_Registrar @mundial = 1, @seleccion = 1;
EXECUTE SP.uspParticipacionMundial_Registrar @mundial = 1, @seleccion = 2;
SELECT * FROM equipos.ParticipacionMundial;
GO

--////Testing de Baja exitoso
EXECUTE SP.uspParticipacionMundial_Bajar @mundial = 1, @seleccion = 1;
SELECT * FROM equipos.ParticipacionMundial;
GO

--////Testing de Casos de Falla

--/registro
--datos invalidos
EXECUTE SP.uspParticipacionMundial_Registrar @mundial = 0, @seleccion = NULL;
--datos inexistentes
EXECUTE SP.uspParticipacionMundial_Registrar @mundial = 45, @seleccion = 22;
--relacion ya existente
EXECUTE SP.uspParticipacionMundial_Registrar @mundial = 1, @seleccion = 2;
GO

--baja
--datos invalidos
EXECUTE SP.uspParticipacionMundial_Bajar @mundial = 0, @seleccion = NULL;
--relacion inexistente
EXECUTE SP.uspParticipacionMundial_Bajar @mundial = 45, @seleccion = 22;
GO

SELECT * FROM equipos.ParticipacionMundial;
GO

--Limpieza
DROP PROCEDURE SP.uspParticipacionMundial_Registrar;
DROP PROCEDURE SP.uspParticipacionMundial_Bajar;
GO

DROP TABLE equipos.ParticipacionMundial;
DROP TABLE equipos.Seleccion;
DROP TABLE sedes.Mundial;
GO

DROP SCHEMA equipos;
DROP SCHEMA sedes;
GO