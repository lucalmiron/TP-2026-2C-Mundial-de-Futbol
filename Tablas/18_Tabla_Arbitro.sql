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

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'arbitros' AND TABLE_NAME = 'Arbitro')
BEGIN
	CREATE TABLE arbitros.Arbitro
	(
		IdArbitro INT,
		Categoria VARCHAR(20) NOT NULL,
		CONSTRAINT PK_Arbitro PRIMARY KEY (IdArbitro),
		CONSTRAINT FK_Arbitro_Persona FOREIGN KEY (IdArbitro) REFERENCES equipos.Persona(IdPersona)
	);
END;
GO
