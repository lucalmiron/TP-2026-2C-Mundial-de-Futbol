-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Grupo 7
-- Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 26/10/26. Revision auxiliar de penales y publicidad por sede.

GO
-- Objetivo: ABM de EspacioPublicitario por sede; la identidad de sede no se mueve en Update.
CREATE OR ALTER PROCEDURE SP.EspacioPublicitario_Registrar
 @tipo VARCHAR(30),@costo DECIMAL(10,2),@idSede INT, @numero TINYINT
AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @errores NVARCHAR(2048)=N'';
 IF @tipo IS NULL OR LTRIM(RTRIM(@tipo))='' SET @errores+=N'Descripcion obligatoria. ';
 IF @costo IS NULL OR @costo<0 SET @errores+=N'Costo debe ser no negativo. ';
 IF NOT EXISTS(SELECT 1 FROM sedes.Sede WHERE IdSede=@idSede) SET @errores+=N'Sede inexistente. ';
 IF @numero IS NULL OR @numero NOT BETWEEN 1 AND 4 SET @errores+=N'Numero debe estar entre 1 y 4. ';
 IF EXISTS(SELECT 1 FROM publicidad.EspacioPublicitario WHERE IdSede=@idSede AND Numero=@numero) SET @errores+=N'Registro duplicado en la sede. ';
 IF LEN(@errores)>0 THROW 51000,@errores,1;
 INSERT publicidad.EspacioPublicitario(IdSede,Tipo,Costo,Numero) VALUES(@idSede,LTRIM(RTRIM(@tipo)),@costo,@numero);
END;
GO
CREATE OR ALTER PROCEDURE SP.EspacioPublicitario_Update
 @idEP INT,@tipo VARCHAR(30)=NULL,@costo DECIMAL(10,2)=NULL
AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @errores NVARCHAR(2048)=N'';
 IF NOT EXISTS(SELECT 1 FROM publicidad.EspacioPublicitario WHERE IdEP=@idEP) SET @errores+=N'Registro inexistente. ';
 IF @tipo IS NOT NULL AND LTRIM(RTRIM(@tipo))='' SET @errores+=N'Descripcion vacia. ';
 IF @costo<0 SET @errores+=N'Costo negativo. ';
 IF LEN(@errores)>0 THROW 51000,@errores,1;
 UPDATE publicidad.EspacioPublicitario SET Tipo=COALESCE(LTRIM(RTRIM(@tipo)),Tipo),Costo=COALESCE(@costo,Costo) WHERE IdEP=@idEP;
END;
GO
CREATE OR ALTER PROCEDURE SP.EspacioPublicitario_Bajar @idEP INT AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @errores NVARCHAR(2048)=N'';
 IF NOT EXISTS(SELECT 1 FROM publicidad.EspacioPublicitario WHERE IdEP=@idEP) SET @errores+=N'Registro inexistente. ';
 IF EXISTS(SELECT 1 FROM publicidad.HistorialPublicidad WHERE IdEP=@idEP) SET @errores+=N'Existen asignaciones publicitarias relacionadas. ';
 IF LEN(@errores)>0 THROW 51000,@errores,1;
 DELETE publicidad.EspacioPublicitario WHERE IdEP=@idEP;
END;
GO
