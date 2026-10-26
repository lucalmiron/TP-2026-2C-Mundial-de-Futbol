-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Grupo 7
-- Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 26/10/26.
-- Objetivo: comprobar ABM de sede con identificadores obtenidos de sus datos de prueba.
USE MUNDIAL;
GO
SET NOCOUNT ON;
DECLARE @pais INT,@huso INT,@sede INT;
IF EXISTS(SELECT 1 FROM equipos.Pais WHERE NOMBRE='Pais prueba sede 84')
 THROW 51999,'Ya existen datos de esta prueba; revisarlos antes de repetir.',1;
EXEC SP.uspPais_Registrar 'Pais prueba sede 84',90;
SELECT @pais=IdPais FROM equipos.Pais WHERE NOMBRE='Pais prueba sede 84';
EXEC SP.uspHusoHorario_Registrar 'UTC-3 (Sede 84)',@pais;
SELECT @huso=IdHuso FROM sedes.HusoHorario WHERE Nombre='UTC-3 (Sede 84)';

BEGIN TRY
 EXEC SP.uspSede_Registrar '', 'Ciudad prueba',50000,@pais,@huso;
 THROW 51999,'Se esperaba rechazo.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()<>50000 OR ERROR_MESSAGE() NOT LIKE '%Nombre%' THROW;
END CATCH;
PRINT 'OK 1: Nombre';

BEGIN TRY
 EXEC SP.uspSede_Registrar 'Sede prueba 84',NULL,50000,@pais,@huso;
 THROW 51999,'Se esperaba rechazo.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()<>50000 OR ERROR_MESSAGE() NOT LIKE '%Ciudad%' THROW;
END CATCH;
PRINT 'OK 2: Ciudad';

BEGIN TRY
 EXEC SP.uspSede_Registrar 'Sede prueba 84','Ciudad prueba',0,@pais,@huso;
 THROW 51999,'Se esperaba rechazo.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()<>50000 OR ERROR_MESSAGE() NOT LIKE '%Capacidad%' THROW;
END CATCH;
PRINT 'OK 3: Capacidad';

BEGIN TRY
 EXEC SP.uspSede_Registrar 'Sede prueba 84','Ciudad prueba',50000,-1,@huso;
 THROW 51999,'Se esperaba rechazo.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()<>50000 OR ERROR_MESSAGE() NOT LIKE '%Pais%' THROW;
END CATCH;
PRINT 'OK 4: Pais';

BEGIN TRY
 EXEC SP.uspSede_Registrar 'Sede prueba 84','Ciudad prueba',50000,@pais,-1;
 THROW 51999,'Se esperaba rechazo.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()<>50000 OR ERROR_MESSAGE() NOT LIKE '%Huso horario%' THROW;
END CATCH;
PRINT 'OK 5: Huso horario';

EXEC SP.uspSede_Registrar 'Sede prueba 84','Ciudad prueba',50000,@pais,@huso;
SELECT @sede=IdSede FROM sedes.Sede WHERE Nombre='Sede prueba 84' AND IdPais=@pais;
IF @sede IS NULL THROW 51999,'No se registro la sede.',1;
SELECT * FROM sedes.Sede WHERE IdSede=@sede;

BEGIN TRY
 EXEC SP.uspSede_Registrar 'Sede prueba 84','Ciudad prueba',50000,@pais,@huso;
 THROW 51999,'Se esperaba rechazo.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()<>50000 OR ERROR_MESSAGE() NOT LIKE '%duplicado%' THROW;
END CATCH;
PRINT 'OK 6: duplicado';

EXEC SP.uspSede_Update @idSede=@sede,@capacidad=60000;
IF NOT EXISTS(SELECT 1 FROM sedes.Sede WHERE IdSede=@sede AND Capacidad=60000)
 THROW 51999,'No se actualizo la capacidad.',1;
SELECT * FROM sedes.Sede WHERE IdSede=@sede;

BEGIN TRY
 EXEC SP.uspSede_Update @idSede=-1,@capacidad=60000;
 THROW 51999,'Se esperaba rechazo.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()<>50000 OR ERROR_MESSAGE() NOT LIKE '%IdSede%' THROW;
END CATCH;
PRINT 'OK 7: IdSede';

BEGIN TRY
 EXEC SP.uspSede_Update @idSede=@sede,@capacidad=-1;
 THROW 51999,'Se esperaba rechazo.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()<>50000 OR ERROR_MESSAGE() NOT LIKE '%Capacidad%' THROW;
END CATCH;
PRINT 'OK 8: Capacidad';

BEGIN TRY
 EXEC SP.uspSede_Update @idSede=@sede,@pais=-1;
 THROW 51999,'Se esperaba rechazo.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()<>50000 OR ERROR_MESSAGE() NOT LIKE '%Pais%' THROW;
END CATCH;
PRINT 'OK 9: Pais';

BEGIN TRY
 EXEC SP.uspSede_Update @idSede=@sede,@huso=-1;
 THROW 51999,'Se esperaba rechazo.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()<>50000 OR ERROR_MESSAGE() NOT LIKE '%Huso horario%' THROW;
END CATCH;
PRINT 'OK 10: Huso horario';

BEGIN TRY
 EXEC SP.uspSede_Bajar -1;
 THROW 51999,'Se esperaba rechazo.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()<>50000 OR ERROR_MESSAGE() NOT LIKE '%IdSede%' THROW;
END CATCH;
PRINT 'OK 11: IdSede';

EXEC SP.uspSede_Bajar @sede;
IF EXISTS(SELECT 1 FROM sedes.Sede WHERE IdSede=@sede) THROW 51999,'No se elimino la sede.',1;
EXEC SP.uspHusoHorario_Bajar @huso;
EXEC SP.uspPais_Bajar @pais;
IF EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais=@pais) OR EXISTS(SELECT 1 FROM sedes.HusoHorario WHERE IdHuso=@huso)
 THROW 51999,'Quedaron datos de prueba.',1;
PRINT 'Sede: alta, modificacion, baja y 11 rechazos comprobados.';
