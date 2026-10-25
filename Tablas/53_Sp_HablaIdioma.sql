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
	BEGIN TRY
		IF(@arbitro IS NULL) OR (@arbitro <= 0)
			THROW 50000, '- Valor invalido: Arbitro.', 1;

		IF(@idioma IS NULL) OR (@idioma <= 0)
			THROW 50000, '- Valor invalido: Idioma.', 1;

		IF NOT EXISTS(SELECT 1 FROM arbitros.Arbitro WHERE IdArbitro = @arbitro)
			THROW 50000, '- Valor inexistente: Arbitro.', 1;

		IF NOT EXISTS(SELECT 1 FROM arbitros.Idioma WHERE IdIdioma = @idioma)
			THROW 50000, '- Valor inexistente: Idioma.', 1;

		IF EXISTS(SELECT 1 FROM arbitros.HablaIdioma WHERE Arbitro = @arbitro AND Idioma = @idioma)
			THROW 50000, '- Valor duplicado: Idioma.', 1;

		INSERT INTO arbitros.HablaIdioma VALUES (@arbitro, @idioma)
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspHablaIdioma_Bajar'))
    DROP PROCEDURE SP.uspHablaIdioma_Bajar
GO
CREATE PROCEDURE SP.uspHablaIdioma_Bajar @arbitro INT, @idioma INT
AS
BEGIN
	BEGIN TRY
		IF(@arbitro IS NULL) OR (@arbitro <= 0)
			THROW 50000, '- Valor invalido: Arbitro.', 1;

		IF(@idioma IS NULL) OR (@idioma <= 0)
			THROW 50000, '- Valor invalido: Idioma.', 1;

		IF NOT EXISTS(SELECT 1 FROM arbitros.Arbitro WHERE IdArbitro = @arbitro)
			THROW 50000, '- Valor inexistente: Arbitro.', 1;

		IF NOT EXISTS(SELECT 1 FROM arbitros.Idioma WHERE IdIdioma = @idioma)
			THROW 50000, '- Valor inexistente: Idioma.', 1;

		IF NOT EXISTS(SELECT 1 FROM arbitros.HablaIdioma WHERE Arbitro = @arbitro AND Idioma = @idioma)
			THROW 50000, '- Registro inexistente.', 1;

		DELETE FROM arbitros.HablaIdioma WHERE Arbitro = @arbitro AND Idioma = @idioma
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO