--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 08/10/2026

--Creacion de Stored Procedures (ABM de HusoHorario)

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

--alta de huso horario
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspHusoHorario_Registrar'))
    DROP PROCEDURE SP.uspHusoHorario_Registrar
GO
CREATE PROCEDURE SP.uspHusoHorario_Registrar
@nombre VARCHAR(50),
@idPais INT
AS
BEGIN
	BEGIN TRY
		--Chequeo validez
		IF(@nombre IS NULL) OR (LTRIM(RTRIM(@nombre)) = '')
			THROW 50000, '- Valor invalido: Nombre.', 1;

		IF(@idPais IS NULL) OR (@idPais <= 0)
			THROW 50000, '- Valor invalido: Pais.', 1;

		--Chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @idPais)
			THROW 50000, '- Valor inexistente: Pais.', 1;

		--Chequeo dup
		IF EXISTS(SELECT 1 FROM sedes.HusoHorario WHERE Nombre = @nombre)
			THROW 50000, '- Valor duplicado: Nombre.', 1;

		INSERT INTO sedes.HusoHorario(Nombre, IdPais)
		VALUES(LTRIM(RTRIM(@nombre)), @idPais)
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
@nombre VARCHAR(50) = NULL,
@idPais INT = NULL
AS
BEGIN
	BEGIN TRY
		--Chequeo validez (solo lo que vino con valor)
		IF(@idHuso IS NULL) OR (@idHuso <= 0)
			THROW 50000, '- Valor invalido: ID HusoHorario.', 1;

		IF(@nombre IS NOT NULL) AND (LTRIM(RTRIM(@nombre)) = '')
			THROW 50000, '- Valor invalido: Nombre.', 1;

		IF(@idPais IS NOT NULL) AND (@idPais <= 0)
			THROW 50000, '- Valor invalido: Pais.', 1;

		--Chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM sedes.HusoHorario WHERE IdHuso = @idHuso)
			THROW 50000, '- Valor inexistente: ID HusoHorario.', 1;

		IF(@idPais IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @idPais)
			THROW 50000, '- Valor inexistente: Pais.', 1;

		--Chequeo dup (excluyendo el propio registro)
		IF(@nombre IS NOT NULL)
		   AND EXISTS(SELECT 1 FROM sedes.HusoHorario WHERE Nombre = @nombre AND IdHuso <> @idHuso)
			THROW 50000, '- Valor duplicado: Nombre.', 1;

		UPDATE sedes.HusoHorario
		SET Nombre = COALESCE(LTRIM(RTRIM(@nombre)), Nombre),
			IdPais = COALESCE(@idPais, IdPais)
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
	BEGIN TRY
		--Chequeo validez
		IF(@idHuso IS NULL) OR (@idHuso <= 0)
			THROW 50000, '- Valor invalido: ID HusoHorario.', 1;

		--Chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM sedes.HusoHorario WHERE IdHuso = @idHuso)
			THROW 50000, '- Valor inexistente: ID HusoHorario.', 1;

		--Chequeo relaciones
		IF EXISTS(SELECT 1 FROM sedes.Sede WHERE IdHuso = @idHuso)
			THROW 50000, '- Existen 1 o mas registros relacionados: Sede. Elimine dichos registros para continuar.', 1;

		DELETE FROM sedes.HusoHorario
		WHERE IdHuso = @idHuso
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO