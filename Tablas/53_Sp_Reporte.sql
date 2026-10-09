--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 08/10/2026

--Creacion de Stored Procedures

IF EXISTS(SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

--Reporte
IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspReporte_Registrar'))
    DROP PROCEDURE SP.uspReporte_Registrar
GO
CREATE PROCEDURE SP.uspReporte_Registrar 
@razon VARCHAR(20), @descripcion VARCHAR(300),
@arbitro INT, @partido INT
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine varchar(300)

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	IF(@razon IS NULL) OR (@razon NOT IN ('Sancion', 'Informe PostPartido'))
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Razon.'
	END

	IF(@descripcion IS NULL)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Descripcion.'
	END

	IF(@arbitro IS NULL) OR (@arbitro <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Arbitro.'
	END

	IF(@partido IS NULL) OR (@partido <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Partido.'
	END

	IF(@errorCount = 0)
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM arbitros.Arbitro WHERE IdArbitro = @arbitro)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Arbitro.'
		END

		IF NOT EXISTS(SELECT 1 FROM partidos.Partido WHERE IdPartido = @partido)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Partido.'
		END
	END

	IF(@errorCount = 0) AND EXISTS(SELECT 1 FROM arbitros.Reporte WHERE Arbitro = @arbitro AND Partido = @partido AND Descripcion = @descripcion)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor duplicado: Descripcion.'
	END

	--chequeo de participacion del arbitro en dicho partido
	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM arbitros.Arbitraje WHERE Arbitro = @arbitro AND Partido = @partido)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- El arbitro no participo de ese partido.'
	END

	--chequeo estado del partido (si ya se jugo o no)
	--Un partido se considera disputado cuando su Fecha + HoraUTC ya paso.
	IF(@errorCount = 0) AND EXISTS(SELECT 1 FROM partidos.Partido WHERE IdPartido = @partido AND CAST(Fecha AS DATETIME) + CAST(HoraUTC AS DATETIME) >= GETDATE())
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- El partido aun no se ha jugado.'
	END

	IF(@errorCount = 0)
		INSERT INTO arbitros.Reporte(Razon, Descripcion, Arbitro, Partido) VALUES (@razon, @descripcion, @arbitro, @partido)
	ELSE
		PRINT @errorLine
END;
GO

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspReporte_Update'))
    DROP PROCEDURE SP.uspReporte_Update
GO
CREATE PROCEDURE SP.uspReporte_Update
@id INT,
@razon VARCHAR(20) = NULL, @descripcion VARCHAR(300) = NULL
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine varchar(300)
	DECLARE @vArbitro INT, @vPartido INT

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	IF(@id IS NULL) OR (@id <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Reporte.'
	END

	IF(@razon IS NOT NULL) AND (@razon NOT IN ('Sancion', 'Informe PostPartido'))
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Razon.'
	END

	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM arbitros.Reporte WHERE IdReporte = @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: ID Reporte.'
	END

	--chequeo dup (descripcion repetida por el mismo arbitro sobre el mismo partido, excluyendo el propio registro)
	IF(@errorCount = 0) 
	AND 
	EXISTS
	(
		SELECT 1
		FROM 
		arbitros.Reporte AS R
		INNER JOIN
		(SELECT Arbitro, Partido FROM arbitros.Reporte WHERE IdReporte = @id) AS AP
		ON R.Arbitro = AP.Arbitro AND R.Partido = AP.Partido
		WHERE R.Descripcion = @descripcion AND R.IdReporte <> @id
	)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor duplicado: Descripcion.'
	END

	IF(@errorCount = 0)
	BEGIN
		UPDATE arbitros.Reporte
		SET
		Razon = COALESCE(@razon, Razon),
		Descripcion = COALESCE(@descripcion, Descripcion)
		WHERE IdReporte = @id
	END
	ELSE
		PRINT @errorLine
END;
GO

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspReporte_Baja'))
    DROP PROCEDURE SP.uspReporte_Baja
GO
CREATE PROCEDURE SP.uspReporte_Baja
@id INT
AS
BEGIN
	DECLARE @errorCount INT

	SET @errorCount = 0

	IF(@id IS NULL) OR (@id <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Valor invalido: ID Reporte.'
	END

	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM arbitros.Reporte WHERE IdReporte = @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Valor inexistente: ID Reporte.'
	END

	--No existen tablas que dependan de Reporte, no se requieren validaciones de relacion.
	IF(@errorCount = 0)
		DELETE FROM arbitros.Reporte WHERE IdReporte = @id
END;
GO
