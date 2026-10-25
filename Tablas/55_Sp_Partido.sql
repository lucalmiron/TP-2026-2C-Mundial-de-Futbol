-- Universidad Nacional de La Matanza
-- Bases de datos aplicada
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 08/10/2026
-- Objetivo: Gestionar Tabla Partido

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID ('SP.uspPartido_Registrar'))
	DROP PROCEDURE SP.uspPartido_Registrar
GO

-- Nota: el marcador oficial (GolesEq1/GolesEq2) lo mueve Gol via
-- SPTRANS.uspGol_Registrar y SPTRANS.uspGol_Bajar, por eso el alta inserta siempre 0-0
CREATE PROCEDURE SP.uspPartido_Registrar
@IdFase INT, @IdSede INT, @IdMundial INT, @Eq1 INT, @Eq2 INT,
@Fecha DATE, @HoraUTC TIME, @HoraLocal TIME,
@Asistencia INT = NULL
AS
BEGIN
	BEGIN TRY
		IF (@IdFase IS NULL OR @IdFase <= 0)
			THROW 50000, '- Valor invalido: Fase', 1;

		IF (@IdSede IS NULL OR @IdSede <= 0)
			THROW 50000, '- Valor invalido: Sede', 1;

		IF (@IdMundial IS NULL OR @IdMundial <= 0)
			THROW 50000, '- Valor invalido: Mundial', 1;

		IF (@Fecha IS NULL)
			THROW 50000, '- Valor invalido: Fecha', 1;

		IF (@HoraUTC IS NULL OR @HoraLocal IS NULL)
			THROW 50000, '- Valor invalido: Hora', 1;

		IF (@Eq1 IS NULL OR @Eq2 IS NULL)
			THROW 50000, '- Deben registrarse ambos equipos', 1;

		IF (@Eq1 IS NOT NULL AND @Eq2 IS NOT NULL AND @Eq1 = @Eq2)
			THROW 50000, '- Un equipo no puede ser su propio rival', 1;

		IF(@Asistencia IS NOT NULL AND @Asistencia<0)
			THROW 50000, '- La asistencia no puede ser negativa', 1;

		IF NOT EXISTS(SELECT 1 FROM partidos.Fase WHERE IdFase = @IdFase)
			THROW 50000, '- Valor inexistente: Fase', 1;

		IF NOT EXISTS(SELECT 1 FROM sedes.Mundial WHERE IdMundial = @IdMundial)
			THROW 50000, '- Valor inexistente: Mundial', 1;

		IF NOT EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @Eq1)
			THROW 50000, '- Valor inexistente: Eq1', 1;

		IF NOT EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @Eq2)
			THROW 50000, '- Valor inexistente: Eq2', 1;

		IF NOT EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @Eq1 AND IdMundial = @IdMundial)
			THROW 50000, '- Eq1 no pertenece al Mundial', 1;

		IF NOT EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @Eq2 AND IdMundial = @IdMundial)
			THROW 50000, '- Eq2 no pertenece al Mundial', 1;

		IF EXISTS(SELECT 1 FROM partidos.Partido WHERE Eq1 = @Eq1 AND Eq2 = @Eq2 AND Fecha = @Fecha AND IdFase = @IdFase)
			THROW 50000, '- Partido duplicado', 1;

		INSERT INTO partidos.Partido(IdFase, IdSede, IdMundial, Eq1, Eq2, Fecha, HoraUTC, HoraLocal, GolesEq1, GolesEq2, Asistencia)
		VALUES(@IdFase, @IdSede, @IdMundial, @Eq1, @Eq2, @Fecha, @HoraUTC, @HoraLocal, 0, 0, @Asistencia)
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO

----------------------------------------------------------------------------------------------------------------

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspPartido_Update'))
	DROP PROCEDURE SP.uspPartido_Update
GO

-- Nota: el marcador oficial (GolesEq1/GolesEq2) lo mueve Gol via
-- SPTRANS.uspGol_Registrar y SPTRANS.uspGol_Bajar. Los parametros de goles se conservan por compatibilidad, pero se rechazan
CREATE PROCEDURE SP.uspPartido_Update
@Id INT,
@IdFase INT = NULL,
@IdSede INT = NULL,
@IdMundial INT = NULL,
@Eq1 INT = NULL,
@Eq2 INT = NULL,
@Fecha DATE = NULL,
@HoraUTC TIME = NULL,
@HoraLocal TIME = NULL,
@GolesEq1 INT = NULL,
@GolesEq2 INT = NULL,
@Asistencia INT = NULL
AS
BEGIN
	DECLARE @vMundial INT
	DECLARE @vEq1 INT
	DECLARE @vEq2 INT

	BEGIN TRY
		IF (@Id IS NULL OR @Id <= 0)
			THROW 50000, '- Valor invalido: Id', 1;

		IF (@IdFase IS NOT NULL AND @IdFase <= 0)
			THROW 50000, '- Valor invalido: Fase', 1;

		IF (@IdSede IS NOT NULL AND @IdSede <= 0)
			THROW 50000, '- Valor invalido: Sede', 1;

		IF (@IdMundial IS NOT NULL AND @IdMundial <= 0)
			THROW 50000, '- Valor invalido: Mundial', 1;

		IF (@GolesEq1 IS NOT NULL AND @GolesEq1 < 0)
			THROW 50000, '- Los goles no pueden ser negativos', 1;

		IF (@GolesEq2 IS NOT NULL AND @GolesEq2 < 0)
			THROW 50000, '- Los goles no pueden ser negativos', 1;

		IF (@Asistencia IS NOT NULL AND @Asistencia < 0)
			THROW 50000, '- La asistencia no puede ser negativa', 1;

		IF NOT EXISTS(SELECT 1 FROM partidos.Partido WHERE IdPartido = @Id)
			THROW 50000, '- Valor inexistente: Partido', 1;

		IF (@IdFase IS NOT NULL AND NOT EXISTS(SELECT 1 FROM partidos.Fase WHERE IdFase = @IdFase))
			THROW 50000, '- Valor inexistente: Fase', 1;

		IF (@IdMundial IS NOT NULL AND NOT EXISTS(SELECT 1 FROM sedes.Mundial WHERE IdMundial = @IdMundial))
			THROW 50000, '- Valor inexistente: Mundial', 1;

		SELECT @vMundial = COALESCE(@IdMundial, IdMundial), @vEq1 = COALESCE(@Eq1, Eq1), @vEq2 = COALESCE(@Eq2, Eq2) FROM partidos.Partido WHERE IdPartido = @Id

		IF (@vEq1 = @vEq2)
			THROW 50000, '- Un equipo no puede ser su propio rival', 1;
		ELSE IF NOT EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @vEq1 AND IdMundial = @vMundial)
			THROW 50000, '- Eq1 no pertenece al Mundial', 1;
		ELSE IF NOT EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @vEq2 AND IdMundial = @vMundial)
			THROW 50000, '- Eq2 no pertenece al Mundial', 1;

		IF @GolesEq1 IS NOT NULL OR @GolesEq2 IS NOT NULL
			THROW 51000, 'El marcador se modifica mediante alta y baja de goles, no manualmente.', 1;

		UPDATE partidos.Partido
		SET IdFase = COALESCE(@IdFase, IdFase),
			IdSede = COALESCE(@IdSede, IdSede),
			IdMundial = COALESCE(@IdMundial, IdMundial),
			Eq1 = COALESCE(@Eq1, Eq1),
			Eq2 = COALESCE(@Eq2, Eq2),
			Fecha = COALESCE(@Fecha, Fecha),
			HoraUTC = COALESCE(@HoraUTC, HoraUTC),
			HoraLocal = COALESCE(@HoraLocal, HoraLocal),
			GolesEq1 = COALESCE(@GolesEq1, GolesEq1),
			GolesEq2 = COALESCE(@GolesEq2, GolesEq2),
			Asistencia = COALESCE(@Asistencia, Asistencia)
		WHERE IdPartido = @Id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspPartido_Bajar'))
	DROP PROCEDURE SP.uspPartido_Bajar
GO

---------------------------------------------------------------------------------------------------------

CREATE PROCEDURE SP.uspPartido_Bajar
@Id INT
AS
BEGIN
	BEGIN TRY
		IF (@Id IS NULL OR @Id <= 0)
			THROW 50000, '- Valor invalido: Id', 1;

		IF NOT EXISTS(SELECT 1 FROM partidos.Partido WHERE IdPartido = @Id)
			THROW 50000, '- Valor inexistente: Partido', 1;

		IF EXISTS(SELECT 1 FROM partidos.Alineacion WHERE IdPartido = @Id)
			THROW 50000, '- Existen alineaciones para este partido', 1;

		IF EXISTS(SELECT 1 FROM partidos.Evento WHERE Partido = @Id)
			THROW 50000, '- Existen eventos para este partido', 1;

		DELETE FROM partidos.Partido WHERE IdPartido = @Id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO