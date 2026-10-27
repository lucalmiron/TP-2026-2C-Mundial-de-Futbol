--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Creacion de Stored Procedures (ABM de HusoHorario)

-- Ejecutar en la base seleccionada por el instalador.
GO

--alta de huso horario
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspHusoHorario_Registrar'))
    DROP PROCEDURE SP.uspHusoHorario_Registrar
GO
CREATE PROCEDURE SP.uspHusoHorario_Registrar
@nombre VARCHAR(50)
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		--Chequeo validez
		IF(@nombre IS NULL) OR (LTRIM(RTRIM(@nombre)) = '')
			SET @errores += '- Valor invalido: Nombre.' + N' ';

		--Chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @idPais)
			SET @errores += '- Valor inexistente: Pais.' + N' ';

		--Chequeo dup
		IF EXISTS(SELECT 1 FROM sedes.HusoHorario WHERE Nombre = @nombre)
			SET @errores += '- Valor duplicado: Nombre.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		INSERT INTO sedes.HusoHorario(Nombre)
		VALUES( LTRIM(RTRIM(@nombre)) )
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

--modificacion de huso horario
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspHusoHorario_Update'))
    DROP PROCEDURE SP.uspHusoHorario_Update
GO
CREATE PROCEDURE SP.uspHusoHorario_Update
@idHuso INT,
@nombre VARCHAR(50) = NULL
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		--Chequeo validez (solo lo que vino con valor)
		IF(@idHuso IS NULL) OR (@idHuso <= 0)
			SET @errores += '- Valor invalido: ID HusoHorario.' + N' ';

		IF(@nombre IS NOT NULL) AND (LTRIM(RTRIM(@nombre)) = '')
			SET @errores += '- Valor invalido: Nombre.' + N' ';

		--Chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM sedes.HusoHorario WHERE IdHuso = @idHuso)
			SET @errores += '- Valor inexistente: ID HusoHorario.' + N' ';

		--Chequeo dup (excluyendo el propio registro)
		IF(@nombre IS NOT NULL)
		   AND EXISTS(SELECT 1 FROM sedes.HusoHorario WHERE Nombre = @nombre AND IdHuso <> @idHuso)
			SET @errores += '- Valor duplicado: Nombre.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		UPDATE sedes.HusoHorario
		SET Nombre = COALESCE(LTRIM(RTRIM(@nombre)), Nombre)
		WHERE IdHuso = @idHuso
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

--baja de huso horario
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspHusoHorario_Bajar'))
    DROP PROCEDURE SP.uspHusoHorario_Bajar
GO
CREATE PROCEDURE SP.uspHusoHorario_Bajar
@idHuso INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		--Chequeo validez
		IF(@idHuso IS NULL) OR (@idHuso <= 0)
			SET @errores += '- Valor invalido: ID HusoHorario.' + N' ';

		--Chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM sedes.HusoHorario WHERE IdHuso = @idHuso)
			SET @errores += '- Valor inexistente: ID HusoHorario.' + N' ';

		--Chequeo relaciones
		IF EXISTS(SELECT 1 FROM sedes.Sede WHERE IdHuso = @idHuso)
			SET @errores += '- Existen 1 o mas registros relacionados: Sede. Elimine dichos registros para continuar.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		DELETE FROM sedes.HusoHorario
		WHERE IdHuso = @idHuso
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO
