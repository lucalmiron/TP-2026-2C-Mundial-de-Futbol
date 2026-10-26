--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 25/10/26

--Objetivo: Gestionar Tabla AnuncianteCampania (solo Registrar y Bajar, PK inmutable)

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspAnuncianteCampania_Registrar'))
    DROP PROCEDURE SP.uspAnuncianteCampania_Registrar
GO
CREATE PROCEDURE SP.uspAnuncianteCampania_Registrar
@idAnunciante INT,
@idCampania INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF (@idAnunciante IS NULL) OR (@idAnunciante <= 0)
			SET @errores += '- Valor invalido: ID Anunciante.' + N' ';

		IF (@idCampania IS NULL) OR (@idCampania <= 0)
			SET @errores += '- Valor invalido: ID Campania.' + N' ';

		IF NOT EXISTS (SELECT 1 FROM publicidad.Anunciante WHERE IdAnunciante = @idAnunciante)
			SET @errores += '- Valor inexistente: ID Anunciante.' + N' ';

		IF NOT EXISTS (SELECT 1 FROM publicidad.Campania WHERE IdCampania = @idCampania)
			SET @errores += '- Valor inexistente: ID Campania.' + N' ';

		IF EXISTS (SELECT 1 FROM publicidad.AnuncianteCampania WHERE IdAnunciante = @idAnunciante AND IdCampania = @idCampania)
			SET @errores += '- Valor duplicado: AnuncianteCampania.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		INSERT INTO publicidad.AnuncianteCampania (IdAnunciante, IdCampania)
		VALUES (@idAnunciante, @idCampania)
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspAnuncianteCampania_Bajar'))
    DROP PROCEDURE SP.uspAnuncianteCampania_Bajar
GO
CREATE PROCEDURE SP.uspAnuncianteCampania_Bajar
@idAnunciante INT,
@idCampania INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF (@idAnunciante IS NULL) OR (@idAnunciante <= 0)
			SET @errores += '- Valor invalido: ID Anunciante.' + N' ';

		IF (@idCampania IS NULL) OR (@idCampania <= 0)
			SET @errores += '- Valor invalido: ID Campania.' + N' ';

		IF NOT EXISTS (SELECT 1 FROM publicidad.AnuncianteCampania WHERE IdAnunciante = @idAnunciante AND IdCampania = @idCampania)
			SET @errores += '- Valor inexistente: AnuncianteCampania.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		DELETE FROM publicidad.AnuncianteCampania WHERE IdAnunciante = @idAnunciante AND IdCampania = @idCampania
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO