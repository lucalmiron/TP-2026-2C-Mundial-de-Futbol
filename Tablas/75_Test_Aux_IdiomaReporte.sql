-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Grupo 7
-- Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 26/10/26.
-- Objetivo: comprobar idiomas, idiomas del arbitro e informes con SP reales.
-- Ejecutar en una base vacia MUNDIAL_Final_Test*, con las tablas y SP reales instalados.
-- Los datos son exclusivos de esta base de prueba. No ejecutar en MUNDIAL.
SET NOCOUNT ON;
IF DB_NAME() NOT LIKE 'MUNDIAL[_]Final[_]Test%'
    THROW 51000, 'Seleccionar una base MUNDIAL_Final_Test para estas pruebas.', 1;
IF EXISTS(SELECT 1 FROM equipos.Pais)
    THROW 51000, 'La base de prueba debe estar vacia.', 1;

DECLARE @idioma INT, @pais1 INT,@pais2 INT,@grupo INT,@mundial INT,@s1 INT,@s2 INT,@huso INT,@sede INT,
        @fase INT,@p1 INT,@p2 INT,@arbitro INT,@motivo INT,@i INT=1,@persona INT;
INSERT sedes.HusoHorario(Nombre) VALUES('UTC'); SET @huso=SCOPE_IDENTITY();
INSERT arbitros.Idioma(Descripcion) VALUES('Idioma'); SET @idioma = SCOPE_IDENTITY();
INSERT equipos.Pais(NOMBRE, Idioma, HusoHorario, PtIni, PtFin, PBI) VALUES('Prueba G1 A', @idioma, @huso, '17:00', '23:00', 1); SET @pais1=SCOPE_IDENTITY();
INSERT equipos.Pais(NOMBRE, Idioma, HusoHorario, PtIni, PtFin, PBI) VALUES('Prueba G1 B', @idioma, @huso, '17:00', '23:00', 1); SET @pais2=SCOPE_IDENTITY();
INSERT equipos.Grupo(NOMBRE) VALUES('Prueba G1'); SET @grupo=SCOPE_IDENTITY();
INSERT sedes.Mundial(IdPais,ACTIVIDAD_FECHA_INICIO,ACTIVIDAD_FECHA_FIN,TAMANIO_SELECCION_MINIMO,TAMANIO_SELECCION_MAXIMO,
 CAMBIOS_VENTANAS,CAMBIOS_CANTIDAD,SUSPENSION_TARJETAS_MAXIMAS,SUSPENSION_TIEMPO)
 VALUES(@pais1,'20260601','20260731',0,26,10,10,2,1); SET @mundial=SCOPE_IDENTITY();
INSERT equipos.Seleccion(IdPais,IdMundial,IdGrupo,CONFEDERACION) VALUES(@pais1,@mundial,@grupo,'Prueba'); SET @s1=SCOPE_IDENTITY();
INSERT equipos.Seleccion(IdPais,IdMundial,IdGrupo,CONFEDERACION) VALUES(@pais2,@mundial,@grupo,'Prueba'); SET @s2=SCOPE_IDENTITY();
INSERT sedes.Sede(Nombre,Ciudad,Capacidad,IdPais,IdHuso) VALUES('Prueba G1','Prueba',50000,@pais1,@huso); SET @sede=SCOPE_IDENTITY();
INSERT partidos.Fase(Descripcion) VALUES('Final'); SET @fase=SCOPE_IDENTITY();
INSERT partidos.Partido(IdFase,IdSede,IdMundial,Eq1,Eq2,Fecha,HoraUTC,HoraLocal)
 VALUES(@fase,@sede,@mundial,@s1,@s2,'20260701','18:00','18:00'); SET @p1=SCOPE_IDENTITY();
INSERT partidos.Partido(IdFase,IdSede,IdMundial,Eq1,Eq2,Fecha,HoraUTC,HoraLocal)
 VALUES(@fase,@sede,@mundial,@s1,@s2,'20260708','18:00','18:00'); SET @p2=SCOPE_IDENTITY();
INSERT partidos.Periodo(IdPeriodo,Descripcion,Inicio,Fin,EsPenales) VALUES(901,'Juego',0,120,0),(902,'Penales',NULL,NULL,1);
INSERT publicidad.Motivo(Descripcion) VALUES('Lesion'); SET @motivo=SCOPE_IDENTITY();
DECLARE @jugadores TABLE(Numero INT,Id INT);
WHILE @i<=16
BEGIN
 INSERT equipos.Persona(Nombre,Fnac,Rol,Pais) VALUES(CONCAT('Prueba G1 jugador ',@i),'20000101','Jugador',@pais1);
 SET @persona=SCOPE_IDENTITY();
 INSERT equipos.Jugador(IdJugador,Estado,Posicion,Numero,Seleccion) VALUES(@persona,'Activo','MED',@i,@s1);
 INSERT @jugadores VALUES(@i,@persona);
 SET @i+=1;
END;
INSERT equipos.Persona(Nombre,Fnac,Rol,Pais) VALUES('Prueba G1 arbitro','19800101','Arbitro',@pais2); SET @arbitro=SCOPE_IDENTITY();
INSERT arbitros.Arbitro(IdArbitro,Categoria) VALUES(@arbitro,'FIFA');
INSERT arbitros.Arbitraje(Arbitro,Funcion,Partido) VALUES(@arbitro,'Principal',@p1),(@arbitro,'Principal',@p2);
DECLARE @j1 INT=(SELECT Id FROM @jugadores WHERE Numero=1),@j2 INT=(SELECT Id FROM @jugadores WHERE Numero=2),
 @j12 INT=(SELECT Id FROM @jugadores WHERE Numero=12),@j13 INT=(SELECT Id FROM @jugadores WHERE Numero=13),
 @j14 INT=(SELECT Id FROM @jugadores WHERE Numero=14),@j15 INT=(SELECT Id FROM @jugadores WHERE Numero=15),
 @j16 INT=(SELECT Id FROM @jugadores WHERE Numero=16),@gol INT,@evento INT,@cantidad INT;

-- alta y edicion de idioma y asignacion.
EXEC SP.uspIdioma_Registrar 'Idioma prueba'; SELECT @persona=IdIdioma FROM arbitros.Idioma WHERE Descripcion='Idioma prueba'; EXEC SP.uspIdioma_Update @persona,'Idioma editado'; EXEC SP.uspHablaIdioma_Registrar @arbitro,@persona;
IF NOT EXISTS(SELECT 1 FROM arbitros.HablaIdioma WHERE Arbitro=@arbitro AND Idioma=@persona)
 THROW 51998,'Fallo: alta y edicion de idioma y asignacion.',1;
PRINT 'OK 1: alta y edicion de idioma y asignacion';

BEGIN TRY
 EXEC SP.uspHablaIdioma_Registrar -1,-1;
 THROW 51999,'La operacion debio rechazarse.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) OR ERROR_MESSAGE() NOT LIKE '%Arbitro%' OR ERROR_MESSAGE() NOT LIKE '%Idioma%' THROW;
END CATCH;
PRINT 'OK 2: agrupa errores de idioma del arbitro';

BEGIN TRY
 EXEC SP.uspIdioma_Bajar @persona;
 THROW 51999,'La operacion debio rechazarse.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) OR ERROR_MESSAGE() NOT LIKE '%HablaIdioma%' THROW;
END CATCH;
PRINT 'OK 3: protege idioma asignado';
UPDATE partidos.Partido SET Fecha='20000101' WHERE IdPartido=@p1;

-- alta y edicion de informe.
EXEC SP.uspReporte_Registrar 'Sancion','Prueba',@arbitro,@p1; SELECT @evento=MAX(IdReporte) FROM arbitros.Reporte; EXEC SP.uspReporte_Update @evento,@descripcion='Editado';
IF NOT EXISTS(SELECT 1 FROM arbitros.Reporte WHERE IdReporte=@evento AND Descripcion='Editado')
 THROW 51998,'Fallo: alta y edicion de informe.',1;
PRINT 'OK 4: alta y edicion de informe';

BEGIN TRY
 EXEC SP.uspReporte_Registrar NULL,NULL,-1,-1;
 THROW 51999,'La operacion debio rechazarse.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN (50000,51000) OR ERROR_MESSAGE() NOT LIKE '%Razon%' OR ERROR_MESSAGE() NOT LIKE '%Descripcion%' OR ERROR_MESSAGE() NOT LIKE '%Arbitro%' OR ERROR_MESSAGE() NOT LIKE '%Partido%' THROW;
END CATCH;
PRINT 'OK 5: agrupa errores de informe';

-- bajas de informe e idioma.
EXEC SP.uspReporte_Baja @evento; EXEC SP.uspHablaIdioma_Bajar @arbitro,@persona; EXEC SP.uspIdioma_Bajar @persona;
IF EXISTS(SELECT 1 FROM arbitros.Reporte WHERE IdReporte=@evento) OR EXISTS(SELECT 1 FROM arbitros.Idioma WHERE IdIdioma=@persona)
 THROW 51998,'Fallo: bajas de informe e idioma.',1;
PRINT 'OK 6: bajas de informe e idioma';

PRINT '75_Test_IdiomaReporte.sql: 6 comprobaciones correctas.';
