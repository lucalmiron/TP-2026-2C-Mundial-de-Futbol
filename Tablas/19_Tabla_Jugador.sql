--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Creacion de Tablas

-- Ejecutar en la base seleccionada por el instalador.
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'equipos' AND TABLE_NAME = 'Jugador')
BEGIN
	CREATE TABLE equipos.Jugador
	(
		IdJugador INT,
		Estado VARCHAR(10) NOT NULL,
		Posicion NVARCHAR(20) NOT NULL,
		Numero INT NOT NULL,
		Club INT NULL,
		Seleccion INT NOT NULL,
		TarjetasAcum INT NOT NULL CONSTRAINT DF_Jugador_TarjetasAcum DEFAULT 0,
		CONSTRAINT PK_Jugador PRIMARY KEY (IdJugador),
		CONSTRAINT FK_Jugador_Persona FOREIGN KEY (IdJugador) REFERENCES equipos.Persona(IdPersona),
		CONSTRAINT FK_Jugador_Club FOREIGN KEY (Club) REFERENCES equipos.Club(IdClub),
		CONSTRAINT FK_Jugador_Seleccion FOREIGN KEY (Seleccion) REFERENCES equipos.Seleccion(IdSeleccion),
		CONSTRAINT UQ_Jugador_Dorsal UNIQUE (Seleccion, Numero)
	);
END;
GO

-- Bases creadas con la version anterior tenian VARCHAR(20): se migra a NVARCHAR(20).
-- El ALTER es idempotente: si ya es NVARCHAR(20) no hace nada.
IF EXISTS (
	SELECT 1
	FROM sys.columns c
	JOIN sys.types t ON t.user_type_id = c.user_type_id
	WHERE c.object_id = OBJECT_ID(N'equipos.Jugador')
	  AND c.name = N'Posicion'
	  AND (t.name <> N'nvarchar' OR c.max_length <> 40)
)
	ALTER TABLE equipos.Jugador ALTER COLUMN Posicion NVARCHAR(20) NOT NULL;
GO
