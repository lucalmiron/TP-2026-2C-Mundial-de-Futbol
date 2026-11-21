--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: --/--/--

--Creacion de Stored Procedures para generacion de Reportes (entrega 7)

-- El instalador 00_Ejecutar_Todo.sql ya selecciona la base activa
-- (MUNDIAL o MUNDIALtesting), asi que no se fuerza el USE MUNDIAL aqui.
GO

--Goleadores por seleccion, fase y torneo
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspReporte_Goleadores'))
    DROP PROCEDURE SP.uspReporte_Goleadores
GO
CREATE PROCEDURE SP.uspReporte_Goleadores
@categoria VARCHAR(9),
@mundial INT
WITH EXECUTE AS OWNER
AS
BEGIN
	-- Abrir clave simetrica para descifrado de nombres (Entrega 8)
	OPEN SYMMETRIC KEY ClaveSimetrica_AES128_Mundial
	DECRYPTION BY CERTIFICATE CertificadoCifradoMundial
	WITH PASSWORD = 'ClaveMaestra_Mundial_2026!';

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
				SELECT info.IdMundial, info.[SELECCION], info.[NOMBRE DEL JUGADOR], 
				golesPorJugador.[TOTAL DE GOLES], 
				DENSE_RANK() OVER (PARTITION BY info.[SELECCION] ORDER BY golesPorJugador.[TOTAL DE GOLES] DESC) AS [RANKING]
				FROM
				(
					SELECT infoSeleccion.IdMundial, infoSeleccion.SELECCION, infoJugador.[NOMBRE DEL JUGADOR], infoJugador.IdJugador
					FROM
					(
						SELECT Seleccion.IdMundial, Seleccion.IdSeleccion, Pais.NOMBRE AS [SELECCION]
						FROM
						equipos.Pais AS Pais INNER JOIN equipos.Seleccion AS Seleccion ON Pais.IdPais = Seleccion.IdPais
						WHERE Seleccion.IdMundial = @mundial

					) AS infoSeleccion
					INNER JOIN
					(
						SELECT CONVERT(NVARCHAR(30), DECRYPTBYKEY(Persona.Nombre)) AS [NOMBRE DEL JUGADOR], Jugador.Seleccion, Jugador.IdJugador
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
				SELECT infoFase.IdMundial, infoFase.[FASE], goles.Autor, SUM(goles.[GOLES POR AUTOR POR PARTIDO]) AS [GOLES POR AUTOR POR FASE]
				FROM
				(
					SELECT Partido.IdMundial, Fase.Descripcion AS [FASE], Partido.IdPartido
					FROM 
					partidos.Fase AS Fase INNER JOIN partidos.Partido AS Partido ON Partido.IdFase = Fase.IdFase
					WHERE Partido.IdMundial = 1

				) AS infoFase
				INNER JOIN
				(
					SELECT Evento.Partido, Gol.Autor, COUNT(IdGol) AS [GOLES POR AUTOR POR PARTIDO]
					FROM
					partidos.Evento AS Evento INNER JOIN partidos.Gol AS Gol ON Evento.IdEvento = Gol.IdGol
					GROUP BY Evento.Partido, Gol.Autor

				) AS goles
				ON infoFase.IdPartido = goles.Partido
				GROUP BY infoFase.IdMundial, infoFase.[FASE], goles.Autor
			)
			SELECT YEAR(Mundial.ACTIVIDAD_FECHA_INICIO) AS [MUNDIAL], infoT.FASE, infoT.[NOMBRE DEL JUGADOR], infoT.[GOLES POR AUTOR POR FASE], infoT.RANKING
			FROM
			(
				SELECT resumen.IdMundial, resumen.[FASE], infoJugador.[NOMBRE DEL JUGADOR], resumen.[GOLES POR AUTOR POR FASE], DENSE_RANK() OVER (PARTITION BY resumen.[FASE] ORDER BY resumen.[GOLES POR AUTOR POR FASE] DESC) AS [RANKING]
				FROM
				(
					SELECT CONVERT(NVARCHAR(30), DECRYPTBYKEY(Persona.Nombre)) AS [NOMBRE DEL JUGADOR], Jugador.IdJugador
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
					ON E.Partido = Partido.IdPartido

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
					SELECT CONVERT(NVARCHAR(30), DECRYPTBYKEY(Persona.Nombre)) AS [NOMBRE DEL JUGADOR], Jugador.IdJugador
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
	CLOSE SYMMETRIC KEY ClaveSimetrica_AES128_Mundial;
END;
GO

--Tarjetas (amarillas y rojas) por selección y jugador, con detalle de suspensiones activas por acumulación
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspReporte_Tarjetas'))
    DROP PROCEDURE SP.uspReporte_Tarjetas
GO
CREATE PROCEDURE SP.uspReporte_Tarjetas
@mundial INT
WITH EXECUTE AS OWNER
AS
BEGIN
	-- Abrir clave simetrica para descifrado de nombres (Entrega 8)
	OPEN SYMMETRIC KEY ClaveSimetrica_AES128_Mundial
	DECRYPTION BY CERTIFICATE CertificadoCifradoMundial
	WITH PASSWORD = 'ClaveMaestra_Mundial_2026!';

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
		WITH resumenAmonestaciones AS
		(
			SELECT A.[MUNDIAL], A.Amonestado, A.[TARJETA], A.[MOTIVO DE LA TARJETA],
			B.Tarjeta AS ultimaTarjeta
			FROM
			(
				SELECT 
				YEAR(Mundial.ACTIVIDAD_FECHA_INICIO) AS [MUNDIAL],
				Amonestacion.Amonestado,
				Amonestacion.Tarjeta AS [TARJETA], Amonestacion.Motivo AS [MOTIVO DE LA TARJETA],
				MAX(Amonestacion.IdAmonestacion) OVER (PARTITION BY Amonestacion.Amonestado) AS idLastAmon
				FROM sedes.Mundial AS Mundial
				INNER JOIN
				partidos.Partido AS Partido
				ON Mundial.IdMundial = Partido.IdMundial
				INNER JOIN
				partidos.Evento AS Evento
				ON Partido.IdPartido = Evento.Partido
				INNER JOIN
				partidos.Amonestacion AS Amonestacion
				ON Evento.IdEvento = Amonestacion.IdAmonestacion
				WHERE Mundial.IdMundial = @mundial

			) AS A
			INNER JOIN
			partidos.Amonestacion AS B
			ON A.IdLastAmon = B.IdAmonestacion
		)
		SELECT 
		resumenAmonestaciones.[MUNDIAL],
		Pais.NOMBRE AS [SELECCION],
		SUM(CASE WHEN resumenAmonestaciones.Tarjeta = 'Amarilla' THEN 1 ELSE 0 END) OVER (PARTITION BY Pais.NOMBRE) AS [TOTAL AMARILLAS DE LA SELECCION], 
		SUM(CASE WHEN resumenAmonestaciones.Tarjeta = 'Roja' THEN 1 ELSE 0 END) OVER (PARTITION BY Pais.NOMBRE) AS [TOTAL ROJAS DE LA SELECCION],
		CONVERT(NVARCHAR(30), DECRYPTBYKEY(Persona.Nombre)) AS [NOMBRE DEL AMONESTADO], Amonestados.ESTADO,
		CASE
		WHEN (Amonestados.ESTADO = 'Suspendido') AND (resumenAmonestaciones.ultimaTarjeta = 'Amarilla') THEN 'Por acumulacion de amarillas.'
		WHEN (Amonestados.ESTADO = 'Suspendido') AND (resumenAmonestaciones.ultimaTarjeta = 'Roja') THEN 'Recibio una tarjeta roja.'
		END AS [MOTIVO DE LA SUSPENSION],
		CASE
		WHEN (resumenAmonestaciones.TARJETA = 'Roja') AND (resumenAmonestaciones.[MOTIVO DE LA TARJETA] <> 'Por acumulacion de amarillas') 
		THEN (resumenAmonestaciones.TARJETA + '(DIRECTA)')
		ELSE resumenAmonestaciones.[TARJETA]
		END AS [TARJETA],
		resumenAmonestaciones.[MOTIVO DE LA TARJETA],
		SUM(CASE WHEN resumenAmonestaciones.Tarjeta = 'Amarilla' THEN 1 ELSE 0 END) OVER (PARTITION BY CONVERT(NVARCHAR(30), DECRYPTBYKEY(Persona.Nombre))) AS [TOTAL AMARILLAS DE LA PERSONA], 
		SUM(CASE WHEN resumenAmonestaciones.Tarjeta = 'Roja' THEN 1 ELSE 0 END) OVER (PARTITION BY CONVERT(NVARCHAR(30), DECRYPTBYKEY(Persona.Nombre))) AS [TOTAL ROJAS DE LA PERSONA]
		FROM
		equipos.Persona AS Persona
		INNER JOIN
		resumenAmonestaciones
		ON Persona.IdPersona = resumenAmonestaciones.Amonestado
		INNER JOIN
		(
			SELECT IdJugador AS ID, Seleccion, Estado AS [ESTADO] FROM equipos.Jugador
			UNION
			SELECT IdTecnico AS ID, Seleccion, Estado AS [ESTADO] FROM equipos.Tecnico
		) AS Amonestados
		ON resumenAmonestaciones.Amonestado = Amonestados.ID
		INNER JOIN
		equipos.Seleccion AS Seleccion
		ON Amonestados.Seleccion = Seleccion.IdSeleccion
		INNER JOIN
		equipos.Pais AS Pais
		ON Seleccion.IdPais = Pais.IdPais
		ORDER BY Pais.NOMBRE, CONVERT(NVARCHAR(30), DECRYPTBYKEY(Persona.Nombre))
	END

	CLOSE SYMMETRIC KEY ClaveSimetrica_AES128_Mundial;
END;
GO

--Designaciones Arbitrales
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspReporte_Arbitraje'))
    DROP PROCEDURE SP.uspReporte_Arbitraje
GO
CREATE PROCEDURE SP.uspReporte_Arbitraje
@mundial INT
WITH EXECUTE AS OWNER
AS
BEGIN
	-- Abrir clave simetrica para descifrado de nombres (Entrega 8)
	OPEN SYMMETRIC KEY ClaveSimetrica_AES128_Mundial
	DECRYPTION BY CERTIFICATE CertificadoCifradoMundial
	WITH PASSWORD = 'ClaveMaestra_Mundial_2026!';

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
			infoPart.IdMundial, infoPart.IdPartido, 
			(infoPart.[SELECCION 1] + ' - ' + infoPart.[SELECCION 2] + ' (' + Fase.Descripcion + ')') AS [PARTIDO]
			FROM
			(
				SELECT P.IdMundial, P.IdPartido, infoEq1.[SELECCION 1], infoEq2.[SELECCION 2], P.IdFase
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
			infoB.[PARTIDO],
			infoB.[AMONESTADO], infoB.[TARJETA RECIBIDA], infoB.[MOTIVO DE LA TARJETA]
			FROM
			(
				SELECT Arbitraje.Partido, CONVERT(NVARCHAR(30), DECRYPTBYKEY(Persona.Nombre)) AS [ARBITRO]
				FROM
				equipos.Persona AS Persona
				INNER JOIN
				arbitros.Arbitro AS Arbitro
				ON Persona.IdPersona = Arbitro.IdArbitro
				INNER JOIN
				arbitros.Arbitraje AS Arbitraje
				ON Arbitro.IdArbitro = Arbitraje.Arbitro

			) AS infoA
			INNER JOIN
			(
				SELECT 
				resumenPartidos.IdMundial,
				resumenPartidos.IdPartido,
				resumenPartidos.[PARTIDO],
				CONVERT(NVARCHAR(30), DECRYPTBYKEY(Persona.Nombre)) AS [AMONESTADO], Amonestacion.Tarjeta AS [TARJETA RECIBIDA], Amonestacion.Motivo AS [MOTIVO DE LA TARJETA]
				FROM
				resumenPartidos
				INNER JOIN
				partidos.Evento AS Evento
				ON resumenPartidos.IdPartido = Evento.Partido
				INNER JOIN
				partidos.Amonestacion AS Amonestacion
				ON Evento.IdEvento = Amonestacion.IdAmonestacion
				INNER JOIN
				equipos.Persona AS Persona
				ON Amonestacion.Amonestado = Persona.IdPersona

			) AS infoB
			ON infoA.Partido = infoB.IdPartido

		) AS infoT
		INNER JOIN
		sedes.Mundial AS Mundial
		ON infoT.IdMundial = Mundial.IdMundial
	END
	CLOSE SYMMETRIC KEY ClaveSimetrica_AES128_Mundial;
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
			infoPublicidad.[PUBLICIDAD], infoPublicidad.[CAMPAÑA], infoPublicidad.[ANUNCIANTE], 
			infoPublicidad.[COSTO CONTRATACION], infoPublicidad.[INGRESO TOTAL DE LA SEDE]
			FROM
			resumenPartidos
			INNER JOIN
			(
				SELECT 
				Historial.IdPartido, 
				Publicidad.Nombre AS [PUBLICIDAD], Campania.Nombre AS [CAMPAÑA], Anunciante.Nombre AS [ANUNCIANTE],
				Historial.CostoFinal AS [COSTO CONTRATACION], Historial.[INGRESO TOTAL DE LA SEDE]
				FROM
				(	
					SELECT IdHistorial, IdPublicidad, IdPartido, IdEP, IdCF, CostoFinal, SUM(CostoFinal) OVER (PARTITION BY IdPartido) AS [INGRESO TOTAL DE LA SEDE]
					FROM publicidad.HistorialPublicidad
				) AS Historial
				INNER JOIN
				publicidad.Publicidad AS Publicidad
				ON Historial.IdPublicidad = Publicidad.IdPublicidad
				INNER JOIN
				publicidad.Campania AS Campania
				ON Publicidad.IdCampania = Campania.IdCampania
				INNER JOIN
				publicidad.AnuncianteCampania AS AnuncianteCampania
				ON Campania.IdCampania = AnuncianteCampania.IdCampania
				INNER JOIN
				publicidad.Anunciante AS Anunciante
				ON Anunciante.IdAnunciante = AnuncianteCampania.IdAnunciante

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
WITH EXECUTE AS OWNER
AS
BEGIN
	-- Abrir clave simetrica para descifrado de nombres (Entrega 8)
	OPEN SYMMETRIC KEY ClaveSimetrica_AES128_Mundial
	DECRYPTION BY CERTIFICATE CertificadoCifradoMundial
	WITH PASSWORD = 'ClaveMaestra_Mundial_2026!';

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
		SELECT YEAR(Mundial.ACTIVIDAD_FECHA_INICIO) AS [@Mundial], infoSeleccion.NOMBRE AS [@Seleccion],
		(
			SELECT nombre.Nombre AS [@Nombre], nombre.Posicion AS [@Posicion], nombre.Numero AS [@Numero], Club.Nombre AS [@Club]
			FROM
			(
				SELECT Jugador.Seleccion, CONVERT(NVARCHAR(30), DECRYPTBYKEY(Persona.Nombre)) AS Nombre, Jugador.Posicion, Jugador.Numero, Jugador.Club
				FROM 
				equipos.Persona AS Persona 
				INNER JOIN 
				(SELECT IdJugador, Seleccion, Posicion, Numero, Club FROM equipos.Jugador WHERE Estado <> 'Inactivo') AS Jugador 
				ON Persona.IdPersona = Jugador.IdJugador

			) AS nombre
			LEFT JOIN
			equipos.Club AS Club
			ON nombre.Club = Club.IdClub
			WHERE nombre.Seleccion = infoSeleccion.IdSeleccion
			ORDER BY nombre.Seleccion, nombre.Numero
			FOR XML PATH ('Jugador'), TYPE
		) AS Jugadores
		FROM
		sedes.Mundial AS Mundial
		INNER JOIN
		(
			SELECT Seleccion.IdMundial, Seleccion.IdSeleccion, Pais.NOMBRE
			FROM equipos.Seleccion AS Seleccion INNER JOIN equipos.Pais AS Pais ON Seleccion.IdPais = Pais.IdPais

		) AS infoSeleccion
		ON Mundial.IdMundial = infoSeleccion.IdMundial
		WHERE Mundial.IdMundial = @mundial
		FOR XML PATH ('Seleccion'), ROOT('Convocados')
	END

	CLOSE SYMMETRIC KEY ClaveSimetrica_AES128_Mundial;
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
			STR(infoPart.GolesEq1, 2) + ' (' + STR(infoPart.PenalesEq1, 2) + ' )' + 
			'  - ' + 
			STR(infoPart.GolesEq2, 2) + ' (' + STR(infoPart.PenalesEq2, 2) + ' ) ' +
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
	DECLARE @errorCount INT, @i INT, @cant INT
	DECLARE @horaUTC TIME, @horaLocal TIME
	DECLARE @fechaP DATE
	DECLARE @huso VARCHAR(50), @pais VARCHAR(50), @select VARCHAR(MAX), @paises VARCHAR(MAX), @query VARCHAR(MAX)
	DECLARE @general TABLE
	(
		ID INT IDENTITY(1, 1) PRIMARY KEY,
		MUNDIAL DATE,
		PARTIDO VARCHAR(130),
		[HORARIO DEL PARTIDO] TIME,
		[FECHA DEL PARTIDO] DATE,
		PAIS VARCHAR(50),
		[INICIO PRIMETIME] TIME,
		[FIN PRIMETIME] TIME,
		[HUSO HORARIO] VARCHAR(50)
	)
	CREATE TABLE #final
	(
		ID INT IDENTITY(1, 1) PRIMARY KEY,
		MUNDIAL DATE,
		PARTIDO VARCHAR(130),
		PAIS VARCHAR(50),
		SEGMENTO CHAR(9)
	)
	DECLARE @lista TABLE (ID INT IDENTITY(1, 1), NOMBRE VARCHAR(50)) 

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
		INSERT INTO @general (MUNDIAL, PARTIDO, [HORARIO DEL PARTIDO], [FECHA DEL PARTIDO], PAIS, [INICIO PRIMETIME], [FIN PRIMETIME], [HUSO HORARIO])
		SELECT Partido.[MUNDIAL], Partido.[PARTIDO], Partido.[HORARIO DEL PARTIDO], Partido.[FECHA DEL PARTIDO], Pais.[PAIS],
		Pais.[INICIO PRIMETIME], Pais.[FIN PRIMETIME], Pais.[HUSO HORARIO]
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
		WHILE (@i <= @cant)
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

			--si el horario del partido (convertido) corresponde a la franja de primetime del pais, lo registro en #final
			IF EXISTS (SELECT 1 FROM @general WHERE ([INICIO PRIMETIME] <= @horaLocal) AND (@horaLocal <= [FIN PRIMETIME]) AND (ID = @i))
			BEGIN
				INSERT INTO #final(MUNDIAL, PARTIDO, PAIS)
				SELECT MUNDIAL, PARTIDO, PAIS
				FROM @general 
				WHERE ID = @i
			END

			SET @i = @i + 1
		END

		--ETAPA 3---------------------------------------------
		--agrego el valor 'PRIMETIME' al campo Segmento en todo #final
		UPDATE #final
		SET SEGMENTO = 'PRIMETIME'

		--muevo todos los nombres de paises a una tabla variable para recorrer sin posibles saltos en ID
		INSERT INTO @lista(NOMBRE)
		SELECT NOMBRE
		FROM equipos.Pais

		--inicializo strings para concatenar segun necesito
		SET @select = ', '
		SET @paises = '('

		--recorro @lista registro por registro para obtener todos los paises (columnas en la tabla pivot) y asi poder armar el string dinamico
		SET @i = 1
		SET @cant = (SELECT COUNT(ID) FROM @lista)
		
		WHILE (@i <= @cant)
		BEGIN
			SET @pais = (SELECT NOMBRE FROM @lista WHERE ID = @i)

			SET @select = @select + 'MAX(['+@pais+']) AS ' + '['+@pais+']' 
			SET @paises = @paises + '['+(SELECT NOMBRE FROM @lista WHERE ID = @i)+']'

			IF (@i <> @cant)
			BEGIN
				SET @select = @select+', ' 
				SET @paises = @paises+', '
			END
			ELSE
				SET @paises = @paises + ')'

			SET @i = @i + 1
		END

		--armo el string final
		SET @query = 
		'SELECT YEAR(MUNDIAL) AS MUNDIAL, PARTIDO' + @select + 
		' FROM #final PIVOT (MAX(SEGMENTO) FOR PAIS IN ' + @paises + ') AS reporte 
		GROUP BY MUNDIAL, PARTIDO'

		--ejecuto el query
		EXEC (@query)
	END
END;
GO