--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 09/10/2026

--Objetivo: Gestionar Tabla Grupo

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspGrupo_Registrar'))
    DROP PROCEDURE SP.uspGrupo_Registrar
GO
CREATE PROCEDURE SP.uspGrupo_Registrar
@nombre VARCHAR(10)
AS
BEGIN
	BEGIN TRY
		IF (@nombre IS NULL) OR (LTRIM(RTRIM(@nombre)) = '')
			THROW 50000, '- Valor invalido: Nombre.', 1;

		IF EXISTS (SELECT 1 FROM equipos.Grupo WHERE NOMBRE = LTRIM(RTRIM(@nombre)))
			THROW 50000, '- Valor duplicado: Grupo (nombre).', 1;

		INSERT INTO equipos.Grupo (NOMBRE)
		VALUES (LTRIM(RTRIM(@nombre)))
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspGrupo_Update'))
    DROP PROCEDURE SP.uspGrupo_Update
GO
CREATE PROCEDURE SP.uspGrupo_Update
@id INT,
@nombre VARCHAR(10)
AS
BEGIN
	BEGIN TRY
		IF (@id IS NULL) OR (@id <= 0)
			THROW 50000, '- Valor invalido: ID Grupo.', 1;

		IF (@nombre IS NULL) OR (LTRIM(RTRIM(@nombre)) = '')
			THROW 50000, '- Valor invalido: Nombre.', 1;

		IF NOT EXISTS (SELECT 1 FROM equipos.Grupo WHERE IdGrupo = @id)
			THROW 50000, '- Valor inexistente: ID Grupo.', 1;

		IF EXISTS (SELECT 1 FROM equipos.Grupo WHERE NOMBRE = LTRIM(RTRIM(@nombre)) AND IdGrupo <> @id)
			THROW 50000, '- Valor duplicado: Grupo (nombre).', 1;

		UPDATE equipos.Grupo
		SET NOMBRE = LTRIM(RTRIM(@nombre))
		WHERE IdGrupo = @id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspGrupo_Bajar'))
    DROP PROCEDURE SP.uspGrupo_Bajar
GO
CREATE PROCEDURE SP.uspGrupo_Bajar
@id INT
AS
BEGIN
	BEGIN TRY
		IF (@id IS NULL) OR (@id <= 0)
			THROW 50000, '- Valor invalido: ID Grupo.', 1;

		IF NOT EXISTS (SELECT 1 FROM equipos.Grupo WHERE IdGrupo = @id)
			THROW 50000, '- Valor inexistente: ID Grupo.', 1;

		IF EXISTS (SELECT 1 FROM equipos.Seleccion WHERE IdGrupo = @id)
			THROW 50000, '- Existen 1 o mas registros relacionados: Seleccion. Elimine dichos registros para continuar.', 1;

		DELETE FROM equipos.Grupo WHERE IdGrupo = @id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO