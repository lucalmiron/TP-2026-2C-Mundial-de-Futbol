--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Creacion de Stored Procedures

-- Ejecutar en la base seleccionada por el instalador.
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
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF(@razon IS NULL) OR (@razon NOT IN ('Sancion', 'Informe PostPartido'))
			SET @errores += '- Valor invalido: Razon.' + N' ';

		IF(@descripcion IS NULL)
			SET @errores += '- Valor invalido: Descripcion.' + N' ';

		IF(@arbitro IS NULL) OR (@arbitro <= 0)
			SET @errores += '- Valor invalido: Arbitro.' + N' ';

		IF(@partido IS NULL) OR (@partido <= 0)
			SET @errores += '- Valor invalido: Partido.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM arbitros.Arbitro WHERE IdArbitro = @arbitro)
			SET @errores += '- Valor inexistente: Arbitro.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM partidos.Partido WHERE IdPartido = @partido)
			SET @errores += '- Valor inexistente: Partido.' + N' ';

		IF EXISTS(SELECT 1 FROM arbitros.Reporte WHERE Arbitro = @arbitro AND Partido = @partido AND Descripcion = @descripcion)
			SET @errores += '- Valor duplicado: Descripcion.' + N' ';

		--chequeo de participacion del arbitro en dicho partido
		IF NOT EXISTS(SELECT 1 FROM arbitros.Arbitraje WHERE Arbitro = @arbitro AND Partido = @partido)
			SET @errores += '- El arbitro no participo de ese partido.' + N' ';

		--chequeo estado del partido (si ya se jugo o no)
		--Un partido se considera disputado cuando su Fecha + HoraUTC ya paso.
		IF EXISTS(SELECT 1 FROM partidos.Partido WHERE IdPartido = @partido AND CAST(Fecha AS DATETIME) + CAST(HoraUTC AS DATETIME) >= GETDATE())
			SET @errores += '- El partido aun no se ha jugado.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		INSERT INTO arbitros.Reporte(Razon, Descripcion, Arbitro, Partido) VALUES (@razon, @descripcion, @arbitro, @partido)
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
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
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF(@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Reporte.' + N' ';

		IF(@razon IS NOT NULL) AND (@razon NOT IN ('Sancion', 'Informe PostPartido'))
			SET @errores += '- Valor invalido: Razon.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM arbitros.Reporte WHERE IdReporte = @id)
			SET @errores += '- Valor inexistente: ID Reporte.' + N' ';

		--chequeo dup (descripcion repetida por el mismo arbitro sobre el mismo partido, excluyendo el propio registro)
		IF(@descripcion IS NOT NULL)
		AND EXISTS
		(
			SELECT 1
			FROM 
			arbitros.Reporte AS R
			INNER JOIN
			(SELECT Arbitro, Partido FROM arbitros.Reporte WHERE IdReporte = @id) AS AP
			ON R.Arbitro = AP.Arbitro AND R.Partido = AP.Partido
			WHERE R.Descripcion = @descripcion AND R.IdReporte <> @id
		)
			SET @errores += '- Valor duplicado: Descripcion.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		UPDATE arbitros.Reporte
		SET
		Razon = COALESCE(@razon, Razon),
		Descripcion = COALESCE(@descripcion, Descripcion)
		WHERE IdReporte = @id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspReporte_Baja'))
    DROP PROCEDURE SP.uspReporte_Baja
GO
CREATE PROCEDURE SP.uspReporte_Baja
@id INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF(@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Reporte.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM arbitros.Reporte WHERE IdReporte = @id)
			SET @errores += '- Valor inexistente: ID Reporte.' + N' ';

		--No existen tablas que dependan de Reporte, no se requieren validaciones de relacion.

		IF LEN(@errores)>0 THROW 50000, @errores, 1;
		DELETE FROM arbitros.Reporte WHERE IdReporte = @id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO