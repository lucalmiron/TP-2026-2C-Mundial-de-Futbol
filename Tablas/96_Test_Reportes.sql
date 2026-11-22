--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: --/--/--

--Objetivo: Testear los SP de reportes(entrega 7) y de consulta(System to be), y corroborar que la salida es acorde a los datos presentes en la base de datos.

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

----REPORTES

--*--reporte de goleadores por seleccion/fase/mundial
--por mundial
EXEC SP.uspReporte_Goleadores @categoria = 'Mundial', @mundial = 1;
--por seleccion
EXEC SP.uspReporte_Goleadores @categoria = 'Seleccion', @mundial = 1;
--por fase
EXEC SP.uspReporte_Goleadores @categoria = 'Fase', @mundial = 1;

--*--Tarjetas (amarillas y rojas) por selección y jugador, con detalle de suspensiones activas por acumulación
EXEC SP.uspReporte_Tarjetas @mundial = 1;

--*--Designaciones Arbitrales
EXEC SP.uspReporte_Arbitraje @mundial = 1;

--*--Ocupacion publicitaria por sede y partido (con salida a XML)
EXEC SP.uspReporte_Publicidad @mundial = 1;

--*--Selecciones y plantillas: listado de selecciones con un vector anidado de convocados (nombre, posición, club, dorsal) (con salida a XML)
EXEC SP.uspReporte_Convocados @mundial = 1;

--*--Resultados de encuentros
EXEC SP.uspReporte_Partidos @mundial = 1;

--*--Pivot de primetime (internamente usa el SP de API de conversion de hora segun zona horaria)
--Idealmente, este SP deberia ser ejecutado en un script propio para controlar la activacion/desactivacion
--de las opciones OLE ya que dejarlas activas representa una vulnerabilidad
/*
--Activo opciones para habilitar el uso de APIs
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'Ole Automation Procedures', 1;
RECONFIGURE;
GO
*/

EXEC SP.uspReporte_Primetime @mundial = 1;

/*
--Desactivo opciones para habilitar el uso de APIs
EXEC sp_configure 'Ole Automation Procedures', 0;
RECONFIGURE;
EXEC sp_configure 'show advanced options', 0;
RECONFIGURE;
GO
*/

----CONSULTAS

----Historial de Partidos en los cuales el Jugador fue titular
EXEC SP.uspJugador_Titularidad @mundial = 1, @jugador = 1;

----Fixture del Mundial con filtro por Sede, Fecha, Seleccion o Fase
--Por Fase
EXEC SP.uspFixture @categoria = 'Fase', @mundial = 1;
--Por Sede
EXEC SP.uspFixture @categoria = 'Sede', @mundial = 1;
--Por Seleccion
EXEC SP.uspFixture @categoria = 'Seleccion', @mundial = 1;
--Por Fecha
EXEC SP.uspFixture @categoria = 'Fecha', @mundial = 1;

----Equipo en cancha de una Seleccion para un determinado Partido dado un minuto
EXEC SP.uspAlineacion_Actual @partido = 1, @seleccion = 1, @minuto = 25;

----Informes post-Partido de un Arbitro por Partido
EXEC SP.uspArbitro_Informes @mundial = 1, @arbitro = 1;
