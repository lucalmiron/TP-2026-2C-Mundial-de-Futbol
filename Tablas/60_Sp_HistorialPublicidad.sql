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

--HistorialPublicidad
IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspHistorialPublicidad_Registrar'))
    DROP PROCEDURE SP.uspHistorialPublicidad_Registrar
GO
CREATE PROCEDURE SP.uspHistorialPublicidad_Registrar @idPublicidad INT, @idPartido INT, @idEP INT, @costoFinal DECIMAL(10,2)
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine varchar(300)

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	IF(@idPublicidad IS NULL) OR (@idPublicidad <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Publicidad.'
	END

	IF(@idPartido IS NULL) OR (@idPartido <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Partido.'
	END

	IF(@idEP IS NULL) OR (@idEP <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID EP.'
	END

	IF(@costoFinal IS NULL) OR (@costoFinal <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Costo Final.'
	END

	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM TABLAS.Publicidad WHERE IdPublicidad = @idPublicidad)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: ID Publicidad.'
	END

	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM TABLAS.Partido WHERE IdPartido = @idPartido)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: ID Partido.'
	END

	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM TABLAS.EspacioPublicitario WHERE IdEP = @idEP)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: ID EP.'
	END

	IF(@errorCount = 0) AND EXISTS(SELECT 1 FROM TABLAS.HistorialPublicidad WHERE IdPublicidad = @idPublicidad AND IdPartido = @idPartido AND IdEP = @idEP)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor duplicado: Publicidad en Partido y Espacio Publicitario.'
	END

	IF(@errorCount = 0)
		INSERT INTO TABLAS.HistorialPublicidad(IdPublicidad, IdPartido, IdEP, CostoFinal) VALUES (@idPublicidad, @idPartido, @idEP, @costoFinal)
	ELSE
		PRINT @errorLine
END;
GO

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspHistorialPublicidad_Update'))
    DROP PROCEDURE SP.uspHistorialPublicidad_Update
GO
CREATE PROCEDURE SP.uspHistorialPublicidad_Update @id INT, @idPublicidad INT, @idPartido INT, @idEP INT, @costoFinal DECIMAL(10,2)
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine varchar(300)

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	IF(@id IS NULL) OR (@id <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Historial.'
	END

	IF(@idPublicidad IS NULL) OR (@idPublicidad <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Publicidad.'
	END

	IF(@idPartido IS NULL) OR (@idPartido <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Partido.'
	END

	IF(@idEP IS NULL) OR (@idEP <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID EP.'
	END

	IF(@costoFinal IS NULL) OR (@costoFinal <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Costo Final.'
	END

	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM TABLAS.HistorialPublicidad WHERE IdHistorial = @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: ID Historial.'
	END

	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM TABLAS.Publicidad WHERE IdPublicidad = @idPublicidad)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: ID Publicidad.'
	END

	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM TABLAS.Partido WHERE IdPartido = @idPartido)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: ID Partido.'
	END

	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM TABLAS.EspacioPublicitario WHERE IdEP = @idEP)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: ID EP.'
	END

	IF(@errorCount = 0) AND EXISTS(SELECT 1 FROM TABLAS.HistorialPublicidad WHERE IdPublicidad = @idPublicidad AND IdPartido = @idPartido AND IdEP = @idEP AND IdHistorial <> @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor duplicado: Publicidad en Partido y Espacio Publicitario.'
	END

	IF(@errorCount = 0)
	BEGIN
		UPDATE TABLAS.HistorialPublicidad
		SET IdPublicidad = @idPublicidad, IdPartido = @idPartido, IdEP = @idEP, CostoFinal = @costoFinal
		WHERE IdHistorial = @id
	END
	ELSE
		PRINT @errorLine
END;
GO

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspHistorialPublicidad_Bajar'))
    DROP PROCEDURE SP.uspHistorialPublicidad_Bajar
GO
CREATE PROCEDURE SP.uspHistorialPublicidad_Bajar @id INT
AS
BEGIN
	DECLARE @errorCount INT

	SET @errorCount = 0

	IF(@id IS NULL) OR (@id <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Valor invalido: ID Historial.'
	END

	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM TABLAS.HistorialPublicidad WHERE IdHistorial = @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Valor inexistente: ID Historial.'
	END

	IF(@errorCount = 0)
		DELETE FROM TABLAS.HistorialPublicidad WHERE IdHistorial = @id
END;
GO