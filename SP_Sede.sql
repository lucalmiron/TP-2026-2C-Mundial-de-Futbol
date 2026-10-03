-- Universidad Nacional de La Matanza
-- Bases de datos aplicada 
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 03/10/2026
-- Objetivo: SP Sede.

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'mundial')
BEGIN
	USE mundial
END;
GO
if exists (select name from sys.objects where object_id = object_id('SP.Sede_Registrar'))
    drop procedure SP.Sede_Registrar
go
create procedure SP.Sede_Registrar
    @nombre    varchar(30),
    @ciudad    varchar(30),
    @capacidad int
    --@pais      int,
    --@huso      int
as
begin
    declare @errorCount int
    declare @errorLine varchar(800)

    set @errorCount = 0
    set @errorLine = 'Error/es:'

    -- chequeo validez
    if (@nombre is null) or (ltrim(rtrim(@nombre)) = '')
    begin
        set @errorCount = @errorCount + 1
        set @errorLine = @errorLine + char(13) + '- Valor invalido: Nombre.'
    end

    if (@ciudad is null) or (ltrim(rtrim(@ciudad)) = '')
    begin
        set @errorCount = @errorCount + 1
        set @errorLine = @errorLine + char(13) + '- Valor invalido: Ciudad.'
    end

    if (@capacidad is null) or (@capacidad <= 0)
    begin
        set @errorCount = @errorCount + 1
        set @errorLine = @errorLine + char(13) + '- Valor invalido: Capacidad.'
    end

    /*if (@pais is null) or (@pais <= 0)
    begin
        set @errorCount = @errorCount + 1
        set @errorLine = @errorLine + char(13) + '- Valor invalido: Pais.'
    end

    if (@huso is null) or (@huso <= 0)
    begin
        set @errorCount = @errorCount + 1
        set @errorLine = @errorLine + char(13) + '- Valor invalido: Huso horario.'
    end

    -- chequeo existencia
    if (@errorCount = 0)
    begin
        if not exists(select 1 from TABLAS.Pais where IdPais = @pais)
        begin
            set @errorCount = @errorCount + 1
            set @errorLine = @errorLine + char(13) + '- Valor inexistente: Pais.'
        end

        if not exists(select 1 from TABLAS.HusoHorario where IdHuso = @huso)
        begin
            set @errorCount = @errorCount + 1
            set @errorLine = @errorLine + char(13) + '- Valor inexistente: Huso horario.'
        end
    end
    */
    -- chequeo dup
    if (@errorCount = 0)
    begin
        if exists(select 1 from TABLAS.Sede where Nombre = @nombre and Ciudad = @ciudad)
        begin
            set @errorCount = @errorCount + 1
            set @errorLine = @errorLine + char(13) + '- Valor duplicado: Sede (nombre y ciudad).'
        end
    end

    if (@errorCount = 0)
    begin
        begin try
            insert into TABLAS.Sede (Nombre, Ciudad, Capacidad)
            --saque pais y huso por ahora
            values (@nombre, @ciudad, @capacidad)
        end try
        begin catch
            print concat('ERROR (', error_number(), '): ', error_message())
        end catch
    end
    else
        print @errorLine
end;
go


-- modificacion de sede
if exists (select name from sys.objects where object_id = object_id('SP.Sede_Update'))
    drop procedure SP.Sede_Update
go
create procedure SP.Sede_Update
    @idSede    int,
    @nombre    varchar(30) = null,
    @ciudad    varchar(30) = null,
    @capacidad int = null
    --@pais      int = null,
    --@huso      int = null
as
begin
    declare @errorCount int
    declare @errorLine varchar(800)

    set @errorCount = 0
    set @errorLine = 'Error/es:'

    -- chequeo validez (solo lo que vino con valor)
    if (@idSede is null) or (@idSede <= 0)
    begin
        set @errorCount = @errorCount + 1
        set @errorLine = @errorLine + char(13) + '- Valor invalido: IdSede.'
    end

    if (@capacidad is not null) and (@capacidad <= 0)
    begin
        set @errorCount = @errorCount + 1
        set @errorLine = @errorLine + char(13) + '- Valor invalido: Capacidad.'
    end
    /*
    if (@pais is not null) and (@pais <= 0)
    begin
        set @errorCount = @errorCount + 1
        set @errorLine = @errorLine + char(13) + '- Valor invalido: Pais.'
    end

    if (@huso is not null) and (@huso <= 0)
    begin
        set @errorCount = @errorCount + 1
        set @errorLine = @errorLine + char(13) + '- Valor invalido: Huso horario.'
    end
    */
    -- chequeo existencia
    if (@errorCount = 0)
    begin
        if not exists(select 1 from TABLAS.Sede where IdSede = @idSede)
        begin
            set @errorCount = @errorCount + 1
            set @errorLine = @errorLine + char(13) + '- Valor inexistente: IdSede.'
        end
    /*
        if (@pais is not null) and not exists(select 1 from TABLAS.Pais where IdPais = @pais)
        begin
            set @errorCount = @errorCount + 1
            set @errorLine = @errorLine + char(13) + '- Valor inexistente: Pais.'
        end

        if (@huso is not null) and not exists(select 1 from TABLAS.HusoHorario where IdHuso = @huso)
        begin
            set @errorCount = @errorCount + 1
            set @errorLine = @errorLine + char(13) + '- Valor inexistente: Huso horario.'
        end
    */
    end

    -- chequeo dup (solo si me pasaron nombre y ciudad juntos)
    if (@errorCount = 0) and (@nombre is not null) and (@ciudad is not null)
    begin
        if exists(select 1 from TABLAS.Sede
                  where Nombre = @nombre and Ciudad = @ciudad and IdSede <> @idSede)
        begin
            set @errorCount = @errorCount + 1
            set @errorLine = @errorLine + char(13) + '- Valor duplicado: Sede (nombre y ciudad).'
        end
    end

    if (@errorCount = 0)
    begin
        begin try
            update TABLAS.Sede
            set Nombre    = coalesce(@nombre, Nombre),
                Ciudad    = coalesce(@ciudad, Ciudad),
                Capacidad = coalesce(@capacidad, Capacidad)
                --IdPais    = coalesce(@pais, IdPais),
                --IdHuso    = coalesce(@huso, IdHuso)
            where IdSede = @idSede
        end try
        begin catch
            print concat('ERROR (', error_number(), '): ', error_message())
        end catch
    end
    else
        print @errorLine
end;
go

-- baja de sede
if exists (select name from sys.objects where object_id = object_id('SP.uspSede_Bajar'))
    drop procedure SP.uspSede_Bajar
go
create procedure SP.uspSede_Bajar
    @idSede int
as
begin
    declare @errorCount int
    declare @errorLine varchar(800)

    set @errorCount = 0
    set @errorLine = 'Error/es:'

    -- chequeo validez
    if (@idSede is null) or (@idSede <= 0)
    begin
        set @errorCount = @errorCount + 1
        set @errorLine = @errorLine + char(13) + '- Valor invalido: IdSede.'
    end

    -- chequeo existencia
    if (@errorCount = 0) and not exists(select 1 from TABLAS.Sede where IdSede = @idSede)
    begin
        set @errorCount = @errorCount + 1
        set @errorLine = @errorLine + char(13) + '- Valor inexistente: IdSede.'
    end

    -- chequeo relaciones (si hay registros hijos, no se puede dar de baja)
    /*
    if (@errorCount = 0)
    begin
    /*
        if exists(select 1 from TABLAS.Partido where Sede = @idSede)
        begin
            set @errorCount = @errorCount + 1
            set @errorLine = @errorLine + char(13) + '- Existen 1 o mas registros relacionados: Partido. Elimine dichos registros para continuar.'
        end
    */
    /*
        if exists(select 1 from TABLAS.EspacioPublicitario where IdSede = @idSede)
        begin
            set @errorCount = @errorCount + 1
            set @errorLine = @errorLine + char(13) + '- Existen 1 o mas registros relacionados: Espacio Publicitario. Elimine dichos registros para continuar.'
        end

        if exists(select 1 from TABLAS.CostoFranja where IdSede = @idSede)
        begin
            set @errorCount = @errorCount + 1
            set @errorLine = @errorLine + char(13) + '- Existen 1 o mas registros relacionados: Costo Franja. Elimine dichos registros para continuar.'
        end
    */
    --comento por ahora ya que espacio publicitario y costofranja estan defectuosos , debo repensarlos
    end
    */
    --comento esto tambien ya que no se ejecuta nada 
    if (@errorCount = 0)
    begin
        begin try
            delete from TABLAS.Sede
            where IdSede = @idSede
        end try
        begin catch
            print concat('ERROR (', error_number(), '): ', error_message())
        end catch
    end
    else
        print @errorLine
end;
go