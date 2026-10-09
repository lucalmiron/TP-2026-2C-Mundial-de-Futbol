--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 08/10/2026

--Testing de StoredProcedures asociados a entidades Persona(Persona, Jugador, Arbitro, Tecnico)

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIALtesting')
BEGIN
	USE MUNDIALtesting
END;
GO

--Limpieza previa para re-ejecucion en base sucia (orden inverso de dependencias)
DROP TABLE IF EXISTS TABLAS.Gol
DROP TABLE IF EXISTS TABLAS.Cambio_Convocatoria
DROP TABLE IF EXISTS TABLAS.Sustitucion
DROP TABLE IF EXISTS TABLAS.Amonestacion
DROP TABLE IF EXISTS TABLAS.Arbitraje
DROP TABLE IF EXISTS TABLAS.HablaIdioma
DROP TABLE IF EXISTS TABLAS.Reporte
DROP TABLE IF EXISTS TABLAS.Mundial
DROP TABLE IF EXISTS TABLAS.Jugador
DROP TABLE IF EXISTS TABLAS.Arbitro
DROP TABLE IF EXISTS TABLAS.Tecnico
DROP TABLE IF EXISTS TABLAS.Persona
DROP TABLE IF EXISTS TABLAS.Pais
DROP TABLE IF EXISTS TABLAS.Seleccion
DROP TABLE IF EXISTS TABLAS.Club
GO

--tablas aux de testing
CREATE TABLE TABLAS.Club
(
	IdClub INT PRIMARY KEY
);
CREATE TABLE TABLAS.Seleccion
(
	IdSeleccion INT PRIMARY KEY
);
CREATE TABLE TABLAS.Pais
(
	IdPais INT PRIMARY KEY
);
CREATE TABLE TABLAS.Amonestacion
(
	Amonestado INT,
	Arbitro INT
);
CREATE TABLE TABLAS.HablaIdioma
(
	Arbitro INT
);
CREATE TABLE TABLAS.Reporte
(
	Arbitro INT
);
CREATE TABLE TABLAS.Arbitraje
(
	Arbitro INT
);
CREATE TABLE TABLAS.Gol
(
	Autor INT,
	Asistencia INT
);
CREATE TABLE TABLAS.Sustitucion
(
	Ingreso INT,
	Egreso INT
);
CREATE TABLE TABLAS.Cambio_Convocatoria
(
	Ingreso INT,
	Egreso INT
);
CREATE TABLE TABLAS.Mundial
(
	CantJugadoresMax INT,
	CantJugadoresMin INT
);
GO

--llenado de tablas aux
INSERT INTO TABLAS.Seleccion VALUES (1), (2), (3);
INSERT INTO TABLAS.Pais VALUES (1), (2), (3);
INSERT INTO TABLAS.Club VALUES (1), (2);

INSERT INTO TABLAS.Amonestacion VALUES (2, 4), (6, 4);
INSERT INTO TABLAS.HablaIdioma VALUES (3);
INSERT INTO TABLAS.Reporte VALUES (4);
INSERT INTO TABLAS.Arbitraje VALUES (4);
INSERT INTO TABLAS.Gol VALUES (6, 7);
INSERT INTO TABLAS.Sustitucion VALUES (6, 7);
INSERT INTO TABLAS.Cambio_Convocatoria VALUES (8, 9);
--Minimo 2 para que el caso de baja exitosa no rompa el cupo minimo de la seleccion.
INSERT INTO TABLAS.Mundial VALUES (3, 2)
GO
--chequeo de datos en tablas aux
SELECT * FROM TABLAS.Club;
SELECT * FROM TABLAS.Pais;
SELECT * FROM TABLAS.Seleccion;
SELECT * FROM TABLAS.Amonestacion;
SELECT * FROM TABLAS.HablaIdioma;
SELECT * FROM TABLAS.Reporte;
SELECT * FROM TABLAS.Arbitraje;
SELECT * FROM TABLAS.Gol;
SELECT * FROM TABLAS.Sustitucion;
SELECT * FROM TABLAS.Cambio_Convocatoria;
SELECT * FROM TABLAS.Mundial;
GO

--tablas a probar
CREATE TABLE TABLAS.Persona
(
	IdPersona INT PRIMARY KEY IDENTITY(1, 1),
	Nombre VARCHAR(30),
	Fnac DATE,
	Rol VARCHAR(10),
	Pais INT,
	FOREIGN KEY(Pais) REFERENCES TABLAS.Pais(IdPais)
);

CREATE TABLE TABLAS.Tecnico
(
	IdTecnico INT,
	Funcion VARCHAR(40),
	Seleccion INT,
	TarjetasAcum INT,
	FOREIGN KEY(Seleccion) REFERENCES TABLAS.Seleccion(IdSeleccion),
	FOREIGN KEY(IdTecnico) REFERENCES TABLAS.Persona(IdPersona),
	PRIMARY KEY(IdTecnico)
);

CREATE TABLE TABLAS.Arbitro
(
	IdArbitro INT,
	Categoria VARCHAR(20),
	FOREIGN KEY(IdArbitro) REFERENCES TABLAS.Persona(IdPersona),
	PRIMARY KEY(IdArbitro)
);

CREATE TABLE TABLAS.Jugador
(
	IdJugador INT,
	Estado VARCHAR(10),
	Posicion VARCHAR(20),
	Numero INT,
	Club INT NULL,
	Seleccion INT,
	TarjetasAcum INT,
	FOREIGN KEY(IdJugador) REFERENCES TABLAS.Persona(IdPersona),
	FOREIGN KEY(Club) REFERENCES TABLAS.Club(IdClub),
	FOREIGN KEY(Seleccion) REFERENCES TABLAS.Seleccion(IdSeleccion),
	PRIMARY KEY(IdJugador)
);
GO

--SPs a probar
--Jugador
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspJugador_Registrar'))
    DROP PROCEDURE SPTRANS.uspJugador_Registrar
GO
CREATE PROCEDURE SPTRANS.uspJugador_Registrar 
@nombre VARCHAR(30),
@fnac DATE,
@pais INT,
@posicion VARCHAR(20),
@numero INT,
@club INT = NULL,
@seleccion INT
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine varchar(300)
	DECLARE @cantJugadores INT
	DECLARE @id TABLE(ID INT)

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	--Chequeo validez
	IF(@nombre IS NULL)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Nombre.'
	END

	IF(@fnac IS NULL) OR ( @fnac > CONVERT(DATE, GETDATE()) )
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Fecha de Nacimiento.'
	END

	IF(@pais IS NULL) OR (@pais <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Pais.'
	END

	IF(@posicion IS NULL)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Posicion.'
	END

	IF(@numero IS NULL) OR (@numero <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Numero.'
	END

	IF( (@club IS NOT NULL) AND (@club <= 0) )
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Club.'
	END

	IF(@seleccion IS NULL) OR (@seleccion <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Seleccion.'
	END

	--chequeo existencia
	IF(@errorCount = 0)
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM TABLAS.Pais WHERE IdPais = @pais)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Pais.'
		END

		IF (@club IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM TABLAS.Club WHERE IdClub = @club)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Club.'
		END

		IF NOT EXISTS(SELECT 1 FROM TABLAS.Seleccion WHERE IdSeleccion = @seleccion)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Seleccion.'
		END
	END

	--chequeo cupo
	IF(@errorCount = 0)
	BEGIN
		SET @cantJugadores = (SELECT COUNT(IdJugador) FROM TABLAS.Jugador WHERE Seleccion = @seleccion AND Estado <> 'Inactivo')
		IF( (@cantJugadores + 1) > (SELECT CantJugadoresMax FROM TABLAS.Mundial) )
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Cupo maximo de jugadores excedido.'
		END
	END

	--chequeo dup
	IF(@errorCount = 0)
	BEGIN
		IF EXISTS(SELECT 1 FROM TABLAS.Persona WHERE Nombre = @nombre)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor duplicado: Nombre.'
		END
		
		IF EXISTS(SELECT 1 FROM TABLAS.Jugador WHERE Numero = @numero)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor duplicado: Numero.'
		END
	END

	IF(@errorCount = 0)
	BEGIN
		BEGIN TRANSACTION
		BEGIN TRY
			INSERT INTO TABLAS.Persona(Nombre, Fnac, Pais, Rol)
			OUTPUT INSERTED.IdPersona INTO @id(ID)
			VALUES (@nombre, @fnac, @pais, 'Jugador')

			INSERT INTO TABLAS.Jugador(IdJugador, Estado, Posicion, Numero, TarjetasAcum, Club, Seleccion)
			VALUES((SELECT ID FROM @id), 'Activo', @posicion, @numero, 0, @club, @seleccion)

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

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspJugador_Update'))
    DROP PROCEDURE SPTRANS.uspJugador_Update
GO
CREATE PROCEDURE SPTRANS.uspJugador_Update 
@id INT,
@nombre VARCHAR(30) = NULL,
@fnac DATE = NULL,
@pais INT = NULL,
@posicion VARCHAR(20) = NULL,
@numero INT = NULL,
@seleccion INT = NULL
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine varchar(300)

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	--Chequeo validez
	IF(@id IS NULL) OR (@id <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Jugador.'
	END

	IF(@fnac IS NOT NULL) AND ( @fnac > CONVERT(DATE, GETDATE()) )
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Fecha de Nacimiento.'
	END

	IF(@pais IS NOT NULL) AND (@pais <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Pais.'
	END

	IF(@numero IS NOT NULL) AND (@numero <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Numero.'
	END

	IF(@seleccion IS NULL) OR (@seleccion <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Seleccion.'
	END

	--chequeo existencia
	IF(@errorCount = 0)
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM TABLAS.Jugador WHERE IdJugador = @id)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: IdJugador.'
		END

		IF (@pais IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM TABLAS.Pais WHERE IdPais = @pais)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Pais.'
		END

		IF (@seleccion IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM TABLAS.Seleccion WHERE IdSeleccion = @seleccion)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Seleccion.'
		END
	END

	--chequeo dup
	IF(@errorCount = 0)
	BEGIN
		IF EXISTS(SELECT 1 FROM TABLAS.Persona WHERE Nombre = @nombre AND IdPersona <> @id)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor duplicado: Nombre.'
		END

		IF (@numero IS NOT NULL) AND EXISTS(SELECT 1 FROM TABLAS.Jugador WHERE Numero = @numero AND IdJugador <> @id)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor duplicado: Numero.'
		END
	END

	IF(@errorCount = 0)
	BEGIN
		BEGIN TRANSACTION
		BEGIN TRY
			UPDATE TABLAS.Persona
			SET
			Nombre = COALESCE(@nombre, Nombre),
			Fnac = COALESCE(@fnac, Fnac),
			Pais = COALESCE(@pais, Pais)
			WHERE IdPersona = @id

			UPDATE TABLAS.Jugador
			SET
			Posicion = COALESCE(@posicion, Posicion),
			Numero = COALESCE(@numero, Numero),
			Seleccion = COALESCE(@seleccion, Seleccion)
			WHERE IdJugador = @id

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

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspJugador_ClubUpdate'))
    DROP PROCEDURE SP.uspJugador_ClubUpdate
GO
CREATE PROCEDURE SP.uspJugador_ClubUpdate
@id INT,
@club INT
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine varchar(300)

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	IF(@id IS NULL) OR (@id<= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Jugador.'
	END

	IF(@club IS NOT NULL) AND (@club <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Club.'
	END

	IF(@errorCount = 0)
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM TABLAS.Jugador WHERE IdJugador = @id)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: IdJugador.'
		END

		IF (@club IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM TABLAS.Club WHERE IdClub = @club)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Club.'
		END
	END

	IF(@errorCount = 0)
	BEGIN
		UPDATE TABLAS.Jugador
		SET Club = @club
		WHERE IdJugador = @id
	END
	ELSE
		PRINT @errorLine
END;
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspJugador_Bajar'))
    DROP PROCEDURE SPTRANS.uspJugador_Bajar
GO
CREATE PROCEDURE SPTRANS.uspJugador_Bajar
@id INT
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine varchar(300)
	DECLARE @cantJugadores INT
	DECLARE @seleccion INT

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	--Chequeo validez
	IF(@id IS NULL) OR (@id <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Jugador.'
	END

	--Chequeo existencia
	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM TABLAS.Jugador WHERE IdJugador = @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: IdJugador.'
	END

	--Chequeo relaciones
	IF(@errorCount = 0)
	BEGIN
		IF EXISTS(SELECT 1 FROM TABLAS.Amonestacion WHERE Amonestado = @id)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Existen 1 o mas registros relacionados: Amonestacion. Elimine dichos registros para continuar.'
		END

		IF EXISTS(SELECT 1 FROM TABLAS.Gol WHERE Autor = @id OR Asistencia = @id)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Existen 1 o mas registros relacionados: Gol. Elimine dichos registros para continuar.'
		END

		IF EXISTS(SELECT 1 FROM TABLAS.Sustitucion WHERE Ingreso = @id OR Egreso = @id)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Existen 1 o mas registros relacionados: Sustitucion. Elimine dichos registros para continuar.'
		END

		IF EXISTS(SELECT 1 FROM TABLAS.Cambio_Convocatoria WHERE Ingreso = @id OR Egreso = @id)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Existen 1 o mas registros relacionados: Cambio en Convocatoria. Elimine dichos registros para continuar.'
		END
	END

	--chequeo cupo
	IF(@errorCount = 0)
	BEGIN
		SET @seleccion = (SELECT Seleccion FROM TABLAS.Jugador WHERE IdJugador = @id)
		SET @cantJugadores = (SELECT COUNT(IdJugador) FROM TABLAS.Jugador WHERE Seleccion = @seleccion AND Estado <> 'Inactivo')

		IF( (@cantJugadores - 1) < (SELECT CantJugadoresMin FROM TABLAS.Mundial) )
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Cupo minimo de jugadores no respetado.'
		END
	END

	IF(@errorCount = 0)
	BEGIN
		BEGIN TRANSACTION
		BEGIN TRY
			DELETE FROM TABLAS.Jugador
			WHERE IdJugador = @id

			DELETE FROM TABLAS.Persona
			WHERE IdPersona = @id

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

--Arbitro
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspArbitro_Registrar'))
    DROP PROCEDURE SPTRANS.uspArbitro_Registrar
GO
CREATE PROCEDURE SPTRANS.uspArbitro_Registrar 
@nombre VARCHAR(30),
@fnac DATE,
@pais INT,
@categoria VARCHAR(13)
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine varchar(300)
	DECLARE @id TABLE(ID INT)

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	--Chequeo validez
	IF(@nombre IS NULL)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Nombre.'
	END

	IF(@fnac IS NULL) OR ( @fnac > CONVERT(DATE, GETDATE()) )
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Fecha de Nacimiento.'
	END

	IF(@pais IS NULL) OR (@pais <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Pais.'
	END

	IF(@categoria IS NULL) OR (@categoria NOT IN ('FIFA', 'Confederacion'))
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Categoria.'
	END

	--chequeo existencia
	IF (@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM TABLAS.Pais WHERE IdPais = @pais)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Pais.'
	END

	--chequeo dup
	IF (@errorCount = 0) AND EXISTS(SELECT 1 FROM TABLAS.Persona WHERE Nombre = @nombre)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor duplicado: Nombre.'
	END

	IF(@errorCount = 0)
	BEGIN
		BEGIN TRANSACTION
		BEGIN TRY
			INSERT INTO TABLAS.Persona(Nombre, Fnac, Pais, Rol)
			OUTPUT INSERTED.IdPersona INTO @id(ID)
			VALUES (@nombre, @fnac, @pais, 'Arbitro')

			INSERT INTO TABLAS.Arbitro(IdArbitro, Categoria)
			VALUES((SELECT ID FROM @id), @categoria)

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

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspArbitro_Update'))
    DROP PROCEDURE SPTRANS.uspArbitro_Update
GO
CREATE PROCEDURE SPTRANS.uspArbitro_Update 
@id INT,
@nombre VARCHAR(30) = NULL,
@fnac DATE = NULL,
@pais INT = NULL,
@categoria VARCHAR(13) = NULL
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine varchar(300)

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	--Chequeo validez
	IF(@id IS NULL) OR (@id <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Arbitro.'
	END

	IF(@fnac IS NOT NULL) AND ( @fnac > CONVERT(DATE, GETDATE()) )
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Fecha de Nacimiento.'
	END

	IF(@pais IS NOT NULL) AND (@pais <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Pais.'
	END

	IF(@categoria IS NOT NULL) AND (@categoria NOT IN ('FIFA', 'Confederacion'))
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Categoria.'
	END

	--chequeo existencia
	IF(@errorCount = 0)
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM TABLAS.Arbitro WHERE IdArbitro = @id)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: IdArbitro.'
		END

		IF (@pais IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM TABLAS.Pais WHERE IdPais = @pais)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Pais.'
		END
	END

	--chequeo dup
	IF (@errorCount = 0) AND (@nombre IS NOT NULL) AND EXISTS(SELECT 1 FROM TABLAS.Persona WHERE Nombre = @nombre AND IdPersona <> @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor duplicado: Nombre.'
	END

	IF(@errorCount = 0)
	BEGIN
		BEGIN TRANSACTION
		BEGIN TRY
			UPDATE TABLAS.Persona
			SET
			Nombre = COALESCE(@nombre, Nombre),
			Fnac = COALESCE(@fnac, Fnac),
			Pais = COALESCE(@pais, Pais)
			WHERE IdPersona = @id

			UPDATE TABLAS.Arbitro
			SET
			Categoria = COALESCE(@categoria, Categoria)
			WHERE IdArbitro = @id

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

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspArbitro_Bajar'))
    DROP PROCEDURE SPTRANS.uspArbitro_Bajar
GO
CREATE PROCEDURE SPTRANS.uspArbitro_Bajar
@id INT
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine varchar(300)

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	--Chequeo validez
	IF(@id IS NULL) OR (@id <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: IdArbitro.'
	END

	--Chequeo existencia
	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM TABLAS.Arbitro WHERE IdArbitro = @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: IdArbitro.'
	END

	--Chequeo relaciones
	IF(@errorCount = 0)
	BEGIN
		IF EXISTS(SELECT 1 FROM TABLAS.Reporte WHERE Arbitro = @id)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Existen 1 o mas registros relacionados: Reporte. Elimine dichos registros para continuar.'
		END

		IF EXISTS(SELECT 1 FROM TABLAS.Arbitraje WHERE Arbitro = @id)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Existen 1 o mas registros relacionados: Arbitraje. Elimine dichos registros para continuar.'
		END

		IF EXISTS(SELECT 1 FROM TABLAS.Amonestacion WHERE Arbitro = @id)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Existen 1 o mas registros relacionados: Amonestacion. Elimine dichos registros para continuar.'
		END
	END

	IF(@errorCount = 0)
	BEGIN
		BEGIN TRANSACTION
		BEGIN TRY
			DELETE FROM TABLAS.HablaIdioma
			WHERE Arbitro = @id

			DELETE FROM TABLAS.Arbitro
			WHERE IdArbitro = @id

			DELETE FROM TABLAS.Persona
			WHERE IdPersona = @id

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

--Tecnico
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspTecnico_Registrar'))
    DROP PROCEDURE SPTRANS.uspTecnico_Registrar
GO
CREATE PROCEDURE SPTRANS.uspTecnico_Registrar 
@nombre VARCHAR(30),
@fnac DATE,
@pais INT,
@funcion VARCHAR(40),
@seleccion INT
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine varchar(300)
	DECLARE @id TABLE(ID INT)

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	--Chequeo validez
	IF(@nombre IS NULL)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Nombre.'
	END

	IF(@fnac IS NULL) OR ( @fnac > CONVERT(DATE, GETDATE()) )
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Fecha de Nacimiento.'
	END

	IF(@pais IS NULL) OR (@pais <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Pais.'
	END

	IF(@funcion IS NULL)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Funcion.'
	END

	IF(@seleccion IS NULL) OR (@seleccion <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Seleccion.'
	END

	--chequeo existencia
	IF(@errorCount = 0)
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM TABLAS.Pais WHERE IdPais = @pais)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Pais.'
		END

		IF NOT EXISTS(SELECT 1 FROM TABLAS.Seleccion WHERE IdSeleccion = @seleccion)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Seleccion.'
		END
	END

	--chequeo dup
	IF(@errorCount = 0) AND EXISTS(SELECT 1 FROM TABLAS.Persona WHERE Nombre = @nombre)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor duplicado: Nombre.'
	END

	IF(@errorCount = 0)
	BEGIN
		BEGIN TRANSACTION
		BEGIN TRY
			INSERT INTO TABLAS.Persona(Nombre, Fnac, Pais, Rol)
			OUTPUT INSERTED.IdPersona INTO @id(ID)
			VALUES (@nombre, @fnac, @pais, 'Tecnico')

			INSERT INTO TABLAS.Tecnico(IdTecnico, Funcion, Seleccion, TarjetasAcum)
			VALUES((SELECT ID FROM @id), @funcion, @seleccion, 0)

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
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspTecnico_Update'))
    DROP PROCEDURE SPTRANS.uspTecnico_Update
GO
CREATE PROCEDURE SPTRANS.uspTecnico_Update 
@id INT,
@nombre VARCHAR(30) = NULL,
@fnac DATE = NULL,
@pais INT = NULL,
@funcion VARCHAR(40) = NULL,
@seleccion INT = NULL
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine varchar(300)

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	--Chequeo validez
	IF(@id IS NULL) OR (@id <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Tecnico.'
	END

	IF(@fnac IS NOT NULL) AND ( @fnac > CONVERT(DATE, GETDATE()) )
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Fecha de Nacimiento.'
	END

	IF(@pais IS NOT NULL) AND (@pais <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Pais.'
	END

	IF(@seleccion IS NOT NULL) AND (@seleccion <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Seleccion.'
	END

	--chequeo existencia
	IF(@errorCount = 0)
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM TABLAS.Tecnico WHERE IdTecnico = @id)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: IdTecnico.'
		END

		IF (@pais IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM TABLAS.Pais WHERE IdPais = @pais)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Pais.'
		END

		IF (@seleccion IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM TABLAS.Seleccion WHERE IdSeleccion = @seleccion)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Seleccion.'
		END
	END

	--chequeo dup
	IF(@errorCount = 0) AND (@nombre IS NOT NULL) AND EXISTS(SELECT 1 FROM TABLAS.Persona WHERE Nombre = @nombre AND IdPersona <> @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor duplicado: Nombre.'
	END

	IF(@errorCount = 0)
	BEGIN
		BEGIN TRANSACTION
		BEGIN TRY
			UPDATE TABLAS.Persona
			SET
			Nombre = COALESCE(@nombre, Nombre),
			Fnac = COALESCE(@fnac, Fnac),
			Pais = COALESCE(@pais, Pais)
			WHERE IdPersona = @id

			UPDATE TABLAS.Tecnico
			SET
			Funcion = COALESCE(@funcion, Funcion),
			Seleccion = COALESCE(@seleccion, Seleccion)
			WHERE IdTecnico = @id

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

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspTecnico_Bajar'))
    DROP PROCEDURE SPTRANS.uspTecnico_Bajar
GO
CREATE PROCEDURE SPTRANS.uspTecnico_Bajar
@id INT
AS
BEGIN
	DECLARE @errorCount INT

	SET @errorCount = 0

	--Chequeo validez
	IF(@id IS NULL) OR (@id <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT 'ERROR: IdTecnico invalido.'
	END

	--Chequeo existencia
	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM TABLAS.Tecnico WHERE IdTecnico = @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT 'ERROR: IdTecnico inexistente.'
	END

	--Chequeo relaciones
	IF(@errorCount = 0) AND EXISTS(SELECT 1 FROM TABLAS.Amonestacion WHERE Amonestado = @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT 'ERROR: Existen 1 o mas registros relacionados: Amonestacion. Elimine dichos registros para continuar.'
	END

	IF(@errorCount = 0)
	BEGIN
		BEGIN TRANSACTION
		BEGIN TRY
			DELETE FROM TABLAS.Tecnico
			WHERE IdTecnico = @id

			DELETE FROM TABLAS.Persona
			WHERE IdPersona = @id

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
END;
GO

--Testing Carga Exitosa de Tablas en prueba
--Tecnico
EXECUTE SPTRANS.uspTecnico_Registrar 
@nombre = 'Pablo Hernandez', @fnac = '2015-04-15', @pais = 1, 
@funcion = 'Ayudante Tactico', @seleccion = 1

EXECUTE SPTRANS.uspTecnico_Registrar 
@nombre = 'Juan Hernandez', @fnac = '2015-04-20', @pais = 1, 
@funcion = '2do Ayudante', @seleccion = 2;
--Arbitro
EXECUTE SPTRANS.uspArbitro_Registrar 
@nombre = 'Juliani Dario',
@fnac = '2025-03-12',
@pais = 1,
@categoria = 'FIFA'

EXECUTE SPTRANS.uspArbitro_Registrar 
@nombre = 'Juliani Mario',
@fnac = '2025-03-12',
@pais = 1,
@categoria = 'FIFA'
--Jugador
EXECUTE SPTRANS.uspJugador_Registrar 
@nombre = 'Cristiano Ronaldo',
@fnac = '2024-05-12',
@pais = 1,
@posicion = 'Delantero',
@numero = 10,
@club = 1,
@seleccion = 1

EXECUTE SPTRANS.uspJugador_Registrar 
@nombre = 'Zinadine Zidane',
@fnac = '2024-05-12',
@pais = 1,
@posicion = 'Delantero',
@numero = 9,
@club = 2,
@seleccion = 1

EXECUTE SPTRANS.uspJugador_Registrar 
@nombre = 'Neymar',
@fnac = '2024-05-12',
@pais = 1,
@posicion = 'Delantero',
@numero = 5,
@club = NULL,
@seleccion = 1

SELECT * FROM TABLAS.Persona WHERE Rol = 'Arbitro'
SELECT * FROM TABLAS.Persona WHERE Rol = 'Tecnico'
SELECT * FROM TABLAS.Persona WHERE Rol = 'Jugador'
SELECT * FROM TABLAS.Tecnico
SELECT * FROM TABLAS.Arbitro
SELECT * FROM TABLAS.Jugador

--////testing Tecnico
--/Registro
--Fallido(Valores invalidos)
EXECUTE SPTRANS.uspTecnico_Registrar 
@nombre = NULL, @fnac = '2030-04-15', @pais = -1, 
@funcion = NULL, @seleccion = 0

SELECT * FROM TABLAS.Persona WHERE Rol = 'Tecnico'
SELECT * FROM TABLAS.Tecnico
--Fallido(Valores inexistentes)
EXECUTE SPTRANS.uspTecnico_Registrar 
@nombre = 'Pablo Hernandez', @fnac = '2015-04-15', @pais = 40, 
@funcion = 'Ayudante Tactico', @seleccion = 20

SELECT * FROM TABLAS.Persona WHERE Rol = 'Tecnico'
SELECT * FROM TABLAS.Tecnico
--Fallido(Valores duplicados)
EXECUTE SPTRANS.uspTecnico_Registrar 
@nombre = 'Pablo Hernandez', @fnac = '2015-04-15', @pais = 1, 
@funcion = 'Ayudante Estrategico', @seleccion = 1

SELECT * FROM TABLAS.Persona WHERE Rol = 'Tecnico'
SELECT * FROM TABLAS.Tecnico

--/Update
--Exitoso
EXECUTE SPTRANS.uspTecnico_Update 
@id = 1,
@nombre = 'Pavlo Ernandez', @fnac = '2015-04-25', @pais = 2, 
@funcion = 'Ayudante Estrategico', @seleccion = 1

SELECT * FROM TABLAS.Persona WHERE Rol = 'Tecnico'
SELECT * FROM TABLAS.Tecnico
--Fallido(Valores invalidos)
EXECUTE SPTRANS.uspTecnico_Update 
@id = 0, @fnac = '2030-04-25', @pais = -2, @seleccion = -1

SELECT * FROM TABLAS.Persona WHERE Rol = 'Tecnico'
SELECT * FROM TABLAS.Tecnico
--Fallido(Valores inexistentes)
EXECUTE SPTRANS.uspTecnico_Update 
@id = 45, @fnac = '2024-04-25', @pais = 24, @seleccion = 30

SELECT * FROM TABLAS.Persona WHERE Rol = 'Tecnico'
SELECT * FROM TABLAS.Tecnico
--Fallido(Valores duplicados)
EXECUTE SPTRANS.uspTecnico_Update 
@id = 1, @nombre = 'Juan Hernandez';

SELECT * FROM TABLAS.Persona WHERE Rol = 'Tecnico'
SELECT * FROM TABLAS.Tecnico

--/Baja
--Exitoso
EXECUTE SPTRANS.uspTecnico_Bajar @id = 1;

SELECT * FROM TABLAS.Persona WHERE Rol = 'Tecnico'
SELECT * FROM TABLAS.Tecnico
--Fallido(Valores invalidos)
EXECUTE SPTRANS.uspTecnico_Bajar @id = -1;

SELECT * FROM TABLAS.Persona WHERE Rol = 'Tecnico'
SELECT * FROM TABLAS.Tecnico
--Fallido(Valores inexistentes)
EXECUTE SPTRANS.uspTecnico_Bajar @id = 40;

SELECT * FROM TABLAS.Persona WHERE Rol = 'Tecnico'
SELECT * FROM TABLAS.Tecnico
--Fallido(Registros referenciados)
EXECUTE SPTRANS.uspTecnico_Bajar @id = 2;

SELECT * FROM TABLAS.Persona WHERE Rol = 'Tecnico'
SELECT * FROM TABLAS.Tecnico
---------------------------------------------------------------------
--////testing Arbitro
--/Registro
--Fallido(Valores invalidos)
EXECUTE SPTRANS.uspArbitro_Registrar 
@nombre = NULL,
@fnac = '2030-03-12',
@pais = -1,
@categoria = 'NBA'

SELECT * FROM TABLAS.Persona WHERE Rol = 'Arbitro'
SELECT * FROM TABLAS.Arbitro
--Fallido(Valores inexistentes)
EXECUTE SPTRANS.uspArbitro_Registrar 
@nombre = 'Panini Juliano',
@fnac = '2025-03-12',
@pais = 45,
@categoria = 'FIFA'

SELECT * FROM TABLAS.Persona WHERE Rol = 'Arbitro'
SELECT * FROM TABLAS.Arbitro
--Fallido(Valores duplicados)
EXECUTE SPTRANS.uspArbitro_Registrar 
@nombre = 'Juliani Dario',
@fnac = '2025-03-12',
@pais = 2,
@categoria = 'FIFA'

SELECT * FROM TABLAS.Persona WHERE Rol = 'Arbitro'
SELECT * FROM TABLAS.Arbitro

--/Update
--Exitoso
EXECUTE SPTRANS.uspArbitro_Update 
@id = 3,
@nombre = 'Panini Dario',
@fnac = '2012-05-14',
@pais = 2,
@categoria = 'Confederacion'

SELECT * FROM TABLAS.Persona WHERE Rol = 'Arbitro'
SELECT * FROM TABLAS.Arbitro
--Fallido(Valores invalidos)
EXECUTE SPTRANS.uspArbitro_Update 
@id = 0,
@fnac = '2045-05-14',
@pais = -2,
@categoria = 'NBA'

SELECT * FROM TABLAS.Persona WHERE Rol = 'Arbitro'
SELECT * FROM TABLAS.Arbitro
--Fallido(Valores inexistentes)
EXECUTE SPTRANS.uspArbitro_Update 
@id = 100,
@nombre = 'Panini Dario',
@fnac = '2012-05-14',
@pais = 60,
@categoria = 'Confederacion'

SELECT * FROM TABLAS.Persona WHERE Rol = 'Arbitro'
SELECT * FROM TABLAS.Arbitro
--Fallido(Valores duplicados)
EXECUTE SPTRANS.uspArbitro_Update 
@id = 3,
@nombre = 'Juan Hernandez',
@fnac = '2012-05-14',
@pais = 1,
@categoria = 'Confederacion'

SELECT * FROM TABLAS.Persona WHERE Rol = 'Arbitro'
SELECT * FROM TABLAS.Arbitro
--/Baja
--Exitoso
EXECUTE SPTRANS.uspArbitro_Bajar @id = 3

SELECT * FROM TABLAS.Persona WHERE Rol = 'Arbitro'
SELECT * FROM TABLAS.Arbitro
--Fallido(Valores invalidos)
EXECUTE SPTRANS.uspArbitro_Bajar @id = -3

SELECT * FROM TABLAS.Persona WHERE Rol = 'Arbitro'
SELECT * FROM TABLAS.Arbitro
--Fallido(Valores inexistentes)
EXECUTE SPTRANS.uspArbitro_Bajar @id = 40

SELECT * FROM TABLAS.Persona WHERE Rol = 'Arbitro'
SELECT * FROM TABLAS.Arbitro
--Fallido(Valores referenciados)
EXECUTE SPTRANS.uspArbitro_Bajar @id = 4

SELECT * FROM TABLAS.Persona WHERE Rol = 'Arbitro'
SELECT * FROM TABLAS.Arbitro
---------------------------------------------------------------------
--////testing Jugador
--/Registro
--Fallido(Valores invalidos)
EXECUTE SPTRANS.uspJugador_Registrar 
@nombre = NULL,
@fnac = '2030-05-12',
@pais = -1,
@posicion = NULL,
@numero = NULL,
@club = -4,
@seleccion = -1

SELECT * FROM TABLAS.Persona WHERE Rol = 'Jugador'
SELECT * FROM TABLAS.Jugador
--Fallido(Valores inexistentes)
EXECUTE SPTRANS.uspJugador_Registrar 
@nombre = 'Neymar',
@fnac = '2024-05-12',
@pais = 100,
@posicion = 'Delantero',
@numero = 5,
@club = NULL,
@seleccion = 200

SELECT * FROM TABLAS.Persona WHERE Rol = 'Jugador'
SELECT * FROM TABLAS.Jugador
--Fallido(Valores Duplicados)
EXECUTE SPTRANS.uspJugador_Registrar 
@nombre = 'Neymar',
@fnac = '2024-05-12',
@pais = 1,
@posicion = 'Delantero',
@numero = 5,
@club = NULL,
@seleccion = 2

SELECT * FROM TABLAS.Persona WHERE Rol = 'Jugador'
SELECT * FROM TABLAS.Jugador
--Fallido(Exceso cupo maximo)
EXECUTE SPTRANS.uspJugador_Registrar 
@nombre = 'Manu Ginobilli',
@fnac = '2024-05-12',
@pais = 1,
@posicion = 'Arquero',
@numero = 1,
@club = 2,
@seleccion = 1

SELECT * FROM TABLAS.Persona WHERE Rol = 'Jugador'
SELECT * FROM TABLAS.Jugador
--/UpdateClub
--Exitoso
EXECUTE SP.uspJugador_ClubUpdate
@id = 7,
@club = 2;

SELECT * FROM TABLAS.Persona WHERE Rol = 'Jugador'
SELECT * FROM TABLAS.Jugador
--Fallido(Valores invalidos)
EXECUTE SP.uspJugador_ClubUpdate
@id = 7,
@club = -2;

SELECT * FROM TABLAS.Persona WHERE Rol = 'Jugador'
SELECT * FROM TABLAS.Jugador
--Fallido(Valores inexistentes)
EXECUTE SP.uspJugador_ClubUpdate
@id = 43,
@club = 22;

SELECT * FROM TABLAS.Persona WHERE Rol = 'Jugador'
SELECT * FROM TABLAS.Jugador
--/UpdateGeneral
--Exitoso
EXECUTE SPTRANS.uspJugador_Update 
@id = 5,
@nombre = 'Cristiano',
@fnac = '2020-10-10',
@pais = 2,
@posicion = 'Arquero',
@numero = 1,
@seleccion = 1;

SELECT * FROM TABLAS.Persona WHERE Rol = 'Jugador'
SELECT * FROM TABLAS.Jugador
--Fallido(Valores invalidos)
EXECUTE SPTRANS.uspJugador_Update 
@id = 0,
@fnac = '2040-10-10',
@pais = -2,
@numero = -10,
@seleccion = -1;

SELECT * FROM TABLAS.Persona WHERE Rol = 'Jugador'
SELECT * FROM TABLAS.Jugador
--Fallido(Valores inexistentes)
EXECUTE SPTRANS.uspJugador_Update 
@id = 50,
@pais = 22,
@seleccion = 100;

SELECT * FROM TABLAS.Persona WHERE Rol = 'Jugador'
SELECT * FROM TABLAS.Jugador
--/Baja
--Exitoso
EXECUTE SPTRANS.uspJugador_Bajar @id = 5

SELECT * FROM TABLAS.Persona WHERE Rol = 'Jugador'
SELECT * FROM TABLAS.Jugador
--Fallido(Valores invalidos)
EXECUTE SPTRANS.uspJugador_Bajar @id = -5

SELECT * FROM TABLAS.Persona WHERE Rol = 'Jugador'
SELECT * FROM TABLAS.Jugador
--Fallido(Valores inexistentes)
EXECUTE SPTRANS.uspJugador_Bajar @id = 10

SELECT * FROM TABLAS.Persona WHERE Rol = 'Jugador'
SELECT * FROM TABLAS.Jugador
--Fallido(Registros referenciados)
EXECUTE SPTRANS.uspJugador_Bajar @id = 6
EXECUTE SPTRANS.uspJugador_Bajar @id = 7

SELECT * FROM TABLAS.Persona WHERE Rol = 'Jugador'
SELECT * FROM TABLAS.Jugador

--drop
DROP TABLE TABLAS.Gol
DROP TABLE TABLAS.Cambio_Convocatoria
DROP TABLE TABLAS.Sustitucion
DROP TABLE TABLAS.Amonestacion
DROP TABLE TABLAS.Arbitraje
DROP TABLE TABLAS.HablaIdioma
DROP TABLE TABLAS.Reporte
DROP TABLE TABLAS.Mundial
GO

DROP TABLE TABLAS.Jugador
DROP TABLE TABLAS.Arbitro
DROP TABLE TABLAS.Tecnico
DROP TABLE TABLAS.Persona
GO

DROP TABLE TABLAS.Pais;
DROP TABLE TABLAS.Seleccion;
DROP TABLE TABLAS.Club;
GO

--Limpieza de los procedimientos creados por este script.
DROP PROCEDURE SPTRANS.uspArbitro_Registrar
DROP PROCEDURE SPTRANS.uspArbitro_Update
DROP PROCEDURE SPTRANS.uspArbitro_Bajar
DROP PROCEDURE SPTRANS.uspTecnico_Registrar
DROP PROCEDURE SPTRANS.uspTecnico_Update
DROP PROCEDURE SPTRANS.uspTecnico_Bajar
DROP PROCEDURE SPTRANS.uspJugador_Registrar
DROP PROCEDURE SPTRANS.uspJugador_Update
DROP PROCEDURE SPTRANS.uspJugador_Bajar
DROP PROCEDURE SP.uspJugador_ClubUpdate
GO