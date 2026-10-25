-- Universidad Nacional de La Matanza
-- Bases de datos aplicada 
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 08/10/2026
-- Objetivo: SPs Fase

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspFase_Registrar'))
  DROP PROCEDURE SP.uspFase_Registrar
GO
CREATE PROCEDURE SP.uspFase_Registrar
@Descripcion VARCHAR(20)
AS
BEGIN
	BEGIN TRY
		IF(@Descripcion IS NULL)
			THROW 50000, '- Valor invalido: Descripcion nula', 1;
		IF(@Descripcion NOT IN ('Grupos','Dieciseisavos','Octavos','Cuartos','Semifinal','Tercer Puesto','Final'))
		BEGIN
			DECLARE @msg VARCHAR(100) = '- Valor invalido: ' + ISNULL(@Descripcion,'NULL') + '.';
			THROW 50000, @msg, 1;
		END
		IF EXISTS(SELECT 1 FROM partidos.Fase WHERE Descripcion=@Descripcion)
			THROW 50000, '- Fase repetida', 1;
		INSERT INTO partidos.Fase(Descripcion) VALUES(@Descripcion)
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO
------------------------------------------------------------------------------------------------

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspFase_Update'))
  DROP PROCEDURE SP.uspFase_Update
GO
CREATE PROCEDURE SP.uspFase_Update
@Id INT,
@Descripcion VARCHAR(20)
AS
BEGIN
	BEGIN TRY
		IF(@Id IS NULL OR @Id <= 0)
		BEGIN
			DECLARE @msg VARCHAR(100) = '- Valor invalido: Id (' + ISNULL(CAST(@Id AS VARCHAR(10)),'NULL') + ').';
			THROW 50000, @msg, 1;
		END
		IF(@Descripcion IS NULL)
			THROW 50000, '- Valor invalido: Descripcion nula.', 1;
		IF(@Descripcion NOT IN ('Grupos','Dieciseisavos','Octavos','Cuartos','Semifinal','Tercer Puesto','Final'))
		BEGIN
			DECLARE @msg2 VARCHAR(100) = '- Valor invalido: ' + ISNULL(@Descripcion,'NULL') + '.';
			THROW 50000, @msg2, 1;
		END
		IF NOT EXISTS(SELECT 1 FROM partidos.Fase WHERE IdFase=@Id)
		BEGIN
			DECLARE @msg3 VARCHAR(100) = '- Valor inexistente: Id (' + ISNULL(CAST(@Id AS VARCHAR(10)),'NULL') + ').';
			THROW 50000, @msg3, 1;
		END
		IF EXISTS(SELECT 1 FROM partidos.Fase WHERE Descripcion=@Descripcion AND IdFase<>@Id)
			THROW 50000, '- Valor duplicado: Fase.', 1;
		UPDATE partidos.Fase SET Descripcion=@Descripcion WHERE IdFase=@Id;
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO
----------------------------------------------------------------------------------------

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspFase_Bajar'))
  DROP PROCEDURE SP.uspFase_Bajar
GO
CREATE PROCEDURE SP.uspFase_Bajar
@Id INT
AS
BEGIN
	BEGIN TRY
		IF(@Id IS NULL OR @Id <= 0)
		BEGIN
			DECLARE @msg VARCHAR(100) = '- Valor invalido: Id (' + ISNULL(CAST(@Id AS VARCHAR(10)),'NULL') + ').';
			THROW 50000, @msg, 1;
		END
		IF NOT EXISTS(SELECT 1 FROM partidos.Fase WHERE IdFase=@Id)
		BEGIN
			DECLARE @msg2 VARCHAR(100) = '- Valor inexistente: Id (' + ISNULL(CAST(@Id AS VARCHAR(10)),'NULL') + ').';
			THROW 50000, @msg2, 1;
		END
		IF EXISTS(SELECT 1 FROM partidos.Partido WHERE IdFase=@Id)
			THROW 50000, '- Existen partidos con esta fase.', 1;
		DELETE FROM partidos.Fase WHERE IdFase=@Id;
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO