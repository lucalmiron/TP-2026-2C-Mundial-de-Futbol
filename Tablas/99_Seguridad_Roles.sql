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

    -- ---------- rol_Administrador: CONTROL sobre todos los esquemas ----------
    GRANT CONTROL ON SCHEMA::SP TO [rol_Administrador];
    GRANT CONTROL ON SCHEMA::SPTRANS TO [rol_Administrador];
    GRANT CONTROL ON SCHEMA::equipos TO [rol_Administrador];
    GRANT CONTROL ON SCHEMA::sedes TO [rol_Administrador];
    GRANT CONTROL ON SCHEMA::partidos TO [rol_Administrador];
    GRANT CONTROL ON SCHEMA::arbitros TO [rol_Administrador];
    GRANT CONTROL ON SCHEMA::publicidad TO [rol_Administrador];

    -- ---------- rol_CargadorResultados ----------
    -- Puede ejecutar SP de ABM y transacciones
    GRANT EXECUTE ON SCHEMA::SP TO [rol_CargadorResultados];
    GRANT EXECUTE ON SCHEMA::SPTRANS TO [rol_CargadorResultados];
    -- Puede leer catalogos
    GRANT SELECT ON SCHEMA::equipos TO [rol_CargadorResultados];
    GRANT SELECT ON SCHEMA::sedes TO [rol_CargadorResultados];
    GRANT SELECT ON SCHEMA::partidos TO [rol_CargadorResultados];
    GRANT SELECT ON SCHEMA::arbitros TO [rol_CargadorResultados];
    GRANT SELECT ON SCHEMA::publicidad TO [rol_CargadorResultados];
    -- NO puede ejecutar reportes
    DENY EXECUTE ON SP.uspReporte_Goleadores TO [rol_CargadorResultados];
    DENY EXECUTE ON SP.uspReporte_Tarjetas TO [rol_CargadorResultados];
    DENY EXECUTE ON SP.uspReporte_Arbitraje TO [rol_CargadorResultados];
    DENY EXECUTE ON SP.uspReporte_Publicidad TO [rol_CargadorResultados];
    DENY EXECUTE ON SP.uspReporte_Convocados TO [rol_CargadorResultados];
    DENY EXECUTE ON SP.uspReporte_Partidos TO [rol_CargadorResultados];
    DENY EXECUTE ON SP.uspReporte_Primetime TO [rol_CargadorResultados];
    -- NO puede escribir directamente en tablas (solo via SP)
    DENY INSERT, UPDATE, DELETE ON SCHEMA::equipos TO [rol_CargadorResultados];
    DENY INSERT, UPDATE, DELETE ON SCHEMA::sedes TO [rol_CargadorResultados];
    DENY INSERT, UPDATE, DELETE ON SCHEMA::partidos TO [rol_CargadorResultados];
    DENY INSERT, UPDATE, DELETE ON SCHEMA::arbitros TO [rol_CargadorResultados];
    DENY INSERT, UPDATE, DELETE ON SCHEMA::publicidad TO [rol_CargadorResultados];

    -- ---------- rol_GestorPublicidad ----------
    GRANT EXECUTE ON SCHEMA::publicidad TO [rol_GestorPublicidad];
    GRANT SELECT ON SCHEMA::publicidad TO [rol_GestorPublicidad];
    GRANT SELECT ON SCHEMA::equipos TO [rol_GestorPublicidad];
    GRANT SELECT ON SCHEMA::sedes TO [rol_GestorPublicidad];
    -- Unicamente los SP de ABM de publicidad (viven en el esquema SP).
    GRANT EXECUTE ON SP.uspAnunciante_Registrar TO [rol_GestorPublicidad];
    GRANT EXECUTE ON SP.uspAnunciante_Update TO [rol_GestorPublicidad];
    GRANT EXECUTE ON SP.uspAnunciante_Bajar TO [rol_GestorPublicidad];
    GRANT EXECUTE ON SP.uspPublicidad_Registrar TO [rol_GestorPublicidad];
    GRANT EXECUTE ON SP.uspPublicidad_Update TO [rol_GestorPublicidad];
    GRANT EXECUTE ON SP.uspPublicidad_Bajar TO [rol_GestorPublicidad];
    GRANT EXECUTE ON SP.uspCampania_Registrar TO [rol_GestorPublicidad];
    GRANT EXECUTE ON SP.uspCampania_Update TO [rol_GestorPublicidad];
    GRANT EXECUTE ON SP.uspCampania_Bajar TO [rol_GestorPublicidad];
    GRANT EXECUTE ON SP.uspAnuncianteCampania_Registrar TO [rol_GestorPublicidad];
    GRANT EXECUTE ON SP.uspAnuncianteCampania_Bajar TO [rol_GestorPublicidad];
    GRANT EXECUTE ON SP.uspPublicidadPais_Registrar TO [rol_GestorPublicidad];
    GRANT EXECUTE ON SP.uspPublicidadPais_Bajar TO [rol_GestorPublicidad];
    -- NO puede ejecutar SP de otros dominios
    DENY EXECUTE ON SCHEMA::SPTRANS TO [rol_GestorPublicidad];
    DENY EXECUTE ON SP.uspReporte_Goleadores TO [rol_GestorPublicidad];
    -- NO escribe directamente en tablas
    DENY INSERT, UPDATE, DELETE ON SCHEMA::publicidad TO [rol_GestorPublicidad];

    -- ---------- rol_Consulta ----------
    -- Solo ejecuta los SP de reporte
    GRANT EXECUTE ON SP.uspReporte_Goleadores TO [rol_Consulta];
    GRANT EXECUTE ON SP.uspReporte_Tarjetas TO [rol_Consulta];
    GRANT EXECUTE ON SP.uspReporte_Arbitraje TO [rol_Consulta];
    GRANT EXECUTE ON SP.uspReporte_Publicidad TO [rol_Consulta];
    GRANT EXECUTE ON SP.uspReporte_Convocados TO [rol_Consulta];
    GRANT EXECUTE ON SP.uspReporte_Partidos TO [rol_Consulta];
    GRANT EXECUTE ON SP.uspReporte_Primetime TO [rol_Consulta];
    -- Primetime llama internamente a este SP de conversion horaria
    GRANT EXECUTE ON SP.uspAPIconversionHora TO [rol_Consulta];
    -- Lectura de catalogos
    GRANT SELECT ON SCHEMA::equipos TO [rol_Consulta];
    GRANT SELECT ON SCHEMA::sedes TO [rol_Consulta];
    GRANT SELECT ON SCHEMA::partidos TO [rol_Consulta];
    GRANT SELECT ON SCHEMA::arbitros TO [rol_Consulta];
    GRANT SELECT ON SCHEMA::publicidad TO [rol_Consulta];
    -- NO ejecuta SP de ABM
    -- NO escribe en tablas
    DENY INSERT, UPDATE, DELETE ON SCHEMA::equipos TO [rol_Consulta];
    DENY INSERT, UPDATE, DELETE ON SCHEMA::sedes TO [rol_Consulta];
    DENY INSERT, UPDATE, DELETE ON SCHEMA::partidos TO [rol_Consulta];
    DENY INSERT, UPDATE, DELETE ON SCHEMA::arbitros TO [rol_Consulta];
    DENY INSERT, UPDATE, DELETE ON SCHEMA::publicidad TO [rol_Consulta];

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
