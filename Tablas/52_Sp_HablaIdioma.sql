--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 08/10/2026

--Creacion de Stored Procedures

IF EXISTS(SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

--HablaIdioma
IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspHablaIdioma_Registrar'))
    DROP PROCEDURE SP.uspHablaIdioma_Registrar
GO
CREATE PROCEDURE SP.uspHablaIdioma_Registrar @arbitro INT, @idioma INT
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine varchar(300)

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	IF(@arbitro IS NULL) OR (@arbitro <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Arbitro.'
	END

	IF(@idioma IS NULL) OR (@idioma <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Idioma.'
	END

	IF(@errorCount = 0)
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM arbitros.Arbitro WHERE IdArbitro = @arbitro)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Arbitro.'
		END

		IF NOT EXISTS(SELECT 1 FROM arbitros.Idioma WHERE IdIdioma = @idioma)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Idioma.'
		END
	END

	IF(@errorCount = 0) AND EXISTS(SELECT 1 FROM arbitros.HablaIdioma WHERE Arbitro = @arbitro AND Idioma = @idioma)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor duplicado: Idioma.'
	END

	IF(@errorCount = 0)
		INSERT INTO arbitros.HablaIdioma VALUES (@arbitro, @idioma)
	ELSE
		PRINT @errorLine
END;
GO

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspHablaIdioma_Bajar'))
    DROP PROCEDURE SP.uspHablaIdioma_Bajar
GO
CREATE PROCEDURE SP.uspHablaIdioma_Bajar @arbitro INT, @idioma INT
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine varchar(300)

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	IF(@arbitro IS NULL) OR (@arbitro <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Arbitro.'
	END

	IF(@idioma IS NULL) OR (@idioma <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Idioma.'
	END

	IF(@errorCount = 0)
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM arbitros.Arbitro WHERE IdArbitro = @arbitro)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Arbitro.'
		END

		IF NOT EXISTS(SELECT 1 FROM arbitros.Idioma WHERE IdIdioma = @idioma)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Idioma.'
		END
	END

	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM arbitros.HablaIdioma WHERE Arbitro = @arbitro AND Idioma = @idioma)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Registro inexistente.'
	END

	IF(@errorCount = 0)
		DELETE FROM arbitros.HablaIdioma WHERE Arbitro = @arbitro AND Idioma = @idioma
	ELSE
		PRINT @errorLine
END;
GO
