--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 08/10/2026

--Creacion de Stored Procedures que involucran transacciones

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

--Arbitraje
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspArbitraje_Registrar'))
    DROP PROCEDURE SPTRANS.uspArbitraje_Registrar
GO
CREATE PROCEDURE SPTRANS.uspArbitraje_Registrar 
@arbitro INT,
@funcion VARCHAR(20),
@partido INT
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine varchar(300)

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	--Chequeo validez
	IF(@arbitro IS NULL) OR (@arbitro <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Arbitro.'
	END

	IF(@funcion IS NULL) OR (@funcion NOT IN ('Principal', 'Asistente', '4to', 'VAR'))
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Funcion.'
	END

	IF(@partido IS NULL) OR (@partido <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Partido.'
	END

	--chequeo existencia
	IF(@errorCount = 0)
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM TABLAS.Arbitro WHERE IdArbitro = @arbitro)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: ID Arbitro.'
		END

		IF NOT EXISTS(SELECT 1 FROM TABLAS.Partido WHERE IdPartido = @partido)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: ID Partido.'
		END
	END

	--chequeo dup
	IF(@errorCount = 0) AND EXISTS(SELECT 1 FROM TABLAS.Arbitraje WHERE Arbitro = @arbitro AND Partido = @partido)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor duplicado: Arbitro. Se encuentra ya asignado a alguna funcion de ese partido.'
	END

	--chequeo cupo
	IF(@errorCount = 0)
	AND
	(
		((@funcion = 'Principal') AND ((SELECT COUNT(Arbitro) FROM TABLAS.Arbitraje WHERE Partido = @partido AND Funcion = 'Principal') >= 1))
		OR
		((@funcion = 'Asistente') AND ((SELECT COUNT(Arbitro) FROM TABLAS.Arbitraje WHERE Partido = @partido AND Funcion = 'Asistente') >= 2))
		OR
		((@funcion = 'VAR') AND ((SELECT COUNT(Arbitro) FROM TABLAS.Arbitraje WHERE Partido = @partido AND Funcion = 'VAR') >= 1))
		OR
		((@funcion = '4to') AND ((SELECT COUNT(Arbitro) FROM TABLAS.Arbitraje WHERE Partido = @partido AND Funcion = '4to') >= 1))
	)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Cupo excedido para esa funcion.'
	END

	--chequeo nacionalidad(para este partido)
	IF(@errorCount = 0) 
	AND 
	EXISTS
	(
		SELECT 1
		FROM
		(
			SELECT IdPais
			FROM TABLAS.Seleccion
			WHERE IdSeleccion 
			IN (SELECT Eq1, Eq2 FROM TABLAS.Partido WHERE IdPartido = @partido)
		) AS P
		WHERE Pais = (SELECT Pais FROM TABLAS.Persona WHERE IdPersona = @arbitro)
	)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- No se puede asignar este arbitro, el pais al que pertenece disputa este partido.'
	END

	--chequeo nacionalidad(por peligro de cruze a futuro -> solo se advierte)
	IF(@errorCount = 0)
	AND
	EXISTS
	(
		SELECT 1
		FROM
		(
			SELECT IdPais
			FROM TABLAS.Seleccion
			WHERE IdSeleccion 
			IN (SELECT P.Eq1, P.Eq2
				FROM TABLAS.Partido P
				INNER JOIN TABLAS.Fase F ON P.IdFase = F.IdFase
				WHERE F.Descripcion <> 'Grupos'
				  AND CAST(P.Fecha AS DATETIME) + P.HoraUTC >= GETDATE())
		) AS P
		WHERE Pais = (SELECT Pais FROM TABLAS.Persona WHERE IdPersona = @arbitro)
	)
		PRINT '-ADVERTENCIA- Este arbitro pertenece a un pais cuya seleccion puede cruzarse con los involucrados en este partido.'

	IF(@errorCount = 0)
	BEGIN
		BEGIN TRANSACTION
		BEGIN TRY
			INSERT INTO TABLAS.Arbitraje
			VALUES (@arbitro, @funcion, @partido)

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

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspArbitraje_Update'))
    DROP PROCEDURE SPTRANS.uspArbitraje_Update
GO
CREATE PROCEDURE SPTRANS.uspArbitraje_Update 
@arbitro INT,
@funcion VARCHAR(20),
@partido INT
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine varchar(300)

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	--Chequeo validez
	IF(@arbitro IS NULL) OR (@arbitro <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Arbitro.'
	END

	IF(@funcion IS NULL) OR (@funcion NOT IN ('Principal', 'Asistente', '4to', 'VAR'))
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Funcion.'
	END

	IF(@partido IS NULL) OR (@partido <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Partido.'
	END

	--chequeo existencia
	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM TABLAS.Arbitraje WHERE Arbitro = @arbitro AND Partido = @partido)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Registro inexistente.'
	END

	--chequeo dup
	IF(@errorCount = 0) AND EXISTS(SELECT 1 FROM TABLAS.Arbitraje WHERE Arbitro = @arbitro AND Partido = @partido AND Funcion = @funcion)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor duplicado: Arbitro. Se encuentra ya asignado a esa funcion.'
	END

	--chequeo cupo (se excluye el propio registro para no contarse a si mismo)
	IF(@errorCount = 0)
	AND
	(
		((@funcion = 'Principal') AND ((SELECT COUNT(Arbitro) FROM TABLAS.Arbitraje WHERE Partido = @partido AND Funcion = 'Principal' AND Arbitro <> @arbitro) >= 1))
		OR
		((@funcion = 'Asistente') AND ((SELECT COUNT(Arbitro) FROM TABLAS.Arbitraje WHERE Partido = @partido AND Funcion = 'Asistente' AND Arbitro <> @arbitro) >= 2))
		OR
		((@funcion = 'VAR') AND ((SELECT COUNT(Arbitro) FROM TABLAS.Arbitraje WHERE Partido = @partido AND Funcion = 'VAR' AND Arbitro <> @arbitro) >= 1))
		OR
		((@funcion = '4to') AND ((SELECT COUNT(Arbitro) FROM TABLAS.Arbitraje WHERE Partido = @partido AND Funcion = '4to' AND Arbitro <> @arbitro) >= 1))
	)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Cupo excedido para esa funcion.'
	END

	IF(@errorCount = 0)
	BEGIN
		BEGIN TRANSACTION
		BEGIN TRY
			UPDATE TABLAS.Arbitraje
			SET Funcion = @funcion
			WHERE Arbitro = @arbitro AND Partido = @partido

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

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspArbitraje_Bajar'))
    DROP PROCEDURE SPTRANS.uspArbitraje_Bajar
GO
CREATE PROCEDURE SPTRANS.uspArbitraje_Bajar 
@arbitro INT,
@partido INT
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine varchar(300)

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	--Chequeo validez
	IF(@arbitro IS NULL) OR (@arbitro <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Arbitro.'
	END

	IF(@partido IS NULL) OR (@partido <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Partido.'
	END

	--chequeo existencia
	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM TABLAS.Arbitraje WHERE Arbitro = @arbitro AND Partido = @partido)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Registro inexistente.'
	END

	IF(@errorCount = 0)
	BEGIN
		BEGIN TRANSACTION
		BEGIN TRY
			DELETE FROM TABLAS.Arbitraje
			WHERE Arbitro = @arbitro AND Partido = @partido

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
