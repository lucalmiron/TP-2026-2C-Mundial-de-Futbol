:ON ERROR EXIT
USE master;
GO
IF '$(BasePrueba)' NOT LIKE 'MUNDIAL[_]%[_]Test[_]E5'
 THROW 51000,'Nombre de base de pruebas no permitido.',1;
IF DB_ID('$(BasePrueba)') IS NOT NULL
 THROW 51000,'La base de pruebas ya existe. Revisarla antes de repetir la ejecucion.',1;
GO
CREATE DATABASE [$(BasePrueba)] COLLATE Latin1_General_100_CI_AS_SC;
GO
USE [$(BasePrueba)];
GO
CREATE SCHEMA equipos;
GO
CREATE SCHEMA sedes;
GO
CREATE SCHEMA partidos;
GO
CREATE SCHEMA arbitros;
GO
CREATE SCHEMA publicidad;
GO
CREATE SCHEMA SP;
GO
CREATE SCHEMA SPTRANS;
GO
-- 06_Tabla_Idioma.sql
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

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'arbitros' AND TABLE_NAME = 'Idioma')
BEGIN
	CREATE TABLE arbitros.Idioma
	(
		IdIdioma INT IDENTITY(1, 1),
		Descripcion VARCHAR(20) NOT NULL,
		CONSTRAINT PK_Idioma PRIMARY KEY (IdIdioma),
		CONSTRAINT UQ_Idioma_Descripcion UNIQUE (Descripcion)
	);
END;
GO

GO
-- 14_Tabla_HusoHorario.sql
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
		CONSTRAINT PK_HusoHorario PRIMARY KEY (IdHuso)
	);
END;
GO

GO
-- 03_Tabla_Pais.sql
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

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'equipos' AND TABLE_NAME = 'Pais')
BEGIN
	CREATE TABLE equipos.Pais(
		IdPais INT IDENTITY(1,1),
		NOMBRE VARCHAR(50) NOT NULL,
		Idioma INT,
		HusoHorario INT,
		PtIni TIME,
		PtFin TIME,
		PBI BIGINT,
		CONSTRAINT PK_Pais PRIMARY KEY (IdPais),
		CONSTRAINT UQ_Pais_NOMBRE UNIQUE (NOMBRE),
		CONSTRAINT FK_Pais_Idioma FOREIGN KEY (Idioma) REFERENCES arbitros.Idioma(IdIdioma),
		CONSTRAINT FK_Pais_HusoHorario FOREIGN KEY (HusoHorario) REFERENCES sedes.HusoHorario(IdHuso)
	);
END;
GO

GO
-- 04_Tabla_Grupo.sql
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

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'equipos' AND TABLE_NAME = 'Grupo')
BEGIN
	CREATE TABLE equipos.Grupo
	(
		IdGrupo INT IDENTITY(1,1),
		NOMBRE VARCHAR(10) NOT NULL,
		CONSTRAINT PK_Grupo PRIMARY KEY (IdGrupo),
		CONSTRAINT UQ_Grupo_NOMBRE UNIQUE (NOMBRE)
	);
END;
GO

GO
-- 05_Tabla_Club.sql
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

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'equipos' AND TABLE_NAME = 'Club')
BEGIN
	CREATE TABLE equipos.Club
	(
		IdClub INT IDENTITY(1, 1),
		Nombre VARCHAR(20) NOT NULL,
		CONSTRAINT PK_Club PRIMARY KEY (IdClub),
		CONSTRAINT UQ_Club_Nombre UNIQUE (Nombre)
	);
END;
GO

GO
-- 07_Tabla_Fase.sql
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

GO
-- 08_Tabla_Periodo.sql
--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Creacion de Tabla Periodo

-- Ejecutar en la base seleccionada por el instalador.
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'partidos' AND TABLE_NAME = 'Periodo')
BEGIN
	CREATE TABLE partidos.Periodo
	(
		IdPeriodo INT,
		Descripcion VARCHAR(12) NOT NULL,
		Inicio INT NULL,
		Fin INT NULL,
		EsPenales BIT NOT NULL CONSTRAINT DF_Periodo_EsPenales DEFAULT 0,
        CONSTRAINT CK_Periodo_Limites CHECK (
            (EsPenales = 1 AND Inicio IS NULL AND Fin IS NULL) OR
            (EsPenales = 0 AND Inicio IS NOT NULL AND Fin IS NOT NULL AND Inicio >= 0 AND Fin >= Inicio)),
        CONSTRAINT PK_Periodo PRIMARY KEY (IdPeriodo),
		CONSTRAINT UQ_Periodo_Descripcion UNIQUE (Descripcion)
	);
END;
GO

GO
-- 09_Tabla_EspacioPublicitario.sql
-- Universidad Nacional de La Matanza
-- Bases de datos aplicada 
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 26/10/26
-- Objetivo: Creacion  tabla espacio publicitario.

-- Ejecutar en la base seleccionada por el instalador.
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'publicidad' AND TABLE_NAME = 'EspacioPublicitario')
BEGIN
	CREATE TABLE publicidad.EspacioPublicitario
	(
		IdEP INT IDENTITY(1,1),
		IdSede INT NOT NULL,
        Numero TINYINT NOT NULL,
        Tipo VARCHAR(30) NOT NULL,
		Costo DECIMAL(10,2) NOT NULL,
		CONSTRAINT CK_EspacioPublicitario_Numero CHECK (Numero BETWEEN 1 AND 4),
        CONSTRAINT UQ_EspacioPublicitario_SedeNumero UNIQUE (IdSede, Numero),
        CONSTRAINT PK_EspacioPublicitario PRIMARY KEY (IdEP),
		CONSTRAINT CK_EspacioPublicitario_Costo CHECK (Costo >= 0)
	);
END;
GO

GO
-- 10_Tabla_CostoFranja.sql
-- Universidad Nacional de La Matanza
-- Bases de datos aplicada 
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 26/10/26
-- Objetivo: Creacion  tabla costoFranja.

-- Ejecutar en la base seleccionada por el instalador.
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'publicidad' AND TABLE_NAME = 'CostoFranja')
BEGIN
	CREATE TABLE publicidad.CostoFranja
	(
		IdCF INT IDENTITY(1,1),
		IdSede INT NOT NULL,
        TipoFranja VARCHAR(30) NOT NULL,
		Costo DECIMAL(10,2) NOT NULL,
		CONSTRAINT UQ_CostoFranja_SedeTipo UNIQUE (IdSede, TipoFranja),
        CONSTRAINT PK_CostoFranja PRIMARY KEY (IdCF),
		CONSTRAINT CK_CostoFranja_Costo CHECK (Costo >= 0)
	);
END;
GO

GO
-- 11_Tabla_Motivo.sql
--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Creacion de Tabla Motivo

-- Ejecutar en la base seleccionada por el instalador.
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'publicidad' AND TABLE_NAME = 'Motivo')
BEGIN
	CREATE TABLE publicidad.Motivo
	(
		IdMotivo INT PRIMARY KEY IDENTITY(1, 1),
		Descripcion VARCHAR(100) NOT NULL
	)
END;
GO

GO
-- 12_Tabla_Campania.sql
--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Creacion de Tabla Campania

-- Ejecutar en la base seleccionada por el instalador.
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'publicidad' AND TABLE_NAME = 'Campania')
BEGIN
	CREATE TABLE publicidad.Campania
	(
		IdCampania INT PRIMARY KEY IDENTITY(1, 1),
		Nombre VARCHAR(50) NOT NULL,
		Descripcion VARCHAR(200) NOT NULL
	)
END;
GO

GO
-- 13_Tabla_Mundial.sql
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

GO
-- 15_Tabla_Sede.sql
-- Universidad Nacional de La Matanza
-- Bases de datos aplicada 
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 26/10/26
-- Objetivo: Creacion sede.

-- Ejecutar en la base seleccionada por el instalador.
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'sedes' AND TABLE_NAME = 'Sede')
BEGIN
	CREATE TABLE sedes.Sede
	(
		IdSede INT IDENTITY(1,1),
		Nombre VARCHAR(30) NOT NULL,
		Ciudad VARCHAR(30) NOT NULL,
		Capacidad INT NOT NULL,
		IdPais INT NOT NULL,
		IdHuso INT NOT NULL,
		CONSTRAINT PK_Sede PRIMARY KEY (IdSede),
		CONSTRAINT CK_Sede_Capacidad CHECK (Capacidad > 0),
		CONSTRAINT UQ_Sede_Nombre_Ciudad UNIQUE (Nombre, Ciudad),
		CONSTRAINT FK_Sede_Pais FOREIGN KEY (IdPais) REFERENCES equipos.Pais(IdPais),
		CONSTRAINT FK_Sede_HusoHorario FOREIGN KEY (IdHuso) REFERENCES sedes.HusoHorario(IdHuso)
	);
END;
GO

GO
-- 16_Tabla_Persona.sql
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

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'equipos' AND TABLE_NAME = 'Persona')
BEGIN
	CREATE TABLE equipos.Persona
	(
		IdPersona INT IDENTITY(1, 1),
		Nombre VARCHAR(30) NOT NULL,
		Fnac DATE NOT NULL,
		Rol VARCHAR(10) NOT NULL,
		Pais INT NOT NULL,
		CONSTRAINT PK_Persona PRIMARY KEY (IdPersona),
		CONSTRAINT FK_Persona_Pais FOREIGN KEY (Pais) REFERENCES equipos.Pais(IdPais)
	);
END;
GO

GO
-- 17_Tabla_Seleccion.sql
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

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'equipos' AND TABLE_NAME = 'Seleccion')
BEGIN
	CREATE TABLE equipos.Seleccion
	(
		IdSeleccion INT IDENTITY(1,1),
		IdPais INT NOT NULL,
		IdMundial INT NOT NULL,
		IdGrupo INT NOT NULL,
		CONFEDERACION VARCHAR(45) NOT NULL,
		CONSTRAINT PK_Seleccion PRIMARY KEY (IdSeleccion),
		CONSTRAINT FK_Seleccion_Pais FOREIGN KEY (IdPais) REFERENCES equipos.Pais(IdPais),
		CONSTRAINT FK_Seleccion_Mundial FOREIGN KEY (IdMundial) REFERENCES sedes.Mundial(IdMundial),
		CONSTRAINT FK_Seleccion_Grupo FOREIGN KEY (IdGrupo) REFERENCES equipos.Grupo(IdGrupo),
		CONSTRAINT UQ_Seleccion_IdPais_IdMundial UNIQUE (IdPais, IdMundial)
	);
END;
GO

GO
-- 18_Tabla_Arbitro.sql
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

GO
-- 19_Tabla_Jugador.sql
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
		Posicion VARCHAR(20) NOT NULL,
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

GO
-- 20_Tabla_Tecnico.sql
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

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'equipos' AND TABLE_NAME = 'Tecnico')
BEGIN
	CREATE TABLE equipos.Tecnico
	(
		IdTecnico INT,
		Funcion VARCHAR(40) NOT NULL,
		Seleccion INT NOT NULL,
		TarjetasAcum INT NOT NULL CONSTRAINT DF_Tecnico_TarjetasAcum DEFAULT 0,
		Estado VARCHAR(10) NOT NULL,
		CONSTRAINT PK_Tecnico PRIMARY KEY (IdTecnico),
		CONSTRAINT FK_Tecnico_Persona FOREIGN KEY (IdTecnico) REFERENCES equipos.Persona(IdPersona),
		CONSTRAINT FK_Tecnico_Seleccion FOREIGN KEY (Seleccion) REFERENCES equipos.Seleccion(IdSeleccion)
	);
END;
GO

GO
-- 21_Tabla_Anunciante.sql
--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Creacion de Tabla Anunciante

-- Ejecutar en la base seleccionada por el instalador.
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'publicidad' AND TABLE_NAME = 'Anunciante')
BEGIN
	CREATE TABLE publicidad.Anunciante
	(
		IdAnunciante INT PRIMARY KEY IDENTITY(1, 1),
		Nombre VARCHAR(50) NOT NULL,
		IdPais INT NOT NULL,
		FOREIGN KEY(IdPais) REFERENCES equipos.Pais(IdPais)
	)
END;
GO

GO
-- 22_Tabla_Publicidad.sql
--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Creacion de Tabla Publicidad

-- Ejecutar en la base seleccionada por el instalador.
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'publicidad' AND TABLE_NAME = 'Publicidad')
BEGIN
	CREATE TABLE publicidad.Publicidad
	(
		IdPublicidad INT PRIMARY KEY IDENTITY(1, 1),
		Nombre VARCHAR(50) NOT NULL,
		IdCampania INT NOT NULL,
		IdIdioma INT NOT NULL,
		FOREIGN KEY(IdCampania) REFERENCES publicidad.Campania(IdCampania),
		FOREIGN KEY(IdIdioma) REFERENCES arbitros.Idioma(IdIdioma)
	)
END;
GO

GO
-- 23_Tabla_HablaIdioma.sql
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

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'arbitros' AND TABLE_NAME = 'HablaIdioma')
BEGIN
	CREATE TABLE arbitros.HablaIdioma
	(
		Arbitro INT NOT NULL,
		Idioma INT NOT NULL,
		CONSTRAINT PK_HablaIdioma PRIMARY KEY (Arbitro, Idioma),
		CONSTRAINT FK_HablaIdioma_Arbitro FOREIGN KEY (Arbitro) REFERENCES arbitros.Arbitro(IdArbitro),
		CONSTRAINT FK_HablaIdioma_Idioma FOREIGN KEY (Idioma) REFERENCES arbitros.Idioma(IdIdioma)
	);
END;
GO

GO
-- 24_Tabla_Partido.sql
-- Universidad Nacional de La Matanza
-- Bases de datos aplicada
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 26/10/26
-- Objetivo: Crear Tabla Partido

-- Ejecutar en la base seleccionada por el instalador.
GO

-- Si la tabla ya existe se libera el CHECK que referencia a la funcion: mientras
-- ese CHECK este puesto, SQL Server no permite alterar la funcion. Al final del
-- script el CHECK se vuelve a agregar (ver CK_Partido_MismoMundial mas abajo).
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Partido_MismoMundial')
	ALTER TABLE partidos.Partido DROP CONSTRAINT CK_Partido_MismoMundial
GO

-- Funcion de apoyo al CHECK de mismo Mundial via equipos.Seleccion
-- Se usa CREATE OR ALTER (y no DROP + CREATE) porque el CHECK la referencia:
-- dropearla dejaria de ser re-ejecutable una vez creado el CHECK
CREATE OR ALTER FUNCTION partidos.fnPartido_MismoMundial(@Eq1 INT, @Eq2 INT, @IdMundial INT)
RETURNS BIT
AS
BEGIN
	DECLARE @vOk BIT = 0
	IF EXISTS (SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @Eq1 AND IdMundial = @IdMundial)
	AND EXISTS (SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @Eq2 AND IdMundial = @IdMundial)
		SET @vOk = 1
	RETURN @vOk
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'partidos' AND TABLE_NAME = 'Partido')
BEGIN
	CREATE TABLE partidos.Partido
	(
		IdPartido INT IDENTITY(1, 1),
		IdFase INT NOT NULL,
		IdSede INT NOT NULL,
		IdMundial INT NOT NULL,
		Eq1 INT NOT NULL,
		Eq2 INT NOT NULL,
		Fecha DATE NOT NULL,
		HoraUTC TIME NOT NULL,
		HoraLocal TIME NOT NULL,
		GolesEq1 INT NOT NULL CONSTRAINT DF_Partido_GolesEq1 DEFAULT 0 CONSTRAINT CK_Partido_GolesEq1 CHECK (GolesEq1 >= 0),
		GolesEq2 INT NOT NULL CONSTRAINT DF_Partido_GolesEq2 DEFAULT 0 CONSTRAINT CK_Partido_GolesEq2 CHECK (GolesEq2 >= 0),
		PenalesEq1 INT NULL,
        PenalesEq2 INT NULL,
        CONSTRAINT CK_Partido_Penales CHECK (
          (PenalesEq1 IS NULL AND PenalesEq2 IS NULL) OR
          (PenalesEq1 IS NOT NULL AND PenalesEq2 IS NOT NULL AND PenalesEq1 >= 0 AND PenalesEq2 >= 0)),
        Asistencia INT CONSTRAINT CK_Partido_Asistencia CHECK (Asistencia >= 0),
		CONSTRAINT PK_Partido PRIMARY KEY (IdPartido),
		CONSTRAINT FK_Partido_Fase FOREIGN KEY (IdFase) REFERENCES partidos.Fase(IdFase),
		CONSTRAINT FK_Partido_Sede FOREIGN KEY (IdSede) REFERENCES sedes.Sede(IdSede),
		CONSTRAINT FK_Partido_Mundial FOREIGN KEY (IdMundial) REFERENCES sedes.Mundial(IdMundial),
		CONSTRAINT FK_Partido_Seleccion_Eq1 FOREIGN KEY (Eq1) REFERENCES equipos.Seleccion(IdSeleccion),
		CONSTRAINT FK_Partido_Seleccion_Eq2 FOREIGN KEY (Eq2) REFERENCES equipos.Seleccion(IdSeleccion),
		CONSTRAINT CK_Partido_Equipos CHECK (Eq1 <> Eq2),
		CONSTRAINT CK_Partido_MismoMundial CHECK (partidos.fnPartido_MismoMundial(Eq1, Eq2, IdMundial) = 1)
	)
END
GO

-- Migracion re-ejecutable para tablas existentes creadas sin IdMundial
IF COL_LENGTH('partidos.Partido', 'IdMundial') IS NULL
	ALTER TABLE partidos.Partido ADD IdMundial INT NULL
GO

-- Backfill con el IdMundial de Eq1 via equipos.Seleccion
IF COL_LENGTH('partidos.Partido', 'IdMundial') IS NOT NULL
AND EXISTS (SELECT 1 FROM partidos.Partido WHERE IdMundial IS NULL)
	UPDATE P SET P.IdMundial = S.IdMundial FROM partidos.Partido P INNER JOIN equipos.Seleccion S ON S.IdSeleccion = P.Eq1 WHERE P.IdMundial IS NULL
GO

-- Endurece a NOT NULL solo cuando ya no quedan nulos (re-ejecutable)
IF COL_LENGTH('partidos.Partido', 'IdMundial') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM partidos.Partido WHERE IdMundial IS NULL)
	ALTER TABLE partidos.Partido ALTER COLUMN IdMundial INT NOT NULL
GO

-- FK a sedes.Mundial solo cuando los datos ya estan saneados (re-ejecutable)
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Partido_Mundial')
AND COL_LENGTH('partidos.Partido', 'IdMundial') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM partidos.Partido WHERE IdMundial IS NULL)
	ALTER TABLE partidos.Partido ADD CONSTRAINT FK_Partido_Mundial FOREIGN KEY (IdMundial) REFERENCES sedes.Mundial(IdMundial)
GO

-- CHECK de mismo Mundial via equipos.Seleccion, solo con datos saneados (re-ejecutable)
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Partido_MismoMundial')
AND COL_LENGTH('partidos.Partido', 'IdMundial') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM partidos.Partido WHERE IdMundial IS NULL)
	ALTER TABLE partidos.Partido ADD CONSTRAINT CK_Partido_MismoMundial CHECK (partidos.fnPartido_MismoMundial(Eq1, Eq2, IdMundial) = 1)
GO

GO
-- 25_Tabla_Alineacion.sql
-- Universidad Nacional de La Matanza
-- Bases de datos aplicada 
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 26/10/26
---- Objetivo: Crear Tabla alineacion

-- Ejecutar en la base seleccionada por el instalador.
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'partidos' AND TABLE_NAME = 'Alineacion')
BEGIN
	CREATE TABLE partidos.Alineacion
	(
		IdPartido INT NOT NULL,
		IdJugador INT NOT NULL,
		Rol VARCHAR(10) NOT NULL CONSTRAINT CK_Alineacion_Rol CHECK (Rol IN ('Titular', 'Suplente')),
		PosicionCancha VARCHAR(20) NULL,
		Esquema VARCHAR(10) NULL,
		CONSTRAINT PK_Alineacion PRIMARY KEY (IdPartido, IdJugador),
		CONSTRAINT FK_Alineacion_Partido FOREIGN KEY (IdPartido) REFERENCES partidos.Partido(IdPartido),
		CONSTRAINT FK_Alineacion_Jugador FOREIGN KEY (IdJugador) REFERENCES equipos.Jugador(IdJugador)
	);
END;
GO

GO
-- 26_Tabla_Arbitraje.sql
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

GO
-- 27_Tabla_Reporte.sql
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

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'arbitros' AND TABLE_NAME = 'Reporte')
BEGIN
	CREATE TABLE arbitros.Reporte
	(
		IdReporte INT IDENTITY(1, 1),
		Razon VARCHAR(20) NOT NULL,
		Descripcion VARCHAR(300) NULL,
		Arbitro INT NOT NULL,
		Partido INT NOT NULL,
		CONSTRAINT PK_Reporte PRIMARY KEY (IdReporte),
		CONSTRAINT FK_Reporte_Arbitro FOREIGN KEY (Arbitro) REFERENCES arbitros.Arbitro(IdArbitro),
		CONSTRAINT FK_Reporte_Partido FOREIGN KEY (Partido) REFERENCES partidos.Partido(IdPartido)
	);
END;
GO

GO
-- 28_Tabla_Evento.sql
--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Creacion de Tabla Evento

-- Ejecutar en la base seleccionada por el instalador.
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'partidos' AND TABLE_NAME = 'Evento')
BEGIN
	CREATE TABLE partidos.Evento
	(
		IdEvento INT IDENTITY(1, 1),
		Minuto INT NULL,
		Tipo VARCHAR(12) NOT NULL,
		Partido INT NOT NULL,
		Periodo INT NOT NULL,
		CONSTRAINT PK_Evento PRIMARY KEY (IdEvento),
		CONSTRAINT FK_Evento_Partido FOREIGN KEY (Partido) REFERENCES partidos.Partido(IdPartido),
		CONSTRAINT FK_Evento_Periodo FOREIGN KEY (Periodo) REFERENCES partidos.Periodo(IdPeriodo)
	);
END;
GO

GO
-- 29_Tabla_Amonestacion.sql
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

GO
-- 30_Tabla_Gol.sql
--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Objetivo: Crear Tabla Gol

-- Ejecutar en la base seleccionada por el instalador.
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'partidos' AND TABLE_NAME = 'Gol')
BEGIN
	CREATE TABLE partidos.Gol
	(
		IdGol INT NOT NULL,
		Autor INT NOT NULL,
		Asistencia INT NULL,
		Tipo VARCHAR(20) NOT NULL,
		CONSTRAINT PK_Gol PRIMARY KEY (IdGol),
		CONSTRAINT FK_Gol_Evento FOREIGN KEY (IdGol) REFERENCES partidos.Evento(IdEvento),
		CONSTRAINT FK_Gol_Autor FOREIGN KEY (Autor) REFERENCES equipos.Jugador(IdJugador),
		CONSTRAINT FK_Gol_Asistencia FOREIGN KEY (Asistencia) REFERENCES equipos.Jugador(IdJugador),
		CONSTRAINT CK_Gol_Tipo CHECK (Tipo IN ('Jugada','Penal','Tiro libre','Corner','En contra')),
		CONSTRAINT CK_Gol_Autor_Asistencia CHECK (Autor <> Asistencia)
	)
END
GO

GO
-- 31_Tabla_Sustitucion.sql
--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Objetivo: Crear Tabla Sustitucion

-- Ejecutar en la base seleccionada por el instalador.
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'partidos' AND TABLE_NAME = 'Sustitucion')
BEGIN
	CREATE TABLE partidos.Sustitucion
	(
		IdSustitucion INT NOT NULL,
		Ingreso INT NOT NULL,
		Egreso INT NOT NULL,
		Motivo INT NOT NULL,
		CONSTRAINT PK_Sustitucion PRIMARY KEY (IdSustitucion),
		CONSTRAINT FK_Sustitucion_Evento FOREIGN KEY (IdSustitucion) REFERENCES partidos.Evento(IdEvento),
		CONSTRAINT FK_Sustitucion_Ingreso FOREIGN KEY (Ingreso) REFERENCES equipos.Jugador(IdJugador),
		CONSTRAINT FK_Sustitucion_Egreso FOREIGN KEY (Egreso) REFERENCES equipos.Jugador(IdJugador),
		CONSTRAINT FK_Sustitucion_Motivo FOREIGN KEY (Motivo) REFERENCES publicidad.Motivo(IdMotivo),
		CONSTRAINT CK_Sustitucion_Ingreso_Egreso CHECK (Ingreso <> Egreso)
	)
END
GO

GO
-- 32_Tabla_HistorialPublicidad.sql
--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Creacion de Tabla HistorialPublicidad

-- Ejecutar en la base seleccionada por el instalador.
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'publicidad' AND TABLE_NAME = 'HistorialPublicidad')
BEGIN
	CREATE TABLE publicidad.HistorialPublicidad
	(
		IdHistorial INT PRIMARY KEY IDENTITY(1, 1),
		IdPublicidad INT NOT NULL,
		IdPartido INT NOT NULL,
		IdEP INT NOT NULL,
        IdCF INT NOT NULL,
		CostoFinal DECIMAL(10,2) NOT NULL,
		CONSTRAINT UQ_HistorialPublicidad_PartidoEspacio UNIQUE (IdPartido, IdEP),
        CONSTRAINT CK_HistorialPublicidad_Costo CHECK (CostoFinal >= 0),
        FOREIGN KEY(IdCF) REFERENCES publicidad.CostoFranja(IdCF),
        FOREIGN KEY(IdPublicidad) REFERENCES publicidad.Publicidad(IdPublicidad),
		FOREIGN KEY(IdPartido) REFERENCES partidos.Partido(IdPartido),
		FOREIGN KEY(IdEP) REFERENCES publicidad.EspacioPublicitario(IdEP)
	)
END;
GO

GO
-- 33_Tabla_PublicidadPais.sql
--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Creacion de Tabla PublicidadPais

-- Ejecutar en la base seleccionada por el instalador.
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'publicidad' AND TABLE_NAME = 'PublicidadPais')
BEGIN
	CREATE TABLE publicidad.PublicidadPais
	(
		IdPublicidad INT NOT NULL,
		IdPais INT NOT NULL,
		PRIMARY KEY(IdPublicidad, IdPais),
		FOREIGN KEY(IdPublicidad) REFERENCES publicidad.Publicidad(IdPublicidad),
		FOREIGN KEY(IdPais) REFERENCES equipos.Pais(IdPais)
	)
END;
GO

GO
-- 34_Tabla_AnuncianteCampania.sql
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

GO
-- 35_Tabla_CambioConvocatoria.sql
--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Objetivo: Crear Tabla CambioConvocatoria

-- Ejecutar en la base seleccionada por el instalador.
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'equipos' AND TABLE_NAME = 'CambioConvocatoria')
BEGIN
	CREATE TABLE equipos.CambioConvocatoria
	(
		IdCambio INT PRIMARY KEY IDENTITY(1, 1),
		Seleccion INT NOT NULL,
		Egreso INT NOT NULL,
		Ingreso INT NOT NULL,
		Fecha DATE NOT NULL,
		Motivo VARCHAR(200) NOT NULL,
		CONSTRAINT FK_CambioConvocatoria_Seleccion FOREIGN KEY (Seleccion) REFERENCES equipos.Seleccion(IdSeleccion),
		CONSTRAINT FK_CambioConvocatoria_Egreso FOREIGN KEY (Egreso) REFERENCES equipos.Jugador(IdJugador),
		CONSTRAINT FK_CambioConvocatoria_Ingreso FOREIGN KEY (Ingreso) REFERENCES equipos.Jugador(IdJugador),
		CONSTRAINT CK_CambioConvocatoria_Ingreso_Egreso CHECK (Ingreso <> Egreso)
	)
END
GO

-- Migracion: la tabla vivia en TABLAS.*, se retira el esquema viejo una vez creado el vigente
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'TABLAS' AND TABLE_NAME = 'CambioConvocatoria')
AND EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'equipos' AND TABLE_NAME = 'CambioConvocatoria')
	DROP TABLE TABLAS.CambioConvocatoria
GO

GO
-- 36_Restricciones_Publicidad.sql
-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Grupo 7
-- Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 26/10/26. Revision auxiliar de penales y publicidad por sede.

GO
-- Se ejecuta despues de Sede y de todas las tablas; mantiene el orden original.
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_EspacioPublicitario_Sede')
 ALTER TABLE publicidad.EspacioPublicitario ADD CONSTRAINT FK_EspacioPublicitario_Sede FOREIGN KEY(IdSede) REFERENCES sedes.Sede(IdSede);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_CostoFranja_Sede')
 ALTER TABLE publicidad.CostoFranja ADD CONSTRAINT FK_CostoFranja_Sede FOREIGN KEY(IdSede) REFERENCES sedes.Sede(IdSede);
GO
-- Las FK garantizan existencia; estos triggers protegen la coincidencia de sedes
-- tambien ante cambios de padres y escrituras ajenas a los SP.
CREATE OR ALTER TRIGGER publicidad.trHistorial_Sedes ON publicidad.HistorialPublicidad AFTER INSERT, UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS (SELECT 1 FROM inserted h JOIN partidos.Partido p ON p.IdPartido=h.IdPartido
 JOIN publicidad.EspacioPublicitario e ON e.IdEP=h.IdEP JOIN publicidad.CostoFranja c ON c.IdCF=h.IdCF
 WHERE p.IdSede<>e.IdSede OR p.IdSede<>c.IdSede)
 THROW 51000, 'El espacio y la tarifa deben pertenecer a la sede del partido.', 1;
END;
GO
CREATE OR ALTER TRIGGER publicidad.trEspacio_SedeHistorica ON publicidad.EspacioPublicitario AFTER UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS (SELECT 1 FROM inserted i JOIN deleted d ON i.IdEP=d.IdEP
 JOIN publicidad.HistorialPublicidad h ON h.IdEP=i.IdEP WHERE i.IdSede<>d.IdSede OR i.Numero<>d.Numero)
 THROW 51000, 'No se puede trasladar ni renumerar un espacio con historial.', 1;
END;
GO
CREATE OR ALTER TRIGGER publicidad.trCostoFranja_SedeHistorica ON publicidad.CostoFranja AFTER UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS (SELECT 1 FROM inserted i JOIN deleted d ON i.IdCF=d.IdCF
 JOIN publicidad.HistorialPublicidad h ON h.IdCF=i.IdCF WHERE i.IdSede<>d.IdSede OR i.TipoFranja<>d.TipoFranja)
 THROW 51000, 'No se puede trasladar ni renombrar una tarifa con historial.', 1;
END;
GO
CREATE OR ALTER TRIGGER partidos.trPartido_SedePublicidad ON partidos.Partido AFTER UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS (SELECT 1 FROM inserted i JOIN deleted d ON i.IdPartido=d.IdPartido
 JOIN publicidad.HistorialPublicidad h ON h.IdPartido=i.IdPartido WHERE i.IdSede<>d.IdSede)
 THROW 51000, 'No se puede cambiar la sede de un partido con publicidad asignada.', 1;
 IF EXISTS (SELECT 1 FROM inserted i JOIN deleted d ON i.IdPartido=d.IdPartido
 WHERE (i.Eq1<>d.Eq1 OR i.Eq2<>d.Eq2 OR i.IdMundial<>d.IdMundial)
 AND EXISTS(SELECT 1 FROM partidos.Evento e WHERE e.Partido=i.IdPartido))
 THROW 51000, 'No se pueden cambiar equipos o Mundial de un partido con eventos.', 1;
END;
GO

GO
-- 37_Sp_Pais.sql
--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Creacion de Stored Procedures (ABM de Pais)

-- Ejecutar en la base seleccionada por el instalador.
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspPais_Registrar'))
    DROP PROCEDURE SP.uspPais_Registrar
GO
CREATE PROCEDURE SP.uspPais_Registrar
@nombre VARCHAR(50),
@idioma INT,
@huso INT,
@ptIni TIME,
@ptFin TIME,
@pbi BIGINT = NULL
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';

	BEGIN TRY
		--Chequeo validez
		IF(@nombre IS NULL) OR (LTRIM(RTRIM(@nombre)) = '')
			SET @errores += '- Valor invalido: Nombre.' + N' ';

		IF(@idioma IS NULL) OR (@idioma <= 0)
			SET @errores += '- Valor invalido: Idioma.' + N' ';

		IF(@huso IS NULL) OR (@huso <= 0)
			SET @errores += '- Valor invalido: Huso Horario.' + N' ';

		IF( (@ptIni IS NULL) OR (@ptFin IS NULL) OR (@ptFin <= @ptIni) )
			SET @errores += '- Valores invalidos: Inicio y Fin de Primetime.' + N' ';

		IF(@pbi IS NOT NULL) AND (@pbi < 0)
			SET @errores += '- Valor invalido: PBI.' + N' ';
			
		--Chequeo existencia
		IF(LEN(@errores) = 0)
		BEGIN
			IF NOT EXISTS(SELECT 1 FROM arbitros.Idioma WHERE IdIdioma = @idioma)
				SET @errores += '- Valor inexistente: Idioma.' + N' ';

			IF NOT EXISTS(SELECT 1 FROM sedes.HusoHorario WHERE IdHuso = @huso)
				SET @errores += '- Valor inexistente: Huso Horario.' + N' ';
		END

		--Chequeo dup
		IF (LEN(@errores) = 0) AND EXISTS(SELECT 1 FROM equipos.Pais WHERE NOMBRE = LTRIM(RTRIM(@nombre)))
			SET @errores += '- Valor duplicado: Pais (nombre).' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		INSERT INTO equipos.Pais(NOMBRE, PBI, Idioma, HusoHorario, PtIni, PtFin)
		VALUES(LTRIM(RTRIM(@nombre)), @pbi, @idioma, @huso, @ptIni, @ptFin)
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspPais_Update'))
    DROP PROCEDURE SP.uspPais_Update
GO
CREATE PROCEDURE SP.uspPais_Update
@idPais INT,
@nombre VARCHAR(50) = NULL,
@idioma INT = NULL,
@huso INT = NULL,
@ptIni TIME = NULL,
@ptFin TIME = NULL,
@pbi BIGINT = NULL
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		--Chequeo validez
		IF(@idPais IS NULL) OR (@idPais <= 0)
			SET @errores += '- Valor invalido: ID Pais.' + N' ';

		IF(@nombre IS NOT NULL) AND (LTRIM(RTRIM(@nombre)) = '')
			SET @errores += '- Valor invalido: Nombre.' + N' ';

		IF(@idioma IS NOT NULL) AND (@idioma <= 0)
			SET @errores += '- Valor invalido: Idioma.' + N' ';

		IF(@huso IS NOT NULL) AND (@huso <= 0)
			SET @errores += '- Valor invalido: Huso Horario.' + N' ';

		IF(@pbi IS NOT NULL) AND (@pbi < 0)
			SET @errores += '- Valor invalido: PBI.' + N' ';

		--Chequeo existencia
		IF (LEN(@errores) = 0)
		BEGIN
			IF NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @idPais)
				SET @errores += '- Valor inexistente: ID Pais.' + N' ';
		
			IF (@idioma IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM arbitros.Idioma WHERE IdIdioma = @idioma)
				SET @errores += '- Valor inexistente: Idioma.' + N' ';

			IF (@huso IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM sedes.HusoHorario WHERE IdHuso = @huso)
				SET @errores += '- Valor inexistente: Huso Horario.' + N' ';
		END

		--Chequeo dup
		IF (LEN(@errores) = 0) AND (@nombre IS NOT NULL)
		   AND EXISTS(SELECT 1 FROM equipos.Pais WHERE NOMBRE = LTRIM(RTRIM(@nombre)) AND IdPais <> @idPais)
			SET @errores += '- Valor duplicado: Pais (nombre).' + N' ';

		--Chequeo franja primetime
		IF(LEN(@errores) = 0)
		AND
		(
			((@ptIni IS NULL) AND (@ptFin IS NOT NULL) AND (@ptFin <= (SELECT PtIni FROM equipos.Pais WHERE IdPais = @idPais)))
			OR
			((@ptIni IS NOT NULL) AND (@ptFin IS NULL) AND (@ptIni >= (SELECT PtFin FROM equipos.Pais WHERE IdPais = @idPais)))
			OR
			((@ptIni IS NOT NULL) AND (@ptFin IS NOT NULL) AND (@ptFin <= @ptIni))
		)
			SET @errores += '- Valores invalidos: Inicio y Fin de Primetime.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		UPDATE equipos.Pais
		SET NOMBRE = COALESCE(LTRIM(RTRIM(@nombre)), NOMBRE),
			Idioma = COALESCE(@idioma, Idioma),
			HusoHorario = COALESCE(@huso, HusoHorario),
			PtIni = COALESCE(@ptIni, PtIni),
			PtFin = COALESCE(@ptFin, PtFin),
			PBI = COALESCE(@pbi, PBI)
		WHERE IdPais = @idPais
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspPais_Bajar'))
    DROP PROCEDURE SP.uspPais_Bajar
GO
CREATE PROCEDURE SP.uspPais_Bajar
@idPais INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		--Chequeo validez
		IF(@idPais IS NULL) OR (@idPais <= 0)
			SET @errores += '- Valor invalido: ID Pais.' + N' ';

		--Chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @idPais)
			SET @errores += '- Valor inexistente: ID Pais.' + N' ';

		--Chequeo relaciones
		IF EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdPais = @idPais)
			SET @errores += '- Existen 1 o mas registros relacionados: Seleccion. Elimine dichos registros para continuar.' + N' ';

		IF EXISTS(SELECT 1 FROM sedes.Mundial WHERE IdPais = @idPais)
			SET @errores += '- Existen 1 o mas registros relacionados: Mundial. Elimine dichos registros para continuar.' + N' ';

		IF EXISTS(SELECT 1 FROM sedes.Sede WHERE IdPais = @idPais)
			SET @errores += '- Existen 1 o mas registros relacionados: Sede. Elimine dichos registros para continuar.' + N' ';

		IF EXISTS(SELECT 1 FROM equipos.Persona WHERE Pais = @idPais)
			SET @errores += '- Existen 1 o mas registros relacionados: Persona. Elimine dichos registros para continuar.' + N' ';

		IF EXISTS(SELECT 1 FROM publicidad.Anunciante WHERE IdPais = @idPais)
			SET @errores += '- Existen 1 o mas registros relacionados: Anunciante. Elimine dichos registros para continuar.' + N' ';

		IF EXISTS(SELECT 1 FROM publicidad.PublicidadPais WHERE IdPais = @idPais)
			SET @errores += '- Existen 1 o mas registros relacionados: PublicidadPais. Elimine dichos registros para continuar.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		DELETE FROM equipos.Pais WHERE IdPais = @idPais
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

GO
-- 38_Sp_Grupo.sql
--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Objetivo: Gestionar Tabla Grupo

-- Ejecutar en la base seleccionada por el instalador.
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspGrupo_Registrar'))
    DROP PROCEDURE SP.uspGrupo_Registrar
GO
CREATE PROCEDURE SP.uspGrupo_Registrar
@nombre VARCHAR(10)
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF (@nombre IS NULL) OR (LTRIM(RTRIM(@nombre)) = '')
			SET @errores += '- Valor invalido: Nombre.' + N' ';

		IF EXISTS (SELECT 1 FROM equipos.Grupo WHERE NOMBRE = LTRIM(RTRIM(@nombre)))
			SET @errores += '- Valor duplicado: Grupo (nombre).' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		INSERT INTO equipos.Grupo (NOMBRE)
		VALUES (LTRIM(RTRIM(@nombre)))
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspGrupo_Update'))
    DROP PROCEDURE SP.uspGrupo_Update
GO
CREATE PROCEDURE SP.uspGrupo_Update
@id INT,
@nombre VARCHAR(10)
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF (@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Grupo.' + N' ';

		IF (@nombre IS NULL) OR (LTRIM(RTRIM(@nombre)) = '')
			SET @errores += '- Valor invalido: Nombre.' + N' ';

		IF NOT EXISTS (SELECT 1 FROM equipos.Grupo WHERE IdGrupo = @id)
			SET @errores += '- Valor inexistente: ID Grupo.' + N' ';

		IF EXISTS (SELECT 1 FROM equipos.Grupo WHERE NOMBRE = LTRIM(RTRIM(@nombre)) AND IdGrupo <> @id)
			SET @errores += '- Valor duplicado: Grupo (nombre).' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		UPDATE equipos.Grupo
		SET NOMBRE = LTRIM(RTRIM(@nombre))
		WHERE IdGrupo = @id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspGrupo_Bajar'))
    DROP PROCEDURE SP.uspGrupo_Bajar
GO
CREATE PROCEDURE SP.uspGrupo_Bajar
@id INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF (@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Grupo.' + N' ';

		IF NOT EXISTS (SELECT 1 FROM equipos.Grupo WHERE IdGrupo = @id)
			SET @errores += '- Valor inexistente: ID Grupo.' + N' ';

		IF EXISTS (SELECT 1 FROM equipos.Seleccion WHERE IdGrupo = @id)
			SET @errores += '- Existen 1 o mas registros relacionados: Seleccion. Elimine dichos registros para continuar.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		DELETE FROM equipos.Grupo WHERE IdGrupo = @id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO

GO
-- 39_Sp_Club.sql
--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Creacion de Stored Procedures

-- Ejecutar en la base seleccionada por el instalador.
GO

--Club
IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspClub_Registrar'))
    DROP PROCEDURE SP.uspClub_Registrar
GO
CREATE PROCEDURE SP.uspClub_Registrar @nombre VARCHAR(20)
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF(@nombre IS NULL)
			SET @errores += '- Valor invalido: Nombre.' + N' ';

		IF EXISTS(SELECT 1 FROM equipos.Club WHERE Nombre = @nombre)
			SET @errores += '- Valor duplicado: Nombre.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		INSERT INTO equipos.Club(Nombre) VALUES (@nombre)
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspClub_Update'))
    DROP PROCEDURE SP.uspClub_Update
GO
CREATE PROCEDURE SP.uspClub_Update @id INT, @nombre VARCHAR(20)
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF(@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Club.' + N' ';

		IF(@nombre IS NULL)
			SET @errores += '- Valor invalido: Nombre.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM equipos.Club WHERE IdClub = @id)
			SET @errores += '- Valor inexistente: ID Club.' + N' ';

		IF EXISTS(SELECT 1 FROM equipos.Club WHERE Nombre = @nombre AND IdClub <> @id)
			SET @errores += '- Valor duplicado: Nombre.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		UPDATE equipos.Club
		SET Nombre = @nombre
		WHERE IdClub = @id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspClub_Bajar'))
    DROP PROCEDURE SP.uspClub_Bajar
GO
CREATE PROCEDURE SP.uspClub_Bajar @id INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF(@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Club.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM equipos.Club WHERE IdClub = @id)
			SET @errores += '- Valor inexistente: ID Club.' + N' ';

		IF EXISTS(SELECT 1 FROM equipos.Jugador WHERE Club = @id)
			SET @errores += '- Existen 1 o mas registros relacionados: Jugador. Elimine dichos registros para continuar.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		DELETE FROM equipos.Club WHERE IdClub = @id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

GO
-- 40_Sp_Idioma.sql
--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Creacion de Stored Procedures

-- Ejecutar en la base seleccionada por el instalador.
GO

--Idioma
IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspIdioma_Registrar'))
    DROP PROCEDURE SP.uspIdioma_Registrar
GO
CREATE PROCEDURE SP.uspIdioma_Registrar @descripcion VARCHAR(20)
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF(@descripcion IS NULL)
			SET @errores += '- Valor invalido: Descripcion.' + N' ';

		IF EXISTS(SELECT 1 FROM arbitros.Idioma WHERE Descripcion = @descripcion)
			SET @errores += '- Valor duplicado: Descripcion.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		INSERT INTO arbitros.Idioma(Descripcion) VALUES (@descripcion)
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspIdioma_Update'))
    DROP PROCEDURE SP.uspIdioma_Update
GO
CREATE PROCEDURE SP.uspIdioma_Update @id INT, @descripcion VARCHAR(20)
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF(@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Idioma.' + N' ';

		IF(@descripcion IS NULL)
			SET @errores += '- Valor invalido: Descripcion.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM arbitros.Idioma WHERE IdIdioma = @id)
			SET @errores += '- Valor inexistente: ID Idioma.' + N' ';

		IF EXISTS(SELECT 1 FROM arbitros.Idioma WHERE Descripcion = @descripcion AND IdIdioma <> @id)
			SET @errores += '- Valor duplicado: Descripcion.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		UPDATE arbitros.Idioma
		SET Descripcion = @descripcion
		WHERE IdIdioma = @id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspIdioma_Bajar'))
    DROP PROCEDURE SP.uspIdioma_Bajar
GO
CREATE PROCEDURE SP.uspIdioma_Bajar @id INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF(@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Idioma.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM arbitros.Idioma WHERE IdIdioma = @id)
			SET @errores += '- Valor inexistente: ID Idioma.' + N' ';

		IF EXISTS(SELECT 1 FROM arbitros.HablaIdioma WHERE Idioma = @id)
			SET @errores += '- Existen 1 o mas registros relacionados: HablaIdioma. Elimine dichos registros para continuar.' + N' ';

		IF EXISTS(SELECT 1 FROM publicidad.Publicidad WHERE IdIdioma = @id)
			SET @errores += '- Existen 1 o mas registros relacionados: Publicidad. Elimine dichos registros para continuar.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		DELETE FROM arbitros.Idioma WHERE IdIdioma = @id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

GO
-- 41_Sp_Fase.sql
-- Universidad Nacional de La Matanza
-- Bases de datos aplicada 
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 26/10/26
-- Objetivo: SPs Fase

-- Ejecutar en la base seleccionada por el instalador.
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspFase_Registrar'))
  DROP PROCEDURE SP.uspFase_Registrar
GO
CREATE PROCEDURE SP.uspFase_Registrar
@Descripcion VARCHAR(20)
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF(@Descripcion IS NULL)
			SET @errores += '- Valor invalido: Descripcion nula' + N' ';
		IF(@Descripcion NOT IN ('Grupos','Dieciseisavos','Octavos','Cuartos','Semifinal','Tercer Puesto','Final'))
		BEGIN
			DECLARE @msg VARCHAR(100) = '- Valor invalido: ' + ISNULL(@Descripcion,'NULL') + '.';
			SET @errores += @msg + N' ';
		END
		IF EXISTS(SELECT 1 FROM partidos.Fase WHERE Descripcion=@Descripcion)
			SET @errores += '- Fase repetida' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;
		INSERT INTO partidos.Fase(Descripcion) VALUES(@Descripcion)
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO
------------------------------------------------------------------------------------------------

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspFase_Update'))
  DROP PROCEDURE SP.uspFase_Update
GO
CREATE PROCEDURE SP.uspFase_Update
@Id INT,
@Descripcion VARCHAR(20)
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF(@Id IS NULL OR @Id <= 0)
		BEGIN
			DECLARE @msg VARCHAR(100) = '- Valor invalido: Id (' + ISNULL(CAST(@Id AS VARCHAR(10)),'NULL') + ').';
			SET @errores += @msg + N' ';
		END
		IF(@Descripcion IS NULL)
			SET @errores += '- Valor invalido: Descripcion nula.' + N' ';
		IF(@Descripcion NOT IN ('Grupos','Dieciseisavos','Octavos','Cuartos','Semifinal','Tercer Puesto','Final'))
		BEGIN
			DECLARE @msg2 VARCHAR(100) = '- Valor invalido: ' + ISNULL(@Descripcion,'NULL') + '.';
			SET @errores += @msg2 + N' ';
		END
		IF NOT EXISTS(SELECT 1 FROM partidos.Fase WHERE IdFase=@Id)
		BEGIN
			DECLARE @msg3 VARCHAR(100) = '- Valor inexistente: Id (' + ISNULL(CAST(@Id AS VARCHAR(10)),'NULL') + ').';
			SET @errores += @msg3 + N' ';
		END
		IF EXISTS(SELECT 1 FROM partidos.Fase WHERE Descripcion=@Descripcion AND IdFase<>@Id)
			SET @errores += '- Valor duplicado: Fase.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;
		UPDATE partidos.Fase SET Descripcion=@Descripcion WHERE IdFase=@Id;
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO
----------------------------------------------------------------------------------------

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspFase_Bajar'))
  DROP PROCEDURE SP.uspFase_Bajar
GO
CREATE PROCEDURE SP.uspFase_Bajar
@Id INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF(@Id IS NULL OR @Id <= 0)
		BEGIN
			DECLARE @msg VARCHAR(100) = '- Valor invalido: Id (' + ISNULL(CAST(@Id AS VARCHAR(10)),'NULL') + ').';
			SET @errores += @msg + N' ';
		END
		IF NOT EXISTS(SELECT 1 FROM partidos.Fase WHERE IdFase=@Id)
		BEGIN
			DECLARE @msg2 VARCHAR(100) = '- Valor inexistente: Id (' + ISNULL(CAST(@Id AS VARCHAR(10)),'NULL') + ').';
			SET @errores += @msg2 + N' ';
		END
		IF EXISTS(SELECT 1 FROM partidos.Partido WHERE IdFase=@Id)
			SET @errores += '- Existen partidos con esta fase.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;
		DELETE FROM partidos.Fase WHERE IdFase=@Id;
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO

GO
-- 42_Sp_Periodo.sql
--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Objetivo: SP de ABM de la tabla partidos.Periodo (Alta, Baja, Modificacion).
--Las validaciones se acumulan en una variable y se lanzan con un unico THROW.

-- Ejecutar en la base seleccionada por el instalador.
GO

-- =============================================
-- partidos.Periodo_Alta
-- Inserta un periodo. Todos los parametros son obligatorios.
-- =============================================
CREATE OR ALTER PROCEDURE partidos.Periodo_Alta
	@idPeriodo INT,
	@descripcion VARCHAR(50),
	@inicio INT,
	@fin INT,
    @esPenales BIT = 0
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE @errores NVARCHAR(MAX) = N'';

	IF @idPeriodo IS NULL
		SET @errores += N'IdPeriodo es obligatorio. ';
	IF @idPeriodo IS NOT NULL AND @idPeriodo <= 0
		SET @errores += N'IdPeriodo debe ser mayor a 0. ';
	IF @idPeriodo IS NOT NULL AND EXISTS (SELECT 1 FROM partidos.Periodo WHERE IdPeriodo = @idPeriodo)
		SET @errores += N'Ya existe un periodo con IdPeriodo ' + CAST(@idPeriodo AS NVARCHAR(10)) + N'. ';

	IF @descripcion IS NULL OR LTRIM(RTRIM(@descripcion)) = N''
		SET @errores += N'La descripcion es obligatoria. ';
	IF @descripcion IS NOT NULL AND LEN(@descripcion) > 12
		SET @errores += N'La descripcion no puede superar los 12 caracteres. ';
	IF @descripcion IS NOT NULL AND EXISTS (SELECT 1 FROM partidos.Periodo WHERE Descripcion = @descripcion)
		SET @errores += N'Ya existe un periodo con la descripcion indicada. ';

	IF @esPenales = 0 AND @inicio IS NULL
		SET @errores += N'El inicio es obligatorio. ';
	IF @inicio IS NOT NULL AND @inicio < 0
		SET @errores += N'El inicio no puede ser negativo. ';

	IF @esPenales = 0 AND @fin IS NULL
		SET @errores += N'El fin es obligatorio. ';
	IF @fin IS NOT NULL AND @inicio IS NOT NULL AND @fin < @inicio
		SET @errores += N'El fin no puede ser menor al inicio. ';

	IF @esPenales IS NULL SET @errores += N'EsPenales es obligatorio. ';
    IF @esPenales = 1 AND (@inicio IS NOT NULL OR @fin IS NOT NULL)
        SET @errores += N'Penales requiere Inicio y Fin NULL. ';
    IF LEN(@errores) > 0
		THROW 50000, @errores, 1;

	BEGIN TRY
		BEGIN TRANSACTION;

		INSERT INTO partidos.Periodo (IdPeriodo, Descripcion, Inicio, Fin, EsPenales)
		VALUES (@idPeriodo, @descripcion, @inicio, @fin, @esPenales);

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END;
GO

-- =============================================
-- partidos.Periodo_Modificacion
-- Modifica un periodo existente. Todos los parametros son obligatorios.
-- =============================================
CREATE OR ALTER PROCEDURE partidos.Periodo_Modificacion
	@idPeriodo INT,
	@descripcion VARCHAR(50),
	@inicio INT,
	@fin INT,
    @esPenales BIT = 0
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE @errores NVARCHAR(MAX) = N'';

	IF @idPeriodo IS NULL
		SET @errores += N'IdPeriodo es obligatorio. ';
	IF @idPeriodo IS NOT NULL AND NOT EXISTS (SELECT 1 FROM partidos.Periodo WHERE IdPeriodo = @idPeriodo)
		SET @errores += N'No existe un periodo con IdPeriodo ' + CAST(@idPeriodo AS NVARCHAR(10)) + N'. ';

	IF @descripcion IS NULL OR LTRIM(RTRIM(@descripcion)) = N''
		SET @errores += N'La descripcion es obligatoria. ';
	IF @descripcion IS NOT NULL AND LEN(@descripcion) > 12
		SET @errores += N'La descripcion no puede superar los 12 caracteres. ';
	IF @descripcion IS NOT NULL AND EXISTS (SELECT 1 FROM partidos.Periodo WHERE Descripcion = @descripcion AND IdPeriodo <> @idPeriodo)
		SET @errores += N'Otro periodo ya tiene esa descripcion. ';

	IF @esPenales = 0 AND @inicio IS NULL
		SET @errores += N'El inicio es obligatorio. ';
	IF @inicio IS NOT NULL AND @inicio < 0
		SET @errores += N'El inicio no puede ser negativo. ';

	IF @esPenales = 0 AND @fin IS NULL
		SET @errores += N'El fin es obligatorio. ';
	IF @fin IS NOT NULL AND @inicio IS NOT NULL AND @fin < @inicio
		SET @errores += N'El fin no puede ser menor al inicio. ';

	IF EXISTS (SELECT 1 FROM partidos.Evento WHERE Periodo=@idPeriodo)
       AND EXISTS (SELECT 1 FROM partidos.Periodo WHERE IdPeriodo=@idPeriodo
         AND (EsPenales<>@esPenales OR ISNULL(Inicio,-1)<>ISNULL(@inicio,-1) OR ISNULL(Fin,-1)<>ISNULL(@fin,-1)))
        SET @errores += N'No se pueden cambiar los limites o tipo de un periodo con eventos. ';
    IF @esPenales IS NULL SET @errores += N'EsPenales es obligatorio. ';
    IF @esPenales = 1 AND (@inicio IS NOT NULL OR @fin IS NOT NULL)
        SET @errores += N'Penales requiere Inicio y Fin NULL. ';
    IF LEN(@errores) > 0
		THROW 50000, @errores, 1;

	BEGIN TRY
		BEGIN TRANSACTION;

		UPDATE partidos.Periodo
		SET Descripcion = @descripcion,
			Inicio = @inicio,
			Fin = @fin,
            EsPenales = @esPenales
		WHERE IdPeriodo = @idPeriodo;

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END;
GO

-- =============================================
-- partidos.Periodo_Baja
-- Elimina un periodo. No se permite si tiene eventos asociados.
-- =============================================
CREATE OR ALTER PROCEDURE partidos.Periodo_Baja
	@idPeriodo INT
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE @errores NVARCHAR(MAX) = N'';

	IF @idPeriodo IS NULL
		SET @errores += N'IdPeriodo es obligatorio. ';
	IF @idPeriodo IS NOT NULL AND NOT EXISTS (SELECT 1 FROM partidos.Periodo WHERE IdPeriodo = @idPeriodo)
		SET @errores += N'No existe un periodo con IdPeriodo ' + CAST(@idPeriodo AS NVARCHAR(10)) + N'. ';
	IF @idPeriodo IS NOT NULL AND EXISTS (SELECT 1 FROM partidos.Evento WHERE Periodo = @idPeriodo)
		SET @errores += N'No se puede eliminar el periodo: tiene eventos asociados. ';

	IF LEN(@errores) > 0
		THROW 50000, @errores, 1;

	BEGIN TRY
		BEGIN TRANSACTION;

		DELETE FROM partidos.Periodo
		WHERE IdPeriodo = @idPeriodo;

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END;
GO

GO
-- 43_Sp_EspacioPublicitario.sql
-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Grupo 7
-- Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 26/10/26. Revision auxiliar de penales y publicidad por sede.

GO
-- Objetivo: ABM de EspacioPublicitario por sede; la identidad de sede no se mueve en Update.
CREATE OR ALTER PROCEDURE SP.EspacioPublicitario_Registrar
 @tipo VARCHAR(30),@costo DECIMAL(10,2),@idSede INT, @numero TINYINT
AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @errores NVARCHAR(2048)=N'';
 IF @tipo IS NULL OR LTRIM(RTRIM(@tipo))='' SET @errores+=N'Descripcion obligatoria. ';
 IF @costo IS NULL OR @costo<0 SET @errores+=N'Costo debe ser no negativo. ';
 IF NOT EXISTS(SELECT 1 FROM sedes.Sede WHERE IdSede=@idSede) SET @errores+=N'Sede inexistente. ';
 IF @numero IS NULL OR @numero NOT BETWEEN 1 AND 4 SET @errores+=N'Numero debe estar entre 1 y 4. ';
 IF EXISTS(SELECT 1 FROM publicidad.EspacioPublicitario WHERE IdSede=@idSede AND Numero=@numero) SET @errores+=N'Registro duplicado en la sede. ';
 IF LEN(@errores)>0 THROW 51000,@errores,1;
 INSERT publicidad.EspacioPublicitario(IdSede,Tipo,Costo,Numero) VALUES(@idSede,LTRIM(RTRIM(@tipo)),@costo,@numero);
END;
GO
CREATE OR ALTER PROCEDURE SP.EspacioPublicitario_Update
 @idEP INT,@tipo VARCHAR(30)=NULL,@costo DECIMAL(10,2)=NULL
AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @errores NVARCHAR(2048)=N'';
 IF NOT EXISTS(SELECT 1 FROM publicidad.EspacioPublicitario WHERE IdEP=@idEP) SET @errores+=N'Registro inexistente. ';
 IF @tipo IS NOT NULL AND LTRIM(RTRIM(@tipo))='' SET @errores+=N'Descripcion vacia. ';
 IF @costo<0 SET @errores+=N'Costo negativo. ';
 IF LEN(@errores)>0 THROW 51000,@errores,1;
 UPDATE publicidad.EspacioPublicitario SET Tipo=COALESCE(LTRIM(RTRIM(@tipo)),Tipo),Costo=COALESCE(@costo,Costo) WHERE IdEP=@idEP;
END;
GO
CREATE OR ALTER PROCEDURE SP.EspacioPublicitario_Bajar @idEP INT AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @errores NVARCHAR(2048)=N'';
 IF NOT EXISTS(SELECT 1 FROM publicidad.EspacioPublicitario WHERE IdEP=@idEP) SET @errores+=N'Registro inexistente. ';
 IF EXISTS(SELECT 1 FROM publicidad.HistorialPublicidad WHERE IdEP=@idEP) SET @errores+=N'Existen asignaciones publicitarias relacionadas. ';
 IF LEN(@errores)>0 THROW 51000,@errores,1;
 DELETE publicidad.EspacioPublicitario WHERE IdEP=@idEP;
END;
GO

GO
-- 44_Sp_CostoFranja.sql
-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Grupo 7
-- Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 26/10/26. Revision auxiliar de penales y publicidad por sede.

GO
-- Objetivo: ABM de CostoFranja por sede; la identidad de sede no se mueve en Update.
CREATE OR ALTER PROCEDURE SP.CostoFranja_Registrar
 @tipoFranja VARCHAR(30),@costo DECIMAL(10,2),@idSede INT
AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @errores NVARCHAR(2048)=N'';
 IF @tipoFranja IS NULL OR LTRIM(RTRIM(@tipoFranja))='' SET @errores+=N'Descripcion obligatoria. ';
 IF @costo IS NULL OR @costo<0 SET @errores+=N'Costo debe ser no negativo. ';
 IF NOT EXISTS(SELECT 1 FROM sedes.Sede WHERE IdSede=@idSede) SET @errores+=N'Sede inexistente. ';
 
 IF EXISTS(SELECT 1 FROM publicidad.CostoFranja WHERE IdSede=@idSede AND TipoFranja=@tipoFranja) SET @errores+=N'Registro duplicado en la sede. ';
 IF LEN(@errores)>0 THROW 51000,@errores,1;
 INSERT publicidad.CostoFranja(IdSede,TipoFranja,Costo) VALUES(@idSede,LTRIM(RTRIM(@tipoFranja)),@costo);
END;
GO
CREATE OR ALTER PROCEDURE SP.CostoFranja_Update
 @idCF INT,@tipoFranja VARCHAR(30)=NULL,@costo DECIMAL(10,2)=NULL
AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @errores NVARCHAR(2048)=N'';
 IF NOT EXISTS(SELECT 1 FROM publicidad.CostoFranja WHERE IdCF=@idCF) SET @errores+=N'Registro inexistente. ';
 IF @tipoFranja IS NOT NULL AND LTRIM(RTRIM(@tipoFranja))='' SET @errores+=N'Descripcion vacia. ';
 IF @costo<0 SET @errores+=N'Costo negativo. ';
 IF EXISTS(SELECT 1 FROM publicidad.CostoFranja a JOIN publicidad.CostoFranja b ON a.IdSede=b.IdSede
 WHERE a.IdCF=@idCF AND b.IdCF<>a.IdCF AND b.TipoFranja=@tipoFranja) SET @errores+=N'Franja duplicada en la sede. ';
 IF @tipoFranja IS NOT NULL AND EXISTS(SELECT 1 FROM publicidad.HistorialPublicidad h JOIN publicidad.CostoFranja c ON c.IdCF=h.IdCF WHERE c.IdCF=@idCF AND c.TipoFranja<>@tipoFranja)
 SET @errores+=N'No se puede renombrar una franja utilizada. ';
 IF LEN(@errores)>0 THROW 51000,@errores,1;
 UPDATE publicidad.CostoFranja SET TipoFranja=COALESCE(LTRIM(RTRIM(@tipoFranja)),TipoFranja),Costo=COALESCE(@costo,Costo) WHERE IdCF=@idCF;
END;
GO
CREATE OR ALTER PROCEDURE SP.CostoFranja_Bajar @idCF INT AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @errores NVARCHAR(2048)=N'';
 IF NOT EXISTS(SELECT 1 FROM publicidad.CostoFranja WHERE IdCF=@idCF) SET @errores+=N'Registro inexistente. ';
 IF EXISTS(SELECT 1 FROM publicidad.HistorialPublicidad WHERE IdCF=@idCF) SET @errores+=N'Existen asignaciones publicitarias relacionadas. ';
 IF LEN(@errores)>0 THROW 51000,@errores,1;
 DELETE publicidad.CostoFranja WHERE IdCF=@idCF;
END;
GO

GO
-- 45_Sp_Motivo.sql
--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Creacion de Stored Procedures

-- Ejecutar en la base seleccionada por el instalador.
GO

--Motivo
IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspMotivo_Registrar'))
    DROP PROCEDURE SP.uspMotivo_Registrar
GO
CREATE PROCEDURE SP.uspMotivo_Registrar @descripcion VARCHAR(100)
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF(@descripcion IS NULL)
			SET @errores += '- Valor invalido: Descripcion.' + N' ';

		IF EXISTS(SELECT 1 FROM publicidad.Motivo WHERE Descripcion = @descripcion)
			SET @errores += '- Valor duplicado: Descripcion.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		INSERT INTO publicidad.Motivo(Descripcion) VALUES (@descripcion)
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspMotivo_Update'))
    DROP PROCEDURE SP.uspMotivo_Update
GO
CREATE PROCEDURE SP.uspMotivo_Update @id INT, @descripcion VARCHAR(100)
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF(@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Motivo.' + N' ';

		IF(@descripcion IS NULL)
			SET @errores += '- Valor invalido: Descripcion.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM publicidad.Motivo WHERE IdMotivo = @id)
			SET @errores += '- Valor inexistente: ID Motivo.' + N' ';

		IF EXISTS(SELECT 1 FROM publicidad.Motivo WHERE Descripcion = @descripcion AND IdMotivo <> @id)
			SET @errores += '- Valor duplicado: Descripcion.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		UPDATE publicidad.Motivo
		SET Descripcion = @descripcion
		WHERE IdMotivo = @id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspMotivo_Bajar'))
    DROP PROCEDURE SP.uspMotivo_Bajar
GO
CREATE PROCEDURE SP.uspMotivo_Bajar @id INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF(@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Motivo.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM publicidad.Motivo WHERE IdMotivo = @id)
			SET @errores += '- Valor inexistente: ID Motivo.' + N' ';

		IF EXISTS(SELECT 1 FROM partidos.Sustitucion WHERE Motivo = @id)
			SET @errores += '- Existen 1 o mas registros relacionados: Sustitucion. Elimine dichos registros para continuar.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		DELETE FROM publicidad.Motivo WHERE IdMotivo = @id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

GO
-- 46_Sp_Campania.sql
--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Creacion de Stored Procedures

-- Ejecutar en la base seleccionada por el instalador.
GO

--Campania
IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspCampania_Registrar'))
    DROP PROCEDURE SP.uspCampania_Registrar
GO
CREATE PROCEDURE SP.uspCampania_Registrar @nombre VARCHAR(50), @descripcion VARCHAR(200)
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF(@nombre IS NULL)
			SET @errores += '- Valor invalido: Nombre.' + N' ';

		IF(@descripcion IS NULL)
			SET @errores += '- Valor invalido: Descripcion.' + N' ';

		IF EXISTS(SELECT 1 FROM publicidad.Campania WHERE Nombre = @nombre)
			SET @errores += '- Valor duplicado: Nombre.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		INSERT INTO publicidad.Campania(Nombre, Descripcion) VALUES (@nombre, @descripcion)
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspCampania_Update'))
    DROP PROCEDURE SP.uspCampania_Update
GO
CREATE PROCEDURE SP.uspCampania_Update @id INT, @nombre VARCHAR(50), @descripcion VARCHAR(200)
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF(@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Campania.' + N' ';

		IF(@nombre IS NULL)
			SET @errores += '- Valor invalido: Nombre.' + N' ';

		IF(@descripcion IS NULL)
			SET @errores += '- Valor invalido: Descripcion.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM publicidad.Campania WHERE IdCampania = @id)
			SET @errores += '- Valor inexistente: ID Campania.' + N' ';

		IF EXISTS(SELECT 1 FROM publicidad.Campania WHERE Nombre = @nombre AND IdCampania <> @id)
			SET @errores += '- Valor duplicado: Nombre.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		UPDATE publicidad.Campania
		SET Nombre = @nombre, Descripcion = @descripcion
		WHERE IdCampania = @id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspCampania_Bajar'))
    DROP PROCEDURE SP.uspCampania_Bajar
GO
CREATE PROCEDURE SP.uspCampania_Bajar @id INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF(@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Campania.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM publicidad.Campania WHERE IdCampania = @id)
			SET @errores += '- Valor inexistente: ID Campania.' + N' ';

		IF EXISTS(SELECT 1 FROM publicidad.Publicidad WHERE IdCampania = @id)
			SET @errores += '- Existen 1 o mas registros relacionados: Publicidad. Elimine dichos registros para continuar.' + N' ';

		IF EXISTS(SELECT 1 FROM publicidad.AnuncianteCampania WHERE IdCampania = @id)
			SET @errores += '- Existen 1 o mas registros relacionados: AnuncianteCampania. Elimine dichos registros para continuar.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		DELETE FROM publicidad.Campania WHERE IdCampania = @id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

GO
-- 47_Sp_Mundial.sql
--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Objetivo: Gestionar Tabla Mundial

-- Ejecutar en la base seleccionada por el instalador.
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspMundial_Registrar'))
    DROP PROCEDURE SP.uspMundial_Registrar
GO
CREATE PROCEDURE SP.uspMundial_Registrar
@idPais INT,
@fechaInicio DATE,
@fechaFin DATE,
@tamMin INT,
@tamMax INT,
@ventanas INT,
@cantidad INT,
@suspMax INT,
@suspTiempo INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF (@idPais IS NULL) OR (@idPais <= 0)
			SET @errores += '- Valor invalido: ID Pais.' + N' ';

		IF (@fechaInicio IS NULL) OR (@fechaFin IS NULL)
			SET @errores += '- Valor invalido: Fechas de actividad.' + N' ';

		IF (@fechaInicio IS NOT NULL) AND (@fechaFin IS NOT NULL) AND (@fechaFin <= @fechaInicio)
			SET @errores += '- La fecha de fin debe ser posterior a la de inicio.' + N' ';

		IF (@tamMin IS NULL) OR (@tamMax IS NULL)
			SET @errores += '- Valor invalido: Tamanio de seleccion.' + N' ';

		IF (@tamMin IS NOT NULL) AND (@tamMax IS NOT NULL) AND (@tamMin > @tamMax)
			SET @errores += '- El tamanio minimo no puede superar al maximo.' + N' ';

		IF (@ventanas IS NULL) OR (@ventanas <= 0)
			SET @errores += '- Valor invalido: Ventanas de cambios.' + N' ';

		IF (@cantidad IS NULL) OR (@cantidad <= 0)
			SET @errores += '- Valor invalido: Cantidad de cambios.' + N' ';

		IF (@suspMax IS NULL) OR (@suspMax <= 0)
			SET @errores += '- Valor invalido: Maximo de tarjetas para suspension.' + N' ';

		IF (@suspTiempo IS NULL) OR (@suspTiempo <= 0)
			SET @errores += '- Valor invalido: Tiempo de suspension.' + N' ';

		IF NOT EXISTS (SELECT 1 FROM equipos.Pais WHERE IdPais = @idPais)
			SET @errores += '- Valor inexistente: ID Pais.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		INSERT INTO sedes.Mundial (IdPais, ACTIVIDAD_FECHA_INICIO, ACTIVIDAD_FECHA_FIN, TAMANIO_SELECCION_MINIMO, TAMANIO_SELECCION_MAXIMO, CAMBIOS_VENTANAS, CAMBIOS_CANTIDAD, SUSPENSION_TARJETAS_MAXIMAS, SUSPENSION_TIEMPO)
		VALUES (@idPais, @fechaInicio, @fechaFin, @tamMin, @tamMax, @ventanas, @cantidad, @suspMax, @suspTiempo)
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspMundial_Update'))
    DROP PROCEDURE SP.uspMundial_Update
GO
CREATE PROCEDURE SP.uspMundial_Update
@id INT,
@idPais INT = NULL,
@fechaInicio DATE = NULL,
@fechaFin DATE = NULL,
@tamMin INT = NULL,
@tamMax INT = NULL,
@ventanas INT = NULL,
@cantidad INT = NULL,
@suspMax INT = NULL,
@suspTiempo INT = NULL
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	DECLARE @vFechaInicio DATE
	DECLARE @vFechaFin DATE
	DECLARE @vTamMin INT
	DECLARE @vTamMax INT

	BEGIN TRY
		IF (@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Mundial.' + N' ';

		IF (@idPais IS NOT NULL) AND (@idPais <= 0)
			SET @errores += '- Valor invalido: ID Pais.' + N' ';

		IF (@ventanas IS NOT NULL) AND (@ventanas <= 0)
			SET @errores += '- Valor invalido: Ventanas de cambios.' + N' ';

		IF (@cantidad IS NOT NULL) AND (@cantidad <= 0)
			SET @errores += '- Valor invalido: Cantidad de cambios.' + N' ';

		IF (@suspMax IS NOT NULL) AND (@suspMax <= 0)
			SET @errores += '- Valor invalido: Maximo de tarjetas para suspension.' + N' ';

		IF (@suspTiempo IS NOT NULL) AND (@suspTiempo <= 0)
			SET @errores += '- Valor invalido: Tiempo de suspension.' + N' ';

		IF NOT EXISTS (SELECT 1 FROM sedes.Mundial WHERE IdMundial = @id)
			SET @errores += '- Valor inexistente: ID Mundial.' + N' ';

		IF (@idPais IS NOT NULL) AND NOT EXISTS (SELECT 1 FROM equipos.Pais WHERE IdPais = @idPais)
			SET @errores += '- Valor inexistente: ID Pais.' + N' ';

		IF ((@fechaInicio IS NOT NULL) OR (@fechaFin IS NOT NULL))
		BEGIN
			SELECT @vFechaInicio = COALESCE(@fechaInicio, ACTIVIDAD_FECHA_INICIO), @vFechaFin = COALESCE(@fechaFin, ACTIVIDAD_FECHA_FIN) FROM sedes.Mundial WHERE IdMundial = @id

			IF (@vFechaFin <= @vFechaInicio)
				SET @errores += '- La fecha de fin debe ser posterior a la de inicio.' + N' ';
		END

		IF ((@tamMin IS NOT NULL) OR (@tamMax IS NOT NULL))
		BEGIN
			SELECT @vTamMin = COALESCE(@tamMin, TAMANIO_SELECCION_MINIMO), @vTamMax = COALESCE(@tamMax, TAMANIO_SELECCION_MAXIMO) FROM sedes.Mundial WHERE IdMundial = @id

			IF (@vTamMin > @vTamMax)
				SET @errores += '- El tamanio minimo no puede superar al maximo.' + N' ';
		END

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		UPDATE sedes.Mundial
		SET IdPais = COALESCE(@idPais, IdPais),
			ACTIVIDAD_FECHA_INICIO = COALESCE(@fechaInicio, ACTIVIDAD_FECHA_INICIO),
			ACTIVIDAD_FECHA_FIN = COALESCE(@fechaFin, ACTIVIDAD_FECHA_FIN),
			TAMANIO_SELECCION_MINIMO = COALESCE(@tamMin, TAMANIO_SELECCION_MINIMO),
			TAMANIO_SELECCION_MAXIMO = COALESCE(@tamMax, TAMANIO_SELECCION_MAXIMO),
			CAMBIOS_VENTANAS = COALESCE(@ventanas, CAMBIOS_VENTANAS),
			CAMBIOS_CANTIDAD = COALESCE(@cantidad, CAMBIOS_CANTIDAD),
			SUSPENSION_TARJETAS_MAXIMAS = COALESCE(@suspMax, SUSPENSION_TARJETAS_MAXIMAS),
			SUSPENSION_TIEMPO = COALESCE(@suspTiempo, SUSPENSION_TIEMPO)
		WHERE IdMundial = @id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspMundial_Bajar'))
    DROP PROCEDURE SP.uspMundial_Bajar
GO
CREATE PROCEDURE SP.uspMundial_Bajar
@id INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF (@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Mundial.' + N' ';

		IF NOT EXISTS (SELECT 1 FROM sedes.Mundial WHERE IdMundial = @id)
			SET @errores += '- Valor inexistente: ID Mundial.' + N' ';

		IF EXISTS (SELECT 1 FROM equipos.Seleccion WHERE IdMundial = @id)
			SET @errores += '- Existen 1 o mas registros relacionados: Seleccion. Elimine dichos registros para continuar.' + N' ';

		IF EXISTS (SELECT 1 FROM partidos.Partido WHERE IdMundial = @id)
			SET @errores += '- Existen 1 o mas registros relacionados: Partido. Elimine dichos registros para continuar.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		DELETE FROM sedes.Mundial WHERE IdMundial = @id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO

GO
-- 48_Sp_HusoHorario.sql
--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Creacion de Stored Procedures (ABM de HusoHorario)

-- Ejecutar en la base seleccionada por el instalador.
GO

--alta de huso horario
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspHusoHorario_Registrar'))
    DROP PROCEDURE SP.uspHusoHorario_Registrar
GO
CREATE PROCEDURE SP.uspHusoHorario_Registrar
@nombre VARCHAR(50)
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		--Chequeo validez
		IF(@nombre IS NULL) OR (LTRIM(RTRIM(@nombre)) = '')
			SET @errores += '- Valor invalido: Nombre.' + N' ';

		--Chequeo dup
		IF EXISTS(SELECT 1 FROM sedes.HusoHorario WHERE Nombre = @nombre)
			SET @errores += '- Valor duplicado: Nombre.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		INSERT INTO sedes.HusoHorario(Nombre)
		VALUES( LTRIM(RTRIM(@nombre)) )
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

--modificacion de huso horario
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspHusoHorario_Update'))
    DROP PROCEDURE SP.uspHusoHorario_Update
GO
CREATE PROCEDURE SP.uspHusoHorario_Update
@idHuso INT,
@nombre VARCHAR(50) = NULL
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		--Chequeo validez (solo lo que vino con valor)
		IF(@idHuso IS NULL) OR (@idHuso <= 0)
			SET @errores += '- Valor invalido: ID HusoHorario.' + N' ';

		IF(@nombre IS NOT NULL) AND (LTRIM(RTRIM(@nombre)) = '')
			SET @errores += '- Valor invalido: Nombre.' + N' ';

		--Chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM sedes.HusoHorario WHERE IdHuso = @idHuso)
			SET @errores += '- Valor inexistente: ID HusoHorario.' + N' ';

		--Chequeo dup (excluyendo el propio registro)
		IF(@nombre IS NOT NULL)
		   AND EXISTS(SELECT 1 FROM sedes.HusoHorario WHERE Nombre = @nombre AND IdHuso <> @idHuso)
			SET @errores += '- Valor duplicado: Nombre.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		UPDATE sedes.HusoHorario
		SET Nombre = COALESCE(LTRIM(RTRIM(@nombre)), Nombre)
		WHERE IdHuso = @idHuso
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

--baja de huso horario
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspHusoHorario_Bajar'))
    DROP PROCEDURE SP.uspHusoHorario_Bajar
GO
CREATE PROCEDURE SP.uspHusoHorario_Bajar
@idHuso INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		--Chequeo validez
		IF(@idHuso IS NULL) OR (@idHuso <= 0)
			SET @errores += '- Valor invalido: ID HusoHorario.' + N' ';

		--Chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM sedes.HusoHorario WHERE IdHuso = @idHuso)
			SET @errores += '- Valor inexistente: ID HusoHorario.' + N' ';

		--Chequeo relaciones
		IF EXISTS(SELECT 1 FROM sedes.Sede WHERE IdHuso = @idHuso)
			SET @errores += '- Existen 1 o mas registros relacionados: Sede. Elimine dichos registros para continuar.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		DELETE FROM sedes.HusoHorario
		WHERE IdHuso = @idHuso
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

GO
-- 49_Sp_Sede.sql
-- Universidad Nacional de La Matanza
-- Bases de datos aplicada 
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 26/10/26
-- Objetivo: SP Sede.

-- Ejecutar en la base seleccionada por el instalador.
GO

if exists (select name from sys.objects where object_id = object_id('SP.uspSede_Registrar'))
    drop procedure SP.uspSede_Registrar
go
create procedure SP.uspSede_Registrar
    @nombre    varchar(30),
    @ciudad    varchar(30),
    @capacidad int,
    @pais      int,
    @huso      int
as
begin
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		-- chequeo validez
		IF (@nombre IS NULL) OR (LTRIM(RTRIM(@nombre)) = '')
			SET @errores += '- Valor invalido: Nombre.' + N' ';

		IF (@ciudad IS NULL) OR (LTRIM(RTRIM(@ciudad)) = '')
			SET @errores += '- Valor invalido: Ciudad.' + N' ';

		IF (@capacidad IS NULL) OR (@capacidad <= 0)
			SET @errores += '- Valor invalido: Capacidad.' + N' ';

		IF (@pais IS NULL) OR (@pais <= 0)
			SET @errores += '- Valor invalido: Pais.' + N' ';

		IF (@huso IS NULL) OR (@huso <= 0)
			SET @errores += '- Valor invalido: Huso horario.' + N' ';

		-- chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @pais)
			SET @errores += '- Valor inexistente: Pais.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM sedes.HusoHorario WHERE IdHuso = @huso)
			SET @errores += '- Valor inexistente: Huso horario.' + N' ';

		-- chequeo dup
		IF EXISTS(SELECT 1 FROM sedes.Sede WHERE Nombre = @nombre AND Ciudad = @ciudad)
			SET @errores += '- Valor duplicado: Sede (nombre y ciudad).' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		INSERT INTO sedes.Sede (Nombre, Ciudad, Capacidad, IdPais, IdHuso)
		VALUES (@nombre, @ciudad, @capacidad, @pais, @huso)
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
end;
go


-- modificacion de sede
if exists (select name from sys.objects where object_id = object_id('SP.uspSede_Update'))
    drop procedure SP.uspSede_Update
go
create procedure SP.uspSede_Update
    @idSede    int,
    @nombre    varchar(30) = null,
    @ciudad    varchar(30) = null,
    @capacidad int = null,
    @pais      int = null,
    @huso      int = null
as
begin
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		-- chequeo validez (solo lo que vino con valor)
		IF (@idSede IS NULL) OR (@idSede <= 0)
			SET @errores += '- Valor invalido: IdSede.' + N' ';

		IF (@capacidad IS NOT NULL) AND (@capacidad <= 0)
			SET @errores += '- Valor invalido: Capacidad.' + N' ';

		IF (@pais IS NOT NULL) AND (@pais <= 0)
			SET @errores += '- Valor invalido: Pais.' + N' ';

		IF (@huso IS NOT NULL) AND (@huso <= 0)
			SET @errores += '- Valor invalido: Huso horario.' + N' ';

		-- chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM sedes.Sede WHERE IdSede = @idSede)
			SET @errores += '- Valor inexistente: IdSede.' + N' ';

		IF (@pais IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @pais)
			SET @errores += '- Valor inexistente: Pais.' + N' ';

		IF (@huso IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM sedes.HusoHorario WHERE IdHuso = @huso)
			SET @errores += '- Valor inexistente: Huso horario.' + N' ';

		-- chequeo dup (solo si me pasaron nombre y ciudad juntos)
		IF (@nombre IS NOT NULL) AND (@ciudad IS NOT NULL)
		BEGIN
			IF EXISTS(SELECT 1 FROM sedes.Sede
				WHERE Nombre = @nombre AND Ciudad = @ciudad AND IdSede <> @idSede)
				SET @errores += '- Valor duplicado: Sede (nombre y ciudad).' + N' ';
		END

		IF @capacidad IS NOT NULL AND EXISTS (
			SELECT 1 FROM partidos.Partido WHERE IdSede=@idSede AND Asistencia>@capacidad)
			SET @errores += N'- La capacidad no puede ser menor a la asistencia registrada en los partidos de la sede. ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		UPDATE sedes.Sede
		SET Nombre    = COALESCE(@nombre, Nombre),
			Ciudad    = COALESCE(@ciudad, Ciudad),
			Capacidad = COALESCE(@capacidad, Capacidad),
			IdPais    = COALESCE(@pais, IdPais),
			IdHuso    = COALESCE(@huso, IdHuso)
		WHERE IdSede = @idSede
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
end;
go


-- baja de sede
if exists (select name from sys.objects where object_id = object_id('SP.uspSede_Bajar'))
    drop procedure SP.uspSede_Bajar
go
create procedure SP.uspSede_Bajar
    @idSede int
as
begin
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		-- chequeo validez
		IF (@idSede IS NULL) OR (@idSede <= 0)
			SET @errores += '- Valor invalido: IdSede.' + N' ';

		-- chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM sedes.Sede WHERE IdSede = @idSede)
			SET @errores += '- Valor inexistente: IdSede.' + N' ';

		-- chequeo relaciones (si hay registros hijos, no se puede dar de baja)
		IF EXISTS(SELECT 1 FROM partidos.Partido WHERE IdSede = @idSede)
			SET @errores += '- Existen 1 o mas registros relacionados: Partido. Elimine dichos registros para continuar.' + N' ';

		IF EXISTS(SELECT 1 FROM publicidad.EspacioPublicitario WHERE IdSede = @idSede)
			SET @errores += '- Existen 1 o mas registros relacionados: EspacioPublicitario. Elimine dichos registros para continuar.' + N' ';

		IF EXISTS(SELECT 1 FROM publicidad.CostoFranja WHERE IdSede = @idSede)
			SET @errores += '- Existen 1 o mas registros relacionados: CostoFranja. Elimine dichos registros para continuar.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		DELETE FROM sedes.Sede
		WHERE IdSede = @idSede
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
end;
go

GO
-- 50_Sp_Seleccion.sql
--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Creacion de Stored Procedures

-- Ejecutar en la base seleccionada por el instalador.
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspSeleccion_Registrar'))
    DROP PROCEDURE SP.uspSeleccion_Registrar
GO
CREATE PROCEDURE SP.uspSeleccion_Registrar
@idPais INT,
@idMundial INT,
@idGrupo INT,
@confederacion VARCHAR(45)
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		--Chequeo validez
		IF(@idPais IS NULL) OR (@idPais <= 0)
			SET @errores += '- Valor invalido: Pais.' + N' ';

		IF(@idMundial IS NULL) OR (@idMundial <= 0)
			SET @errores += '- Valor invalido: Mundial.' + N' ';

		IF(@idGrupo IS NULL) OR (@idGrupo <= 0)
			SET @errores += '- Valor invalido: Grupo.' + N' ';

		IF(@confederacion IS NULL) OR (LTRIM(RTRIM(@confederacion)) = '')
			SET @errores += '- Valor invalido: Confederacion.' + N' ';

		--Chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @idPais)
			SET @errores += '- Valor inexistente: Pais.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM sedes.Mundial WHERE IdMundial = @idMundial)
			SET @errores += '- Valor inexistente: Mundial.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM equipos.Grupo WHERE IdGrupo = @idGrupo)
			SET @errores += '- Valor inexistente: Grupo.' + N' ';

		--Chequeo dup
		IF EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdPais = @idPais AND IdMundial = @idMundial)
			SET @errores += '- Valor duplicado: Seleccion (pais y mundial).' + N' ';

		--Chequeo cupo (maximo 4 selecciones por grupo en cada mundial)
		IF (SELECT COUNT(*) FROM equipos.Seleccion WHERE IdMundial = @idMundial AND IdGrupo = @idGrupo) >= 4
			SET @errores += '- Cupo excedido: el grupo ya tiene 4 selecciones en el mundial.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		INSERT INTO equipos.Seleccion(IdPais, IdMundial, IdGrupo, CONFEDERACION)
		VALUES(@idPais, @idMundial, @idGrupo, LTRIM(RTRIM(@confederacion)))
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspSeleccion_Update'))
    DROP PROCEDURE SP.uspSeleccion_Update
GO
CREATE PROCEDURE SP.uspSeleccion_Update
@idSeleccion INT,
@idPais INT = NULL,
@idMundial INT = NULL,
@idGrupo INT = NULL,
@confederacion VARCHAR(45) = NULL
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	DECLARE @vMundial INT

	BEGIN TRY
		--Chequeo validez
		IF(@idSeleccion IS NULL) OR (@idSeleccion <= 0)
			SET @errores += '- Valor invalido: ID Seleccion.' + N' ';

		IF(@idPais IS NOT NULL) AND (@idPais <= 0)
			SET @errores += '- Valor invalido: Pais.' + N' ';

		IF(@idMundial IS NOT NULL) AND (@idMundial <= 0)
			SET @errores += '- Valor invalido: Mundial.' + N' ';

		IF(@idGrupo IS NOT NULL) AND (@idGrupo <= 0)
			SET @errores += '- Valor invalido: Grupo.' + N' ';

		IF(@confederacion IS NOT NULL) AND (LTRIM(RTRIM(@confederacion)) = '')
			SET @errores += '- Valor invalido: Confederacion.' + N' ';

		--Chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @idSeleccion)
			SET @errores += '- Valor inexistente: ID Seleccion.' + N' ';

		IF(@idPais IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @idPais)
			SET @errores += '- Valor inexistente: Pais.' + N' ';

		IF(@idMundial IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM sedes.Mundial WHERE IdMundial = @idMundial)
			SET @errores += '- Valor inexistente: Mundial.' + N' ';

		IF(@idGrupo IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM equipos.Grupo WHERE IdGrupo = @idGrupo)
			SET @errores += '- Valor inexistente: Grupo.' + N' ';

		--Chequeo dup
		IF(@idPais IS NOT NULL) AND (@idMundial IS NOT NULL)
		   AND EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdPais = @idPais AND IdMundial = @idMundial AND IdSeleccion <> @idSeleccion)
			SET @errores += '- Valor duplicado: Seleccion (pais y mundial).' + N' ';

		--Chequeo cupo (maximo 4 selecciones por grupo en cada mundial, sin contar la propia)
		IF(@idGrupo IS NOT NULL)
		BEGIN
			SET @vMundial = COALESCE(@idMundial, (SELECT IdMundial FROM equipos.Seleccion WHERE IdSeleccion = @idSeleccion))

			IF (SELECT COUNT(*) FROM equipos.Seleccion WHERE IdMundial = @vMundial AND IdGrupo = @idGrupo AND IdSeleccion <> @idSeleccion) >= 4
				SET @errores += '- Cupo excedido: el grupo ya tiene 4 selecciones en el mundial.' + N' ';
		END

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		UPDATE equipos.Seleccion
		SET IdPais = COALESCE(@idPais, IdPais),
			IdMundial = COALESCE(@idMundial, IdMundial),
			IdGrupo = COALESCE(@idGrupo, IdGrupo),
			CONFEDERACION = COALESCE(LTRIM(RTRIM(@confederacion)), CONFEDERACION)
		WHERE IdSeleccion = @idSeleccion
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspSeleccion_Bajar'))
    DROP PROCEDURE SP.uspSeleccion_Bajar
GO
CREATE PROCEDURE SP.uspSeleccion_Bajar
@idSeleccion INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		--Chequeo validez
		IF(@idSeleccion IS NULL) OR (@idSeleccion <= 0)
			SET @errores += '- Valor invalido: ID Seleccion.' + N' ';

		--Chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @idSeleccion)
			SET @errores += '- Valor inexistente: ID Seleccion.' + N' ';

		--Chequeo relaciones
		IF EXISTS(SELECT 1 FROM equipos.Jugador WHERE Seleccion = @idSeleccion)
			SET @errores += '- Existen 1 o mas registros relacionados: Jugador. Elimine dichos registros para continuar.' + N' ';

		IF EXISTS(SELECT 1 FROM equipos.Tecnico WHERE Seleccion = @idSeleccion)
			SET @errores += '- Existen 1 o mas registros relacionados: Tecnico. Elimine dichos registros para continuar.' + N' ';

		IF EXISTS(SELECT 1 FROM partidos.Partido WHERE Eq1 = @idSeleccion OR Eq2 = @idSeleccion)
			SET @errores += '- Existen 1 o mas registros relacionados: Partido. Elimine dichos registros para continuar.' + N' ';

		IF EXISTS(SELECT 1 FROM partidos.Alineacion A
				INNER JOIN equipos.Jugador J ON J.IdJugador = A.IdJugador
				WHERE J.Seleccion = @idSeleccion)
			SET @errores += '- Existen 1 o mas registros relacionados: Alineacion. Elimine dichos registros para continuar.' + N' ';

		IF EXISTS(SELECT 1 FROM equipos.CambioConvocatoria WHERE Seleccion = @idSeleccion)
			SET @errores += '- Existen 1 o mas registros relacionados: CambioConvocatoria. Elimine dichos registros para continuar.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		DELETE FROM equipos.Seleccion WHERE IdSeleccion = @idSeleccion
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

GO
-- 51_Sp_Anunciante.sql
--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Creacion de Stored Procedures

-- Ejecutar en la base seleccionada por el instalador.
GO

--Anunciante
IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspAnunciante_Registrar'))
    DROP PROCEDURE SP.uspAnunciante_Registrar
GO
CREATE PROCEDURE SP.uspAnunciante_Registrar @nombre VARCHAR(50), @idPais INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF(@nombre IS NULL)
			SET @errores += '- Valor invalido: Nombre.' + N' ';

		IF(@idPais IS NULL) OR (@idPais <= 0)
			SET @errores += '- Valor invalido: ID Pais.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @idPais)
			SET @errores += '- Valor inexistente: ID Pais.' + N' ';

		IF EXISTS(SELECT 1 FROM publicidad.Anunciante WHERE Nombre = @nombre)
			SET @errores += '- Valor duplicado: Nombre.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		INSERT INTO publicidad.Anunciante(Nombre, IdPais) VALUES (@nombre, @idPais)
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspAnunciante_Update'))
    DROP PROCEDURE SP.uspAnunciante_Update
GO
CREATE PROCEDURE SP.uspAnunciante_Update @id INT, @nombre VARCHAR(50), @idPais INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF(@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Anunciante.' + N' ';

		IF(@nombre IS NULL)
			SET @errores += '- Valor invalido: Nombre.' + N' ';

		IF(@idPais IS NULL) OR (@idPais <= 0)
			SET @errores += '- Valor invalido: ID Pais.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM publicidad.Anunciante WHERE IdAnunciante = @id)
			SET @errores += '- Valor inexistente: ID Anunciante.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @idPais)
			SET @errores += '- Valor inexistente: ID Pais.' + N' ';

		IF EXISTS(SELECT 1 FROM publicidad.Anunciante WHERE Nombre = @nombre AND IdAnunciante <> @id)
			SET @errores += '- Valor duplicado: Nombre.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		UPDATE publicidad.Anunciante
		SET Nombre = @nombre, IdPais = @idPais
		WHERE IdAnunciante = @id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspAnunciante_Bajar'))
    DROP PROCEDURE SP.uspAnunciante_Bajar
GO
CREATE PROCEDURE SP.uspAnunciante_Bajar @id INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF(@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Anunciante.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM publicidad.Anunciante WHERE IdAnunciante = @id)
			SET @errores += '- Valor inexistente: ID Anunciante.' + N' ';

		IF EXISTS(SELECT 1 FROM publicidad.AnuncianteCampania WHERE IdAnunciante = @id)
			SET @errores += '- Existen 1 o mas registros relacionados: AnuncianteCampania. Elimine dichos registros para continuar.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		DELETE FROM publicidad.Anunciante WHERE IdAnunciante = @id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

GO
-- 52_Sp_Publicidad.sql
--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Creacion de Stored Procedures

-- Ejecutar en la base seleccionada por el instalador.
GO

--Publicidad
IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspPublicidad_Registrar'))
    DROP PROCEDURE SP.uspPublicidad_Registrar
GO
CREATE PROCEDURE SP.uspPublicidad_Registrar @nombre VARCHAR(50), @idCampania INT, @idIdioma INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF(@nombre IS NULL)
			SET @errores += '- Valor invalido: Nombre.' + N' ';

		IF(@idCampania IS NULL) OR (@idCampania <= 0)
			SET @errores += '- Valor invalido: ID Campania.' + N' ';

		IF(@idIdioma IS NULL) OR (@idIdioma <= 0)
			SET @errores += '- Valor invalido: ID Idioma.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM publicidad.Campania WHERE IdCampania = @idCampania)
			SET @errores += '- Valor inexistente: ID Campania.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM arbitros.Idioma WHERE IdIdioma = @idIdioma)
			SET @errores += '- Valor inexistente: ID Idioma.' + N' ';

		IF EXISTS(SELECT 1 FROM publicidad.Publicidad WHERE Nombre = @nombre)
			SET @errores += '- Valor duplicado: Nombre.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		INSERT INTO publicidad.Publicidad(Nombre, IdCampania, IdIdioma) VALUES (@nombre, @idCampania, @idIdioma)
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspPublicidad_Update'))
    DROP PROCEDURE SP.uspPublicidad_Update
GO
CREATE PROCEDURE SP.uspPublicidad_Update @id INT, @nombre VARCHAR(50), @idCampania INT, @idIdioma INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF(@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Publicidad.' + N' ';

		IF(@nombre IS NULL)
			SET @errores += '- Valor invalido: Nombre.' + N' ';

		IF(@idCampania IS NULL) OR (@idCampania <= 0)
			SET @errores += '- Valor invalido: ID Campania.' + N' ';

		IF(@idIdioma IS NULL) OR (@idIdioma <= 0)
			SET @errores += '- Valor invalido: ID Idioma.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM publicidad.Publicidad WHERE IdPublicidad = @id)
			SET @errores += '- Valor inexistente: ID Publicidad.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM publicidad.Campania WHERE IdCampania = @idCampania)
			SET @errores += '- Valor inexistente: ID Campania.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM arbitros.Idioma WHERE IdIdioma = @idIdioma)
			SET @errores += '- Valor inexistente: ID Idioma.' + N' ';

		IF EXISTS(SELECT 1 FROM publicidad.Publicidad WHERE Nombre = @nombre AND IdPublicidad <> @id)
			SET @errores += '- Valor duplicado: Nombre.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		UPDATE publicidad.Publicidad
		SET Nombre = @nombre, IdCampania = @idCampania, IdIdioma = @idIdioma
		WHERE IdPublicidad = @id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspPublicidad_Bajar'))
    DROP PROCEDURE SP.uspPublicidad_Bajar
GO
CREATE PROCEDURE SP.uspPublicidad_Bajar @id INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF(@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Publicidad.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM publicidad.Publicidad WHERE IdPublicidad = @id)
			SET @errores += '- Valor inexistente: ID Publicidad.' + N' ';

		IF EXISTS(SELECT 1 FROM publicidad.HistorialPublicidad WHERE IdPublicidad = @id)
			SET @errores += '- Existen 1 o mas registros relacionados: HistorialPublicidad. Elimine dichos registros para continuar.' + N' ';

		IF EXISTS(SELECT 1 FROM publicidad.PublicidadPais WHERE IdPublicidad = @id)
			SET @errores += '- Existen 1 o mas registros relacionados: PublicidadPais. Elimine dichos registros para continuar.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		DELETE FROM publicidad.Publicidad WHERE IdPublicidad = @id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

GO
-- 53_Sp_HablaIdioma.sql
--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Creacion de Stored Procedures

-- Ejecutar en la base seleccionada por el instalador.
GO

--HablaIdioma
IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspHablaIdioma_Registrar'))
    DROP PROCEDURE SP.uspHablaIdioma_Registrar
GO
CREATE PROCEDURE SP.uspHablaIdioma_Registrar @arbitro INT, @idioma INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF(@arbitro IS NULL) OR (@arbitro <= 0)
			SET @errores += '- Valor invalido: Arbitro.' + N' ';

		IF(@idioma IS NULL) OR (@idioma <= 0)
			SET @errores += '- Valor invalido: Idioma.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM arbitros.Arbitro WHERE IdArbitro = @arbitro)
			SET @errores += '- Valor inexistente: Arbitro.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM arbitros.Idioma WHERE IdIdioma = @idioma)
			SET @errores += '- Valor inexistente: Idioma.' + N' ';

		IF EXISTS(SELECT 1 FROM arbitros.HablaIdioma WHERE Arbitro = @arbitro AND Idioma = @idioma)
			SET @errores += '- Valor duplicado: Idioma.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		INSERT INTO arbitros.HablaIdioma VALUES (@arbitro, @idioma)
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspHablaIdioma_Bajar'))
    DROP PROCEDURE SP.uspHablaIdioma_Bajar
GO
CREATE PROCEDURE SP.uspHablaIdioma_Bajar @arbitro INT, @idioma INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF(@arbitro IS NULL) OR (@arbitro <= 0)
			SET @errores += '- Valor invalido: Arbitro.' + N' ';

		IF(@idioma IS NULL) OR (@idioma <= 0)
			SET @errores += '- Valor invalido: Idioma.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM arbitros.Arbitro WHERE IdArbitro = @arbitro)
			SET @errores += '- Valor inexistente: Arbitro.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM arbitros.Idioma WHERE IdIdioma = @idioma)
			SET @errores += '- Valor inexistente: Idioma.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM arbitros.HablaIdioma WHERE Arbitro = @arbitro AND Idioma = @idioma)
			SET @errores += '- Registro inexistente.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		DELETE FROM arbitros.HablaIdioma WHERE Arbitro = @arbitro AND Idioma = @idioma
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

GO
-- 54_Sp_Reporte.sql
--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Creacion de Stored Procedures

-- Ejecutar en la base seleccionada por el instalador.
GO

--Reporte
IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspReporte_Registrar'))
    DROP PROCEDURE SP.uspReporte_Registrar
GO
CREATE PROCEDURE SP.uspReporte_Registrar 
@razon VARCHAR(20), @descripcion VARCHAR(300),
@arbitro INT, @partido INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF(@razon IS NULL) OR (@razon NOT IN ('Sancion', 'Informe PostPartido'))
			SET @errores += '- Valor invalido: Razon.' + N' ';

		IF(@descripcion IS NULL)
			SET @errores += '- Valor invalido: Descripcion.' + N' ';

		IF(@arbitro IS NULL) OR (@arbitro <= 0)
			SET @errores += '- Valor invalido: Arbitro.' + N' ';

		IF(@partido IS NULL) OR (@partido <= 0)
			SET @errores += '- Valor invalido: Partido.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM arbitros.Arbitro WHERE IdArbitro = @arbitro)
			SET @errores += '- Valor inexistente: Arbitro.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM partidos.Partido WHERE IdPartido = @partido)
			SET @errores += '- Valor inexistente: Partido.' + N' ';

		IF EXISTS(SELECT 1 FROM arbitros.Reporte WHERE Arbitro = @arbitro AND Partido = @partido AND Descripcion = @descripcion)
			SET @errores += '- Valor duplicado: Descripcion.' + N' ';

		--chequeo de participacion del arbitro en dicho partido
		IF NOT EXISTS(SELECT 1 FROM arbitros.Arbitraje WHERE Arbitro = @arbitro AND Partido = @partido)
			SET @errores += '- El arbitro no participo de ese partido.' + N' ';

		--chequeo estado del partido (si ya se jugo o no)
		--Un partido se considera disputado cuando su Fecha + HoraUTC ya paso.
		IF EXISTS(SELECT 1 FROM partidos.Partido WHERE IdPartido = @partido AND CAST(Fecha AS DATETIME) + CAST(HoraUTC AS DATETIME) >= GETDATE())
			SET @errores += '- El partido aun no se ha jugado.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		INSERT INTO arbitros.Reporte(Razon, Descripcion, Arbitro, Partido) VALUES (@razon, @descripcion, @arbitro, @partido)
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspReporte_Update'))
    DROP PROCEDURE SP.uspReporte_Update
GO
CREATE PROCEDURE SP.uspReporte_Update
@id INT,
@razon VARCHAR(20) = NULL, @descripcion VARCHAR(300) = NULL
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF(@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Reporte.' + N' ';

		IF(@razon IS NOT NULL) AND (@razon NOT IN ('Sancion', 'Informe PostPartido'))
			SET @errores += '- Valor invalido: Razon.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM arbitros.Reporte WHERE IdReporte = @id)
			SET @errores += '- Valor inexistente: ID Reporte.' + N' ';

		--chequeo dup (descripcion repetida por el mismo arbitro sobre el mismo partido, excluyendo el propio registro)
		IF(@descripcion IS NOT NULL)
		AND EXISTS
		(
			SELECT 1
			FROM 
			arbitros.Reporte AS R
			INNER JOIN
			(SELECT Arbitro, Partido FROM arbitros.Reporte WHERE IdReporte = @id) AS AP
			ON R.Arbitro = AP.Arbitro AND R.Partido = AP.Partido
			WHERE R.Descripcion = @descripcion AND R.IdReporte <> @id
		)
			SET @errores += '- Valor duplicado: Descripcion.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		UPDATE arbitros.Reporte
		SET
		Razon = COALESCE(@razon, Razon),
		Descripcion = COALESCE(@descripcion, Descripcion)
		WHERE IdReporte = @id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspReporte_Baja'))
    DROP PROCEDURE SP.uspReporte_Baja
GO
CREATE PROCEDURE SP.uspReporte_Baja
@id INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF(@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Reporte.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM arbitros.Reporte WHERE IdReporte = @id)
			SET @errores += '- Valor inexistente: ID Reporte.' + N' ';

		--No existen tablas que dependan de Reporte, no se requieren validaciones de relacion.

		IF LEN(@errores)>0 THROW 50000, @errores, 1;
		DELETE FROM arbitros.Reporte WHERE IdReporte = @id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

GO
-- 55_Sp_Partido.sql
-- Universidad Nacional de La Matanza
-- Bases de datos aplicada
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 26/10/26
-- Objetivo: Gestionar Tabla Partido

-- Fecha del partido se interpreta en UTC. El sufijo del huso puede ser una etiqueta.
CREATE OR ALTER FUNCTION sedes.fnFechaHoraLocal(@fecha DATE, @hora TIME, @huso VARCHAR(50))
RETURNS DATETIMEOFFSET
AS
BEGIN
	DECLARE @utc DATETIME2 = DATEADD(DAY, DATEDIFF(DAY, '19000101', @fecha), CAST(@hora AS DATETIME2));
	DECLARE @nombre VARCHAR(50) = LTRIM(RTRIM(@huso));
	IF @utc IS NULL OR @nombre IS NULL RETURN NULL;
	IF EXISTS (SELECT 1 FROM sys.time_zone_info WHERE name = @nombre)
		RETURN (@utc AT TIME ZONE 'UTC') AT TIME ZONE @nombre;

	DECLARE @windows VARCHAR(50) = CASE @nombre
		WHEN 'America/New_York' THEN 'Eastern Standard Time'
		WHEN 'America/Toronto' THEN 'Eastern Standard Time'
		WHEN 'America/Chicago' THEN 'Central Standard Time'
		WHEN 'America/Los_Angeles' THEN 'Pacific Standard Time'
		WHEN 'America/Mexico_City' THEN 'Central Standard Time (Mexico)'
		WHEN 'America/Monterrey' THEN 'Central Standard Time (Mexico)'
		WHEN 'America/Vancouver' THEN 'Pacific Standard Time' END;
	IF @nombre = 'America/Vancouver' AND @fecha >= '20261101'
		SET @windows = CASE WHEN EXISTS (SELECT 1 FROM sys.time_zone_info
		    WHERE name = 'British Columbia Standard Time')
		    THEN 'British Columbia Standard Time' ELSE 'Yukon Standard Time' END;
	IF EXISTS (SELECT 1 FROM sys.time_zone_info WHERE name = @windows)
		RETURN (@utc AT TIME ZONE 'UTC') AT TIME ZONE @windows;

	-- Desplazamientos fijos: UTC-3, UTC+05:30, UTC-3.
	SET @nombre = LEFT(@nombre, CHARINDEX(' ', @nombre + ' ') - 1);
	IF @nombre = 'UTC' RETURN TODATETIMEOFFSET(@utc, 0);
	IF LEFT(@nombre, 3) <> 'UTC' OR SUBSTRING(@nombre, 4, 1) NOT IN ('+', '-') RETURN NULL;
	DECLARE @valor VARCHAR(50) = SUBSTRING(@nombre, 5, 46);
	DECLARE @separador INT = CHARINDEX(':', @valor), @horas INT, @minutos INT = 0;
	IF @separador = 0
	BEGIN
		IF @valor = '' OR @valor LIKE '%[^0-9]%' RETURN NULL;
		SET @horas = TRY_CONVERT(INT, @valor);
	END
	ELSE
	BEGIN
		IF @separador = 1 OR LEN(@valor) - @separador <> 2 RETURN NULL;
		IF LEFT(@valor, @separador - 1) LIKE '%[^0-9]%' OR SUBSTRING(@valor, @separador + 1, 2) LIKE '%[^0-9]%' RETURN NULL;
		SET @horas = TRY_CONVERT(INT, LEFT(@valor, @separador - 1));
		SET @minutos = TRY_CONVERT(INT, SUBSTRING(@valor, @separador + 1, 2));
	END
	IF @horas IS NULL OR @horas > 14 OR @minutos > 59 OR (@horas = 14 AND @minutos <> 0) RETURN NULL;
	DECLARE @offset INT = (@horas * 60 + @minutos) * CASE WHEN SUBSTRING(@nombre, 4, 1) = '-' THEN -1 ELSE 1 END;
	RETURN SWITCHOFFSET(TODATETIMEOFFSET(@utc, 0), @offset);
END;
GO

CREATE OR ALTER VIEW partidos.vHorarioPartido
AS
	SELECT P.IdPartido, P.Fecha AS FechaUTC, P.HoraUTC,
		CAST(sedes.fnFechaHoraLocal(P.Fecha, P.HoraUTC, H.Nombre) AS DATE) AS FechaLocal,
		CAST(sedes.fnFechaHoraLocal(P.Fecha, P.HoraUTC, H.Nombre) AS TIME) AS HoraLocal
	FROM partidos.Partido P
	JOIN sedes.Sede S ON S.IdSede = P.IdSede
	JOIN sedes.HusoHorario H ON H.IdHuso = S.IdHuso;
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID ('SP.uspPartido_Registrar'))
	DROP PROCEDURE SP.uspPartido_Registrar
GO

CREATE PROCEDURE SP.uspPartido_Registrar
@IdFase INT, @IdSede INT, @IdMundial INT, @Eq1 INT, @Eq2 INT,
@Fecha DATE, @HoraUTC TIME, @HoraLocal TIME,
@Asistencia INT = NULL
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF (@IdFase IS NULL OR @IdFase <= 0)
			SET @errores += '- Valor invalido: Fase' + N' ';

		IF (@IdSede IS NULL OR @IdSede <= 0)
			SET @errores += '- Valor invalido: Sede' + N' ';

		IF (@IdMundial IS NULL OR @IdMundial <= 0)
			SET @errores += '- Valor invalido: Mundial' + N' ';

		IF (@Fecha IS NULL)
			SET @errores += '- Valor invalido: Fecha' + N' ';

		IF (@HoraUTC IS NULL OR @HoraLocal IS NULL)
			SET @errores += '- Valor invalido: Hora' + N' ';

		IF (@Eq1 IS NULL OR @Eq2 IS NULL)
			SET @errores += '- Deben registrarse ambos equipos' + N' ';

		IF (@Eq1 IS NOT NULL AND @Eq2 IS NOT NULL AND @Eq1 = @Eq2)
			SET @errores += '- Un equipo no puede ser su propio rival' + N' ';

		IF(@Asistencia IS NOT NULL AND @Asistencia<0)
			SET @errores += '- La asistencia no puede ser negativa' + N' ';

		IF NOT EXISTS(SELECT 1 FROM partidos.Fase WHERE IdFase = @IdFase)
			SET @errores += '- Valor inexistente: Fase' + N' ';

		IF NOT EXISTS(SELECT 1 FROM sedes.Sede WHERE IdSede = @IdSede)
			SET @errores += '- Valor inexistente: Sede' + N' ';

		IF @Asistencia > (SELECT Capacidad FROM sedes.Sede WHERE IdSede = @IdSede)
			SET @errores += '- La asistencia supera la capacidad de la sede' + N' ';

		IF NOT EXISTS(SELECT 1 FROM sedes.Mundial WHERE IdMundial = @IdMundial)
			SET @errores += '- Valor inexistente: Mundial' + N' ';

		IF NOT EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @Eq1)
			SET @errores += '- Valor inexistente: Eq1' + N' ';

		IF NOT EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @Eq2)
			SET @errores += '- Valor inexistente: Eq2' + N' ';

		IF NOT EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @Eq1 AND IdMundial = @IdMundial)
			SET @errores += '- Eq1 no pertenece al Mundial' + N' ';

		IF NOT EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @Eq2 AND IdMundial = @IdMundial)
			SET @errores += '- Eq2 no pertenece al Mundial' + N' ';

		IF EXISTS(SELECT 1 FROM partidos.Partido WHERE Eq1 = @Eq1 AND Eq2 = @Eq2 AND Fecha = @Fecha AND IdFase = @IdFase)
			SET @errores += '- Partido duplicado' + N' ';

		DECLARE @local DATETIMEOFFSET;
		SELECT @local = sedes.fnFechaHoraLocal(@Fecha, @HoraUTC, H.Nombre)
		FROM sedes.Sede S JOIN sedes.HusoHorario H ON H.IdHuso = S.IdHuso WHERE S.IdSede = @IdSede;
		IF @local IS NULL
			SET @errores += '- Huso horario no reconocido. Use UTC, UTC con desplazamiento o un nombre de sys.time_zone_info.' + N' ';
		IF @HoraLocal <> CAST(@local AS TIME)
			SET @errores += '- La hora local no coincide con la hora UTC y el huso de la sede.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		INSERT INTO partidos.Partido(IdFase, IdSede, IdMundial, Eq1, Eq2, Fecha, HoraUTC, HoraLocal, GolesEq1, GolesEq2, Asistencia)
		VALUES(@IdFase, @IdSede, @IdMundial, @Eq1, @Eq2, @Fecha, @HoraUTC, @HoraLocal, 0, 0, @Asistencia)
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO

----------------------------------------------------------------------------------------------------------------

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspPartido_Update'))
	DROP PROCEDURE SP.uspPartido_Update
GO

CREATE PROCEDURE SP.uspPartido_Update
@Id INT,
@IdFase INT = NULL,
@IdSede INT = NULL,
@IdMundial INT = NULL,
@Eq1 INT = NULL,
@Eq2 INT = NULL,
@Fecha DATE = NULL,
@HoraUTC TIME = NULL,
@HoraLocal TIME = NULL,
@GolesEq1 INT = NULL,
@GolesEq2 INT = NULL,
@Asistencia INT = NULL
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	DECLARE @vMundial INT
	DECLARE @vEq1 INT
	DECLARE @vEq2 INT

	BEGIN TRY
		IF (@Id IS NULL OR @Id <= 0)
			SET @errores += '- Valor invalido: Id' + N' ';

		IF (@IdFase IS NOT NULL AND @IdFase <= 0)
			SET @errores += '- Valor invalido: Fase' + N' ';

		IF (@IdSede IS NOT NULL AND @IdSede <= 0)
			SET @errores += '- Valor invalido: Sede' + N' ';

		IF (@IdMundial IS NOT NULL AND @IdMundial <= 0)
			SET @errores += '- Valor invalido: Mundial' + N' ';

		IF (@GolesEq1 IS NOT NULL AND @GolesEq1 < 0)
			SET @errores += '- Los goles no pueden ser negativos' + N' ';

		IF (@GolesEq2 IS NOT NULL AND @GolesEq2 < 0)
			SET @errores += '- Los goles no pueden ser negativos' + N' ';

		IF (@Asistencia IS NOT NULL AND @Asistencia < 0)
			SET @errores += '- La asistencia no puede ser negativa' + N' ';

		IF NOT EXISTS(SELECT 1 FROM partidos.Partido WHERE IdPartido = @Id)
			SET @errores += '- Valor inexistente: Partido' + N' ';

		IF (@IdFase IS NOT NULL AND NOT EXISTS(SELECT 1 FROM partidos.Fase WHERE IdFase = @IdFase))
			SET @errores += '- Valor inexistente: Fase' + N' ';

		IF (@IdMundial IS NOT NULL AND NOT EXISTS(SELECT 1 FROM sedes.Mundial WHERE IdMundial = @IdMundial))
			SET @errores += '- Valor inexistente: Mundial' + N' ';

		SELECT @vMundial = COALESCE(@IdMundial, IdMundial), @vEq1 = COALESCE(@Eq1, Eq1), @vEq2 = COALESCE(@Eq2, Eq2) FROM partidos.Partido WHERE IdPartido = @Id

		IF (@vEq1 = @vEq2)
			SET @errores += '- Un equipo no puede ser su propio rival' + N' ';
		ELSE IF NOT EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @vEq1 AND IdMundial = @vMundial)
			SET @errores += '- Eq1 no pertenece al Mundial' + N' ';
		ELSE IF NOT EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @vEq2 AND IdMundial = @vMundial)
			SET @errores += '- Eq2 no pertenece al Mundial' + N' ';

		DECLARE @vSede INT, @vAsistencia INT;
		SELECT @vSede = COALESCE(@IdSede, IdSede), @vAsistencia = COALESCE(@Asistencia, Asistencia)
		FROM partidos.Partido WHERE IdPartido = @Id;

		IF NOT EXISTS(SELECT 1 FROM sedes.Sede WHERE IdSede = @vSede)
			SET @errores += '- Valor inexistente: Sede' + N' ';

		IF @vAsistencia > (SELECT Capacidad FROM sedes.Sede WHERE IdSede = @vSede)
			SET @errores += '- La asistencia supera la capacidad de la sede' + N' ';

		IF EXISTS (SELECT 1 FROM partidos.Partido WHERE IdPartido = @Id
			AND (Eq1 <> @vEq1 OR Eq2 <> @vEq2 OR IdMundial <> @vMundial))
		BEGIN
			IF EXISTS (SELECT 1 FROM partidos.Alineacion WHERE IdPartido = @Id)
			OR EXISTS (SELECT 1 FROM partidos.Evento WHERE Partido = @Id)
			OR EXISTS (SELECT 1 FROM arbitros.Arbitraje WHERE Partido = @Id)
				SET @errores += '- No se pueden cambiar equipos o mundial con alineaciones, eventos o arbitrajes registrados' + N' ';
		END

		IF @GolesEq1 IS NOT NULL OR @GolesEq2 IS NOT NULL
			SET @errores += 'El marcador se modifica mediante alta y baja de goles, no manualmente.' + N' ';

		IF @Fecha IS NOT NULL OR @HoraUTC IS NOT NULL OR @HoraLocal IS NOT NULL OR @IdSede IS NOT NULL
		BEGIN
			DECLARE @local DATETIMEOFFSET;
			SELECT @local = sedes.fnFechaHoraLocal(COALESCE(@Fecha, P.Fecha), COALESCE(@HoraUTC, P.HoraUTC), H.Nombre)
			FROM partidos.Partido P JOIN sedes.Sede S ON S.IdSede = @vSede
			JOIN sedes.HusoHorario H ON H.IdHuso = S.IdHuso WHERE P.IdPartido = @Id;
			IF @local IS NULL
				SET @errores += '- Huso horario no reconocido. Use UTC, UTC con desplazamiento o un nombre de sys.time_zone_info.' + N' ';
			IF @HoraLocal IS NOT NULL AND @HoraLocal <> CAST(@local AS TIME)
				SET @errores += '- La hora local no coincide con la hora UTC y el huso de la sede.' + N' ';
			SET @HoraLocal = CAST(@local AS TIME);
		END

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		UPDATE partidos.Partido
		SET IdFase = COALESCE(@IdFase, IdFase),
			IdSede = COALESCE(@IdSede, IdSede),
			IdMundial = COALESCE(@IdMundial, IdMundial),
			Eq1 = COALESCE(@Eq1, Eq1),
			Eq2 = COALESCE(@Eq2, Eq2),
			Fecha = COALESCE(@Fecha, Fecha),
			HoraUTC = COALESCE(@HoraUTC, HoraUTC),
			HoraLocal = COALESCE(@HoraLocal, HoraLocal),
			GolesEq1 = COALESCE(@GolesEq1, GolesEq1),
			GolesEq2 = COALESCE(@GolesEq2, GolesEq2),
			Asistencia = COALESCE(@Asistencia, Asistencia)
		WHERE IdPartido = @Id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspPartido_Bajar'))
	DROP PROCEDURE SP.uspPartido_Bajar
GO

---------------------------------------------------------------------------------------------------------

CREATE PROCEDURE SP.uspPartido_Bajar
@Id INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF (@Id IS NULL OR @Id <= 0)
			SET @errores += '- Valor invalido: Id' + N' ';

		IF NOT EXISTS(SELECT 1 FROM partidos.Partido WHERE IdPartido = @Id)
			SET @errores += '- Valor inexistente: Partido' + N' ';

		IF EXISTS(SELECT 1 FROM partidos.Alineacion WHERE IdPartido = @Id)
			SET @errores += '- Existen alineaciones para este partido' + N' ';

		IF EXISTS(SELECT 1 FROM partidos.Evento WHERE Partido = @Id)
			SET @errores += '- Existen eventos para este partido' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		DELETE FROM partidos.Partido WHERE IdPartido = @Id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO

GO
-- 56_Sp_Alineacion.sql
-- Universidad Nacional de La Matanza
-- Bases de datos aplicada 
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 28/10/26
-- Objetivo: Registrar y Eliminar Alineacion

-- Ajuste: soporte de Descanso y orden por minuto/periodo.
-- Ejecutar en la base seleccionada por el instalador.
GO

-- Orden temporal: distingue 45 del primer tiempo, descanso y segundo tiempo.
-- Los nombres corresponden al catalogo de Periodo. No representa descuento.
CREATE OR ALTER FUNCTION partidos.fnMomentoEvento(@minuto INT, @periodo INT)
RETURNS BIGINT
AS
BEGIN
    DECLARE @orden INT = 0;
    IF @periodo IS NULL
        SET @orden = 9; -- Consulta antigua: incluye todo lo registrado en ese minuto.
    ELSE
        SELECT @orden = CASE
            WHEN EsPenales = 1 THEN 5
            WHEN Descripcion = 'Descanso' THEN 1
            WHEN Descripcion = '2do tiempo' THEN 2
            WHEN Descripcion = 'Alargue 1' THEN 3
            WHEN Descripcion = 'Alargue 2' THEN 4
            ELSE 0 END
        FROM partidos.Periodo WHERE IdPeriodo = @periodo;
    RETURN CONVERT(BIGINT, COALESCE(@minuto, 2147483647)) * 10 + @orden;
END;
GO

-- Consulta precisa: los eventos ya registrados en el mismo momento se aplican.
CREATE OR ALTER FUNCTION partidos.fnJugadorEnCanchaPeriodo
(@partido INT, @jugador INT, @minuto INT, @periodo INT)
RETURNS BIT
AS
BEGIN
    DECLARE @momento BIGINT = partidos.fnMomentoEvento(@minuto, @periodo);
    IF NOT EXISTS (SELECT 1 FROM partidos.Alineacion WHERE IdPartido=@partido AND IdJugador=@jugador)
        RETURN 0;
    IF NOT EXISTS (SELECT 1 FROM partidos.Alineacion WHERE IdPartido=@partido AND IdJugador=@jugador AND Rol='Titular')
       AND NOT EXISTS (SELECT 1 FROM partidos.Sustitucion S JOIN partidos.Evento E ON E.IdEvento=S.IdSustitucion
                       WHERE E.Partido=@partido AND S.Ingreso=@jugador
                         AND partidos.fnMomentoEvento(E.Minuto,E.Periodo)<=@momento)
        RETURN 0;
    IF EXISTS (SELECT 1 FROM partidos.Sustitucion S JOIN partidos.Evento E ON E.IdEvento=S.IdSustitucion
               WHERE E.Partido=@partido AND S.Egreso=@jugador
                 AND partidos.fnMomentoEvento(E.Minuto,E.Periodo)<=@momento)
        RETURN 0;
    IF EXISTS (SELECT 1 FROM partidos.Amonestacion A JOIN partidos.Evento E ON E.IdEvento=A.IdAmonestacion
               WHERE E.Partido=@partido AND A.Amonestado=@jugador AND A.Tarjeta='Roja'
                 AND partidos.fnMomentoEvento(E.Minuto,E.Periodo)<=@momento)
        RETURN 0;
    RETURN 1;
END;
GO

-- Conserva la firma y semantica de las consultas anteriores.
-- Para distinguir periodos en un minuto compartido usar la funcion de 4 parametros.
CREATE OR ALTER FUNCTION partidos.fnJugadorEnCancha(@partido INT, @jugador INT, @minuto INT)
RETURNS BIT
AS
BEGIN
    RETURN partidos.fnJugadorEnCanchaPeriodo(@partido, @jugador, @minuto, NULL);
END;
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID ('SP.uspAlineacion_Registrar'))
	DROP PROCEDURE SP.uspAlineacion_Registrar
GO

CREATE PROCEDURE SP.uspAlineacion_Registrar 
@IdPartido INT, @IdJugador INT,
@Rol VARCHAR (10), @PosicionCancha VARCHAR(20) = NULL, @Esquema VARCHAR (10) = NULL
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF (@IdPartido IS NULL OR @IdPartido <=0)
			SET @errores += '-Valor Invalido: IdPartido' + N' ';

		IF (@IdJugador IS NULL OR @IdJugador <=0)
			SET @errores += '-Valor Invalido: IdJugador' + N' ';

		IF (@Rol IS NULL)
			SET @errores += '-Valor Invalido: Rol nulo' + N' ';

		IF (@ROL NOT IN ('Suplente', 'Titular'))
			SET @errores += '-Valor Invalido: Rol' + N' ';

		IF NOT EXISTS(SELECT 1 FROM partidos.Partido WHERE IdPartido = @IdPartido)
			SET @errores += '- Valor inexistente: Partido' + N' ';

		IF NOT EXISTS(SELECT 1 FROM equipos.Jugador WHERE IdJugador = @IdJugador)
			SET @errores += '- Valor inexistente: Jugador' + N' ';

		IF NOT EXISTS(SELECT 1 FROM partidos.Partido P
				INNER JOIN equipos.Jugador J ON J.IdJugador = @IdJugador
				WHERE P.IdPartido = @IdPartido AND (P.Eq1 = J.Seleccion OR P.Eq2 = J.Seleccion))
			SET @errores += '- La seleccion del jugador no juega este partido' + N' ';

		IF EXISTS (SELECT 1 FROM partidos.Alineacion WHERE IdJugador = @IdJugador AND IdPartido = @IdPartido)
			SET @errores += '- Jugador ya cargado' + N' ';

		IF EXISTS (SELECT 1 FROM equipos.Jugador WHERE IdJugador=@IdJugador AND Estado<>'Activo')
			SET @errores += '- El jugador no esta habilitado para integrar la alineacion.' + N' ';

		IF @Rol='Titular' AND (SELECT COUNT(*) FROM partidos.Alineacion A
			JOIN equipos.Jugador J ON J.IdJugador=A.IdJugador
			WHERE A.IdPartido=@IdPartido AND A.Rol='Titular'
			AND J.Seleccion=(SELECT Seleccion FROM equipos.Jugador WHERE IdJugador=@IdJugador)) >= 11
			SET @errores += '- La seleccion ya tiene once titulares.' + N' ';

		IF @Esquema IS NOT NULL AND EXISTS (SELECT 1 FROM partidos.Alineacion A
			JOIN equipos.Jugador J ON J.IdJugador=A.IdJugador
			WHERE A.IdPartido=@IdPartido AND A.Esquema<>@Esquema
			AND J.Seleccion=(SELECT Seleccion FROM equipos.Jugador WHERE IdJugador=@IdJugador))
			SET @errores += '- El esquema debe coincidir con el de la seleccion en el partido.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		INSERT INTO partidos.Alineacion (IdPartido, IdJugador, Rol, PosicionCancha, Esquema) 
		VALUES (@IdPartido, @IdJugador, @Rol, @PosicionCancha, @Esquema) 
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO 

---------------------------------------------------------------------------------------------------------------

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID ('SP.uspAlineacion_Bajar'))
	DROP PROCEDURE SP.uspAlineacion_Bajar
GO

CREATE PROCEDURE SP.uspAlineacion_Bajar
@IdPartido INT, @IdJugador INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF (@IdPartido IS NULL OR @IdPartido <=0)
			SET @errores += '-Valor Invalido: IdPartido' + N' ';

		IF (@IdJugador IS NULL OR @IdJugador <=0)
			SET @errores += '-Valor Invalido: IdJugador' + N' ';

		IF NOT EXISTS (SELECT 1 FROM partidos.Alineacion WHERE IdJugador = @IdJugador AND IdPartido = @IdPartido)
			SET @errores += '-No existe alineacion a eliminar' + N' ';

		IF EXISTS(SELECT 1 FROM partidos.Evento WHERE Partido = @IdPartido)
			SET @errores += '-Tabla siendo utilizada en Evento, no se puede eliminar' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		DELETE FROM partidos.Alineacion WHERE IdJugador = @IdJugador AND IdPartido = @IdPartido
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO

GO
-- 57_Sp_PublicidadPais.sql
--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Objetivo: Gestionar Tabla PublicidadPais (solo Registrar y Bajar, PK inmutable)

-- Ejecutar en la base seleccionada por el instalador.
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspPublicidadPais_Registrar'))
    DROP PROCEDURE SP.uspPublicidadPais_Registrar
GO
CREATE PROCEDURE SP.uspPublicidadPais_Registrar
@idPublicidad INT,
@idPais INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF (@idPublicidad IS NULL) OR (@idPublicidad <= 0)
			SET @errores += '- Valor invalido: ID Publicidad.' + N' ';

		IF (@idPais IS NULL) OR (@idPais <= 0)
			SET @errores += '- Valor invalido: ID Pais.' + N' ';

		IF NOT EXISTS (SELECT 1 FROM publicidad.Publicidad WHERE IdPublicidad = @idPublicidad)
			SET @errores += '- Valor inexistente: ID Publicidad.' + N' ';

		IF NOT EXISTS (SELECT 1 FROM equipos.Pais WHERE IdPais = @idPais)
			SET @errores += '- Valor inexistente: ID Pais.' + N' ';

		IF EXISTS (SELECT 1 FROM publicidad.PublicidadPais WHERE IdPublicidad = @idPublicidad AND IdPais = @idPais)
			SET @errores += '- Valor duplicado: PublicidadPais.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		INSERT INTO publicidad.PublicidadPais (IdPublicidad, IdPais)
		VALUES (@idPublicidad, @idPais)
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspPublicidadPais_Bajar'))
    DROP PROCEDURE SP.uspPublicidadPais_Bajar
GO
CREATE PROCEDURE SP.uspPublicidadPais_Bajar
@idPublicidad INT,
@idPais INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF (@idPublicidad IS NULL) OR (@idPublicidad <= 0)
			SET @errores += '- Valor invalido: ID Publicidad.' + N' ';

		IF (@idPais IS NULL) OR (@idPais <= 0)
			SET @errores += '- Valor invalido: ID Pais.' + N' ';

		IF NOT EXISTS (SELECT 1 FROM publicidad.PublicidadPais WHERE IdPublicidad = @idPublicidad AND IdPais = @idPais)
			SET @errores += '- Valor inexistente: PublicidadPais.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		DELETE FROM publicidad.PublicidadPais WHERE IdPublicidad = @idPublicidad AND IdPais = @idPais
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO

GO
-- 58_Sp_AnuncianteCampania.sql
--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Objetivo: Gestionar Tabla AnuncianteCampania (solo Registrar y Bajar, PK inmutable)

-- Ejecutar en la base seleccionada por el instalador.
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspAnuncianteCampania_Registrar'))
    DROP PROCEDURE SP.uspAnuncianteCampania_Registrar
GO
CREATE PROCEDURE SP.uspAnuncianteCampania_Registrar
@idAnunciante INT,
@idCampania INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF (@idAnunciante IS NULL) OR (@idAnunciante <= 0)
			SET @errores += '- Valor invalido: ID Anunciante.' + N' ';

		IF (@idCampania IS NULL) OR (@idCampania <= 0)
			SET @errores += '- Valor invalido: ID Campania.' + N' ';

		IF NOT EXISTS (SELECT 1 FROM publicidad.Anunciante WHERE IdAnunciante = @idAnunciante)
			SET @errores += '- Valor inexistente: ID Anunciante.' + N' ';

		IF NOT EXISTS (SELECT 1 FROM publicidad.Campania WHERE IdCampania = @idCampania)
			SET @errores += '- Valor inexistente: ID Campania.' + N' ';

		IF EXISTS (SELECT 1 FROM publicidad.AnuncianteCampania WHERE IdAnunciante = @idAnunciante AND IdCampania = @idCampania)
			SET @errores += '- Valor duplicado: AnuncianteCampania.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		INSERT INTO publicidad.AnuncianteCampania (IdAnunciante, IdCampania)
		VALUES (@idAnunciante, @idCampania)
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspAnuncianteCampania_Bajar'))
    DROP PROCEDURE SP.uspAnuncianteCampania_Bajar
GO
CREATE PROCEDURE SP.uspAnuncianteCampania_Bajar
@idAnunciante INT,
@idCampania INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF (@idAnunciante IS NULL) OR (@idAnunciante <= 0)
			SET @errores += '- Valor invalido: ID Anunciante.' + N' ';

		IF (@idCampania IS NULL) OR (@idCampania <= 0)
			SET @errores += '- Valor invalido: ID Campania.' + N' ';

		IF NOT EXISTS (SELECT 1 FROM publicidad.AnuncianteCampania WHERE IdAnunciante = @idAnunciante AND IdCampania = @idCampania)
			SET @errores += '- Valor inexistente: AnuncianteCampania.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		DELETE FROM publicidad.AnuncianteCampania WHERE IdAnunciante = @idAnunciante AND IdCampania = @idCampania
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO

GO
-- 59_Sp_Jugador_ClubUpdate.sql
--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Creacion de Stored Procedures

-- Ejecutar en la base seleccionada por el instalador.
GO

--Jugador
IF EXISTS(SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SP.uspJugador_ClubUpdate'))
    DROP PROCEDURE SP.uspJugador_ClubUpdate
GO
CREATE PROCEDURE SP.uspJugador_ClubUpdate
@id INT,
@club INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF(@id IS NULL) OR (@id<= 0)
			SET @errores += '- Valor invalido: ID Jugador.' + N' ';

		IF(@club IS NOT NULL) AND (@club <= 0)
			SET @errores += '- Valor invalido: Club.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM equipos.Jugador WHERE IdJugador = @id)
			SET @errores += '- Valor inexistente: IdJugador.' + N' ';

		IF (@club IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM equipos.Club WHERE IdClub = @club)
			SET @errores += '- Valor inexistente: Club.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

		UPDATE equipos.Jugador
		SET Club = @club
		WHERE IdJugador = @id
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END;
GO

GO
-- 60_Sp_HistorialPublicidad.sql
-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Grupo 7
-- Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 26/10/26. Revision auxiliar de penales y publicidad por sede.
-- Objetivo: asignar piezas a espacios de la sede y conservar el costo pactado.
-- CostoFinal omitido: costo del espacio + costo de franja; explicito: importe pactado.


CREATE OR ALTER PROCEDURE SP.uspHistorialPublicidad_Registrar
    @idPublicidad INT,
    @idPartido    INT,
    @idEP         INT,
    @costoFinal   DECIMAL(10,2) = NULL,
    @idCF         INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @errores NVARCHAR(2048) = N'',
            @sede    INT,
            @costo   DECIMAL(10,2);

    IF NOT EXISTS (SELECT 1 FROM publicidad.Publicidad WHERE IdPublicidad = @idPublicidad)
        SET @errores += N'Publicidad inexistente. ';

    IF NOT EXISTS (SELECT 1 FROM partidos.Partido WHERE IdPartido = @idPartido)
        SET @errores += N'Partido inexistente. ';

    IF NOT EXISTS (SELECT 1 FROM publicidad.EspacioPublicitario WHERE IdEP = @idEP)
        SET @errores += N'Espacio inexistente. ';

    IF NOT EXISTS (SELECT 1 FROM publicidad.CostoFranja WHERE IdCF = @idCF)
        SET @errores += N'Tarifa de franja inexistente. ';

    IF @costoFinal < 0
        SET @errores += N'Costo final negativo. ';

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @sede = IdSede
        FROM partidos.Partido WITH (UPDLOCK, HOLDLOCK)
        WHERE IdPartido = @idPartido;

        SELECT @costo = COALESCE(@costoFinal, e.Costo + c.Costo)
        FROM publicidad.EspacioPublicitario e WITH (UPDLOCK, HOLDLOCK)
        JOIN publicidad.CostoFranja c WITH (UPDLOCK, HOLDLOCK) ON c.IdCF = @idCF
        WHERE e.IdEP = @idEP;

        IF NOT EXISTS (SELECT 1 FROM publicidad.EspacioPublicitario WHERE IdEP = @idEP AND IdSede = @sede)
            SET @errores += N'El espacio no pertenece a la sede del partido. ';

        IF NOT EXISTS (SELECT 1 FROM publicidad.CostoFranja WHERE IdCF = @idCF AND IdSede = @sede)
            SET @errores += N'La franja no pertenece a la sede del partido. ';

        IF EXISTS (SELECT 1 FROM publicidad.HistorialPublicidad WHERE IdPartido = @idPartido AND IdEP = @idEP)
            SET @errores += N'Espacio ya ocupado en el partido. ';

        IF (SELECT COUNT(*) FROM publicidad.HistorialPublicidad WHERE IdPartido = @idPartido) >= 4
            SET @errores += N'El partido ya tiene cuatro espacios asignados. ';

        IF LEN(@errores) > 0
            THROW 51000, @errores, 1;

        INSERT publicidad.HistorialPublicidad (IdPublicidad, IdPartido, IdEP, IdCF, CostoFinal)
        VALUES (@idPublicidad, @idPartido, @idEP, @idCF, @costo);

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE SP.uspHistorialPublicidad_Update
    @id           INT,
    @idPublicidad INT,
    @idPartido    INT,
    @idEP         INT,
    @costoFinal   DECIMAL(10,2),
    @idCF         INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @errores NVARCHAR(2048) = N'',
            @sede    INT;

    IF NOT EXISTS (SELECT 1 FROM publicidad.HistorialPublicidad WHERE IdHistorial = @id)
        SET @errores += N'Historial inexistente. ';

    IF NOT EXISTS (SELECT 1 FROM publicidad.Publicidad WHERE IdPublicidad = @idPublicidad)
        SET @errores += N'Publicidad inexistente. ';

    IF NOT EXISTS (SELECT 1 FROM partidos.Partido WHERE IdPartido = @idPartido)
        SET @errores += N'Partido inexistente. ';

    IF @costoFinal IS NULL OR @costoFinal < 0
        SET @errores += N'Indicar un costo final no negativo. ';

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @sede = IdSede
        FROM partidos.Partido WITH (UPDLOCK, HOLDLOCK)
        WHERE IdPartido = @idPartido;

        IF NOT EXISTS (SELECT 1 FROM publicidad.EspacioPublicitario WITH (UPDLOCK, HOLDLOCK) WHERE IdEP = @idEP AND IdSede = @sede)
            SET @errores += N'Espacio inexistente o de otra sede. ';

        IF NOT EXISTS (SELECT 1 FROM publicidad.CostoFranja WITH (UPDLOCK, HOLDLOCK) WHERE IdCF = @idCF AND IdSede = @sede)
            SET @errores += N'Franja inexistente o de otra sede. ';

        IF EXISTS (SELECT 1 FROM publicidad.HistorialPublicidad WHERE IdPartido = @idPartido AND IdEP = @idEP AND IdHistorial <> @id)
            SET @errores += N'Espacio ya ocupado. ';

        IF LEN(@errores) > 0
            THROW 51000, @errores, 1;

        UPDATE publicidad.HistorialPublicidad
        SET IdPublicidad = @idPublicidad,
            IdPartido    = @idPartido,
            IdEP         = @idEP,
            IdCF         = @idCF,
            CostoFinal   = @costoFinal
        WHERE IdHistorial = @id;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE SP.uspHistorialPublicidad_Bajar
    @id INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores NVARCHAR(2048) = N'';

    IF NOT EXISTS (SELECT 1 FROM publicidad.HistorialPublicidad WHERE IdHistorial = @id)
        SET @errores += 'Historial inexistente.' + N' ';

    IF LEN(@errores) > 0
        THROW 50000, @errores, 1;

    DELETE publicidad.HistorialPublicidad
    WHERE IdHistorial = @id;
END;
GO

-- Tipo de entrada para la asignacion atomica de exactamente cuatro espacios.
IF TYPE_ID('publicidad.AsignacionesPartido') IS NULL
    EXEC('CREATE TYPE publicidad.AsignacionesPartido AS TABLE (
        IdEP         INT NOT NULL PRIMARY KEY,
        IdPublicidad INT NOT NULL,
        IdCF         INT NOT NULL,
        CostoFinal   DECIMAL(10,2) NULL)');
GO

CREATE OR ALTER PROCEDURE SPTRANS.uspPublicidad_AsignarCuatro
    @idPartido    INT,
    @asignaciones publicidad.AsignacionesPartido READONLY
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @errores NVARCHAR(2048) = N'';

    IF (SELECT COUNT(*) FROM @asignaciones) <> 4
        SET @errores += 'Se requieren exactamente cuatro espacios distintos.' + N' ';

    IF NOT EXISTS (SELECT 1 FROM partidos.Partido WHERE IdPartido = @idPartido)
        SET @errores += 'Partido inexistente.' + N' ';

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @sede INT;

        SELECT @sede = IdSede
        FROM partidos.Partido WITH (UPDLOCK, HOLDLOCK)
        WHERE IdPartido = @idPartido;

        IF EXISTS (SELECT 1 FROM publicidad.HistorialPublicidad WHERE IdPartido = @idPartido)
            SET @errores += 'El partido ya tiene asignaciones; revisarlas antes de programar cuatro piezas.' + N' ';

        IF EXISTS (
            SELECT 1
            FROM @asignaciones a
            LEFT JOIN publicidad.EspacioPublicitario e WITH (UPDLOCK, HOLDLOCK) ON e.IdEP = a.IdEP
            WHERE e.IdEP IS NULL OR e.IdSede <> @sede
        )
            SET @errores += N'Espacios inexistentes o de otra sede. ';

        IF EXISTS (
            SELECT 1
            FROM @asignaciones a
            LEFT JOIN publicidad.CostoFranja c WITH (UPDLOCK, HOLDLOCK) ON c.IdCF = a.IdCF
            WHERE c.IdCF IS NULL OR c.IdSede <> @sede
        )
            SET @errores += N'Franjas inexistentes o de otra sede. ';

        IF EXISTS (
            SELECT 1
            FROM @asignaciones a
            LEFT JOIN publicidad.Publicidad p ON p.IdPublicidad = a.IdPublicidad
            WHERE p.IdPublicidad IS NULL
        )
            SET @errores += N'Publicidades inexistentes. ';

        IF EXISTS (SELECT 1 FROM @asignaciones WHERE CostoFinal < 0)
            SET @errores += N'Costos finales negativos. ';

        IF LEN(@errores) > 0
            THROW 51000, @errores, 1;

        INSERT publicidad.HistorialPublicidad (IdPartido, IdEP, IdPublicidad, IdCF, CostoFinal)
        SELECT @idPartido,
               a.IdEP,
               a.IdPublicidad,
               a.IdCF,
               COALESCE(a.CostoFinal, e.Costo + c.Costo)
        FROM @asignaciones a
        JOIN publicidad.EspacioPublicitario e ON e.IdEP = a.IdEP
        JOIN publicidad.CostoFranja c         ON c.IdCF = a.IdCF;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;
        THROW;
    END CATCH;
END;
GO


GO

CREATE OR ALTER PROCEDURE SP.uspPublicidad_PrimeTime
    @idPartido INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM partidos.Partido WHERE IdPartido = @idPartido)
        THROW 51000, 'Partido inexistente.', 1;

    -- Un pais con varios husos aparece una vez por huso.
    -- Desconocido no equivale a fuera de prime time.
    SELECT P.IdPais,
           P.NOMBRE,
           H.IdHuso,
           H.Nombre AS HusoHorario,
           L.FechaHoraLocal,
           CAST(
               CASE
                   WHEN L.FechaHoraLocal IS NULL THEN NULL
                   WHEN CAST(L.FechaHoraLocal AS TIME) >= '19:00'
                    AND CAST(L.FechaHoraLocal AS TIME) <  '23:00' THEN 1
                   ELSE 0
               END AS BIT
           ) AS EsPrimeTime
    FROM equipos.Pais P
    LEFT JOIN sedes.HusoHorario H ON H.IdHuso=P.HusoHorario
    CROSS JOIN partidos.Partido Partido
    CROSS APPLY (
        SELECT sedes.fnFechaHoraLocal(Partido.Fecha, Partido.HoraUTC, H.Nombre) AS FechaHoraLocal
    ) L
    WHERE Partido.IdPartido = @idPartido
    ORDER BY P.IdPais, H.IdHuso;
END;
GO

CREATE OR ALTER PROCEDURE SP.uspPublicidad_Proponer
    @idPartido INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM partidos.Partido WHERE IdPartido = @idPartido)
        THROW 51000, 'Partido inexistente.', 1;

    -- Prioridad: pais participante, PBI registrado, prime time [19:00,23:00).
    -- PBI se usa como indicador disponible, no se interpreta como PBI per capita.
    -- Se toma el mejor mercado de cada pieza; alcanza con un huso del pais en prime time.
    -- Empates: IdPublicidad y luego IdPais. Las piezas sin mercado no son candidatas.
    ;WITH Mercados AS (
        SELECT PP.IdPublicidad,
               PP.IdPais,
               CASE WHEN PP.IdPais IN (S1.IdPais, S2.IdPais) THEN 1 ELSE 0 END AS EsParticipante,
               Pais.PBI,
               CASE
                   WHEN EXISTS (
                       SELECT 1
                       FROM sedes.HusoHorario H
                       WHERE H.IdHuso=Pais.HusoHorario
                         AND CAST(sedes.fnFechaHoraLocal(P.Fecha, P.HoraUTC, H.Nombre) AS TIME) >= '19:00'
                         AND CAST(sedes.fnFechaHoraLocal(P.Fecha, P.HoraUTC, H.Nombre) AS TIME) <  '23:00'
                   ) THEN 1
                   ELSE 0
               END AS EsPrimeTime
        FROM publicidad.PublicidadPais PP
        JOIN equipos.Pais Pais ON Pais.IdPais = PP.IdPais
        CROSS JOIN partidos.Partido P
        JOIN equipos.Seleccion S1 ON S1.IdSeleccion = P.Eq1
        JOIN equipos.Seleccion S2 ON S2.IdSeleccion = P.Eq2
        WHERE P.IdPartido = @idPartido
    ),
    Mejores AS (
        SELECT *,
               ROW_NUMBER() OVER (
                   PARTITION BY IdPublicidad
                   ORDER BY EsParticipante DESC, PBI DESC, EsPrimeTime DESC, IdPais
               ) AS OrdenMercado
        FROM Mercados
    )
    SELECT TOP (4)
           IdPublicidad,
           IdPais,
           EsParticipante,
           PBI,
           EsPrimeTime
    FROM Mejores
    WHERE OrdenMercado = 1
    ORDER BY EsParticipante DESC, PBI DESC, EsPrimeTime DESC, IdPublicidad;
END;
GO

CREATE OR ALTER PROCEDURE SPTRANS.uspPublicidad_AsignarAutomaticamente
    @idPartido INT,
    @idCF      INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores NVARCHAR(2048) = N'',
            @sede    INT;

    SELECT @sede = IdSede
    FROM partidos.Partido
    WHERE IdPartido = @idPartido;

    IF @sede IS NULL
        SET @errores += N'Partido inexistente. ';

    IF NOT EXISTS (SELECT 1 FROM publicidad.CostoFranja WHERE IdCF = @idCF AND IdSede = @sede)
        SET @errores += N'Tarifa inexistente o de otra sede. ';

    IF (SELECT COUNT(*) FROM publicidad.EspacioPublicitario WHERE IdSede = @sede) <> 4
        SET @errores += N'La sede debe tener cuatro espacios. ';

    IF EXISTS (SELECT 1 FROM publicidad.HistorialPublicidad WHERE IdPartido = @idPartido)
        SET @errores += N'El partido ya tiene asignaciones. ';

    IF LEN(@errores) > 0
        THROW 51000, @errores, 1;

    DECLARE @piezas TABLE (
        IdPublicidad   INT,
        IdPais         INT,
        EsParticipante INT,
        PBI            BIGINT,
        EsPrimeTime    INT
    );

    INSERT @piezas
    EXEC SP.uspPublicidad_Proponer @idPartido;

    IF (SELECT COUNT(*) FROM @piezas) <> 4
        THROW 51000, 'No hay cuatro piezas con mercados de interes.', 1;

    DECLARE @asignaciones publicidad.AsignacionesPartido;

    ;WITH Piezas AS (
        SELECT IdPublicidad,
               ROW_NUMBER() OVER (
                   ORDER BY EsParticipante DESC, PBI DESC, EsPrimeTime DESC, IdPublicidad
               ) AS Orden
        FROM @piezas
    ),
    Espacios AS (
        SELECT IdEP,
               ROW_NUMBER() OVER (ORDER BY Numero) AS Orden
        FROM publicidad.EspacioPublicitario
        WHERE IdSede = @sede
    )
    INSERT @asignaciones (IdEP, IdPublicidad, IdCF)
    SELECT E.IdEP,
           P.IdPublicidad,
           @idCF
    FROM Piezas P
    JOIN Espacios E ON E.Orden = P.Orden;

    EXEC SPTRANS.uspPublicidad_AsignarCuatro @idPartido, @asignaciones;
END;
GO

GO
-- 61_Sp_Trans_Jugador.sql
--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Creacion de Stored Procedures que involucran transacciones

-- Ejecutar en la base seleccionada por el instalador.
GO

--Jugador
IF OBJECT_ID('SPTRANS.uspJugador_Registrar', 'P') IS NOT NULL
    DROP PROCEDURE SPTRANS.uspJugador_Registrar;
GO
CREATE PROCEDURE SPTRANS.uspJugador_Registrar 
@nombre VARCHAR(30),
@fnac DATE,
@pais INT,
@posicion VARCHAR(20),
@numero INT,
@club INT = NULL,
@seleccion INT,
@estado VARCHAR(10) = 'Activo'
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	DECLARE @cantJugadores INT;
	DECLARE @idPersona INT;
	DECLARE @nuevo TABLE(ID INT);

	BEGIN TRY
		--Chequeo validez
		IF(@nombre IS NULL)
			SET @errores += '- Valor invalido: Nombre.' + N' ';

		IF(@fnac IS NULL) OR ( @fnac > CONVERT(DATE, GETDATE()) )
			SET @errores += '- Valor invalido: Fecha de Nacimiento.' + N' ';

		IF(@pais IS NULL) OR (@pais <= 0)
			SET @errores += '- Valor invalido: Pais.' + N' ';

		IF(@posicion IS NULL)
			SET @errores += '- Valor invalido: Posicion.' + N' ';

		IF(@numero IS NULL) OR (@numero <= 0)
			SET @errores += '- Valor invalido: Numero.' + N' ';

		IF( (@club IS NOT NULL) AND (@club <= 0) )
			SET @errores += '- Valor invalido: Club.' + N' ';

		IF(@seleccion IS NULL) OR (@seleccion <= 0)
			SET @errores += '- Valor invalido: Seleccion.' + N' ';

		--chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @pais)
			SET @errores += '- Valor inexistente: Pais.' + N' ';

		IF (@club IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM equipos.Club WHERE IdClub = @club)
			SET @errores += '- Valor inexistente: Club.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @seleccion)
			SET @errores += '- Valor inexistente: Seleccion.' + N' ';

		IF @estado IS NULL OR @estado NOT IN ('Activo', 'Inactivo')
			SET @errores += '- Estado inicial invalido: use Activo o Inactivo.' + N' ';

		-- Los reemplazantes inactivos no ocupan un lugar en la convocatoria.
		SET @cantJugadores = (SELECT COUNT(IdJugador) FROM equipos.Jugador WHERE Seleccion = @seleccion AND Estado <> 'Inactivo');
		IF @estado = 'Activo' AND ( (@cantJugadores + 1) > (SELECT TAMANIO_SELECCION_MAXIMO FROM sedes.Mundial WHERE IdMundial = (SELECT IdMundial FROM equipos.Seleccion WHERE IdSeleccion = @seleccion)) )
			SET @errores += '- Cupo maximo de jugadores excedido.' + N' ';

		--chequeo dup
		IF EXISTS(SELECT 1 FROM equipos.Persona WHERE Nombre = @nombre)
			SET @errores += '- Valor duplicado: Nombre.' + N' ';
		
		--El dorsal es unico por seleccion (UQ_Jugador_Dorsal), no globalmente.
		IF EXISTS(SELECT 1 FROM equipos.Jugador WHERE Numero = @numero AND Seleccion = @seleccion)
			SET @errores += '- Valor duplicado: Numero.' + N' ';

		BEGIN TRANSACTION;

		IF LEN(@errores)>0 THROW 50000, @errores, 1;
			INSERT INTO equipos.Persona(Nombre, Fnac, Pais, Rol)
			OUTPUT INSERTED.IdPersona INTO @nuevo(ID)
			VALUES (@nombre, @fnac, @pais, 'Jugador');

			SELECT TOP 1 @idPersona = ID FROM @nuevo;

			INSERT INTO equipos.Jugador(IdJugador, Estado, Posicion, Numero, TarjetasAcum, Club, Seleccion)
			VALUES(@idPersona, @estado, @posicion, @numero, 0, @club, @seleccion);

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END
GO

IF OBJECT_ID('SPTRANS.uspJugador_Update', 'P') IS NOT NULL
    DROP PROCEDURE SPTRANS.uspJugador_Update;
GO
CREATE PROCEDURE SPTRANS.uspJugador_Update 
@id INT,
@nombre VARCHAR(30) = NULL,
@fnac DATE = NULL,
@pais INT = NULL,
@posicion VARCHAR(20) = NULL,
@numero INT = NULL,
@seleccion INT = NULL
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	DECLARE @selDestino INT;

	BEGIN TRY
		--Chequeo validez
		IF(@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Jugador.' + N' ';

		IF(@fnac IS NOT NULL) AND ( @fnac > CONVERT(DATE, GETDATE()) )
			SET @errores += '- Valor invalido: Fecha de Nacimiento.' + N' ';

		IF(@pais IS NOT NULL) AND (@pais <= 0)
			SET @errores += '- Valor invalido: Pais.' + N' ';

		IF(@numero IS NOT NULL) AND (@numero <= 0)
			SET @errores += '- Valor invalido: Numero.' + N' ';

		IF(@seleccion IS NOT NULL) AND (@seleccion <= 0)
			SET @errores += '- Valor invalido: Seleccion.' + N' ';

		--chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM equipos.Jugador WHERE IdJugador = @id)
			SET @errores += '- Valor inexistente: IdJugador.' + N' ';

		IF (@pais IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @pais)
			SET @errores += '- Valor inexistente: Pais.' + N' ';

		IF (@seleccion IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @seleccion)
			SET @errores += '- Valor inexistente: Seleccion.' + N' ';

		--chequeo dup
		IF (@nombre IS NOT NULL) AND EXISTS(SELECT 1 FROM equipos.Persona WHERE Nombre = @nombre AND IdPersona <> @id)
			SET @errores += '- Valor duplicado: Nombre.' + N' ';

		--El dorsal es unico por seleccion: se controla contra la seleccion que quedara.
		SET @selDestino = COALESCE(@seleccion, (SELECT Seleccion FROM equipos.Jugador WHERE IdJugador = @id));

		IF EXISTS(SELECT 1 FROM equipos.Jugador WHERE Numero = COALESCE(@numero, (SELECT Numero FROM equipos.Jugador WHERE IdJugador = @id)) AND Seleccion = @selDestino AND IdJugador <> @id)
			SET @errores += '- Valor duplicado: Numero.' + N' ';


		IF @selDestino <> (SELECT Seleccion FROM equipos.Jugador WHERE IdJugador = @id)
		BEGIN
			IF EXISTS (SELECT 1 FROM partidos.Alineacion WHERE IdJugador = @id)
			OR EXISTS (SELECT 1 FROM partidos.Gol WHERE Autor = @id OR Asistencia = @id)
			OR EXISTS (SELECT 1 FROM partidos.Amonestacion WHERE Amonestado = @id)
			OR EXISTS (SELECT 1 FROM partidos.Sustitucion WHERE Ingreso = @id OR Egreso = @id)
			OR EXISTS (SELECT 1 FROM equipos.CambioConvocatoria WHERE Ingreso = @id OR Egreso = @id)
				SET @errores += '- No se puede cambiar la seleccion de un jugador con historial.' + N' ';

			IF EXISTS (SELECT 1 FROM equipos.Jugador WHERE IdJugador = @id AND Estado <> 'Inactivo')
			BEGIN
				IF (SELECT COUNT(*) FROM equipos.Jugador WHERE Seleccion = @selDestino AND Estado <> 'Inactivo') >=
				   (SELECT M.TAMANIO_SELECCION_MAXIMO FROM sedes.Mundial M JOIN equipos.Seleccion S ON S.IdMundial = M.IdMundial WHERE S.IdSeleccion = @selDestino)
					SET @errores += '- Cupo maximo de jugadores excedido en la seleccion destino.' + N' ';

				IF (SELECT COUNT(*) FROM equipos.Jugador WHERE Seleccion = (SELECT Seleccion FROM equipos.Jugador WHERE IdJugador = @id) AND Estado <> 'Inactivo' AND IdJugador <> @id) <
				   (SELECT M.TAMANIO_SELECCION_MINIMO FROM sedes.Mundial M JOIN equipos.Seleccion S ON S.IdMundial = M.IdMundial JOIN equipos.Jugador J ON J.Seleccion = S.IdSeleccion WHERE J.IdJugador = @id)
					SET @errores += '- Cupo minimo de jugadores no respetado en la seleccion origen.' + N' ';
			END
		END

		BEGIN TRANSACTION;

		IF LEN(@errores)>0 THROW 50000, @errores, 1;
			UPDATE equipos.Persona
			SET
			Nombre = COALESCE(@nombre, Nombre),
			Fnac = COALESCE(@fnac, Fnac),
			Pais = COALESCE(@pais, Pais)
			WHERE IdPersona = @id;

			UPDATE equipos.Jugador
			SET
			Posicion = COALESCE(@posicion, Posicion),
			Numero = COALESCE(@numero, Numero),
			Seleccion = COALESCE(@seleccion, Seleccion)
			WHERE IdJugador = @id;

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END
GO

IF OBJECT_ID('SPTRANS.uspJugador_Bajar', 'P') IS NOT NULL
    DROP PROCEDURE SPTRANS.uspJugador_Bajar;
GO
CREATE PROCEDURE SPTRANS.uspJugador_Bajar
@id INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	DECLARE @cantJugadores INT;
	DECLARE @seleccion INT;

	BEGIN TRY
		--Chequeo validez
		IF(@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Jugador.' + N' ';

		--Chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM equipos.Jugador WHERE IdJugador = @id)
			SET @errores += '- Valor inexistente: IdJugador.' + N' ';

		--Chequeo relaciones
		IF EXISTS(SELECT 1 FROM partidos.Amonestacion WHERE Amonestado = @id)
			SET @errores += '- Existen 1 o mas registros relacionados: Amonestacion. Elimine dichos registros para continuar.' + N' ';

		IF EXISTS(SELECT 1 FROM partidos.Gol WHERE Autor = @id OR Asistencia = @id)
			SET @errores += '- Existen 1 o mas registros relacionados: Gol. Elimine dichos registros para continuar.' + N' ';

		IF EXISTS(SELECT 1 FROM partidos.Sustitucion WHERE Ingreso = @id OR Egreso = @id)
			SET @errores += '- Existen 1 o mas registros relacionados: Sustitucion. Elimine dichos registros para continuar.' + N' ';

		IF EXISTS(SELECT 1 FROM equipos.CambioConvocatoria WHERE Ingreso = @id OR Egreso = @id)
			SET @errores += '- Existen 1 o mas registros relacionados: Cambio en Convocatoria. Elimine dichos registros para continuar.' + N' ';

		--chequeo cupo
		SET @seleccion = (SELECT Seleccion FROM equipos.Jugador WHERE IdJugador = @id);
		--Se cuentan SOLO los jugadores activos que quedarian, es decir, sin contar al que se elimina.
		SET @cantJugadores = (SELECT COUNT(IdJugador) FROM equipos.Jugador WHERE Seleccion = @seleccion AND Estado <> 'Inactivo' AND IdJugador <> @id);

		IF( @cantJugadores < (SELECT TAMANIO_SELECCION_MINIMO FROM sedes.Mundial WHERE IdMundial = (SELECT IdMundial FROM equipos.Seleccion WHERE IdSeleccion = @seleccion)) )
			SET @errores += '- Cupo minimo de jugadores no respetado.' + N' ';

		BEGIN TRANSACTION;
			-- Baja logica en vez de DELETE fisico.
			-- El jugador pasa a Estado='Inactivo' (puede ser reingresado como ingreso de cambio de convocatoria).

		IF LEN(@errores)>0 THROW 50000, @errores, 1;
			UPDATE equipos.Jugador
			SET Estado = 'Inactivo'
			WHERE IdJugador = @id;

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END
GO

GO
-- 62_Sp_Trans_Arbitro.sql
--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Creacion de Stored Procedures que involucran transacciones

-- Ejecutar en la base seleccionada por el instalador.
GO

--Arbitro
IF OBJECT_ID('SPTRANS.uspArbitro_Registrar', 'P') IS NOT NULL
    DROP PROCEDURE SPTRANS.uspArbitro_Registrar;
GO
CREATE PROCEDURE SPTRANS.uspArbitro_Registrar 
@nombre VARCHAR(30),
@fnac DATE,
@pais INT,
@categoria VARCHAR(13)
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	DECLARE @idPersona INT;
	DECLARE @nuevo TABLE(ID INT);

	BEGIN TRY
		--Chequeo validez
		IF(@nombre IS NULL)
			SET @errores += '- Valor invalido: Nombre.' + N' ';

		IF(@fnac IS NULL) OR ( @fnac > CONVERT(DATE, GETDATE()) )
			SET @errores += '- Valor invalido: Fecha de Nacimiento.' + N' ';

		IF(@pais IS NULL) OR (@pais <= 0)
			SET @errores += '- Valor invalido: Pais.' + N' ';

		IF(@categoria IS NULL) OR (@categoria NOT IN ('FIFA', 'Confederacion'))
			SET @errores += '- Valor invalido: Categoria.' + N' ';

		--chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @pais)
			SET @errores += '- Valor inexistente: Pais.' + N' ';

		--chequeo dup
		IF EXISTS(SELECT 1 FROM equipos.Persona WHERE Nombre = @nombre)
			SET @errores += '- Valor duplicado: Nombre.' + N' ';

		BEGIN TRANSACTION;

		IF LEN(@errores)>0 THROW 50000, @errores, 1;
			INSERT INTO equipos.Persona(Nombre, Fnac, Pais, Rol)
			OUTPUT INSERTED.IdPersona INTO @nuevo(ID)
			VALUES (@nombre, @fnac, @pais, 'Arbitro');

			SELECT TOP 1 @idPersona = ID FROM @nuevo;

			INSERT INTO arbitros.Arbitro(IdArbitro, Categoria)
			VALUES(@idPersona, @categoria);

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END
GO

IF OBJECT_ID('SPTRANS.uspArbitro_Update', 'P') IS NOT NULL
    DROP PROCEDURE SPTRANS.uspArbitro_Update;
GO
CREATE PROCEDURE SPTRANS.uspArbitro_Update 
@id INT,
@nombre VARCHAR(30) = NULL,
@fnac DATE = NULL,
@pais INT = NULL,
@categoria VARCHAR(13) = NULL
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		--Chequeo validez
		IF(@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Arbitro.' + N' ';

		IF(@fnac IS NOT NULL) AND ( @fnac > CONVERT(DATE, GETDATE()) )
			SET @errores += '- Valor invalido: Fecha de Nacimiento.' + N' ';

		IF(@pais IS NOT NULL) AND (@pais <= 0)
			SET @errores += '- Valor invalido: Pais.' + N' ';

		IF(@categoria IS NOT NULL) AND (@categoria NOT IN ('FIFA', 'Confederacion'))
			SET @errores += '- Valor invalido: Categoria.' + N' ';

		--chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM arbitros.Arbitro WHERE IdArbitro = @id)
			SET @errores += '- Valor inexistente: IdArbitro.' + N' ';

		IF (@pais IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @pais)
			SET @errores += '- Valor inexistente: Pais.' + N' ';

		--chequeo dup
		IF (@nombre IS NOT NULL) AND EXISTS(SELECT 1 FROM equipos.Persona WHERE Nombre = @nombre AND IdPersona <> @id)
			SET @errores += '- Valor duplicado: Nombre.' + N' ';

		BEGIN TRANSACTION;

		IF LEN(@errores)>0 THROW 50000, @errores, 1;
			UPDATE equipos.Persona
			SET
			Nombre = COALESCE(@nombre, Nombre),
			Fnac = COALESCE(@fnac, Fnac),
			Pais = COALESCE(@pais, Pais)
			WHERE IdPersona = @id;

			UPDATE arbitros.Arbitro
			SET
			Categoria = COALESCE(@categoria, Categoria)
			WHERE IdArbitro = @id;

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END
GO

IF OBJECT_ID('SPTRANS.uspArbitro_Bajar', 'P') IS NOT NULL
    DROP PROCEDURE SPTRANS.uspArbitro_Bajar;
GO
CREATE PROCEDURE SPTRANS.uspArbitro_Bajar
@id INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		--Chequeo validez
		IF(@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: IdArbitro.' + N' ';

		--Chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM arbitros.Arbitro WHERE IdArbitro = @id)
			SET @errores += '- Valor inexistente: IdArbitro.' + N' ';

		--Chequeo relaciones
		IF EXISTS(SELECT 1 FROM arbitros.Reporte WHERE Arbitro = @id)
			SET @errores += '- Existen 1 o mas registros relacionados: Reporte. Elimine dichos registros para continuar.' + N' ';

		IF EXISTS(SELECT 1 FROM arbitros.Arbitraje WHERE Arbitro = @id)
			SET @errores += '- Existen 1 o mas registros relacionados: Arbitraje. Elimine dichos registros para continuar.' + N' ';

		IF EXISTS(SELECT 1 FROM partidos.Amonestacion WHERE Arbitro = @id)
			SET @errores += '- Existen 1 o mas registros relacionados: Amonestacion. Elimine dichos registros para continuar.' + N' ';

		BEGIN TRANSACTION;

		IF LEN(@errores)>0 THROW 50000, @errores, 1;
			DELETE FROM arbitros.HablaIdioma
			WHERE Arbitro = @id;

			DELETE FROM arbitros.Arbitro
			WHERE IdArbitro = @id;

			DELETE FROM equipos.Persona
			WHERE IdPersona = @id;

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END
GO

GO
-- 63_Sp_Trans_Tecnico.sql
--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Creacion de Stored Procedures que involucran transacciones

-- Ejecutar en la base seleccionada por el instalador.
GO

--Tecnico
IF OBJECT_ID('SPTRANS.uspTecnico_Registrar', 'P') IS NOT NULL
    DROP PROCEDURE SPTRANS.uspTecnico_Registrar;
GO
CREATE PROCEDURE SPTRANS.uspTecnico_Registrar 
@nombre VARCHAR(30),
@fnac DATE,
@pais INT,
@funcion VARCHAR(40),
@seleccion INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	DECLARE @idPersona INT;
	DECLARE @nuevo TABLE(ID INT);

	BEGIN TRY
		--Chequeo validez
		IF(@nombre IS NULL)
			SET @errores += '- Valor invalido: Nombre.' + N' ';

		IF(@fnac IS NULL) OR ( @fnac > CONVERT(DATE, GETDATE()) )
			SET @errores += '- Valor invalido: Fecha de Nacimiento.' + N' ';

		IF(@pais IS NULL) OR (@pais <= 0)
			SET @errores += '- Valor invalido: Pais.' + N' ';

		IF(@funcion IS NULL)
			SET @errores += '- Valor invalido: Funcion.' + N' ';

		IF(@seleccion IS NULL) OR (@seleccion <= 0)
			SET @errores += '- Valor invalido: Seleccion.' + N' ';

		--chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @pais)
			SET @errores += '- Valor inexistente: Pais.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @seleccion)
			SET @errores += '- Valor inexistente: Seleccion.' + N' ';

		--chequeo dup
		IF EXISTS(SELECT 1 FROM equipos.Persona WHERE Nombre = @nombre)
			SET @errores += '- Valor duplicado: Nombre.' + N' ';

		BEGIN TRANSACTION;

		IF LEN(@errores)>0 THROW 50000, @errores, 1;
			INSERT INTO equipos.Persona(Nombre, Fnac, Pais, Rol)
			OUTPUT INSERTED.IdPersona INTO @nuevo(ID)
			VALUES (@nombre, @fnac, @pais, 'Tecnico');

			SELECT TOP 1 @idPersona = ID FROM @nuevo;

			INSERT INTO equipos.Tecnico(IdTecnico, Funcion, Seleccion, TarjetasAcum, Estado)
			VALUES(@idPersona, @funcion, @seleccion, 0, 'Activo');

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END
GO

IF OBJECT_ID('SPTRANS.uspTecnico_Update', 'P') IS NOT NULL
    DROP PROCEDURE SPTRANS.uspTecnico_Update;
GO
CREATE PROCEDURE SPTRANS.uspTecnico_Update 
@id INT,
@nombre VARCHAR(30) = NULL,
@fnac DATE = NULL,
@pais INT = NULL,
@funcion VARCHAR(40) = NULL,
@seleccion INT = NULL
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		--Chequeo validez
		IF(@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Tecnico.' + N' ';

		IF(@fnac IS NOT NULL) AND ( @fnac > CONVERT(DATE, GETDATE()) )
			SET @errores += '- Valor invalido: Fecha de Nacimiento.' + N' ';

		IF(@pais IS NOT NULL) AND (@pais <= 0)
			SET @errores += '- Valor invalido: Pais.' + N' ';

		IF(@seleccion IS NOT NULL) AND (@seleccion <= 0)
			SET @errores += '- Valor invalido: Seleccion.' + N' ';

		--chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM equipos.Tecnico WHERE IdTecnico = @id)
			SET @errores += '- Valor inexistente: ID Tecnico.' + N' ';

		IF (@pais IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM equipos.Pais WHERE IdPais = @pais)
			SET @errores += '- Valor inexistente: Pais.' + N' ';

		IF (@seleccion IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @seleccion)
			SET @errores += '- Valor inexistente: Seleccion.' + N' ';

		--chequeo dup
		IF (@nombre IS NOT NULL) AND EXISTS(SELECT 1 FROM equipos.Persona WHERE Nombre = @nombre AND IdPersona <> @id)
			SET @errores += '- Valor duplicado: Nombre.' + N' ';

		BEGIN TRANSACTION;

		IF LEN(@errores)>0 THROW 50000, @errores, 1;
			UPDATE equipos.Persona
			SET
			Nombre = COALESCE(@nombre, Nombre),
			Fnac = COALESCE(@fnac, Fnac),
			Pais = COALESCE(@pais, Pais)
			WHERE IdPersona = @id;

			UPDATE equipos.Tecnico
			SET
			Funcion = COALESCE(@funcion, Funcion),
			Seleccion = COALESCE(@seleccion, Seleccion)
			WHERE IdTecnico = @id;

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END
GO

IF OBJECT_ID('SPTRANS.uspTecnico_Bajar', 'P') IS NOT NULL
    DROP PROCEDURE SPTRANS.uspTecnico_Bajar;
GO
CREATE PROCEDURE SPTRANS.uspTecnico_Bajar
@id INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		--Chequeo validez
		IF(@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Tecnico.' + N' ';

		--Chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM equipos.Tecnico WHERE IdTecnico = @id)
			SET @errores += '- Valor inexistente: ID Tecnico.' + N' ';

		--Chequeo relaciones
		IF EXISTS(SELECT 1 FROM partidos.Amonestacion WHERE Amonestado = @id)
			SET @errores += '- Existen 1 o mas registros relacionados: Amonestacion. Elimine dichos registros para continuar.' + N' ';

		BEGIN TRANSACTION;

		IF LEN(@errores)>0 THROW 50000, @errores, 1;
			DELETE FROM equipos.Tecnico
			WHERE IdTecnico = @id;

			DELETE FROM equipos.Persona
			WHERE IdPersona = @id;

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END
GO

GO
-- 64_Sp_Trans_Arbitraje.sql
--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Creacion de Stored Procedures que involucran transacciones

-- Ejecutar en la base seleccionada por el instalador.
GO

--Arbitraje
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspArbitraje_Registrar'))
    DROP PROCEDURE SPTRANS.uspArbitraje_Registrar
GO
CREATE PROCEDURE SPTRANS.uspArbitraje_Registrar 
@arbitro INT,
@funcion VARCHAR(20),
@partido INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		--Chequeo validez
		IF(@arbitro IS NULL) OR (@arbitro <= 0)
			SET @errores += '- Valor invalido: ID Arbitro.' + N' ';

		IF(@funcion IS NULL) OR (@funcion NOT IN ('Principal', 'Asistente', '4to', 'VAR'))
			SET @errores += '- Valor invalido: Funcion.' + N' ';

		IF(@partido IS NULL) OR (@partido <= 0)
			SET @errores += '- Valor invalido: ID Partido.' + N' ';

		--chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM arbitros.Arbitro WHERE IdArbitro = @arbitro)
			SET @errores += '- Valor inexistente: ID Arbitro.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM partidos.Partido WHERE IdPartido = @partido)
			SET @errores += '- Valor inexistente: ID Partido.' + N' ';

		--chequeo dup
		IF EXISTS(SELECT 1 FROM arbitros.Arbitraje WHERE Arbitro = @arbitro AND Partido = @partido)
			SET @errores += '- Valor duplicado: Arbitro. Se encuentra ya asignado a alguna funcion de ese partido.' + N' ';

		--chequeo cupo
		IF(
			((@funcion = 'Principal') AND ((SELECT COUNT(Arbitro) FROM arbitros.Arbitraje WHERE Partido = @partido AND Funcion = 'Principal') >= 1))
			OR
			((@funcion = 'Asistente') AND ((SELECT COUNT(Arbitro) FROM arbitros.Arbitraje WHERE Partido = @partido AND Funcion = 'Asistente') >= 2))
			OR
			((@funcion = 'VAR') AND ((SELECT COUNT(Arbitro) FROM arbitros.Arbitraje WHERE Partido = @partido AND Funcion = 'VAR') >= 1))
			OR
			((@funcion = '4to') AND ((SELECT COUNT(Arbitro) FROM arbitros.Arbitraje WHERE Partido = @partido AND Funcion = '4to') >= 1))
		)
			SET @errores += '- Cupo excedido para esa funcion.' + N' ';

		--chequeo nacionalidad(para este partido)
		IF EXISTS
		(
			SELECT 1
			FROM
			(
				SELECT IdPais
				FROM equipos.Seleccion
				WHERE IdSeleccion 
				IN (SELECT Eq1 FROM partidos.Partido WHERE IdPartido = @partido UNION SELECT Eq2 FROM partidos.Partido WHERE IdPartido = @partido)
			) AS P
			WHERE P.IdPais = (SELECT Pais FROM equipos.Persona WHERE IdPersona = @arbitro)
		)
			SET @errores += '- No se puede asignar este arbitro, el pais al que pertenece disputa este partido.' + N' ';

		-- Aviso preventivo: el fixture no guarda las llaves de eliminacion.
		IF EXISTS (
			SELECT 1 FROM partidos.Partido Actual
			JOIN partidos.Fase FA ON FA.IdFase = Actual.IdFase
			JOIN partidos.Partido Otro ON Otro.IdMundial = Actual.IdMundial AND Otro.IdPartido <> Actual.IdPartido
			JOIN partidos.Fase FO ON FO.IdFase = Otro.IdFase
			JOIN equipos.Seleccion S ON S.IdSeleccion IN (Otro.Eq1, Otro.Eq2)
			JOIN equipos.Persona A ON A.Pais = S.IdPais AND A.IdPersona = @arbitro
			WHERE Actual.IdPartido = @partido
			AND FA.Descripcion IN ('Dieciseisavos', 'Octavos', 'Cuartos', 'Semifinal')
			AND FO.Descripcion IN ('Dieciseisavos', 'Octavos', 'Cuartos', 'Semifinal', 'Final')
			AND (Otro.Fecha > Actual.Fecha OR (Otro.Fecha = Actual.Fecha AND Otro.HoraUTC >= Actual.HoraUTC))
		)
			PRINT '-ADVERTENCIA- La seleccion del pais del arbitro tiene otro partido eliminatorio programado en este mundial. Revisar posibles cruces.';

		BEGIN TRANSACTION

		IF LEN(@errores)>0 THROW 50000, @errores, 1;
			INSERT INTO arbitros.Arbitraje
			VALUES (@arbitro, @funcion, @partido)

			COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspArbitraje_Update'))
    DROP PROCEDURE SPTRANS.uspArbitraje_Update
GO
CREATE PROCEDURE SPTRANS.uspArbitraje_Update 
@arbitro INT,
@funcion VARCHAR(20),
@partido INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		--Chequeo validez
		IF(@arbitro IS NULL) OR (@arbitro <= 0)
			SET @errores += '- Valor invalido: ID Arbitro.' + N' ';

		IF(@funcion IS NULL) OR (@funcion NOT IN ('Principal', 'Asistente', '4to', 'VAR'))
			SET @errores += '- Valor invalido: Funcion.' + N' ';

		IF(@partido IS NULL) OR (@partido <= 0)
			SET @errores += '- Valor invalido: ID Partido.' + N' ';

		--chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM arbitros.Arbitraje WHERE Arbitro = @arbitro AND Partido = @partido)
			SET @errores += '- Registro inexistente.' + N' ';

		--chequeo dup
		IF EXISTS(SELECT 1 FROM arbitros.Arbitraje WHERE Arbitro = @arbitro AND Partido = @partido AND Funcion = @funcion)
			SET @errores += '- Valor duplicado: Arbitro. Se encuentra ya asignado a esa funcion.' + N' ';

		--chequeo cupo (se excluye el propio registro para no contarse a si mismo)
		IF(
			((@funcion = 'Principal') AND ((SELECT COUNT(Arbitro) FROM arbitros.Arbitraje WHERE Partido = @partido AND Funcion = 'Principal' AND Arbitro <> @arbitro) >= 1))
			OR
			((@funcion = 'Asistente') AND ((SELECT COUNT(Arbitro) FROM arbitros.Arbitraje WHERE Partido = @partido AND Funcion = 'Asistente' AND Arbitro <> @arbitro) >= 2))
			OR
			((@funcion = 'VAR') AND ((SELECT COUNT(Arbitro) FROM arbitros.Arbitraje WHERE Partido = @partido AND Funcion = 'VAR' AND Arbitro <> @arbitro) >= 1))
			OR
			((@funcion = '4to') AND ((SELECT COUNT(Arbitro) FROM arbitros.Arbitraje WHERE Partido = @partido AND Funcion = '4to' AND Arbitro <> @arbitro) >= 1))
		)
			SET @errores += '- Cupo excedido para esa funcion.' + N' ';

		IF EXISTS (SELECT 1 FROM partidos.Partido P
			JOIN equipos.Seleccion S ON S.IdSeleccion IN (P.Eq1, P.Eq2)
			JOIN equipos.Persona A ON A.Pais = S.IdPais AND A.IdPersona = @arbitro
			WHERE P.IdPartido = @partido)
			SET @errores += '- No se puede asignar este arbitro, el pais al que pertenece disputa este partido.' + N' ';
		-- Aviso preventivo: el fixture no guarda las llaves de eliminacion.
		IF EXISTS (
			SELECT 1 FROM partidos.Partido Actual
			JOIN partidos.Fase FA ON FA.IdFase = Actual.IdFase
			JOIN partidos.Partido Otro ON Otro.IdMundial = Actual.IdMundial AND Otro.IdPartido <> Actual.IdPartido
			JOIN partidos.Fase FO ON FO.IdFase = Otro.IdFase
			JOIN equipos.Seleccion S ON S.IdSeleccion IN (Otro.Eq1, Otro.Eq2)
			JOIN equipos.Persona A ON A.Pais = S.IdPais AND A.IdPersona = @arbitro
			WHERE Actual.IdPartido = @partido
			AND FA.Descripcion IN ('Dieciseisavos', 'Octavos', 'Cuartos', 'Semifinal')
			AND FO.Descripcion IN ('Dieciseisavos', 'Octavos', 'Cuartos', 'Semifinal', 'Final')
			AND (Otro.Fecha > Actual.Fecha OR (Otro.Fecha = Actual.Fecha AND Otro.HoraUTC >= Actual.HoraUTC))
		)
			PRINT '-ADVERTENCIA- La seleccion del pais del arbitro tiene otro partido eliminatorio programado en este mundial. Revisar posibles cruces.';

		BEGIN TRANSACTION

		IF LEN(@errores)>0 THROW 50000, @errores, 1;
			UPDATE arbitros.Arbitraje
			SET Funcion = @funcion
			WHERE Arbitro = @arbitro AND Partido = @partido

			COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspArbitraje_Bajar'))
    DROP PROCEDURE SPTRANS.uspArbitraje_Bajar
GO
CREATE PROCEDURE SPTRANS.uspArbitraje_Bajar 
@arbitro INT,
@partido INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		--Chequeo validez
		IF(@arbitro IS NULL) OR (@arbitro <= 0)
			SET @errores += '- Valor invalido: ID Arbitro.' + N' ';

		IF(@partido IS NULL) OR (@partido <= 0)
			SET @errores += '- Valor invalido: ID Partido.' + N' ';

		--chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM arbitros.Arbitraje WHERE Arbitro = @arbitro AND Partido = @partido)
			SET @errores += '- Registro inexistente.' + N' ';

		BEGIN TRANSACTION

		IF LEN(@errores)>0 THROW 50000, @errores, 1;
			DELETE FROM arbitros.Arbitraje
			WHERE Arbitro = @arbitro AND Partido = @partido

			COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END
GO

GO
-- 65_Sp_Amonestacion.sql
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

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspAmonestacion_Registrar'))
    DROP PROCEDURE SPTRANS.uspAmonestacion_Registrar
GO
CREATE PROCEDURE SPTRANS.uspAmonestacion_Registrar 
@minuto INT,
@partido INT,
@periodo INT,
@amonestado INT,
@arbitro INT,
@tarjeta VARCHAR(8),
@motivo VARCHAR(300)
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	DECLARE @vRol VARCHAR(10)
	DECLARE @vLimSuspension INT
	DECLARE @vTarjetasAcum INT
	DECLARE @vAutoRoja INT
	DECLARE @vSusp INT
	DECLARE @ID TABLE(ID INT)

	BEGIN TRY
		--Chequeo validez
		IF(@minuto IS NOT NULL) AND (@minuto < 0)
			SET @errores += '- Valor invalido: Minuto.' + N' ';

		IF(@partido IS NULL) OR (@partido <= 0)
			SET @errores += '- Valor invalido: Partido.' + N' ';

		IF(@periodo IS NULL) OR (@periodo <= 0)
			SET @errores += '- Valor invalido: Periodo.' + N' ';

		IF(@amonestado IS NULL) OR (@amonestado <= 0)
			SET @errores += '- Valor invalido: Amonestado.' + N' ';

		IF(@arbitro IS NULL) OR (@arbitro <= 0)
			SET @errores += '- Valor invalido: Arbitro.' + N' ';

		IF(@tarjeta IS NULL) OR (@tarjeta NOT IN ('Amarilla', 'Roja'))
			SET @errores += '- Valor invalido: Tarjeta.' + N' ';

		IF(@motivo IS NULL)
			SET @errores += '- Valor invalido: Motivo.' + N' ';

		--chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM partidos.Periodo WHERE IdPeriodo = @periodo)
			SET @errores += '- Valor inexistente: Periodo.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM equipos.Persona WHERE IdPersona = @amonestado)
			SET @errores += '- Valor inexistente: Amonestado.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM arbitros.Arbitro WHERE IdArbitro = @arbitro)
			SET @errores += '- Valor inexistente: Arbitro.' + N' ';

		IF NOT EXISTS(SELECT 1 FROM partidos.Partido WHERE IdPartido = @partido)
			SET @errores += '- Valor inexistente: Partido.' + N' ';

		--validez del minuto en relacion al periodo
		IF(
			(
				(@minuto IS NULL) 
				AND 
				((SELECT Descripcion FROM partidos.Periodo WHERE IdPeriodo = @periodo) <> 'Penales')
			)
			OR
			(
				(@minuto IS NOT NULL)
				AND
				(
					(@minuto < (SELECT Inicio FROM partidos.Periodo WHERE IdPeriodo = @periodo))
					OR
					(@minuto > (SELECT Fin FROM partidos.Periodo WHERE IdPeriodo = @periodo))
				)
			)
		)
			SET @errores += '- El minuto esta fuera del rango del periodo indicado.' + N' ';

		--validez del amonestado
		SET @vRol = (SELECT Rol FROM equipos.Persona WHERE IdPersona = @amonestado)

		IF(@vRol = 'Arbitro')
			SET @errores += '- Objetivo de amonestacion invalido.' + N' ';

		--chequeo participacion
		IF NOT EXISTS(SELECT 1 FROM arbitros.Arbitraje WHERE Arbitro = @arbitro AND Partido = @partido AND Funcion = 'Principal')
			SET @errores += '- El arbitro no participo del encuentro o su funcion no le permite sancionar.' + N' ';

		IF(@vRol = 'Tecnico') AND 
		NOT EXISTS
		(
			SELECT 1 FROM equipos.Tecnico  
			WHERE IdTecnico = @amonestado AND 
			Seleccion IN
			((SELECT Eq1 FROM partidos.Partido WHERE IdPartido = @partido)
			UNION
			(SELECT Eq2 FROM partidos.Partido WHERE IdPartido = @partido))
		)
			SET @errores += '- El tecnico no participo del encuentro.' + N' ';

		IF(@vRol = 'Jugador') AND
		NOT EXISTS
		(
			SELECT 1 FROM equipos.Jugador  
			WHERE IdJugador = @amonestado AND
			Seleccion IN
			((SELECT Eq1 FROM partidos.Partido WHERE IdPartido = @partido)
			UNION
			(SELECT Eq2 FROM partidos.Partido WHERE IdPartido = @partido))
		)
			SET @errores += '- El jugador no participo del encuentro.' + N' ';

		SET @vLimSuspension = (SELECT SUSPENSION_TARJETAS_MAXIMAS FROM sedes.Mundial WHERE IdMundial = (SELECT IdMundial FROM partidos.Partido WHERE IdPartido = @partido))
		SET @vAutoRoja = 0
		SET @vSusp = 0

		BEGIN TRANSACTION

			IF
			EXISTS(
			SELECT 1
			FROM 
			partidos.Amonestacion AS A
			INNER JOIN
			(SELECT IdEvento FROM partidos.Evento WHERE Partido = @partido AND Tipo = 'Amonestacion') AS E
			ON A.IdAmonestacion = E.IdEvento
			WHERE A.Amonestado = @amonestado AND A.Tarjeta = 'Roja')
				SET @errores += 'Esta persona ya fue expulsada.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

			INSERT INTO partidos.Evento (Minuto, Periodo, Partido, Tipo)
			OUTPUT INSERTED.IdEvento into @ID
			VALUES (@minuto, @periodo, @partido, 'Amonestacion')

			INSERT INTO partidos.Amonestacion(IdAmonestacion, Amonestado, Arbitro, Tarjeta, Motivo)
			VALUES ((SELECT ID FROM @ID), @amonestado, @arbitro, @tarjeta, @motivo)

			IF(@tarjeta = 'Amarilla')
			BEGIN
				IF(@vRol = 'Jugador')
					SET @vTarjetasAcum = (SELECT TarjetasAcum FROM equipos.Jugador  WHERE IdJugador = @amonestado)
				ELSE
					SET @vTarjetasAcum = (SELECT TarjetasAcum FROM equipos.Tecnico  WHERE IdTecnico = @amonestado)

				IF( (@vTarjetasAcum + 1) = @vLimSuspension )
					SET @vSusp = 1
			END

			--chequeo si merece roja automatica(tiene 2 amarillas)
			IF(
			(
				SELECT COUNT(IdAmonestacion)
				FROM partidos.Amonestacion
				WHERE 
				Amonestado = @amonestado
				AND
				Tarjeta = 'Amarilla'
				AND
				IdAmonestacion IN (SELECT IdEvento FROM partidos.Evento WHERE Partido = @partido)
			) = 2)
			BEGIN
				INSERT INTO partidos.Evento (Minuto, Periodo, Partido, Tipo)
				OUTPUT INSERTED.IdEvento into @ID
				VALUES (@minuto, @periodo, @partido, 'Amonestacion')

				INSERT INTO partidos.Amonestacion(IdAmonestacion, Amonestado, Arbitro, Tarjeta, Motivo)
				VALUES ((SELECT TOP 1 ID FROM @ID ORDER BY ID DESC), @amonestado, @arbitro, 'Roja', 'Otorgada por recibir 2 tarjetas amarillas previamente.')

				SET @vAutoRoja = 1
			END

			--chequeo si merece suspension
			IF(@vRol = 'Jugador')
			BEGIN
				IF
				(@vSusp = 1)
				OR
				(@tarjeta = 'Roja')
				OR
				(@vAutoRoja = 1)
				BEGIN
					UPDATE equipos.Jugador 
					SET
					Estado = 'Suspendido', TarjetasAcum = 0
					WHERE IdJugador = @amonestado
				END
				ELSE
					UPDATE equipos.Jugador  SET TarjetasAcum = TarjetasAcum + 1 WHERE IdJugador = @amonestado
			END
			ELSE
			BEGIN
				IF
				(@vSusp = 1)
				OR
				(@tarjeta = 'Roja')
				OR
				(@vAutoRoja = 1)
				BEGIN
					UPDATE equipos.Tecnico 
					SET
					Estado = 'Suspendido', TarjetasAcum = 0
					WHERE IdTecnico = @amonestado
				END
				ELSE
					UPDATE equipos.Tecnico  SET TarjetasAcum = TarjetasAcum + 1 WHERE IdTecnico = @amonestado
			END

			COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END;
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspAmonestacion_UpdateTiempo'))
    DROP PROCEDURE SPTRANS.uspAmonestacion_UpdateTiempo
GO
CREATE PROCEDURE SPTRANS.uspAmonestacion_UpdateTiempo
@id INT,
@minuto INT,
@periodo INT = NULL
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		--Chequeo validez
		IF(@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Amonestacion.' + N' ';

		IF(@minuto IS NOT NULL) AND (@minuto < 0)
			SET @errores += '- Valor invalido: Minuto.' + N' ';

		IF(@periodo IS NOT NULL) AND (@periodo <= 0)
			SET @errores += '- Valor invalido: Periodo.' + N' ';

		--chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM partidos.Amonestacion WHERE IdAmonestacion = @id)
			SET @errores += '- Registro inexistente.' + N' ';

		IF(@periodo IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM partidos.Periodo WHERE IdPeriodo = @periodo)
			SET @errores += '- Valor inexistente: Periodo.' + N' ';
		
		--validez del minuto en relacion al periodo(cambiando solo el minuto)
		IF(@periodo IS NULL)
		BEGIN
			DECLARE @vCheck INT = (SELECT Periodo FROM partidos.Evento WHERE IdEvento = @id)

			IF
			( 
				(@minuto IS NULL) 
				AND 
				((SELECT Descripcion FROM partidos.Periodo WHERE IdPeriodo = @vCheck) <> 'Penales')
			)
			OR
			(
				(@minuto IS NOT NULL)
				AND
				(
					(@minuto < (SELECT Inicio FROM partidos.Periodo WHERE IdPeriodo = @vCheck))
					OR
					(@minuto > (SELECT Fin FROM partidos.Periodo WHERE IdPeriodo = @vCheck))
				)
			)
				SET @errores += '- El minuto esta fuera del rango del periodo actual.' + N' ';
		END

		--validez del minuto en relacion al periodo(cambiando ambos)
		IF(@periodo IS NOT NULL)
		BEGIN
			IF
			(
				(@minuto IS NULL) 
				AND 
				( (SELECT Descripcion FROM partidos.Periodo WHERE IdPeriodo = @periodo) <> 'Penales' )
			)
			OR
			(
				(@minuto IS NOT NULL)
				AND
				(
					(@minuto < (SELECT Inicio FROM partidos.Periodo WHERE IdPeriodo = @periodo))
					OR
					(@minuto > (SELECT Fin FROM partidos.Periodo WHERE IdPeriodo = @periodo))
				)
			)
				SET @errores += '- El minuto esta fuera del rango del periodo indicado.' + N' ';
		END

		BEGIN TRANSACTION

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

			UPDATE partidos.Evento
			SET
			Minuto = @minuto,
			Periodo = COALESCE(@periodo, Periodo)
			WHERE IdEvento = @id

			COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END;
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspAmonestacion_UpdateMotivo'))
    DROP PROCEDURE SPTRANS.uspAmonestacion_UpdateMotivo
GO
CREATE PROCEDURE SPTRANS.uspAmonestacion_UpdateMotivo
@id INT,
@motivo VARCHAR(300) 
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		--Chequeo validez
		IF(@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Amonestacion.' + N' ';

		IF(@motivo IS NULL)
			SET @errores += '- Valor invalido: Motivo.' + N' ';

		--chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM partidos.Amonestacion WHERE IdAmonestacion = @id)
			SET @errores += '- Registro inexistente.' + N' ';

		BEGIN TRANSACTION

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

			UPDATE partidos.Amonestacion
			SET Motivo = @motivo
			WHERE IdAmonestacion = @id

			COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END;
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspAmonestacion_Bajar'))
    DROP PROCEDURE SPTRANS.uspAmonestacion_Bajar
GO
CREATE PROCEDURE SPTRANS.uspAmonestacion_Bajar
@id INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		--Chequeo validez
		IF(@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Amonestacion.' + N' ';

		--chequeo existencia
		IF NOT EXISTS(SELECT 1 FROM partidos.Amonestacion WHERE IdAmonestacion = @id)
			SET @errores += '- Registro inexistente.' + N' ';

		BEGIN TRANSACTION

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

			DELETE FROM partidos.Amonestacion
			WHERE IdAmonestacion = @id

			DELETE FROM partidos.Evento
			WHERE IdEvento = @id

			COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END;
GO

GO
-- 66_Sp_Gol.sql
--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 28/10/26
-- Objetivo: separar goles de juego y conversiones de tanda en una transaccion.

GO
 
CREATE OR ALTER PROCEDURE SPTRANS.uspGol_Registrar
    @minuto     INT,
    @partido    INT,
    @periodo    INT,
    @autor      INT,
    @asistencia INT = NULL,
    @tipo       VARCHAR(20),
    @idGol      INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
 
    DECLARE @errores   NVARCHAR(2048) = N'',
            @penales   BIT,
            @eq1       INT,
            @eq2       INT,
            @seleccion INT;
 
    SELECT @penales = EsPenales
    FROM partidos.Periodo
    WHERE IdPeriodo = @periodo;
 
    IF EXISTS (SELECT 1 FROM partidos.Periodo WHERE IdPeriodo=@periodo AND Descripcion='Descanso')
        SET @errores += N'No se permiten goles durante el descanso. ';

    IF @penales IS NULL
        SET @errores += N'Periodo inexistente. ';
 
    IF NOT EXISTS (SELECT 1 FROM partidos.Partido WHERE IdPartido = @partido)
        SET @errores += N'Partido inexistente. ';
 
    IF @tipo IS NULL OR @tipo NOT IN ('Jugada', 'Penal', 'Tiro libre', 'Corner', 'En contra')
        SET @errores += N'Tipo de gol invalido. ';
 
    IF @minuto < 0
        SET @errores += N'Minuto invalido. ';
 
    IF @penales = 0 AND @minuto IS NULL
        SET @errores += N'El minuto es obligatorio fuera de la tanda. ';
 
    DECLARE @minutoJuego INT = COALESCE(@minuto, 2147483647);
 
    IF partidos.fnJugadorEnCanchaPeriodo(@partido, @autor, @minutoJuego, @periodo) = 0
        SET @errores += N'El autor no estaba en cancha. ';
 
    IF @asistencia IS NOT NULL AND partidos.fnJugadorEnCanchaPeriodo(@partido, @asistencia, @minutoJuego, @periodo) = 0
        SET @errores += N'El asistente no estaba en cancha. ';
 
    IF @penales = 1 AND (@minuto IS NOT NULL OR @tipo <> 'Penal' OR @asistencia IS NOT NULL)
        SET @errores += N'La tanda requiere tipo Penal, minuto NULL y sin asistencia. ';
 
    IF @penales = 0
       AND @minuto IS NOT NULL
       AND EXISTS (
            SELECT 1
            FROM partidos.Periodo
            WHERE IdPeriodo = @periodo
              AND (@minuto < Inicio OR @minuto > Fin)
       )
        SET @errores += N'Minuto fuera del periodo. ';
 
    IF @autor = @asistencia
        SET @errores += N'Autor y asistente deben ser diferentes. ';
 
    IF @tipo = 'En contra' AND @asistencia IS NOT NULL
        SET @errores += N'Un gol en contra no lleva asistencia. ';
 
    SELECT @seleccion = Seleccion
    FROM equipos.Jugador
    WHERE IdJugador = @autor;
 
    SELECT @eq1 = Eq1,
           @eq2 = Eq2
    FROM partidos.Partido
    WHERE IdPartido = @partido;
 
    IF @seleccion IS NULL OR @seleccion NOT IN (@eq1, @eq2)
        SET @errores += N'El autor no pertenece a un equipo del partido. ';
 
    IF @asistencia IS NOT NULL
       AND NOT EXISTS (
            SELECT 1
            FROM equipos.Jugador
            WHERE IdJugador = @asistencia
              AND Seleccion = @seleccion
       )
        SET @errores += N'El asistente debe pertenecer al equipo del autor. ';
 

 
    BEGIN TRY
        BEGIN TRANSACTION;
 
        -- Serializa goles y bajas del mismo partido para no perder incrementos.
        SELECT @eq1 = Eq1,
               @eq2 = Eq2
        FROM partidos.Partido WITH (UPDLOCK, HOLDLOCK)
        WHERE IdPartido = @partido;
 
        IF @penales = 1
           AND EXISTS (
                SELECT 1
                FROM partidos.Partido p
                JOIN partidos.Fase f ON f.IdFase = p.IdFase
                WHERE p.IdPartido = @partido
                  AND f.Descripcion = 'Grupos'
           )
            SET @errores += 'La fase de grupos no admite definicion por penales.' + N' ';
 
        IF @penales = 1
           AND EXISTS (
                SELECT 1
                FROM partidos.Partido
                WHERE IdPartido = @partido
                  AND GolesEq1 <> GolesEq2
           )
            SET @errores += 'Solo se puede iniciar una tanda con marcador empatado.' + N' ';
 
        IF @penales = 0
           AND EXISTS (
                SELECT 1
                FROM partidos.Partido
                WHERE IdPartido = @partido
                  AND PenalesEq1 IS NOT NULL
           )
            SET @errores += 'Anular la tanda antes de corregir goles del partido.' + N' ';
 
        IF LEN(@errores)>0 THROW 51000,@errores,1;

        INSERT partidos.Evento (Minuto, Tipo, Partido, Periodo)
        VALUES (@minuto, 'Gol', @partido, @periodo);
 
        SET @idGol = CONVERT(INT, SCOPE_IDENTITY());
 
        INSERT partidos.Gol (IdGol, Autor, Asistencia, Tipo)
        VALUES (@idGol, @autor, @asistencia, @tipo);
 
        IF @penales = 1
            UPDATE partidos.Partido
            SET PenalesEq1 = COALESCE(PenalesEq1, 0) + CASE WHEN @seleccion = @eq1 THEN 1 ELSE 0 END,
                PenalesEq2 = COALESCE(PenalesEq2, 0) + CASE WHEN @seleccion = @eq2 THEN 1 ELSE 0 END
            WHERE IdPartido = @partido;
        ELSE
            UPDATE partidos.Partido
            SET GolesEq1 = GolesEq1 + CASE WHEN (@seleccion = @eq1 AND @tipo <> 'En contra') OR (@seleccion = @eq2 AND @tipo = 'En contra') THEN 1 ELSE 0 END,
                GolesEq2 = GolesEq2 + CASE WHEN (@seleccion = @eq2 AND @tipo <> 'En contra') OR (@seleccion = @eq1 AND @tipo = 'En contra') THEN 1 ELSE 0 END
            WHERE IdPartido = @partido;
 
        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;
 
        THROW;
    END CATCH;
END;
GO
 
CREATE OR ALTER PROCEDURE SPTRANS.uspGol_Bajar
    @id INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
 
    DECLARE @partido INT,
            @penales BIT,
            @tipo    VARCHAR(20),
            @sel     INT,
            @eq1     INT,
            @eq2     INT;
 
    SELECT @partido = Partido
    FROM partidos.Evento
    WHERE IdEvento = @id;
 
    IF @partido IS NULL OR NOT EXISTS (SELECT 1 FROM partidos.Gol WHERE IdGol = @id)
        SET @errores += 'Gol inexistente.' + N' ';
 
    BEGIN TRY
        BEGIN TRANSACTION;
 
        SELECT @eq1 = Eq1,
               @eq2 = Eq2
        FROM partidos.Partido WITH (UPDLOCK, HOLDLOCK)
        WHERE IdPartido = @partido;
 
        IF NOT EXISTS (SELECT 1 FROM partidos.Gol WHERE IdGol = @id)
            SET @errores += 'El gol ya fue eliminado.' + N' ';
 
        SELECT @penales = r.EsPenales,
               @tipo    = g.Tipo,
               @sel     = j.Seleccion
        FROM partidos.Gol g
        JOIN partidos.Evento e  ON e.IdEvento  = g.IdGol
        JOIN partidos.Periodo r ON r.IdPeriodo = e.Periodo
        JOIN equipos.Jugador j  ON j.IdJugador = g.Autor
        WHERE g.IdGol = @id;
 
        IF @penales = 0
           AND EXISTS (
                SELECT 1
                FROM partidos.Partido
                WHERE IdPartido = @partido
                  AND PenalesEq1 IS NOT NULL
           )
            SET @errores += 'Anular la tanda antes de corregir goles del partido.' + N' ';
 
        IF LEN(@errores)>0 THROW 50000, @errores, 1;

        IF @penales = 1
            UPDATE partidos.Partido
            SET PenalesEq1 = PenalesEq1 - CASE WHEN @sel = @eq1 THEN 1 ELSE 0 END,
                PenalesEq2 = PenalesEq2 - CASE WHEN @sel = @eq2 THEN 1 ELSE 0 END
            WHERE IdPartido = @partido;
        ELSE
            UPDATE partidos.Partido
            SET GolesEq1 = GolesEq1 - CASE WHEN (@sel = @eq1 AND @tipo <> 'En contra') OR (@sel = @eq2 AND @tipo = 'En contra') THEN 1 ELSE 0 END,
                GolesEq2 = GolesEq2 - CASE WHEN (@sel = @eq2 AND @tipo <> 'En contra') OR (@sel = @eq1 AND @tipo = 'En contra') THEN 1 ELSE 0 END
            WHERE IdPartido = @partido;
 
        DELETE partidos.Gol
        WHERE IdGol = @id;
 
        DELETE partidos.Evento
        WHERE IdEvento = @id;
 
        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;
 
        THROW;
    END CATCH;
END;
GO
 
-- Iniciar permite representar una tanda 0-0; anular la deja NULL-NULL.
-- No representa cierre de partido ni verifica todas las reglas de tiros de una tanda.
CREATE OR ALTER PROCEDURE SP.uspPartido_Tanda
    @IdPartido INT,
    @Iniciar   BIT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
 
    IF @Iniciar IS NULL
        SET @errores += 'Iniciar es obligatorio.' + N' ';
 
    IF NOT EXISTS (SELECT 1 FROM partidos.Partido WHERE IdPartido = @IdPartido)
        SET @errores += 'Partido inexistente.' + N' ';
 
    BEGIN TRY
        BEGIN TRANSACTION;
 
        DECLARE @g1 INT,
                @g2 INT;
 
        SELECT @g1 = GolesEq1,
               @g2 = GolesEq2
        FROM partidos.Partido WITH (UPDLOCK, HOLDLOCK)
        WHERE IdPartido = @IdPartido;
 
        IF @Iniciar = 1
           AND EXISTS (
                SELECT 1
                FROM partidos.Partido p
                JOIN partidos.Fase f ON f.IdFase = p.IdFase
                WHERE p.IdPartido = @IdPartido
                  AND f.Descripcion = 'Grupos'
           )
            SET @errores += 'La fase de grupos no admite definicion por penales.' + N' ';
 
        IF @Iniciar = 1 AND @g1 <> @g2
            SET @errores += 'La tanda requiere empate.' + N' ';
 
        IF @Iniciar = 0
           AND EXISTS (
                SELECT 1
                FROM partidos.Evento e
                JOIN partidos.Gol g     ON g.IdGol     = e.IdEvento
                JOIN partidos.Periodo r ON r.IdPeriodo = e.Periodo
                WHERE e.Partido = @IdPartido
                  AND r.EsPenales = 1
           )
            SET @errores += 'Eliminar primero las conversiones de la tanda.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;
 
        UPDATE partidos.Partido
        SET PenalesEq1 = CASE WHEN @Iniciar = 1 THEN COALESCE(PenalesEq1, 0) ELSE NULL END,
            PenalesEq2 = CASE WHEN @Iniciar = 1 THEN COALESCE(PenalesEq2, 0) ELSE NULL END
        WHERE IdPartido = @IdPartido;
 
        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;
 
        THROW;
    END CATCH;
END;
GO
 
CREATE OR ALTER VIEW partidos.vResultadoPartido AS
    SELECT IdPartido,
           GolesEq1,
           GolesEq2,
           PenalesEq1,
           PenalesEq2,
           CONCAT(
               GolesEq1,
               CASE WHEN PenalesEq1 IS NOT NULL THEN CONCAT('(', PenalesEq1, ')') ELSE '' END,
               ' - ',
               GolesEq2,
               CASE WHEN PenalesEq2 IS NOT NULL THEN CONCAT('(', PenalesEq2, ')') ELSE '' END
           ) AS Resultado
    FROM partidos.Partido;
GO
 
-- Fuente para reportes de goleadores: excluye tandas y goles en contra.
CREATE OR ALTER VIEW partidos.vGolesComputables AS
    SELECT g.IdGol,
           g.Autor,
           g.Asistencia,
           g.Tipo,
           e.Partido,
           e.Minuto,
           e.Periodo
    FROM partidos.Gol g
    JOIN partidos.Evento e  ON e.IdEvento  = g.IdGol
    JOIN partidos.Periodo r ON r.IdPeriodo = e.Periodo
    WHERE r.EsPenales = 0
      AND g.Tipo <> 'En contra';
GO

GO
-- 67_Sp_Sustitucion.sql
--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 28/10/26

--Objetivo: Gestionar Tabla Sustitucion

-- Ajuste: soporte de Descanso y orden por minuto/periodo.
-- Ejecutar en la base seleccionada por el instalador.
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspSustitucion_Registrar'))
    DROP PROCEDURE SPTRANS.uspSustitucion_Registrar
GO
CREATE PROCEDURE SPTRANS.uspSustitucion_Registrar
@minuto INT,
@partido INT,
@periodo INT,
@ingreso INT,
@egreso INT,
@motivo INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	DECLARE @vSeleccion INT
	DECLARE @vIdMundial INT
	DECLARE @vCambios INT
	DECLARE @vVentanas INT
	DECLARE @vMaxCambios INT
	DECLARE @vMaxVentanas INT

	DECLARE @vDescanso BIT = 0;
	DECLARE @vMomento BIGINT = partidos.fnMomentoEvento(@minuto,@periodo);
	SELECT @vDescanso = CASE WHEN Descripcion='Descanso' THEN 1 ELSE 0 END
	FROM partidos.Periodo WHERE IdPeriodo=@periodo;

	BEGIN TRY
		IF (@minuto IS NULL) OR (@minuto < 0)
			SET @errores += '- Valor invalido: Minuto.' + N' ';

		IF (@partido IS NULL) OR (@partido <= 0)
			SET @errores += '- Valor invalido: Partido.' + N' ';

		IF (@periodo IS NULL) OR (@periodo <= 0)
			SET @errores += '- Valor invalido: Periodo.' + N' ';

		IF (@ingreso IS NULL) OR (@ingreso <= 0)
			SET @errores += '- Valor invalido: Ingreso.' + N' ';

		IF (@egreso IS NULL) OR (@egreso <= 0)
			SET @errores += '- Valor invalido: Egreso.' + N' ';

		IF (@motivo IS NULL) OR (@motivo <= 0)
			SET @errores += '- Valor invalido: Motivo.' + N' ';

		IF (@ingreso = @egreso)
			SET @errores += '- Ingreso y egreso no pueden ser el mismo jugador.' + N' ';

		IF NOT EXISTS (SELECT 1 FROM partidos.Partido WHERE IdPartido = @partido)
			SET @errores += '- Valor inexistente: Partido.' + N' ';

		IF NOT EXISTS (SELECT 1 FROM partidos.Periodo WHERE IdPeriodo = @periodo)
			SET @errores += '- Valor inexistente: Periodo.' + N' ';

        IF EXISTS (SELECT 1 FROM partidos.Periodo WHERE IdPeriodo=@periodo AND EsPenales=1)
            SET @errores += N'- No se permiten sustituciones mediante este SP durante la tanda de penales. ';

        IF EXISTS (SELECT 1 FROM partidos.Periodo WHERE IdPeriodo=@periodo
                   AND (@minuto<Inicio OR @minuto>Fin))
            SET @errores += N'- El minuto esta fuera del rango del periodo indicado. ';

		IF NOT EXISTS (SELECT 1 FROM equipos.Jugador WHERE IdJugador = @ingreso)
			SET @errores += '- Valor inexistente: Ingreso.' + N' ';

		IF NOT EXISTS (SELECT 1 FROM equipos.Jugador WHERE IdJugador = @egreso)
			SET @errores += '- Valor inexistente: Egreso.' + N' ';

		IF NOT EXISTS (SELECT 1 FROM publicidad.Motivo WHERE IdMotivo = @motivo)
			SET @errores += '- Valor inexistente: Motivo.' + N' ';

		SET @vSeleccion = (SELECT Seleccion FROM equipos.Jugador WHERE IdJugador = @egreso)

		IF (SELECT Seleccion FROM equipos.Jugador WHERE IdJugador = @ingreso) <> @vSeleccion
			SET @errores += '- Ingreso y egreso deben ser de la misma seleccion.' + N' ';

		IF NOT EXISTS (SELECT 1 FROM partidos.Partido WHERE IdPartido = @partido AND (Eq1 = @vSeleccion OR Eq2 = @vSeleccion))
			SET @errores += '- La seleccion no juega este partido.' + N' ';

		IF partidos.fnJugadorEnCanchaPeriodo(@partido,@egreso,@minuto,@periodo)=0
			SET @errores += '- El egreso no estaba en cancha.' + N' ';

		IF NOT EXISTS (SELECT 1 FROM partidos.Alineacion WHERE IdPartido = @partido AND IdJugador = @ingreso AND Rol = 'Suplente')
			SET @errores += '- El ingreso no estaba en el banco.' + N' ';

		IF EXISTS (SELECT 1 FROM partidos.Sustitucion S JOIN partidos.Evento E ON E.IdEvento=S.IdSustitucion
			WHERE E.Partido=@partido AND (S.Ingreso=@ingreso OR S.Egreso=@ingreso OR S.Egreso=@egreso))
			SET @errores += '- El ingreso ya participo o el egreso ya fue reemplazado.' + N' ';

		IF EXISTS (SELECT 1 FROM partidos.Amonestacion A JOIN partidos.Evento E ON E.IdEvento=A.IdAmonestacion
			WHERE E.Partido=@partido AND A.Amonestado=@ingreso AND A.Tarjeta='Roja' AND partidos.fnMomentoEvento(E.Minuto,E.Periodo)<=@vMomento)
			SET @errores += '- No puede ingresar un jugador expulsado.' + N' ';

		-- Los cambios se cargan antes de los eventos posteriores del partido.
		IF EXISTS (SELECT 1 FROM partidos.Evento WHERE Partido=@partido AND partidos.fnMomentoEvento(Minuto,Periodo)>@vMomento)
			SET @errores += '- Registrar los cambios en orden de minuto y periodo, antes de los eventos posteriores.' + N' ';

		SELECT @vIdMundial = IdMundial FROM partidos.Partido WHERE IdPartido = @partido

		SELECT @vMaxCambios = CAMBIOS_CANTIDAD, @vMaxVentanas = CAMBIOS_VENTANAS FROM sedes.Mundial WHERE IdMundial = @vIdMundial

		SELECT @vCambios = COUNT(*) FROM partidos.Sustitucion S INNER JOIN partidos.Evento E ON S.IdSustitucion = E.IdEvento INNER JOIN equipos.Jugador J ON S.Egreso = J.IdJugador WHERE E.Partido = @partido AND J.Seleccion = @vSeleccion

        -- Una ventana por periodo y minuto; el descanso no consume ventanas.
        -- Se conserva la aproximacion existente: cambios en un mismo minuto = una ventana.
        SELECT @vVentanas = COUNT(*)
        FROM (
            SELECT E.Periodo, E.Minuto
            FROM partidos.Sustitucion S
            JOIN partidos.Evento E ON S.IdSustitucion=E.IdEvento
            JOIN equipos.Jugador J ON S.Egreso=J.IdJugador
            JOIN partidos.Periodo P ON P.IdPeriodo=E.Periodo
            WHERE E.Partido=@partido AND J.Seleccion=@vSeleccion
              AND P.Descripcion<>'Descanso' AND P.EsPenales=0
            GROUP BY E.Periodo,E.Minuto
        ) V;

		IF (@vCambios + 1) > @vMaxCambios
			SET @errores += '- Tope de cambios del reglamento excedido.' + N' ';

		IF @vDescanso = 0 AND NOT EXISTS (SELECT 1 FROM partidos.Sustitucion S INNER JOIN partidos.Evento E ON S.IdSustitucion = E.IdEvento INNER JOIN equipos.Jugador J ON S.Egreso = J.IdJugador WHERE E.Partido = @partido AND J.Seleccion = @vSeleccion AND E.Minuto = @minuto AND E.Periodo = @periodo)
		AND (@vVentanas + 1) > @vMaxVentanas
			SET @errores += '- Tope de ventanas del reglamento excedido.' + N' ';

		DECLARE @idEvento INT

		BEGIN TRANSACTION

		IF LEN(@errores)>0 THROW 50000, @errores, 1;
			INSERT INTO partidos.Evento (Minuto, Tipo, Partido, Periodo)
			VALUES (@minuto, 'Sustitucion', @partido, @periodo)

			SET @idEvento = SCOPE_IDENTITY()

			INSERT INTO partidos.Sustitucion (IdSustitucion, Ingreso, Egreso, Motivo)
			VALUES (@idEvento, @ingreso, @egreso, @motivo)

			COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspSustitucion_Bajar'))
    DROP PROCEDURE SPTRANS.uspSustitucion_Bajar
GO
CREATE PROCEDURE SPTRANS.uspSustitucion_Bajar
@id INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	BEGIN TRY
		IF (@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Sustitucion.' + N' ';

		IF NOT EXISTS (SELECT 1 FROM partidos.Sustitucion WHERE IdSustitucion = @id)
			SET @errores += '- Registro inexistente.' + N' ';

		BEGIN TRANSACTION

		IF LEN(@errores)>0 THROW 50000, @errores, 1;
			DELETE FROM partidos.Sustitucion
			WHERE IdSustitucion = @id

			DELETE FROM partidos.Evento
			WHERE IdEvento = @id

			COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END
GO

GO
-- 68_Sp_Evento.sql
--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 28/10/26

--Objetivo: SP de ABM de la tabla partidos.Evento (Alta, Baja, Modificacion).
--Las validaciones se acumulan en una variable y se lanzan con un unico THROW.

-- Ajuste: soporte de Descanso y orden por minuto/periodo.
-- Ejecutar en la base seleccionada por el instalador.
GO

-- =============================================
-- partidos.Evento_Alta
-- Inserta un evento y devuelve el IdEvento generado en @idEvento.
-- Minuto es opcional; el resto de los parametros son obligatorios.
-- =============================================
CREATE OR ALTER PROCEDURE partidos.Evento_Alta
	@minuto INT,
	@tipo VARCHAR(50),
	@partido INT,
	@periodo INT,
	@idEvento INT OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE @errores NVARCHAR(MAX) = N'';

	IF @tipo IS NULL OR LTRIM(RTRIM(@tipo)) = N''
		SET @errores += N'El tipo es obligatorio. ';
	IF @tipo IS NOT NULL AND LEN(@tipo) > 12
		SET @errores += N'El tipo no puede superar los 12 caracteres. ';

	IF @partido IS NULL
		SET @errores += N'El partido es obligatorio. ';
	IF @partido IS NOT NULL AND NOT EXISTS (SELECT 1 FROM partidos.Partido WHERE IdPartido = @partido)
		SET @errores += N'No existe un partido con IdPartido ' + CAST(@partido AS NVARCHAR(10)) + N'. ';

	IF @periodo IS NULL
		SET @errores += N'El periodo es obligatorio. ';
	IF @periodo IS NOT NULL AND NOT EXISTS (SELECT 1 FROM partidos.Periodo WHERE IdPeriodo = @periodo)
		SET @errores += N'No existe un periodo con IdPeriodo ' + CAST(@periodo AS NVARCHAR(10)) + N'. ';

    IF EXISTS (SELECT 1 FROM partidos.Periodo WHERE IdPeriodo=@periodo AND Descripcion='Descanso')
    BEGIN
        IF LTRIM(RTRIM(@tipo))='Gol'
            SET @errores += N'No se permiten goles durante el descanso. ';
        IF @minuto IS NULL
            SET @errores += N'El descanso requiere el minuto de referencia del periodo. ';
    END;

	IF @minuto IS NOT NULL AND @minuto < 0
		SET @errores += N'El minuto no puede ser negativo. ';
	IF @minuto IS NOT NULL AND @minuto >= 0
		AND EXISTS (SELECT 1 FROM partidos.Periodo
					WHERE IdPeriodo = @periodo AND (@minuto < Inicio OR @minuto > Fin))
		SET @errores += N'El minuto esta fuera del rango del periodo indicado. ';

	IF @minuto IS NOT NULL AND EXISTS(SELECT 1 FROM partidos.Periodo WHERE IdPeriodo=@periodo AND EsPenales=1)
        SET @errores += N'La tanda de penales no utiliza minuto; enviar NULL. ';
    IF LEN(@errores) > 0
		THROW 50000, @errores, 1;

	BEGIN TRY
		BEGIN TRANSACTION;

		INSERT INTO partidos.Evento (Minuto, Tipo, Partido, Periodo)
		VALUES (@minuto, @tipo, @partido, @periodo);

		SET @idEvento = SCOPE_IDENTITY();

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END;
GO

-- =============================================
-- partidos.Evento_Modificacion
-- Modifica un evento existente. Minuto es opcional; el resto es obligatorio.
-- =============================================
CREATE OR ALTER PROCEDURE partidos.Evento_Modificacion
	@idEvento INT,
	@minuto INT,
	@tipo VARCHAR(50),
	@partido INT,
	@periodo INT
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE @errores NVARCHAR(MAX) = N'';

	IF @idEvento IS NULL
		SET @errores += N'IdEvento es obligatorio. ';
	IF @idEvento IS NOT NULL AND NOT EXISTS (SELECT 1 FROM partidos.Evento WHERE IdEvento = @idEvento)
		SET @errores += N'No existe un evento con IdEvento ' + CAST(@idEvento AS NVARCHAR(10)) + N'. ';

	IF @tipo IS NULL OR LTRIM(RTRIM(@tipo)) = N''
		SET @errores += N'El tipo es obligatorio. ';
	IF @tipo IS NOT NULL AND LEN(@tipo) > 12
		SET @errores += N'El tipo no puede superar los 12 caracteres. ';

	IF @partido IS NULL
		SET @errores += N'El partido es obligatorio. ';
	IF @partido IS NOT NULL AND NOT EXISTS (SELECT 1 FROM partidos.Partido WHERE IdPartido = @partido)
		SET @errores += N'No existe un partido con IdPartido ' + CAST(@partido AS NVARCHAR(10)) + N'. ';

	IF @periodo IS NULL
		SET @errores += N'El periodo es obligatorio. ';
	IF @periodo IS NOT NULL AND NOT EXISTS (SELECT 1 FROM partidos.Periodo WHERE IdPeriodo = @periodo)
		SET @errores += N'No existe un periodo con IdPeriodo ' + CAST(@periodo AS NVARCHAR(10)) + N'. ';

    IF EXISTS (SELECT 1 FROM partidos.Periodo WHERE IdPeriodo=@periodo AND Descripcion='Descanso')
    BEGIN
        IF LTRIM(RTRIM(@tipo))='Gol'
            SET @errores += N'No se permiten goles durante el descanso. ';
        IF @minuto IS NULL
            SET @errores += N'El descanso requiere el minuto de referencia del periodo. ';
    END;

	IF @minuto IS NOT NULL AND @minuto < 0
		SET @errores += N'El minuto no puede ser negativo. ';
	IF @minuto IS NOT NULL AND @minuto >= 0
		AND EXISTS (SELECT 1 FROM partidos.Periodo
					WHERE IdPeriodo = @periodo AND (@minuto < Inicio OR @minuto > Fin))
		SET @errores += N'El minuto esta fuera del rango del periodo indicado. ';

	IF @minuto IS NOT NULL AND EXISTS(SELECT 1 FROM partidos.Periodo WHERE IdPeriodo=@periodo AND EsPenales=1)
        SET @errores += N'La tanda de penales no utiliza minuto; enviar NULL. ';
    IF EXISTS(SELECT 1 FROM partidos.Amonestacion WHERE IdAmonestacion=@idEvento)
        SET @errores += N'La amonestacion debe modificarse mediante su procedimiento especifico. ';
    IF EXISTS(SELECT 1 FROM partidos.Sustitucion WHERE IdSustitucion=@idEvento)
        SET @errores += N'Para corregir una sustitucion, usar su baja y registrar el cambio correcto. ';
    IF EXISTS(SELECT 1 FROM partidos.Gol WHERE IdGol=@idEvento)
        SET @errores += N'Para corregir un gol, usar su baja y registrar el evento correcto. ';
    IF LEN(@errores) > 0
		THROW 50000, @errores, 1;

	BEGIN TRY
		BEGIN TRANSACTION;

		UPDATE partidos.Evento
		SET Minuto = @minuto,
			Tipo = @tipo,
			Partido = @partido,
			Periodo = @periodo
		WHERE IdEvento = @idEvento;

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END;
GO

-- =============================================
-- partidos.Evento_Baja
-- Elimina un evento. No se permite si tiene una amonestacion asociada.
-- =============================================
CREATE OR ALTER PROCEDURE partidos.Evento_Baja
	@idEvento INT
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE @errores NVARCHAR(MAX) = N'';

	IF @idEvento IS NULL
		SET @errores += N'IdEvento es obligatorio. ';
	IF @idEvento IS NOT NULL AND NOT EXISTS (SELECT 1 FROM partidos.Evento WHERE IdEvento = @idEvento)
		SET @errores += N'No existe un evento con IdEvento ' + CAST(@idEvento AS NVARCHAR(10)) + N'. ';
	IF @idEvento IS NOT NULL AND EXISTS (SELECT 1 FROM partidos.Amonestacion WHERE IdAmonestacion = @idEvento)
		SET @errores += N'No se puede eliminar el evento: tiene una amonestacion asociada. ';

    IF EXISTS(SELECT 1 FROM partidos.Sustitucion WHERE IdSustitucion=@idEvento)
        SET @errores += N'Utilizar SPTRANS.uspSustitucion_Bajar para eliminar el cambio completo. ';
	IF EXISTS(SELECT 1 FROM partidos.Gol WHERE IdGol=@idEvento)
        SET @errores += N'Utilizar SPTRANS.uspGol_Bajar para mantener el marcador. ';
    IF LEN(@errores) > 0
		THROW 50000, @errores, 1;

	BEGIN TRY
		BEGIN TRANSACTION;

		DELETE FROM partidos.Evento
		WHERE IdEvento = @idEvento;

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END;
GO

GO
-- 69_Sp_CambioConvocatoria.sql
--/Universidad Nacional de La Matanza
--/Bases de Datos Aplicadas - Comision 02

--/Grupo 7 - Integrantes:
--Almiron, Luca
--Figueroa, Santiago
--Ruarte, Fidel
--Villalba, Leandro

--/Fecha: 26/10/26

--Objetivo: Gestionar Tabla CambioConvocatoria

-- Ejecutar en la base seleccionada por el instalador.
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspCambioConvocatoria_Registrar'))
    DROP PROCEDURE SPTRANS.uspCambioConvocatoria_Registrar
GO
CREATE PROCEDURE SPTRANS.uspCambioConvocatoria_Registrar
@seleccion INT,
@egreso INT,
@ingreso INT,
@fecha DATE,
@motivo VARCHAR(200)
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	DECLARE @vActivos INT
	DECLARE @vIdMundial INT
	DECLARE @vMin INT
	DECLARE @vMax INT

	BEGIN TRY
		IF (@seleccion IS NULL) OR (@seleccion <= 0)
			SET @errores += '- Valor invalido: Seleccion.' + N' ';

		IF (@egreso IS NULL) OR (@egreso <= 0)
			SET @errores += '- Valor invalido: Egreso.' + N' ';

		IF (@ingreso IS NULL) OR (@ingreso <= 0)
			SET @errores += '- Valor invalido: Ingreso.' + N' ';

		IF (@fecha IS NULL)
			SET @errores += '- Valor invalido: Fecha.' + N' ';

		IF (@motivo IS NULL)
			SET @errores += '- Valor invalido: Motivo.' + N' ';

		IF (@egreso = @ingreso)
			SET @errores += '- Egreso e ingreso no pueden ser el mismo jugador.' + N' ';

		IF NOT EXISTS (SELECT 1 FROM equipos.Seleccion WHERE IdSeleccion = @seleccion)
			SET @errores += '- Valor inexistente: Seleccion.' + N' ';

		IF NOT EXISTS (SELECT 1 FROM equipos.Jugador WHERE IdJugador = @egreso AND Seleccion = @seleccion AND Estado = 'Activo')
			SET @errores += '- El egreso no es un convocado activo de la seleccion.' + N' ';

		IF NOT EXISTS (SELECT 1 FROM equipos.Jugador WHERE IdJugador = @ingreso AND Seleccion = @seleccion)
			SET @errores += '- El ingreso no pertenece a la seleccion.' + N' ';

		IF EXISTS (SELECT 1 FROM equipos.Jugador WHERE IdJugador = @ingreso AND Estado <> 'Inactivo')
			SET @errores += '- El ingreso debe ser un jugador inactivo.' + N' ';

		SELECT @vIdMundial = IdMundial FROM equipos.Seleccion WHERE IdSeleccion = @seleccion

		SELECT @vMin = TAMANIO_SELECCION_MINIMO, @vMax = TAMANIO_SELECCION_MAXIMO FROM sedes.Mundial WHERE IdMundial = @vIdMundial

		SELECT @vActivos = COUNT(*) FROM equipos.Jugador WHERE Seleccion = @seleccion AND Estado <> 'Inactivo'

		IF (@vActivos < @vMin) OR (@vActivos > @vMax)
			SET @errores += '- La convocatoria incumple el cupo del reglamento.' + N' ';

		IF EXISTS (SELECT 1 FROM equipos.CambioConvocatoria
			WHERE (Ingreso IN (@ingreso, @egreso) OR Egreso IN (@ingreso, @egreso)) AND Fecha > @fecha)
			SET @errores += '- Existen cambios de convocatoria posteriores para estos jugadores.' + N' ';

		IF EXISTS (SELECT 1 FROM partidos.Alineacion A JOIN partidos.Partido P ON P.IdPartido = A.IdPartido
			WHERE A.IdJugador = @egreso AND P.Fecha >= @fecha)
			SET @errores += '- El egreso tiene alineaciones desde la fecha del cambio.' + N' ';

		BEGIN TRANSACTION

		IF LEN(@errores)>0 THROW 50000, @errores, 1;
			UPDATE equipos.Jugador
			SET Estado = 'Inactivo'
			WHERE IdJugador = @egreso

			UPDATE equipos.Jugador
			SET Estado = 'Activo'
			WHERE IdJugador = @ingreso

			INSERT INTO equipos.CambioConvocatoria (Seleccion, Egreso, Ingreso, Fecha, Motivo)
			VALUES (@seleccion, @egreso, @ingreso, @fecha, @motivo)

			COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END
GO

IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('SPTRANS.uspCambioConvocatoria_Bajar'))
    DROP PROCEDURE SPTRANS.uspCambioConvocatoria_Bajar
GO
CREATE PROCEDURE SPTRANS.uspCambioConvocatoria_Bajar
@id INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';
	DECLARE @vEgreso INT
	DECLARE @vIngreso INT
	DECLARE @vFecha DATE

	BEGIN TRY
		IF (@id IS NULL) OR (@id <= 0)
			SET @errores += '- Valor invalido: ID Cambio.' + N' ';

		IF NOT EXISTS (SELECT 1 FROM equipos.CambioConvocatoria WHERE IdCambio = @id)
			SET @errores += '- Registro inexistente.' + N' ';

		BEGIN TRANSACTION
			SELECT @vEgreso = Egreso, @vIngreso = Ingreso, @vFecha = Fecha FROM equipos.CambioConvocatoria WHERE IdCambio = @id

			IF EXISTS (SELECT 1 FROM equipos.CambioConvocatoria
				WHERE (Ingreso IN (@vIngreso, @vEgreso) OR Egreso IN (@vIngreso, @vEgreso))
				AND (Fecha > @vFecha OR (Fecha = @vFecha AND IdCambio > @id)))
				SET @errores += '- Anule primero los cambios de convocatoria posteriores.' + N' ';

			IF NOT EXISTS (SELECT 1 FROM equipos.Jugador WHERE IdJugador = @vEgreso AND Estado = 'Inactivo')
			OR NOT EXISTS (SELECT 1 FROM equipos.Jugador WHERE IdJugador = @vIngreso AND Estado = 'Activo')
				SET @errores += '- Los estados actuales no permiten anular el cambio.' + N' ';

			IF EXISTS (SELECT 1 FROM partidos.Alineacion A JOIN partidos.Partido P ON P.IdPartido = A.IdPartido
				WHERE A.IdJugador = @vIngreso AND P.Fecha >= @vFecha)
				SET @errores += '- El ingreso tiene alineaciones desde la fecha del cambio.' + N' ';

		IF LEN(@errores)>0 THROW 50000, @errores, 1;

			UPDATE equipos.Jugador
			SET Estado = 'Activo'
			WHERE IdJugador = @vEgreso

			UPDATE equipos.Jugador
			SET Estado = 'Inactivo'
			WHERE IdJugador = @vIngreso

			DELETE FROM equipos.CambioConvocatoria
			WHERE IdCambio = @id

			COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END
GO

GO
