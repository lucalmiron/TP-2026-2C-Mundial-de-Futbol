--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 08/10/2026

--Objetivo: SP de ABM de la tabla partidos.Evento (Alta, Baja, Modificacion).
--Las validaciones se acumulan en una variable y se lanzan con un unico THROW.

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

-- =============================================
-- partidos.Evento_Alta
-- Inserta un evento y devuelve el IdEvento generado en @idEvento.
-- Minuto es opcional; el resto de los parametros son obligatorios.
-- =============================================
CREATE OR ALTER PROCEDURE partidos.Evento_Alta
	@minuto INT,
	@tipo VARCHAR(50),
	@partido INT,
	@periodo INT,
	@idEvento INT OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE @errores NVARCHAR(MAX) = N'';

	IF @tipo IS NULL OR LTRIM(RTRIM(@tipo)) = N''
		SET @errores += N'El tipo es obligatorio. ';
	IF @tipo IS NOT NULL AND LEN(@tipo) > 12
		SET @errores += N'El tipo no puede superar los 12 caracteres. ';

	IF @partido IS NULL
		SET @errores += N'El partido es obligatorio. ';
	IF @partido IS NOT NULL AND NOT EXISTS (SELECT 1 FROM partidos.Partido WHERE IdPartido = @partido)
		SET @errores += N'No existe un partido con IdPartido ' + CAST(@partido AS NVARCHAR(10)) + N'. ';

	IF @periodo IS NULL
		SET @errores += N'El periodo es obligatorio. ';
	IF @periodo IS NOT NULL AND NOT EXISTS (SELECT 1 FROM partidos.Periodo WHERE IdPeriodo = @periodo)
		SET @errores += N'No existe un periodo con IdPeriodo ' + CAST(@periodo AS NVARCHAR(10)) + N'. ';

	IF @minuto IS NOT NULL AND @minuto < 0
		SET @errores += N'El minuto no puede ser negativo. ';
	IF @minuto IS NOT NULL AND @minuto >= 0
		AND EXISTS (SELECT 1 FROM partidos.Periodo
					WHERE IdPeriodo = @periodo AND (@minuto < Inicio OR @minuto > Fin))
		SET @errores += N'El minuto esta fuera del rango del periodo indicado. ';

	IF LEN(@errores) > 0
		THROW 50000, @errores, 1;

	BEGIN TRY
		BEGIN TRANSACTION;

		INSERT INTO partidos.Evento (Minuto, Tipo, Partido, Periodo)
		VALUES (@minuto, @tipo, @partido, @periodo);

		SET @idEvento = SCOPE_IDENTITY();

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END;
GO

-- =============================================
-- partidos.Evento_Modificacion
-- Modifica un evento existente. Minuto es opcional; el resto es obligatorio.
-- =============================================
CREATE OR ALTER PROCEDURE partidos.Evento_Modificacion
	@idEvento INT,
	@minuto INT,
	@tipo VARCHAR(50),
	@partido INT,
	@periodo INT
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE @errores NVARCHAR(MAX) = N'';

	IF @idEvento IS NULL
		SET @errores += N'IdEvento es obligatorio. ';
	IF @idEvento IS NOT NULL AND NOT EXISTS (SELECT 1 FROM partidos.Evento WHERE IdEvento = @idEvento)
		SET @errores += N'No existe un evento con IdEvento ' + CAST(@idEvento AS NVARCHAR(10)) + N'. ';

	IF @tipo IS NULL OR LTRIM(RTRIM(@tipo)) = N''
		SET @errores += N'El tipo es obligatorio. ';
	IF @tipo IS NOT NULL AND LEN(@tipo) > 12
		SET @errores += N'El tipo no puede superar los 12 caracteres. ';

	IF @partido IS NULL
		SET @errores += N'El partido es obligatorio. ';
	IF @partido IS NOT NULL AND NOT EXISTS (SELECT 1 FROM partidos.Partido WHERE IdPartido = @partido)
		SET @errores += N'No existe un partido con IdPartido ' + CAST(@partido AS NVARCHAR(10)) + N'. ';

	IF @periodo IS NULL
		SET @errores += N'El periodo es obligatorio. ';
	IF @periodo IS NOT NULL AND NOT EXISTS (SELECT 1 FROM partidos.Periodo WHERE IdPeriodo = @periodo)
		SET @errores += N'No existe un periodo con IdPeriodo ' + CAST(@periodo AS NVARCHAR(10)) + N'. ';

	IF @minuto IS NOT NULL AND @minuto < 0
		SET @errores += N'El minuto no puede ser negativo. ';
	IF @minuto IS NOT NULL AND @minuto >= 0
		AND EXISTS (SELECT 1 FROM partidos.Periodo
					WHERE IdPeriodo = @periodo AND (@minuto < Inicio OR @minuto > Fin))
		SET @errores += N'El minuto esta fuera del rango del periodo indicado. ';

	IF LEN(@errores) > 0
		THROW 50000, @errores, 1;

	BEGIN TRY
		BEGIN TRANSACTION;

		UPDATE partidos.Evento
		SET Minuto = @minuto,
			Tipo = @tipo,
			Partido = @partido,
			Periodo = @periodo
		WHERE IdEvento = @idEvento;

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END;
GO

-- =============================================
-- partidos.Evento_Baja
-- Elimina un evento. No se permite si tiene una amonestacion asociada.
-- =============================================
CREATE OR ALTER PROCEDURE partidos.Evento_Baja
	@idEvento INT
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE @errores NVARCHAR(MAX) = N'';

	IF @idEvento IS NULL
		SET @errores += N'IdEvento es obligatorio. ';
	IF @idEvento IS NOT NULL AND NOT EXISTS (SELECT 1 FROM partidos.Evento WHERE IdEvento = @idEvento)
		SET @errores += N'No existe un evento con IdEvento ' + CAST(@idEvento AS NVARCHAR(10)) + N'. ';
	IF @idEvento IS NOT NULL AND EXISTS (SELECT 1 FROM partidos.Amonestacion WHERE IdAmonestacion = @idEvento)
		SET @errores += N'No se puede eliminar el evento: tiene una amonestacion asociada. ';

	IF LEN(@errores) > 0
		THROW 50000, @errores, 1;

	BEGIN TRY
		BEGIN TRANSACTION;

		DELETE FROM partidos.Evento
		WHERE IdEvento = @idEvento;

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END;
GO
