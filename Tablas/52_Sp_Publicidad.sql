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

--Publicidad
IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspPublicidad_Registrar'))
    DROP PROCEDURE SP.uspPublicidad_Registrar
GO
CREATE PROCEDURE SP.uspPublicidad_Registrar @nombre VARCHAR(50), @idCampania INT, @idIdioma INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF(@nombre IS NULL)
			SET @errores += '- Valor invalido: Nombre.' + N' ';

		IF(@idCampania IS NULL) OR (@idCampania <= 0)
			SET @errores += '- Valor invalido: ID Campania.' + N' ';

		IF(@idIdioma IS NULL) OR (@idIdioma <= 0)
			SET @errores += '- Valor invalido: ID Idioma.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM publicidad.Campania WHERE IdCampania = @idCampania)
			SET @errores += '- Valor inexistente: ID Campania.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM arbitros.Idioma WHERE IdIdioma = @idIdioma)
			SET @errores += '- Valor inexistente: ID Idioma.' + N' ';

		IF EXISTS(SELECT 1 FROM publicidad.Publicidad WHERE Nombre = @nombre)
			SET @errores += '- Valor duplicado: Nombre.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

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
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF(@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Publicidad.' + N' ';

		IF(@nombre IS NULL)
			SET @errores += '- Valor invalido: Nombre.' + N' ';

		IF(@idCampania IS NULL) OR (@idCampania <= 0)
			SET @errores += '- Valor invalido: ID Campania.' + N' ';

		IF(@idIdioma IS NULL) OR (@idIdioma <= 0)
			SET @errores += '- Valor invalido: ID Idioma.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM publicidad.Publicidad WHERE IdPublicidad = @id)
			SET @errores += '- Valor inexistente: ID Publicidad.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM publicidad.Campania WHERE IdCampania = @idCampania)
			SET @errores += '- Valor inexistente: ID Campania.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM arbitros.Idioma WHERE IdIdioma = @idIdioma)
			SET @errores += '- Valor inexistente: ID Idioma.' + N' ';

		IF EXISTS(SELECT 1 FROM publicidad.Publicidad WHERE Nombre = @nombre AND IdPublicidad <> @id)
			SET @errores += '- Valor duplicado: Nombre.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

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
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF(@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Publicidad.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM publicidad.Publicidad WHERE IdPublicidad = @id)
			SET @errores += '- Valor inexistente: ID Publicidad.' + N' ';

		IF EXISTS(SELECT 1 FROM publicidad.HistorialPublicidad WHERE IdPublicidad = @id)
			SET @errores += '- Existen 1 o mas registros relacionados: HistorialPublicidad. Elimine dichos registros para continuar.' + N' ';

		IF EXISTS(SELECT 1 FROM publicidad.PublicidadPais WHERE IdPublicidad = @id)
			SET @errores += '- Existen 1 o mas registros relacionados: PublicidadPais. Elimine dichos registros para continuar.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		DELETE FROM publicidad.Publicidad WHERE IdPublicidad = @id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO