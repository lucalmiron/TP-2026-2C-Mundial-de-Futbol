--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02
--/Grupo 7 - Integrantes:
--/Almiron, Luca
--/Figueroa, Santiago
--/Ruarte, Fidel
--/Villalba, Leandro
--/Fecha: 26/10/26
--/Objetivo: Esquema y tablas de importacion (Entrega 6)
--/  Contiene: Schema importacion, ArchivoImportado, StagingPais, vwStagingPais

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

-- ============================================================
-- ESQUEMA DE IMPORTACION
-- ============================================================
IF NOT EXISTS (SELECT name FROM sys.schemas WHERE name = 'importacion')
BEGIN
	EXECUTE('CREATE SCHEMA importacion')
END;
GO

-- ============================================================
-- TABLA: importacion.ArchivoImportado (Metadata de archivos)
-- ============================================================
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'importacion' AND TABLE_NAME = 'ArchivoImportado')
BEGIN
	CREATE TABLE importacion.ArchivoImportado(
		IdArchivo INT IDENTITY(1,1),
		NombreArchivo VARCHAR(200) NOT NULL,
		RutaArchivo VARCHAR(500) NULL,
		TipoArchivo VARCHAR(10) NOT NULL,
		FechaImportacion DATETIME NOT NULL,
		Usuario VARCHAR(128) NOT NULL,
		Estado VARCHAR(20) NOT NULL,
		CantidadFilas INT NOT NULL CONSTRAINT DF_ArchivoImportado_CantidadFilas DEFAULT 0,
		CantidadErrores INT NOT NULL CONSTRAINT DF_ArchivoImportado_CantidadErrores DEFAULT 0,
		MensajeError VARCHAR(500) NULL,
		CONSTRAINT PK_ArchivoImportado PRIMARY KEY (IdArchivo),
		CONSTRAINT CK_ArchivoImportado_Estado CHECK (Estado IN ('Procesando', 'Completado', 'Parcial', 'Fallido'))
	);
END;
GO

-- ============================================================
-- TABLA: importacion.StagingPais (Staging para carga de Pais)
-- Todo el contenido del CSV entra como texto para que una fila mal formada no frene la carga del resto.
-- ============================================================
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'importacion' AND TABLE_NAME = 'StagingPais')
BEGIN
	CREATE TABLE importacion.StagingPais(
		IdFila INT IDENTITY(1,1),
		IdArchivo INT NULL,
		NOMBRE VARCHAR(500) NULL,
		PBI VARCHAR(500) NULL,
		NombreLimpio VARCHAR(50) NULL,
		PBIValor BIGINT NULL,
		Estado VARCHAR(12) NOT NULL CONSTRAINT DF_StagingPais_Estado DEFAULT 'Pendiente',
		Detalle VARCHAR(400) NULL,
		CONSTRAINT PK_StagingPais PRIMARY KEY (IdFila),
		CONSTRAINT FK_StagingPais_ArchivoImportado FOREIGN KEY (IdArchivo) REFERENCES importacion.ArchivoImportado(IdArchivo),
		CONSTRAINT CK_StagingPais_Estado CHECK (Estado IN ('Pendiente', 'Valida', 'Error', 'Omitida', 'Insertada', 'Actualizada', 'SinCambios'))
	);
END;
GO

-- ============================================================
-- VISTA: importacion.vwStagingPais
-- Vista con solo las columnas del CSV: es el destino del BULK INSERT
-- (el resto de las columnas toman su default)
-- ============================================================
CREATE OR ALTER VIEW importacion.vwStagingPais
AS
	SELECT NOMBRE, PBI
	FROM importacion.StagingPais;
GO

PRINT 'Esquema y tablas de importacion creados correctamente.';
GO