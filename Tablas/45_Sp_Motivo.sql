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

--Motivo
IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspMotivo_Registrar'))
    DROP PROCEDURE SP.uspMotivo_Registrar
GO
CREATE PROCEDURE SP.uspMotivo_Registrar @descripcion VARCHAR(100)
AS
BEGIN
	BEGIN TRY
		IF(@descripcion IS NULL)
			THROW 50000, '- Valor invalido: Descripcion.', 1;

		IF EXISTS(SELECT 1 FROM publicidad.Motivo WHERE Descripcion = @descripcion)
			THROW 50000, '- Valor duplicado: Descripcion.', 1;

		INSERT INTO publicidad.Motivo(Descripcion) VALUES (@descripcion)
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspMotivo_Update'))
    DROP PROCEDURE SP.uspMotivo_Update
GO
CREATE PROCEDURE SP.uspMotivo_Update @id INT, @descripcion VARCHAR(100)
AS
BEGIN
	BEGIN TRY
		IF(@id IS NULL) OR (@id <= 0)
			THROW 50000, '- Valor invalido: ID Motivo.', 1;

		IF(@descripcion IS NULL)
			THROW 50000, '- Valor invalido: Descripcion.', 1;

		IF NOT EXISTS(SELECT 1 FROM publicidad.Motivo WHERE IdMotivo = @id)
			THROW 50000, '- Valor inexistente: ID Motivo.', 1;

		IF EXISTS(SELECT 1 FROM publicidad.Motivo WHERE Descripcion = @descripcion AND IdMotivo <> @id)
			THROW 50000, '- Valor duplicado: Descripcion.', 1;

		UPDATE publicidad.Motivo
		SET Descripcion = @descripcion
		WHERE IdMotivo = @id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspMotivo_Bajar'))
    DROP PROCEDURE SP.uspMotivo_Bajar
GO
CREATE PROCEDURE SP.uspMotivo_Bajar @id INT
AS
BEGIN
	BEGIN TRY
		IF(@id IS NULL) OR (@id <= 0)
			THROW 50000, '- Valor invalido: ID Motivo.', 1;

		IF NOT EXISTS(SELECT 1 FROM publicidad.Motivo WHERE IdMotivo = @id)
			THROW 50000, '- Valor inexistente: ID Motivo.', 1;

		IF EXISTS(SELECT 1 FROM partidos.Sustitucion WHERE Motivo = @id)
			THROW 50000, '- Existen 1 o mas registros relacionados: Sustitucion. Elimine dichos registros para continuar.', 1;

		DELETE FROM publicidad.Motivo WHERE IdMotivo = @id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO