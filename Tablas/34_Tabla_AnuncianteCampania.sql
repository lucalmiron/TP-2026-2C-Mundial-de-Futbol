--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Creacion de Tabla AnuncianteCampania

-- Ejecutar en la base seleccionada por el instalador.
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'publicidad' AND TABLE_NAME = 'AnuncianteCampania')
BEGIN
	CREATE TABLE publicidad.AnuncianteCampania
	(
		IdAnunciante INT NOT NULL,
		IdCampania INT NOT NULL,
		PRIMARY KEY(IdAnunciante, IdCampania),
		FOREIGN KEY(IdAnunciante) REFERENCES publicidad.Anunciante(IdAnunciante),
		FOREIGN KEY(IdCampania) REFERENCES publicidad.Campania(IdCampania)
	)
END;
GO
