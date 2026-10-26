--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02
--/Grupo 7 - Integrantes:
--/Almiron, Luca
--/Figueroa, Santiago
--/Ruarte, Fidel
--/Villalba, Leandro
--/Fecha: 26/10/26
--/Objetivo: Test de la importacion de Pais (SP.uspImportacion_Registrar y sus SP auxiliares)
--/Requisito: copiar pais_test.csv a C:\Importacion\ en la maquina donde corre SQL Server.
--/Contenido esperado de pais_test.csv (con encabezado):
--/ NOMBRE,PBI
--/ Argentina,650000000000
--/ Brasil,1800000000000
--/ Uruguay,60000000000
--/ Mexico,1200000000000
--/ Estados Unidos,25000000000000
--/ Francia,2800000000000
--/ Alemania,4200000000000
--/ Japon,4900000000000
--/ Espana,1400000000000
--/ Canada,1900000000000
--/ ,100000000000
--/ Chile,300000000000
--/ Ecuador,
--/ Peru,-50000000000
--/ Colombia,abc
--/ Argentina,650000000000

--/Nota: los resultados esperados suponen que equipos.Pais no tiene ninguno de los paises del CSV.
--/      Si ya cargaron datos semilla, algunas filas saldran como Actualizadas o SinCambios en lugar de Insertadas.

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

-- ============================================================
-- VALIDACIONES DE PARAMETROS
-- ============================================================

-- Esperado: error 50001 'Error/es: - Valor invalido: Nombre de archivo.'
EXEC SP.uspImportacion_Registrar @nombreArchivo = '';
GO

-- Esperado: error 50001 con 'Valor invalido: Nombre de archivo (no debe incluir la ruta...)'
EXEC SP.uspImportacion_Registrar @nombreArchivo = 'C:\otra\pais_test.csv';
GO

-- Esperado: error 50001 'Error/es: - Valor invalido: Tipo de archivo (por ahora solo CSV).'
EXEC SP.uspImportacion_Registrar @nombreArchivo = 'pais_test.csv', @tipoArchivo = 'XML';
GO

-- Esperado: error de BULK INSERT (no se puede abrir el archivo). 
-- Queda una fila en ArchivoImportado con Estado = 'Fallido'
-- y MensajeError con el motivo. No se carga nada en equipos.Pais.
EXEC SP.uspImportacion_Registrar @nombreArchivo = 'no_existe.csv';
GO

SELECT TOP 1 * FROM importacion.ArchivoImportado ORDER BY IdArchivo DESC;
GO

-- ============================================================
-- IMPORTACION CON ERRORES PARCIALES (primera vez)
-- ============================================================

-- Esperado, primer resultado: Estado = 'Parcial', CantidadFilas = 16, Insertadas = 12, Actualizadas = 0,
--   SinCambios = 0, Omitidas = 1 (la primera 'Argentina'), CantidadErrores = 3.
-- Esperado, segundo resultado: 3 filas rechazadas:
--   fila con nombre vacio, 'Peru' con PBI negativo y 'Colombia' con PBI 'abc'.
EXEC SP.uspImportacion_Registrar @nombreArchivo = 'pais_test.csv';
GO

-- Esperado: 12 paises nuevos. 'Chile' sin espacios, 'Ecuador' con PBI NULL y 'Argentina' con PBI = 650000000000 (ultima aparicion).
-- No deben existir 'Peru', 'Colombia' ni un pais con nombre vacio.
SELECT * FROM equipos.Pais WHERE NOMBRE IN ('Argentina', 'Brasil', 'Uruguay', 'Mexico', 'Estados Unidos', 'Francia',
	'Alemania', 'Japon', 'Espana', 'Canada', 'Chile', 'Ecuador', 'Peru', 'Colombia') ORDER BY IdPais;
GO

-- Esperado: ultima fila con Estado = 'Parcial', CantidadFilas = 16, CantidadErrores = 3.
SELECT TOP 1 * FROM importacion.ArchivoImportado ORDER BY IdArchivo DESC;
GO

-- Esperado: 16 filas del ultimo archivo: 12 Insertada, 1 Omitida, 3 Error.
SELECT Estado, COUNT(*) AS Cantidad
FROM importacion.StagingPais
WHERE IdArchivo = (SELECT MAX(IdArchivo) FROM importacion.ArchivoImportado WHERE Estado <> 'Fallido')
GROUP BY Estado;
GO

-- ============================================================
-- IMPORTACION REITERADA DEL MISMO ARCHIVO (no debe duplicar)
-- ============================================================

-- Esperado: Estado = 'Parcial', Insertadas = 0, Actualizadas = 0, SinCambios = 12, Omitidas = 1, CantidadErrores = 3.
EXEC SP.uspImportacion_Registrar @nombreArchivo = 'pais_test.csv';
GO

-- Esperado: el mismo conteo que antes de la segunda importacion, 12 paises del CSV, sin duplicados.
SELECT COUNT(*) AS PaisesDelCsv FROM equipos.Pais WHERE NOMBRE IN ('Argentina', 'Brasil', 'Uruguay', 'Mexico', 'Estados Unidos',
	'Francia', 'Alemania', 'Japon', 'Espana', 'Canada', 'Chile', 'Ecuador');
GO