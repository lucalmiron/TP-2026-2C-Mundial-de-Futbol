--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 08/10/2026

--Testing de StoredProcedures asociados a entidades Idioma, HablaIdioma y Reporte
--HablaIdioma surge de la relacion Arbitro-n---<Habla>---n-Idioma

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIALtesting')
BEGIN
	USE MUNDIALtesting
END;
GO

--Tablas auxiliares de testing
CREATE TABLE arbitros.Arbitro
(
	IdArbitro INT PRIMARY KEY
);

CREATE TABLE partidos.Partido
(
	IdPartido INT PRIMARY KEY
);
GO

--Tablas a testear
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'TABLAS' AND TABLE_NAME = 'Idioma')
BEGIN
	CREATE TABLE arbitros.Idioma
	(
		IdIdioma INT PRIMARY KEY IDENTITY(1, 1),
		Descripcion VARCHAR(20)
	)
END;
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'TABLAS' AND TABLE_NAME = 'HablaIdioma')
BEGIN
	CREATE TABLE arbitros.HablaIdioma
	(
		Arbitro INT,
		Idioma INT,
		FOREIGN KEY(Arbitro) REFERENCES arbitros.Arbitro(IdArbitro),
		FOREIGN KEY(Idioma) REFERENCES arbitros.Idioma(IdIdioma)
	)
END;
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'TABLAS' AND TABLE_NAME = 'Reporte')
BEGIN
	CREATE TABLE arbitros.Reporte
	(
		IdReporte INT PRIMARY KEY IDENTITY(1, 1),
		Razon VARCHAR(20),
		Descripcion VARCHAR(300),
		Arbitro INT,
		Partido INT,
		FOREIGN KEY(Arbitro) REFERENCES arbitros.Arbitro(IdArbitro),
		FOREIGN KEY(Partido) REFERENCES partidos.Partido(IdPartido)
	)
END;
GO

--tablas aux
CREATE TABLE publicidad.Publicidad
(
	Idioma INT,
	FOREIGN KEY(Idioma) REFERENCES arbitros.Idioma(IdIdioma)
);
GO

--SPs a testear
--Idioma
IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspIdioma_Registrar'))
    DROP PROCEDURE SP.uspIdioma_Registrar
GO
CREATE PROCEDURE SP.uspIdioma_Registrar @descripcion VARCHAR(20)
AS
BEGIN
	DECLARE @errorCount INT

	SET @errorCount = 0

	IF(@descripcion IS NULL)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Descripcion invalida.'
	END

	IF(@errorCount = 0) AND EXISTS(SELECT 1 FROM arbitros.Idioma WHERE Descripcion = @descripcion)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Descripcion duplicada.'
	END

	IF(@errorCount = 0)
		INSERT INTO arbitros.Idioma(Descripcion) VALUES (@descripcion)
END;
GO

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspIdioma_Update'))
    DROP PROCEDURE SP.uspIdioma_Update
GO
CREATE PROCEDURE SP.uspIdioma_Update @id INT, @descripcion VARCHAR(20)
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine varchar(300)

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	IF(@id IS NULL) OR (@id <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: ID Idioma.'
	END

	IF(@descripcion IS NULL)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Descripcion.'
	END

	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM arbitros.Idioma WHERE IdIdioma = @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: ID Idioma.'
	END

	IF(@errorCount = 0) AND EXISTS(SELECT 1 FROM arbitros.Idioma WHERE Descripcion = @descripcion AND IdIdioma <> @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor duplicado: Descripcion.'
	END

	IF(@errorCount = 0)
	BEGIN
		UPDATE arbitros.Idioma
		SET Descripcion = @descripcion
		WHERE IdIdioma = @id
	END
	ELSE
		PRINT @errorLine
END;
GO

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspIdioma_Bajar'))
    DROP PROCEDURE SP.uspIdioma_Bajar
GO
CREATE PROCEDURE SP.uspIdioma_Bajar @id INT
AS
BEGIN
	DECLARE @errorCount INT

	SET @errorCount = 0

	IF(@id IS NULL) OR (@id <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Valor invalido: ID Idioma.'
	END

	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM arbitros.Idioma WHERE IdIdioma = @id)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Valor inexistente: ID Idioma.'
	END

	IF(@errorCount = 0)
	BEGIN
		IF EXISTS(SELECT 1 FROM arbitros.HablaIdioma WHERE Idioma = @id)
		BEGIN
			SET @errorCount = @errorCount + 1
			PRINT '-ERROR- Existen 1 o mas registros relacionados: HablaIdioma. Elimine dichos registros para continuar.'
		END

		IF EXISTS(SELECT 1 FROM publicidad.Publicidad WHERE Idioma = @id)
		BEGIN
			SET @errorCount = @errorCount + 1
			PRINT '-ERROR- Existen 1 o mas registros relacionados: Publicidad. Elimine dichos registros para continuar.'
		END
	END

	IF(@errorCount = 0)
		DELETE FROM arbitros.Idioma WHERE IdIdioma = @id
END;
GO

--HablaIdioma
IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspHablaIdioma_Registrar'))
    DROP PROCEDURE SP.uspHablaIdioma_Registrar
GO
CREATE PROCEDURE SP.uspHablaIdioma_Registrar @arbitro INT, @idioma INT
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine varchar(300)

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	IF(@arbitro IS NULL) OR (@arbitro <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Arbitro.'
	END

	IF(@idioma IS NULL) OR (@idioma <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Idioma.'
	END

	IF(@errorCount = 0)
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM arbitros.Arbitro WHERE IdArbitro = @arbitro)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Arbitro.'
		END

		IF NOT EXISTS(SELECT 1 FROM arbitros.Idioma WHERE IdIdioma = @idioma)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Idioma.'
		END
	END

	IF(@errorCount = 0) AND EXISTS(SELECT 1 FROM arbitros.HablaIdioma WHERE Arbitro = @arbitro AND Idioma = @idioma)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor duplicado: Idioma.'
	END

	IF(@errorCount = 0)
		INSERT INTO arbitros.HablaIdioma VALUES (@arbitro, @idioma)
	ELSE
		PRINT @errorLine
END;
GO

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspHablaIdioma_Bajar'))
    DROP PROCEDURE SP.uspHablaIdioma_Bajar
GO
CREATE PROCEDURE SP.uspHablaIdioma_Bajar @arbitro INT, @idioma INT
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine varchar(300)

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	IF(@arbitro IS NULL) OR (@arbitro <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Arbitro.'
	END

	IF(@idioma IS NULL) OR (@idioma <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Idioma.'
	END

	IF(@errorCount = 0)
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM arbitros.Arbitro WHERE IdArbitro = @arbitro)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Arbitro.'
		END

		IF NOT EXISTS(SELECT 1 FROM arbitros.Idioma WHERE IdIdioma = @idioma)
		BEGIN
			SET @errorCount = @errorCount + 1
			SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Idioma.'
		END
	END

	IF(@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM arbitros.HablaIdioma WHERE Arbitro = @arbitro AND Idioma = @idioma)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Registro inexistente.'
	END

	IF(@errorCount = 0)
		DELETE FROM arbitros.HablaIdioma WHERE Arbitro = @arbitro AND Idioma = @idioma
	ELSE
		PRINT @errorLine
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

--Llenado de tablas aux
INSERT INTO arbitros.Arbitro VALUES (1), (2), (3);
INSERT INTO partidos.Partido VALUES (1), (2), (3);
INSERT INTO publicidad.Publicidad VALUES (1), (2);
GO

SELECT * FROM arbitros.Arbitro;
SELECT * FROM partidos.Partido;
GO
--Llenado de tablas y testeo de registro exitoso
EXECUTE SP.uspIdioma_Registrar @descripcion = 'Polaco';
EXECUTE SP.uspIdioma_Registrar @descripcion = 'Chino';

EXECUTE SP.uspHablaIdioma_Registrar @arbitro = 1, @idioma = 2;
EXECUTE SP.uspHablaIdioma_Registrar @arbitro = 2, @idioma = 2;

EXECUTE SP.uspReporte_Registrar 
@razon = 'Informe PostPartido', 
@descripcion = 'Salio lesionado en el 2do tiempo.',
@arbitro = 2, @partido = 1;
EXECUTE SP.uspReporte_Registrar 
@razon = 'Sancion', 
@descripcion = 'Intencionalmente golpeo a un jugador.',
@arbitro = 2, @partido = 2;
EXECUTE SP.uspReporte_Registrar 
@razon = 'Informe PostPartido', 
@descripcion = 'Intencionalmente golpeo a un jugador.',
@arbitro = 2, @partido = 1;
GO

SELECT * FROM arbitros.Idioma;
SELECT * FROM arbitros.HablaIdioma;
SELECT * FROM arbitros.Reporte;
GO

--//Testing Idioma
--/Registro
--Fallido(Valores invalidos)
EXECUTE SP.uspIdioma_Registrar @descripcion = NULL;

SELECT * FROM arbitros.Idioma;
GO
--Fallido(Valores dup)
EXECUTE SP.uspIdioma_Registrar @descripcion = 'Polaco';

SELECT * FROM arbitros.Idioma;
GO
--/Update
--Exitoso
EXECUTE SP.uspIdioma_Update @id = 2, @descripcion = 'Chino Mandarin';

SELECT * FROM arbitros.Idioma;
GO
--Fallido(Valores invalidos)
EXECUTE SP.uspIdioma_Update @id = 0, @descripcion = NULL;

SELECT * FROM arbitros.Idioma;
GO
--Fallido(Valores inexistentes)
EXECUTE SP.uspIdioma_Update @id = 40, @descripcion = 'Polaco-Ruso';

SELECT * FROM arbitros.Idioma;
GO
--Fallido(Valores dup)
EXECUTE SP.uspIdioma_Update @id = 2, @descripcion = 'Polaco';

SELECT * FROM arbitros.Idioma;
GO
--/Baja
--Exitoso
EXECUTE SP.uspIdioma_Bajar @id = 1;

SELECT * FROM arbitros.Idioma;
GO
--Fallido(Valores invalidos)
EXECUTE SP.uspIdioma_Bajar @id = 0;

SELECT * FROM arbitros.Idioma;
GO
--Fallido(Valores inexistentes)
EXECUTE SP.uspIdioma_Bajar @id = 45;

SELECT * FROM arbitros.Idioma;
GO
--Fallido(Registros referenciados)
EXECUTE SP.uspIdioma_Bajar @id = 2;

SELECT * FROM arbitros.Idioma;
GO
---------------------------------------------------------------------
--//Testing HablaIdioma
--/Registro
--Fallida(Valores invalidos)
EXECUTE SP.uspHablaIdioma_Registrar @arbitro = 0, @idioma = NULL;

SELECT * FROM arbitros.HablaIdioma;
GO
--Fallida(Valores inexistentes)
EXECUTE SP.uspHablaIdioma_Registrar @arbitro = 45, @idioma = 78;

SELECT * FROM arbitros.HablaIdioma;
GO
--Fallida(Valores dup)
EXECUTE SP.uspHablaIdioma_Registrar @arbitro = 1, @idioma = 2;

SELECT * FROM arbitros.HablaIdioma;
GO
--/Baja
--Exitosa
EXECUTE SP.uspHablaIdioma_Bajar @arbitro = 1, @idioma = 2;

SELECT * FROM arbitros.HablaIdioma;
GO
--Fallida(Valores invalidos)
EXECUTE SP.uspHablaIdioma_Bajar @arbitro = NULL, @idioma = 0;

SELECT * FROM arbitros.HablaIdioma;
GO
--Fallida(Valores inexistentes)
EXECUTE SP.uspHablaIdioma_Bajar @arbitro = 1, @idioma = 2;

SELECT * FROM arbitros.HablaIdioma;
GO
---------------------------------------------------------------------
--//Testing Reporte
--/Registro
--Fallida(Valores invalidos)
EXECUTE SP.uspReporte_Registrar 
@razon = 'Broma', 
@descripcion = NULL,
@arbitro = NULL, 
@partido = -1;

SELECT * FROM arbitros.Reporte;
GO
--Fallida(Valores inexistentes)
EXECUTE SP.uspReporte_Registrar 
@razon = 'Sancion', 
@descripcion = 'Se peleo con otro arbitro.',
@arbitro = 45, 
@partido = 123;

SELECT * FROM arbitros.Reporte;
GO
--Fallida(Valores dup)
EXECUTE SP.uspReporte_Registrar 
@razon = 'Informe PostPartido', 
@descripcion = 'Salio lesionado en el 2do tiempo.',
@arbitro = 2, 
@partido = 1;

SELECT * FROM arbitros.Reporte;
GO
--/Update
--Exitoso
EXECUTE SP.uspReporte_Update
@id = 1,
@descripcion = 'Faltas mal cobradas';

SELECT * FROM arbitros.Reporte;
GO
--Fallido(Valores invalidos)
EXECUTE SP.uspReporte_Update
@id = 1,
@razon = 'Ataque';

SELECT * FROM arbitros.Reporte;
GO
--Fallido(Valores inexistentes)
EXECUTE SP.uspReporte_Update
@id = 145;

SELECT * FROM arbitros.Reporte;
GO
--Fallido(Valores dup)
EXECUTE SP.uspReporte_Update
@id = 1,
@razon = 'Sancion', 
@descripcion = 'Intencionalmente golpeo a un jugador.';

SELECT * FROM arbitros.Reporte;
GO
--/Baja
--Exitosa
EXECUTE SP.uspReporte_Baja @id = 1;

SELECT * FROM arbitros.Reporte;
GO
--Fallida(Valores invalidos)
EXECUTE SP.uspReporte_Baja @id = -1;

SELECT * FROM arbitros.Reporte;
GO
--Fallida(Valores inexistentes)
EXECUTE SP.uspReporte_Baja @id = 456;

SELECT * FROM arbitros.Reporte;
GO

--Limpieza (primero las tablas hijas, despues las padres, por las claves foraneas)
DROP TABLE arbitros.Reporte;
DROP TABLE publicidad.Publicidad;
DROP TABLE arbitros.HablaIdioma;
DROP TABLE arbitros.Arbitro;
DROP TABLE partidos.Partido;
DROP TABLE arbitros.Idioma;
GO

DROP PROCEDURE SP.uspIdioma_Registrar;
DROP PROCEDURE SP.uspIdioma_Update;
DROP PROCEDURE SP.uspIdioma_Bajar;
DROP PROCEDURE SP.uspHablaIdioma_Registrar;
DROP PROCEDURE SP.uspHablaIdioma_Bajar;
DROP PROCEDURE SP.uspReporte_Registrar;
DROP PROCEDURE SP.uspReporte_Update;
DROP PROCEDURE SP.uspReporte_Baja;
GO