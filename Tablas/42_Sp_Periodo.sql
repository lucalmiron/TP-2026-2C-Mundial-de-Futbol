--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Objetivo: SP de ABM de la tabla partidos.Periodo (Alta, Baja, Modificacion).
--Las validaciones se acumulan en una variable y se lanzan con un unico THROW.

-- Ejecutar en la base seleccionada por el instalador.
GO

-- =============================================
-- partidos.Periodo_Alta
-- Inserta un periodo. Todos los parametros son obligatorios.
-- =============================================
CREATE OR ALTER PROCEDURE partidos.Periodo_Alta
	@idPeriodo INT,
	@descripcion VARCHAR(50),
	@inicio INT,
	@fin INT,
    @esPenales BIT = 0
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

	IF @esPenales = 0 AND @inicio IS NULL
		SET @errores += N'El inicio es obligatorio. ';
	IF @inicio IS NOT NULL AND @inicio < 0
		SET @errores += N'El inicio no puede ser negativo. ';

	IF @esPenales = 0 AND @fin IS NULL
		SET @errores += N'El fin es obligatorio. ';
	IF @fin IS NOT NULL AND @inicio IS NOT NULL AND @fin < @inicio
		SET @errores += N'El fin no puede ser menor al inicio. ';

	IF @esPenales IS NULL SET @errores += N'EsPenales es obligatorio. ';
    IF @esPenales = 1 AND (@inicio IS NOT NULL OR @fin IS NOT NULL)
        SET @errores += N'Penales requiere Inicio y Fin NULL. ';
    IF LEN(@errores) > 0
		THROW 50000, @errores, 1;

	BEGIN TRY
		BEGIN TRANSACTION;

		INSERT INTO partidos.Periodo (IdPeriodo, Descripcion, Inicio, Fin, EsPenales)
		VALUES (@idPeriodo, @descripcion, @inicio, @fin, @esPenales);

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
	@fin INT,
    @esPenales BIT = 0
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

	IF @esPenales = 0 AND @inicio IS NULL
		SET @errores += N'El inicio es obligatorio. ';
	IF @inicio IS NOT NULL AND @inicio < 0
		SET @errores += N'El inicio no puede ser negativo. ';

	IF @esPenales = 0 AND @fin IS NULL
		SET @errores += N'El fin es obligatorio. ';
	IF @fin IS NOT NULL AND @inicio IS NOT NULL AND @fin < @inicio
		SET @errores += N'El fin no puede ser menor al inicio. ';

	IF EXISTS (SELECT 1 FROM partidos.Evento WHERE Periodo=@idPeriodo)
       AND EXISTS (SELECT 1 FROM partidos.Periodo WHERE IdPeriodo=@idPeriodo
         AND (EsPenales<>@esPenales OR ISNULL(Inicio,-1)<>ISNULL(@inicio,-1) OR ISNULL(Fin,-1)<>ISNULL(@fin,-1)))
        SET @errores += N'No se pueden cambiar los limites o tipo de un periodo con eventos. ';
    IF @esPenales IS NULL SET @errores += N'EsPenales es obligatorio. ';
    IF @esPenales = 1 AND (@inicio IS NOT NULL OR @fin IS NOT NULL)
        SET @errores += N'Penales requiere Inicio y Fin NULL. ';
    IF LEN(@errores) > 0
		THROW 50000, @errores, 1;

	BEGIN TRY
		BEGIN TRANSACTION;

		UPDATE partidos.Periodo
		SET Descripcion = @descripcion,
			Inicio = @inicio,
			Fin = @fin,
            EsPenales = @esPenales
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
