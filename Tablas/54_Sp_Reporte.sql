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
	BEGIN TRY
		IF(@razon IS NULL) OR (@razon NOT IN ('Sancion', 'Informe PostPartido'))
			THROW 50000, '- Valor invalido: Razon.', 1;

		IF(@descripcion IS NULL)
			THROW 50000, '- Valor invalido: Descripcion.', 1;

		IF(@arbitro IS NULL) OR (@arbitro <= 0)
			THROW 50000, '- Valor invalido: Arbitro.', 1;

		IF(@partido IS NULL) OR (@partido <= 0)
			THROW 50000, '- Valor invalido: Partido.', 1;

		IF NOT EXISTS(SELECT 1 FROM arbitros.Arbitro WHERE IdArbitro = @arbitro)
			THROW 50000, '- Valor inexistente: Arbitro.', 1;

		IF NOT EXISTS(SELECT 1 FROM partidos.Partido WHERE IdPartido = @partido)
			THROW 50000, '- Valor inexistente: Partido.', 1;

		IF EXISTS(SELECT 1 FROM arbitros.Reporte WHERE Arbitro = @arbitro AND Partido = @partido AND Descripcion = @descripcion)
			THROW 50000, '- Valor duplicado: Descripcion.', 1;

		--chequeo de participacion del arbitro en dicho partido
		IF NOT EXISTS(SELECT 1 FROM arbitros.Arbitraje WHERE Arbitro = @arbitro AND Partido = @partido)
			THROW 50000, '- El arbitro no participo de ese partido.', 1;

		--chequeo estado del partido (si ya se jugo o no)
		--Un partido se considera disputado cuando su Fecha + HoraUTC ya paso.
		IF EXISTS(SELECT 1 FROM partidos.Partido WHERE IdPartido = @partido AND CAST(Fecha AS DATETIME) + CAST(HoraUTC AS DATETIME) >= GETDATE())
			THROW 50000, '- El partido aun no se ha jugado.', 1;

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
	BEGIN TRY
		IF(@id IS NULL) OR (@id <= 0)
			THROW 50000, '- Valor invalido: ID Reporte.', 1;

		IF(@razon IS NOT NULL) AND (@razon NOT IN ('Sancion', 'Informe PostPartido'))
			THROW 50000, '- Valor invalido: Razon.', 1;

		IF NOT EXISTS(SELECT 1 FROM arbitros.Reporte WHERE IdReporte = @id)
			THROW 50000, '- Valor inexistente: ID Reporte.', 1;

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
			THROW 50000, '- Valor duplicado: Descripcion.', 1;

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
	BEGIN TRY
		IF(@id IS NULL) OR (@id <= 0)
			THROW 50000, '- Valor invalido: ID Reporte.', 1;

		IF NOT EXISTS(SELECT 1 FROM arbitros.Reporte WHERE IdReporte = @id)
			THROW 50000, '- Valor inexistente: ID Reporte.', 1;

		--No existen tablas que dependan de Reporte, no se requieren validaciones de relacion.
		DELETE FROM arbitros.Reporte WHERE IdReporte = @id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO