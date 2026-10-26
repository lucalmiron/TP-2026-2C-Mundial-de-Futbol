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
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		--Chequeo validez
		IF(@idPais IS NULL) OR (@idPais <= 0)
			SET @errores += '- Valor invalido: Pais.' + N' ';

		IF(@idMundial IS NULL) OR (@idMundial <= 0)
			SET @errores += '- Valor invalido: Mundial.' + N' ';

		IF(@idGrupo IS NULL) OR (@idGrupo <= 0)
			SET @errores += '- Valor invalido: Grupo.' + N' ';

		IF(@confederacion IS NULL) OR (LTRIM(RTRIM(@confederacion)) = '')
			SET @errores += '- Valor invalido: Confederacion.' + N' ';

		--Chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @idPais)
			SET @errores += '- Valor inexistente: Pais.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM sedes.Mundial WHERE IdMundial = @idMundial)
			SET @errores += '- Valor inexistente: Mundial.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM equipos.Grupo WHERE IdGrupo = @idGrupo)
			SET @errores += '- Valor inexistente: Grupo.' + N' ';

		--Chequeo dup
		IF EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdPais = @idPais AND IdMundial = @idMundial)
			SET @errores += '- Valor duplicado: Seleccion (pais y mundial).' + N' ';

		--Chequeo cupo (maximo 4 selecciones por grupo en cada mundial)
		IF (SELECT COUNT(*) FROM equipos.Seleccion WHERE IdMundial = @idMundial AND IdGrupo = @idGrupo) >= 4
			SET @errores += '- Cupo excedido: el grupo ya tiene 4 selecciones en el mundial.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		INSERT INTO equipos.Seleccion(IdPais, IdMundial, IdGrupo, CONFEDERACION)
		VALUES(@idPais, @idMundial, @idGrupo, LTRIM(RTRIM(@confederacion)))
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
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
	DECLARE @errores NVARCHAR(2048) = N'';
	DECLARE @vMundial INT

	BEGIN TRY
		--Chequeo validez
		IF(@idSeleccion IS NULL) OR (@idSeleccion <= 0)
			SET @errores += '- Valor invalido: ID Seleccion.' + N' ';

		IF(@idPais IS NOT NULL) AND (@idPais <= 0)
			SET @errores += '- Valor invalido: Pais.' + N' ';

		IF(@idMundial IS NOT NULL) AND (@idMundial <= 0)
			SET @errores += '- Valor invalido: Mundial.' + N' ';

		IF(@idGrupo IS NOT NULL) AND (@idGrupo <= 0)
			SET @errores += '- Valor invalido: Grupo.' + N' ';

		IF(@confederacion IS NOT NULL) AND (LTRIM(RTRIM(@confederacion)) = '')
			SET @errores += '- Valor invalido: Confederacion.' + N' ';

		--Chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @idSeleccion)
			SET @errores += '- Valor inexistente: ID Seleccion.' + N' ';

		IF(@idPais IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @idPais)
			SET @errores += '- Valor inexistente: Pais.' + N' ';

		IF(@idMundial IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM sedes.Mundial WHERE IdMundial = @idMundial)
			SET @errores += '- Valor inexistente: Mundial.' + N' ';

		IF(@idGrupo IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM equipos.Grupo WHERE IdGrupo = @idGrupo)
			SET @errores += '- Valor inexistente: Grupo.' + N' ';

		--Chequeo dup
		IF(@idPais IS NOT NULL) AND (@idMundial IS NOT NULL)
		   AND EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdPais = @idPais AND IdMundial = @idMundial AND IdSeleccion <> @idSeleccion)
			SET @errores += '- Valor duplicado: Seleccion (pais y mundial).' + N' ';

		--Chequeo cupo (maximo 4 selecciones por grupo en cada mundial, sin contar la propia)
		IF(@idGrupo IS NOT NULL)
		BEGIN
			SET @vMundial = COALESCE(@idMundial, (SELECT IdMundial FROM equipos.Seleccion WHERE IdSeleccion = @idSeleccion))

			IF (SELECT COUNT(*) FROM equipos.Seleccion WHERE IdMundial = @vMundial AND IdGrupo = @idGrupo AND IdSeleccion <> @idSeleccion) >= 4
				SET @errores += '- Cupo excedido: el grupo ya tiene 4 selecciones en el mundial.' + N' ';
		END

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		UPDATE equipos.Seleccion
		SET IdPais = COALESCE(@idPais, IdPais),
			IdMundial = COALESCE(@idMundial, IdMundial),
			IdGrupo = COALESCE(@idGrupo, IdGrupo),
			CONFEDERACION = COALESCE(LTRIM(RTRIM(@confederacion)), CONFEDERACION)
		WHERE IdSeleccion = @idSeleccion
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspSeleccion_Bajar'))
    DROP PROCEDURE SP.uspSeleccion_Bajar
GO
CREATE PROCEDURE SP.uspSeleccion_Bajar
@idSeleccion INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		--Chequeo validez
		IF(@idSeleccion IS NULL) OR (@idSeleccion <= 0)
			SET @errores += '- Valor invalido: ID Seleccion.' + N' ';

		--Chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @idSeleccion)
			SET @errores += '- Valor inexistente: ID Seleccion.' + N' ';

		--Chequeo relaciones
		IF EXISTS(SELECT 1 FROM equipos.Jugador WHERE Seleccion = @idSeleccion)
			SET @errores += '- Existen 1 o mas registros relacionados: Jugador. Elimine dichos registros para continuar.' + N' ';

		IF EXISTS(SELECT 1 FROM equipos.Tecnico WHERE Seleccion = @idSeleccion)
			SET @errores += '- Existen 1 o mas registros relacionados: Tecnico. Elimine dichos registros para continuar.' + N' ';

		IF EXISTS(SELECT 1 FROM partidos.Partido WHERE Eq1 = @idSeleccion OR Eq2 = @idSeleccion)
			SET @errores += '- Existen 1 o mas registros relacionados: Partido. Elimine dichos registros para continuar.' + N' ';

		IF EXISTS(SELECT 1 FROM partidos.Alineacion A
				INNER JOIN equipos.Jugador J ON J.IdJugador = A.IdJugador
				WHERE J.Seleccion = @idSeleccion)
			SET @errores += '- Existen 1 o mas registros relacionados: Alineacion. Elimine dichos registros para continuar.' + N' ';

		IF EXISTS(SELECT 1 FROM equipos.CambioConvocatoria WHERE Seleccion = @idSeleccion)
			SET @errores += '- Existen 1 o mas registros relacionados: CambioConvocatoria. Elimine dichos registros para continuar.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		DELETE FROM equipos.Seleccion WHERE IdSeleccion = @idSeleccion
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO