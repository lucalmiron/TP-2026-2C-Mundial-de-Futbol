--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 08/10/2026

--Creacion de Tabla Sustitucion

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'TABLAS' AND TABLE_NAME = 'Sustitucion')
BEGIN
	CREATE TABLE TABLAS.Sustitucion
	(
		IdSustitucion INT NOT NULL,
		Ingreso INT NOT NULL,
		Egreso INT NOT NULL,
		Motivo INT NOT NULL,
		CONSTRAINT PK_Sustitucion PRIMARY KEY (IdSustitucion),
		CONSTRAINT FK_Sustitucion_Evento FOREIGN KEY (IdSustitucion) REFERENCES TABLAS.Evento(IdEvento),
		CONSTRAINT FK_Sustitucion_Ingreso FOREIGN KEY (Ingreso) REFERENCES TABLAS.Jugador(IdJugador),
		CONSTRAINT FK_Sustitucion_Egreso FOREIGN KEY (Egreso) REFERENCES TABLAS.Jugador(IdJugador),
		CONSTRAINT FK_Sustitucion_Motivo FOREIGN KEY (Motivo) REFERENCES TABLAS.Motivo(IdMotivo),
		CONSTRAINT CK_Sustitucion_Ingreso_Egreso CHECK (Ingreso <> Egreso)
	)
END;
GO