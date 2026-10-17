--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: xx/xx/2026

--Testing de StoredProcedures asociados a la entidad PoseeHorario

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
CREATE TABLE sedes.HusoHorario
(
	IdHuso INT PRIMARY KEY
);
CREATE TABLE equipos.Pais
(
	IdPais INT PRIMARY KEY
);
GO

--llenado de tablas aux
INSERT INTO sedes.HusoHorario VALUES (1);
INSERT INTO equipos.Pais VALUES (1), (2);

SELECT * FROM sedes.HusoHorario;
SELECT * FROM equipos.Pais;
GO

--tablas a testear
CREATE TABLE sedes.PoseeHorario
(
	Horario INT,
	Pais INT,
	FOREIGN KEY(Horario) REFERENCES sedes.HusoHorario(IdHuso),
	FOREIGN KEY(Pais) REFERENCES equipos.Pais(IdPais),
	PRIMARY KEY(Horario, Pais)
)
GO

--SPs a testear
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspPoseeHorario_Registrar'))
    DROP PROCEDURE SP.uspPoseeHorario_Registrar
GO
CREATE PROCEDURE SP.uspPoseeHorario_Registrar
@horario INT,
@pais INT
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine varchar(300)
	
	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	--chequeo validez
	IF(@horario IS NULL) OR (@horario <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Horario.'
	END

	IF(@pais IS NULL) OR (@pais <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Pais.'
	END

	--chequeo existencia
	IF(@errorCount = 0)
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM sedes.HusoHorario WHERE IdHuso = @horario)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Horario.'
		END

		IF NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @pais)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Pais.'
		END
	END

	--chequeo duplicidad
	IF(@errorCount = 0) AND EXISTS(SELECT 1 FROM sedes.PoseeHorario WHERE Horario = @horario AND Pais = @pais)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Relacion ya existente.'
	END

	IF(@errorCount = 0)
	BEGIN
		INSERT INTO sedes.PoseeHorario
		VALUES (@horario, @pais)
	END
	ELSE
		PRINT @errorLine
END;
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspPoseeHorario_Bajar'))
    DROP PROCEDURE SP.uspPoseeHorario_Bajar
GO
CREATE PROCEDURE SP.uspPoseeHorario_Bajar
@horario INT,
@pais INT
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine varchar(300)
	
	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	--chequeo validez
	IF(@horario IS NULL) OR (@horario <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Horario.'
	END

	IF(@pais IS NULL) OR (@pais <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Pais.'
	END

	--chequeo existencia
	IF(@errorCount = 0)
	AND
	NOT EXISTS(SELECT 1 FROM sedes.PoseeHorario WHERE Horario = @horario AND Pais = @pais)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Relacion inexistente.'
	END

	IF(@errorCount = 0)
	BEGIN
		DELETE FROM sedes.PoseeHorario
		WHERE Horario = @horario AND Pais = @pais
	END
	ELSE
		PRINT @errorLine
END;
GO

--////Testing de Registro exitoso
EXECUTE SP.uspPoseeHorario_Registrar @horario = 1, @pais = 1;
EXECUTE SP.uspPoseeHorario_Registrar @horario = 1, @pais = 2;
SELECT * FROM sedes.PoseeHorario;
GO

--////Testing de Baja exitoso
EXECUTE SP.uspPoseeHorario_Bajar @horario = 1, @pais = 1;
SELECT * FROM sedes.PoseeHorario;
GO

--////Testing de Casos de Falla

--/registro
--datos invalidos
EXECUTE SP.uspPoseeHorario_Registrar @horario = 0, @pais = NULL;
GO
--datos inexistentes
EXECUTE SP.uspPoseeHorario_Registrar @horario = 45, @pais = 22;
GO
--relacion ya existente
EXECUTE SP.uspPoseeHorario_Registrar @horario = 1, @pais = 2;
GO

--baja
--datos invalidos
EXECUTE SP.uspPoseeHorario_Bajar @horario = 0, @pais = NULL;
GO
--relacion inexistente
EXECUTE SP.uspPoseeHorario_Bajar @horario = 45, @pais = 22;
GO

SELECT * FROM sedes.PoseeHorario;
GO

--Limpieza
DROP PROCEDURE SP.uspPoseeHorario_Registrar;
DROP PROCEDURE SP.uspPoseeHorario_Bajar;
GO

DROP TABLE sedes.PoseeHorario;
DROP TABLE equipos.Pais;
DROP TABLE sedes.HusoHorario;
GO

DROP SCHEMA equipos;
DROP SCHEMA sedes;
GO