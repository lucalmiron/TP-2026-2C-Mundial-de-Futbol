-- Universidad Nacional de La Matanza
-- Bases de datos aplicada 
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 08/10/2026
-- Objetivo: SP Sede.

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO
if exists (select name from sys.objects where object_id = object_id('SP.uspSede_Registrar'))
    drop procedure SP.uspSede_Registrar
go
create procedure SP.uspSede_Registrar
    @nombre    varchar(30),
    @ciudad    varchar(30),
    @capacidad int,
    @pais      int,
    @huso      int
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

    if (@pais is null) or (@pais <= 0)
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
        if not exists(select 1 from equipos.Pais where IdPais = @pais)
        begin
            set @errorCount = @errorCount + 1
            set @errorLine = @errorLine + char(13) + '- Valor inexistente: Pais.'
        end

        if not exists(select 1 from sedes.HusoHorario where IdHuso = @huso)
        begin
            set @errorCount = @errorCount + 1
            set @errorLine = @errorLine + char(13) + '- Valor inexistente: Huso horario.'
        end
    end

    -- chequeo dup
    if (@errorCount = 0)
    begin
        if exists(select 1 from sedes.Sede where Nombre = @nombre and Ciudad = @ciudad)
        begin
            set @errorCount = @errorCount + 1
            set @errorLine = @errorLine + char(13) + '- Valor duplicado: Sede (nombre y ciudad).'
        end
    end

    if (@errorCount = 0)
    begin
        begin try
            insert into sedes.Sede (Nombre, Ciudad, Capacidad, IdPais, IdHuso)
            values (@nombre, @ciudad, @capacidad, @pais, @huso)
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
if exists (select name from sys.objects where object_id = object_id('SP.uspSede_Update'))
    drop procedure SP.uspSede_Update
go
create procedure SP.uspSede_Update
    @idSede    int,
    @nombre    varchar(30) = null,
    @ciudad    varchar(30) = null,
    @capacidad int = null,
    @pais      int = null,
    @huso      int = null
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

    -- chequeo existencia
    if (@errorCount = 0)
    begin
        if not exists(select 1 from sedes.Sede where IdSede = @idSede)
        begin
            set @errorCount = @errorCount + 1
            set @errorLine = @errorLine + char(13) + '- Valor inexistente: IdSede.'
        end

        if (@pais is not null) and not exists(select 1 from equipos.Pais where IdPais = @pais)
        begin
            set @errorCount = @errorCount + 1
            set @errorLine = @errorLine + char(13) + '- Valor inexistente: Pais.'
        end

        if (@huso is not null) and not exists(select 1 from sedes.HusoHorario where IdHuso = @huso)
        begin
            set @errorCount = @errorCount + 1
            set @errorLine = @errorLine + char(13) + '- Valor inexistente: Huso horario.'
        end
    end

    -- chequeo dup (solo si me pasaron nombre y ciudad juntos)
    if (@errorCount = 0) and (@nombre is not null) and (@ciudad is not null)
    begin
        if exists(select 1 from sedes.Sede
                  where Nombre = @nombre and Ciudad = @ciudad and IdSede <> @idSede)
        begin
            set @errorCount = @errorCount + 1
            set @errorLine = @errorLine + char(13) + '- Valor duplicado: Sede (nombre y ciudad).'
        end
    end

    if (@errorCount = 0)
    begin
        begin try
            update sedes.Sede
            set Nombre    = coalesce(@nombre, Nombre),
                Ciudad    = coalesce(@ciudad, Ciudad),
                Capacidad = coalesce(@capacidad, Capacidad),
                IdPais    = coalesce(@pais, IdPais),
                IdHuso    = coalesce(@huso, IdHuso)
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
    if (@errorCount = 0) and not exists(select 1 from sedes.Sede where IdSede = @idSede)
    begin
        set @errorCount = @errorCount + 1
        set @errorLine = @errorLine + char(13) + '- Valor inexistente: IdSede.'
    end

    -- chequeo relaciones (si hay registros hijos, no se puede dar de baja)
    if (@errorCount = 0)
    begin
        if exists(select 1 from partidos.Partido where IdSede = @idSede)
        begin
            set @errorCount = @errorCount + 1
            set @errorLine = @errorLine + char(13) + '- Existen 1 o mas registros relacionados: Partido. Elimine dichos registros para continuar.'
        end
    end

    if (@errorCount = 0)
    begin
        begin try
            delete from sedes.Sede
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