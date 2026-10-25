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

--Campania
IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspCampania_Registrar'))
    DROP PROCEDURE SP.uspCampania_Registrar
GO
CREATE PROCEDURE SP.uspCampania_Registrar @nombre VARCHAR(50), @descripcion VARCHAR(200)
AS
BEGIN
	BEGIN TRY
		IF(@nombre IS NULL)
			THROW 50000, '- Valor invalido: Nombre.', 1;

		IF(@descripcion IS NULL)
			THROW 50000, '- Valor invalido: Descripcion.', 1;

		IF EXISTS(SELECT 1 FROM publicidad.Campania WHERE Nombre = @nombre)
			THROW 50000, '- Valor duplicado: Nombre.', 1;

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
	BEGIN TRY
		IF(@id IS NULL) OR (@id <= 0)
			THROW 50000, '- Valor invalido: ID Campania.', 1;

		IF(@nombre IS NULL)
			THROW 50000, '- Valor invalido: Nombre.', 1;

		IF(@descripcion IS NULL)
			THROW 50000, '- Valor invalido: Descripcion.', 1;

		IF NOT EXISTS(SELECT 1 FROM publicidad.Campania WHERE IdCampania = @id)
			THROW 50000, '- Valor inexistente: ID Campania.', 1;

		IF EXISTS(SELECT 1 FROM publicidad.Campania WHERE Nombre = @nombre AND IdCampania <> @id)
			THROW 50000, '- Valor duplicado: Nombre.', 1;

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
	BEGIN TRY
		IF(@id IS NULL) OR (@id <= 0)
			THROW 50000, '- Valor invalido: ID Campania.', 1;

		IF NOT EXISTS(SELECT 1 FROM publicidad.Campania WHERE IdCampania = @id)
			THROW 50000, '- Valor inexistente: ID Campania.', 1;

		IF EXISTS(SELECT 1 FROM publicidad.Publicidad WHERE IdCampania = @id)
			THROW 50000, '- Existen 1 o mas registros relacionados: Publicidad. Elimine dichos registros para continuar.', 1;

		IF EXISTS(SELECT 1 FROM publicidad.AnuncianteCampania WHERE IdCampania = @id)
			THROW 50000, '- Existen 1 o mas registros relacionados: AnuncianteCampania. Elimine dichos registros para continuar.', 1;

		DELETE FROM publicidad.Campania WHERE IdCampania = @id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO