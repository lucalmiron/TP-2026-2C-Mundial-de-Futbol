--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 08/10/2026

--Objetivo: SP de ABM de la tabla partidos.Periodo (Alta, Baja, Modificacion).
--Las validaciones se acumulan en una variable y se lanzan con un unico THROW.

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

-- =============================================
-- partidos.Periodo_Alta
-- Inserta un periodo. Todos los parametros son obligatorios.
-- =============================================
CREATE OR ALTER PROCEDURE partidos.Periodo_Alta
	@idPeriodo INT,
	@descripcion VARCHAR(50),
	@inicio INT,
	@fin INT
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE @errores NVARCHAR(MAX) = N'';

	IF @idPeriodo IS NULL
		SET @errores += N'IdPeriodo es obligatorio. ';
	IF @idPeriodo IS NOT NULL AND @idPeriodo <= 0
		SET @errores += N'IdPeriodo debe ser mayor a 0. ';
	IF @idPeriodo IS NOT NULL AND EXISTS (SELECT 1 FROM partidos.Periodo WHERE IdPeriodo = @idPeriodo)
		SET @errores += N'Ya existe un periodo con IdPeriodo ' + CAST(@idPeriodo AS NVARCHAR(10)) + N'. ';

	IF @descripcion IS NULL OR LTRIM(RTRIM(@descripcion)) = N''
		SET @errores += N'La descripcion es obligatoria. ';
	IF @descripcion IS NOT NULL AND LEN(@descripcion) > 12
		SET @errores += N'La descripcion no puede superar los 12 caracteres. ';
	IF @descripcion IS NOT NULL AND EXISTS (SELECT 1 FROM partidos.Periodo WHERE Descripcion = @descripcion)
		SET @errores += N'Ya existe un periodo con la descripcion indicada. ';

	IF @inicio IS NULL
		SET @errores += N'El inicio es obligatorio. ';
	IF @inicio IS NOT NULL AND @inicio < 0
		SET @errores += N'El inicio no puede ser negativo. ';

	IF @fin IS NULL
		SET @errores += N'El fin es obligatorio. ';
	IF @fin IS NOT NULL AND @inicio IS NOT NULL AND @fin < @inicio
		SET @errores += N'El fin no puede ser menor al inicio. ';

	IF LEN(@errores) > 0
		THROW 50000, @errores, 1;

	BEGIN TRY
		BEGIN TRANSACTION;

		INSERT INTO partidos.Periodo (IdPeriodo, Descripcion, Inicio, Fin)
		VALUES (@idPeriodo, @descripcion, @inicio, @fin);

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END;
GO

-- =============================================
-- partidos.Periodo_Modificacion
-- Modifica un periodo existente. Todos los parametros son obligatorios.
-- =============================================
CREATE OR ALTER PROCEDURE partidos.Periodo_Modificacion
	@idPeriodo INT,
	@descripcion VARCHAR(50),
	@inicio INT,
	@fin INT
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE @errores NVARCHAR(MAX) = N'';

	IF @idPeriodo IS NULL
		SET @errores += N'IdPeriodo es obligatorio. ';
	IF @idPeriodo IS NOT NULL AND NOT EXISTS (SELECT 1 FROM partidos.Periodo WHERE IdPeriodo = @idPeriodo)
		SET @errores += N'No existe un periodo con IdPeriodo ' + CAST(@idPeriodo AS NVARCHAR(10)) + N'. ';

	IF @descripcion IS NULL OR LTRIM(RTRIM(@descripcion)) = N''
		SET @errores += N'La descripcion es obligatoria. ';
	IF @descripcion IS NOT NULL AND LEN(@descripcion) > 12
		SET @errores += N'La descripcion no puede superar los 12 caracteres. ';
	IF @descripcion IS NOT NULL AND EXISTS (SELECT 1 FROM partidos.Periodo WHERE Descripcion = @descripcion AND IdPeriodo <> @idPeriodo)
		SET @errores += N'Otro periodo ya tiene esa descripcion. ';

	IF @inicio IS NULL
		SET @errores += N'El inicio es obligatorio. ';
	IF @inicio IS NOT NULL AND @inicio < 0
		SET @errores += N'El inicio no puede ser negativo. ';

	IF @fin IS NULL
		SET @errores += N'El fin es obligatorio. ';
	IF @fin IS NOT NULL AND @inicio IS NOT NULL AND @fin < @inicio
		SET @errores += N'El fin no puede ser menor al inicio. ';

	IF LEN(@errores) > 0
		THROW 50000, @errores, 1;

	BEGIN TRY
		BEGIN TRANSACTION;

		UPDATE partidos.Periodo
		SET Descripcion = @descripcion,
			Inicio = @inicio,
			Fin = @fin
		WHERE IdPeriodo = @idPeriodo;

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END;
GO

-- =============================================
-- partidos.Periodo_Baja
-- Elimina un periodo. No se permite si tiene eventos asociados.
-- =============================================
CREATE OR ALTER PROCEDURE partidos.Periodo_Baja
	@idPeriodo INT
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE @errores NVARCHAR(MAX) = N'';

	IF @idPeriodo IS NULL
		SET @errores += N'IdPeriodo es obligatorio. ';
	IF @idPeriodo IS NOT NULL AND NOT EXISTS (SELECT 1 FROM partidos.Periodo WHERE IdPeriodo = @idPeriodo)
		SET @errores += N'No existe un periodo con IdPeriodo ' + CAST(@idPeriodo AS NVARCHAR(10)) + N'. ';
	IF @idPeriodo IS NOT NULL AND EXISTS (SELECT 1 FROM partidos.Evento WHERE Periodo = @idPeriodo)
		SET @errores += N'No se puede eliminar el periodo: tiene eventos asociados. ';

	IF LEN(@errores) > 0
		THROW 50000, @errores, 1;

	BEGIN TRY
		BEGIN TRANSACTION;

		DELETE FROM partidos.Periodo
		WHERE IdPeriodo = @idPeriodo;

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END;
GO
