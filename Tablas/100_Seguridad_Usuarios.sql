--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 20/11/2026

--Entrega 8: Seguridad y Respaldo - Fase B (Usuarios)
--Crea los logins (SQL Authentication) y los usuarios de prueba,
--y los asigna a los roles de seguridad. Ejecutar DESPUES de 99_Seguridad_Roles.sql.

-- Ejecutar en la base seleccionada por el instalador.
GO

-- 1) Crear roles y configurar permisos (idempotente)
EXEC SP.uspSeguridad_CrearRoles;
GO
EXEC SP.uspSeguridad_ConfigurarRoles;
GO

-- 2) Crear logins a nivel servidor (idempotente)
-- Nota: contrasenias de ejemplo para el TP. Reemplazar en un entorno real.
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'usr_admin')
    CREATE LOGIN usr_admin WITH PASSWORD = 'Admin_Mundial_2026!', CHECK_POLICY = OFF;
GO
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'usr_carga')
    CREATE LOGIN usr_carga WITH PASSWORD = 'Carga_Mundial_2026!', CHECK_POLICY = OFF;
GO
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'usr_publicidad')
    CREATE LOGIN usr_publicidad WITH PASSWORD = 'Publicidad_Mundial_2026!', CHECK_POLICY = OFF;
GO
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'usr_consulta')
    CREATE LOGIN usr_consulta WITH PASSWORD = 'Consulta_Mundial_2026!', CHECK_POLICY = OFF;
GO

-- 3) Crear usuarios en la base actual (idempotente)
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'usr_admin')
    CREATE USER usr_admin FOR LOGIN usr_admin;
GO
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'usr_carga')
    CREATE USER usr_carga FOR LOGIN usr_carga;
GO
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'usr_publicidad')
    CREATE USER usr_publicidad FOR LOGIN usr_publicidad;
GO
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'usr_consulta')
    CREATE USER usr_consulta FOR LOGIN usr_consulta;
GO

-- 4) Asignar usuarios a roles (idempotente)
-- IS_ROLEMEMBER devuelve NULL si el usuario/rol no existe: ISNULL lo trata como 0.
IF ISNULL(IS_ROLEMEMBER('rol_Administrador', 'usr_admin'), 0) = 0
    ALTER ROLE rol_Administrador ADD MEMBER usr_admin;
GO
IF ISNULL(IS_ROLEMEMBER('rol_CargadorResultados', 'usr_carga'), 0) = 0
    ALTER ROLE rol_CargadorResultados ADD MEMBER usr_carga;
GO
IF ISNULL(IS_ROLEMEMBER('rol_GestorPublicidad', 'usr_publicidad'), 0) = 0
    ALTER ROLE rol_GestorPublicidad ADD MEMBER usr_publicidad;
GO
IF ISNULL(IS_ROLEMEMBER('rol_Consulta', 'usr_consulta'), 0) = 0
    ALTER ROLE rol_Consulta ADD MEMBER usr_consulta;
GO

PRINT 'Usuarios de seguridad creados/verificados y asignados a roles.';
GO
