--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 08/10/2026

--Objetivo: Gestionar Tabla Gol

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspGol_Registrar'))
    DROP PROCEDURE SPTRANS.uspGol_Registrar
GO
CREATE PROCEDURE SPTRANS.uspGol_Registrar
@minuto INT,
@partido INT,
@periodo INT,
@autor INT,
@asistencia INT = NULL,
@tipo VARCHAR(20)
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine VARCHAR(300)

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	IF (@minuto IS NOT NULL) AND (@minuto < 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Minuto.'
	END

	IF (@partido IS NULL) OR (@partido <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Partido.'
	END

	IF (@periodo IS NULL) OR (@periodo <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Periodo.'
	END

	IF (@autor IS NULL) OR (@autor <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Autor.'
	END

	IF (@asistencia IS NOT NULL) AND (@asistencia <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Asistencia.'
	END

	IF (@tipo IS NULL) OR (@tipo NOT IN ('Jugada', 'Penal', 'Tiro libre', 'Corner', 'En contra'))
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Tipo.'
	END

	IF (@errorCount = 0)
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM partidos.Partido WHERE IdPartido = @partido)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Partido.'
		END

		IF NOT EXISTS (SELECT 1 FROM partidos.Periodo WHERE IdPeriodo = @periodo)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Periodo.'
		END

		IF NOT EXISTS (SELECT 1 FROM equipos.Jugador WHERE IdJugador = @autor)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Autor.'
		END

		IF (@asistencia IS NOT NULL) AND NOT EXISTS (SELECT 1 FROM equipos.Jugador WHERE IdJugador = @asistencia)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Asistencia.'
		END
	END

	IF (@errorCount = 0) AND (@asistencia IS NOT NULL) AND (@autor = @asistencia)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Autor y asistencia no pueden ser el mismo jugador.'
	END

	IF (@errorCount = 0) AND (@tipo = 'En contra') AND (@asistencia IS NOT NULL)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- El gol en contra no lleva asistencia.'
	END

	IF (@errorCount = 0)
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM equipos.Jugador WHERE IdJugador = @autor AND Seleccion IN (SELECT Eq1 FROM partidos.Partido WHERE IdPartido = @partido UNION SELECT Eq2 FROM partidos.Partido WHERE IdPartido = @partido))
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- El autor no participo del encuentro.'
		END

		IF (@asistencia IS NOT NULL) AND NOT EXISTS (SELECT 1 FROM equipos.Jugador WHERE IdJugador = @asistencia AND Seleccion IN (SELECT Eq1 FROM partidos.Partido WHERE IdPartido = @partido UNION SELECT Eq2 FROM partidos.Partido WHERE IdPartido = @partido))
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- La asistencia no participo del encuentro.'
		END
	END

	IF (@errorCount = 0)
	BEGIN
		DECLARE @idEvento INT
		DECLARE @vEq1 INT
		DECLARE @vEq2 INT
		DECLARE @vSelAutor INT

		BEGIN TRANSACTION
		BEGIN TRY
			INSERT INTO partidos.Evento (Minuto, Tipo, Partido, Periodo)
			VALUES (@minuto, 'Gol', @partido, @periodo)

			SET @idEvento = SCOPE_IDENTITY()

			INSERT INTO partidos.Gol (IdGol, Autor, Asistencia, Tipo)
			VALUES (@idEvento, @autor, @asistencia, @tipo)

			-- El marcador de partidos.Partido es derivado de Gol: cada gol suma 1
			-- Si el tipo es 'En contra' suma al rival del autor, sino al equipo del autor
			SELECT @vEq1 = Eq1, @vEq2 = Eq2 FROM partidos.Partido WHERE IdPartido = @partido

			SELECT @vSelAutor = Seleccion FROM equipos.Jugador WHERE IdJugador = @autor

			IF (@tipo = 'En contra')
			BEGIN
				IF (@vSelAutor = @vEq1)
					UPDATE partidos.Partido SET GolesEq2 = GolesEq2 + 1 WHERE IdPartido = @partido
				ELSE
					UPDATE partidos.Partido SET GolesEq1 = GolesEq1 + 1 WHERE IdPartido = @partido
			END
			ELSE
			BEGIN
				IF (@vSelAutor = @vEq1)
					UPDATE partidos.Partido SET GolesEq1 = GolesEq1 + 1 WHERE IdPartido = @partido
				ELSE
					UPDATE partidos.Partido SET GolesEq2 = GolesEq2 + 1 WHERE IdPartido = @partido
			END

			COMMIT TRANSACTION
		END TRY
		BEGIN CATCH
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION

			DECLARE @Msg NVARCHAR(500) = ERROR_MESSAGE()
			DECLARE @Num INT = ERROR_NUMBER()
			PRINT CONCAT('ERROR (', @Num, '): ', @Msg)
		END CATCH
	END
	ELSE
		PRINT @errorLine
END
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspGol_Bajar'))
    DROP PROCEDURE SPTRANS.uspGol_Bajar
GO
CREATE PROCEDURE SPTRANS.uspGol_Bajar
@id INT
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine VARCHAR(300)
	DECLARE @vPartido INT
	DECLARE @vTipo VARCHAR(20)
	DECLARE @vAutor INT
	DECLARE @vEq1 INT
	DECLARE @vEq2 INT
	DECLARE @vSelAutor INT

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	IF (@id IS NULL) OR (@id <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Gol.'
	END

	IF (@errorCount = 0) AND NOT EXISTS (SELECT 1 FROM partidos.Gol WHERE IdGol = @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Registro inexistente.'
	END

	IF (@errorCount = 0)
	BEGIN
		BEGIN TRANSACTION
		BEGIN TRY
			SELECT @vTipo = Tipo, @vAutor = Autor FROM partidos.Gol WHERE IdGol = @id

			SELECT @vPartido = Partido FROM partidos.Evento WHERE IdEvento = @id

			-- Revierte el marcador derivado del mismo lado que sumo el alta, con piso en 0
			IF (@vPartido IS NOT NULL) AND (@vTipo IS NOT NULL) AND (@vAutor IS NOT NULL)
			BEGIN
				SELECT @vEq1 = Eq1, @vEq2 = Eq2 FROM partidos.Partido WHERE IdPartido = @vPartido

				SELECT @vSelAutor = Seleccion FROM equipos.Jugador WHERE IdJugador = @vAutor

				IF (@vTipo = 'En contra')
				BEGIN
					IF (@vSelAutor = @vEq1)
						UPDATE partidos.Partido SET GolesEq2 = CASE WHEN GolesEq2 > 0 THEN GolesEq2 - 1 ELSE 0 END WHERE IdPartido = @vPartido
					ELSE
						UPDATE partidos.Partido SET GolesEq1 = CASE WHEN GolesEq1 > 0 THEN GolesEq1 - 1 ELSE 0 END WHERE IdPartido = @vPartido
				END
				ELSE
				BEGIN
					IF (@vSelAutor = @vEq1)
						UPDATE partidos.Partido SET GolesEq1 = CASE WHEN GolesEq1 > 0 THEN GolesEq1 - 1 ELSE 0 END WHERE IdPartido = @vPartido
					ELSE
						UPDATE partidos.Partido SET GolesEq2 = CASE WHEN GolesEq2 > 0 THEN GolesEq2 - 1 ELSE 0 END WHERE IdPartido = @vPartido
				END
			END

			DELETE FROM partidos.Gol
			WHERE IdGol = @id

			DELETE FROM partidos.Evento
			WHERE IdEvento = @id

			COMMIT TRANSACTION
		END TRY
		BEGIN CATCH
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION

			DECLARE @Msg NVARCHAR(500) = ERROR_MESSAGE()
			DECLARE @Num INT = ERROR_NUMBER()
			PRINT CONCAT('ERROR (', @Num, '): ', @Msg)
		END CATCH
	END
	ELSE
		PRINT @errorLine
END
GO
