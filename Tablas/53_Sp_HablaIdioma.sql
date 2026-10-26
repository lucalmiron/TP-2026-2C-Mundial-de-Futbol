--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Creacion de Stored Procedures

-- Ejecutar en la base seleccionada por el instalador.
GO

--HablaIdioma
IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspHablaIdioma_Registrar'))
    DROP PROCEDURE SP.uspHablaIdioma_Registrar
GO
CREATE PROCEDURE SP.uspHablaIdioma_Registrar @arbitro INT, @idioma INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF(@arbitro IS NULL) OR (@arbitro <= 0)
			SET @errores += '- Valor invalido: Arbitro.' + N' ';

		IF(@idioma IS NULL) OR (@idioma <= 0)
			SET @errores += '- Valor invalido: Idioma.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM arbitros.Arbitro WHERE IdArbitro = @arbitro)
			SET @errores += '- Valor inexistente: Arbitro.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM arbitros.Idioma WHERE IdIdioma = @idioma)
			SET @errores += '- Valor inexistente: Idioma.' + N' ';

		IF EXISTS(SELECT 1 FROM arbitros.HablaIdioma WHERE Arbitro = @arbitro AND Idioma = @idioma)
			SET @errores += '- Valor duplicado: Idioma.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

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
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF(@arbitro IS NULL) OR (@arbitro <= 0)
			SET @errores += '- Valor invalido: Arbitro.' + N' ';

		IF(@idioma IS NULL) OR (@idioma <= 0)
			SET @errores += '- Valor invalido: Idioma.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM arbitros.Arbitro WHERE IdArbitro = @arbitro)
			SET @errores += '- Valor inexistente: Arbitro.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM arbitros.Idioma WHERE IdIdioma = @idioma)
			SET @errores += '- Valor inexistente: Idioma.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM arbitros.HablaIdioma WHERE Arbitro = @arbitro AND Idioma = @idioma)
			SET @errores += '- Registro inexistente.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		DELETE FROM arbitros.HablaIdioma WHERE Arbitro = @arbitro AND Idioma = @idioma
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO