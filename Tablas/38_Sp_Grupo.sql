--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 25/10/26

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
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF (@nombre IS NULL) OR (LTRIM(RTRIM(@nombre)) = '')
			SET @errores += '- Valor invalido: Nombre.' + N' ';

		IF EXISTS (SELECT 1 FROM equipos.Grupo WHERE NOMBRE = LTRIM(RTRIM(@nombre)))
			SET @errores += '- Valor duplicado: Grupo (nombre).' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

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
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF (@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Grupo.' + N' ';

		IF (@nombre IS NULL) OR (LTRIM(RTRIM(@nombre)) = '')
			SET @errores += '- Valor invalido: Nombre.' + N' ';

		IF NOT EXISTS (SELECT 1 FROM equipos.Grupo WHERE IdGrupo = @id)
			SET @errores += '- Valor inexistente: ID Grupo.' + N' ';

		IF EXISTS (SELECT 1 FROM equipos.Grupo WHERE NOMBRE = LTRIM(RTRIM(@nombre)) AND IdGrupo <> @id)
			SET @errores += '- Valor duplicado: Grupo (nombre).' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

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
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF (@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Grupo.' + N' ';

		IF NOT EXISTS (SELECT 1 FROM equipos.Grupo WHERE IdGrupo = @id)
			SET @errores += '- Valor inexistente: ID Grupo.' + N' ';

		IF EXISTS (SELECT 1 FROM equipos.Seleccion WHERE IdGrupo = @id)
			SET @errores += '- Existen 1 o mas registros relacionados: Seleccion. Elimine dichos registros para continuar.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		DELETE FROM equipos.Grupo WHERE IdGrupo = @id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO