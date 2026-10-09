--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 08/10/2026

--Objetivo: Crear Tabla CambioConvocatoria

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'TABLAS' AND TABLE_NAME = 'CambioConvocatoria')
BEGIN
	CREATE TABLE TABLAS.CambioConvocatoria
	(
		IdCambio INT PRIMARY KEY IDENTITY(1, 1),
		Seleccion INT NOT NULL,
		Egreso INT NOT NULL,
		Ingreso INT NOT NULL,
		Fecha DATE NOT NULL,
		Motivo VARCHAR(200) NOT NULL,
		CONSTRAINT FK_CambioConvocatoria_Seleccion FOREIGN KEY (Seleccion) REFERENCES TABLAS.Seleccion(IdSeleccion),
		CONSTRAINT FK_CambioConvocatoria_Egreso FOREIGN KEY (Egreso) REFERENCES TABLAS.Jugador(IdJugador),
		CONSTRAINT FK_CambioConvocatoria_Ingreso FOREIGN KEY (Ingreso) REFERENCES TABLAS.Jugador(IdJugador),
		CONSTRAINT CK_CambioConvocatoria_Ingreso_Egreso CHECK (Ingreso <> Egreso)
	)
END
GO