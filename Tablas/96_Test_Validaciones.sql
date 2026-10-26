-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Grupo 7
-- Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 25/10/26.
-- Objetivo: verificar rechazos de entradas nulas en los SP modificados.
-- Ejecutar con los SP reales instalados en una base MUNDIAL_Final_Test*.
SET NOCOUNT ON;
IF DB_NAME() NOT LIKE 'MUNDIAL[_]Final[_]Test%' THROW 51000,'Seleccionar una base de pruebas aislada.',1;

BEGIN TRY
 EXEC SP.uspPais_Registrar @nombre=NULL,@pbi=NULL;
 THROW 51999,'SP.uspPais_Registrar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspPais_Registrar dejo transaccion abierta.',1;
PRINT 'OK: SP.uspPais_Registrar';

BEGIN TRY
 EXEC SP.uspPais_Update @idPais=NULL,@nombre=NULL,@pbi=NULL;
 THROW 51999,'SP.uspPais_Update acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspPais_Update dejo transaccion abierta.',1;
PRINT 'OK: SP.uspPais_Update';

BEGIN TRY
 EXEC SP.uspPais_Bajar @idPais=NULL;
 THROW 51999,'SP.uspPais_Bajar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspPais_Bajar dejo transaccion abierta.',1;
PRINT 'OK: SP.uspPais_Bajar';

BEGIN TRY
 EXEC SP.uspGrupo_Registrar @nombre=NULL;
 THROW 51999,'SP.uspGrupo_Registrar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspGrupo_Registrar dejo transaccion abierta.',1;
PRINT 'OK: SP.uspGrupo_Registrar';

BEGIN TRY
 EXEC SP.uspGrupo_Update @id=NULL,@nombre=NULL;
 THROW 51999,'SP.uspGrupo_Update acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspGrupo_Update dejo transaccion abierta.',1;
PRINT 'OK: SP.uspGrupo_Update';

BEGIN TRY
 EXEC SP.uspGrupo_Bajar @id=NULL;
 THROW 51999,'SP.uspGrupo_Bajar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspGrupo_Bajar dejo transaccion abierta.',1;
PRINT 'OK: SP.uspGrupo_Bajar';

BEGIN TRY
 EXEC SP.uspClub_Registrar @nombre=NULL;
 THROW 51999,'SP.uspClub_Registrar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspClub_Registrar dejo transaccion abierta.',1;
PRINT 'OK: SP.uspClub_Registrar';

BEGIN TRY
 EXEC SP.uspClub_Update @id=NULL,@nombre=NULL;
 THROW 51999,'SP.uspClub_Update acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspClub_Update dejo transaccion abierta.',1;
PRINT 'OK: SP.uspClub_Update';

BEGIN TRY
 EXEC SP.uspClub_Bajar @id=NULL;
 THROW 51999,'SP.uspClub_Bajar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspClub_Bajar dejo transaccion abierta.',1;
PRINT 'OK: SP.uspClub_Bajar';

BEGIN TRY
 EXEC SP.uspIdioma_Registrar @descripcion=NULL;
 THROW 51999,'SP.uspIdioma_Registrar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspIdioma_Registrar dejo transaccion abierta.',1;
PRINT 'OK: SP.uspIdioma_Registrar';

BEGIN TRY
 EXEC SP.uspIdioma_Update @id=NULL,@descripcion=NULL;
 THROW 51999,'SP.uspIdioma_Update acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspIdioma_Update dejo transaccion abierta.',1;
PRINT 'OK: SP.uspIdioma_Update';

BEGIN TRY
 EXEC SP.uspIdioma_Bajar @id=NULL;
 THROW 51999,'SP.uspIdioma_Bajar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspIdioma_Bajar dejo transaccion abierta.',1;
PRINT 'OK: SP.uspIdioma_Bajar';

BEGIN TRY
 EXEC SP.uspFase_Registrar @Descripcion=NULL;
 THROW 51999,'SP.uspFase_Registrar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspFase_Registrar dejo transaccion abierta.',1;
PRINT 'OK: SP.uspFase_Registrar';

BEGIN TRY
 EXEC SP.uspFase_Update @Id=NULL,@Descripcion=NULL;
 THROW 51999,'SP.uspFase_Update acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspFase_Update dejo transaccion abierta.',1;
PRINT 'OK: SP.uspFase_Update';

BEGIN TRY
 EXEC SP.uspFase_Bajar @Id=NULL;
 THROW 51999,'SP.uspFase_Bajar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspFase_Bajar dejo transaccion abierta.',1;
PRINT 'OK: SP.uspFase_Bajar';

BEGIN TRY
 EXEC SP.uspMotivo_Registrar @descripcion=NULL;
 THROW 51999,'SP.uspMotivo_Registrar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspMotivo_Registrar dejo transaccion abierta.',1;
PRINT 'OK: SP.uspMotivo_Registrar';

BEGIN TRY
 EXEC SP.uspMotivo_Update @id=NULL,@descripcion=NULL;
 THROW 51999,'SP.uspMotivo_Update acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspMotivo_Update dejo transaccion abierta.',1;
PRINT 'OK: SP.uspMotivo_Update';

BEGIN TRY
 EXEC SP.uspMotivo_Bajar @id=NULL;
 THROW 51999,'SP.uspMotivo_Bajar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspMotivo_Bajar dejo transaccion abierta.',1;
PRINT 'OK: SP.uspMotivo_Bajar';

BEGIN TRY
 EXEC SP.uspCampania_Registrar @nombre=NULL,@descripcion=NULL;
 THROW 51999,'SP.uspCampania_Registrar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspCampania_Registrar dejo transaccion abierta.',1;
PRINT 'OK: SP.uspCampania_Registrar';

BEGIN TRY
 EXEC SP.uspCampania_Update @id=NULL,@nombre=NULL,@descripcion=NULL;
 THROW 51999,'SP.uspCampania_Update acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspCampania_Update dejo transaccion abierta.',1;
PRINT 'OK: SP.uspCampania_Update';

BEGIN TRY
 EXEC SP.uspCampania_Bajar @id=NULL;
 THROW 51999,'SP.uspCampania_Bajar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspCampania_Bajar dejo transaccion abierta.',1;
PRINT 'OK: SP.uspCampania_Bajar';

BEGIN TRY
 EXEC SP.uspMundial_Registrar @idPais=NULL,@fechaInicio=NULL,@fechaFin=NULL,@tamMin=NULL,@tamMax=NULL,@ventanas=NULL,@cantidad=NULL,@suspMax=NULL,@suspTiempo=NULL;
 THROW 51999,'SP.uspMundial_Registrar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspMundial_Registrar dejo transaccion abierta.',1;
PRINT 'OK: SP.uspMundial_Registrar';

BEGIN TRY
 EXEC SP.uspMundial_Update @id=NULL,@idPais=NULL,@fechaInicio=NULL,@fechaFin=NULL,@tamMin=NULL,@tamMax=NULL,@ventanas=NULL,@cantidad=NULL,@suspMax=NULL,@suspTiempo=NULL;
 THROW 51999,'SP.uspMundial_Update acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspMundial_Update dejo transaccion abierta.',1;
PRINT 'OK: SP.uspMundial_Update';

BEGIN TRY
 EXEC SP.uspMundial_Bajar @id=NULL;
 THROW 51999,'SP.uspMundial_Bajar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspMundial_Bajar dejo transaccion abierta.',1;
PRINT 'OK: SP.uspMundial_Bajar';

BEGIN TRY
 EXEC SP.uspHusoHorario_Registrar @nombre=NULL,@idPais=NULL;
 THROW 51999,'SP.uspHusoHorario_Registrar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspHusoHorario_Registrar dejo transaccion abierta.',1;
PRINT 'OK: SP.uspHusoHorario_Registrar';

BEGIN TRY
 EXEC SP.uspHusoHorario_Update @idHuso=NULL,@nombre=NULL,@idPais=NULL;
 THROW 51999,'SP.uspHusoHorario_Update acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspHusoHorario_Update dejo transaccion abierta.',1;
PRINT 'OK: SP.uspHusoHorario_Update';

BEGIN TRY
 EXEC SP.uspHusoHorario_Bajar @idHuso=NULL;
 THROW 51999,'SP.uspHusoHorario_Bajar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspHusoHorario_Bajar dejo transaccion abierta.',1;
PRINT 'OK: SP.uspHusoHorario_Bajar';

BEGIN TRY
 EXEC SP.uspSede_Registrar @nombre=NULL,@ciudad=NULL,@capacidad=NULL,@pais=NULL,@huso=NULL;
 THROW 51999,'SP.uspSede_Registrar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspSede_Registrar dejo transaccion abierta.',1;
PRINT 'OK: SP.uspSede_Registrar';

BEGIN TRY
 EXEC SP.uspSede_Update @idSede=NULL,@nombre=NULL,@ciudad=NULL,@capacidad=NULL,@pais=NULL,@huso=NULL;
 THROW 51999,'SP.uspSede_Update acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspSede_Update dejo transaccion abierta.',1;
PRINT 'OK: SP.uspSede_Update';

BEGIN TRY
 EXEC SP.uspSede_Bajar @idSede=NULL;
 THROW 51999,'SP.uspSede_Bajar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspSede_Bajar dejo transaccion abierta.',1;
PRINT 'OK: SP.uspSede_Bajar';

BEGIN TRY
 EXEC SP.uspSeleccion_Registrar @idPais=NULL,@idMundial=NULL,@idGrupo=NULL,@confederacion=NULL;
 THROW 51999,'SP.uspSeleccion_Registrar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspSeleccion_Registrar dejo transaccion abierta.',1;
PRINT 'OK: SP.uspSeleccion_Registrar';

BEGIN TRY
 EXEC SP.uspSeleccion_Update @idSeleccion=NULL,@idPais=NULL,@idMundial=NULL,@idGrupo=NULL,@confederacion=NULL;
 THROW 51999,'SP.uspSeleccion_Update acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspSeleccion_Update dejo transaccion abierta.',1;
PRINT 'OK: SP.uspSeleccion_Update';

BEGIN TRY
 EXEC SP.uspSeleccion_Bajar @idSeleccion=NULL;
 THROW 51999,'SP.uspSeleccion_Bajar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspSeleccion_Bajar dejo transaccion abierta.',1;
PRINT 'OK: SP.uspSeleccion_Bajar';

BEGIN TRY
 EXEC SP.uspAnunciante_Registrar @nombre=NULL,@idPais=NULL;
 THROW 51999,'SP.uspAnunciante_Registrar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspAnunciante_Registrar dejo transaccion abierta.',1;
PRINT 'OK: SP.uspAnunciante_Registrar';

BEGIN TRY
 EXEC SP.uspAnunciante_Update @id=NULL,@nombre=NULL,@idPais=NULL;
 THROW 51999,'SP.uspAnunciante_Update acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspAnunciante_Update dejo transaccion abierta.',1;
PRINT 'OK: SP.uspAnunciante_Update';

BEGIN TRY
 EXEC SP.uspAnunciante_Bajar @id=NULL;
 THROW 51999,'SP.uspAnunciante_Bajar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspAnunciante_Bajar dejo transaccion abierta.',1;
PRINT 'OK: SP.uspAnunciante_Bajar';

BEGIN TRY
 EXEC SP.uspPublicidad_Registrar @nombre=NULL,@idCampania=NULL,@idIdioma=NULL;
 THROW 51999,'SP.uspPublicidad_Registrar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspPublicidad_Registrar dejo transaccion abierta.',1;
PRINT 'OK: SP.uspPublicidad_Registrar';

BEGIN TRY
 EXEC SP.uspPublicidad_Update @id=NULL,@nombre=NULL,@idCampania=NULL,@idIdioma=NULL;
 THROW 51999,'SP.uspPublicidad_Update acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspPublicidad_Update dejo transaccion abierta.',1;
PRINT 'OK: SP.uspPublicidad_Update';

BEGIN TRY
 EXEC SP.uspPublicidad_Bajar @id=NULL;
 THROW 51999,'SP.uspPublicidad_Bajar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspPublicidad_Bajar dejo transaccion abierta.',1;
PRINT 'OK: SP.uspPublicidad_Bajar';

BEGIN TRY
 EXEC SP.uspHablaIdioma_Registrar @arbitro=NULL,@idioma=NULL;
 THROW 51999,'SP.uspHablaIdioma_Registrar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspHablaIdioma_Registrar dejo transaccion abierta.',1;
PRINT 'OK: SP.uspHablaIdioma_Registrar';

BEGIN TRY
 EXEC SP.uspHablaIdioma_Bajar @arbitro=NULL,@idioma=NULL;
 THROW 51999,'SP.uspHablaIdioma_Bajar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspHablaIdioma_Bajar dejo transaccion abierta.',1;
PRINT 'OK: SP.uspHablaIdioma_Bajar';

BEGIN TRY
 EXEC SP.uspReporte_Registrar @razon=NULL,@descripcion=NULL,@arbitro=NULL,@partido=NULL;
 THROW 51999,'SP.uspReporte_Registrar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspReporte_Registrar dejo transaccion abierta.',1;
PRINT 'OK: SP.uspReporte_Registrar';

BEGIN TRY
 EXEC SP.uspReporte_Update @id=NULL,@razon=NULL,@descripcion=NULL;
 THROW 51999,'SP.uspReporte_Update acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspReporte_Update dejo transaccion abierta.',1;
PRINT 'OK: SP.uspReporte_Update';

BEGIN TRY
 EXEC SP.uspReporte_Baja @id=NULL;
 THROW 51999,'SP.uspReporte_Baja acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspReporte_Baja dejo transaccion abierta.',1;
PRINT 'OK: SP.uspReporte_Baja';

BEGIN TRY
 EXEC SP.uspPartido_Registrar @IdFase=NULL,@IdSede=NULL,@IdMundial=NULL,@Eq1=NULL,@Eq2=NULL,@Fecha=NULL,@HoraUTC=NULL,@HoraLocal=NULL,@Asistencia=NULL;
 THROW 51999,'SP.uspPartido_Registrar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspPartido_Registrar dejo transaccion abierta.',1;
PRINT 'OK: SP.uspPartido_Registrar';

BEGIN TRY
 EXEC SP.uspPartido_Update @Id=NULL,@IdFase=NULL,@IdSede=NULL,@IdMundial=NULL,@Eq1=NULL,@Eq2=NULL,@Fecha=NULL,@HoraUTC=NULL,@HoraLocal=NULL,@GolesEq1=NULL,@GolesEq2=NULL,@Asistencia=NULL;
 THROW 51999,'SP.uspPartido_Update acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspPartido_Update dejo transaccion abierta.',1;
PRINT 'OK: SP.uspPartido_Update';

BEGIN TRY
 EXEC SP.uspPartido_Bajar @Id=NULL;
 THROW 51999,'SP.uspPartido_Bajar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspPartido_Bajar dejo transaccion abierta.',1;
PRINT 'OK: SP.uspPartido_Bajar';

BEGIN TRY
 EXEC SP.uspAlineacion_Registrar @IdPartido=NULL,@IdJugador=NULL,@Rol=NULL,@PosicionCancha=NULL,@Esquema=NULL;
 THROW 51999,'SP.uspAlineacion_Registrar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspAlineacion_Registrar dejo transaccion abierta.',1;
PRINT 'OK: SP.uspAlineacion_Registrar';

BEGIN TRY
 EXEC SP.uspAlineacion_Bajar @IdPartido=NULL,@IdJugador=NULL;
 THROW 51999,'SP.uspAlineacion_Bajar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspAlineacion_Bajar dejo transaccion abierta.',1;
PRINT 'OK: SP.uspAlineacion_Bajar';

BEGIN TRY
 EXEC SP.uspPublicidadPais_Registrar @idPublicidad=NULL,@idPais=NULL;
 THROW 51999,'SP.uspPublicidadPais_Registrar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspPublicidadPais_Registrar dejo transaccion abierta.',1;
PRINT 'OK: SP.uspPublicidadPais_Registrar';

BEGIN TRY
 EXEC SP.uspPublicidadPais_Bajar @idPublicidad=NULL,@idPais=NULL;
 THROW 51999,'SP.uspPublicidadPais_Bajar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspPublicidadPais_Bajar dejo transaccion abierta.',1;
PRINT 'OK: SP.uspPublicidadPais_Bajar';

BEGIN TRY
 EXEC SP.uspAnuncianteCampania_Registrar @idAnunciante=NULL,@idCampania=NULL;
 THROW 51999,'SP.uspAnuncianteCampania_Registrar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspAnuncianteCampania_Registrar dejo transaccion abierta.',1;
PRINT 'OK: SP.uspAnuncianteCampania_Registrar';

BEGIN TRY
 EXEC SP.uspAnuncianteCampania_Bajar @idAnunciante=NULL,@idCampania=NULL;
 THROW 51999,'SP.uspAnuncianteCampania_Bajar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspAnuncianteCampania_Bajar dejo transaccion abierta.',1;
PRINT 'OK: SP.uspAnuncianteCampania_Bajar';

BEGIN TRY
 EXEC SP.uspJugador_ClubUpdate @id=NULL,@club=NULL;
 THROW 51999,'SP.uspJugador_ClubUpdate acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspJugador_ClubUpdate dejo transaccion abierta.',1;
PRINT 'OK: SP.uspJugador_ClubUpdate';

BEGIN TRY
 EXEC SP.uspHistorialPublicidad_Bajar @id=NULL;
 THROW 51999,'SP.uspHistorialPublicidad_Bajar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspHistorialPublicidad_Bajar dejo transaccion abierta.',1;
PRINT 'OK: SP.uspHistorialPublicidad_Bajar';

BEGIN TRY
 EXEC SPTRANS.uspJugador_Registrar @nombre=NULL,@fnac=NULL,@pais=NULL,@posicion=NULL,@numero=NULL,@club=NULL,@seleccion=NULL,@estado=NULL;
 THROW 51999,'SPTRANS.uspJugador_Registrar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SPTRANS.uspJugador_Registrar dejo transaccion abierta.',1;
PRINT 'OK: SPTRANS.uspJugador_Registrar';

BEGIN TRY
 EXEC SPTRANS.uspJugador_Update @id=NULL,@nombre=NULL,@fnac=NULL,@pais=NULL,@posicion=NULL,@numero=NULL,@seleccion=NULL;
 THROW 51999,'SPTRANS.uspJugador_Update acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SPTRANS.uspJugador_Update dejo transaccion abierta.',1;
PRINT 'OK: SPTRANS.uspJugador_Update';

BEGIN TRY
 EXEC SPTRANS.uspJugador_Bajar @id=NULL;
 THROW 51999,'SPTRANS.uspJugador_Bajar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SPTRANS.uspJugador_Bajar dejo transaccion abierta.',1;
PRINT 'OK: SPTRANS.uspJugador_Bajar';

BEGIN TRY
 EXEC SPTRANS.uspArbitro_Registrar @nombre=NULL,@fnac=NULL,@pais=NULL,@categoria=NULL;
 THROW 51999,'SPTRANS.uspArbitro_Registrar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SPTRANS.uspArbitro_Registrar dejo transaccion abierta.',1;
PRINT 'OK: SPTRANS.uspArbitro_Registrar';

BEGIN TRY
 EXEC SPTRANS.uspArbitro_Update @id=NULL,@nombre=NULL,@fnac=NULL,@pais=NULL,@categoria=NULL;
 THROW 51999,'SPTRANS.uspArbitro_Update acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SPTRANS.uspArbitro_Update dejo transaccion abierta.',1;
PRINT 'OK: SPTRANS.uspArbitro_Update';

BEGIN TRY
 EXEC SPTRANS.uspArbitro_Bajar @id=NULL;
 THROW 51999,'SPTRANS.uspArbitro_Bajar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SPTRANS.uspArbitro_Bajar dejo transaccion abierta.',1;
PRINT 'OK: SPTRANS.uspArbitro_Bajar';

BEGIN TRY
 EXEC SPTRANS.uspTecnico_Registrar @nombre=NULL,@fnac=NULL,@pais=NULL,@funcion=NULL,@seleccion=NULL;
 THROW 51999,'SPTRANS.uspTecnico_Registrar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SPTRANS.uspTecnico_Registrar dejo transaccion abierta.',1;
PRINT 'OK: SPTRANS.uspTecnico_Registrar';

BEGIN TRY
 EXEC SPTRANS.uspTecnico_Update @id=NULL,@nombre=NULL,@fnac=NULL,@pais=NULL,@funcion=NULL,@seleccion=NULL;
 THROW 51999,'SPTRANS.uspTecnico_Update acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SPTRANS.uspTecnico_Update dejo transaccion abierta.',1;
PRINT 'OK: SPTRANS.uspTecnico_Update';

BEGIN TRY
 EXEC SPTRANS.uspTecnico_Bajar @id=NULL;
 THROW 51999,'SPTRANS.uspTecnico_Bajar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SPTRANS.uspTecnico_Bajar dejo transaccion abierta.',1;
PRINT 'OK: SPTRANS.uspTecnico_Bajar';

BEGIN TRY
 EXEC SPTRANS.uspArbitraje_Registrar @arbitro=NULL,@funcion=NULL,@partido=NULL;
 THROW 51999,'SPTRANS.uspArbitraje_Registrar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SPTRANS.uspArbitraje_Registrar dejo transaccion abierta.',1;
PRINT 'OK: SPTRANS.uspArbitraje_Registrar';

BEGIN TRY
 EXEC SPTRANS.uspArbitraje_Update @arbitro=NULL,@funcion=NULL,@partido=NULL;
 THROW 51999,'SPTRANS.uspArbitraje_Update acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SPTRANS.uspArbitraje_Update dejo transaccion abierta.',1;
PRINT 'OK: SPTRANS.uspArbitraje_Update';

BEGIN TRY
 EXEC SPTRANS.uspArbitraje_Bajar @arbitro=NULL,@partido=NULL;
 THROW 51999,'SPTRANS.uspArbitraje_Bajar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SPTRANS.uspArbitraje_Bajar dejo transaccion abierta.',1;
PRINT 'OK: SPTRANS.uspArbitraje_Bajar';

BEGIN TRY
 EXEC SPTRANS.uspAmonestacion_Registrar @minuto=NULL,@partido=NULL,@periodo=NULL,@amonestado=NULL,@arbitro=NULL,@tarjeta=NULL,@motivo=NULL;
 THROW 51999,'SPTRANS.uspAmonestacion_Registrar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SPTRANS.uspAmonestacion_Registrar dejo transaccion abierta.',1;
PRINT 'OK: SPTRANS.uspAmonestacion_Registrar';

BEGIN TRY
 EXEC SPTRANS.uspAmonestacion_UpdateTiempo @id=NULL,@minuto=NULL,@periodo=NULL;
 THROW 51999,'SPTRANS.uspAmonestacion_UpdateTiempo acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SPTRANS.uspAmonestacion_UpdateTiempo dejo transaccion abierta.',1;
PRINT 'OK: SPTRANS.uspAmonestacion_UpdateTiempo';

BEGIN TRY
 EXEC SPTRANS.uspAmonestacion_UpdateMotivo @id=NULL,@motivo=NULL;
 THROW 51999,'SPTRANS.uspAmonestacion_UpdateMotivo acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SPTRANS.uspAmonestacion_UpdateMotivo dejo transaccion abierta.',1;
PRINT 'OK: SPTRANS.uspAmonestacion_UpdateMotivo';

BEGIN TRY
 EXEC SPTRANS.uspAmonestacion_Bajar @id=NULL;
 THROW 51999,'SPTRANS.uspAmonestacion_Bajar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SPTRANS.uspAmonestacion_Bajar dejo transaccion abierta.',1;
PRINT 'OK: SPTRANS.uspAmonestacion_Bajar';

BEGIN TRY
 EXEC SPTRANS.uspGol_Bajar @id=NULL;
 THROW 51999,'SPTRANS.uspGol_Bajar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SPTRANS.uspGol_Bajar dejo transaccion abierta.',1;
PRINT 'OK: SPTRANS.uspGol_Bajar';

BEGIN TRY
 EXEC SP.uspPartido_Tanda @IdPartido=NULL,@Iniciar=NULL;
 THROW 51999,'SP.uspPartido_Tanda acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SP.uspPartido_Tanda dejo transaccion abierta.',1;
PRINT 'OK: SP.uspPartido_Tanda';

BEGIN TRY
 EXEC SPTRANS.uspSustitucion_Registrar @minuto=NULL,@partido=NULL,@periodo=NULL,@ingreso=NULL,@egreso=NULL,@motivo=NULL;
 THROW 51999,'SPTRANS.uspSustitucion_Registrar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SPTRANS.uspSustitucion_Registrar dejo transaccion abierta.',1;
PRINT 'OK: SPTRANS.uspSustitucion_Registrar';

BEGIN TRY
 EXEC SPTRANS.uspSustitucion_Bajar @id=NULL;
 THROW 51999,'SPTRANS.uspSustitucion_Bajar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SPTRANS.uspSustitucion_Bajar dejo transaccion abierta.',1;
PRINT 'OK: SPTRANS.uspSustitucion_Bajar';

BEGIN TRY
 EXEC SPTRANS.uspCambioConvocatoria_Registrar @seleccion=NULL,@egreso=NULL,@ingreso=NULL,@fecha=NULL,@motivo=NULL;
 THROW 51999,'SPTRANS.uspCambioConvocatoria_Registrar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SPTRANS.uspCambioConvocatoria_Registrar dejo transaccion abierta.',1;
PRINT 'OK: SPTRANS.uspCambioConvocatoria_Registrar';

BEGIN TRY
 EXEC SPTRANS.uspCambioConvocatoria_Bajar @id=NULL;
 THROW 51999,'SPTRANS.uspCambioConvocatoria_Bajar acepto entrada nula.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 51999,'SPTRANS.uspCambioConvocatoria_Bajar dejo transaccion abierta.',1;
PRINT 'OK: SPTRANS.uspCambioConvocatoria_Bajar';

BEGIN TRY
 EXEC SP.uspFase_Update NULL,NULL;
 THROW 51999,'Se esperaba rechazo de fase.',1;
END TRY
BEGIN CATCH
 IF ERROR_MESSAGE() NOT LIKE '%Id%' OR ERROR_MESSAGE() NOT LIKE '%Descripcion%' THROW;
END CATCH;
BEGIN TRY
 EXEC SP.uspPublicidad_Registrar NULL,-1,-1;
 THROW 51999,'Se esperaba rechazo de publicidad.',1;
END TRY
BEGIN CATCH
 IF ERROR_MESSAGE() NOT LIKE '%Nombre%' OR ERROR_MESSAGE() NOT LIKE '%Campania%' OR ERROR_MESSAGE() NOT LIKE '%Idioma%' THROW;
END CATCH;
PRINT 'Validaciones: 77 rechazos y dos mensajes multiples comprobados.';
