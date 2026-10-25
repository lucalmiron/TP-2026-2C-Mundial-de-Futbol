--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: xx/xx/2026

--Creacion de SP para asignacion de publicidad a partido

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspPublicidad_Asignar'))
    DROP PROCEDURE SPTRANS.uspPublicidad_Asignar
GO
CREATE PROCEDURE SPTRANS.uspPublicidad_Asignar
@partido INT,
@lim INT = 4
AS
BEGIN
	DECLARE @cantActual INT, @case INT, @cantInsert INT, @prime INT, @id INT
	DECLARE @huso VARCHAR(50)
	DECLARE @horaPartido TIME, @horaConvert TIME
	DECLARE @fechaPartido DATE
	DECLARE @aumento DECIMAL(10, 2)

	DECLARE @paises TABLE (ID INT IDENTITY(1, 1), Pais INT, Huso VARCHAR(50), PtIni TIME, PtFin TIME)
	DECLARE @aInsertarA TABLE (ID INT IDENTITY(1, 1), Publicidad INT)
	DECLARE @aInsertarB TABLE (ID INT IDENTITY(1, 1), Publicidad INT, Partido INT, Espacio INT, Costo DECIMAL(10, 2))
	DECLARE @primeTimes TABLE (ID INT IDENTITY(1, 1), Pais INT, Ini TIME, Fin TIME)

	DECLARE @errorCount INT
	DECLARE @errorLine varchar(100)

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	IF (@partido IS NULL) OR (@partido <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Partido.'
	END

	IF (@lim IS NULL) OR (@lim <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Limite.'
	END

	IF (@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM partidos.Partido WHERE IdPartido = @partido)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Partido.'
	END

	IF (@errorCount = 0)
	BEGIN
		BEGIN TRANSACTION
		BEGIN TRY
			SET @cantActual = 0
			SET @case = 1
			SET @id = 1
			SET @prime = 0

			--Hago la consulta una sola vez y guardo los datos que necesito de paises que juegan el partido en una tabla variable
			INSERT INTO @paises(Pais, Huso, PtIni, PtFin)
			SELECT IdPais, HusoHorario, PtIni, PtFin
			FROM equipos.Pais
			WHERE IdPais IN
			(
				SELECT IdPais
				FROM equipos.Seleccion
				WHERE IdSeleccion IN
				(SELECT Eq1 AS Seleccion FROM partidos.Partido WHERE IdPartido = @partido
				UNION
				SELECT Eq2 AS Seleccion FROM partidos.Partido WHERE IdPartido = @partido)
			)

			--obtengo las publicidades para el partido segun el criterio armado
			WHILE (@cantActual <> @lim)
			BEGIN
				SET @cantInsert = @lim - @cantActual

				IF @case = 1
				BEGIN
					INSERT INTO @aInsertarA(Publicidad)
					SELECT TOP (@cantInsert) IdPublicidad
					FROM publicidad.PublicidadPais
					WHERE IdPais IN (SELECT Pais FROM @paises)
					EXCEPT
					SELECT Publicidad
					FROM @aInsertarA
				END

				IF @case = 2
				BEGIN
					WITH pais AS
					(
						SELECT IdPais
						FROM sedes.Sede
						WHERE IdSede = (SELECT IdSede FROM partidos.Partido WHERE IdPartido = @partido)
					)
					INSERT INTO @aInsertarA(Publicidad)
					SELECT TOP (@cantInsert) IdPublicidad
					FROM publicidad.PublicidadPais
					WHERE IdPais IN (SELECT IdPais FROM pais)
					EXCEPT
					SELECT Publicidad
					FROM @aInsertarA
				END

				IF @case = 3
				BEGIN
					WITH idiomas AS
					(
						SELECT Idioma
						FROM equipos.Pais
						WHERE IdPais IN (SELECT Pais FROM @paises)
					)
					INSERT INTO @aInsertarA(Publicidad)
					SELECT TOP (@cantInsert) IdPublicidad
					FROM publicidad.Publicidad
					WHERE IdIdioma IN (SELECT Idioma FROM idiomas)
					EXCEPT
					SELECT Publicidad
					FROM @aInsertarA 
				END

				IF @case = 4
				BEGIN
					INSERT INTO @aInsertarA(Publicidad)
					SELECT TOP (@cantInsert) IdPublicidad
					FROM publicidad.Publicidad
					EXCEPT
					SELECT Publicidad
					FROM @aInsertarA 
				END

				SET @cantActual = (SELECT COUNT(Publicidad) FROM @aInsertarA)
				SET @case = @case + 1
			END

			--Obtengo los datos relacionados a los espacios publicitarios de la sede del partido
			INSERT INTO @aInsertarB(Espacio, Costo)
			SELECT TOP (@lim) IdEP, Costo 
			FROM publicidad.EspacioPublicitario
			WHERE IdSede = (SELECT IdSede FROM partidos.Partido)

			--Registro el partido
			UPDATE @aInsertarB
			SET Partido = @partido

			--Combino los datos de las publicidades con los de los espacios publicitarios en una sola tabla
			UPDATE B
			SET B.Publicidad = A.Publicidad
			FROM 
			@aInsertarA AS A
			INNER JOIN 
			@aInsertarB AS B
			ON A.ID = B.ID

			--Obtengo fecha y hora del partido
			SET @horaPartido = (SELECT Hora FROM partidos.Partido WHERE IdPartido = @partido)
			SET @fechaPartido = (SELECT Fecha FROM partidos.Partido WHERE IdPartido = @partido)

			--hago conversion y comparo contra el primer pais de los que juegan
			WHILE( (@id < 3) AND (@prime = 0) )
			BEGIN
				SET @huso =
				(
					SELECT Nombre
					FROM sedes.HusoHorario
					WHERE IdHuso = (SELECT Huso FROM @paises WHERE ID = @id)
				)

				EXECUTE SP.uspAPIconversionHora @fecha = @fechaPartido, @hora = @horaPartido, @timezone = @huso, @horaConv = @horaConvert OUTPUT

				IF EXISTS(SELECT 1 FROM @paises WHERE ID = @id AND PtIni <= @horaConvert AND @horaConvert <= PtFin)
					SET @prime = 1

				SET @id = @id + 1
			END

			----ajusto los costos segun si cayo en franja prime o no
			--primero obtengo el costo de la franja segun la sede
			IF @prime = 1
			BEGIN
				SET @aumento =
				(
					SELECT Costo
					FROM publicidad.CostoFranja
					WHERE TipoFranja = 'Primetime'
					AND
					IdSede = (SELECT IdSede FROM partidos.Partido WHERE IdPartido = @partido)
				)
			END
			ELSE
			BEGIN
				SET @aumento =
				(
					SELECT Costo
					FROM publicidad.CostoFranja
					WHERE TipoFranja = 'Normal'
					AND
					IdSede = (SELECT IdSede FROM partidos.Partido WHERE IdPartido = @partido)
				)
			END
			--finalmente actualizo los costos
			UPDATE @aInsertarB
			SET Costo = Costo + @aumento

			--registro sobre historial
			INSERT INTO publicidad.HistorialPublicidad(IdPublicidad, IdPartido, IdEP, CostoFinal)
			SELECT Publicidad, Partido, Espacio, Costo
			FROM @aInsertarB

			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION;

			DECLARE @Msg NVARCHAR(500) = ERROR_MESSAGE();
			DECLARE @Num INT           = ERROR_NUMBER();
			PRINT CONCAT('ERROR (', @Num, '): ', @Msg);
		END CATCH
	END
	ELSE
		PRINT @errorLine
END;
GO