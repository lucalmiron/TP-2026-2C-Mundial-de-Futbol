-- Universidad Nacional de La Matanza
-- Bases de datos aplicada 
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 26/10/26
-- Objetivo: SPs Fase

-- Ejecutar en la base seleccionada por el instalador.
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspFase_Registrar'))
  DROP PROCEDURE SP.uspFase_Registrar
GO
CREATE PROCEDURE SP.uspFase_Registrar
@Descripcion VARCHAR(20)
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF(@Descripcion IS NULL)
			SET @errores += '- Valor invalido: Descripcion nula' + N' ';
		IF(@Descripcion NOT IN ('Grupos','Dieciseisavos','Octavos','Cuartos','Semifinal','Tercer Puesto','Final'))
		BEGIN
			DECLARE @msg VARCHAR(100) = '- Valor invalido: ' + ISNULL(@Descripcion,'NULL') + '.';
			SET @errores += @msg + N' ';
		END
		IF EXISTS(SELECT 1 FROM partidos.Fase WHERE Descripcion=@Descripcion)
			SET @errores += '- Fase repetida' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;
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
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF(@Id IS NULL OR @Id <= 0)
		BEGIN
			DECLARE @msg VARCHAR(100) = '- Valor invalido: Id (' + ISNULL(CAST(@Id AS VARCHAR(10)),'NULL') + ').';
			SET @errores += @msg + N' ';
		END
		IF(@Descripcion IS NULL)
			SET @errores += '- Valor invalido: Descripcion nula.' + N' ';
		IF(@Descripcion NOT IN ('Grupos','Dieciseisavos','Octavos','Cuartos','Semifinal','Tercer Puesto','Final'))
		BEGIN
			DECLARE @msg2 VARCHAR(100) = '- Valor invalido: ' + ISNULL(@Descripcion,'NULL') + '.';
			SET @errores += @msg2 + N' ';
		END
		IF NOT EXISTS(SELECT 1 FROM partidos.Fase WHERE IdFase=@Id)
		BEGIN
			DECLARE @msg3 VARCHAR(100) = '- Valor inexistente: Id (' + ISNULL(CAST(@Id AS VARCHAR(10)),'NULL') + ').';
			SET @errores += @msg3 + N' ';
		END
		IF EXISTS(SELECT 1 FROM partidos.Fase WHERE Descripcion=@Descripcion AND IdFase<>@Id)
			SET @errores += '- Valor duplicado: Fase.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;
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
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF(@Id IS NULL OR @Id <= 0)
		BEGIN
			DECLARE @msg VARCHAR(100) = '- Valor invalido: Id (' + ISNULL(CAST(@Id AS VARCHAR(10)),'NULL') + ').';
			SET @errores += @msg + N' ';
		END
		IF NOT EXISTS(SELECT 1 FROM partidos.Fase WHERE IdFase=@Id)
		BEGIN
			DECLARE @msg2 VARCHAR(100) = '- Valor inexistente: Id (' + ISNULL(CAST(@Id AS VARCHAR(10)),'NULL') + ').';
			SET @errores += @msg2 + N' ';
		END
		IF EXISTS(SELECT 1 FROM partidos.Partido WHERE IdFase=@Id)
			SET @errores += '- Existen partidos con esta fase.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;
		DELETE FROM partidos.Fase WHERE IdFase=@Id;
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO