--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 09/10/2026

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
	BEGIN TRY
		IF (@idAnunciante IS NULL) OR (@idAnunciante <= 0)
			THROW 50000, '- Valor invalido: ID Anunciante.', 1;

		IF (@idCampania IS NULL) OR (@idCampania <= 0)
			THROW 50000, '- Valor invalido: ID Campania.', 1;

		IF NOT EXISTS (SELECT 1 FROM publicidad.Anunciante WHERE IdAnunciante = @idAnunciante)
			THROW 50000, '- Valor inexistente: ID Anunciante.', 1;

		IF NOT EXISTS (SELECT 1 FROM publicidad.Campania WHERE IdCampania = @idCampania)
			THROW 50000, '- Valor inexistente: ID Campania.', 1;

		IF EXISTS (SELECT 1 FROM publicidad.AnuncianteCampania WHERE IdAnunciante = @idAnunciante AND IdCampania = @idCampania)
			THROW 50000, '- Valor duplicado: AnuncianteCampania.', 1;

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
	BEGIN TRY
		IF (@idAnunciante IS NULL) OR (@idAnunciante <= 0)
			THROW 50000, '- Valor invalido: ID Anunciante.', 1;

		IF (@idCampania IS NULL) OR (@idCampania <= 0)
			THROW 50000, '- Valor invalido: ID Campania.', 1;

		IF NOT EXISTS (SELECT 1 FROM publicidad.AnuncianteCampania WHERE IdAnunciante = @idAnunciante AND IdCampania = @idCampania)
			THROW 50000, '- Valor inexistente: AnuncianteCampania.', 1;

		DELETE FROM publicidad.AnuncianteCampania WHERE IdAnunciante = @idAnunciante AND IdCampania = @idCampania
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO