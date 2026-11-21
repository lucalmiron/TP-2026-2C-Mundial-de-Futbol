# Checklist post-merge — Entrega 6/8

Revisar **después** de hacer el merge. Si alguno de estos puntos no aparece, hay que volver a aplicarlo antes de correr los importadores.

## Código SQL

| Archivo | Qué debe estar presente |
|---|---|
| `Importacion/XX_Lectura_Partidos_JSON.sql` | Detección de fin de línea del CSV de equivalencias: `DECLARE @aliasBytes VARBINARY(MAX) = (SELECT BulkColumn FROM OPENROWSET(BULK '$(RutaAliasJugadores)', SINGLE_BLOB) AS f);` y `IF CHARINDEX(0x0D0A, @aliasBytes) > 0 ... ELSE ...`. **No** debe quedar el TRY/CATCH que reintentaba con `0x0d0a`. |
| `Importacion/10_Importacion_Carga_Jugadores.sql` | Los 3 BULK (`#JugadoresCsv`, `#AliasJugadores`, `#EquiposCsv`) con intento `0x0a` y reintento `0x0d0a`; búsqueda de jugador con `CONVERT(NVARCHAR(30), DECRYPTBYKEYAUTOCERT(...p.Nombre))`. |
| `Importacion/14_Importacion_Carga_Alineaciones.sql` | En D8b, el fallback de nombre abreviado: `s.Nombre LIKE N'_. %'` + `LEFT(nombre_descifrado,1) = LEFT(s.Nombre,1)` + `nombre_descifrado LIKE N'% ' + SUBSTRING(s.Nombre,4,100)`. |
| `Importacion/15_Importacion_Carga_Arbitrajes.sql` | Las búsquedas por `NombreHash = HASHBYTES('SHA2_256', @nombre)` siguen **intactas** (no cambiar por AUTOCERT). |
| `Importacion/18_Importacion_Carga_Tecnicos.sql` | Igual: `NombreHash` intacto. |
| `Importacion/24_Importacion_Carga_Arbitraje_FIFA.sql` | Igual: `NombreHash` intacto. |
| `Importacion/16_Importacion_Carga_Sustituciones.sql` | `IF ERROR_MESSAGE() LIKE N'%Tope de ventanas del reglamento%'` y `'%Tope de cambios%'` → `Estado='Omitida'`. Rechazo legítimo del reglamento. |
| `Importacion/17_Importacion_Carga_Goles.sql` | D8a: autor en banco sin ingreso → `Omitida`. D8b: resto → `Error`. |
| `Importacion/19_Importacion_Carga_Amonestaciones.sql` | Bloque `#EquivalenciaArbitros` (`I. Barton → Iván Barton`, `Clement Turpin → Clément Turpin`) y resolución de técnicos (`IdTecnico`). |
| `Importacion/20_Importacion_Carga_Publicidad.sql` | `SELECT Fila, Anunciante, Titulo, Descripcion, IdIdioma` en `crsCampania`, `FETCH ... INTO ..., @idIdioma` (inicial y dentro del loop) y `SET @idCampania = NULL; SET @idPublicidad = NULL;` al inicio de cada fila. |
| `Importacion/21_Importacion_Carga_Tanda_Penales.sql` | D6a: ejecutante en banco sin ingreso → `Omitida`. D6b: resto → `Error`. Reporte de FASE 2 incluye `'Omitida'`. |
| `Importacion/23_Importacion_Carga_Rojas_Directas.sql` | Bloque de normalización de árbitro (`#EquivalenciaArbitros`) copiado del 19. |
| `Importacion/21,22,23` | Rutas de **Fidel** activas (`C:\Users\Usuario\Documents\proyecto BDDA\...`), rutas de Santutu comentadas. |
| `Tablas/61_Sp_Trans_Jugador.sql` | `INSERT INTO equipos.Persona(Nombre, NombreHash, Fnac, Pais, Rol)` con `HASHBYTES('SHA2_256', @nombre)`. |
| `Tablas/62_Sp_Trans_Arbitro.sql` | Igual. |
| `Tablas/63_Sp_Trans_Tecnico.sql` | Igual. |
| `Importacion/00_Reparar_Hash_E8.sql` | Archivo nuevo presente (backfill de `NombreHash` + unificación de árbitros duplicados). |

## Fuentes (Datos/)

| Archivo | Valores que deben sobrevivir al merge |
|---|---|
| `Datos/equivalencias_selecciones.csv` | `R. D. del Congo,Congo DR` (con espacios) y `Croacia,Croatia`. |
| `Datos/equivalencias_equipos_jugadores.csv` | Deben estar las 48 filas, incluidas `Japan`, `Jordan`, `South Africa`, `Korea Republic`, `Spain`, `Sweden`, `Tunisia`. |
| `Datos/equivalencias_sedes_partidos.csv` | Deben estar `Levi's Stadium`, `Arrowhead Stadium (Kansas City)`, `BMO Field (Toronto)`, `AT&T Stadium` y la línea `Estadio Banorte,Estadio Azteca,Ciudad de México,Mexico` (con `é` real, no `?`). |
| `Datos/Jugadores/equivalencias_jugadores.csv` | 181 equivalencias, con comillas en la columna `criterio`. |

## Cómo verificar rápido (PowerShell, desde la raíz del repo)

```powershell
# Marcar todos los descifros
git grep -n "DECRYPTBYKEYAUTOCERT" -- Importacion

# Deteccion de CRLF en el lector compartido
git grep -n "0x0D0A" -- Importacion/XX_Lectura_Partidos_JSON.sql

# Hash en los SP de alta
git grep -n "NombreHash" -- Tablas/61_Sp_Trans_Jugador.sql Tablas/62_Sp_Trans_Arbitro.sql Tablas/63_Sp_Trans_Tecnico.sql

# Rutas activas del 21/22/23
git grep -n '^:setvar RutaAliasJugadores' -- Importacion/21_Importacion_Carga_Tanda_Penales.sql Importacion/22_Importacion_Carga_Goles_Penal.sql Importacion/23_Importacion_Carga_Rojas_Directas.sql

# CSVs
Select-String -Path Datos\equivalencias_selecciones.csv -Pattern "Congo|Croacia"
Select-String -Path Datos\equivalencias_equipos_jugadores.csv -Pattern "Japan|Jordan|South Africa|Korea Republic|Spain|Sweden|Tunisia"
Select-String -Path Datos\equivalencias_sedes_partidos.csv -Pattern "Banorte|Arrowhead|BMO Field|AT&T|Levi"
```

## Después del merge

1. Si hubo conflictos, resolverlos **conservando** los valores de arriba.
2. Si se reinstaló la base con los SP corregidos, no hace falta `00_Reparar_Hash_E8.sql`. Si la base ya tenía datos y se sigue usando, ejecutarlo antes de re-corre el 15/19/23.
3. Correr una pasada corta (14 → 16 → 17 → 19 → 20 → 21 → 22 → 23) para confirmar que no haya vuelto ninguno de los errores ya resueltos.
