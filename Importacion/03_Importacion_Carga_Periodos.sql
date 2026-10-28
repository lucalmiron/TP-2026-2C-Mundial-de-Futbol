-- Universidad Nacional de La Matanza
-- Bases de Datos Aplicadas - Comision 02 - Grupo 7
-- Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 28/10/2026
-- Objetivo: carga inicial de Periodo usando el SP existente.
-- Ejecutar en MUNDIAL despues de instalar tablas y procedimientos.
-- Puede repetirse sin duplicar registros por descripcion.

SET NOCOUNT ON;

IF OBJECT_ID('partidos.Periodo', 'U') IS NULL
    THROW 50001, 'Falta la tabla partidos.Periodo.', 1;
IF OBJECT_ID('partidos.Periodo_Alta', 'P') IS NULL
    THROW 50002, 'Falta partidos.Periodo_Alta.', 1;

-- Se toma un ID libre para no colisionar con cargas anteriores.
-- Ejecutar esta carga inicial sin otras cargas simultaneas de periodos.
DECLARE @idPeriodo INT;

IF EXISTS (SELECT 1 FROM partidos.Periodo WHERE Descripcion = '1er tiempo')
BEGIN
    IF NOT EXISTS (SELECT 1 FROM partidos.Periodo
                   WHERE Descripcion = '1er tiempo' AND EsPenales = 0 AND Inicio = 0 AND Fin = 45)
        THROW 50005, 'El periodo 1er tiempo ya existe con otra configuracion. Revisarlo antes de continuar.', 1;
END
ELSE
BEGIN
    SELECT @idPeriodo = ISNULL(MAX(IdPeriodo), 0) + 1 FROM partidos.Periodo;
    EXEC partidos.Periodo_Alta
        @idPeriodo = @idPeriodo, @descripcion = '1er tiempo',
        @inicio = 0, @fin = 45, @esPenales = 0;
END;

-- Descanso: minuto 45 como referencia entre ambos tiempos, no duracion.
IF EXISTS (SELECT 1 FROM partidos.Periodo WHERE Descripcion = 'Descanso')
BEGIN
    IF NOT EXISTS (SELECT 1 FROM partidos.Periodo
                   WHERE Descripcion = 'Descanso' AND EsPenales = 0 AND Inicio = 45 AND Fin = 45)
        THROW 50005, 'El periodo Descanso ya existe con otra configuracion. Revisarlo antes de continuar.', 1;
END
ELSE
BEGIN
    SELECT @idPeriodo = ISNULL(MAX(IdPeriodo), 0) + 1 FROM partidos.Periodo;
    EXEC partidos.Periodo_Alta
        @idPeriodo = @idPeriodo, @descripcion = 'Descanso',
        @inicio = 45, @fin = 45, @esPenales = 0;
END;

IF EXISTS (SELECT 1 FROM partidos.Periodo WHERE Descripcion = '2do tiempo')
BEGIN
    IF NOT EXISTS (SELECT 1 FROM partidos.Periodo
                   WHERE Descripcion = '2do tiempo' AND EsPenales = 0 AND Inicio = 45 AND Fin = 90)
        THROW 50005, 'El periodo 2do tiempo ya existe con otra configuracion. Revisarlo antes de continuar.', 1;
END
ELSE
BEGIN
    SELECT @idPeriodo = ISNULL(MAX(IdPeriodo), 0) + 1 FROM partidos.Periodo;
    EXEC partidos.Periodo_Alta
        @idPeriodo = @idPeriodo, @descripcion = '2do tiempo',
        @inicio = 45, @fin = 90, @esPenales = 0;
END;

IF EXISTS (SELECT 1 FROM partidos.Periodo WHERE Descripcion = 'Alargue 1')
BEGIN
    IF NOT EXISTS (SELECT 1 FROM partidos.Periodo
                   WHERE Descripcion = 'Alargue 1' AND EsPenales = 0 AND Inicio = 90 AND Fin = 105)
        THROW 50005, 'El periodo Alargue 1 ya existe con otra configuracion. Revisarlo antes de continuar.', 1;
END
ELSE
BEGIN
    SELECT @idPeriodo = ISNULL(MAX(IdPeriodo), 0) + 1 FROM partidos.Periodo;
    EXEC partidos.Periodo_Alta
        @idPeriodo = @idPeriodo, @descripcion = 'Alargue 1',
        @inicio = 90, @fin = 105, @esPenales = 0;
END;

IF EXISTS (SELECT 1 FROM partidos.Periodo WHERE Descripcion = 'Alargue 2')
BEGIN
    IF NOT EXISTS (SELECT 1 FROM partidos.Periodo
                   WHERE Descripcion = 'Alargue 2' AND EsPenales = 0 AND Inicio = 105 AND Fin = 120)
        THROW 50005, 'El periodo Alargue 2 ya existe con otra configuracion. Revisarlo antes de continuar.', 1;
END
ELSE
BEGIN
    SELECT @idPeriodo = ISNULL(MAX(IdPeriodo), 0) + 1 FROM partidos.Periodo;
    EXEC partidos.Periodo_Alta
        @idPeriodo = @idPeriodo, @descripcion = 'Alargue 2',
        @inicio = 105, @fin = 120, @esPenales = 0;
END;

IF EXISTS (SELECT 1 FROM partidos.Periodo WHERE Descripcion = 'Penales')
BEGIN
    IF NOT EXISTS (SELECT 1 FROM partidos.Periodo
                   WHERE Descripcion = 'Penales' AND EsPenales = 1 AND Inicio IS NULL AND Fin IS NULL)
        THROW 50005, 'El periodo Penales ya existe con otra configuracion. Revisarlo antes de continuar.', 1;
END
ELSE
BEGIN
    SELECT @idPeriodo = ISNULL(MAX(IdPeriodo), 0) + 1 FROM partidos.Periodo;
    EXEC partidos.Periodo_Alta
        @idPeriodo = @idPeriodo, @descripcion = 'Penales',
        @inicio = NULL, @fin = NULL, @esPenales = 1;
END;

PRINT 'Carga de Periodo finalizada.';
