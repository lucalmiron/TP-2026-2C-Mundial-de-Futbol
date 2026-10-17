--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: xx/xx/2026

--Testing de StoredProcedures asociados a la entidad SedeMundial

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
CREATE TABLE equipos.Pais
(
	IdPais INT PRIMARY KEY
);
GO

--llenado de tablas aux
INSERT INTO sedes.Mundial VALUES (1);
INSERT INTO equipos.Pais VALUES (1), (2);

SELECT * FROM sedes.Mundial;
SELECT * FROM equipos.Pais;
GO

--tablas a testear
CREATE TABLE sedes.SedeMundial
(
	Mundial INT,
	Pais INT,
	FOREIGN KEY(Mundial) REFERENCES sedes.Mundial(IdMundial),
	FOREIGN KEY(Pais) REFERENCES equipos.Pais(IdPais),
	PRIMARY KEY(Mundial, Pais)
);
GO

--SPs a testear
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspSedeMundial_Registrar'))
    DROP PROCEDURE SP.uspSedeMundial_Registrar
GO
CREATE PROCEDURE SP.uspSedeMundial_Registrar
@mundial INT,
@pais INT
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

	IF(@pais IS NULL) OR (@pais <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Pais.'
	END

	--chequeo existencia
	IF(@errorCount = 0)
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM sedes.Mundial WHERE IdMundial = @mundial)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Mundial.'
		END

		IF NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @pais)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Pais.'
		END
	END

	--chequeo duplicidad
	IF(@errorCount = 0) AND EXISTS(SELECT 1 FROM sedes.SedeMundial WHERE Mundial = @mundial AND Pais = @pais)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Relacion ya existente.'
	END

	IF(@errorCount = 0)
	BEGIN
		INSERT INTO sedes.SedeMundial
		VALUES (@mundial, @pais)
	END
	ELSE
		PRINT @errorLine
END;
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspSedeMundial_Bajar'))
    DROP PROCEDURE SP.uspSedeMundial_Bajar
GO
CREATE PROCEDURE SP.uspSedeMundial_Bajar
@mundial INT,
@pais INT
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

	IF(@pais IS NULL) OR (@pais <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Pais.'
	END

	--chequeo existencia
	IF(@errorCount = 0)
	AND
	NOT EXISTS(SELECT 1 FROM sedes.SedeMundial WHERE Mundial = @mundial AND Pais = @pais)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Relacion inexistente.'
	END

	IF(@errorCount = 0)
	BEGIN
		DELETE FROM sedes.SedeMundial
		WHERE Mundial = @mundial AND Pais = @pais
	END
	ELSE
		PRINT @errorLine
END;
GO

--////Testing de Registro exitoso
EXECUTE SP.uspSedeMundial_Registrar @mundial = 1, @pais = 1;
EXECUTE SP.uspSedeMundial_Registrar @mundial = 1, @pais = 2;
SELECT * FROM sedes.SedeMundial;
GO

--////Testing de Baja exitoso
EXECUTE SP.uspSedeMundial_Bajar @mundial = 1, @pais = 1;
SELECT * FROM sedes.SedeMundial;
GO

--////Testing de Casos de Falla

--/registro
--datos invalidos
EXECUTE SP.uspSedeMundial_Registrar @mundial = 0, @pais = NULL;
GO
--datos inexistentes
EXECUTE SP.uspSedeMundial_Registrar @mundial = 45, @pais = 22;
GO
--relacion ya existente
EXECUTE SP.uspSedeMundial_Registrar @mundial = 1, @pais = 2;
GO

--baja
--datos invalidos
EXECUTE SP.uspSedeMundial_Bajar @mundial = 0, @pais = NULL;
GO
--relacion inexistente
EXECUTE SP.uspSedeMundial_Bajar @mundial = 45, @pais = 22;
GO

SELECT * FROM sedes.SedeMundial;
GO

--Limpieza
DROP PROCEDURE SP.uspSedeMundial_Registrar;
DROP PROCEDURE SP.uspSedeMundial_Bajar;
GO

DROP TABLE sedes.SedeMundial;
DROP TABLE equipos.Pais;
DROP TABLE sedes.Mundial;
GO

DROP SCHEMA equipos;
DROP SCHEMA sedes;
GO