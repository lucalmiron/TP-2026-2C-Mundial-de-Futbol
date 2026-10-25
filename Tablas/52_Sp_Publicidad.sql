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

--Publicidad
IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspPublicidad_Registrar'))
    DROP PROCEDURE SP.uspPublicidad_Registrar
GO
CREATE PROCEDURE SP.uspPublicidad_Registrar @nombre VARCHAR(50), @idCampania INT, @idIdioma INT
AS
BEGIN
	BEGIN TRY
		IF(@nombre IS NULL)
			THROW 50000, '- Valor invalido: Nombre.', 1;

		IF(@idCampania IS NULL) OR (@idCampania <= 0)
			THROW 50000, '- Valor invalido: ID Campania.', 1;

		IF(@idIdioma IS NULL) OR (@idIdioma <= 0)
			THROW 50000, '- Valor invalido: ID Idioma.', 1;

		IF NOT EXISTS(SELECT 1 FROM publicidad.Campania WHERE IdCampania = @idCampania)
			THROW 50000, '- Valor inexistente: ID Campania.', 1;

		IF NOT EXISTS(SELECT 1 FROM arbitros.Idioma WHERE IdIdioma = @idIdioma)
			THROW 50000, '- Valor inexistente: ID Idioma.', 1;

		IF EXISTS(SELECT 1 FROM publicidad.Publicidad WHERE Nombre = @nombre)
			THROW 50000, '- Valor duplicado: Nombre.', 1;

		INSERT INTO publicidad.Publicidad(Nombre, IdCampania, IdIdioma) VALUES (@nombre, @idCampania, @idIdioma)
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspPublicidad_Update'))
    DROP PROCEDURE SP.uspPublicidad_Update
GO
CREATE PROCEDURE SP.uspPublicidad_Update @id INT, @nombre VARCHAR(50), @idCampania INT, @idIdioma INT
AS
BEGIN
	BEGIN TRY
		IF(@id IS NULL) OR (@id <= 0)
			THROW 50000, '- Valor invalido: ID Publicidad.', 1;

		IF(@nombre IS NULL)
			THROW 50000, '- Valor invalido: Nombre.', 1;

		IF(@idCampania IS NULL) OR (@idCampania <= 0)
			THROW 50000, '- Valor invalido: ID Campania.', 1;

		IF(@idIdioma IS NULL) OR (@idIdioma <= 0)
			THROW 50000, '- Valor invalido: ID Idioma.', 1;

		IF NOT EXISTS(SELECT 1 FROM publicidad.Publicidad WHERE IdPublicidad = @id)
			THROW 50000, '- Valor inexistente: ID Publicidad.', 1;

		IF NOT EXISTS(SELECT 1 FROM publicidad.Campania WHERE IdCampania = @idCampania)
			THROW 50000, '- Valor inexistente: ID Campania.', 1;

		IF NOT EXISTS(SELECT 1 FROM arbitros.Idioma WHERE IdIdioma = @idIdioma)
			THROW 50000, '- Valor inexistente: ID Idioma.', 1;

		IF EXISTS(SELECT 1 FROM publicidad.Publicidad WHERE Nombre = @nombre AND IdPublicidad <> @id)
			THROW 50000, '- Valor duplicado: Nombre.', 1;

		UPDATE publicidad.Publicidad
		SET Nombre = @nombre, IdCampania = @idCampania, IdIdioma = @idIdioma
		WHERE IdPublicidad = @id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspPublicidad_Bajar'))
    DROP PROCEDURE SP.uspPublicidad_Bajar
GO
CREATE PROCEDURE SP.uspPublicidad_Bajar @id INT
AS
BEGIN
	BEGIN TRY
		IF(@id IS NULL) OR (@id <= 0)
			THROW 50000, '- Valor invalido: ID Publicidad.', 1;

		IF NOT EXISTS(SELECT 1 FROM publicidad.Publicidad WHERE IdPublicidad = @id)
			THROW 50000, '- Valor inexistente: ID Publicidad.', 1;

		IF EXISTS(SELECT 1 FROM publicidad.HistorialPublicidad WHERE IdPublicidad = @id)
			THROW 50000, '- Existen 1 o mas registros relacionados: HistorialPublicidad. Elimine dichos registros para continuar.', 1;

		IF EXISTS(SELECT 1 FROM publicidad.PublicidadPais WHERE IdPublicidad = @id)
			THROW 50000, '- Existen 1 o mas registros relacionados: PublicidadPais. Elimine dichos registros para continuar.', 1;

		DELETE FROM publicidad.Publicidad WHERE IdPublicidad = @id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO