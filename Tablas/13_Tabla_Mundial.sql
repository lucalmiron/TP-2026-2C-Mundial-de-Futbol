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

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'sedes' AND TABLE_NAME = 'Mundial')
BEGIN
	CREATE TABLE sedes.Mundial(
		IdMundial INT IDENTITY(1,1),
		IdPais INT NOT NULL,
		ACTIVIDAD_FECHA_INICIO DATE NOT NULL,
		ACTIVIDAD_FECHA_FIN DATE NOT NULL,
		TAMANIO_SELECCION_MINIMO INT NOT NULL,
		TAMANIO_SELECCION_MAXIMO INT NOT NULL,
		CAMBIOS_VENTANAS INT NOT NULL,
		CAMBIOS_CANTIDAD INT NOT NULL,
		SUSPENSION_TARJETAS_MAXIMAS INT NOT NULL,
		SUSPENSION_TIEMPO INT NOT NULL,
		CONSTRAINT PK_Mundial PRIMARY KEY (IdMundial),
		CONSTRAINT FK_Mundial_Pais FOREIGN KEY (IdPais) REFERENCES equipos.Pais(IdPais)
	);
END;
GO
