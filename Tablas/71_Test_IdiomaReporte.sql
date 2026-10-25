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

-- Limpieza completa de tablas de test (orden inverso por FKs)
DROP TABLE IF EXISTS arbitros.Arbitraje;
DROP TABLE IF EXISTS arbitros.HablaIdioma;
DROP TABLE IF EXISTS arbitros.Reporte;
DROP TABLE IF EXISTS arbitros.Arbitraje;
DROP TABLE IF EXISTS arbitros.Arbitro;
DROP TABLE IF EXISTS partidos.Partido;
DROP TABLE IF EXISTS publicidad.Publicidad;
DROP TABLE IF EXISTS arbitros.Idioma;
DROP TABLE IF EXISTS arbitros.HablaIdioma;
GO

--Tablas auxiliares de testing
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'arbitros' AND TABLE_NAME = 'Arbitro')
BEGIN
	CREATE TABLE arbitros.Arbitro
	(
		IdArbitro INT PRIMARY KEY
	)
END

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'partidos' AND TABLE_NAME = 'Partido')
BEGIN
	CREATE TABLE partidos.Partido
	(
		IdPartido INT PRIMARY KEY,
		Fecha DATE,
		HoraUTC TIME
	)
END
GO

-- Tabla Arbitraje requerida por SP.uspReporte_Registrar
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'arbitros' AND TABLE_NAME = 'Arbitraje')
BEGIN
	CREATE TABLE arbitros.Arbitraje
	(
		Arbitro INT,
		Partido INT,
		FOREIGN KEY(Arbitro) REFERENCES arbitros.Arbitro(IdArbitro),
		FOREIGN KEY(Partido) REFERENCES partidos.Partido(IdPartido)
	)
END
GO

--Tablas a testear
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'arbitros' AND TABLE_NAME = 'Idioma')
BEGIN
	CREATE TABLE arbitros.Idioma
	(
		IdIdioma INT PRIMARY KEY IDENTITY(1, 1),
		Descripcion VARCHAR(20)
	)
END;
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'arbitros' AND TABLE_NAME = 'HablaIdioma')
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

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'arbitros' AND TABLE_NAME = 'Reporte')
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
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'publicidad' AND TABLE_NAME = 'Publicidad')
BEGIN
	CREATE TABLE publicidad.Publicidad
	(
		Idioma INT,
		FOREIGN KEY(Idioma) REFERENCES arbitros.Idioma(IdIdioma)
	)
END
GO

--SPs a testear
--Idioma
IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspIdioma_Registrar'))
    DROP PROCEDURE SP.uspIdioma_Registrar
GO
CREATE PROCEDURE SP.uspIdioma_Registrar @descripcion VARCHAR(20)
AS
BEGIN
	BEGIN TRY
		IF(@descripcion IS NULL)
			THROW 50000, '- Valor invalido: Descripcion.', 1;

		IF EXISTS(SELECT 1 FROM arbitros.Idioma WHERE Descripcion = @descripcion)
			THROW 50000, '- Valor duplicado: Descripcion.', 1;

		INSERT INTO arbitros.Idioma(Descripcion) VALUES (@descripcion)
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspIdioma_Update'))
    DROP PROCEDURE SP.uspIdioma_Update
GO
CREATE PROCEDURE SP.uspIdioma_Update @id INT, @descripcion VARCHAR(20)
AS
BEGIN
	BEGIN TRY
		IF(@id IS NULL) OR (@id <= 0)
			THROW 50000, '- Valor invalido: ID Idioma.', 1;

		IF(@descripcion IS NULL)
			THROW 50000, '- Valor invalido: Descripcion.', 1;

		IF NOT EXISTS(SELECT 1 FROM arbitros.Idioma WHERE IdIdioma = @id)
			THROW 50000, '- Valor inexistente: ID Idioma.', 1;

		IF EXISTS(SELECT 1 FROM arbitros.Idioma WHERE Descripcion = @descripcion AND IdIdioma <> @id)
			THROW 50000, '- Valor duplicado: Descripcion.', 1;

		UPDATE arbitros.Idioma
		SET Descripcion = @descripcion
		WHERE IdIdioma = @id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspIdioma_Bajar'))
    DROP PROCEDURE SP.uspIdioma_Bajar
GO
CREATE PROCEDURE SP.uspIdioma_Bajar @id INT
AS
BEGIN
	BEGIN TRY
		IF(@id IS NULL) OR (@id <= 0)
			THROW 50000, '- Valor invalido: ID Idioma.', 1;

		IF NOT EXISTS(SELECT 1 FROM arbitros.Idioma WHERE IdIdioma = @id)
			THROW 50000, '- Valor inexistente: ID Idioma.', 1;

		IF EXISTS(SELECT 1 FROM arbitros.HablaIdioma WHERE Idioma = @id)
			THROW 50000, '- Existen 1 o mas registros relacionados: HablaIdioma. Elimine dichos registros para continuar.', 1;

		IF EXISTS(SELECT 1 FROM publicidad.Publicidad WHERE Idioma = @id)
			THROW 50000, '- Existen 1 o mas registros relacionados: Publicidad. Elimine dichos registros para continuar.', 1;

		DELETE FROM arbitros.Idioma WHERE IdIdioma = @id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

--HablaIdioma
IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspHablaIdioma_Registrar'))
    DROP PROCEDURE SP.uspHablaIdioma_Registrar
GO
CREATE PROCEDURE SP.uspHablaIdioma_Registrar @arbitro INT, @idioma INT
AS
BEGIN
	BEGIN TRY
		IF(@arbitro IS NULL) OR (@arbitro <= 0)
			THROW 50000, '- Valor invalido: Arbitro.', 1;

		IF(@idioma IS NULL) OR (@idioma <= 0)
			THROW 50000, '- Valor invalido: Idioma.', 1;

		IF NOT EXISTS(SELECT 1 FROM arbitros.Arbitro WHERE IdArbitro = @arbitro)
			THROW 50000, '- Valor inexistente: Arbitro.', 1;

		IF NOT EXISTS(SELECT 1 FROM arbitros.Idioma WHERE IdIdioma = @idioma)
			THROW 50000, '- Valor inexistente: Idioma.', 1;

		IF EXISTS(SELECT 1 FROM arbitros.HablaIdioma WHERE Arbitro = @arbitro AND Idioma = @idioma)
			THROW 50000, '- Valor duplicado: Idioma.', 1;

		INSERT INTO arbitros.HablaIdioma VALUES (@arbitro, @idioma)
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspHablaIdioma_Bajar'))
    DROP PROCEDURE SP.uspHablaIdioma_Bajar
GO
CREATE PROCEDURE SP.uspHablaIdioma_Bajar @arbitro INT, @idioma INT
AS
BEGIN
	BEGIN TRY
		IF(@arbitro IS NULL) OR (@arbitro <= 0)
			THROW 50000, '- Valor invalido: Arbitro.', 1;

		IF(@idioma IS NULL) OR (@idioma <= 0)
			THROW 50000, '- Valor invalido: Idioma.', 1;

		IF NOT EXISTS(SELECT 1 FROM arbitros.Arbitro WHERE IdArbitro = @arbitro)
			THROW 50000, '- Valor inexistente: Arbitro.', 1;

		IF NOT EXISTS(SELECT 1 FROM arbitros.Idioma WHERE IdIdioma = @idioma)
			THROW 50000, '- Valor inexistente: Idioma.', 1;

		IF NOT EXISTS(SELECT 1 FROM arbitros.HablaIdioma WHERE Arbitro = @arbitro AND Idioma = @idioma)
			THROW 50000, '- Registro inexistente.', 1;

		DELETE FROM arbitros.HablaIdioma WHERE Arbitro = @arbitro AND Idioma = @idioma
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
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

--Llenado de tablas aux
INSERT INTO arbitros.Idioma(Descripcion) VALUES ('Aux1'),('Aux2')
INSERT INTO arbitros.Arbitro VALUES (1), (2), (3);
INSERT INTO partidos.Partido (IdPartido, Fecha, HoraUTC) VALUES (1, '2026-06-15', '16:00'), (2, '2026-06-16', '18:00'), (3, '2026-06-17', '20:00');
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