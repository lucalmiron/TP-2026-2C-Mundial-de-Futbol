USE MUNDIALtesting;
GO

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
						SELECT Partido.IdPartido, infoSeleccion.[SELECCION 1]
						FROM
						partidos.Partido AS Partido
						INNER JOIN
						(
							SELECT Seleccion.IdSeleccion, Pais.NOMBRE AS [SELECCION 1]
							FROM equipos.Pais AS Pais INNER JOIN equipos.Seleccion AS Seleccion ON Pais.IdPais = Seleccion.IdPais
						) AS infoSeleccion
						ON Partido.Eq1 = infoSeleccion.IdSeleccion
					) AS infoEq1 --info del equipo 1 (Tomo el nombre del pais del equipo como SELECCION)
					ON P.IdPartido = infoEq1.IdPartido
					INNER JOIN --join de partido P con info del equipo 2
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
	END
END;
GO