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

/*IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='TABLAS' AND TABLE_NAME='Partido')
BEGIN CREATE TABLE TABLAS.Partido(IdPartido INT PRIMARY KEY, IdFase INT); END;
GO

DROP TABLE TABLAS.Partido*/

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspFase_Registrar'))
  DROP PROCEDURE SP.uspFase_Registrar
GO
CREATE PROCEDURE SP.uspFase_Registrar
@Descripcion VARCHAR(20)
AS
BEGIN
	DECLARE @errorCount INT = 0;
	DECLARE @errorLine VARCHAR(300) = 'Error/es:'
	IF(@Descripcion IS NULL)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Descripción nula'
	END
	IF(@Descripcion NOT IN ('Grupos','Dieciseisavos','Octavos','Cuartos','Semifinal','Tercer Puesto','Final'))
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: '+ISNULL(@Descripcion,'NULL')+'.'
	END
	IF(@errorCount=0 AND EXISTS(SELECT 1 FROM TABLAS.Fase WHERE Descripcion=@Descripcion))
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Fase repetida'
	END
	IF(@errorCount=0) INSERT INTO TABLAS.Fase(Descripcion) VALUES(@Descripcion)
	ELSE PRINT @errorLine
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
	DECLARE @errorCount INT = 0
	DECLARE @errorLine VARCHAR(300) = 'Error/es:'
	IF(@Id IS NULL OR @Id <= 0)
	BEGIN 
		SET @errorCount=@errorCount+1
		SET @errorLine=@errorLine+CHAR(13)+'- Valor invalido: Id ('+ISNULL(CAST(@Id AS VARCHAR(10)),'NULL')+').' 
	END
	IF(@Descripcion IS NULL)
	BEGIN 
		SET @errorCount=@errorCount+1; 
		SET @errorLine=@errorLine+CHAR(13)+'- Valor invalido: Descripcion nula.'
	END
	IF(@Descripcion NOT IN ('Grupos','Dieciseisavos','Octavos','Cuartos','Semifinal','Tercer Puesto','Final'))
	BEGIN 
		SET @errorCount=@errorCount+1; 
		SET @errorLine=@errorLine+CHAR(13)+'- Valor invalido: '+ISNULL(@Descripcion,'NULL')+'.'
	END
	IF(@errorCount=0 AND NOT EXISTS(SELECT 1 FROM TABLAS.Fase WHERE IdFase=@Id))
	BEGIN 
		SET @errorCount=@errorCount+1; 
		SET @errorLine=@errorLine+CHAR(13)+'- Valor inexistente: Id ('+ISNULL(CAST(@Id AS VARCHAR(10)),'NULL')+').'
	END
	IF(@errorCount=0 AND EXISTS(SELECT 1 FROM TABLAS.Fase WHERE Descripcion=@Descripcion AND IdFase<>@Id))
	BEGIN 
		SET @errorCount=@errorCount+1; 
		SET @errorLine=@errorLine+CHAR(13)+'- Valor duplicado: Fase.' 
	END
	IF(@errorCount=0) UPDATE TABLAS.Fase SET Descripcion=@Descripcion WHERE IdFase=@Id;
	ELSE PRINT @errorLine;
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
	DECLARE @errorCount INT = 0;
	DECLARE @errorLine VARCHAR(300) = 'Error/es:';
	IF(@Id IS NULL OR @Id <= 0)
	BEGIN 
		SET @errorCount=@errorCount+1 
		SET @errorLine=@errorLine+CHAR(13)+'- Valor invalido: Id ('+ISNULL(CAST(@Id AS VARCHAR(10)),'NULL')+').' 
	END
	IF(@errorCount=0 AND NOT EXISTS(SELECT 1 FROM TABLAS.Fase WHERE IdFase=@Id))
	BEGIN 
		SET @errorCount=@errorCount+1 
		SET @errorLine=@errorLine+CHAR(13)+'- Valor inexistente: Id ('+ISNULL(CAST(@Id AS VARCHAR(10)),'NULL')+').' 
	END
	IF(@errorCount=0 AND EXISTS(SELECT 1 FROM TABLAS.Partido WHERE IdFase=@Id))
	BEGIN 
		SET @errorCount=@errorCount+1 
		SET @errorLine=@errorLine+CHAR(13)+'- Existen partidos con esta fase.' 
	END
	IF(@errorCount=0) DELETE FROM TABLAS.Fase WHERE IdFase=@Id;
	ELSE PRINT @errorLine;
END
GO