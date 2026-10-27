--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Creacion de Stored Procedures (ABM de Pais)

-- Ejecutar en la base seleccionada por el instalador.
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspPais_Registrar'))
    DROP PROCEDURE SP.uspPais_Registrar
GO
CREATE PROCEDURE SP.uspPais_Registrar
@nombre VARCHAR(50),
@idioma INT,
@huso INT,
@ptIni TIME,
@ptFin TIME,
@pbi BIGINT = NULL
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';

	BEGIN TRY
		--Chequeo validez
		IF(@nombre IS NULL) OR (LTRIM(RTRIM(@nombre)) = '')
			SET @errores += '- Valor invalido: Nombre.' + N' ';

		IF(@idioma IS NULL) OR (@idioma <= 0)
			SET @errores += '- Valor invalido: Idioma.' + N' ';

		IF(@huso IS NULL) OR (@huso <= 0)
			SET @errores += '- Valor invalido: Huso Horario.' + N' ';

		IF( (@ptIni IS NULL) OR (@ptFin IS NULL) OR (@ptFin <= @ptIni) )
			SET @errores += '- Valores invalidos: Inicio y Fin de Primetime.' + N' ';

		IF(@pbi IS NOT NULL) AND (@pbi < 0)
			SET @errores += '- Valor invalido: PBI.' + N' ';
			
		--Chequeo existencia
		IF(LEN(@errores) = 0)
		BEGIN
			IF NOT EXISTS(SELECT 1 FROM arbitros.Idioma WHERE IdIdioma = @idioma)
				SET @errores += '- Valor inexistente: Idioma.' + N' ';

			IF NOT EXISTS(SELECT 1 FROM sedes.HusoHorario WHERE IdHuso = @huso)
				SET @errores += '- Valor inexistente: Huso Horario.' + N' ';
		END

		--Chequeo dup
		IF (LEN(@errores) = 0) AND EXISTS(SELECT 1 FROM equipos.Pais WHERE NOMBRE = LTRIM(RTRIM(@nombre)))
			SET @errores += '- Valor duplicado: Pais (nombre).' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		INSERT INTO equipos.Pais(NOMBRE, PBI, Idioma, HusoHorario, PtIni, PtFin)
		VALUES(LTRIM(RTRIM(@nombre)), @pbi, @idioma, @huso, @ptIni, @ptFin)
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
@idioma INT = NULL,
@huso INT = NULL,
@ptIni TIME = NULL,
@ptFin TIME = NULL,
@pbi BIGINT = NULL
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		--Chequeo validez
		IF(@idPais IS NULL) OR (@idPais <= 0)
			SET @errores += '- Valor invalido: ID Pais.' + N' ';

		IF(@nombre IS NOT NULL) AND (LTRIM(RTRIM(@nombre)) = '')
			SET @errores += '- Valor invalido: Nombre.' + N' ';

		IF(@idioma IS NOT NULL) AND (@idioma <= 0)
			SET @errores += '- Valor invalido: Idioma.' + N' ';

		IF(@huso IS NOT NULL) AND (@huso <= 0)
			SET @errores += '- Valor invalido: Huso Horario.' + N' ';

		IF(@pbi IS NOT NULL) AND (@pbi < 0)
			SET @errores += '- Valor invalido: PBI.' + N' ';

		--Chequeo existencia
		IF (LEN(@errores) = 0)
		BEGIN
			IF NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @idPais)
				SET @errores += '- Valor inexistente: ID Pais.' + N' ';
		
			IF (@idioma IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM arbitros.Idioma WHERE IdIdioma = @idioma)
				SET @errores += '- Valor inexistente: Idioma.' + N' ';

			IF (@huso IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM sedes.HusoHorario WHERE IdHuso = @huso)
				SET @errores += '- Valor inexistente: Huso Horario.' + N' ';
		END

		--Chequeo dup
		IF (LEN(@errores) = 0) AND (@nombre IS NOT NULL)
		   AND EXISTS(SELECT 1 FROM equipos.Pais WHERE NOMBRE = LTRIM(RTRIM(@nombre)) AND IdPais <> @idPais)
			SET @errores += '- Valor duplicado: Pais (nombre).' + N' ';

		--Chequeo franja primetime
		IF(LEN(@errores) = 0)
		AND
		(
			((@ptIni IS NULL) AND (@ptFin IS NOT NULL) AND (@ptFin <= (SELECT PtIni FROM equipos.Pais WHERE IdPais = @idPais)))
			OR
			((@ptIni IS NOT NULL) AND (@ptFin IS NULL) AND (@ptIni >= (SELECT PtFin FROM equipos.Pais WHERE IdPais = @idPais)))
			OR
			((@ptIni IS NOT NULL) AND (@ptFin IS NOT NULL) AND (@ptFin <= @ptIni))
		)
			SET @errores += '- Valores invalidos: Inicio y Fin de Primetime.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		UPDATE equipos.Pais
		SET NOMBRE = COALESCE(LTRIM(RTRIM(@nombre)), NOMBRE),
			Idioma = COALESCE(@idioma, Idioma),
			HusoHorario = COALESCE(@huso, HusoHorario),
			PtIni = COALESCE(@ptIni, PtIni),
			PtFin = COALESCE(@ptFin, PtFin),
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
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		--Chequeo validez
		IF(@idPais IS NULL) OR (@idPais <= 0)
			SET @errores += '- Valor invalido: ID Pais.' + N' ';

		--Chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @idPais)
			SET @errores += '- Valor inexistente: ID Pais.' + N' ';

		--Chequeo relaciones
		IF EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdPais = @idPais)
			SET @errores += '- Existen 1 o mas registros relacionados: Seleccion. Elimine dichos registros para continuar.' + N' ';

		IF EXISTS(SELECT 1 FROM sedes.Mundial WHERE IdPais = @idPais)
			SET @errores += '- Existen 1 o mas registros relacionados: Mundial. Elimine dichos registros para continuar.' + N' ';

		IF EXISTS(SELECT 1 FROM sedes.HusoHorario WHERE IdPais = @idPais)
			SET @errores += '- Existen 1 o mas registros relacionados: HusoHorario. Elimine dichos registros para continuar.' + N' ';

		IF EXISTS(SELECT 1 FROM sedes.Sede WHERE IdPais = @idPais)
			SET @errores += '- Existen 1 o mas registros relacionados: Sede. Elimine dichos registros para continuar.' + N' ';

		IF EXISTS(SELECT 1 FROM equipos.Persona WHERE Pais = @idPais)
			SET @errores += '- Existen 1 o mas registros relacionados: Persona. Elimine dichos registros para continuar.' + N' ';

		IF EXISTS(SELECT 1 FROM publicidad.Anunciante WHERE IdPais = @idPais)
			SET @errores += '- Existen 1 o mas registros relacionados: Anunciante. Elimine dichos registros para continuar.' + N' ';

		IF EXISTS(SELECT 1 FROM publicidad.PublicidadPais WHERE IdPais = @idPais)
			SET @errores += '- Existen 1 o mas registros relacionados: PublicidadPais. Elimine dichos registros para continuar.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		DELETE FROM equipos.Pais WHERE IdPais = @idPais
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO
