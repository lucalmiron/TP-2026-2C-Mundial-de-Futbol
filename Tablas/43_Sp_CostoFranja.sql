-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Grupo 7
-- Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 21/10/2026. Revision auxiliar de penales y publicidad por sede.
USE MUNDIAL;
GO
-- Objetivo: ABM de CostoFranja por sede; la identidad de sede no se mueve en Update.
CREATE OR ALTER PROCEDURE SP.CostoFranja_Registrar
 @tipoFranja VARCHAR(30),@costo DECIMAL(10,2),@idSede INT
AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @errores NVARCHAR(2048)=N'';
 IF @tipoFranja IS NULL OR LTRIM(RTRIM(@tipoFranja))='' SET @errores+=N'Descripcion obligatoria. ';
 IF @costo IS NULL OR @costo<0 SET @errores+=N'Costo debe ser no negativo. ';
 IF NOT EXISTS(SELECT 1 FROM sedes.Sede WHERE IdSede=@idSede) SET @errores+=N'Sede inexistente. ';
 
 IF EXISTS(SELECT 1 FROM publicidad.CostoFranja WHERE IdSede=@idSede AND TipoFranja=@tipoFranja) SET @errores+=N'Registro duplicado en la sede. ';
 IF LEN(@errores)>0 THROW 51000,@errores,1;
 INSERT publicidad.CostoFranja(IdSede,TipoFranja,Costo) VALUES(@idSede,LTRIM(RTRIM(@tipoFranja)),@costo);
END;
GO
CREATE OR ALTER PROCEDURE SP.CostoFranja_Update
 @idCF INT,@tipoFranja VARCHAR(30)=NULL,@costo DECIMAL(10,2)=NULL
AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @errores NVARCHAR(2048)=N'';
 IF NOT EXISTS(SELECT 1 FROM publicidad.CostoFranja WHERE IdCF=@idCF) SET @errores+=N'Registro inexistente. ';
 IF @tipoFranja IS NOT NULL AND LTRIM(RTRIM(@tipoFranja))='' SET @errores+=N'Descripcion vacia. ';
 IF @costo<0 SET @errores+=N'Costo negativo. ';
 IF EXISTS(SELECT 1 FROM publicidad.CostoFranja a JOIN publicidad.CostoFranja b ON a.IdSede=b.IdSede
 WHERE a.IdCF=@idCF AND b.IdCF<>a.IdCF AND b.TipoFranja=@tipoFranja) SET @errores+=N'Franja duplicada en la sede. ';
 IF @tipoFranja IS NOT NULL AND EXISTS(SELECT 1 FROM publicidad.HistorialPublicidad h JOIN publicidad.CostoFranja c ON c.IdCF=h.IdCF WHERE c.IdCF=@idCF AND c.TipoFranja<>@tipoFranja)
 SET @errores+=N'No se puede renombrar una franja utilizada. ';
 IF LEN(@errores)>0 THROW 51000,@errores,1;
 UPDATE publicidad.CostoFranja SET TipoFranja=COALESCE(LTRIM(RTRIM(@tipoFranja)),TipoFranja),Costo=COALESCE(@costo,Costo) WHERE IdCF=@idCF;
END;
GO
CREATE OR ALTER PROCEDURE SP.CostoFranja_Bajar @idCF INT AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @errores NVARCHAR(2048)=N'';
 IF NOT EXISTS(SELECT 1 FROM publicidad.CostoFranja WHERE IdCF=@idCF) SET @errores+=N'Registro inexistente. ';
 IF EXISTS(SELECT 1 FROM publicidad.HistorialPublicidad WHERE IdCF=@idCF) SET @errores+=N'Existen asignaciones publicitarias relacionadas. ';
 IF LEN(@errores)>0 THROW 51000,@errores,1;
 DELETE publicidad.CostoFranja WHERE IdCF=@idCF;
END;
GO
