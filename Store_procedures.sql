use db_mundial;
go

----------------------------------------------------------
----------STORE PROCEDURE DE SELECCION--------------------
----------------------------------------------------------

create or alter procedure dbo.sp_Seleccion_Alta
	@ID_PAIS INT,
	@ID_MUNDIAL INT,
	@ID_GRUPO INT, 
	@CONFEDERACION VARCHAR(45)
as
begin
	SET NOCOUNT ON;
    DECLARE @ERRORES VARCHAR(400) = '';

    IF NOT EXISTS (SELECT 1 FROM dbo.Pais WHERE ID_PAIS = @ID_PAIS)
        SET @ERRORES += '- El pais indicado no existe. ';

    IF NOT EXISTS (SELECT 1 FROM dbo.Mundial WHERE ID_MUNDIAL = @ID_MUNDIAL)
        SET @ERRORES += '- El mundial indicado no existe. ';

    IF NOT EXISTS (SELECT 1 FROM dbo.Grupo WHERE ID_GRUPO = @ID_GRUPO)
        SET @ERRORES += '- El grupo indicado no existe. ';

    IF EXISTS (SELECT 1 FROM dbo.Seleccion
               WHERE ID_PAIS = @ID_PAIS AND ID_MUNDIAL = @ID_MUNDIAL)
        SET @ERRORES += '- Ese pais ya tiene una seleccion en este mundial. ';

    IF @CONFEDERACION IS NULL OR LTRIM(RTRIM(@CONFEDERACION)) = ''
        SET @ERRORES += '- La confederacion es obligatoria. ';

    IF (SELECT COUNT(*) FROM dbo.Seleccion
        WHERE ID_MUNDIAL = @ID_MUNDIAL AND ID_GRUPO = @ID_GRUPO) >= 4
        SET @ERRORES += '- El grupo ya tiene 4 selecciones en este mundial. ';

    IF @ERRORES <> ''
        THROW 50001, @ERRORES, 1;

    INSERT INTO dbo.Seleccion (ID_PAIS, ID_MUNDIAL, ID_GRUPO, CONFEDERACION)
    VALUES (@ID_PAIS, @ID_MUNDIAL, @ID_GRUPO, LTRIM(RTRIM(@CONFEDERACION)));

    SELECT SCOPE_IDENTITY() AS ID_SELECCION_NUEVA;

end
go

create or alter procedure dbo.sp_Seleccion_Baja
	@ID_SELECCION INT
as
begin
    SET NOCOUNT ON;
    DECLARE @ERROR VARCHAR(2000) = '';
    --SE PONE 2K DE CARACTERES PARA FUTUROS MENSAJES DE ERROR
    IF NOT EXISTS (select 1 from dbo.Seleccion where ID_SELECCION = @ID_SELECCION)
        SET @ERROR += '- Seleccion indicada no existe ';

    --INSERTAR MUCHISIMAS MAS VALIDACIONES ASOCIADAS CON ESTA SELECCION

    IF @ERROR <> ''
        THROW 50001, @ERROR, 1;

    delete from dbo.Seleccion where ID_SELECCION = @ID_SELECCION;
end
go

create or alter procedure dbo.sp_Seleccion_Modificacion
	@ID_SELECCION INT,
	@ID_GRUPO INT,
	@CONFEDERACION VARCHAR(45)
AS
BEGIN 
    SET NOCOUNT ON;
    DECLARE @ERRORES VARCHAR(1000) = '';

END