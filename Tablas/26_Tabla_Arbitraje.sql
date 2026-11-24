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

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'arbitros' AND TABLE_NAME = 'Arbitraje')
BEGIN
	CREATE TABLE arbitros.Arbitraje
	(
		Arbitro INT NOT NULL,
		Funcion VARCHAR(20) NOT NULL,
		Partido INT NOT NULL,
		CONSTRAINT PK_Arbitraje PRIMARY KEY (Arbitro, Partido),
		CONSTRAINT FK_Arbitraje_Arbitro FOREIGN KEY (Arbitro) REFERENCES arbitros.Arbitro(IdArbitro),
		CONSTRAINT FK_Arbitraje_Partido FOREIGN KEY (Partido) REFERENCES partidos.Partido(IdPartido)
	);
END;
GO
