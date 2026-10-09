-- Universidad Nacional de La Matanza
-- Bases de datos aplicada 
-- Almiron, Luca
-- Figueroa, Santiago
-- Ruarte, Fidel
-- Villalba, Leandro
-- 08/10/2026
-- Objetivo: Testear Registro y Baja de Alineacion

--Los objetos de negocio (TABLAS y SP) viven en MUNDIAL, el test se ejecuta contra ellos.
--Requiere datos minimos cargados: un partido, un jugador y dos selcciones.
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MUNDIAL')
BEGIN
	USE MUNDIAL
END;
GO

-- Esperado: inserta titular, 1 fila
EXEC SP.uspAlineacion_Registrar @IdPartido=1, @IdJugador=1, @IdSeleccion=1, @Rol='Titular', @PosicionCancha='DEL', @Esquema='4-3-3';
GO
SELECT * FROM partidos.Alineacion;
GO

-- Esperado: PRINT duplicado, 0 filas nuevas
EXEC SP.uspAlineacion_Registrar @IdPartido=1, @IdJugador=1, @IdSeleccion=1, @Rol='Titular';
GO
SELECT * FROM partidos.Alineacion;
GO

-- Esperado: PRINT Rol invalido
EXEC SP.uspAlineacion_Registrar @IdPartido=1, @IdJugador=2, @IdSeleccion=1, @Rol='Arquero';
GO
SELECT * FROM partidos.Alineacion;
GO

-- Esperado: PRINT inexistente Partido (99)
EXEC SP.uspAlineacion_Registrar @IdPartido=99, @IdJugador=2, @IdSeleccion=1, @Rol='Suplente';
GO
SELECT * FROM partidos.Alineacion;
GO

-- Esperado: PRINT no convocado / no juega partido
EXEC SP.uspAlineacion_Registrar @IdPartido=1, @IdJugador=2, @IdSeleccion=99, @Rol='Suplente';
GO
SELECT * FROM partidos.Alineacion;
GO

-- Esperado: borra 1-1
EXEC SP.uspAlineacion_Bajar @IdPartido=1, @IdJugador=1;
GO
SELECT * FROM partidos.Alineacion;
GO

-- Esperado: PRINT no existe
EXEC SP.uspAlineacion_Bajar @IdPartido=1, @IdJugador=99;
GO
SELECT * FROM partidos.Alineacion;
GO