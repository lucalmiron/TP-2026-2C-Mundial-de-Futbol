--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 08/10/2026

--Creacion de Stored Procedures (ABM de Pais)

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspPais_Registrar'))
    DROP PROCEDURE SP.uspPais_Registrar
GO
CREATE PROCEDURE SP.uspPais_Registrar
@nombre VARCHAR(50),
@pbi BIGINT = NULL
AS
BEGIN
	BEGIN TRY
		--Chequeo validez
		IF(@nombre IS NULL) OR (LTRIM(RTRIM(@nombre)) = '')
			THROW 50000, '- Valor invalido: Nombre.', 1;

		IF(@pbi IS NOT NULL) AND (@pbi < 0)
			THROW 50000, '- Valor invalido: PBI.', 1;

		--Chequeo dup
		IF EXISTS(SELECT 1 FROM equipos.Pais WHERE NOMBRE = LTRIM(RTRIM(@nombre)))
			THROW 50000, '- Valor duplicado: Pais (nombre).', 1;

		INSERT INTO equipos.Pais(NOMBRE, PBI)
		VALUES(LTRIM(RTRIM(@nombre)), @pbi)
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspPais_Update'))
    DROP PROCEDURE SP.uspPais_Update
GO
CREATE PROCEDURE SP.uspPais_Update
@idPais INT,
@nombre VARCHAR(50) = NULL,
@pbi BIGINT = NULL
AS
BEGIN
	BEGIN TRY
		--Chequeo validez
		IF(@idPais IS NULL) OR (@idPais <= 0)
			THROW 50000, '- Valor invalido: ID Pais.', 1;

		IF(@nombre IS NOT NULL) AND (LTRIM(RTRIM(@nombre)) = '')
			THROW 50000, '- Valor invalido: Nombre.', 1;

		IF(@pbi IS NOT NULL) AND (@pbi < 0)
			THROW 50000, '- Valor invalido: PBI.', 1;

		--Chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @idPais)
			THROW 50000, '- Valor inexistente: ID Pais.', 1;

		--Chequeo dup
		IF(@nombre IS NOT NULL)
		   AND EXISTS(SELECT 1 FROM equipos.Pais WHERE NOMBRE = LTRIM(RTRIM(@nombre)) AND IdPais <> @idPais)
			THROW 50000, '- Valor duplicado: Pais (nombre).', 1;

		UPDATE equipos.Pais
		SET NOMBRE = COALESCE(LTRIM(RTRIM(@nombre)), NOMBRE),
			PBI = COALESCE(@pbi, PBI)
		WHERE IdPais = @idPais
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspPais_Bajar'))
    DROP PROCEDURE SP.uspPais_Bajar
GO
CREATE PROCEDURE SP.uspPais_Bajar
@idPais INT
AS
BEGIN
	BEGIN TRY
		--Chequeo validez
		IF(@idPais IS NULL) OR (@idPais <= 0)
			THROW 50000, '- Valor invalido: ID Pais.', 1;

		--Chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @idPais)
			THROW 50000, '- Valor inexistente: ID Pais.', 1;

		--Chequeo relaciones
		IF EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdPais = @idPais)
			THROW 50000, '- Existen 1 o mas registros relacionados: Seleccion. Elimine dichos registros para continuar.', 1;

		IF EXISTS(SELECT 1 FROM sedes.Mundial WHERE IdPais = @idPais)
			THROW 50000, '- Existen 1 o mas registros relacionados: Mundial. Elimine dichos registros para continuar.', 1;

		IF EXISTS(SELECT 1 FROM sedes.HusoHorario WHERE IdPais = @idPais)
			THROW 50000, '- Existen 1 o mas registros relacionados: HusoHorario. Elimine dichos registros para continuar.', 1;

		IF EXISTS(SELECT 1 FROM sedes.Sede WHERE IdPais = @idPais)
			THROW 50000, '- Existen 1 o mas registros relacionados: Sede. Elimine dichos registros para continuar.', 1;

		IF EXISTS(SELECT 1 FROM equipos.Persona WHERE Pais = @idPais)
			THROW 50000, '- Existen 1 o mas registros relacionados: Persona. Elimine dichos registros para continuar.', 1;

		IF EXISTS(SELECT 1 FROM publicidad.Anunciante WHERE IdPais = @idPais)
			THROW 50000, '- Existen 1 o mas registros relacionados: Anunciante. Elimine dichos registros para continuar.', 1;

		IF EXISTS(SELECT 1 FROM publicidad.PublicidadPais WHERE IdPais = @idPais)
			THROW 50000, '- Existen 1 o mas registros relacionados: PublicidadPais. Elimine dichos registros para continuar.', 1;

		DELETE FROM equipos.Pais WHERE IdPais = @idPais
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO