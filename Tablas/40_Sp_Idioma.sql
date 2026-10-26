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

--Idioma
IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspIdioma_Registrar'))
    DROP PROCEDURE SP.uspIdioma_Registrar
GO
CREATE PROCEDURE SP.uspIdioma_Registrar @descripcion VARCHAR(20)
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF(@descripcion IS NULL)
			SET @errores += '- Valor invalido: Descripcion.' + N' ';

		IF EXISTS(SELECT 1 FROM arbitros.Idioma WHERE Descripcion = @descripcion)
			SET @errores += '- Valor duplicado: Descripcion.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		INSERT INTO arbitros.Idioma(Descripcion) VALUES (@descripcion)
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspIdioma_Update'))
    DROP PROCEDURE SP.uspIdioma_Update
GO
CREATE PROCEDURE SP.uspIdioma_Update @id INT, @descripcion VARCHAR(20)
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF(@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Idioma.' + N' ';

		IF(@descripcion IS NULL)
			SET @errores += '- Valor invalido: Descripcion.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM arbitros.Idioma WHERE IdIdioma = @id)
			SET @errores += '- Valor inexistente: ID Idioma.' + N' ';

		IF EXISTS(SELECT 1 FROM arbitros.Idioma WHERE Descripcion = @descripcion AND IdIdioma <> @id)
			SET @errores += '- Valor duplicado: Descripcion.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		UPDATE arbitros.Idioma
		SET Descripcion = @descripcion
		WHERE IdIdioma = @id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspIdioma_Bajar'))
    DROP PROCEDURE SP.uspIdioma_Bajar
GO
CREATE PROCEDURE SP.uspIdioma_Bajar @id INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF(@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Idioma.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM arbitros.Idioma WHERE IdIdioma = @id)
			SET @errores += '- Valor inexistente: ID Idioma.' + N' ';

		IF EXISTS(SELECT 1 FROM arbitros.HablaIdioma WHERE Idioma = @id)
			SET @errores += '- Existen 1 o mas registros relacionados: HablaIdioma. Elimine dichos registros para continuar.' + N' ';

		IF EXISTS(SELECT 1 FROM publicidad.Publicidad WHERE IdIdioma = @id)
			SET @errores += '- Existen 1 o mas registros relacionados: Publicidad. Elimine dichos registros para continuar.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		DELETE FROM arbitros.Idioma WHERE IdIdioma = @id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO