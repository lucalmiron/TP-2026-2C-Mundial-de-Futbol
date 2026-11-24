--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Creacion de Tabla Amonestacion

-- Ejecutar en la base seleccionada por el instalador.
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'partidos' AND TABLE_NAME = 'Amonestacion')
BEGIN
	CREATE TABLE partidos.Amonestacion
	(
		IdAmonestacion INT,
		Amonestado INT NOT NULL,
		Arbitro INT NOT NULL,
		Tarjeta VARCHAR(8) NOT NULL,
		Motivo VARCHAR(300) NOT NULL,
		CONSTRAINT PK_Amonestacion PRIMARY KEY (IdAmonestacion),
		CONSTRAINT FK_Amonestacion_Evento FOREIGN KEY (IdAmonestacion) REFERENCES partidos.Evento(IdEvento),
		CONSTRAINT FK_Amonestacion_Persona FOREIGN KEY (Amonestado) REFERENCES equipos.Persona(IdPersona),
		CONSTRAINT FK_Amonestacion_Arbitro FOREIGN KEY (Arbitro) REFERENCES arbitros.Arbitro(IdArbitro)
	);
END;
GO
