# Metodología de importación en tres fases

Guía de referencia para los importadores de la Entrega 6.
**Grupo 7 – Bases de Datos Aplicadas (3641) – UNLaM – Comisión 02**
Integrantes: Almiron Luca, Figueroa Santiago, Ruarte Fidel, Villalba Leandro.

---

## 1. Qué es y por qué

Todo importador de la Entrega 6 sigue **el mismo esqueleto de tres fases**:

```
   FUENTE (archivo original, sin modificar)
        │
        ▼
   FASE 1 — STAGING      Se baja TODO a tablas temporales. No se descarta nada.
        │                #<Entidad>Crudo    = el archivo, tal cual llegó
        │                #<Entidad>Staging  = una fila por registro, con los
        │                                     campos del dominio + Estado + Detalle
        ▼
   FASE 2 — DEPURACIÓN   Reglas de conjunto (UPDATE) que marcan lo que se
        │                descarta y POR QUÉ. Nada se borra: las filas malas
        │                quedan con Estado='Error' o 'Duplicada'.
        │                → Se imprime el REPORTE de depuración antes de escribir.
        ▼
   FASE 3 — PERSISTENCIA Solo lo que quedó en Estado='Pendiente' pasa a la tabla
                         real, siempre a través de los SP de ABM de la Entrega 5
                         (SP.uspX_Registrar / SP.uspX_Update).
```

**Las tres reglas de oro:**

1. **El archivo fuente nunca se modifica.** Se lee crudo y se copia a una tabla
   temporal. Los `.py` solo descargan; nunca re-serializan la respuesta.
2. **La depuración es una fase propia, con reglas de conjunto.** No se valida
   fila por fila dentro del cursor de escritura: se resuelve todo con
   `UPDATE ... WHERE`, que es más rápido y produce un reporte claro.
3. **La persistencia solo escribe lo que ya pasó la depuración**, y lo hace
   llamando a los SP de la Entrega 5 (nunca `INSERT` directo sobre las tablas
   del modelo). Así las validaciones de la Entrega 5 (cupos, duplicados,
   existencia de FKs) siguen siendo la única puerta de entrada.

**Por qué importa en el coloquio:** una fila mala del archivo de origen no se
pierde: queda registrada en el reporte de depuración con su motivo y su línea
original, y el resto del archivo se carga completo. Eso es exactamente lo que
pide la consigna ("importación parcial de registros válidos").

---

## 2. Anatomía de un importador

### 2.1 Cabecera y rutas

```sql
-- Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Comision 02
-- Grupo 7: Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
-- Fecha: dd/mm/aaaa.
-- Objetivo: ...
--   FASE 1 STAGING     : ...
--   FASE 2 DEPURACION  : ...
--   FASE 3 PERSISTENCIA : ...
-- SSMS: Consulta -> Modo SQLCMD. Ajustar las rutas del servidor SQL.
-- IMPORTANTE: cada integrante debe poner las rutas de su propia PC, porque
-- SQL Server lee los archivos desde el disco local del servidor.
-- :setvar RutaX "C:\ruta\proyecto\Datos\..."

:setvar RutaX "C:\ruta\de\esta\PC\Datos\..."
```

Las rutas **son por máquina**: cada integrante las cambia antes de ejecutar.

### 2.2 Tablas temporales

| Tabla | Contenido |
|---|---|
| `#<Entidad>Crudo` | El archivo original, byte a byte. Es el "acta" de lo que se recibió. |
| `#<Entidad>Texto` | (XML + CSV) Copia de los bytes en `VARCHAR` con collation UTF-8, para leer el texto de los CSV. |
| `#<Entidad>Staging` | Una fila por registro, con los campos del dominio y `Estado`/`Detalle`. |

Todas son tablas temporales de sesión (`#`), viven en `tempdb` y se borran solas
al cerrar la conexión. El script las dropea al final.

### 2.3 Columnas de control

```sql
Fila           INT IDENTITY(1,1) PRIMARY KEY,   -- correlativo interno
Archivo        NVARCHAR(100),                   -- de qué archivo salió la fila
NumeroLinea    INT,                             -- número de línea en el archivo
LineaOriginal  NVARCHAR(MAX),                   -- la línea tal cual llegó
Estado         VARCHAR(20) NOT NULL DEFAULT 'Pendiente',
Detalle        NVARCHAR(2048)                   -- por qué se descartó (si aplica)
```

### 2.4 Estados posibles

| Estado | Significado |
|---|---|
| `Pendiente` | Todavía no evaluada (o aprobada, lista para persistir). |
| `Insertada` | Se creó el registro en la tabla real. |
| `Actualizada` | El registro existía y cambió algo. |
| `SinCambios` | El registro existía y ya estaba igual. |
| `Duplicada` | La misma información ya había sido procesada. No es un error. |
| `Error` | Rechazada, con el motivo en `Detalle`. |

### 2.5 Códigos de error

| Código | Significado |
|---|---|
| `x0` | Error de ejecución (falta un SP, hay una transacción abierta, etc.). |
| `x1` | No se pudo leer un archivo. **No se modificó nada.** |
| `x2` | El archivo no tiene el formato esperado. **No se modificó nada.** |
| `x3` | Falló una fila durante la persistencia. **Las demás se conservaron.** |
| `x4` | Importación parcial: hubo filas rechazadas. **Las válidas se conservaron.** |

El `x4` **no es un fallo del script**: es el aviso de que hubo filas en `Error`.
El script igual terminó bien y todo lo válido quedó cargado.

---

## 3. Cómo ejecutar

1. En SSMS: **Consulta → Modo SQLCMD** (obligatorio: los `:setvar` y `:r` son
   comandos de SQLCMD, no T-SQL).
2. Conectarse a la base **MUNDIAL**.
3. Poner las rutas de tu PC.
4. Ejecutar.

**Los importadores son idempotentes**: se pueden correr las veces que haga
falta. La segunda corrida da `SinCambios` en lugar de `Insertada`.

### Verificación rápida

```sql
SELECT (SELECT COUNT(*) FROM equipos.Pais)       AS Paises,
       (SELECT COUNT(*) FROM equipos.Seleccion)   AS Selecciones,
       (SELECT COUNT(*) FROM equipos.Jugador)     AS Jugadores,
       (SELECT COUNT(*) FROM equipos.Club)        AS Clubes,
       (SELECT COUNT(*) FROM equipos.Tecnico)      AS Tecnicos,
       (SELECT COUNT(*) FROM arbitros.Arbitro)    AS Arbitros,
       (SELECT COUNT(*) FROM arbitros.Arbitraje)  AS Arbitrajes,
       (SELECT COUNT(*) FROM partidos.Partido)    AS Partidos,
       (SELECT COUNT(*) FROM partidos.Alineacion) AS Alineaciones,
       (SELECT COUNT(*) FROM partidos.Evento)      AS Eventos,
       (SELECT COUNT(*) FROM partidos.Gol)         AS Goles,
       (SELECT COUNT(*) FROM partidos.Amonestacion) AS Amonestaciones,
       (SELECT COUNT(*) FROM partidos.Sustitucion) AS Sustituciones;
```

---

## 4. Los importadores

### 4.1 Catálogos (01, 02, 03, 06b) — sin archivo externo

Están hardcodeados con `IF NOT EXISTS` + `EXEC SP...`: no hay nada que "bajar a
una tabla" ni que depurar. Se quedan como están.

### 4.2 Los que tienen archivo (04 a 12)

| # | Importador | Fuentes | Tablas destino |
|---|---|---|---|
| 04 | Husos horarios | `husos_horarios.json` (JSON, OpenTimezone) | `sedes.HusoHorario` |
| 05 | Idiomas | `pais_idioma.csv` (CSV) | `arbitros.Idioma` |
| 06 | Países | `selecciones_confederaciones.xml` (XML) + `pais_idioma.csv` + `pais_zona.csv` | `equipos.Pais` |
| 06b | Mundial | hardcodeado | `sedes.Mundial` |
| 07 | Selecciones | `selecciones_grupos.csv` + `equivalencias_selecciones.csv` + `selecciones_confederaciones.xml` | `equipos.Seleccion` |
| 08 | Sedes | `sedes.csv` + `equivalencias_ubicacion_sedes.csv` | `sedes.Sede` |
| 09 | Clubes | `jugadores.csv` (columna `club`) | `equipos.Club` |
| 10 | Jugadores | `jugadores.csv` + `equivalencias_jugadores.csv` + 104 JSON | `equipos.Persona`, `equipos.Jugador` |
| 11 | Partidos | 104 JSON + 3 CSV de equivalencias | `partidos.Partido` |
| 12 | PBI | API Banco Mundial (XML + CSV) | `equipos.Pais.PBI` |

Detalle de las reglas de depuración de cada uno: en la cabecera de cada script.

### 4.3 Importadores de datos deportivos (13 a 19) y lector compartido

Todos leen los **104 JSON de Promiedos** (`Datos/Datos_Partidos/partidos/`) y usan
un lector compartido, `Importacion/XX_Lectura_Partidos_JSON.sql`, que se incluye
con `:r $(RutaLecturaPartidos)`. El lector deja:

| Tabla | Contenido |
|---|---|
| `#ArchivosPartidos` | Los 104 JSON originales, sin modificar. |
| `#ErroresArchivos` | Los archivos ilegibles o con JSON inválido. |
| `#FasesPartidos` | Equivalencias tipo/valor → fase de la base. |
| `#EquiposPartidos` | Equivalencias equipo de Promiedos → país de la base. |
| `#SedesPartidos` | Equivalencias nombre_json → sede de la base. |
| `#AliasJugadores` | Equivalencias nombre_csv ↔ nombre_promiedos (del CSV de jugadores). |
| `#PartidosJson` | Una fila por JSON con el partido ya resuelto (Mundial 1, fase, Eq1, Eq2, sede). |

**El staging se arma siempre desde los JSON**, aunque el partido no se pueda
resolver: las filas que quedan sin partido aparecen en el reporte con el
motivo, en lugar de desaparecer.

| # | Importador | Qué carga | Tablas destino |
|---|---|---|---|
| 13 | Alineaciones | `lineups.teams[].starting[]` y `.bench[]` | `partidos.Alineacion` |
| 14 | Goles | eventos tipo 1 (gol) y 2 (en contra) | `partidos.Evento` + `partidos.Gol` |
| 15 | Amonestaciones | eventos tipo 4 (amarilla) y 6 (doble amarilla) | `partidos.Evento` + `partidos.Amonestacion` |
| 16 | Sustituciones | evento tipo 15 (`texts[0]` entra, `texts[1]` sale) | `partidos.Evento` + `partidos.Sustitucion` |
| 17 | Cuerpos técnicos | `lineups.teams[].staff[]` | `equipos.Tecnico` (+ `Persona`) |
| 18 | Designaciones | `game_info` → "Árbitro" | `arbitros.Arbitro` + `arbitros.Arbitraje` |
| 19 | Motivos | `Datos/motivos_sustitucion.csv` | `publicidad.Motivo` |

**Datos por defecto documentados.** La fuente Promiedos no trae la fecha de
nacimiento ni la nacionalidad de árbitros y técnicos, y el modelo las exige
(`NOT NULL`). Se cargan con `1900-01-01` y el país anfitrión (USA), y la
columna `DatoPorDefecto` del reporte lo deja explícito. Para el motivo de la
sustitución (que la fuente tampoco indica) se usa `'Táctica'` del catálogo de
la carga 19.

### 4.4 El marcador y la asistencia

**El marcador NO se carga en el importador de partidos.** El modelo de la
Entrega 5 lo modifica de una sola forma:

```sql
-- SP.uspPartido_Update
IF @GolesEq1 IS NOT NULL OR @GolesEq2 IS NOT NULL
SET @errores += 'El marcador se modifica mediante alta y baja de goles, no manualmente.';
```

Es decir: el marcador se arma **sumando los eventos de gol** (importador `14`,
que llama a `SPTRANS.uspGol_Registrar`). Por eso el orden importa: `14` va
después de `13` y `16`.

**La asistencia no viene en la fuente.** Los JSON de Promiedos traen en
`game_info` solo `Estadio`, `Capacidad`, `Árbitro` y `Arg TV`; no hay ningún
campo de asistencia/espectadores (0 coincidencias en los 104 archivos). Por eso
`Asistencia` queda en `NULL`. Si el grupo quiere tenerla, hay que obtenerla de
otra fuente (la capacidad del estadio es lo más cercano, pero no es lo mismo).

### 4.5 Idempotencia de los eventos

Los SP de alta de `Gol`, `Amonestacion` y `Sustitucion` **no validan
duplicados**: si se corre dos veces, duplican los eventos. Por eso los
importadores 14, 15 y 16 verifican antes de llamar al SP si el evento ya está
cargado (mismo partido, minuto, periodo y jugador) y en ese caso lo marcan
como `SinCambios` en lugar de insertar de nuevo.

### 4.6 Orden de ejecución de los importadores

El orden **no es libre**: los SP validan el estado del modelo.

```
00  Instalación de la Entrega 5
01  Grupos           →  02  Fases        →  03  Periodos
04  Husos            →  05  Idiomas      →  06  Países  →  06b  Mundial
07  Selecciones     →  08  Sedes        →  09  Clubes  →  10  Jugadores
11  Partidos         →  12  PBI
19  Motivos          →  13  Alineaciones →  16  Sustituciones
18  Arbitrajes       →  14  Goles        →  15  Amonestaciones →  17  Técnicos
```

Reglas que impone el modelo:

- El `09` (clubes) va **antes** del `10` (jugadores): el jugador se rechaza si
  su club no está cargado.
- El `16` (sustituciones) va **antes** del `14` y del `15`: el SP de
  sustituciones rechaza el alta si el partido ya tiene eventos posteriores
  registrados.
- El `15` (amonestaciones) necesita el `18` (árbitros): el árbitro del partido
  es obligatorio.
- El `14` (goles) necesita el `13` (alineaciones): el SP exige que el autor
  esté en cancha.
- Dentro del `16`, el cursor ordena por `IdPartido, Minuto, Periodo`: el SP
  exige registrar los cambios en orden cronológico.

---

## 5. Cómo escribir un importador nuevo

1. **Cabecera y rutas** con el formato de la sección 2.1.
2. **Guardias**: sin transacción externa, `IMPLICIT_TRANSACTIONS` off, que
   existan las tablas y los SP de ABM.
3. **FASE 1**: crudo + staging, con una fila por registro.
4. **FASE 2**: un `UPDATE` por regla, cada uno con su mensaje. Al final, el
   reporte (`SELECT Estado, COUNT(*) ... GROUP BY Estado` + el detalle de las
   rechazadas) **antes** de la fase 3.
5. **FASE 3**: un cursor sobre `WHERE Estado='Pendiente'`, con `BEGIN TRY` /
   `BEGIN CATCH` por fila, que llama al SP de ABM.
6. **Cierre**: reporte final, `DROP TABLE` de las temporales, y el `THROW` del
   código `x4` si hubo filas en `Error`.

---

## 6. Aprendizajes técnicos (para no tropezar)

### 6.1 `sqlcmd` solo detecta UTF-8 si el archivo tiene BOM

Sin BOM, `sqlcmd` manda el archivo en la codepage de la consola y **los acentos
de los literales llegan corruptos al motor** (`N'Táctica'` se vuelve
`N'T?ctica'` y las comparaciones fallan).

**Solución:** construir los literales con `NCHAR()`, que no depende de la
codepage:

```sql
N'T'+NCHAR(225)+'ctica'      -- 'Táctica'
NCHAR(193)+'rbitro'           -- 'Árbitro'
N'Direcci'+NCHAR(243)+'n'     -- 'Dirección'
```

### 6.2 `BULK INSERT` no admite lista de columnas

```sql
-- NO compila (error 102)
BULK INSERT #t (Col1, Col2) FROM 'archivo.csv' WITH (FORMAT='CSV', ...);

-- Y sin lista exige que la tabla tenga EXACTAMENTE la misma cantidad de
-- columnas que el CSV (error 7301).
```

**Solución usada:** no se usa `BULK INSERT` para armar la staging. Se lee el
archivo crudo y se separa con `STRING_SPLIT`, que además da el número de
línea y el texto original. Beneficio extra: **una línea malformada no invalida
el archivo entero**, queda como `Error`.

### 6.3 `ROWTERMINATOR` tiene que coincidir con el fin de línea real

`0x0a` es LF y `0x0d0a` es CRLF. Si el archivo usa CRLF y se declara `0x0a`,
el `\r` queda pegado al último campo y rompe el parseo de los campos entre
comillas (`"Puntuacion, espacios o transliteracion"`). **Con `0x0d0a` funciona.**

### 6.4 Leer UTF-8

`CONVERT(NVARCHAR(MAX), @binario, 65001)` **no funciona**: el tercer
parámetro de `CONVERT` es *style*, no un code page, y devuelve `?` por byte.

**Solución:** guardar el crudo en `VARCHAR(MAX) COLLATE Latin1_General_100_CI_AS_SC_UTF8`
y convertir con `CONVERT(NVARCHAR(MAX), Contenido)`.

### 6.5 XML con declaración de encoding

Un XML con `<?xml version='1.0' encoding='utf-8'?>` **no se puede convertir
desde NVARCHAR** ("unable to switch the encoding"). Hay que convertirlo desde
los bytes: `CONVERT(XML, (SELECT Contenido FROM #Crudo))`.

### 6.6 `QUOTED_IDENTIFIER`

Las operaciones XML requieren `QUOTED_IDENTIFIER ON`. SSMS lo tiene por
defecto; **`sqlcmd` lo tiene OFF salvo que se pase el flag `-I`**.

### 6.7 `DATALENGTH` cuenta bytes, `LEN` cuenta caracteres

En una columna `NVARCHAR`, `DATALENGTH` devuelve el doble de los caracteres.
Para comparar contra el ancho de una columna `VARCHAR`, convertir primero:

```sql
DATALENGTH(CONVERT(VARCHAR(MAX), NVARCHARValue))   -- caracteres reales
```

Y el round-trip a `VARCHAR` solo corresponde si la columna **es** `VARCHAR`:
en una `NVARCHAR` no hay pérdida de caracteres, y el chequeo debe ser solo
`LEN(...) > ancho`.

### 6.8 `EXEC sp @parametro = CONVERT(...)` es error de sintaxis

El valor de un parámetro de `EXEC` debe ser constante o variable:

```sql
DECLARE @fnac DATE = CONVERT(DATE,'1900-01-01',23);   -- ok
EXEC SPTRANS.uspTecnico_Registrar @fnac=@fnac;        -- ok
EXEC SPTRANS.uspTecnico_Registrar @fnac=CONVERT(...); -- error 156
```

### 6.9 `SELECT @var = ...` no resetea la variable

Si la consulta no devuelve filas, **la variable conserva el valor anterior**:

```sql
SET @id = NULL;                       -- obligatorio
SELECT @id = IdMotivo FROM ... WHERE ...;
```

Sin ese `SET`, un `IdMotivo` de una iteración se reutiliza en la siguiente.

### 6.10 `UPDATE` no admite alias

`UPDATE s SET ...` es inválido; el objetivo es la tabla:

```sql
UPDATE #GolesStaging SET NombreAutorBd = ...
FROM #GolesStaging AS s JOIN ...        -- ok
```

### 6.11 Apóstrofos en literales

`''''` son **cuatro** apóstrofos = una cadena de **dos** caracteres. Para buscar
un apóstrofo conviene usar `NCHAR(39)`:

```sql
CASE WHEN CHARINDEX(NCHAR(39), @texto) > 0
     THEN LEFT(@texto, CHARINDEX(NCHAR(39), @texto)-1)
     ELSE @texto END
```

### 6.12 `COALESCE` en los `Update`

Los SP de ABM usan `COALESCE(@parametro, Columna)` para que un `NULL` en
parámetro signifique "no cambiar este campo". Por eso un importador puede
actualizar solo el `PBI` sin tocar el idioma, el huso ni el prime time.

---

## 7. Reglas del proyecto que se respetan

- Todo en **T-SQL**, sin CLR y sin SQL dinámico.
- La escritura en el modelo **siempre a través de los SP de la Entrega 5**.
- Los archivos fuente **no se modifican** antes de importar.
- Cada script lleva su cabecera con universidad, materia, integrantes y objetivo.
- Importación **idempotente**: se puede reejecutar sin duplicar ni romper.
- Importación **parcial**: las filas válidas se conservan aunque otras fallen.
