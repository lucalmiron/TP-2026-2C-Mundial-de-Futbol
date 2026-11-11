USE MUNDIAL;
GO

--Goleadores por seleccion, fase y torneo
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspReporte_Goleadores'))
    DROP PROCEDURE SP.uspReporte_Goleadores
GO
CREATE PROCEDURE SP.uspReporte_Goleadores
@categoria VARCHAR(9),
@mundial INT
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @errorLine VARCHAR(200)

	SET @errorCount = 0
	SET @errorLine = 'Error/es:'

	IF(@categoria IS NULL) OR (@categoria NOT IN ('Seleccion', 'Fase', 'Mundial'))
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Categoria.'
	END

	IF(@mundial IS NULL) OR (@mundial <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor invalido: Mundial.'
	END

	IF (@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM sedes.Mundial WHERE IdMundial = @mundial)
	BEGIN
		SET @errorCount = @errorCount + 1
		SET @errorLine = @errorLine + CHAR(13) + '- Valor inexistente: Mundial.'
	END

	IF (@errorCount <> 0)
		PRINT @errorLine
	ELSE
	BEGIN
		IF(@categoria = 'Seleccion')
		BEGIN
			WITH golesPorJugador AS
			(
				SELECT Autor, COUNT(IdGol) AS [TOTAL DE GOLES]
				FROM partidos.Gol
				WHERE IdGol IN
				(
					SELECT IdEvento
					FROM partidos.Evento
					WHERE Partido IN (SELECT IdPartido FROM partidos.Partido WHERE IdMundial = @mundial)
				)
				GROUP BY Autor
			)
			SELECT YEAR(Mundial.ACTIVIDAD_FECHA_INICIO) AS [MUNDIAL], infoT.[SELECCION], infoT.[NOMBRE DEL JUGADOR], infoT.[TOTAL DE GOLES], infoT.RANKING
			FROM
			(
				SELECT info.IdMundial, info.[SELECCION], info.[NOMBRE DEL JUGADOR], golesPorJugador.[TOTAL DE GOLES], DENSE_RANK() OVER (ORDER BY golesPorJugador.[TOTAL DE GOLES] DESC) AS [RANKING]
				FROM
				(
					SELECT infoSeleccion.IdMundial, infoSeleccion.SELECCION, infoJugador.[NOMBRE DEL JUGADOR], infoJugador.IdJugador
					FROM
					(
						SELECT Pais.NOMBRE AS [SELECCION], Seleccion.IdSeleccion, Seleccion.IdMundial
						FROM
						equipos.Pais AS Pais INNER JOIN equipos.Seleccion AS Seleccion ON Pais.IdPais = Seleccion.IdPais
						WHERE Seleccion.IdMundial = @mundial
					) AS infoSeleccion
					INNER JOIN
					(
						SELECT Persona.Nombre AS [NOMBRE DEL JUGADOR], Jugador.Seleccion, Jugador.IdJugador
						FROM
						equipos.Persona AS Persona INNER JOIN equipos.Jugador AS Jugador ON Persona.IdPersona = Jugador.IdJugador
					) AS infoJugador
					ON infoSeleccion.IdSeleccion = infoJugador.Seleccion
				) AS info
				INNER JOIN
				golesPorJugador
				ON info.IdJugador = golesPorJugador.Autor
			) AS infoT
			INNER JOIN
			sedes.Mundial AS Mundial
			ON infoT.IdMundial = Mundial.IdMundial
		END

		IF(@categoria = 'Fase')
		BEGIN
			WITH resumen AS
			(
				SELECT infoFase.IdMundial, infoFase.[FASE], goles.Autor, COUNT(goles.IdGol) OVER (PARTITION BY infoFase.[FASE], goles.Autor) AS [TOTAL DE GOLES]
				FROM
				(
					SELECT Partido.IdMundial, Fase.Descripcion AS [FASE], Partido.IdPartido
					FROM 
					partidos.Fase AS Fase INNER JOIN partidos.Partido AS Partido ON Partido.IdFase = Fase.IdFase
					WHERE Partido.IdMundial = @mundial
				) AS infoFase
				INNER JOIN
				(
					SELECT Evento.Partido, Gol.IdGol, Gol.Autor
					FROM
					partidos.Evento AS Evento INNER JOIN partidos.Gol AS Gol ON Evento.IdEvento = Gol.IdGol
				) AS goles
				ON infoFase.IdPartido = goles.Partido
			)
			SELECT YEAR(Mundial.ACTIVIDAD_FECHA_INICIO) AS [MUNDIAL], infoT.FASE, infoT.[NOMBRE DEL JUGADOR], infoT.[TOTAL DE GOLES], infoT.RANKING
			FROM
			(
				SELECT resumen.IdMundial, resumen.[FASE], infoJugador.[NOMBRE DEL JUGADOR], resumen.[TOTAL DE GOLES], DENSE_RANK() OVER (PARTITION BY resumen.[FASE] ORDER BY resumen.[TOTAL DE GOLES] DESC) AS [RANKING]
				FROM
				(
					SELECT Persona.Nombre AS [NOMBRE DEL JUGADOR], Jugador.IdJugador
					FROM
					equipos.Persona AS Persona INNER JOIN equipos.Jugador AS Jugador ON Persona.IdPersona = Jugador.IdJugador
				) AS infoJugador
				INNER JOIN
				resumen
				ON infoJugador.IdJugador = resumen.Autor
			) AS infoT
			INNER JOIN
			sedes.Mundial AS Mundial
			ON infoT.IdMundial = Mundial.IdMundial
		END

		IF(@categoria = 'Mundial')
		BEGIN
			
			WITH resumen AS
			(
				SELECT Evento.IdMundial, Gol.Autor, COUNT(Gol.IdGol) AS [TOTAL DE GOLES]
				FROM
				(	
					SELECT E.IdEvento, Partido.IdMundial
					FROM
					partidos.Evento AS E
					INNER JOIN
					(SELECT IdPartido, IdMundial FROM partidos.Partido WHERE IdMundial = @mundial) AS Partido
					ON Evento.Partido = Partido.IdPartido
				)AS Evento 
				INNER JOIN 
				partidos.Gol AS Gol 
				ON Evento.IdEvento = Gol.IdGol
				GROUP BY Gol.Autor, Evento.IdMundial
			)
			SELECT YEAR(Mundial.ACTIVIDAD_FECHA_INICIO) AS [MUNDIAL], infoT.[NOMBRE DEL JUGADOR], infoT.[TOTAL DE GOLES], infoT.[RANKING]
			FROM
			(
				SELECT resumen.IdMundial, infoJugador.[NOMBRE DEL JUGADOR], resumen.[TOTAL DE GOLES], DENSE_RANK() OVER (ORDER BY resumen.[TOTAL DE GOLES] DESC) AS [RANKING]
				FROM
				(
					SELECT Persona.Nombre AS [NOMBRE DEL JUGADOR], Jugador.IdJugador
					FROM
					equipos.Persona AS Persona INNER JOIN equipos.Jugador AS Jugador ON Persona.IdPersona = Jugador.IdJugador
				) AS infoJugador
				INNER JOIN
				resumen
				ON resumen.Autor = infoJugador.IdJugador
			) AS infoT
			INNER JOIN
			sedes.Mundial AS Mundial
			ON infoT.IdMundial = Mundial.IdMundial
		END
	END
END;
GO

--Tarjetas (amarillas y rojas) por selección y jugador, con detalle de suspensiones activas por acumulación
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspReporte_Tarjetas'))
    DROP PROCEDURE SP.uspReporte_Tarjetas
GO
CREATE PROCEDURE SP.uspReporte_Tarjetas
@mundial INT
AS
BEGIN
	DECLARE @errorCount INT

	SET @errorCount = 0

	IF(@mundial IS NULL) OR (@mundial <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Valor invalido: Mundial.'
	END

	IF NOT EXISTS(SELECT 1 FROM sedes.Mundial WHERE IdMundial = @mundial)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Valor inexistente: Mundial.'
	END

	IF(@errorCount = 0)
	BEGIN
		WITH resumen AS
		(
			SELECT Amonestado, 
			SUM(CASE WHEN Tarjeta = 'Amarilla' THEN 1 ELSE 0 END) AS [TOTAL AMARILLAS], 
			SUM(CASE WHEN Tarjeta = 'Roja' THEN 1 ELSE 0 END) AS [TOTAL ROJAS]
			FROM partidos.Amonestacion
			WHERE IdAmonestacion
			IN
			(
				SELECT IdEvento
				FROM partidos.Evento
				WHERE Partido IN (SELECT IdPartido FROM partidos.Partido WHERE IdMundial = @mundial)
			)
			GROUP BY Amonestado
		)
		SELECT 
		YEAR(Mundial.ACTIVIDAD_FECHA_INICIO) AS [MUNDIAL], 
		infoT.SELECCION, 
		SUM(infoT.[TOTAL AMARILLAS]) OVER (PARTITION BY infoT.[SELECCION]) AS [TOTAL TARJETAS AMARILLAS EN SELECCION],
		SUM(infoT.[TOTAL ROJAS]) OVER (PARTITION BY infoT.[SELECCION]) AS [TOTAL TARJETAS ROJAS EN SELECCION],
		infoT.[NOMBRE AMONESTADO], infoT.[ESTADO], infoT.[TOTAL AMARILLAS], infoT.[TOTAL ROJAS]
		FROM
		(
			SELECT infoSeleccion.IdMundial, infoSeleccion.[SELECCION], infoMasResumen.[NOMBRE AMONESTADO], infoMasResumen.[ESTADO], infoMasResumen.[TOTAL AMARILLAS], infoMasResumen.[TOTAL ROJAS]
			FROM
			(
				SELECT infoAmonestado.Seleccion, infoAmonestado.[NOMBRE AMONESTADO], infoAmonestado.ESTADO, resumen.[TOTAL AMARILLAS], resumen.[TOTAL ROJAS]
				FROM
				(
					SELECT Persona.ID, Persona.Nombre AS [NOMBRE AMONESTADO], info.ESTADO, info.Seleccion
					FROM equipos.Persona AS Persona
					INNER JOIN
					(
						SELECT IdJugador AS ID, Seleccion, Estado AS [ESTADO] FROM equipos.Jugador
						UNION
						SELECT IdTecnico AS ID, Seleccion, Estado AS [ESTADO] FROM equipos.Tecnico
					) AS info
					ON Persona.IdPersona = info.ID
				) AS infoAmonestado
				INNER JOIN
				resumen
				ON infoAmonestado.ID = resumen.Amonestado
			) AS infoMasResumen
			INNER JOIN
			(
				SELECT Pais.NOMBRE AS [SELECCION], Seleccion.IdSeleccion, Seleccion.IdMundial
				FROM equipos.Pais AS Pais INNER JOIN equipos.Seleccion AS Seleccion ON Pais.IdPais = Seleccion.IdPais
			) AS infoSeleccion
			ON infoMasResumen.Seleccion = infoSeleccion.IdSeleccion
		) AS infoT
		INNER JOIN
		sedes.Mundial AS Mundial
		ON infoT.IdMundial = Mundial.IdMundial
	END
END;
GO

--Designaciones Arbitrales
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspReporte_Arbitraje'))
    DROP PROCEDURE SP.uspReporte_Arbitraje
GO
CREATE PROCEDURE SP.uspReporte_Arbitraje
@mundial INT
AS
BEGIN
	DECLARE @errorCount INT

	SET @errorCount = 0

	IF(@mundial IS NULL) OR (@mundial <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Valor invalido: Mundial.'
	END

	IF NOT EXISTS(SELECT 1 FROM sedes.Mundial WHERE IdMundial = @mundial)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Valor inexistente: Mundial.'
	END

	IF(@errorCount = 0)
	BEGIN
		WITH resumenPartidos AS
		(
			SELECT infoPart.IdMundial, infoPart.IdPartido, infoPart.[SELECCION 1], infoPart.[SELECCION 2], Fase.Descripcion AS [FASE]
			FROM
			(
				SELECT P.IdMundial, P.IdPartido, infoEq1.[SELECCION 1], infoEq2.[SELECCION 2], P.IdFase
				FROM partidos.Partido AS P
				INNER JOIN
				(
					SELECT Partido.IdPartido, infoSeleccion.[SELECCION 1]
					FROM
					partidos.Partido AS Partido
					INNER JOIN
					(
						SELECT Seleccion.IdSeleccion, Pais.NOMBRE AS [SELECCION 1]
						FROM equipos.Pais AS Pais INNER JOIN equipos.Seleccion AS Seleccion ON Pais.IdPais = Seleccion.IdPais
					) AS infoSeleccion
					ON Partido.Eq1 = infoSeleccion.IdSeleccion
				) AS infoEq1
				ON P.IdPartido = infoEq1.IdPartido
				INNER JOIN
				(
					SELECT Partido.IdPartido, infoSeleccion.[SELECCION 2]
					FROM
					partidos.Partido AS Partido
					INNER JOIN
					(
						SELECT Seleccion.IdSeleccion, Pais.NOMBRE AS [SELECCION 2]
						FROM equipos.Pais AS Pais INNER JOIN equipos.Seleccion AS Seleccion ON Pais.IdPais = Seleccion.IdPais
					) AS infoSeleccion
					ON Partido.Eq2 = infoSeleccion.IdSeleccion
				) AS infoEq2
				ON P.IdPartido = infoEq2.IdPartido
				WHERE P.IdMundial = @mundial
			) AS infoPart
			INNER JOIN
			partidos.Fase AS Fase
			ON infoPart.IdFase = Fase.IdFase
		)
		SELECT
		YEAR(Mundial.ACTIVIDAD_FECHA_INICIO) AS [MUNDIAL], 
		infoT.[ARBITRO],
		infoT.[PARTIDO],
		infoT.[AMONESTADO],
		infoT.[TARJETA RECIBIDA],
		infoT.[MOTIVO DE LA TARJETA]
		FROM
		(
			SELECT 
			infoB.IdMundial, 
			infoA.[ARBITRO], 
			(infoB.[SELECCION 1] + ' - ' + infoB.[SELECCION 2] + ' (' + infoB.FASE + ')') AS [PARTIDO],
			infoB.[AMONESTADO], infoB.[TARJETA RECIBIDA], infoB.[MOTIVO DE LA TARJETA]
			FROM
			(
				SELECT Arbitraje.Partido, infoArbitro.[ARBITRO]
				FROM
				(
					SELECT Arbitro.IdArbitro, P.Nombre AS [ARBITRO]
					FROM arbitros.Arbitro AS Arbitro INNER JOIN equipos.Persona AS P ON Arbitro.IdArbitro = P.IdPersona
				) AS infoArbitro
				INNER JOIN
				arbitros.Arbitraje AS Arbitraje
				ON infoArbitro.IdArbitro = Arbitraje.Arbitro
			) AS infoA
			INNER JOIN
			(
				SELECT resumenPartidos.IdMundial, 
				resumenPartidos.IdPartido, resumenPartidos.[SELECCION 1], resumenPartidos.[SELECCION 2], resumenPartidos.FASE,
				infoAmonestado.AMONESTADO, infoAmonestado.[TARJETA RECIBIDA], infoAmonestado.[MOTIVO DE LA TARJETA]
				FROM
				(
					SELECT infoAmonestacion.Partido, Persona.Nombre AS [AMONESTADO], infoAmonestacion.[TARJETA RECIBIDA], infoAmonestacion.[MOTIVO DE LA TARJETA]
					FROM
					(
						SELECT Evento.Partido, Amonestacion.Amonestado, Amonestacion.Tarjeta AS [TARJETA RECIBIDA], Amonestacion.Motivo AS [MOTIVO DE LA TARJETA]
						FROM
						partidos.Amonestacion AS Amonestacion
						INNER JOIN
						partidos.Evento AS Evento
						ON Amonestacion.IdAmonestacion = Evento.IdEvento
					) AS infoAmonestacion
					INNER JOIN
					equipos.Persona AS Persona
					ON infoAmonestacion.Amonestado = Persona.IdPersona
				) AS infoAmonestado
				INNER JOIN
				resumenPartidos
				ON infoAmonestado.Partido = resumenPartidos.IdPartido
			) AS infoB
			ON infoA.Partido = infoB.IdPartido
		) AS infoT
		INNER JOIN
		sedes.Mundial AS Mundial
		ON infoT.IdMundial = Mundial.IdMundial
	END
END;
GO

--Ocupacion publicitaria por sede y partido
--con salida a XML
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspReporte_Publicidad'))
    DROP PROCEDURE SP.uspReporte_Publicidad
GO
CREATE PROCEDURE SP.uspReporte_Publicidad
@mundial INT
AS
BEGIN
	DECLARE @errorCount INT

	SET @errorCount = 0

	IF(@mundial IS NULL) OR (@mundial <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Valor invalido: Mundial.'
	END

	IF NOT EXISTS(SELECT 1 FROM sedes.Mundial WHERE IdMundial = @mundial)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Valor inexistente: Mundial.'
	END

	IF(@errorCount = 0)
	BEGIN
		WITH resumenPartidos AS
		(
			SELECT B.IdMundial, B.IdPartido, A.Nombre AS [SEDE], (B.[SELECCION 1] + ' - ' + B.[SELECCION 2] + ' (' + B.[FASE] + ')') AS [PARTIDO]
			FROM
			sedes.Sede AS A
			INNER JOIN
			(
				SELECT infoPart.IdMundial, infoPart.IdPartido, infoPart.IdSede, infoPart.[SELECCION 1], infoPart.[SELECCION 2], Fase.Descripcion AS [FASE]
				FROM
				(
					SELECT P.IdMundial, P.IdPartido, P.IdSede, infoEq1.[SELECCION 1], infoEq2.[SELECCION 2], P.IdFase
					FROM partidos.Partido AS P
					INNER JOIN --join de partido P con info del equipo 1
					(
						SELECT Partido1.IdPartido, Pais1.NOMBRE AS [SELECCION 1]
						FROM
						partidos.Partido AS Partido1
						INNER JOIN
						equipos.Seleccion AS Seleccion1
						ON Partido1.Eq1 = Seleccion1.IdSeleccion
						INNER JOIN
						equipos.Pais AS Pais1
						ON Seleccion1.IdPais = Pais1.IdPais
					) AS infoEq1 --info del equipo 1 (Tomo el nombre del pais del equipo como SELECCION)
					ON P.IdPartido = infoEq1.IdPartido
					INNER JOIN --join de partido P con info del equipo 2
					(
						SELECT Partido2.IdPartido, Pais2.NOMBRE AS [SELECCION 2]
						FROM
						partidos.Partido AS Partido2
						INNER JOIN
						equipos.Seleccion AS Seleccion2
						ON Partido2.Eq2 = Seleccion2.IdSeleccion
						INNER JOIN
						equipos.Pais AS Pais2
						ON Seleccion2.IdPais = Pais2.IdPais
					) AS infoEq2 --info del equipo 2 (Tomo el nombre del pais del equipo como SELECCION)
					ON P.IdPartido = infoEq2.IdPartido
					WHERE P.IdMundial = @mundial
				) AS infoPart
				INNER JOIN
				partidos.Fase AS Fase
				ON infoPart.IdFase = Fase.IdFase
			) AS B
			ON A.IdSede = B.IdSede
		)
		SELECT
		YEAR(Mundial.ACTIVIDAD_FECHA_INICIO) AS [MUNDIAL], 
		infoT.[SEDE], infoT.[PARTIDO],
		infoT.[PUBLICIDAD], infoT.[CAMPAÑA], infoT.[ANUNCIANTE], infoT.[COSTO CONTRATACION], 
		infoT.[INGRESO TOTAL DE LA SEDE]
		FROM
		(
			SELECT 
			resumenPartidos.IdMundial, 
			resumenPartidos.[SEDE], resumenPartidos.[PARTIDO], 
			infoPublicidad.[PUBLICIDAD], infoPublicidad.[CAMPAÑA], infoPublicidad.[ANUNCIANTE], infoPublicidad.[COSTO CONTRATACION],
			SUM(infoPublicidad.[COSTO CONTRATACION]) OVER (PARTITION BY resumenPartidos.[SEDE]) AS [INGRESO TOTAL DE LA SEDE]
			FROM
			resumenPartidos
			INNER JOIN
			(
				SELECT 
				Historial.IdPartido, 
				Publicidad.Nombre AS [PUBLICIDAD], infoAnuncianteCampania.[CAMPAÑA], infoAnuncianteCampania.[ANUNCIANTE], 
				Historial.CostoFinal AS [COSTO CONTRATACION]
				FROM 
				publicidad.HistorialPublicidad AS Historial
				INNER JOIN
				publicidad.Publicidad AS Publicidad
				ON Historial.IdPublicidad = Publicidad.IdPublicidad --uno Historial con Publicidad
				INNER JOIN
				(
					SELECT Campania.IdCampania, Campania.Nombre AS [CAMPAÑA], infoAnunciante.[ANUNCIANTE]
					FROM
					publicidad.Campania AS Campania
					INNER JOIN
					(
						SELECT AnunCamp.IdCampania, Anunciante.Nombre AS [ANUNCIANTE]
						FROM 
						publicidad.AnuncianteCampania AS AnunCamp
						INNER JOIN
						publicidad.Anunciante AS Anunciante
						ON AnunCamp.IdAnunciante = Anunciante.IdAnunciante
					) AS infoAnunciante
					ON Campania.IdCampania = infoAnunciante.IdCampania
				) AS infoAnuncianteCampania
				ON Publicidad.IdCampania = infoAnuncianteCampania.IdCampania --join Publicidad con infoAnuncianteCampania
			) AS infoPublicidad
			ON resumenPartidos.IdPartido = infoPublicidad.IdPartido
		) AS infoT
		INNER JOIN
		sedes.Mundial AS Mundial
		ON infoT.IdMundial = Mundial.IdMundial
		FOR XML RAW ('Publicidad'), ROOT('ReportePublicidad'), ELEMENTS
	END
END;
GO

--Selecciones y plantillas: listado de selecciones con un vector anidado de convocados (nombre, posición, club, dorsal).
--con salida a XML
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspReporte_Convocados'))
    DROP PROCEDURE SP.uspReporte_Convocados
GO
CREATE PROCEDURE SP.uspReporte_Convocados
@mundial INT
AS
BEGIN
	DECLARE @errorCount INT

	SET @errorCount = 0

	IF(@mundial IS NULL) OR (@mundial <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Valor invalido: Mundial.'
	END

	IF NOT EXISTS(SELECT 1 FROM sedes.Mundial WHERE IdMundial = @mundial)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Valor inexistente: Mundial.'
	END

	IF(@errorCount = 0)
	BEGIN
		SELECT 
		YEAR(Mundial.ACTIVIDAD_FECHA_INICIO) AS [MUNDIAL], 
		infoSeleccion.[SELECCION],
		infoJugador.[CONVOCADO], infoJugador.[POSICION], infoJugador.[NUMERO], Club.Nombre AS [CLUB]
		FROM
		sedes.Mundial AS Mundial
		INNER JOIN
		(
			SELECT Seleccion.IdMundial, Seleccion.IdSeleccion, Pais.NOMBRE AS [SELECCION]
			FROM equipos.Seleccion AS Seleccion INNER JOIN equipos.Pais AS Pais ON Seleccion.IdPais = Pais.IdPais
		) AS infoSeleccion
		ON Mundial.IdMundial = infoSeleccion.IdMundial
		INNER JOIN
		(
			SELECT Jugador.Seleccion, Persona.Nombre AS [CONVOCADO], Jugador.Posicion AS [POSICION], Jugador.Numero AS [NUMERO], Jugador.Club
			FROM equipos.Persona AS Persona INNER JOIN equipos.Jugador AS Jugador ON Persona.IdPersona = Jugador.IdJugador
		) AS infoJugador
		ON infoSeleccion.IdSeleccion = infoJugador.Seleccion
		LEFT JOIN
		equipos.Club AS Club
		ON infoJugador.Club = Club.IdClub
		WHERE Mundial.IdMundial = @mundial
		FOR XML RAW ('Convocado'), ROOT('ReporteConvocados'), ELEMENTS
	END
END;
GO

--Resultados de encuentros
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspReporte_Partidos'))
    DROP PROCEDURE SP.uspReporte_Partidos
GO
CREATE PROCEDURE SP.uspReporte_Partidos
@mundial INT
AS
BEGIN
	DECLARE @errorCount INT

	SET @errorCount = 0

	IF(@mundial IS NULL) OR (@mundial <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Valor invalido: Mundial.'
	END

	IF NOT EXISTS(SELECT 1 FROM sedes.Mundial WHERE IdMundial = @mundial)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Valor inexistente: Mundial.'
	END

	IF(@errorCount = 0)
	BEGIN
		WITH resumenPartidos AS
		(
			SELECT 
			infoPart.IdMundial, 
			Fase.Descripcion AS [FASE], 
			(infoPart.[SELECCION 1] + ' ' + 
			SRT(infoPart.GolesEq1) + '(' + SRT(infoPart.PenalesEq1) + ')' + 
			' - ' + 
			SRT(infoPart.GolesEq2) + '(' + SRT(infoPart.PenalesEq2) + ')' +
			' ' + infoPart.[SELECCION 2]) AS [RESULTADO DEL PARTIDO]
			FROM
			(
				SELECT P.IdMundial, P.IdFase, infoEq1.[SELECCION 1], infoEq2.[SELECCION 2], P.GolesEq1, P.GolesEq2, P.PenalesEq1, P.PenalesEq2
				FROM partidos.Partido AS P
				INNER JOIN
				(
					SELECT Partido1.IdPartido, Pais1.NOMBRE AS [SELECCION 1]
					FROM
					partidos.Partido AS Partido1
					INNER JOIN
					equipos.Seleccion AS Seleccion1
					ON Partido1.Eq1 = Seleccion1.IdSeleccion
					INNER JOIN
					equipos.Pais AS Pais1
					ON Seleccion1.IdPais = Pais1.IdPais
				) AS infoEq1
				ON P.IdPartido = infoEq1.IdPartido
				INNER JOIN
				(
					SELECT Partido2.IdPartido, Pais2.NOMBRE AS [SELECCION 2]
					FROM
					partidos.Partido AS Partido2
					INNER JOIN
					equipos.Seleccion AS Seleccion2
					ON Partido2.Eq2 = Seleccion2.IdSeleccion
					INNER JOIN
					equipos.Pais AS Pais2
					ON Seleccion2.IdPais = Pais2.IdPais
				) AS infoEq2
				ON P.IdPartido = infoEq2.IdPartido
				WHERE P.IdMundial = @mundial
			) AS infoPart
			INNER JOIN
			partidos.Fase AS Fase
			ON infoPart.IdFase = Fase.IdFase
		)
		SELECT 
		YEAR(Mundial.ACTIVIDAD_FECHA_INICIO) AS [MUNDIAL],
		resumenPartidos.[FASE],
		resumenPartidos.[RESULTADO DEL PARTIDO]
		FROM
		resumenPartidos
		INNER JOIN
		sedes.Mundial AS Mundial
		ON resumenPartidos.IdMundial = Mundial.IdMundial
	END
END;
GO


--Pivot de primetime
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspReporte_Primetime'))
    DROP PROCEDURE SP.uspReporte_Primetime
GO
CREATE PROCEDURE SP.uspReporte_Primetime
@mundial INT
AS
BEGIN
	DECLARE @errorCount INT
	DECLARE @i INT, @cant INT
	DECLARE @horaUTC TIME, @horaLocal TIME
	DECLARE @fechaP DATE
	DECLARE @huso VARCHAR(50), @paises VARCHAR(MAX), @query VARCHAR(MAX)
	DECLARE @general TABLE
	(
		ID INT IDENTITY(1, 1) PRIMARY KEY,
		MUNDIAL INT,
		PARTIDO VARCHAR(130),
		[HORARIO DEL PARTIDO] TIME,
		[FECHA DEL PARTIDO] DATE,
		PAIS VARCHAR(50),
		[INICIO PRIMETIME] TIME,
		[FIN PRIMETIME] TIME,
		[HUSO HORARIO] VARCHAR(50)
	)
	DECLARE @final TABLE
	(
		ID INT IDENTITY(1, 1) PRIMARY KEY,
		MUNDIAL INT,
		PARTIDO VARCHAR(130),
		PAIS VARCHAR(50),
		SEGMENTO CHAR(9)
	)

	SET @errorCount = 0
	SET @i = 1

	IF(@mundial IS NULL) OR (@mundial <= 0)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Valor invalido: Mundial.'
	END

	IF NOT EXISTS(SELECT 1 FROM sedes.Mundial WHERE IdMundial = @mundial)
	BEGIN
		SET @errorCount = @errorCount + 1
		PRINT '-ERROR- Valor inexistente: Mundial.'
	END

	IF(@errorCount = 0)
	BEGIN
		--ETAPA 1---------------------------------------------
		--llenado de tabla @general con toda la info que necesito a traves de un cross join de partido con pais
		INSERT INTO @general(MUNDIAL, PARTIDO, [HORARIO DEL PARTIDO], [FECHA DEL PARTIDO], PAIS, [INICIO PRIMETIME], [FIN PRIMETIME], [HUSO HORARIO])
		SELECT 
		Partido.[MUNDIAL], Partido.[PARTIDO], Partido.[HORARIO DEL PARTIDO], Partido.[FECHA DEL PARTIDO],
		Pais.[PAIS], Pais.[INICIO PRIMETIME], Pais.[FIN PRIMETIME], Pais.[HUSO HORARIO]
		FROM
		(
			SELECT 
			Pais.NOMBRE AS [PAIS], 
			Pais.PtIni AS [INICIO PRIMETIME], Pais.PtFin AS [FIN PRIMETIME], 
			Huso.Nombre AS [HUSO HORARIO]
			FROM
			equipos.Pais AS Pais
			INNER JOIN
			sedes.HusoHorario AS Huso
			ON Pais.HusoHorario = Huso.IdHuso
		) AS Pais
		CROSS JOIN
		(
			SELECT 
			Mundial.ACTIVIDAD_FECHA_INICIO AS [MUNDIAL],
			resumenPartidos.[PARTIDO],
			resumenPartidos.[HORARIO DEL PARTIDO], resumenPartidos.[FECHA DEL PARTIDO]
			FROM
			(
				SELECT 
				infoPart.IdMundial, 
				(infoPart.[SELECCION 1] + ' - ' + infoPart.[SELECCION 2] + ' (' + Fase.Descripcion + ')') AS [PARTIDO],
				infoPart.[HORARIO DEL PARTIDO], infoPart.[FECHA DEL PARTIDO]
				FROM
				(
					SELECT 
					P.IdMundial, P.IdFase, 
					infoEq1.[SELECCION 1], infoEq2.[SELECCION 2],
					P.HoraUTC AS [HORARIO DEL PARTIDO], P.Fecha AS [FECHA DEL PARTIDO]
					FROM partidos.Partido AS P
					INNER JOIN
					(
						SELECT Partido1.IdPartido, Pais1.NOMBRE AS [SELECCION 1]
						FROM
						partidos.Partido AS Partido1
						INNER JOIN
						equipos.Seleccion AS Seleccion1
						ON Partido1.Eq1 = Seleccion1.IdSeleccion
						INNER JOIN
						equipos.Pais AS Pais1
						ON Seleccion1.IdPais = Pais1.IdPais
					) AS infoEq1
					ON P.IdPartido = infoEq1.IdPartido
					INNER JOIN
					(
						SELECT Partido2.IdPartido, Pais2.NOMBRE AS [SELECCION 2]
						FROM
						partidos.Partido AS Partido2
						INNER JOIN
						equipos.Seleccion AS Seleccion2
						ON Partido2.Eq2 = Seleccion2.IdSeleccion
						INNER JOIN
						equipos.Pais AS Pais2
						ON Seleccion2.IdPais = Pais2.IdPais
					) AS infoEq2
					ON P.IdPartido = infoEq2.IdPartido
					WHERE P.IdMundial = @mundial
				) AS infoPart
				INNER JOIN
				partidos.Fase AS Fase
				ON infoPart.IdFase = Fase.IdFase
			) AS resumenPartidos
			INNER JOIN
			sedes.Mundial AS Mundial
			ON resumenPartidos.IdMundial = Mundial.IdMundial
		) AS Partido

		--ETAPA 2---------------------------------------------
		SET @cant = (SELECT COUNT(ID) FROM @general)

		--proceso registro por registro sobre @general
		WHILE (@id <= @cant)
		BEGIN
			--obtengo los datos que necesito
			SET @huso = (SELECT [HUSO HORARIO] FROM @general WHERE ID = @i)
			SET @horaUTC = (SELECT [HORARIO DEL PARTIDO] FROM @general WHERE ID = @i)
			SET @fechaP = (SELECT [FECHA DEL PARTIDO] FROM @general WHERE ID = @i)

			--utilizo la API para hacer la conversion del horario del partido al horario local del pais
			EXEC SP.uspAPIconversionHora 
			@fecha = @fechaP,
			@hora = @horaUTC,
			@timezone = @huso,
			@horaConv = @horaLocal OUTPUT

			--si el horario del partido (convertido) corresponde a la franja de primetime del pais, lo registro en @final
			IF EXISTS (SELECT 1 FROM @general WHERE ([INICIO PRIMETIME] <= @horaLocal) AND (@horaLocal <= [FIN PRIMETIME]) AND (ID = @i))
			BEGIN
				INSERT INTO @final(MUNDIAL, PARTIDO, PAIS)
				SELECT MUNDIAL, PARTIDO, PAIS
				FROM @general 
				WHERE ID = @i
			END

			SET @i = @i + 1
		END

		--ETAPA 3---------------------------------------------
		--agrego el valor 'PRIMETIME' al campo Segmento en todo @final
		UPDATE @final
		SET SEGMENTO = 'PRIMETIME'

		--recorro @final registro por registro para obtener todos los paises (columnas en la tabla pivot) y asi poder armar el string dinamico
		SET @i = 1
		SET @cant = (SELECT COUNT(ID) FROM @final)
		SET @paises = '('

		WHILE (@i <= @cant)
		BEGIN
			SET @paises = @paises + '[' + (SELECT PAIS FROM @final WHERE ID = @i) + ']'

			IF (@i <> @cant)
				SET @paises = @paises + ', '
			ELSE
				SET @paises = @paises + ')'

			SET @id = @id + 1
		END

		--armo el string final
		SET @query = 'SELECT * FROM @final PIVOT (MAX(SEGMENTO) FOR PAIS IN ' + @paises + ') AS reporte'

		--ejecuto el query
		EXEC (@query)
	END
END;
GO
