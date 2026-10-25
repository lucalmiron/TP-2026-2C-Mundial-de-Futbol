--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 09/10/2026

--Objetivo: Gestionar Tabla PublicidadPais (solo Registrar y Bajar, PK inmutable)

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspPublicidadPais_Registrar'))
    DROP PROCEDURE SP.uspPublicidadPais_Registrar
GO
CREATE PROCEDURE SP.uspPublicidadPais_Registrar
@idPublicidad INT,
@idPais INT
AS
BEGIN
	BEGIN TRY
		IF (@idPublicidad IS NULL) OR (@idPublicidad <= 0)
			THROW 50000, '- Valor invalido: ID Publicidad.', 1;

		IF (@idPais IS NULL) OR (@idPais <= 0)
			THROW 50000, '- Valor invalido: ID Pais.', 1;

		IF NOT EXISTS (SELECT 1 FROM publicidad.Publicidad WHERE IdPublicidad = @idPublicidad)
			THROW 50000, '- Valor inexistente: ID Publicidad.', 1;

		IF NOT EXISTS (SELECT 1 FROM equipos.Pais WHERE IdPais = @idPais)
			THROW 50000, '- Valor inexistente: ID Pais.', 1;

		IF EXISTS (SELECT 1 FROM publicidad.PublicidadPais WHERE IdPublicidad = @idPublicidad AND IdPais = @idPais)
			THROW 50000, '- Valor duplicado: PublicidadPais.', 1;

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
	BEGIN TRY
		IF (@idPublicidad IS NULL) OR (@idPublicidad <= 0)
			THROW 50000, '- Valor invalido: ID Publicidad.', 1;

		IF (@idPais IS NULL) OR (@idPais <= 0)
			THROW 50000, '- Valor invalido: ID Pais.', 1;

		IF NOT EXISTS (SELECT 1 FROM publicidad.PublicidadPais WHERE IdPublicidad = @idPublicidad AND IdPais = @idPais)
			THROW 50000, '- Valor inexistente: PublicidadPais.', 1;

		DELETE FROM publicidad.PublicidadPais WHERE IdPublicidad = @idPublicidad AND IdPais = @idPais
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO