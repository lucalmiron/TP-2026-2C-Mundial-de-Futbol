--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: xx/xx/2026

--Creacion de SP para utilizacion de API para convertir horario

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

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