-- Universidad Nacional de La Matanza
-- Bases de datos aplicada 
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 26/10/26
-- Objetivo: SP Sede.

-- Ejecutar en la base seleccionada por el instalador.
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
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		-- chequeo validez
		IF (@nombre IS NULL) OR (LTRIM(RTRIM(@nombre)) = '')
			SET @errores += '- Valor invalido: Nombre.' + N' ';

		IF (@ciudad IS NULL) OR (LTRIM(RTRIM(@ciudad)) = '')
			SET @errores += '- Valor invalido: Ciudad.' + N' ';

		IF (@capacidad IS NULL) OR (@capacidad <= 0)
			SET @errores += '- Valor invalido: Capacidad.' + N' ';

		IF (@pais IS NULL) OR (@pais <= 0)
			SET @errores += '- Valor invalido: Pais.' + N' ';

		IF (@huso IS NULL) OR (@huso <= 0)
			SET @errores += '- Valor invalido: Huso horario.' + N' ';

		-- chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @pais)
			SET @errores += '- Valor inexistente: Pais.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM sedes.HusoHorario WHERE IdHuso = @huso)
			SET @errores += '- Valor inexistente: Huso horario.' + N' ';

		-- chequeo dup
		IF EXISTS(SELECT 1 FROM sedes.Sede WHERE Nombre = @nombre AND Ciudad = @ciudad)
			SET @errores += '- Valor duplicado: Sede (nombre y ciudad).' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

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
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		-- chequeo validez (solo lo que vino con valor)
		IF (@idSede IS NULL) OR (@idSede <= 0)
			SET @errores += '- Valor invalido: IdSede.' + N' ';

		IF (@capacidad IS NOT NULL) AND (@capacidad <= 0)
			SET @errores += '- Valor invalido: Capacidad.' + N' ';

		IF (@pais IS NOT NULL) AND (@pais <= 0)
			SET @errores += '- Valor invalido: Pais.' + N' ';

		IF (@huso IS NOT NULL) AND (@huso <= 0)
			SET @errores += '- Valor invalido: Huso horario.' + N' ';

		-- chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM sedes.Sede WHERE IdSede = @idSede)
			SET @errores += '- Valor inexistente: IdSede.' + N' ';

		IF (@pais IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @pais)
			SET @errores += '- Valor inexistente: Pais.' + N' ';

		IF (@huso IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM sedes.HusoHorario WHERE IdHuso = @huso)
			SET @errores += '- Valor inexistente: Huso horario.' + N' ';

		-- chequeo dup (solo si me pasaron nombre y ciudad juntos)
		IF (@nombre IS NOT NULL) AND (@ciudad IS NOT NULL)
		BEGIN
			IF EXISTS(SELECT 1 FROM sedes.Sede
				WHERE Nombre = @nombre AND Ciudad = @ciudad AND IdSede <> @idSede)
				SET @errores += '- Valor duplicado: Sede (nombre y ciudad).' + N' ';
		END

		IF @capacidad IS NOT NULL AND EXISTS (
			SELECT 1 FROM partidos.Partido WHERE IdSede=@idSede AND Asistencia>@capacidad)
			SET @errores += N'- La capacidad no puede ser menor a la asistencia registrada en los partidos de la sede. ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

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
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		-- chequeo validez
		IF (@idSede IS NULL) OR (@idSede <= 0)
			SET @errores += '- Valor invalido: IdSede.' + N' ';

		-- chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM sedes.Sede WHERE IdSede = @idSede)
			SET @errores += '- Valor inexistente: IdSede.' + N' ';

		-- chequeo relaciones (si hay registros hijos, no se puede dar de baja)
		IF EXISTS(SELECT 1 FROM partidos.Partido WHERE IdSede = @idSede)
			SET @errores += '- Existen 1 o mas registros relacionados: Partido. Elimine dichos registros para continuar.' + N' ';

		IF EXISTS(SELECT 1 FROM publicidad.EspacioPublicitario WHERE IdSede = @idSede)
			SET @errores += '- Existen 1 o mas registros relacionados: EspacioPublicitario. Elimine dichos registros para continuar.' + N' ';

		IF EXISTS(SELECT 1 FROM publicidad.CostoFranja WHERE IdSede = @idSede)
			SET @errores += '- Existen 1 o mas registros relacionados: CostoFranja. Elimine dichos registros para continuar.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		DELETE FROM sedes.Sede
		WHERE IdSede = @idSede
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
end;
go