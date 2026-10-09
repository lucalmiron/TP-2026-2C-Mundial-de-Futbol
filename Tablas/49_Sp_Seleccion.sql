--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 08/10/2026

--Creacion de Stored Procedures

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspSeleccion_Registrar'))
    DROP PROCEDURE SP.uspSeleccion_Registrar
GO
CREATE PROCEDURE SP.uspSeleccion_Registrar
@idPais INT,
@idMundial INT,
@idGrupo INT,
@confederacion VARCHAR(45)
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine varchar(800)

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	--Chequeo validez
	IF(@idPais IS NULL) OR (@idPais <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Pais.'
	END

	IF(@idMundial IS NULL) OR (@idMundial <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Mundial.'
	END

	IF(@idGrupo IS NULL) OR (@idGrupo <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Grupo.'
	END

	IF(@confederacion IS NULL) OR (LTRIM(RTRIM(@confederacion)) = '')
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Confederacion.'
	END

	--Chequeo existencia
	IF(@errorCount = 0)
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @idPais)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Pais.'
		END

		IF NOT EXISTS(SELECT 1 FROM sedes.Mundial WHERE IdMundial = @idMundial)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Mundial.'
		END

		IF NOT EXISTS(SELECT 1 FROM equipos.Grupo WHERE IdGrupo = @idGrupo)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Grupo.'
		END
	END

	--Chequeo dup
	IF(@errorCount = 0) AND EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdPais = @idPais AND IdMundial = @idMundial)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor duplicado: Seleccion (pais y mundial).'
	END

	--Chequeo cupo (maximo 4 selecciones por grupo en cada mundial)
	IF(@errorCount = 0) AND (SELECT COUNT(*) FROM equipos.Seleccion WHERE IdMundial = @idMundial AND IdGrupo = @idGrupo) >= 4
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Cupo excedido: el grupo ya tiene 4 selecciones en el mundial.'
	END

	IF(@errorCount = 0)
	BEGIN
		BEGIN TRY
			INSERT INTO equipos.Seleccion(IdPais, IdMundial, IdGrupo, CONFEDERACION)
			VALUES(@idPais, @idMundial, @idGrupo, LTRIM(RTRIM(@confederacion)))
		END TRY
		BEGIN CATCH
			PRINT CONCAT('ERROR (', ERROR_NUMBER(), '): ', ERROR_MESSAGE())
		END CATCH
	END
	ELSE
		PRINT @errorLine
END;
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspSeleccion_Update'))
    DROP PROCEDURE SP.uspSeleccion_Update
GO
CREATE PROCEDURE SP.uspSeleccion_Update
@idSeleccion INT,
@idPais INT = NULL,
@idMundial INT = NULL,
@idGrupo INT = NULL,
@confederacion VARCHAR(45) = NULL
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine varchar(800)

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	--Chequeo validez
	IF(@idSeleccion IS NULL) OR (@idSeleccion <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Seleccion.'
	END

	IF(@idPais IS NOT NULL) AND (@idPais <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Pais.'
	END

	IF(@idMundial IS NOT NULL) AND (@idMundial <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Mundial.'
	END

	IF(@idGrupo IS NOT NULL) AND (@idGrupo <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Grupo.'
	END

	IF(@confederacion IS NOT NULL) AND (LTRIM(RTRIM(@confederacion)) = '')
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Confederacion.'
	END

	--Chequeo existencia
	IF(@errorCount = 0)
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @idSeleccion)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: ID Seleccion.'
		END

		IF(@idPais IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @idPais)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Pais.'
		END

		IF(@idMundial IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM sedes.Mundial WHERE IdMundial = @idMundial)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Mundial.'
		END

		IF(@idGrupo IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM equipos.Grupo WHERE IdGrupo = @idGrupo)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Grupo.'
		END
	END

	--Chequeo dup
	IF(@errorCount = 0) AND (@idPais IS NOT NULL) AND (@idMundial IS NOT NULL)
	   AND EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdPais = @idPais AND IdMundial = @idMundial AND IdSeleccion <> @idSeleccion)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor duplicado: Seleccion (pais y mundial).'
	END

	--Chequeo cupo (maximo 4 selecciones por grupo en cada mundial, sin contar la propia)
	IF(@errorCount = 0) AND (@idGrupo IS NOT NULL)
	BEGIN
		DECLARE @vMundial INT = COALESCE(@idMundial, (SELECT IdMundial FROM equipos.Seleccion WHERE IdSeleccion = @idSeleccion))

		IF (SELECT COUNT(*) FROM equipos.Seleccion WHERE IdMundial = @vMundial AND IdGrupo = @idGrupo AND IdSeleccion <> @idSeleccion) >= 4
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Cupo excedido: el grupo ya tiene 4 selecciones en el mundial.'
		END
	END

	IF(@errorCount = 0)
	BEGIN
		BEGIN TRY
			UPDATE equipos.Seleccion
			SET IdPais = COALESCE(@idPais, IdPais),
				IdMundial = COALESCE(@idMundial, IdMundial),
				IdGrupo = COALESCE(@idGrupo, IdGrupo),
				CONFEDERACION = COALESCE(LTRIM(RTRIM(@confederacion)), CONFEDERACION)
			WHERE IdSeleccion = @idSeleccion
		END TRY
		BEGIN CATCH
			PRINT CONCAT('ERROR (', ERROR_NUMBER(), '): ', ERROR_MESSAGE())
		END CATCH
	END
	ELSE
		PRINT @errorLine
END;
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspSeleccion_Bajar'))
    DROP PROCEDURE SP.uspSeleccion_Bajar
GO
CREATE PROCEDURE SP.uspSeleccion_Bajar
@idSeleccion INT
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine varchar(800)

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	--Chequeo validez
	IF(@idSeleccion IS NULL) OR (@idSeleccion <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Seleccion.'
	END

	--Chequeo existencia
	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @idSeleccion)
	BEGIN
		SET @errorCount = @errorCount + 1
	SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: ID Seleccion.'
	END

	--Chequeo relaciones
	IF(@errorCount = 0)
	BEGIN
		IF EXISTS(SELECT 1 FROM equipos.Jugador WHERE Seleccion = @idSeleccion)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Existen 1 o mas registros relacionados: Jugador. Elimine dichos registros para continuar.'
		END

		IF EXISTS(SELECT 1 FROM equipos.Tecnico WHERE Seleccion = @idSeleccion)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Existen 1 o mas registros relacionados: Tecnico. Elimine dichos registros para continuar.'
		END

		IF EXISTS(SELECT 1 FROM partidos.Partido WHERE Eq1 = @idSeleccion OR Eq2 = @idSeleccion)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Existen 1 o mas registros relacionados: Partido. Elimine dichos registros para continuar.'
		END

		IF EXISTS(SELECT 1 FROM partidos.Alineacion WHERE IdSeleccion = @idSeleccion)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Existen 1 o mas registros relacionados: Alineacion. Elimine dichos registros para continuar.'
		END
	END

	IF(@errorCount = 0)
	BEGIN
		BEGIN TRY
			DELETE FROM equipos.Seleccion WHERE IdSeleccion = @idSeleccion
		END TRY
		BEGIN CATCH
			PRINT CONCAT('ERROR (', ERROR_NUMBER(), '): ', ERROR_MESSAGE())
		END CATCH
	END
	ELSE
		PRINT @errorLine
END;
GO