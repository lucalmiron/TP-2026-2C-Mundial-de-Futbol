-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Grupo 7
-- Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 21/10/2026. Revision auxiliar de penales y publicidad por sede.
USE MUNDIAL;
GO
-- Objetivo: asignar piezas a espacios de la sede y conservar el costo pactado.
-- CostoFinal omitido: costo del espacio + costo de franja; explicito: importe pactado.
CREATE OR ALTER PROCEDURE SP.uspHistorialPublicidad_Registrar
 @idPublicidad INT,@idPartido INT,@idEP INT,@costoFinal DECIMAL(10,2)=NULL,@idCF INT=NULL
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 DECLARE @errores NVARCHAR(2048)=N'',@sede INT,@costo DECIMAL(10,2);
 IF NOT EXISTS(SELECT 1 FROM publicidad.Publicidad WHERE IdPublicidad=@idPublicidad) SET @errores+=N'Publicidad inexistente. ';
 IF NOT EXISTS(SELECT 1 FROM partidos.Partido WHERE IdPartido=@idPartido) SET @errores+=N'Partido inexistente. ';
 IF NOT EXISTS(SELECT 1 FROM publicidad.EspacioPublicitario WHERE IdEP=@idEP) SET @errores+=N'Espacio inexistente. ';
 IF NOT EXISTS(SELECT 1 FROM publicidad.CostoFranja WHERE IdCF=@idCF) SET @errores+=N'Tarifa de franja inexistente. ';
 IF @costoFinal<0 SET @errores+=N'Costo final negativo. ';
 IF LEN(@errores)>0 THROW 51000,@errores,1;
 BEGIN TRY
  BEGIN TRANSACTION;
  SELECT @sede=IdSede FROM partidos.Partido WITH(UPDLOCK,HOLDLOCK) WHERE IdPartido=@idPartido;
  SELECT @costo=COALESCE(@costoFinal,e.Costo+c.Costo) FROM publicidad.EspacioPublicitario e WITH(UPDLOCK,HOLDLOCK)
   JOIN publicidad.CostoFranja c WITH(UPDLOCK,HOLDLOCK) ON c.IdCF=@idCF WHERE e.IdEP=@idEP;
  IF NOT EXISTS(SELECT 1 FROM publicidad.EspacioPublicitario WHERE IdEP=@idEP AND IdSede=@sede) SET @errores+=N'El espacio no pertenece a la sede del partido. ';
  IF NOT EXISTS(SELECT 1 FROM publicidad.CostoFranja WHERE IdCF=@idCF AND IdSede=@sede) SET @errores+=N'La franja no pertenece a la sede del partido. ';
  IF EXISTS(SELECT 1 FROM publicidad.HistorialPublicidad WHERE IdPartido=@idPartido AND IdEP=@idEP) SET @errores+=N'Espacio ya ocupado en el partido. ';
  IF (SELECT COUNT(*) FROM publicidad.HistorialPublicidad WHERE IdPartido=@idPartido)>=4 SET @errores+=N'El partido ya tiene cuatro espacios asignados. ';
  IF LEN(@errores)>0 THROW 51000,@errores,1;
  INSERT publicidad.HistorialPublicidad(IdPublicidad,IdPartido,IdEP,IdCF,CostoFinal) VALUES(@idPublicidad,@idPartido,@idEP,@idCF,@costo);
  COMMIT;
 END TRY
 BEGIN CATCH
  IF @@TRANCOUNT>0 ROLLBACK;
  THROW;
 END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE SP.uspHistorialPublicidad_Update
 @id INT,@idPublicidad INT,@idPartido INT,@idEP INT,@costoFinal DECIMAL(10,2),@idCF INT=NULL
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 DECLARE @errores NVARCHAR(2048)=N'',@sede INT;
 IF NOT EXISTS(SELECT 1 FROM publicidad.HistorialPublicidad WHERE IdHistorial=@id) SET @errores+=N'Historial inexistente. ';
 IF NOT EXISTS(SELECT 1 FROM publicidad.Publicidad WHERE IdPublicidad=@idPublicidad) SET @errores+=N'Publicidad inexistente. ';
 IF NOT EXISTS(SELECT 1 FROM partidos.Partido WHERE IdPartido=@idPartido) SET @errores+=N'Partido inexistente. ';
 IF @costoFinal IS NULL OR @costoFinal<0 SET @errores+=N'Indicar un costo final no negativo. ';
 IF LEN(@errores)>0 THROW 51000,@errores,1;
 BEGIN TRY
  BEGIN TRANSACTION;
  SELECT @sede=IdSede FROM partidos.Partido WITH(UPDLOCK,HOLDLOCK) WHERE IdPartido=@idPartido;
  IF NOT EXISTS(SELECT 1 FROM publicidad.EspacioPublicitario WITH(UPDLOCK,HOLDLOCK) WHERE IdEP=@idEP AND IdSede=@sede) SET @errores+=N'Espacio inexistente o de otra sede. ';
  IF NOT EXISTS(SELECT 1 FROM publicidad.CostoFranja WITH(UPDLOCK,HOLDLOCK) WHERE IdCF=@idCF AND IdSede=@sede) SET @errores+=N'Franja inexistente o de otra sede. ';
  IF EXISTS(SELECT 1 FROM publicidad.HistorialPublicidad WHERE IdPartido=@idPartido AND IdEP=@idEP AND IdHistorial<>@id) SET @errores+=N'Espacio ya ocupado. ';
  IF LEN(@errores)>0 THROW 51000,@errores,1;
  UPDATE publicidad.HistorialPublicidad SET IdPublicidad=@idPublicidad,IdPartido=@idPartido,IdEP=@idEP,IdCF=@idCF,CostoFinal=@costoFinal WHERE IdHistorial=@id;
  COMMIT;
 END TRY
 BEGIN CATCH
  IF @@TRANCOUNT>0 ROLLBACK;
  THROW;
 END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE SP.uspHistorialPublicidad_Bajar @id INT AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM publicidad.HistorialPublicidad WHERE IdHistorial=@id) THROW 51000,'Historial inexistente.',1;
 DELETE publicidad.HistorialPublicidad WHERE IdHistorial=@id;
END;
GO
-- Tipo de entrada para la asignacion atomica de exactamente cuatro espacios.
IF TYPE_ID('publicidad.AsignacionesPartido') IS NULL
 EXEC('CREATE TYPE publicidad.AsignacionesPartido AS TABLE (
 IdEP INT NOT NULL PRIMARY KEY, IdPublicidad INT NOT NULL, IdCF INT NOT NULL, CostoFinal DECIMAL(10,2) NULL)');
GO
CREATE OR ALTER PROCEDURE SPTRANS.uspPublicidad_AsignarCuatro
 @idPartido INT,@asignaciones publicidad.AsignacionesPartido READONLY
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 IF (SELECT COUNT(*) FROM @asignaciones)<>4 THROW 51000,'Se requieren exactamente cuatro espacios distintos.',1;
 IF NOT EXISTS(SELECT 1 FROM partidos.Partido WHERE IdPartido=@idPartido) THROW 51000,'Partido inexistente.',1;
 BEGIN TRY
  BEGIN TRANSACTION;
  DECLARE @sede INT;
  SELECT @sede=IdSede FROM partidos.Partido WITH(UPDLOCK,HOLDLOCK) WHERE IdPartido=@idPartido;
  IF EXISTS(SELECT 1 FROM publicidad.HistorialPublicidad WHERE IdPartido=@idPartido) THROW 51000,'El partido ya tiene asignaciones; revisarlas antes de programar cuatro piezas.',1;
  DECLARE @errores NVARCHAR(2048)=N'';
  IF EXISTS(SELECT 1 FROM @asignaciones a LEFT JOIN publicidad.EspacioPublicitario e WITH(UPDLOCK,HOLDLOCK) ON e.IdEP=a.IdEP
      WHERE e.IdEP IS NULL OR e.IdSede<>@sede) SET @errores+=N'Espacios inexistentes o de otra sede. ';
  IF EXISTS(SELECT 1 FROM @asignaciones a LEFT JOIN publicidad.CostoFranja c WITH(UPDLOCK,HOLDLOCK) ON c.IdCF=a.IdCF
      WHERE c.IdCF IS NULL OR c.IdSede<>@sede) SET @errores+=N'Franjas inexistentes o de otra sede. ';
  IF EXISTS(SELECT 1 FROM @asignaciones a LEFT JOIN publicidad.Publicidad p ON p.IdPublicidad=a.IdPublicidad
      WHERE p.IdPublicidad IS NULL) SET @errores+=N'Publicidades inexistentes. ';
  IF EXISTS(SELECT 1 FROM @asignaciones WHERE CostoFinal<0) SET @errores+=N'Costos finales negativos. ';
  IF LEN(@errores)>0 THROW 51000,@errores,1;
  INSERT publicidad.HistorialPublicidad(IdPartido,IdEP,IdPublicidad,IdCF,CostoFinal)
  SELECT @idPartido,a.IdEP,a.IdPublicidad,a.IdCF,COALESCE(a.CostoFinal,e.Costo+c.Costo)
  FROM @asignaciones a JOIN publicidad.EspacioPublicitario e ON e.IdEP=a.IdEP
  JOIN publicidad.CostoFranja c ON c.IdCF=a.IdCF;
  COMMIT;
 END TRY
 BEGIN CATCH
  IF @@TRANCOUNT>0 ROLLBACK;
  THROW;
 END CATCH;
END;
GO
