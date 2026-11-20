-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Comision 02
-- Grupo 7: Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: 21/11/2026.
-- Objetivo: reparar los efectos del bug de la Entrega 8 en una base ya cargada.
--   Los SP de ABM (61/62/63) cifraban Persona.Nombre pero no completaban
--   NombreHash, asi que las busquedas por hash del importador 15 no encontraban
--   los arbitros existentes y los insertaba de nuevo (104 arbitros, 42 nombres).
--   El importador 19 exige que el nombre del arbitro aparezca una sola vez,
--   por eso rechazaba todas las tarjetas de esos partidos.
-- Ejecutar DESPUES de reinstalar los SP 61/62/63 y ANTES de re-ejecutar 15/19.
-- Si se reinstala la base desde cero, NO hace falta este script.

USE MUNDIAL;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

-- 1) Completa NombreHash de las personas ya cargadas, descifrando el nombre.
UPDATE equipos.Persona
SET NombreHash = HASHBYTES('SHA2_256', CONVERT(NVARCHAR(30),
        DECRYPTBYKEYAUTOCERT(CERT_ID(N'CertificadoCifradoMundial'),
                             N'ClaveMaestra_Mundial_2026!', Nombre)))
WHERE NombreHash IS NULL;
GO

-- 2) Unifica los arbitros duplicados, redirigiendo sus referencias al de menor Id.
BEGIN TRY
    BEGIN TRANSACTION;

    CREATE TABLE #Duplicados (IdMantener INT, IdBorrar INT);

    ;WITH d AS (
        SELECT pe.IdPersona,
               MIN(pe.IdPersona) OVER (PARTITION BY pe.NombreHash) AS IdMantener
        FROM equipos.Persona AS pe
        JOIN arbitros.Arbitro AS a ON a.IdArbitro = pe.IdPersona
        WHERE pe.NombreHash IS NOT NULL
    )
    INSERT #Duplicados (IdMantener, IdBorrar)
    SELECT IdMantener, IdPersona
    FROM d
    WHERE IdPersona <> IdMantener;

    -- Si el partido ya tenia al arbitro correcto, se descarta la fila duplicada
    -- (PK_Arbitraje es Arbitro + Partido).
    DELETE a
    FROM arbitros.Arbitraje AS a
    JOIN #Duplicados AS d ON a.Arbitro = d.IdBorrar
    WHERE EXISTS (SELECT 1 FROM arbitros.Arbitraje AS x
                  WHERE x.Arbitro = d.IdMantener AND x.Partido = a.Partido);

    UPDATE a SET Arbitro = d.IdMantener
    FROM arbitros.Arbitraje AS a
    JOIN #Duplicados AS d ON a.Arbitro = d.IdBorrar;

    UPDATE am SET Arbitro = d.IdMantener
    FROM partidos.Amonestacion AS am
    JOIN #Duplicados AS d ON am.Arbitro = d.IdBorrar;

    DELETE a
    FROM arbitros.Arbitro AS a
    JOIN #Duplicados AS d ON a.IdArbitro = d.IdBorrar;

    DELETE p
    FROM equipos.Persona AS p
    JOIN #Duplicados AS d ON p.IdPersona = d.IdBorrar;

    SELECT COUNT(*) AS ArbitrosUnificados FROM #Duplicados;
    SELECT COUNT(*) AS ArbitrosRestantes FROM arbitros.Arbitro;

    DROP TABLE #Duplicados;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
