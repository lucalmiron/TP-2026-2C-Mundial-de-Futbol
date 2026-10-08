-- Universidad Nacional de La Matanza
-- Bases de datos aplicada
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 08/10/2026
-- Objetivo: SP costo franja

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'mundial')
BEGIN
	USE mundial
END;
GO

-- alta de costo franja
if exists (select name from sys.objects where object_id = object_id('SP.CostoFranja_Registrar'))
    drop procedure SP.CostoFranja_Registrar
go
create procedure SP.CostoFranja_Registrar
    @tipoFranja varchar(30),
    @costo      decimal(10,2)
as
begin
    declare @errorCount int
    declare @errorLine varchar(800)

    set @errorCount = 0
    set @errorLine = 'Error/es:'

    -- chequeo validez
    if (@tipoFranja is null) or (ltrim(rtrim(@tipoFranja)) = '')
    begin
        set @errorCount = @errorCount + 1
        set @errorLine = @errorLine + char(13) + '- Valor invalido: Tipo de franja.'
    end

    if (@costo is null) or (@costo <= 0)
    begin
        set @errorCount = @errorCount + 1
        set @errorLine = @errorLine + char(13) + '- Valor invalido: Costo.'
    end

    -- chequeo dup
    if (@errorCount = 0)
    begin
        if exists(select 1 from TABLAS.CostoFranja where TipoFranja = @tipoFranja)
        begin
            set @errorCount = @errorCount + 1
            set @errorLine = @errorLine + char(13) + '- Valor duplicado: Tipo de franja.'
        end
    end

    if (@errorCount = 0)
    begin
        begin try
            insert into TABLAS.CostoFranja (TipoFranja, Costo)
            values (@tipoFranja, @costo)
        end try
        begin catch
            print concat('ERROR (', error_number(), '): ', error_message())
        end catch
    end
    else
        print @errorLine
end;
GO

-- modificacion de costo franja
if exists (select name from sys.objects where object_id = object_id('SP.CostoFranja_Update'))
    drop procedure SP.CostoFranja_Update
go
create procedure SP.CostoFranja_Update
    @idCF       int,
    @tipoFranja varchar(30) = null,
    @costo      decimal(10,2) = null
as
begin
    declare @errorCount int
    declare @errorLine varchar(800)

    set @errorCount = 0
    set @errorLine = 'Error/es:'

    -- chequeo validez (solo lo que vino con valor)
    if (@idCF is null) or (@idCF <= 0)
    begin
        set @errorCount = @errorCount + 1
        set @errorLine = @errorLine + char(13) + '- Valor invalido: IdCF.'
    end

    if (@tipoFranja is not null) and (ltrim(rtrim(@tipoFranja)) = '')
    begin
        set @errorCount = @errorCount + 1
        set @errorLine = @errorLine + char(13) + '- Valor invalido: Tipo de franja.'
    end

    if (@costo is not null) and (@costo <= 0)
    begin
        set @errorCount = @errorCount + 1
        set @errorLine = @errorLine + char(13) + '- Valor invalido: Costo.'
    end

    -- chequeo existencia
    if (@errorCount = 0) and not exists(select 1 from TABLAS.CostoFranja where IdCF = @idCF)
    begin
        set @errorCount = @errorCount + 1
        set @errorLine = @errorLine + char(13) + '- Valor inexistente: IdCF.'
    end

    -- chequeo dup (solo si me pasaron tipoFranja)
    if (@errorCount = 0) and (@tipoFranja is not null)
    begin
        if exists(select 1 from TABLAS.CostoFranja
                  where TipoFranja = @tipoFranja and IdCF <> @idCF)
        begin
            set @errorCount = @errorCount + 1
            set @errorLine = @errorLine + char(13) + '- Valor duplicado: Tipo de franja.'
        end
    end

    if (@errorCount = 0)
    begin
        begin try
            update TABLAS.CostoFranja
            set TipoFranja = coalesce(@tipoFranja, TipoFranja),
                Costo      = coalesce(@costo, Costo)
            where IdCF = @idCF
        end try
        begin catch
            print concat('ERROR (', error_number(), '): ', error_message())
        end catch
    end
    else
        print @errorLine
end;
GO

-- baja de costo franja
if exists (select name from sys.objects where object_id = object_id('SP.CostoFranja_Bajar'))
    drop procedure SP.CostoFranja_Bajar
go
create procedure SP.CostoFranja_Bajar
    @idCF int
as
begin
    declare @errorCount int
    declare @errorLine varchar(800)

    set @errorCount = 0
    set @errorLine = 'Error/es:'

    -- chequeo validez
    if (@idCF is null) or (@idCF <= 0)
    begin
        set @errorCount = @errorCount + 1
        set @errorLine = @errorLine + char(13) + '- Valor invalido: IdCF.'
    end

    -- chequeo existencia
    if (@errorCount = 0) and not exists(select 1 from TABLAS.CostoFranja where IdCF = @idCF)
    begin
        set @errorCount = @errorCount + 1
        set @errorLine = @errorLine + char(13) + '- Valor inexistente: IdCF.'
    end

    -- (sin chequeo de relaciones: ninguna tabla depende de CostoFranja)

    if (@errorCount = 0)
    begin
        begin try
            delete from TABLAS.CostoFranja
            where IdCF = @idCF
        end try
        begin catch
            print concat('ERROR (', error_number(), '): ', error_message())
        end catch
    end
    else
        print @errorLine
end;
GO