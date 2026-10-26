-- Universidad Nacional de La Matanza
-- Bases de datos aplicada 
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 26/10/26
-- Objetivo: Tablas Partido

-- Ejecutar en la base seleccionada por el instalador.
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'partidos' AND TABLE_NAME = 'Fase')
BEGIN
	CREATE TABLE partidos.Fase
	(
		IdFase INT IDENTITY(1, 1),
		Descripcion VARCHAR(20) NOT NULL,
		CONSTRAINT PK_Fase PRIMARY KEY (IdFase),
		CONSTRAINT UQ_Fase_Descripcion UNIQUE (Descripcion),
		CONSTRAINT CK_Fase_Descripcion CHECK (Descripcion IN ('Grupos', 'Dieciseisavos', 'Octavos', 'Cuartos', 'Semifinal', 'Tercer Puesto', 'Final'))
	);
END;
GO
