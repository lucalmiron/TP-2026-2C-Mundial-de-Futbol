--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Creacion de Tablas

-- Ejecutar en la base seleccionada por el instalador.
GO

-- ============================================
-- 16_Tabla_Persona.sql
-- Crea equipos.Persona con Nombre NVARCHAR(30)
-- Si existe con esquema viejo (VARBINARY), la elimina para recrearla
-- ============================================

-- Paso 1: Si la tabla existe con Nombre VARBINARY (esquema viejo), eliminarla
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'equipos' AND TABLE_NAME = 'Persona')
BEGIN
    IF EXISTS (
        SELECT 1 FROM sys.columns c
        JOIN sys.types t ON t.user_type_id = c.user_type_id
        WHERE c.object_id = OBJECT_ID('equipos.Persona')
          AND c.name = 'Nombre'
          AND t.name = 'varbinary'
    )
    BEGIN
        -- Eliminar dependencias FK que apuntan a Persona
        IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE referenced_object_id = OBJECT_ID('equipos.Persona'))
        BEGIN
            DECLARE @dropFkSql NVARCHAR(MAX) = N'';
            SELECT @dropFkSql = @dropFkSql + N'ALTER TABLE ' + QUOTENAME(OBJECT_SCHEMA_NAME(fk.parent_object_id)) + N'.' + QUOTENAME(OBJECT_NAME(fk.parent_object_id)) + N' DROP CONSTRAINT ' + QUOTENAME(fk.name) + N';' + CHAR(13) + CHAR(10)
            FROM sys.foreign_keys fk
            WHERE fk.referenced_object_id = OBJECT_ID('equipos.Persona');

            EXEC sp_executesql @dropFkSql;
        END

        DROP TABLE equipos.Persona;
        PRINT 'Tabla Persona eliminada (esquema viejo VARBINARY detectado).';
    END
END
GO

-- Paso 2: Crear la tabla si no existe
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'equipos' AND TABLE_NAME = 'Persona')
BEGIN
    CREATE TABLE equipos.Persona
    (
        IdPersona INT IDENTITY(1, 1),
        Nombre NVARCHAR(30) NOT NULL,
        Fnac DATE NOT NULL,
        Rol VARCHAR(10) NOT NULL,
        Pais INT NOT NULL,
        CONSTRAINT PK_Persona PRIMARY KEY (IdPersona),
        CONSTRAINT FK_Persona_Pais FOREIGN KEY (Pais) REFERENCES equipos.Pais(IdPais)
    );
    PRINT 'Tabla Persona creada con Nombre NVARCHAR(30).';
END
GO