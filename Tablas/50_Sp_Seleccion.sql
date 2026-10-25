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
	BEGIN TRY
		--Chequeo validez
		IF(@idPais IS NULL) OR (@idPais <= 0)
			THROW 50000, '- Valor invalido: Pais.', 1;

		IF(@idMundial IS NULL) OR (@idMundial <= 0)
			THROW 50000, '- Valor invalido: Mundial.', 1;

		IF(@idGrupo IS NULL) OR (@idGrupo <= 0)
			THROW 50000, '- Valor invalido: Grupo.', 1;

		IF(@confederacion IS NULL) OR (LTRIM(RTRIM(@confederacion)) = '')
			THROW 50000, '- Valor invalido: Confederacion.', 1;

		--Chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @idPais)
			THROW 50000, '- Valor inexistente: Pais.', 1;

		IF NOT EXISTS(SELECT 1 FROM sedes.Mundial WHERE IdMundial = @idMundial)
			THROW 50000, '- Valor inexistente: Mundial.', 1;

		IF NOT EXISTS(SELECT 1 FROM equipos.Grupo WHERE IdGrupo = @idGrupo)
			THROW 50000, '- Valor inexistente: Grupo.', 1;

		--Chequeo dup
		IF EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdPais = @idPais AND IdMundial = @idMundial)
			THROW 50000, '- Valor duplicado: Seleccion (pais y mundial).', 1;

		--Chequeo cupo (maximo 4 selecciones por grupo en cada mundial)
		IF (SELECT COUNT(*) FROM equipos.Seleccion WHERE IdMundial = @idMundial AND IdGrupo = @idGrupo) >= 4
			THROW 50000, '- Cupo excedido: el grupo ya tiene 4 selecciones en el mundial.', 1;

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
	DECLARE @vMundial INT

	BEGIN TRY
		--Chequeo validez
		IF(@idSeleccion IS NULL) OR (@idSeleccion <= 0)
			THROW 50000, '- Valor invalido: ID Seleccion.', 1;

		IF(@idPais IS NOT NULL) AND (@idPais <= 0)
			THROW 50000, '- Valor invalido: Pais.', 1;

		IF(@idMundial IS NOT NULL) AND (@idMundial <= 0)
			THROW 50000, '- Valor invalido: Mundial.', 1;

		IF(@idGrupo IS NOT NULL) AND (@idGrupo <= 0)
			THROW 50000, '- Valor invalido: Grupo.', 1;

		IF(@confederacion IS NOT NULL) AND (LTRIM(RTRIM(@confederacion)) = '')
			THROW 50000, '- Valor invalido: Confederacion.', 1;

		--Chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @idSeleccion)
			THROW 50000, '- Valor inexistente: ID Seleccion.', 1;

		IF(@idPais IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @idPais)
			THROW 50000, '- Valor inexistente: Pais.', 1;

		IF(@idMundial IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM sedes.Mundial WHERE IdMundial = @idMundial)
			THROW 50000, '- Valor inexistente: Mundial.', 1;

		IF(@idGrupo IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM equipos.Grupo WHERE IdGrupo = @idGrupo)
			THROW 50000, '- Valor inexistente: Grupo.', 1;

		--Chequeo dup
		IF(@idPais IS NOT NULL) AND (@idMundial IS NOT NULL)
		   AND EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdPais = @idPais AND IdMundial = @idMundial AND IdSeleccion <> @idSeleccion)
			THROW 50000, '- Valor duplicado: Seleccion (pais y mundial).', 1;

		--Chequeo cupo (maximo 4 selecciones por grupo en cada mundial, sin contar la propia)
		IF(@idGrupo IS NOT NULL)
		BEGIN
			SET @vMundial = COALESCE(@idMundial, (SELECT IdMundial FROM equipos.Seleccion WHERE IdSeleccion = @idSeleccion))

			IF (SELECT COUNT(*) FROM equipos.Seleccion WHERE IdMundial = @vMundial AND IdGrupo = @idGrupo AND IdSeleccion <> @idSeleccion) >= 4
				THROW 50000, '- Cupo excedido: el grupo ya tiene 4 selecciones en el mundial.', 1;
		END

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
	BEGIN TRY
		--Chequeo validez
		IF(@idSeleccion IS NULL) OR (@idSeleccion <= 0)
			THROW 50000, '- Valor invalido: ID Seleccion.', 1;

		--Chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @idSeleccion)
			THROW 50000, '- Valor inexistente: ID Seleccion.', 1;

		--Chequeo relaciones
		IF EXISTS(SELECT 1 FROM equipos.Jugador WHERE Seleccion = @idSeleccion)
			THROW 50000, '- Existen 1 o mas registros relacionados: Jugador. Elimine dichos registros para continuar.', 1;

		IF EXISTS(SELECT 1 FROM equipos.Tecnico WHERE Seleccion = @idSeleccion)
			THROW 50000, '- Existen 1 o mas registros relacionados: Tecnico. Elimine dichos registros para continuar.', 1;

		IF EXISTS(SELECT 1 FROM partidos.Partido WHERE Eq1 = @idSeleccion OR Eq2 = @idSeleccion)
			THROW 50000, '- Existen 1 o mas registros relacionados: Partido. Elimine dichos registros para continuar.', 1;

		IF EXISTS(SELECT 1 FROM partidos.Alineacion A
				INNER JOIN equipos.Jugador J ON J.IdJugador = A.IdJugador
				WHERE J.Seleccion = @idSeleccion)
			THROW 50000, '- Existen 1 o mas registros relacionados: Alineacion. Elimine dichos registros para continuar.', 1;

		IF EXISTS(SELECT 1 FROM equipos.CambioConvocatoria WHERE Seleccion = @idSeleccion)
			THROW 50000, '- Existen 1 o mas registros relacionados: CambioConvocatoria. Elimine dichos registros para continuar.', 1;

		DELETE FROM equipos.Seleccion WHERE IdSeleccion = @idSeleccion
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO