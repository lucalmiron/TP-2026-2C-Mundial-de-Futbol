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

--Anunciante
IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspAnunciante_Registrar'))
    DROP PROCEDURE SP.uspAnunciante_Registrar
GO
CREATE PROCEDURE SP.uspAnunciante_Registrar @nombre VARCHAR(50), @idPais INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF(@nombre IS NULL)
			SET @errores += '- Valor invalido: Nombre.' + N' ';

		IF(@idPais IS NULL) OR (@idPais <= 0)
			SET @errores += '- Valor invalido: ID Pais.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @idPais)
			SET @errores += '- Valor inexistente: ID Pais.' + N' ';

		IF EXISTS(SELECT 1 FROM publicidad.Anunciante WHERE Nombre = @nombre)
			SET @errores += '- Valor duplicado: Nombre.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

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
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF(@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Anunciante.' + N' ';

		IF(@nombre IS NULL)
			SET @errores += '- Valor invalido: Nombre.' + N' ';

		IF(@idPais IS NULL) OR (@idPais <= 0)
			SET @errores += '- Valor invalido: ID Pais.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM publicidad.Anunciante WHERE IdAnunciante = @id)
			SET @errores += '- Valor inexistente: ID Anunciante.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @idPais)
			SET @errores += '- Valor inexistente: ID Pais.' + N' ';

		IF EXISTS(SELECT 1 FROM publicidad.Anunciante WHERE Nombre = @nombre AND IdAnunciante <> @id)
			SET @errores += '- Valor duplicado: Nombre.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

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
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF(@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Anunciante.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM publicidad.Anunciante WHERE IdAnunciante = @id)
			SET @errores += '- Valor inexistente: ID Anunciante.' + N' ';

		IF EXISTS(SELECT 1 FROM publicidad.AnuncianteCampania WHERE IdAnunciante = @id)
			SET @errores += '- Existen 1 o mas registros relacionados: AnuncianteCampania. Elimine dichos registros para continuar.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		DELETE FROM publicidad.Anunciante WHERE IdAnunciante = @id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO