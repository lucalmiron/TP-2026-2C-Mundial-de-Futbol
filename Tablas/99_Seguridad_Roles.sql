--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 20/11/2026

--Entrega 8: Seguridad y Respaldo - Fase B (Roles)
--Creacion de roles de seguridad y asignacion de permisos granulares.
--Ejecutar DESPUES de la Fase A (97/98) y de la instalacion de tablas y SPs.

-- Ejecutar en la base seleccionada por el instalador.
GO

-- ============================================
-- SP.uspSeguridad_CrearRoles
-- Crea los roles de seguridad si no existen.
-- ============================================
IF OBJECT_ID('SP.uspSeguridad_CrearRoles', 'P') IS NOT NULL
    DROP PROCEDURE SP.uspSeguridad_CrearRoles;
GO
CREATE PROCEDURE SP.uspSeguridad_CrearRoles
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'rol_Administrador' AND type = 'R')
        EXEC('CREATE ROLE rol_Administrador');

    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'rol_CargadorResultados' AND type = 'R')
        EXEC('CREATE ROLE rol_CargadorResultados');

    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'rol_GestorPublicidad' AND type = 'R')
        EXEC('CREATE ROLE rol_GestorPublicidad');

    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'rol_Consulta' AND type = 'R')
        EXEC('CREATE ROLE rol_Consulta');

    PRINT 'Roles de seguridad creados/verificados.';
END
GO

-- ============================================
-- SP.uspSeguridad_AsignarPermisos
-- Ejecuta GRANT/DENY sobre un objeto para un rol.
-- Usa SQL dinamico porque GRANT no puede ejecutarse
-- directamente dentro de un stored procedure.
--   @accion   : GRANT | DENY | REVOKE
--   @permiso  : SELECT, INSERT, UPDATE, DELETE, EXECUTE, CONTROL, etc.
--   @objeto   : SCHEMA::equipos, SP.uspReporte_Goleadores, etc.
-- ============================================
IF OBJECT_ID('SP.uspSeguridad_AsignarPermisos', 'P') IS NOT NULL
    DROP PROCEDURE SP.uspSeguridad_AsignarPermisos;
GO
CREATE PROCEDURE SP.uspSeguridad_AsignarPermisos
    @rol     SYSNAME,
    @permiso NVARCHAR(50),
    @objeto  NVARCHAR(500),
    @accion  NVARCHAR(10) = 'GRANT'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @sql NVARCHAR(MAX);

    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @rol AND type = 'R')
    BEGIN
        RAISERROR('El rol %s no existe.', 16, 1, @rol);
        RETURN;
    END

    IF UPPER(@accion) = 'REVOKE'
        SET @sql = 'REVOKE ' + @permiso + ' ON ' + @objeto + ' FROM ' + QUOTENAME(@rol);
    ELSE
        SET @sql = @accion + ' ' + @permiso + ' ON ' + @objeto + ' TO ' + QUOTENAME(@rol);

    BEGIN TRY
        EXEC(@sql);
        PRINT @sql;
    END TRY
    BEGIN CATCH
        -- Si el objeto todavia no existe (ej. instalacion incompleta), no cortar
        -- el lote: se avisa y se continua. Cualquier otro error se propaga.
        IF ERROR_NUMBER() IN (15151, 15006)
            PRINT 'AVISO (objeto inexistente, se omite): ' + @sql;
        ELSE
            THROW;
    END CATCH;
END
GO

-- ============================================
-- SP.uspSeguridad_ConfigurarRoles
-- Aplica la matriz de permisos de la Entrega 8.
-- ============================================
IF OBJECT_ID('SP.uspSeguridad_ConfigurarRoles', 'P') IS NOT NULL
    DROP PROCEDURE SP.uspSeguridad_ConfigurarRoles;
GO
CREATE PROCEDURE SP.uspSeguridad_ConfigurarRoles
AS
BEGIN
    SET NOCOUNT ON;

    -- Limpiar permisos/DENYs de ejecuciones anteriores del instalador.
    -- Versiones viejas de este SP bloqueaban todo el esquema SP al gestor de
    -- publicidad; ese DENY quedaba en la base y anulaba los GRANT especificos.
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_GestorPublicidad', @permiso = 'EXECUTE', @objeto = 'SCHEMA::SP', @accion = 'REVOKE';

    -- ---------- rol_Administrador: CONTROL sobre todos los esquemas ----------
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_Administrador', @permiso = 'CONTROL', @objeto = 'SCHEMA::SP';
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_Administrador', @permiso = 'CONTROL', @objeto = 'SCHEMA::SPTRANS';
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_Administrador', @permiso = 'CONTROL', @objeto = 'SCHEMA::equipos';
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_Administrador', @permiso = 'CONTROL', @objeto = 'SCHEMA::sedes';
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_Administrador', @permiso = 'CONTROL', @objeto = 'SCHEMA::partidos';
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_Administrador', @permiso = 'CONTROL', @objeto = 'SCHEMA::arbitros';
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_Administrador', @permiso = 'CONTROL', @objeto = 'SCHEMA::publicidad';

    -- ---------- rol_CargadorResultados ----------
    -- Puede ejecutar SP de ABM y transacciones
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_CargadorResultados', @permiso = 'EXECUTE', @objeto = 'SCHEMA::SP';
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_CargadorResultados', @permiso = 'EXECUTE', @objeto = 'SCHEMA::SPTRANS';
    -- Puede leer catalogos
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_CargadorResultados', @permiso = 'SELECT', @objeto = 'SCHEMA::equipos';
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_CargadorResultados', @permiso = 'SELECT', @objeto = 'SCHEMA::sedes';
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_CargadorResultados', @permiso = 'SELECT', @objeto = 'SCHEMA::partidos';
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_CargadorResultados', @permiso = 'SELECT', @objeto = 'SCHEMA::arbitros';
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_CargadorResultados', @permiso = 'SELECT', @objeto = 'SCHEMA::publicidad';
    -- NO puede ejecutar reportes
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_CargadorResultados', @permiso = 'EXECUTE', @objeto = 'SP.uspReporte_Goleadores', @accion = 'DENY';
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_CargadorResultados', @permiso = 'EXECUTE', @objeto = 'SP.uspReporte_Tarjetas', @accion = 'DENY';
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_CargadorResultados', @permiso = 'EXECUTE', @objeto = 'SP.uspReporte_Arbitraje', @accion = 'DENY';
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_CargadorResultados', @permiso = 'EXECUTE', @objeto = 'SP.uspReporte_Publicidad', @accion = 'DENY';
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_CargadorResultados', @permiso = 'EXECUTE', @objeto = 'SP.uspReporte_Convocados', @accion = 'DENY';
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_CargadorResultados', @permiso = 'EXECUTE', @objeto = 'SP.uspReporte_Partidos', @accion = 'DENY';
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_CargadorResultados', @permiso = 'EXECUTE', @objeto = 'SP.uspReporte_Primetime', @accion = 'DENY';
    -- NO puede escribir directamente en tablas (solo via SP)
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_CargadorResultados', @permiso = 'INSERT, UPDATE, DELETE', @objeto = 'SCHEMA::equipos', @accion = 'DENY';
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_CargadorResultados', @permiso = 'INSERT, UPDATE, DELETE', @objeto = 'SCHEMA::sedes', @accion = 'DENY';
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_CargadorResultados', @permiso = 'INSERT, UPDATE, DELETE', @objeto = 'SCHEMA::partidos', @accion = 'DENY';
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_CargadorResultados', @permiso = 'INSERT, UPDATE, DELETE', @objeto = 'SCHEMA::arbitros', @accion = 'DENY';
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_CargadorResultados', @permiso = 'INSERT, UPDATE, DELETE', @objeto = 'SCHEMA::publicidad', @accion = 'DENY';

    -- ---------- rol_GestorPublicidad ----------
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_GestorPublicidad', @permiso = 'EXECUTE', @objeto = 'SCHEMA::publicidad';
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_GestorPublicidad', @permiso = 'SELECT', @objeto = 'SCHEMA::publicidad';
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_GestorPublicidad', @permiso = 'SELECT', @objeto = 'SCHEMA::equipos';
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_GestorPublicidad', @permiso = 'SELECT', @objeto = 'SCHEMA::sedes';
    -- Unicamente los SP de ABM de publicidad (viven en el esquema SP).
    -- No se da EXECUTE a todo el esquema SP para no habilitar otros dominios.
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_GestorPublicidad', @permiso = 'EXECUTE', @objeto = 'SP.uspAnunciante_Registrar';
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_GestorPublicidad', @permiso = 'EXECUTE', @objeto = 'SP.uspAnunciante_Update';
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_GestorPublicidad', @permiso = 'EXECUTE', @objeto = 'SP.uspAnunciante_Bajar';
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_GestorPublicidad', @permiso = 'EXECUTE', @objeto = 'SP.uspPublicidad_Registrar';
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_GestorPublicidad', @permiso = 'EXECUTE', @objeto = 'SP.uspPublicidad_Update';
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_GestorPublicidad', @permiso = 'EXECUTE', @objeto = 'SP.uspPublicidad_Bajar';
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_GestorPublicidad', @permiso = 'EXECUTE', @objeto = 'SP.uspCampania_Registrar';
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_GestorPublicidad', @permiso = 'EXECUTE', @objeto = 'SP.uspCampania_Update';
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_GestorPublicidad', @permiso = 'EXECUTE', @objeto = 'SP.uspCampania_Bajar';
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_GestorPublicidad', @permiso = 'EXECUTE', @objeto = 'SP.uspAnuncianteCampania_Registrar';
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_GestorPublicidad', @permiso = 'EXECUTE', @objeto = 'SP.uspAnuncianteCampania_Bajar';
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_GestorPublicidad', @permiso = 'EXECUTE', @objeto = 'SP.uspPublicidadPais_Registrar';
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_GestorPublicidad', @permiso = 'EXECUTE', @objeto = 'SP.uspPublicidadPais_Bajar';
    -- NO puede ejecutar SP de otros dominios
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_GestorPublicidad', @permiso = 'EXECUTE', @objeto = 'SCHEMA::SPTRANS', @accion = 'DENY';
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_GestorPublicidad', @permiso = 'EXECUTE', @objeto = 'SP.uspReporte_Goleadores', @accion = 'DENY';
    -- NO escribe directamente en tablas
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_GestorPublicidad', @permiso = 'INSERT, UPDATE, DELETE', @objeto = 'SCHEMA::publicidad', @accion = 'DENY';

    -- ---------- rol_Consulta ----------
    -- Solo ejecuta los SP de reporte
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_Consulta', @permiso = 'EXECUTE', @objeto = 'SP.uspReporte_Goleadores';
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_Consulta', @permiso = 'EXECUTE', @objeto = 'SP.uspReporte_Tarjetas';
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_Consulta', @permiso = 'EXECUTE', @objeto = 'SP.uspReporte_Arbitraje';
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_Consulta', @permiso = 'EXECUTE', @objeto = 'SP.uspReporte_Publicidad';
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_Consulta', @permiso = 'EXECUTE', @objeto = 'SP.uspReporte_Convocados';
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_Consulta', @permiso = 'EXECUTE', @objeto = 'SP.uspReporte_Partidos';
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_Consulta', @permiso = 'EXECUTE', @objeto = 'SP.uspReporte_Primetime';
    -- Primetime llama internamente a este SP de conversion horaria
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_Consulta', @permiso = 'EXECUTE', @objeto = 'SP.uspAPIconversionHora';
    -- Lectura de catalogos
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_Consulta', @permiso = 'SELECT', @objeto = 'SCHEMA::equipos';
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_Consulta', @permiso = 'SELECT', @objeto = 'SCHEMA::sedes';
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_Consulta', @permiso = 'SELECT', @objeto = 'SCHEMA::partidos';
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_Consulta', @permiso = 'SELECT', @objeto = 'SCHEMA::arbitros';
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_Consulta', @permiso = 'SELECT', @objeto = 'SCHEMA::publicidad';
    -- NO ejecuta SP de ABM (no se le otorga EXECUTE en esos esquemas; no se usa DENY
    -- a nivel esquema para no anular los GRANT especificos sobre los reportes)
    -- NO escribe en tablas
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_Consulta', @permiso = 'INSERT, UPDATE, DELETE', @objeto = 'SCHEMA::equipos', @accion = 'DENY';
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_Consulta', @permiso = 'INSERT, UPDATE, DELETE', @objeto = 'SCHEMA::sedes', @accion = 'DENY';
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_Consulta', @permiso = 'INSERT, UPDATE, DELETE', @objeto = 'SCHEMA::partidos', @accion = 'DENY';
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_Consulta', @permiso = 'INSERT, UPDATE, DELETE', @objeto = 'SCHEMA::arbitros', @accion = 'DENY';
    EXEC SP.uspSeguridad_AsignarPermisos @rol = 'rol_Consulta', @permiso = 'INSERT, UPDATE, DELETE', @objeto = 'SCHEMA::publicidad', @accion = 'DENY';

    PRINT 'Permisos de roles configurados.';
END
GO

-- ============================================
-- SP.uspSeguridad_InformePermisos
-- Devuelve los permisos efectivos de un rol (para el cuadro documentado).
-- ============================================
IF OBJECT_ID('SP.uspSeguridad_InformePermisos', 'P') IS NOT NULL
    DROP PROCEDURE SP.uspSeguridad_InformePermisos;
GO
CREATE PROCEDURE SP.uspSeguridad_InformePermisos
    @rol SYSNAME
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        @rol AS Rol,
        o.name AS Objeto,
        s.name AS Esquema,
        p.permission_name AS Permiso,
        p.state_desc AS Estado
    FROM sys.database_permissions p
    JOIN sys.database_principals dp ON dp.principal_id = p.grantee_principal_id
    LEFT JOIN sys.objects o ON o.object_id = p.major_id
    LEFT JOIN sys.schemas s ON s.schema_id = p.major_id
    WHERE dp.name = @rol
    ORDER BY Esquema, Objeto, Permiso;
END
GO

PRINT 'SPs de roles creados/verificados.';
GO
