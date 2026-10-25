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

--Idioma
IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspIdioma_Registrar'))
    DROP PROCEDURE SP.uspIdioma_Registrar
GO
CREATE PROCEDURE SP.uspIdioma_Registrar @descripcion VARCHAR(20)
AS
BEGIN
	BEGIN TRY
		IF(@descripcion IS NULL)
			THROW 50000, '- Valor invalido: Descripcion.', 1;

		IF EXISTS(SELECT 1 FROM arbitros.Idioma WHERE Descripcion = @descripcion)
			THROW 50000, '- Valor duplicado: Descripcion.', 1;

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
	BEGIN TRY
		IF(@id IS NULL) OR (@id <= 0)
			THROW 50000, '- Valor invalido: ID Idioma.', 1;

		IF(@descripcion IS NULL)
			THROW 50000, '- Valor invalido: Descripcion.', 1;

		IF NOT EXISTS(SELECT 1 FROM arbitros.Idioma WHERE IdIdioma = @id)
			THROW 50000, '- Valor inexistente: ID Idioma.', 1;

		IF EXISTS(SELECT 1 FROM arbitros.Idioma WHERE Descripcion = @descripcion AND IdIdioma <> @id)
			THROW 50000, '- Valor duplicado: Descripcion.', 1;

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
	BEGIN TRY
		IF(@id IS NULL) OR (@id <= 0)
			THROW 50000, '- Valor invalido: ID Idioma.', 1;

		IF NOT EXISTS(SELECT 1 FROM arbitros.Idioma WHERE IdIdioma = @id)
			THROW 50000, '- Valor inexistente: ID Idioma.', 1;

		IF EXISTS(SELECT 1 FROM arbitros.HablaIdioma WHERE Idioma = @id)
			THROW 50000, '- Existen 1 o mas registros relacionados: HablaIdioma. Elimine dichos registros para continuar.', 1;

		IF EXISTS(SELECT 1 FROM publicidad.Publicidad WHERE IdIdioma = @id)
			THROW 50000, '- Existen 1 o mas registros relacionados: Publicidad. Elimine dichos registros para continuar.', 1;

		DELETE FROM arbitros.Idioma WHERE IdIdioma = @id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO