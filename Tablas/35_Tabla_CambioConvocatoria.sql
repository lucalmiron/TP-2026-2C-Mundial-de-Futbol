--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Objetivo: Crear Tabla CambioConvocatoria

-- Ejecutar en la base seleccionada por el instalador.
GO

-- ============================================
-- 35_Tabla_CambioConvocatoria.sql
-- Crea equipos.CambioConvocatoria con Motivo VARBINARY(256) + MotivoHash
-- Si existe con esquema viejo (Motivo VARCHAR), la elimina para recrearla
-- ============================================

-- Paso 1: Si la tabla existe con Motivo VARCHAR (esquema viejo), eliminarla
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'equipos' AND TABLE_NAME = 'CambioConvocatoria')
BEGIN
    IF EXISTS (
        SELECT 1 FROM sys.columns c
        JOIN sys.types t ON t.user_type_id = c.user_type_id
        WHERE c.object_id = OBJECT_ID('equipos.CambioConvocatoria')
          AND c.name = 'Motivo'
          AND t.name = 'varchar'
    )
    BEGIN
        -- Verificar si tiene MotivoHash (si no, es esquema viejo)
        IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('equipos.CambioConvocatoria') AND name = 'MotivoHash')
        BEGIN
            DROP TABLE equipos.CambioConvocatoria;
            PRINT 'Tabla CambioConvocatoria eliminada (esquema viejo VARCHAR detectado).';
        END
    END
END
GO

-- Paso 2: Crear la tabla si no existe
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'equipos' AND TABLE_NAME = 'CambioConvocatoria')
BEGIN
    CREATE TABLE equipos.CambioConvocatoria
    (
        IdCambio INT PRIMARY KEY IDENTITY(1, 1),
        Seleccion INT NOT NULL,
        Egreso INT NOT NULL,
        Ingreso INT NOT NULL,
        Fecha DATE NOT NULL,
        Motivo VARBINARY(256) NOT NULL,      -- Cifrado con AES_128 (ver 97_Seguridad_Cifrado_Claves.sql)
        MotivoHash VARBINARY(32) NULL,        -- HASHBYTES('SHA2_256', Motivo) para busquedas sin descifrar
        CONSTRAINT FK_CambioConvocatoria_Seleccion FOREIGN KEY (Seleccion) REFERENCES equipos.Seleccion(IdSeleccion),
        CONSTRAINT FK_CambioConvocatoria_Egreso FOREIGN KEY (Egreso) REFERENCES equipos.Jugador(IdJugador),
        CONSTRAINT FK_CambioConvocatoria_Ingreso FOREIGN KEY (Ingreso) REFERENCES equipos.Jugador(IdJugador),
        CONSTRAINT CK_CambioConvocatoria_Ingreso_Egreso CHECK (Ingreso <> Egreso)
    )
    PRINT 'Tabla CambioConvocatoria creada con Motivo VARBINARY(256) + MotivoHash.';
END
GO

-- Migracion: la tabla vivia en TABLAS.*, se retira el esquema viejo una vez creado el vigente
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'TABLAS' AND TABLE_NAME = 'CambioConvocatoria')
AND EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'equipos' AND TABLE_NAME = 'CambioConvocatoria')
BEGIN
    DROP TABLE TABLAS.CambioConvocatoria
END
GO