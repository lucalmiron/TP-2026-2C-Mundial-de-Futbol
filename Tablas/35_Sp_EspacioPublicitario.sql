-- Universidad Nacional de La Matanza
-- Bases de datos aplicada
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 08/10/2026
-- Objetivo: SP espacio publicitario

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'mundial')
BEGIN
	USE mundial
END;
GO

-- alta de espacio publicitario
if exists (select name from sys.objects where object_id = object_id('SP.EspacioPublicitario_Registrar'))
    drop procedure SP.EspacioPublicitario_Registrar
go
create procedure SP.EspacioPublicitario_Registrar
    @tipo  varchar(30),
    @costo decimal(10,2)
as
begin
    declare @errorCount int
    declare @errorLine varchar(800)

    set @errorCount = 0
    set @errorLine = 'Error/es:'

    -- chequeo validez
    if (@tipo is null) or (ltrim(rtrim(@tipo)) = '')
    begin
        set @errorCount = @errorCount + 1
        set @errorLine = @errorLine + char(13) + '- Valor invalido: Tipo.'
    end

    if (@costo is null) or (@costo <= 0)
    begin
        set @errorCount = @errorCount + 1
        set @errorLine = @errorLine + char(13) + '- Valor invalido: Costo.'
    end

    -- chequeo dup
    if (@errorCount = 0)
    begin
        if exists(select 1 from publicidad.EspacioPublicitario where Tipo = @tipo)
        begin
            set @errorCount = @errorCount + 1
            set @errorLine = @errorLine + char(13) + '- Valor duplicado: Tipo de espacio.'
        end
    end

    if (@errorCount = 0)
    begin
        begin try
            insert into publicidad.EspacioPublicitario (Tipo, Costo)
            values (@tipo, @costo)
        end try
        begin catch
            print concat('ERROR (', error_number(), '): ', error_message())
        end catch
    end
    else
        print @errorLine
end;
GO

-- modificacion de espacio publicitario
if exists (select name from sys.objects where object_id = object_id('SP.EspacioPublicitario_Update'))
    drop procedure SP.EspacioPublicitario_Update
go
create procedure SP.EspacioPublicitario_Update
    @idEP  int,
    @tipo  varchar(30) = null,
    @costo decimal(10,2) = null
as
begin
    declare @errorCount int
    declare @errorLine varchar(800)

    set @errorCount = 0
    set @errorLine = 'Error/es:'

    -- chequeo validez (solo lo que vino con valor)
    if (@idEP is null) or (@idEP <= 0)
    begin
        set @errorCount = @errorCount + 1
        set @errorLine = @errorLine + char(13) + '- Valor invalido: IdEP.'
    end

    if (@tipo is not null) and (ltrim(rtrim(@tipo)) = '')
    begin
        set @errorCount = @errorCount + 1
        set @errorLine = @errorLine + char(13) + '- Valor invalido: Tipo.'
    end

    if (@costo is not null) and (@costo <= 0)
    begin
        set @errorCount = @errorCount + 1
        set @errorLine = @errorLine + char(13) + '- Valor invalido: Costo.'
    end

    -- chequeo existencia
    if (@errorCount = 0) and not exists(select 1 from publicidad.EspacioPublicitario where IdEP = @idEP)
    begin
        set @errorCount = @errorCount + 1
        set @errorLine = @errorLine + char(13) + '- Valor inexistente: IdEP.'
    end

    -- chequeo dup (solo si me pasaron tipo)
    if (@errorCount = 0) and (@tipo is not null)
    begin
        if exists(select 1 from publicidad.EspacioPublicitario
                  where Tipo = @tipo and IdEP <> @idEP)
        begin
            set @errorCount = @errorCount + 1
            set @errorLine = @errorLine + char(13) + '- Valor duplicado: Tipo de espacio.'
        end
    end

    if (@errorCount = 0)
    begin
        begin try
            update publicidad.EspacioPublicitario
            set Tipo  = coalesce(@tipo, Tipo),
                Costo = coalesce(@costo, Costo)
            where IdEP = @idEP
        end try
        begin catch
            print concat('ERROR (', error_number(), '): ', error_message())
        end catch
    end
    else
        print @errorLine
end;
GO

-- baja de espacio publicitario
if exists (select name from sys.objects where object_id = object_id('SP.Espacio_Bajar'))
    drop procedure SP.EspacioPublicitario_Bajar
go
create procedure SP.EspacioPublicitario_Bajar
    @idEP int
as
begin
    declare @errorCount int
    declare @errorLine varchar(800)

    set @errorCount = 0
    set @errorLine = 'Error/es:'

    -- chequeo validez
    if (@idEP is null) or (@idEP <= 0)
    begin
        set @errorCount = @errorCount + 1
        set @errorLine = @errorLine + char(13) + '- Valor invalido: IdEP.'
    end

    -- chequeo existencia
    if (@errorCount = 0) and not exists(select 1 from publicidad.EspacioPublicitario where IdEP = @idEP)
    begin
        set @errorCount = @errorCount + 1
        set @errorLine = @errorLine + char(13) + '- Valor inexistente: IdEP.'
    end

    -- chequeo relaciones (si hay registros hijos, no se puede dar de baja)
    /*
    if (@errorCount = 0)
    begin
        -- Si publicidad.HistorialPublicidad todavia no existe, comentar este bloque.
        -- Ajustar 'IdEP' al nombre real de la columna en HistorialPublicidad.
        if exists(select 1 from publicidad.HistorialPublicidad where IdEP = @idEP)
        begin
            set @errorCount = @errorCount + 1
            set @errorLine = @errorLine + char(13) + '- Existen 1 o mas registros relacionados: Historial Publicidad. Elimine dichos registros para continuar.'
        end
    end
    */
    if (@errorCount = 0)
    begin
        begin try
            delete from publicidad.EspacioPublicitario
            where IdEP = @idEP
        end try
        begin catch
            print concat('ERROR (', error_number(), '): ', error_message())
        end catch
    end
    else
        print @errorLine
end;
GO