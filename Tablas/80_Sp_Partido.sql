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
	DECLARE @errorCount INT = 0
	DECLARE @errorLine VARCHAR(300) = 'Error/es:'

	IF (@IdFase IS NULL OR @IdFase <= 0)
	BEGIN
		SET @errorCount=@errorCount+1
		SET @errorLine=@errorLine+CHAR(13)+'- Valor invalido: Fase'
	END

	IF (@IdSede IS NULL OR @IdSede <= 0)
	BEGIN
		SET @errorCount=@errorCount+1
		SET @errorLine=@errorLine+CHAR(13)+'- Valor invalido: Sede'
	END

	IF (@IdMundial IS NULL OR @IdMundial <= 0)
	BEGIN
		SET @errorCount=@errorCount+1
		SET @errorLine=@errorLine+CHAR(13)+'- Valor invalido: Mundial'
	END

	IF (@Fecha IS NULL)
	BEGIN
		SET @errorCount=@errorCount+1
		SET @errorLine=@errorLine+CHAR(13)+'- Valor invalido: Fecha'
	END

	IF (@HoraUTC IS NULL OR @HoraLocal IS NULL)
	BEGIN
		SET @errorCount=@errorCount+1
		SET @errorLine=@errorLine+CHAR(13)+'- Valor invalido: Hora'
	END

	IF (@Eq1 IS NULL OR @Eq2 IS NULL)
	BEGIN
		SET @errorCount=@errorCount+1
		SET @errorLine=@errorLine+CHAR(13)+'- Deben registrarse ambos equipos'
	END

	IF (@Eq1 IS NOT NULL AND @Eq2 IS NOT NULL AND @Eq1 = @Eq2)
	BEGIN
		SET @errorCount=@errorCount+1
		SET @errorLine=@errorLine+CHAR(13)+'- Un equipo no puede ser su propio rival'
	END

	IF(@Asistencia IS NOT NULL AND @Asistencia<0)
	BEGIN
		SET @errorCount=@errorCount+1
		SET @errorLine=@errorLine+CHAR(13)+'- La asistencia no puede ser negativa'
	END

	IF (@errorCount = 0 AND NOT EXISTS(SELECT 1 FROM partidos.Fase WHERE IdFase = @IdFase))
	BEGIN
		SET @errorCount=@errorCount+1
		SET @errorLine=@errorLine+CHAR(13)+'- Valor inexistente: Fase'
	END

	IF (@errorCount = 0 AND NOT EXISTS(SELECT 1 FROM sedes.Mundial WHERE IdMundial = @IdMundial))
	BEGIN
		SET @errorCount=@errorCount+1
		SET @errorLine=@errorLine+CHAR(13)+'- Valor inexistente: Mundial'
	END

	IF (@errorCount = 0 AND NOT EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @Eq1))
	BEGIN
		SET @errorCount=@errorCount+1
		SET @errorLine=@errorLine+CHAR(13)+'- Valor inexistente: Eq1'
	END

	IF (@errorCount = 0 AND NOT EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @Eq2))
	BEGIN
		SET @errorCount=@errorCount+1
		SET @errorLine=@errorLine+CHAR(13)+'- Valor inexistente: Eq2'
	END

	IF (@errorCount = 0 AND NOT EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @Eq1 AND IdMundial = @IdMundial))
	BEGIN
		SET @errorCount=@errorCount+1
		SET @errorLine=@errorLine+CHAR(13)+'- Eq1 no pertenece al Mundial'
	END

	IF (@errorCount = 0 AND NOT EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @Eq2 AND IdMundial = @IdMundial))
	BEGIN
		SET @errorCount=@errorCount+1
		SET @errorLine=@errorLine+CHAR(13)+'- Eq2 no pertenece al Mundial'
	END

	IF (@errorCount = 0 AND EXISTS(SELECT 1 FROM partidos.Partido WHERE Eq1 = @Eq1 AND Eq2 = @Eq2 AND Fecha = @Fecha AND IdFase = @IdFase))
	BEGIN
		SET @errorCount=@errorCount+1
		SET @errorLine=@errorLine+CHAR(13)+'- Partido duplicado'
	END

	IF (@errorCount = 0)
		INSERT INTO partidos.Partido(IdFase, IdSede, IdMundial, Eq1, Eq2, Fecha, HoraUTC, HoraLocal, GolesEq1, GolesEq2, Asistencia)
		VALUES(@IdFase, @IdSede, @IdMundial, @Eq1, @Eq2, @Fecha, @HoraUTC, @HoraLocal, 0, 0, @Asistencia)
	ELSE
		PRINT @errorLine
END
GO

----------------------------------------------------------------------------------------------------------------

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspPartido_Update'))
	DROP PROCEDURE SP.uspPartido_Update
GO

-- Nota: el marcador oficial (GolesEq1/GolesEq2) lo mueve Gol via
-- SPTRANS.uspGol_Registrar y SPTRANS.uspGol_Bajar. Estos parametros solo permiten correcciones manuales
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
	DECLARE @errorCount INT = 0
	DECLARE @errorLine VARCHAR(300) = 'Error/es:'
	DECLARE @vMundial INT
	DECLARE @vEq1 INT
	DECLARE @vEq2 INT

	IF (@Id IS NULL OR @Id <= 0)
	BEGIN
		SET @errorCount=@errorCount+1
		SET @errorLine=@errorLine+CHAR(13)+'- Valor invalido: Id'
	END

	IF (@IdFase IS NOT NULL AND @IdFase <= 0)
	BEGIN
		SET @errorCount=@errorCount+1
		SET @errorLine=@errorLine+CHAR(13)+'- Valor invalido: Fase'
	END

	IF (@IdSede IS NOT NULL AND @IdSede <= 0)
	BEGIN
		SET @errorCount=@errorCount+1
		SET @errorLine=@errorLine+CHAR(13)+'- Valor invalido: Sede'
	END

	IF (@IdMundial IS NOT NULL AND @IdMundial <= 0)
	BEGIN
		SET @errorCount=@errorCount+1
		SET @errorLine=@errorLine+CHAR(13)+'- Valor invalido: Mundial'
	END

	IF (@GolesEq1 IS NOT NULL AND @GolesEq1 < 0)
	BEGIN
		SET @errorCount=@errorCount+1
		SET @errorLine=@errorLine+CHAR(13)+'- Los goles no pueden ser negativos'
	END

	IF (@GolesEq2 IS NOT NULL AND @GolesEq2 < 0)
	BEGIN
		SET @errorCount=@errorCount+1
		SET @errorLine=@errorLine+CHAR(13)+'- Los goles no pueden ser negativos'
	END

	IF (@Asistencia IS NOT NULL AND @Asistencia < 0)
	BEGIN
		SET @errorCount=@errorCount+1
		SET @errorLine=@errorLine+CHAR(13)+'- La asistencia no puede ser negativa'
	END

	IF (@errorCount = 0 AND NOT EXISTS(SELECT 1 FROM partidos.Partido WHERE IdPartido = @Id))
	BEGIN
		SET @errorCount=@errorCount+1
		SET @errorLine=@errorLine+CHAR(13)+'- Valor inexistente: Partido'
	END

	IF (@errorCount = 0 AND @IdFase IS NOT NULL AND NOT EXISTS(SELECT 1 FROM partidos.Fase WHERE IdFase = @IdFase))
	BEGIN
		SET @errorCount=@errorCount+1
		SET @errorLine=@errorLine+CHAR(13)+'- Valor inexistente: Fase'
	END

	IF (@errorCount = 0 AND @IdMundial IS NOT NULL AND NOT EXISTS(SELECT 1 FROM sedes.Mundial WHERE IdMundial = @IdMundial))
	BEGIN
		SET @errorCount=@errorCount+1
		SET @errorLine=@errorLine+CHAR(13)+'- Valor inexistente: Mundial'
	END

	IF (@errorCount = 0)
	BEGIN
		SELECT @vMundial = COALESCE(@IdMundial, IdMundial), @vEq1 = COALESCE(@Eq1, Eq1), @vEq2 = COALESCE(@Eq2, Eq2) FROM partidos.Partido WHERE IdPartido = @Id

		IF (@vEq1 = @vEq2)
		BEGIN
			SET @errorCount=@errorCount+1
			SET @errorLine=@errorLine+CHAR(13)+'- Un equipo no puede ser su propio rival'
		END
		ELSE IF NOT EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @vEq1 AND IdMundial = @vMundial)
		BEGIN
			SET @errorCount=@errorCount+1
			SET @errorLine=@errorLine+CHAR(13)+'- Eq1 no pertenece al Mundial'
		END
		ELSE IF NOT EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @vEq2 AND IdMundial = @vMundial)
		BEGIN
			SET @errorCount=@errorCount+1
			SET @errorLine=@errorLine+CHAR(13)+'- Eq2 no pertenece al Mundial'
		END
	END

	IF (@errorCount = 0)
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
	ELSE
		PRINT @errorLine
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
	DECLARE @errorCount INT = 0
	DECLARE @errorLine VARCHAR(300) = 'Error/es:'

	IF (@Id IS NULL OR @Id <= 0)
	BEGIN
		SET @errorCount=@errorCount+1
		SET @errorLine=@errorLine+CHAR(13)+'- Valor invalido: Id'
	END

	IF (@errorCount = 0 AND NOT EXISTS(SELECT 1 FROM partidos.Partido WHERE IdPartido = @Id))
	BEGIN
		SET @errorCount=@errorCount+1
		SET @errorLine=@errorLine+CHAR(13)+'- Valor inexistente: Partido'
	END

	IF (@errorCount = 0 AND EXISTS(SELECT 1 FROM partidos.Alineacion WHERE IdPartido = @Id))
	BEGIN
		SET @errorCount=@errorCount+1
		SET @errorLine=@errorLine+CHAR(13)+'- Existen alineaciones para este partido'
	END

	IF (@errorCount = 0 AND EXISTS(SELECT 1 FROM partidos.Evento WHERE Partido = @Id))
	BEGIN
		SET @errorCount=@errorCount+1
		SET @errorLine=@errorLine+CHAR(13)+'- Existen eventos para este partido'
	END

	IF (@errorCount = 0)
		DELETE FROM partidos.Partido WHERE IdPartido = @Id
	ELSE
		PRINT @errorLine
END
GO
