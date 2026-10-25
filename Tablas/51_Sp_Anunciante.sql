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

--Anunciante
IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspAnunciante_Registrar'))
    DROP PROCEDURE SP.uspAnunciante_Registrar
GO
CREATE PROCEDURE SP.uspAnunciante_Registrar @nombre VARCHAR(50), @idPais INT
AS
BEGIN
	BEGIN TRY
		IF(@nombre IS NULL)
			THROW 50000, '- Valor invalido: Nombre.', 1;

		IF(@idPais IS NULL) OR (@idPais <= 0)
			THROW 50000, '- Valor invalido: ID Pais.', 1;

		IF NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @idPais)
			THROW 50000, '- Valor inexistente: ID Pais.', 1;

		IF EXISTS(SELECT 1 FROM publicidad.Anunciante WHERE Nombre = @nombre)
			THROW 50000, '- Valor duplicado: Nombre.', 1;

		INSERT INTO publicidad.Anunciante(Nombre, IdPais) VALUES (@nombre, @idPais)
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspAnunciante_Update'))
    DROP PROCEDURE SP.uspAnunciante_Update
GO
CREATE PROCEDURE SP.uspAnunciante_Update @id INT, @nombre VARCHAR(50), @idPais INT
AS
BEGIN
	BEGIN TRY
		IF(@id IS NULL) OR (@id <= 0)
			THROW 50000, '- Valor invalido: ID Anunciante.', 1;

		IF(@nombre IS NULL)
			THROW 50000, '- Valor invalido: Nombre.', 1;

		IF(@idPais IS NULL) OR (@idPais <= 0)
			THROW 50000, '- Valor invalido: ID Pais.', 1;

		IF NOT EXISTS(SELECT 1 FROM publicidad.Anunciante WHERE IdAnunciante = @id)
			THROW 50000, '- Valor inexistente: ID Anunciante.', 1;

		IF NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @idPais)
			THROW 50000, '- Valor inexistente: ID Pais.', 1;

		IF EXISTS(SELECT 1 FROM publicidad.Anunciante WHERE Nombre = @nombre AND IdAnunciante <> @id)
			THROW 50000, '- Valor duplicado: Nombre.', 1;

		UPDATE publicidad.Anunciante
		SET Nombre = @nombre, IdPais = @idPais
		WHERE IdAnunciante = @id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspAnunciante_Bajar'))
    DROP PROCEDURE SP.uspAnunciante_Bajar
GO
CREATE PROCEDURE SP.uspAnunciante_Bajar @id INT
AS
BEGIN
	BEGIN TRY
		IF(@id IS NULL) OR (@id <= 0)
			THROW 50000, '- Valor invalido: ID Anunciante.', 1;

		IF NOT EXISTS(SELECT 1 FROM publicidad.Anunciante WHERE IdAnunciante = @id)
			THROW 50000, '- Valor inexistente: ID Anunciante.', 1;

		IF EXISTS(SELECT 1 FROM publicidad.AnuncianteCampania WHERE IdAnunciante = @id)
			THROW 50000, '- Existen 1 o mas registros relacionados: AnuncianteCampania. Elimine dichos registros para continuar.', 1;

		DELETE FROM publicidad.Anunciante WHERE IdAnunciante = @id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO