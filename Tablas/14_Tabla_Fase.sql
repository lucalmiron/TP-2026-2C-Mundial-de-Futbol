-- Universidad Nacional de La Matanza
-- Bases de datos aplicada 
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 08/10/2026
-- Objetivo: Tablas Partido

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='TABLAS' AND TABLE_NAME='Fase')
BEGIN 
	CREATE TABLE TABLAS.Fase(
	IdFase INT IDENTITY(1, 1) PRIMARY KEY,
	Descripcion VARCHAR (20) NOT NULL CHECK (Descripcion IN ('Grupos', 'Dieciseisavos', 'Octavos', 'Cuartos', 'Semifinal', 'Tercer Puesto', 'Final')))
END
GO