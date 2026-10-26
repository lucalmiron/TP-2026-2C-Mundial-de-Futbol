-- Universidad Nacional de La Matanza
-- Bases de datos aplicada
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 25/10/26
-- Objetivo: Gestionar Tabla Partido

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END
GO

-- Fecha del partido se interpreta en UTC. El sufijo del huso puede ser una etiqueta.
CREATE OR ALTER FUNCTION sedes.fnFechaHoraLocal(@fecha DATE, @hora TIME, @huso VARCHAR(50))
RETURNS DATETIMEOFFSET
AS
BEGIN
	DECLARE @utc DATETIME2 = DATEADD(DAY, DATEDIFF(DAY, '19000101', @fecha), CAST(@hora AS DATETIME2));
	DECLARE @nombre VARCHAR(50) = LTRIM(RTRIM(@huso));
	IF @utc IS NULL OR @nombre IS NULL RETURN NULL;
	IF EXISTS (SELECT 1 FROM sys.time_zone_info WHERE name = @nombre)
		RETURN (@utc AT TIME ZONE 'UTC') AT TIME ZONE @nombre;

	-- Desplazamientos fijos: UTC-3, UTC+05:30, UTC-3 (Prueba).
	SET @nombre = LEFT(@nombre, CHARINDEX(' ', @nombre + ' ') - 1);
	IF @nombre = 'UTC' RETURN TODATETIMEOFFSET(@utc, 0);
	IF LEFT(@nombre, 3) <> 'UTC' OR SUBSTRING(@nombre, 4, 1) NOT IN ('+', '-') RETURN NULL;
	DECLARE @valor VARCHAR(50) = SUBSTRING(@nombre, 5, 46);
	DECLARE @separador INT = CHARINDEX(':', @valor), @horas INT, @minutos INT = 0;
	IF @separador = 0
	BEGIN
		IF @valor = '' OR @valor LIKE '%[^0-9]%' RETURN NULL;
		SET @horas = TRY_CONVERT(INT, @valor);
	END
	ELSE
	BEGIN
		IF @separador = 1 OR LEN(@valor) - @separador <> 2 RETURN NULL;
		IF LEFT(@valor, @separador - 1) LIKE '%[^0-9]%' OR SUBSTRING(@valor, @separador + 1, 2) LIKE '%[^0-9]%' RETURN NULL;
		SET @horas = TRY_CONVERT(INT, LEFT(@valor, @separador - 1));
		SET @minutos = TRY_CONVERT(INT, SUBSTRING(@valor, @separador + 1, 2));
	END
	IF @horas IS NULL OR @horas > 14 OR @minutos > 59 OR (@horas = 14 AND @minutos <> 0) RETURN NULL;
	DECLARE @offset INT = (@horas * 60 + @minutos) * CASE WHEN SUBSTRING(@nombre, 4, 1) = '-' THEN -1 ELSE 1 END;
	RETURN SWITCHOFFSET(TODATETIMEOFFSET(@utc, 0), @offset);
END;
GO

CREATE OR ALTER VIEW partidos.vHorarioPartido
AS
	SELECT P.IdPartido, P.Fecha AS FechaUTC, P.HoraUTC,
		CAST(sedes.fnFechaHoraLocal(P.Fecha, P.HoraUTC, H.Nombre) AS DATE) AS FechaLocal,
		CAST(sedes.fnFechaHoraLocal(P.Fecha, P.HoraUTC, H.Nombre) AS TIME) AS HoraLocal
	FROM partidos.Partido P
	JOIN sedes.Sede S ON S.IdSede = P.IdSede
	JOIN sedes.HusoHorario H ON H.IdHuso = S.IdHuso;
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
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF (@IdFase IS NULL OR @IdFase <= 0)
			SET @errores += '- Valor invalido: Fase' + N' ';

		IF (@IdSede IS NULL OR @IdSede <= 0)
			SET @errores += '- Valor invalido: Sede' + N' ';

		IF (@IdMundial IS NULL OR @IdMundial <= 0)
			SET @errores += '- Valor invalido: Mundial' + N' ';

		IF (@Fecha IS NULL)
			SET @errores += '- Valor invalido: Fecha' + N' ';

		IF (@HoraUTC IS NULL OR @HoraLocal IS NULL)
			SET @errores += '- Valor invalido: Hora' + N' ';

		IF (@Eq1 IS NULL OR @Eq2 IS NULL)
			SET @errores += '- Deben registrarse ambos equipos' + N' ';

		IF (@Eq1 IS NOT NULL AND @Eq2 IS NOT NULL AND @Eq1 = @Eq2)
			SET @errores += '- Un equipo no puede ser su propio rival' + N' ';

		IF(@Asistencia IS NOT NULL AND @Asistencia<0)
			SET @errores += '- La asistencia no puede ser negativa' + N' ';

		IF NOT EXISTS(SELECT 1 FROM partidos.Fase WHERE IdFase = @IdFase)
			SET @errores += '- Valor inexistente: Fase' + N' ';

		IF NOT EXISTS(SELECT 1 FROM sedes.Sede WHERE IdSede = @IdSede)
			SET @errores += '- Valor inexistente: Sede' + N' ';

		IF @Asistencia > (SELECT Capacidad FROM sedes.Sede WHERE IdSede = @IdSede)
			SET @errores += '- La asistencia supera la capacidad de la sede' + N' ';

		IF NOT EXISTS(SELECT 1 FROM sedes.Mundial WHERE IdMundial = @IdMundial)
			SET @errores += '- Valor inexistente: Mundial' + N' ';

		IF NOT EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @Eq1)
			SET @errores += '- Valor inexistente: Eq1' + N' ';

		IF NOT EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @Eq2)
			SET @errores += '- Valor inexistente: Eq2' + N' ';

		IF NOT EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @Eq1 AND IdMundial = @IdMundial)
			SET @errores += '- Eq1 no pertenece al Mundial' + N' ';

		IF NOT EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @Eq2 AND IdMundial = @IdMundial)
			SET @errores += '- Eq2 no pertenece al Mundial' + N' ';

		IF EXISTS(SELECT 1 FROM partidos.Partido WHERE Eq1 = @Eq1 AND Eq2 = @Eq2 AND Fecha = @Fecha AND IdFase = @IdFase)
			SET @errores += '- Partido duplicado' + N' ';

		DECLARE @local DATETIMEOFFSET;
		SELECT @local = sedes.fnFechaHoraLocal(@Fecha, @HoraUTC, H.Nombre)
		FROM sedes.Sede S JOIN sedes.HusoHorario H ON H.IdHuso = S.IdHuso WHERE S.IdSede = @IdSede;
		IF @local IS NULL
			SET @errores += '- Huso horario no reconocido. Use UTC, UTC con desplazamiento o un nombre de sys.time_zone_info.' + N' ';
		IF @HoraLocal <> CAST(@local AS TIME)
			SET @errores += '- La hora local no coincide con la hora UTC y el huso de la sede.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

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
	DECLARE @errores NVARCHAR(2048) = N'';
	DECLARE @vMundial INT
	DECLARE @vEq1 INT
	DECLARE @vEq2 INT

	BEGIN TRY
		IF (@Id IS NULL OR @Id <= 0)
			SET @errores += '- Valor invalido: Id' + N' ';

		IF (@IdFase IS NOT NULL AND @IdFase <= 0)
			SET @errores += '- Valor invalido: Fase' + N' ';

		IF (@IdSede IS NOT NULL AND @IdSede <= 0)
			SET @errores += '- Valor invalido: Sede' + N' ';

		IF (@IdMundial IS NOT NULL AND @IdMundial <= 0)
			SET @errores += '- Valor invalido: Mundial' + N' ';

		IF (@GolesEq1 IS NOT NULL AND @GolesEq1 < 0)
			SET @errores += '- Los goles no pueden ser negativos' + N' ';

		IF (@GolesEq2 IS NOT NULL AND @GolesEq2 < 0)
			SET @errores += '- Los goles no pueden ser negativos' + N' ';

		IF (@Asistencia IS NOT NULL AND @Asistencia < 0)
			SET @errores += '- La asistencia no puede ser negativa' + N' ';

		IF NOT EXISTS(SELECT 1 FROM partidos.Partido WHERE IdPartido = @Id)
			SET @errores += '- Valor inexistente: Partido' + N' ';

		IF (@IdFase IS NOT NULL AND NOT EXISTS(SELECT 1 FROM partidos.Fase WHERE IdFase = @IdFase))
			SET @errores += '- Valor inexistente: Fase' + N' ';

		IF (@IdMundial IS NOT NULL AND NOT EXISTS(SELECT 1 FROM sedes.Mundial WHERE IdMundial = @IdMundial))
			SET @errores += '- Valor inexistente: Mundial' + N' ';

		SELECT @vMundial = COALESCE(@IdMundial, IdMundial), @vEq1 = COALESCE(@Eq1, Eq1), @vEq2 = COALESCE(@Eq2, Eq2) FROM partidos.Partido WHERE IdPartido = @Id

		IF (@vEq1 = @vEq2)
			SET @errores += '- Un equipo no puede ser su propio rival' + N' ';
		ELSE IF NOT EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @vEq1 AND IdMundial = @vMundial)
			SET @errores += '- Eq1 no pertenece al Mundial' + N' ';
		ELSE IF NOT EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @vEq2 AND IdMundial = @vMundial)
			SET @errores += '- Eq2 no pertenece al Mundial' + N' ';

		DECLARE @vSede INT, @vAsistencia INT;
		SELECT @vSede = COALESCE(@IdSede, IdSede), @vAsistencia = COALESCE(@Asistencia, Asistencia)
		FROM partidos.Partido WHERE IdPartido = @Id;

		IF NOT EXISTS(SELECT 1 FROM sedes.Sede WHERE IdSede = @vSede)
			SET @errores += '- Valor inexistente: Sede' + N' ';

		IF @vAsistencia > (SELECT Capacidad FROM sedes.Sede WHERE IdSede = @vSede)
			SET @errores += '- La asistencia supera la capacidad de la sede' + N' ';

		IF EXISTS (SELECT 1 FROM partidos.Partido WHERE IdPartido = @Id
			AND (Eq1 <> @vEq1 OR Eq2 <> @vEq2 OR IdMundial <> @vMundial))
		BEGIN
			IF EXISTS (SELECT 1 FROM partidos.Alineacion WHERE IdPartido = @Id)
			OR EXISTS (SELECT 1 FROM partidos.Evento WHERE Partido = @Id)
			OR EXISTS (SELECT 1 FROM arbitros.Arbitraje WHERE Partido = @Id)
				SET @errores += '- No se pueden cambiar equipos o mundial con alineaciones, eventos o arbitrajes registrados' + N' ';
		END

		IF @GolesEq1 IS NOT NULL OR @GolesEq2 IS NOT NULL
			SET @errores += 'El marcador se modifica mediante alta y baja de goles, no manualmente.' + N' ';

		IF @Fecha IS NOT NULL OR @HoraUTC IS NOT NULL OR @HoraLocal IS NOT NULL OR @IdSede IS NOT NULL
		BEGIN
			DECLARE @local DATETIMEOFFSET;
			SELECT @local = sedes.fnFechaHoraLocal(COALESCE(@Fecha, P.Fecha), COALESCE(@HoraUTC, P.HoraUTC), H.Nombre)
			FROM partidos.Partido P JOIN sedes.Sede S ON S.IdSede = @vSede
			JOIN sedes.HusoHorario H ON H.IdHuso = S.IdHuso WHERE P.IdPartido = @Id;
			IF @local IS NULL
				SET @errores += '- Huso horario no reconocido. Use UTC, UTC con desplazamiento o un nombre de sys.time_zone_info.' + N' ';
			IF @HoraLocal IS NOT NULL AND @HoraLocal <> CAST(@local AS TIME)
				SET @errores += '- La hora local no coincide con la hora UTC y el huso de la sede.' + N' ';
			SET @HoraLocal = CAST(@local AS TIME);
		END

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

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
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF (@Id IS NULL OR @Id <= 0)
			SET @errores += '- Valor invalido: Id' + N' ';

		IF NOT EXISTS(SELECT 1 FROM partidos.Partido WHERE IdPartido = @Id)
			SET @errores += '- Valor inexistente: Partido' + N' ';

		IF EXISTS(SELECT 1 FROM partidos.Alineacion WHERE IdPartido = @Id)
			SET @errores += '- Existen alineaciones para este partido' + N' ';

		IF EXISTS(SELECT 1 FROM partidos.Evento WHERE Partido = @Id)
			SET @errores += '- Existen eventos para este partido' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		DELETE FROM partidos.Partido WHERE IdPartido = @Id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO