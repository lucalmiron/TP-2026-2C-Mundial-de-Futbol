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
