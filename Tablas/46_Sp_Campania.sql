--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 25/10/26

--Creacion de Stored Procedures

IF EXISTS(SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

--Campania
IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspCampania_Registrar'))
    DROP PROCEDURE SP.uspCampania_Registrar
GO
CREATE PROCEDURE SP.uspCampania_Registrar @nombre VARCHAR(50), @descripcion VARCHAR(200)
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF(@nombre IS NULL)
			SET @errores += '- Valor invalido: Nombre.' + N' ';

		IF(@descripcion IS NULL)
			SET @errores += '- Valor invalido: Descripcion.' + N' ';

		IF EXISTS(SELECT 1 FROM publicidad.Campania WHERE Nombre = @nombre)
			SET @errores += '- Valor duplicado: Nombre.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		INSERT INTO publicidad.Campania(Nombre, Descripcion) VALUES (@nombre, @descripcion)
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspCampania_Update'))
    DROP PROCEDURE SP.uspCampania_Update
GO
CREATE PROCEDURE SP.uspCampania_Update @id INT, @nombre VARCHAR(50), @descripcion VARCHAR(200)
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF(@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Campania.' + N' ';

		IF(@nombre IS NULL)
			SET @errores += '- Valor invalido: Nombre.' + N' ';

		IF(@descripcion IS NULL)
			SET @errores += '- Valor invalido: Descripcion.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM publicidad.Campania WHERE IdCampania = @id)
			SET @errores += '- Valor inexistente: ID Campania.' + N' ';

		IF EXISTS(SELECT 1 FROM publicidad.Campania WHERE Nombre = @nombre AND IdCampania <> @id)
			SET @errores += '- Valor duplicado: Nombre.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		UPDATE publicidad.Campania
		SET Nombre = @nombre, Descripcion = @descripcion
		WHERE IdCampania = @id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspCampania_Bajar'))
    DROP PROCEDURE SP.uspCampania_Bajar
GO
CREATE PROCEDURE SP.uspCampania_Bajar @id INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF(@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Campania.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM publicidad.Campania WHERE IdCampania = @id)
			SET @errores += '- Valor inexistente: ID Campania.' + N' ';

		IF EXISTS(SELECT 1 FROM publicidad.Publicidad WHERE IdCampania = @id)
			SET @errores += '- Existen 1 o mas registros relacionados: Publicidad. Elimine dichos registros para continuar.' + N' ';

		IF EXISTS(SELECT 1 FROM publicidad.AnuncianteCampania WHERE IdCampania = @id)
			SET @errores += '- Existen 1 o mas registros relacionados: AnuncianteCampania. Elimine dichos registros para continuar.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		DELETE FROM publicidad.Campania WHERE IdCampania = @id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO