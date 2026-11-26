-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Comision 02
-- Grupo 7: Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 25/11/2026.
-- Objetivo: Entrega 9 / Fase 1 - capa de datos plana para Power BI.
-- Crea el esquema reportes (si no existe) y 7 vistas sin parametros ni XML,
-- ademas de dar SELECT al rol de consulta de la Entrega 8.
-- Idempotente: CREATE OR ALTER VIEW, se puede repetir sin efecto.
-- Ejecutar DESPUES del instalador 00_Ejecutar_Todo.sql (ya trae 15_Tabla_Sede
-- con Latitud/Longitud y 99/100 con los roles y usuarios).
-- Ejecutar en la base seleccionada por el instalador (MUNDIAL / MUNDIALtesting).
GO

-- CREATE SCHEMA no admite IF en T-SQL (debe ser la primera instruccion del
-- lote); este EXECUTE es la unica excepcion de DDL al "sin SQL dinamico" y
-- existe solo en 01_Base_Mundial.sql. Se repite aca para que el script sea
-- autonomo si se ejecuta suelto.
IF SCHEMA_ID(N'reportes') IS NULL
    EXECUTE(N'CREATE SCHEMA reportes');
GO

-- Partidos: una fila por partido con los nombres ya resueltos.
CREATE OR ALTER VIEW reportes.vPartidos AS
    SELECT p.IdPartido,
           p.IdMundial,
           f.Descripcion AS Fase,
           p.Fecha,
           p.HoraLocal,
           p.HoraUTC,
           s.Nombre AS Sede,
           s.Ciudad,
           pa1.NOMBRE AS Eq1,
           pa2.NOMBRE AS Eq2,
           p.GolesEq1,
           p.GolesEq2,
           p.PenalesEq1,
           p.PenalesEq2,
           p.Asistencia
    FROM partidos.Partido AS p
    JOIN partidos.Fase AS f ON f.IdFase = p.IdFase
    JOIN sedes.Sede AS s ON s.IdSede = p.IdSede
    JOIN equipos.Seleccion AS se1 ON se1.IdSeleccion = p.Eq1
    JOIN equipos.Pais AS pa1 ON pa1.IdPais = se1.IdPais
    JOIN equipos.Seleccion AS se2 ON se2.IdSeleccion = p.Eq2
    JOIN equipos.Pais AS pa2 ON pa2.IdPais = se2.IdPais;
GO

-- Goleadores: misma exclusion que el SP de la entrega 7 (sin tandas ni goles
-- en contra) apoyada en partidos.vGolesComputables.
CREATE OR ALTER VIEW reportes.vGoleadores AS
    SELECT j.IdJugador,
           pe.Nombre AS Autor,
           pa.NOMBRE AS Seleccion,
           g.Tipo,
           f.Descripcion AS Fase,
           p.IdMundial AS Mundial,
           COUNT(*) AS Goles
    FROM partidos.vGolesComputables AS vc
    JOIN partidos.Gol AS g ON g.IdGol = vc.IdGol
    JOIN equipos.Jugador AS j ON j.IdJugador = g.Autor
    JOIN equipos.Persona AS pe ON pe.IdPersona = j.IdJugador
    JOIN equipos.Seleccion AS se ON se.IdSeleccion = j.Seleccion
    JOIN equipos.Pais AS pa ON pa.IdPais = se.IdPais
    JOIN partidos.Partido AS p ON p.IdPartido = vc.Partido
    JOIN partidos.Fase AS f ON f.IdFase = p.IdFase
    GROUP BY j.IdJugador, pe.Nombre, pa.NOMBRE, g.Tipo,
             f.Descripcion, p.IdMundial;
GO

-- Tarjetas: el amonestado puede ser jugador o tecnico (carga 19). Se toma la
-- seleccion de uno u otro con COALESCE para no perder a los entrenadores.
CREATE OR ALTER VIEW reportes.vTarjetas AS
    SELECT a.IdAmonestacion,
           pe.Nombre AS Amonestado,
           COALESCE(paj.NOMBRE, pat.NOMBRE) AS Seleccion,
           a.Tarjeta,
           a.Motivo,
           e.Partido,
           f.Descripcion AS Fase,
           p.IdMundial
    FROM partidos.Amonestacion AS a
    JOIN partidos.Evento AS e ON e.IdEvento = a.IdAmonestacion
    JOIN equipos.Persona AS pe ON pe.IdPersona = a.Amonestado
    LEFT JOIN equipos.Jugador AS j ON j.IdJugador = a.Amonestado
    LEFT JOIN equipos.Seleccion AS sej ON sej.IdSeleccion = j.Seleccion
    LEFT JOIN equipos.Pais AS paj ON paj.IdPais = sej.IdPais
    LEFT JOIN equipos.Tecnico AS t ON t.IdTecnico = a.Amonestado
    LEFT JOIN equipos.Seleccion AS sete ON sete.IdSeleccion = t.Seleccion
    LEFT JOIN equipos.Pais AS pat ON pat.IdPais = sete.IdPais
    JOIN partidos.Partido AS p ON p.IdPartido = e.Partido
    JOIN partidos.Fase AS f ON f.IdFase = p.IdFase;
GO

-- Arbitraje: una fila por designacion. El modelo no tiene columna de sancion,
-- asi que se expone NULL en vez de inventar un dato.
CREATE OR ALTER VIEW reportes.vArbitraje AS
    SELECT pe.Nombre AS Arbitro,
           ar.Categoria,
           aa.Funcion,
           aa.Partido,
           f.Descripcion AS Fase,
           p.IdMundial,
           CONVERT(VARCHAR(50), NULL) AS Sancion
    FROM arbitros.Arbitraje AS aa
    JOIN arbitros.Arbitro AS ar ON ar.IdArbitro = aa.Arbitro
    JOIN equipos.Persona AS pe ON pe.IdPersona = ar.IdArbitro
    JOIN partidos.Partido AS p ON p.IdPartido = aa.Partido
    JOIN partidos.Fase AS f ON f.IdFase = p.IdFase;
GO

-- Publicidad: historial de publicidad en partidos, con campania y anunciante.
CREATE OR ALTER VIEW reportes.vPublicidad AS
    SELECT h.IdPartido,
           p.Fecha,
           s.Nombre AS Sede,
           ep.Numero AS Espacio,
           ep.Tipo AS TipoEspacio,
           pub.Nombre AS Publicidad,
           c.Nombre AS Campania,
          anunciante.Nombre AS Anunciante,
           h.CostoFinal
    FROM publicidad.HistorialPublicidad AS h
    JOIN partidos.Partido AS p ON p.IdPartido = h.IdPartido
    JOIN sedes.Sede AS s ON s.IdSede = p.IdSede
    JOIN publicidad.EspacioPublicitario AS ep ON ep.IdEP = h.IdEP
    JOIN publicidad.Publicidad AS pub ON pub.IdPublicidad = h.IdPublicidad
    JOIN publicidad.Campania AS c ON c.IdCampania = pub.IdCampania
    OUTER APPLY (
        SELECT MIN(an.Nombre) AS Nombre
        FROM publicidad.AnuncianteCampania AS ac
        JOIN publicidad.Anunciante AS an ON an.IdAnunciante = ac.IdAnunciante
        WHERE ac.IdCampania = c.IdCampania
    ) AS anunciante;
GO

-- Convocados: plantel de cada seleccion (jugadores, no cuerpos tecnicos).
CREATE OR ALTER VIEW reportes.vConvocados AS
    SELECT se.IdSeleccion,
           pa.NOMBRE AS Seleccion,
           j.IdJugador,
           pe.Nombre AS Jugador,
           j.Posicion,
           j.Numero AS Dorsal,
           c.Nombre AS Club,
           j.Estado
    FROM equipos.Jugador AS j
    JOIN equipos.Persona AS pe ON pe.IdPersona = j.IdJugador
    JOIN equipos.Seleccion AS se ON se.IdSeleccion = j.Seleccion
    JOIN equipos.Pais AS pa ON pa.IdPais = se.IdPais
    LEFT JOIN equipos.Club AS c ON c.IdClub = j.Club;
GO

-- Sedes: incluye las coordenadas que agrego Kilo para el visual de mapa.
CREATE OR ALTER VIEW reportes.vSedes AS
    SELECT s.IdSede,
           s.Nombre AS Estadio,
           s.Ciudad,
           pa.NOMBRE AS Pais,
           s.Capacidad,
           h.Nombre AS Huso,
           s.Latitud,
           s.Longitud
    FROM sedes.Sede AS s
    JOIN equipos.Pais AS pa ON pa.IdPais = s.IdPais
    LEFT JOIN sedes.HusoHorario AS h ON h.IdHuso = s.IdHuso;
GO

-- Seguridad: solo lectura para el rol de consulta de la entrega 8.
IF DATABASE_PRINCIPAL_ID(N'rol_Consulta') IS NOT NULL
    GRANT SELECT ON SCHEMA::reportes TO rol_Consulta;
GO

PRINT 'Vistas de reportes para Power BI creadas.';
GO
