--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Objetivo: Crear Tabla Sustitucion

-- Ejecutar en la base seleccionada por el instalador.
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'partidos' AND TABLE_NAME = 'Sustitucion')
BEGIN
	CREATE TABLE partidos.Sustitucion
	(
		IdSustitucion INT NOT NULL,
		Ingreso INT NOT NULL,
		Egreso INT NOT NULL,
		Motivo INT NOT NULL,
		CONSTRAINT PK_Sustitucion PRIMARY KEY (IdSustitucion),
		CONSTRAINT FK_Sustitucion_Evento FOREIGN KEY (IdSustitucion) REFERENCES partidos.Evento(IdEvento),
		CONSTRAINT FK_Sustitucion_Ingreso FOREIGN KEY (Ingreso) REFERENCES equipos.Jugador(IdJugador),
		CONSTRAINT FK_Sustitucion_Egreso FOREIGN KEY (Egreso) REFERENCES equipos.Jugador(IdJugador),
		CONSTRAINT FK_Sustitucion_Motivo FOREIGN KEY (Motivo) REFERENCES publicidad.Motivo(IdMotivo),
		CONSTRAINT CK_Sustitucion_Ingreso_Egreso CHECK (Ingreso <> Egreso)
	)
END
GO