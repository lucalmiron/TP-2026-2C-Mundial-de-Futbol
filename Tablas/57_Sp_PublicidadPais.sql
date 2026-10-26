--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Objetivo: Gestionar Tabla PublicidadPais (solo Registrar y Bajar, PK inmutable)

-- Ejecutar en la base seleccionada por el instalador.
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspPublicidadPais_Registrar'))
    DROP PROCEDURE SP.uspPublicidadPais_Registrar
GO
CREATE PROCEDURE SP.uspPublicidadPais_Registrar
@idPublicidad INT,
@idPais INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF (@idPublicidad IS NULL) OR (@idPublicidad <= 0)
			SET @errores += '- Valor invalido: ID Publicidad.' + N' ';

		IF (@idPais IS NULL) OR (@idPais <= 0)
			SET @errores += '- Valor invalido: ID Pais.' + N' ';

		IF NOT EXISTS (SELECT 1 FROM publicidad.Publicidad WHERE IdPublicidad = @idPublicidad)
			SET @errores += '- Valor inexistente: ID Publicidad.' + N' ';

		IF NOT EXISTS (SELECT 1 FROM equipos.Pais WHERE IdPais = @idPais)
			SET @errores += '- Valor inexistente: ID Pais.' + N' ';

		IF EXISTS (SELECT 1 FROM publicidad.PublicidadPais WHERE IdPublicidad = @idPublicidad AND IdPais = @idPais)
			SET @errores += '- Valor duplicado: PublicidadPais.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		INSERT INTO publicidad.PublicidadPais (IdPublicidad, IdPais)
		VALUES (@idPublicidad, @idPais)
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspPublicidadPais_Bajar'))
    DROP PROCEDURE SP.uspPublicidadPais_Bajar
GO
CREATE PROCEDURE SP.uspPublicidadPais_Bajar
@idPublicidad INT,
@idPais INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF (@idPublicidad IS NULL) OR (@idPublicidad <= 0)
			SET @errores += '- Valor invalido: ID Publicidad.' + N' ';

		IF (@idPais IS NULL) OR (@idPais <= 0)
			SET @errores += '- Valor invalido: ID Pais.' + N' ';

		IF NOT EXISTS (SELECT 1 FROM publicidad.PublicidadPais WHERE IdPublicidad = @idPublicidad AND IdPais = @idPais)
			SET @errores += '- Valor inexistente: PublicidadPais.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		DELETE FROM publicidad.PublicidadPais WHERE IdPublicidad = @idPublicidad AND IdPais = @idPais
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO