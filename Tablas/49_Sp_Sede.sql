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
	BEGIN TRY
		-- chequeo validez
		IF (@nombre IS NULL) OR (LTRIM(RTRIM(@nombre)) = '')
			THROW 50000, '- Valor invalido: Nombre.', 1;

		IF (@ciudad IS NULL) OR (LTRIM(RTRIM(@ciudad)) = '')
			THROW 50000, '- Valor invalido: Ciudad.', 1;

		IF (@capacidad IS NULL) OR (@capacidad <= 0)
			THROW 50000, '- Valor invalido: Capacidad.', 1;

		IF (@pais IS NULL) OR (@pais <= 0)
			THROW 50000, '- Valor invalido: Pais.', 1;

		IF (@huso IS NULL) OR (@huso <= 0)
			THROW 50000, '- Valor invalido: Huso horario.', 1;

		-- chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @pais)
			THROW 50000, '- Valor inexistente: Pais.', 1;

		IF NOT EXISTS(SELECT 1 FROM sedes.HusoHorario WHERE IdHuso = @huso)
			THROW 50000, '- Valor inexistente: Huso horario.', 1;

		-- chequeo dup
		IF EXISTS(SELECT 1 FROM sedes.Sede WHERE Nombre = @nombre AND Ciudad = @ciudad)
			THROW 50000, '- Valor duplicado: Sede (nombre y ciudad).', 1;

		INSERT INTO sedes.Sede (Nombre, Ciudad, Capacidad, IdPais, IdHuso)
		VALUES (@nombre, @ciudad, @capacidad, @pais, @huso)
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
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
	BEGIN TRY
		-- chequeo validez (solo lo que vino con valor)
		IF (@idSede IS NULL) OR (@idSede <= 0)
			THROW 50000, '- Valor invalido: IdSede.', 1;

		IF (@capacidad IS NOT NULL) AND (@capacidad <= 0)
			THROW 50000, '- Valor invalido: Capacidad.', 1;

		IF (@pais IS NOT NULL) AND (@pais <= 0)
			THROW 50000, '- Valor invalido: Pais.', 1;

		IF (@huso IS NOT NULL) AND (@huso <= 0)
			THROW 50000, '- Valor invalido: Huso horario.', 1;

		-- chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM sedes.Sede WHERE IdSede = @idSede)
			THROW 50000, '- Valor inexistente: IdSede.', 1;

		IF (@pais IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @pais)
			THROW 50000, '- Valor inexistente: Pais.', 1;

		IF (@huso IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM sedes.HusoHorario WHERE IdHuso = @huso)
			THROW 50000, '- Valor inexistente: Huso horario.', 1;

		-- chequeo dup (solo si me pasaron nombre y ciudad juntos)
		IF (@nombre IS NOT NULL) AND (@ciudad IS NOT NULL)
		BEGIN
			IF EXISTS(SELECT 1 FROM sedes.Sede
				WHERE Nombre = @nombre AND Ciudad = @ciudad AND IdSede <> @idSede)
				THROW 50000, '- Valor duplicado: Sede (nombre y ciudad).', 1;
		END

		UPDATE sedes.Sede
		SET Nombre    = COALESCE(@nombre, Nombre),
			Ciudad    = COALESCE(@ciudad, Ciudad),
			Capacidad = COALESCE(@capacidad, Capacidad),
			IdPais    = COALESCE(@pais, IdPais),
			IdHuso    = COALESCE(@huso, IdHuso)
		WHERE IdSede = @idSede
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
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
	BEGIN TRY
		-- chequeo validez
		IF (@idSede IS NULL) OR (@idSede <= 0)
			THROW 50000, '- Valor invalido: IdSede.', 1;

		-- chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM sedes.Sede WHERE IdSede = @idSede)
			THROW 50000, '- Valor inexistente: IdSede.', 1;

		-- chequeo relaciones (si hay registros hijos, no se puede dar de baja)
		IF EXISTS(SELECT 1 FROM partidos.Partido WHERE IdSede = @idSede)
			THROW 50000, '- Existen 1 o mas registros relacionados: Partido. Elimine dichos registros para continuar.', 1;

		IF EXISTS(SELECT 1 FROM publicidad.EspacioPublicitario WHERE IdSede = @idSede)
			THROW 50000, '- Existen 1 o mas registros relacionados: EspacioPublicitario. Elimine dichos registros para continuar.', 1;

		IF EXISTS(SELECT 1 FROM publicidad.CostoFranja WHERE IdSede = @idSede)
			THROW 50000, '- Existen 1 o mas registros relacionados: CostoFranja. Elimine dichos registros para continuar.', 1;

		DELETE FROM sedes.Sede
		WHERE IdSede = @idSede
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
end;
go