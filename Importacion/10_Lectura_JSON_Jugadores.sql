-- UNLaM - Bases de Datos Aplicadas - Grupo 7. 
-- Fecha: 05/11/2026. 
-- Almiron, Luca 
-- Figueroa, Santiago 
-- Ruarte, Fidel 
-- Villalba, Leandro. 
-- Objetivo: leer los JSON originales de jugadores. Incluir desde 10_Importacion_Carga_Jugadores.sql. 
-- No ejecutar solo. Sin GO: utiliza las tablas temporales del importador.

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchife.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchife.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchife.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchiff.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchiff.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchiff.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchifg.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchifg.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchifg.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchifh.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchifh.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchifh.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchifi.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchifi.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchifi.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchifj.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchifj.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchifj.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchiga.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchiga.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchiga.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchigb.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchigb.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchigb.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchigc.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchigc.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchigc.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchigd.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchigd.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchigd.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchige.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchige.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchige.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchigf.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchigf.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchigf.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchigg.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchigg.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchigg.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchigh.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchigh.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchigh.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchigi.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchigi.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchigi.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchigj.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchigj.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchigj.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchiha.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchiha.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchiha.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchihb.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchihb.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchihb.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchihc.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchihc.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchihc.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchihd.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchihd.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchihd.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchihe.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchihe.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchihe.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchihf.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchihf.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchihf.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchihg.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchihg.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchihg.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchihh.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchihh.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchihh.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchihj.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchihj.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchihj.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchiia.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchiia.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchiia.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchiib.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchiib.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchiib.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchiic.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchiic.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchiic.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchiid.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchiid.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchiid.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchiie.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchiie.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchiie.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchijb.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchijb.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchijb.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchijg.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchijg.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchijg.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchijh.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchijh.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchijh.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchjab.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchjab.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchjab.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchjac.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchjac.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchjac.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchjad.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchjad.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchjad.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchjae.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchjae.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchjae.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchjaf.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchjaf.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchjaf.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchjag.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchjag.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchjag.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchjba.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchjba.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchjba.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchjbb.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchjbb.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchjbb.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchjbc.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchjbc.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchjbc.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchjbi.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchjbi.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchjbi.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchjca.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchjca.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchjca.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchjcb.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchjcb.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchjcb.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchjce.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchjce.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchjce.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchjch.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchjch.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchjch.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchjcj.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchjcj.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchjcj.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchjda.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchjda.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchjda.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchjdc.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchjdc.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchjdc.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchjdd.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchjdd.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchjdd.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchjdf.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchjdf.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchjdf.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchjdh.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchjdh.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchjdh.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egchjdi.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egchjdi.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egchjdi.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egjhgjg.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egjhgjg.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egjhgjg.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egjhgjh.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egjhgjh.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egjhgjh.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egjhgji.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egjhgji.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egjhgji.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egjhgjj.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egjhgjj.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egjhgjj.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egjhhaa.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egjhhaa.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egjhhaa.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egjhhab.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egjhhab.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egjhhab.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egjhhac.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egjhhac.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egjhhac.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egjhhad.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egjhhad.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egjhhad.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egjhhae.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egjhhae.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egjhhae.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egjhhaf.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egjhhaf.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egjhhaf.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egjhhag.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egjhhag.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egjhhag.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egjhhah.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egjhhah.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egjhhah.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egjhhde.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egjhhde.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egjhhde.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egjhhdf.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egjhhdf.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egjhhdf.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egjhhdg.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egjhhdg.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egjhhdg.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egjhjcb.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egjhjcb.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egjhjcb.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egjhjcc.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egjhjcc.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egjhjcc.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'egjhjcd.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\egjhjcd.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'egjhjcd.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'ehefgah.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\ehefgah.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'ehefgah.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'ehehgjg.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\ehehgjg.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'ehehgjg.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'ehehgjh.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\ehehgjh.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'ehehgjh.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'ehehgjj.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\ehehgjj.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'ehehgjj.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'eheibaj.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\eheibaj.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'eheibaj.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'eheicce.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\eheicce.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'eheicce.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'eheiccf.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\eheiccf.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'eheiccf.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'eheicde.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\eheicde.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'eheicde.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'eheicee.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\eheicee.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'eheicee.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'eheiiii.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\eheiiii.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'eheiiii.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'ehejcgi.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\ehejcgi.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'ehejcgi.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'ehejcha.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\ehejcha.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'ehejcha.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'ehejchb.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\ehejchb.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'ehejchb.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'ehejchc.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\ehejchc.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'ehejchc.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'ehejchd.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\ehejchd.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'ehejchd.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'ehejche.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\ehejche.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'ehejche.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'ehfaaaj.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\ehfaaaj.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'ehfaaaj.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'ehfafad.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\ehfafad.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'ehfafad.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'ehfajad.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\ehfajad.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'ehfajad.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'ehfdebf.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\ehfdebf.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'ehfdebf.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'ehfecjd.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\ehfecjd.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'ehfecjd.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'ehfhage.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\ehfhage.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'ehfhage.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'ehfihdg.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\ehfihdg.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'ehfihdg.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'ehfihfd.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\ehfihfd.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'ehfihfd.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'ehfjdhg.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\ehfjdhg.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'ehfjdhg.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'ehgahcb.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\ehgahcb.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'ehgahcb.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'ehgbeie.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\ehgbeie.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'ehgbeie.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'ehgcaec.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\ehgcaec.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'ehgcaec.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'ehgejfb.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\ehgejfb.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'ehgejfb.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'ehgjhcc.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\ehgjhcc.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'ehgjhcc.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'ehhdcbe.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\ehhdcbe.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'ehhdcbe.json',ERROR_MESSAGE())
END CATCH

BEGIN TRY
    INSERT #ArchivosJugadores (Archivo,Contenido)
    SELECT N'ehhdcbj.json',BulkColumn FROM OPENROWSET(BULK '$(CarpetaPartidos)\ehhdcbj.json',SINGLE_CLOB,CODEPAGE='65001') a
END TRY
BEGIN CATCH
    INSERT #ErroresArchivos VALUES (N'ehhdcbj.json',ERROR_MESSAGE())
END CATCH
