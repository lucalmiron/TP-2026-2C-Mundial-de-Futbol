--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: xx/xx/2026

--Testing de SP de asignacion de publicidad a partido

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIALtesting')
BEGIN
	USE MUNDIALtesting
END;
GO

--schemas para testing
CREATE SCHEMA arbitros;
GO
CREATE SCHEMA equipos;
GO
CREATE SCHEMA publicidad;
GO
CREATE SCHEMA sedes;
GO
CREATE SCHEMA partidos;
GO

--tablas auxiliares de testing
CREATE TABLE sedes.HusoHorario
(
	IdHuso INT PRIMARY KEY,
	Nombre VARCHAR(50)
);
CREATE TABLE arbitros.Idioma
(
	IdIdioma INT PRIMARY KEY
);
CREATE TABLE equipos.Pais
(
	IdPais INT PRIMARY KEY,
	Idioma INT,
	HusoHorario INT,
	PtIni TIME,
	PtFin TIME,
	FOREIGN KEY(Idioma) REFERENCES arbitros.Idioma(IdIdioma),
	FOREIGN KEY(HusoHorario) REFERENCES sedes.HusoHorario(IdHuso)
);
CREATE TABLE equipos.Seleccion
(
	IdSeleccion INT PRIMARY KEY,
	IdPais INT,
	FOREIGN KEY(IdPais) REFERENCES equipos.Pais(IdPais)
);
CREATE TABLE publicidad.Publicidad
(
	IdPublicidad INT PRIMARY KEY,
	IdIdioma INT,
	FOREIGN KEY(IdIdioma) REFERENCES arbitros.Idioma(IdIdioma)
);
CREATE TABLE publicidad.PublicidadPais
(
	IdPublicidad INT NOT NULL,
	IdPais INT NOT NULL,
	PRIMARY KEY(IdPublicidad, IdPais),
	FOREIGN KEY(IdPublicidad) REFERENCES publicidad.Publicidad(IdPublicidad),
	FOREIGN KEY(IdPais) REFERENCES equipos.Pais(IdPais)
);
CREATE TABLE sedes.Sede
(
	IdSede INT PRIMARY KEY,
	IdPais INT NOT NULL,
	FOREIGN KEY(IdPais) REFERENCES equipos.Pais(IdPais)
);
CREATE TABLE partidos.Partido
(
	IdPartido INT PRIMARY KEY,
	Eq1 INT,
	Eq2 INT,
	IdSede INT,
	Hora TIME,
	Fecha DATE,
	FOREIGN KEY(IdSede) REFERENCES sedes.Sede(IdSede),
	FOREIGN KEY(Eq1) REFERENCES equipos.Seleccion(IdSeleccion),
	FOREIGN KEY(Eq2) REFERENCES equipos.Seleccion(IdSeleccion)
);
CREATE TABLE publicidad.EspacioPublicitario
(
	IdEP INT PRIMARY KEY,
	IdSede INT,
	Costo DECIMAL(10,2)
	FOREIGN KEY(IdSede) REFERENCES sedes.Sede(IdSede)
);
CREATE TABLE publicidad.CostoFranja
(
	IdCF INT PRIMARY KEY,
	IdSede INT,
    TipoFranja VARCHAR(30),
	Costo DECIMAL(10,2),
	FOREIGN KEY(IdSede) REFERENCES sedes.Sede(IdSede)
);
CREATE TABLE publicidad.HistorialPublicidad
(
	IdHistorial INT PRIMARY KEY IDENTITY(1, 1),
	IdPublicidad INT,
	IdPartido INT,
	IdEP INT,
	CostoFinal DECIMAL(10,2),
	FOREIGN KEY(IdPublicidad) REFERENCES publicidad.Publicidad(IdPublicidad),
	FOREIGN KEY(IdPartido) REFERENCES partidos.Partido(IdPartido),
	FOREIGN KEY(IdEP) REFERENCES publicidad.EspacioPublicitario
)
GO

--llenado tablas
INSERT INTO sedes.HusoHorario(IdHuso, Nombre) VALUES (1, 'America/New_York'), (2, 'Europe/London');
INSERT INTO arbitros.Idioma(IdIdioma) VALUES (1), (2), (3);
INSERT INTO equipos.Pais(IdPais, Idioma, HusoHorario, PtIni, PtFin) 
VALUES 
(1, 2, 1, '22:00', '23:00'), 
(2, 1, 2, '20:00', '22:00'), 
(3, 2, 1, '20:00', '22:00'), 
(4, 3, 2, '19:30', '21:00'), 
(5, 1, 2, '21:30', '23:00');
INSERT INTO publicidad.Publicidad(IdPublicidad, IdIdioma) VALUES (1, 1), (2, 1), (3, 1), (4, 2), (5, 1), (6, 1);
INSERT INTO publicidad.PublicidadPais(IdPublicidad, IdPais) VALUES (1, 2), (2, 3), (3, 5), (4, 1), (5, 5), (6, 4);
INSERT INTO sedes.Sede(IdSede, IdPais) VALUES (1, 2);
INSERT INTO equipos.Seleccion(IdSeleccion, IdPais) VALUES (3, 3), (4, 4);
INSERT INTO partidos.Partido(IdPartido, Eq1, Eq2, IdSede, Hora, Fecha) VALUES (1, 3, 4, 1, '21:30', '2026-12-12');
INSERT INTO publicidad.EspacioPublicitario(IdEP, IdSede, Costo) VALUES (10, 1, 20), (11, 1, 10), (23, 1, 40), (45, 1, 20);
INSERT INTO publicidad.CostoFranja(IdCF, IdSede, TipoFranja, Costo) 
VALUES 
(1, 1, 'Normal', 100),
(2, 1, 'Primetime', 200);
GO

/*
--Activo opciones para habilitar el uso de APIs
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'Ole Automation Procedures', 1;
RECONFIGURE;
GO
*/

--SP API
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspAPIconversionHora'))
    DROP PROCEDURE SP.uspAPIconversionHora
GO
CREATE PROCEDURE SP.uspAPIconversionHora
@fecha DATE,
@hora TIME,
@timezone VARCHAR(100),
@horaConv TIME OUTPUT
AS
BEGIN
	DECLARE @Object AS INT;
	DECLARE @ResponseText AS VARCHAR(8000);

	DECLARE @Body AS VARCHAR(8000);
	SET @Body =
	'{
		 "dateTime":' + ' "' + CONVERT(CHAR(10), @fecha) + 'T' + CONVERT(VARCHAR(100), @hora) + '",' + CHAR(13) + 
		 '"fromTimezone": "UTC",
		 "toTimezone": "' + @timezone + '"' + CHAR(13) +
	'}';

	EXEC sp_OACreate 'MSXML2.ServerXMLHTTP', @Object OUT;
	EXEC sp_OAMethod @Object, 'open', NULL, 'post','https://api.opentimezone.com/convert', 'false'

	EXEC sp_OAMethod @Object, 'setRequestHeader', null, 'Content-Type', 'application/json'
	EXEC sp_OAMethod @Object, 'send', null, @body

	EXEC sp_OAMethod @Object, 'responseText', @ResponseText OUTPUT

	SELECT @horaConv = CONVERT(TIME, (SELECT * FROM OPENJSON(@ResponseText) WITH (horaFecha DATETIME2 '$."dateTime"')))

	EXEC sp_OADestroy @Object
END;
GO

--SP a testear
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
-----------------------------------------------
--test
EXECUTE SPTRANS.uspPublicidad_Asignar @partido = 1;

SELECT * FROM publicidad.HistorialPublicidad
GO
-----------------------------------------------
----borrado
--SPs
DROP PROCEDURE SP.uspAPIconversionHora;
DROP PROCEDURE SPTRANS.uspPublicidad_Asignar;
GO

--tablas
DROP TABLE publicidad.HistorialPublicidad;
DROP TABLE publicidad.EspacioPublicitario;
DROP TABLE publicidad.CostoFranja;
DROP TABLE partidos.Partido;
DROP TABLE equipos.Seleccion;
DROP TABLE publicidad.PublicidadPais;
DROP TABLE publicidad.Publicidad;
DROP TABLE sedes.Sede;
DROP TABLE equipos.Pais;
DROP TABLE arbitros.Idioma;
DROP TABLE sedes.HusoHorario;
GO
--SCHEMAS
DROP SCHEMA arbitros;
DROP SCHEMA equipos;
DROP SCHEMA publicidad;
DROP SCHEMA sedes;
DROP SCHEMA partidos;
GO

/*
--Desactivo opciones para habilitar el uso de APIs
EXEC sp_configure 'Ole Automation Procedures', 0;
RECONFIGURE;
EXEC sp_configure 'show advanced options', 0;
RECONFIGURE;
GO
*/