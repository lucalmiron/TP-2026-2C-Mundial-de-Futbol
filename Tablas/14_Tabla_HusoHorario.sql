--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Creacion de Tabla HusoHorario

-- Ejecutar en la base seleccionada por el instalador.
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'sedes' AND TABLE_NAME = 'HusoHorario')
BEGIN
	CREATE TABLE sedes.HusoHorario
	(
		IdHuso INT IDENTITY(1,1),
		Nombre VARCHAR(50) NOT NULL,
		IdPais INT NOT NULL,
		CONSTRAINT PK_HusoHorario PRIMARY KEY (IdHuso),
		CONSTRAINT FK_HusoHorario_Pais FOREIGN KEY (IdPais) REFERENCES equipos.Pais(IdPais)
	);
END;
GO