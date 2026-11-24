# Universidad Nacional de La Matanza
# Bases de Datos Aplicadas - Comision 02
# Grupo 7 - Almiron, Luca / Figueroa, Santiago / Ruarte, Fidel / Villalba, Leandro
# Entrega 9 - Aplicacion de gestion del Mundial (visor de datos).
#
# Backend minimo: Flask + pyodbc. Expone la informacion de la base MUNDIAL como JSON
# para la interfaz web (static/index.html). Por ahora es SOLO LECTURA.
# Las operaciones de alta/baja/modificacion se agregaran despues y deberan pasar
# unicamente por los stored procedures de la Entrega 5.
#
# Configuracion por variables de entorno (todas opcionales):
#   DB_SERVER   (por defecto  localhost\SQLEXPRESS)
#   DB_NAME     (por defecto  MUNDIAL)
#   DB_DRIVER   (por defecto  ODBC Driver 17 for SQL Server)
#   DB_USER / DB_PASSWORD  (si no se definen, usa autenticacion de Windows)

import datetime
import decimal
import os
import re
import time

import pyodbc
from flask import Flask, jsonify, request, send_from_directory
from werkzeug.utils import secure_filename

from abm_config import ABM, ROLES, EXCLUIR, SQL_SPS, OPCIONES

DB_SERVER = os.getenv("DB_SERVER", r"localhost\SQLEXPRESS")
DB_NAME = os.getenv("DB_NAME", "MUNDIAL")
DB_DRIVER = os.getenv("DB_DRIVER", "ODBC Driver 17 for SQL Server")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
MAX_FILAS = 10000
BASE = os.path.dirname(os.path.abspath(__file__))
# Carpeta con los scripts de importacion de la Entrega 6 (.sql) y carpeta donde se guardan,
# sin modificar, los archivos que se suben desde la pantalla de importacion.
RUTA_IMPORTADORES = os.getenv("RUTA_IMPORTADORES", os.path.join(BASE, "importadores"))
RUTA_SUBIDAS = os.getenv("RUTA_SUBIDAS", os.path.join(BASE, "subidas"))
LIMITE_FILAS_VISTA = 1000        # importacion
LIMITE_FILAS_REPORTE = 200000    # reportes: practicamente todas las filas

app = Flask(__name__, static_folder="static", static_url_path="/static")
app.config["MAX_CONTENT_LENGTH"] = 50 * 1024 * 1024
if hasattr(app, "json") and hasattr(app.json, "compact"):
    app.json.compact = True      # sin sangrias: respuestas mucho mas livianas
    app.json.sort_keys = False


def conectar(autocommit=False):
    cadena = f"DRIVER={{{DB_DRIVER}}};SERVER={DB_SERVER};DATABASE={DB_NAME};TrustServerCertificate=yes;"
    if DB_USER:
        cadena += f"UID={DB_USER};PWD={DB_PASSWORD};"
    else:
        cadena += "Trusted_Connection=yes;"
    return pyodbc.connect(cadena, timeout=5, autocommit=autocommit)


def formatear(valor):
    """Convierte tipos de SQL Server a algo serializable en JSON."""
    if isinstance(valor, datetime.datetime):
        return valor.isoformat(sep=" ", timespec="minutes")
    if isinstance(valor, datetime.date):
        return valor.isoformat()
    if isinstance(valor, datetime.time):
        return valor.strftime("%H:%M")
    if isinstance(valor, decimal.Decimal):
        return float(valor)
    if isinstance(valor, (bytes, bytearray)):
        return valor.hex()
    return valor


def consultar(sql, params=()):
    """Ejecuta un SELECT y devuelve {columns: [...], rows: [[...], ...]}."""
    with conectar() as cn:
        cur = cn.cursor()
        cur.execute(sql, *params)
        columnas = [c[0] for c in cur.description]
        filas = [[formatear(v) for v in f] for f in cur.fetchmany(MAX_FILAS)]
    return {"columns": columnas, "rows": filas}


def consultar_varias(consultas):
    """Ejecuta varios SELECT en UNA sola conexion. {nombre: sql} -> {nombre: [dict, ...]}."""
    salida = {}
    cn = conectar()
    try:
        cur = cn.cursor()
        for nombre, sql in consultas.items():
            cur.execute(sql)
            cols = [c[0] for c in cur.description]
            salida[nombre] = [dict(zip(cols, [formatear(v) for v in f])) for f in cur.fetchmany(MAX_FILAS)]
    finally:
        cn.close()
    return salida


# --------------------------------------------------------------------------
# Fragmento reutilizable: datos de las dos selecciones de un partido (alias P)
# --------------------------------------------------------------------------
_EQUIPOS = """
    JOIN equipos.Seleccion S1 ON S1.IdSeleccion = P.Eq1
    JOIN equipos.Pais PA1 ON PA1.IdPais = S1.IdPais
    JOIN equipos.Seleccion S2 ON S2.IdSeleccion = P.Eq2
    JOIN equipos.Pais PA2 ON PA2.IdPais = S2.IdPais
"""
_ETIQUETA = "CONCAT(PA1.NOMBRE, ' vs ', PA2.NOMBRE)"

DATASETS = {
    "partidos": f"""
        SELECT P.IdPartido AS [N°], F.Descripcion AS [Fase], P.Fecha AS [Fecha],
               P.HoraLocal AS [Hora local], P.HoraUTC AS [Hora UTC],
               SE.Nombre AS [Sede], PA1.NOMBRE AS [Equipo 1],
               CONCAT(P.GolesEq1, ' - ', P.GolesEq2,
                      CASE WHEN P.PenalesEq1 IS NOT NULL
                           THEN CONCAT(' (', P.PenalesEq1, '-', P.PenalesEq2, ' pen.)') ELSE '' END) AS [Resultado],
               PA2.NOMBRE AS [Equipo 2], P.Asistencia AS [Asistencia]
        FROM partidos.Partido P
        JOIN partidos.Fase F ON F.IdFase = P.IdFase
        JOIN sedes.Sede SE ON SE.IdSede = P.IdSede
        {_EQUIPOS}
        ORDER BY P.Fecha, P.HoraUTC, P.IdPartido""",
    "selecciones": """
        SELECT S.IdSeleccion AS [ID], P.NOMBRE AS [País], G.NOMBRE AS [Grupo],
               S.CONFEDERACION AS [Confederación],
               (SELECT COUNT(*) FROM equipos.Jugador J WHERE J.Seleccion = S.IdSeleccion) AS [Convocados],
               (SELECT COUNT(*) FROM equipos.Tecnico T WHERE T.Seleccion = S.IdSeleccion) AS [Cuerpo técnico]
        FROM equipos.Seleccion S
        JOIN equipos.Pais P ON P.IdPais = S.IdPais
        JOIN equipos.Grupo G ON G.IdGrupo = S.IdGrupo
        ORDER BY G.NOMBRE, P.NOMBRE""",
    "jugadores": """
        SELECT J.IdJugador AS [ID], PE.Nombre AS [Nombre], PA.NOMBRE AS [Selección],
               J.Numero AS [Dorsal], J.Posicion AS [Posición], ISNULL(C.Nombre, N'—') AS [Club],
               PE.Fnac AS [Fecha nac.], J.Estado AS [Estado], J.TarjetasAcum AS [Tarjetas acum.]
        FROM equipos.Jugador J
        JOIN equipos.Persona PE ON PE.IdPersona = J.IdJugador
        JOIN equipos.Seleccion S ON S.IdSeleccion = J.Seleccion
        JOIN equipos.Pais PA ON PA.IdPais = S.IdPais
        LEFT JOIN equipos.Club C ON C.IdClub = J.Club
        ORDER BY PA.NOMBRE, J.Numero""",
    "tecnicos": """
        SELECT T.IdTecnico AS [ID], PE.Nombre AS [Nombre], T.Funcion AS [Función],
               PA.NOMBRE AS [Selección], T.Estado AS [Estado], T.TarjetasAcum AS [Tarjetas acum.]
        FROM equipos.Tecnico T
        JOIN equipos.Persona PE ON PE.IdPersona = T.IdTecnico
        JOIN equipos.Seleccion S ON S.IdSeleccion = T.Seleccion
        JOIN equipos.Pais PA ON PA.IdPais = S.IdPais
        ORDER BY PA.NOMBRE, T.Funcion""",
    "sedes": """
        SELECT S.IdSede AS [ID], S.Nombre AS [Estadio], S.Ciudad AS [Ciudad], PA.NOMBRE AS [País],
               S.Capacidad AS [Capacidad], H.Nombre AS [Huso horario]
        FROM sedes.Sede S
        JOIN equipos.Pais PA ON PA.IdPais = S.IdPais
        JOIN sedes.HusoHorario H ON H.IdHuso = S.IdHuso
        ORDER BY PA.NOMBRE, S.Ciudad""",
    "arbitros": """
        SELECT A.IdArbitro AS [ID], PE.Nombre AS [Nombre], PA.NOMBRE AS [País], A.Categoria AS [Categoría],
               ISNULL((SELECT STRING_AGG(I.Descripcion, ', ')
                       FROM arbitros.HablaIdioma HI
                       JOIN arbitros.Idioma I ON I.IdIdioma = HI.Idioma
                       WHERE HI.Arbitro = A.IdArbitro), N'—') AS [Idiomas],
               (SELECT COUNT(*) FROM arbitros.Arbitraje AJ WHERE AJ.Arbitro = A.IdArbitro) AS [Designaciones]
        FROM arbitros.Arbitro A
        JOIN equipos.Persona PE ON PE.IdPersona = A.IdArbitro
        JOIN equipos.Pais PA ON PA.IdPais = PE.Pais
        ORDER BY PE.Nombre""",
    "goles": f"""
        SELECT G.IdGol AS [ID], P.IdPartido AS [Partido N°], {_ETIQUETA} AS [Partido],
               E.Minuto AS [Minuto], PER.Descripcion AS [Período], AU.Nombre AS [Autor],
               PAA.NOMBRE AS [Selección], ISNULL(ASI.Nombre, N'—') AS [Asistencia], G.Tipo AS [Tipo]
        FROM partidos.Gol G
        JOIN partidos.Evento E ON E.IdEvento = G.IdGol
        JOIN partidos.Periodo PER ON PER.IdPeriodo = E.Periodo
        JOIN partidos.Partido P ON P.IdPartido = E.Partido
        {_EQUIPOS}
        JOIN equipos.Persona AU ON AU.IdPersona = G.Autor
        JOIN equipos.Jugador JA ON JA.IdJugador = G.Autor
        JOIN equipos.Seleccion SA ON SA.IdSeleccion = JA.Seleccion
        JOIN equipos.Pais PAA ON PAA.IdPais = SA.IdPais
        LEFT JOIN equipos.Persona ASI ON ASI.IdPersona = G.Asistencia
        ORDER BY P.Fecha, P.IdPartido, PER.IdPeriodo, E.Minuto""",
    "tarjetas": f"""
        SELECT A.IdAmonestacion AS [ID], P.IdPartido AS [Partido N°], {_ETIQUETA} AS [Partido],
               E.Minuto AS [Minuto], PE.Nombre AS [Amonestado], PE.Rol AS [Rol],
               PAS.NOMBRE AS [Selección], A.Tarjeta AS [Tarjeta], A.Motivo AS [Motivo],
               AR.Nombre AS [Árbitro]
        FROM partidos.Amonestacion A
        JOIN partidos.Evento E ON E.IdEvento = A.IdAmonestacion
        JOIN partidos.Partido P ON P.IdPartido = E.Partido
        {_EQUIPOS}
        JOIN equipos.Persona PE ON PE.IdPersona = A.Amonestado
        JOIN equipos.Persona AR ON AR.IdPersona = A.Arbitro
        LEFT JOIN equipos.Jugador JU ON JU.IdJugador = A.Amonestado
        LEFT JOIN equipos.Tecnico TE ON TE.IdTecnico = A.Amonestado
        LEFT JOIN equipos.Seleccion SS ON SS.IdSeleccion = COALESCE(JU.Seleccion, TE.Seleccion)
        LEFT JOIN equipos.Pais PAS ON PAS.IdPais = SS.IdPais
        ORDER BY P.Fecha, P.IdPartido, E.Minuto""",
    "cambios": f"""
        SELECT X.IdSustitucion AS [ID], P.IdPartido AS [Partido N°], {_ETIQUETA} AS [Partido],
               E.Minuto AS [Minuto], PAI.NOMBRE AS [Selección], PS.Nombre AS [Sale],
               PI_.Nombre AS [Entra], M.Descripcion AS [Motivo]
        FROM partidos.Sustitucion X
        JOIN partidos.Evento E ON E.IdEvento = X.IdSustitucion
        JOIN partidos.Partido P ON P.IdPartido = E.Partido
        {_EQUIPOS}
        JOIN equipos.Persona PS ON PS.IdPersona = X.Egreso
        JOIN equipos.Persona PI_ ON PI_.IdPersona = X.Ingreso
        JOIN equipos.Jugador JI ON JI.IdJugador = X.Ingreso
        JOIN equipos.Seleccion SI ON SI.IdSeleccion = JI.Seleccion
        JOIN equipos.Pais PAI ON PAI.IdPais = SI.IdPais
        JOIN publicidad.Motivo M ON M.IdMotivo = X.Motivo
        ORDER BY P.Fecha, P.IdPartido, E.Minuto""",
    "publicidad": f"""
        SELECT H.IdHistorial AS [ID], P.IdPartido AS [Partido N°], {_ETIQUETA} AS [Partido],
               SE.Nombre AS [Sede], EP.Numero AS [Espacio], PU.Nombre AS [Publicidad],
               C.Nombre AS [Campaña],
               ISNULL((SELECT STRING_AGG(AN.Nombre, ', ')
                       FROM publicidad.AnuncianteCampania AC
                       JOIN publicidad.Anunciante AN ON AN.IdAnunciante = AC.IdAnunciante
                       WHERE AC.IdCampania = C.IdCampania), N'—') AS [Anunciante],
               H.CostoFinal AS [Costo final]
        FROM publicidad.HistorialPublicidad H
        JOIN partidos.Partido P ON P.IdPartido = H.IdPartido
        {_EQUIPOS}
        JOIN publicidad.EspacioPublicitario EP ON EP.IdEP = H.IdEP
        JOIN sedes.Sede SE ON SE.IdSede = EP.IdSede
        JOIN publicidad.Publicidad PU ON PU.IdPublicidad = H.IdPublicidad
        JOIN publicidad.Campania C ON C.IdCampania = PU.IdCampania
        ORDER BY P.Fecha, P.IdPartido, EP.Numero""",
}

RESUMEN_KPIS = """
    SELECT
      (SELECT COUNT(*) FROM partidos.Partido)       AS partidos,
      (SELECT COUNT(*) FROM equipos.Seleccion)      AS selecciones,
      (SELECT COUNT(*) FROM equipos.Jugador)        AS jugadores,
      (SELECT COUNT(*) FROM sedes.Sede)             AS sedes,
      (SELECT COUNT(*) FROM arbitros.Arbitro)       AS arbitros,
      (SELECT COUNT(*) FROM partidos.Gol)           AS goles,
      (SELECT COUNT(*) FROM partidos.Amonestacion WHERE Tarjeta LIKE 'A%') AS amarillas,
      (SELECT COUNT(*) FROM partidos.Amonestacion WHERE Tarjeta LIKE 'R%') AS rojas,
      (SELECT ISNULL(SUM(CostoFinal), 0) FROM publicidad.HistorialPublicidad) AS ingresos"""

RESUMEN_GRAFICOS = {
    "goleadores": """
        SELECT TOP 8 PE.Nombre AS etiqueta, COUNT(*) AS valor
        FROM partidos.Gol G
        JOIN equipos.Persona PE ON PE.IdPersona = G.Autor
        WHERE G.Tipo <> 'En contra'
        GROUP BY PE.IdPersona, PE.Nombre
        ORDER BY COUNT(*) DESC, PE.Nombre""",
    "tarjetas": """
        SELECT TOP 8 PA.NOMBRE AS etiqueta,
               SUM(CASE WHEN A.Tarjeta LIKE 'A%' THEN 1 ELSE 0 END) AS amarillas,
               SUM(CASE WHEN A.Tarjeta LIKE 'R%' THEN 1 ELSE 0 END) AS rojas
        FROM partidos.Amonestacion A
        JOIN equipos.Jugador J ON J.IdJugador = A.Amonestado
        JOIN equipos.Seleccion S ON S.IdSeleccion = J.Seleccion
        JOIN equipos.Pais PA ON PA.IdPais = S.IdPais
        GROUP BY PA.IdPais, PA.NOMBRE
        ORDER BY COUNT(*) DESC, PA.NOMBRE""",
    "ingresos": """
        SELECT TOP 8 SE.Nombre AS etiqueta, SUM(H.CostoFinal) AS valor
        FROM publicidad.HistorialPublicidad H
        JOIN publicidad.EspacioPublicitario EP ON EP.IdEP = H.IdEP
        JOIN sedes.Sede SE ON SE.IdSede = EP.IdSede
        GROUP BY SE.IdSede, SE.Nombre
        ORDER BY SUM(H.CostoFinal) DESC""",
    "fases": """
        SELECT F.Descripcion AS etiqueta, COUNT(*) AS valor
        FROM partidos.Partido P
        JOIN partidos.Fase F ON F.IdFase = P.IdFase
        GROUP BY F.IdFase, F.Descripcion
        ORDER BY F.IdFase""",
}


def _como_dicts(res):
    return [dict(zip(res["columns"], f)) for f in res["rows"]]


# ==========================================================================
# ABM (alta / baja / modificacion) - SIEMPRE a traves de los stored procedures
# de la Entrega 5: la aplicacion nunca hace INSERT/UPDATE/DELETE sobre las tablas.
#
# La descripcion de cada tabla administrable (columnas, formulario, claves y SP)
# vive en abm_config.py. Si un SP no se detecta por nombre, se fija a mano con
# "sps_manual": {"alta": "esquema.NombreSP", ...}; tambien admite una lista de
# SP cuando la modificacion se reparte en dos procedimientos.
# ==========================================================================


class ErrorApi(Exception):
    """Error pensado para mostrarse tal cual en la interfaz."""


def limpiar_texto(msg):
    """Saca los prefijos del driver ODBC y el codigo final: deja solo el mensaje del SP."""
    msg = re.sub(r"^(\[[^\]]*\]\s*)+", "", str(msg))
    msg = re.sub(r"\s*\(\d+\)(\s*\(SQL\w+\))?\s*$", "", msg)
    return msg.strip()


def limpiar_error(exc):
    return limpiar_texto(exc.args[-1] if exc.args else str(exc))


def _norm(s):
    return re.sub(r"[@_\s]", "", str(s)).lower()


def _leer_sps(patron):
    sps = {}
    for f in _como_dicts(consultar(SQL_SPS, (patron,))):
        sp = sps.setdefault((f["esquema"], f["sp"]),
                            {"esquema": f["esquema"], "nombre": f["sp"], "params": []})
        if f["param"]:
            sp["params"].append({"param": f["param"], "salida": bool(f["salida"]),
                                 "tipo": f["tipo"], "largo": f["largo"]})
    return sps


def _sp_ref(ref):
    """Busca un SP por 'esquema.nombre' y devuelve su metadata."""
    esq, nom = ref.split(".", 1)
    return _leer_sps(nom).get((esq, nom))


_CACHE_SPS = {}
TTL_SPS = 120   # segundos; los SP casi no cambian, no hace falta consultarlos en cada pedido


def detectar_sps(cfg):
    """Igual que _detectar_sps pero recuerda el resultado TTL_SPS segundos."""
    clave = (cfg.get("buscar_sp"), repr(cfg.get("sps_manual")))
    hit = _CACHE_SPS.get(clave)
    if hit and time.time() - hit[0] < TTL_SPS:
        return hit[1]
    res = _detectar_sps(cfg)
    _CACHE_SPS[clave] = (time.time(), res)
    return res


def _detectar_sps(cfg):
    """Devuelve {'alta': sp|[sp]|None, ..., 'todos': [...]}.

    Un rol con lista de SP significa que la operación se reparte en varios
    procedimientos (por ejemplo Jugador = datos + club, o Amonestación =
    tiempo + motivo).
    """
    candidatos = _leer_sps(f"%{cfg['buscar_sp']}%") if cfg.get("buscar_sp") else {}
    manual = cfg.get("sps_manual", {})
    todos = {f"{e}.{n}" for e, n in candidatos}
    res = {}
    for rol, patron in ROLES.items():
        if rol in manual:
            refs = manual[rol] if isinstance(manual[rol], list) else [manual[rol]]
            encontrados = []
            for ref in refs:
                sp = _sp_ref(ref)
                if sp:
                    encontrados.append(sp)
                    todos.add(f"{sp['esquema']}.{sp['nombre']}")
            res[rol] = encontrados if isinstance(manual[rol], list) else (encontrados[0] if encontrados else None)
            continue
        validos = [sp for sp in candidatos.values()
                   if re.search(patron, sp["nombre"], re.I) and not re.search(EXCLUIR, sp["nombre"], re.I)]
        res[rol] = min(validos, key=lambda sp: len(sp["nombre"])) if validos else None
    res["todos"] = sorted(todos)
    return res


def _tipo_sql(p):
    t, largo = p["tipo"], p["largo"]
    if t in ("varchar", "char", "varbinary", "binary"):
        return f"{t}({'MAX' if largo == -1 else largo})"
    if t in ("nvarchar", "nchar"):
        return f"{t}({'MAX' if largo == -1 else largo // 2})"
    return t


def _pk_cols(cfg):
    return [cfg["pk"]] if isinstance(cfg["pk"], str) else list(cfg["pk"])


def _campo_aplica(c, modo):
    if modo == "alta":
        return not c.get("solo_edicion")
    if modo == "modificacion":
        return not c.get("solo_alta")
    return True


def armar_llamada(sp, cfg, valores, pk, modo):
    """Arma el EXEC con parametros nombrados, emparejando por nombre de parametro.

    "pk" es un diccionario columna -> valor para bajas y modificaciones; en un
    alta puede ser None (la clave la genera el SP o la carga el formulario).
    """
    cols = _pk_cols(cfg)
    pk_por_norm = {_norm(c): c for c in cols}
    campos = {c["clave"]: c for c in cfg["campos"]}
    alias = {c["clave"]: {_norm(c["clave"])} | {_norm(a) for a in c.get("alias", [])}
             for c in cfg["campos"]}
    sin_valor = object()
    decl, partes, args, salidas = [], [], [], []
    for p in sp["params"]:
        n = _norm(p["param"])
        if p["salida"]:
            var = "@o_" + n
            decl.append(f"DECLARE {var} {_tipo_sql(p)};")
            partes.append(f"{p['param']} = {var} OUTPUT")
            salidas.append(var)
            continue

        valor = sin_valor
        if n in pk_por_norm:
            col = pk_por_norm[n]
            if pk is not None:
                valor = pk.get(col)
            elif cfg.get("pk_editable"):
                valor = valores.get(col)

        # Varios SP de la Entrega 5 reciben la clave como "@id" aunque la columna
        # se llame IdPais, IdJugador, etc. Si la entidad tiene una sola PK, ese
        # parametro es la clave del registro.
        if valor is sin_valor and n == "id" and len(cols) == 1:
            col = cols[0]
            if pk is not None:
                valor = pk.get(col)
            elif cfg.get("pk_editable"):
                valor = valores.get(col)

        if valor is sin_valor:
            clave = next((k for k, a in alias.items() if n in a), None)
            if clave is None:
                continue  # parametro desconocido: se omite (el SP usa su valor por defecto)
            if not _campo_aplica(campos[clave], modo):
                continue
            valor = valores.get(clave)

        partes.append(f"{p['param']} = ?")
        args.append(valor)
    if not partes:
        raise ErrorApi(f"El procedimiento {sp['esquema']}.{sp['nombre']} no tiene parámetros compatibles.")
    sql = "SET NOCOUNT ON; " + " ".join(decl) + f" EXEC [{sp['esquema']}].[{sp['nombre']}] " + ", ".join(partes) + ";"
    if salidas:
        sql += " SELECT " + ", ".join(salidas) + ";"
    return sql, args


def ejecutar_sp(sps, cfg, valores, pk, modo):
    """Ejecuta uno o varios SP en una misma conexión y devuelve mensajes/salidas."""
    if not isinstance(sps, list):
        sps = [sps]
    cn = conectar()
    mensajes, salida = [], []
    try:
        for sp in sps:
            sql, args = armar_llamada(sp, cfg, valores, pk, modo)
            cur = cn.cursor()
            try:
                cur.execute(sql, *args)
                while True:  # recorrer todos los resultados para que afloren los errores del SP
                    if cur.description:
                        for fila in cur.fetchall():
                            salida += [str(formatear(x)) for x in fila if x is not None]
                    if not cur.nextset():
                        break
                mensajes += [limpiar_texto(m[1]) for m in (getattr(cur, "messages", None) or [])]
            except pyodbc.Error as exc:
                cn.rollback()
                raise ErrorApi(limpiar_error(exc)) from exc
        cn.commit()
    finally:
        cn.close()
    return {"ok": True, "mensajes": [m for m in mensajes if m], "salida": salida}


def _err(errores, texto):
    if texto not in errores:
        errores.append(texto)


def _validar_reglas(cfg, v):
    """Reglas de conjunto visibles en el formulario. El SP sigue siendo la autoridad."""
    errores = []
    reglas = cfg.get("reglas", [])

    if "primetime" in reglas and v.get("PtIni") and v.get("PtFin") and v["PtFin"] <= v["PtIni"]:
        _err(errores, "El fin del prime time debe ser posterior al inicio.")
    if "periodo" in reglas:
        if v.get("EsPenales") == 1:
            if v.get("Inicio") is not None or v.get("Fin") is not None:
                _err(errores, "En la tanda de penales, inicio y fin deben quedar vacíos.")
        else:
            if v.get("Inicio") is None or v.get("Fin") is None:
                _err(errores, "El inicio y el fin son obligatorios salvo en la tanda de penales.")
            elif v["Fin"] < v["Inicio"]:
                _err(errores, "El fin del período no puede ser menor al inicio.")
    if "fechas" in reglas and v.get("FechaInicio") and v.get("FechaFin") and v["FechaFin"] < v["FechaInicio"]:
        _err(errores, "La fecha de fin no puede ser anterior a la de inicio.")
    if "tamanios" in reglas and v.get("TamMin") is not None and v.get("TamMax") is not None \
            and v["TamMin"] > v["TamMax"]:
        _err(errores, "El mínimo de convocados no puede superar al máximo.")
    if "equipos" in reglas and v.get("Eq1") is not None and v.get("Eq1") == v.get("Eq2"):
        _err(errores, "Los dos equipos del partido deben ser distintos.")
    if "gol" in reglas:
        if v.get("Asistencia") is not None and v.get("Asistencia") == v.get("Autor"):
            _err(errores, "El autor y el asistente deben ser jugadores distintos.")
        if v.get("Tipo") == "En contra" and v.get("Asistencia") is not None:
            _err(errores, "Un gol en contra no lleva asistencia.")
    if "sustitucion" in reglas and v.get("Ingreso") is not None and v.get("Ingreso") == v.get("Egreso"):
        _err(errores, "El jugador que ingresa y el que sale deben ser distintos.")
    if "cambio" in reglas and v.get("Ingreso") is not None and v.get("Ingreso") == v.get("Egreso"):
        _err(errores, "El jugador que ingresa y el que sale deben ser distintos.")
    if "nacimiento" in reglas and v.get("Fnac") and v["Fnac"] > datetime.date.today():
        _err(errores, "La fecha de nacimiento no puede ser futura.")
    return errores


def _preparar(cfg, datos, modo):
    """Convierte tipos y valida formato. Las reglas de negocio las valida el SP."""
    valores, errores = {}, []
    for c in cfg["campos"]:
        if not _campo_aplica(c, modo):
            continue
        clave, tipo = c["clave"], c.get("tipo", "texto")
        bruto = datos.get(clave)
        if tipo == "booleano":
            valores[clave] = 1 if bruto in (True, 1, "1", "true", "on", "True") else 0
            continue
        if isinstance(bruto, str):
            bruto = bruto.strip()
        if bruto is None or bruto == "":
            if c.get("obligatorio"):
                errores.append(f"{c['etiqueta']} es obligatorio.")
            valores[clave] = None
            continue
        try:
            if tipo in ("texto", "texto_largo", "lista_texto"):
                valor = str(bruto)
                if c.get("max") and len(valor) > c["max"]:
                    raise ValueError(f"no puede superar los {c['max']} caracteres")
            elif tipo in ("numero", "lista"):
                valor = int(bruto)
            elif tipo == "decimal":
                valor = decimal.Decimal(str(bruto))
            elif tipo == "fecha":
                valor = datetime.date.fromisoformat(str(bruto)[:10])
            elif tipo == "hora":
                valor = datetime.time.fromisoformat(str(bruto))
            else:
                valor = bruto
            if tipo in ("numero", "decimal"):
                if c.get("min") is not None and valor < c["min"]:
                    raise ValueError(f"debe ser mayor o igual a {c['min']}")
                if c.get("max") is not None and valor > c["max"]:
                    raise ValueError(f"debe ser menor o igual a {c['max']}")
        except (TypeError, ValueError, decimal.InvalidOperation) as exc:
            errores.append(f"{c['etiqueta']}: {exc}.")
            continue
        valores[clave] = valor
    if not errores:
        errores = _validar_reglas(cfg, valores)
    if errores:
        raise ErrorApi("\n".join(errores))
    return valores


def _cfg(nombre):
    if nombre not in ABM:
        raise ErrorApi(f"ABM desconocido: {nombre}")
    return ABM[nombre]


def _sp_requerido(cfg, rol):
    sps = detectar_sps(cfg)
    sp = sps[rol]
    if not sp:
        todos = ", ".join(sps["todos"]) or "ninguno"
        raise ErrorApi(f"No se encontró el procedimiento de {rol} para {cfg['etiqueta']}. "
                       f"Procedimientos disponibles: {todos}.")
    return sp if isinstance(sp, list) else [sp]


def _parse_pk(cfg, texto):
    cols = _pk_cols(cfg)
    partes = str(texto).split("~")
    if len(partes) != len(cols):
        raise ErrorApi("Identificador de registro inválido.")
    valores = []
    for p in partes:
        try:
            valores.append(int(p))
        except (TypeError, ValueError):
            raise ErrorApi("Identificador de registro inválido.")
    return dict(zip(cols, valores))


@app.errorhandler(ErrorApi)
def _manejar_error_api(exc):
    return jsonify(error=str(exc)), 400


@app.errorhandler(pyodbc.Error)
def _manejar_error_odbc(exc):
    return jsonify(error=limpiar_error(exc)), 500

# ==========================================================================
# ROLES (Entrega 9): el frontend manda el rol elegido en el header X-Rol y
# aca se valida en TODOS los endpoints /api/*. Cada rol de la interfaz equivale
# a un rol de SQL Server del TP (Administrador -> rol_Administrador,
# Consulta -> rol_Consulta). Es un control de interfaz: el control real de
# permisos sobre los datos sigue siendo el de SQL Server.
#   consultar -> /api/datos, /api/resumen    abm -> /api/abm*
#   importar  -> /api/importar*              reportes -> /api/reportes*
# ==========================================================================
PUBLICIDAD = {"anunciantes", "campanias", "publicidades"}   # entidades ABM del Gestor de publicidad
ROL_PERMISOS = {
    # permisos: areas de la API; abm: entidades ABM permitidas (None = todas); baja: puede eliminar
    "Administrador":          {"permisos": {"consultar", "abm", "importar", "reportes"}, "abm": None, "baja": True},
    "Gestor de publicidad":   {"permisos": {"consultar", "abm", "reportes"}, "abm": PUBLICIDAD, "baja": False},
    "Cargador de resultados": {"permisos": {"consultar", "importar"}, "abm": set(), "baja": False},
    "Consulta":               {"permisos": {"consultar", "reportes"}, "abm": set(), "baja": False},
}


def _permiso_de_ruta(path):
    for prefijo, permiso in (("/api/abm", "abm"), ("/api/importar", "importar"), ("/api/reportes", "reportes")):
        if path == prefijo or path.startswith(prefijo + "/"):
            return permiso
    return "consultar"


def _rol_actual():
    return ROL_PERMISOS.get(request.headers.get("X-Rol", ""))


@app.before_request
def _controlar_rol():
    if not request.path.startswith("/api/"):
        return None
    rol = request.headers.get("X-Rol", "")
    cfg = ROL_PERMISOS.get(rol)
    if cfg is None:
        return jsonify(error="Sesión sin rol: elegí un usuario para continuar."), 401
    area = _permiso_de_ruta(request.path)
    if area not in cfg["permisos"]:
        return jsonify(error=f"El rol {rol} no tiene permiso para esta operación."), 403
    if area == "abm":
        partes = request.path.strip("/").split("/")          # api / abm / <entidad> / <pk>
        if len(partes) >= 3 and cfg["abm"] is not None and partes[2] not in cfg["abm"]:
            return jsonify(error=f"El rol {rol} no tiene acceso a esta entidad."), 403
        if request.method == "DELETE" and not cfg["baja"]:
            return jsonify(error=f"El rol {rol} no puede eliminar registros."), 403
    return None


@app.get("/api/abm")
def abm_lista():
    ok = _rol_actual()["abm"]
    return jsonify([{"id": k, "titulo": v["titulo"], "desc": v["desc"]} for k, v in ABM.items()
                    if ok is None or k in ok])


def _info_sp(x):
    if not x:
        return None
    if isinstance(x, list):
        return [_info_sp(sp) for sp in x]
    return {"nombre": f"{x['esquema']}.{x['nombre']}",
            "params": [p["param"] for p in x["params"]]}


@app.get("/api/abm/<nombre>")
def abm_datos(nombre):
    cfg = _cfg(nombre)
    consultas = {"__filas": cfg["base"] + " " + cfg["orden"]}
    for k in cfg.get("opciones", []):
        consultas[k] = OPCIONES[k]
    opciones = consultar_varias(consultas)
    filas = opciones.pop("__filas")
    sps = detectar_sps(cfg)
    info = {rol: _info_sp(sps[rol]) for rol in ROLES}
    return jsonify(titulo=cfg["titulo"], etiqueta=cfg["etiqueta"], pk=_pk_cols(cfg),
                   pk_editable=bool(cfg.get("pk_editable")), reglas=cfg.get("reglas", []),
                   columnas=[{"clave": k, "titulo": t} for k, t in cfg["columnas"]],
                   campos=cfg["campos"], opciones=opciones, filas=filas, sps=info, todos=sps["todos"])


@app.post("/api/abm/<nombre>")
def abm_alta(nombre):
    cfg = _cfg(nombre)
    datos = request.get_json(silent=True) or {}
    sps = _sp_requerido(cfg, "alta")
    valores = _preparar(cfg, datos, "alta")
    return jsonify(ejecutar_sp(sps, cfg, valores, None, "alta"))


@app.put("/api/abm/<nombre>/<pk>")
def abm_modificacion(nombre, pk):
    cfg = _cfg(nombre)
    datos = request.get_json(silent=True) or {}
    sps = _sp_requerido(cfg, "modificacion")
    valores = _preparar(cfg, datos, "modificacion")
    return jsonify(ejecutar_sp(sps, cfg, valores, _parse_pk(cfg, pk), "modificacion"))


@app.delete("/api/abm/<nombre>/<pk>")
def abm_baja(nombre, pk):
    cfg = _cfg(nombre)
    datos = request.get_json(silent=True) or {}
    sps = _sp_requerido(cfg, "baja")
    clave = _parse_pk(cfg, pk)
    fila = _como_dicts(consultar(cfg["base"] + " " + cfg["filtro_pk"],
                                 tuple(clave[c] for c in _pk_cols(cfg))))
    if not fila:
        raise ErrorApi("El registro ya no existe.")
    return jsonify(ejecutar_sp(sps, cfg, fila[0], clave, "baja"))


@app.post("/api/abm/partidos/<pk>/tanda")
def abm_partido_tanda(pk):
    """Tanda de penales de un partido: SP.uspPartido_Tanda(@IdPartido, @Iniciar bit).

    Los penales no se editan como un campo: los maneja este SP. 'iniciar' true/false
    se pasa tal cual como @Iniciar.
    """
    cfg = _cfg("partidos")
    idp = _parse_pk(cfg, pk)["IdPartido"]
    datos = request.get_json(silent=True) or {}
    iniciar = 1 if datos.get("iniciar") in (True, 1, "1", "true") else 0
    if not _sp_ref("SP.uspPartido_Tanda"):
        raise ErrorApi("No se encontró el procedimiento SP.uspPartido_Tanda.")
    cn = conectar()
    mensajes, salida = [], []
    try:
        cur = cn.cursor()
        try:
            cur.execute("SET NOCOUNT ON; EXEC [SP].[uspPartido_Tanda] @IdPartido = ?, @Iniciar = ?;", idp, iniciar)
            while True:
                if cur.description:
                    for fila in cur.fetchall():
                        salida += [str(formatear(x)) for x in fila if x is not None]
                if not cur.nextset():
                    break
            mensajes += [limpiar_texto(m[1]) for m in (getattr(cur, "messages", None) or [])]
        except pyodbc.Error as exc:
            cn.rollback()
            raise ErrorApi(limpiar_error(exc)) from exc
        cn.commit()
    finally:
        cn.close()
    return jsonify({"ok": True, "mensajes": [m for m in mensajes if m], "salida": salida})


# ==========================================================================
# IMPORTACION (Entrega 6) y REPORTES (Entrega 7)
#
# Importacion: se ejecuta el MISMO script .sql de la Entrega 6, sin tocarlo.
# Los scripts son para SSMS en modo SQLCMD (:setvar y $(Variable)); aca se quitan
# las lineas :setvar de cada integrante, se reemplaza $(Variable) por la ruta del
# archivo subido y se ejecuta lote por lote (separando por GO). El archivo se
# guarda tal cual llega (la Entrega 6 prohibe modificarlo antes de importarlo).
# ==========================================================================

IMPORTADORES = {
    "motivos": {
        "titulo": "Motivos de sustitución",
        "desc": "Catálogo de motivos de cambio (CSV)",
        "script": "13_Importacion_Carga_Motivos.sql",
        "archivos": [{"variable": "RutaMotivos", "etiqueta": "motivos_sustitucion.csv", "ext": [".csv"]}],
    },
    "pbi": {
        "titulo": "PBI por país",
        "desc": "API del Banco Mundial (XML) y equivalencias ISO3 (CSV)",
        "script": "12_Importacion_Carga_PBI_Pais.sql",
        "archivos": [{"variable": "RutaPBI", "etiqueta": "pbi_por_pais.xml", "ext": [".xml"]},
                     {"variable": "RutaEquiv", "etiqueta": "pais_iso3.csv", "ext": [".csv"]}],
    },
}

# Reportes de la Entrega 7. "xml": True si el SP devuelve un XML (FOR XML).
# "extra": parametros ademas de @mundial, con sus valores permitidos.
REPORTES = {
    "publicidad": {"titulo": "Ocupación publicitaria", "desc": "Anunciantes por sede y partido (XML)",
                   "sp": "SP.uspReporte_Publicidad"},
    "convocados": {"titulo": "Selecciones y plantillas", "desc": "Selecciones con sus convocados (XML)",
                   "sp": "SP.uspReporte_Convocados"},
    "goleadores": {"titulo": "Goleadores", "desc": "Por mundial, selección o fase",
                   "sp": "SP.uspReporte_Goleadores", "extra": {"categoria": ["Mundial", "Seleccion", "Fase"]}},
    "tarjetas": {"titulo": "Tarjetas", "desc": "Amarillas, rojas y suspensiones", "sp": "SP.uspReporte_Tarjetas"},
    "arbitraje": {"titulo": "Designaciones arbitrales", "desc": "Partidos dirigidos y sanciones",
                  "sp": "SP.uspReporte_Arbitraje"},
    "partidos": {"titulo": "Resultados", "desc": "Resultados de los encuentros", "sp": "SP.uspReporte_Partidos"},
    "primetime": {"titulo": "Pivot de prime time",
                  "desc": "Horarios de prime time por país (requiere Ole Automation Procedures habilitado en SQL Server)",
                  "sp": "SP.uspReporte_Primetime"},
    # --- Consultas (System to be). "campos" = parametros extra del SP; "sin_mundial" = el SP no recibe @mundial.
    # tipo "lista" usa OPCIONES[opciones] (el valor enviado es el id); tipo "numero" es un entero libre.
    "fixture": {"titulo": "Fixture", "desc": "Fixture del mundial filtrado por fase, sede, selección o fecha",
                "sp": "SP.uspFixture", "extra": {"categoria": ["Fase", "Sede", "Seleccion", "Fecha"]}},
    "titularidad": {"titulo": "Titularidad de un jugador", "desc": "Partidos en los que el jugador fue titular",
                    "sp": "SP.uspJugador_Titularidad",
                    "campos": [{"nombre": "jugador", "etiqueta": "Jugador", "tipo": "lista", "opciones": "jugadores_id"}]},
    "alineacion": {"titulo": "Equipo en cancha", "desc": "Alineación de una selección en un partido, a un minuto dado",
                   "sp": "SP.uspAlineacion_Actual", "sin_mundial": True,
                   "campos": [{"nombre": "partido", "etiqueta": "Partido", "tipo": "lista", "opciones": "partidos"},
                              {"nombre": "seleccion", "etiqueta": "Selección", "tipo": "lista", "opciones": "selecciones"},
                              {"nombre": "minuto", "etiqueta": "Minuto", "tipo": "numero"}]},
    "informes-arbitro": {"titulo": "Informes de un árbitro", "desc": "Informes post-partido de un árbitro",
                         "sp": "SP.uspArbitro_Informes",
                         "campos": [{"nombre": "arbitro", "etiqueta": "Árbitro", "tipo": "lista", "opciones": "arbitros_id"}]},
}


def _leer_texto(ruta):
    datos = open(ruta, "rb").read()
    if datos[:2] in (b"\xff\xfe", b"\xfe\xff"):
        return datos.decode("utf-16")
    try:
        return datos.decode("utf-8-sig")
    except UnicodeDecodeError:
        return datos.decode("cp1252")


def _lotes_sql(texto):
    """Separa el script en lotes por las lineas que solo dicen GO."""
    texto = texto.replace("\r\n", "\n").replace("\r", "\n")
    return [l.strip("\n") for l in re.split(r"^[ \t]*GO[ \t]*$", texto, flags=re.I | re.M) if l.strip()]


# Carpetas donde se busca el script .sql de cada importacion (en este orden).
CARPETAS_SCRIPTS = [RUTA_IMPORTADORES, BASE,
                    r"C:\Users\Administrator\Desktop\tp_bdda\TP-2026-2C-Mundial-de-Futbol\Importacion"]


def buscar_script(nombre):
    for carpeta in CARPETAS_SCRIPTS:
        ruta = os.path.join(carpeta, nombre)
        if os.path.isfile(ruta):
            return ruta
    return None


def preparar_script(cfg, rutas):
    ruta = buscar_script(cfg["script"])
    if not ruta:
        raise ErrorApi(f"No se encontró el script {cfg['script']}. Copialo a la carpeta {RUTA_IMPORTADORES} "
                       "(o definí la variable de entorno RUTA_IMPORTADORES).")
    texto = _leer_texto(ruta)
    texto = re.sub(r"^[ \t]*:setvar\b.*$", "", texto, flags=re.M)   # rutas fijas de cada integrante
    for variable, valor in rutas.items():
        texto = texto.replace(f"$({variable})", valor.replace("'", "''"))
    faltan = sorted(set(re.findall(r"\$\((\w+)\)", texto)))
    if faltan:
        raise ErrorApi("El script usa variables sin valor: " + ", ".join(faltan))
    return _lotes_sql(texto)


def _juntar_mensajes(cur, lista):
    for m in (getattr(cur, "messages", None) or []):
        t = limpiar_texto(m[1])
        if t and t not in lista:
            lista.append(t)


def ejecutar_lotes(lotes):
    """Ejecuta los lotes en una conexion con autocommit (los scripts manejan sus transacciones).

    Devuelve todos los resultados que mostro el script. Si un lote falla, se detiene y
    devuelve lo obtenido hasta ahi junto con el error (asi se ve una importacion parcial).
    """
    conjuntos, mensajes, error = [], [], None
    cn = conectar(autocommit=True)
    try:
        cur = cn.cursor()
        for lote in lotes:
            try:
                cur.execute(lote)
                while True:
                    _juntar_mensajes(cur, mensajes)
                    if cur.description:
                        cols = [c[0] for c in cur.description]
                        filas = cur.fetchall()
                        conjuntos.append({"columnas": cols, "total": len(filas),
                                          "filas": [[formatear(v) for v in f] for f in filas[:LIMITE_FILAS_VISTA]]})
                    if not cur.nextset():
                        break
                _juntar_mensajes(cur, mensajes)
            except pyodbc.Error as exc:
                error = limpiar_error(exc)
                break
    finally:
        cn.close()
    return conjuntos, mensajes, error


@app.get("/api/importar")
def importar_lista():
    return jsonify([{"id": k, "titulo": v["titulo"], "desc": v["desc"], "archivos": v["archivos"],
                     "script": v["script"], "carpeta": RUTA_IMPORTADORES,
                     "disponible": buscar_script(v["script"]) is not None}
                    for k, v in IMPORTADORES.items()])


@app.post("/api/importar/<nombre>")
def importar_ejecutar(nombre):
    cfg = IMPORTADORES.get(nombre)
    if not cfg:
        raise ErrorApi(f"Importación desconocida: {nombre}")
    os.makedirs(RUTA_SUBIDAS, exist_ok=True)
    rutas, marca = {}, time.strftime("%Y%m%d_%H%M%S")
    for a in cfg["archivos"]:
        f = request.files.get(a["variable"])
        if not f or not f.filename:
            raise ErrorApi(f"Falta el archivo: {a['etiqueta']}.")
        ext = os.path.splitext(f.filename)[1].lower()
        if ext not in a["ext"]:
            raise ErrorApi(f"{a['etiqueta']}: se esperaba un archivo {' / '.join(a['ext'])}.")
        nombre_seguro = secure_filename(f.filename) or ("archivo" + ext)
        destino = os.path.abspath(os.path.join(RUTA_SUBIDAS, f"{marca}_{nombre_seguro}"))
        f.save(destino)
        rutas[a["variable"]] = destino
    lotes = preparar_script(cfg, rutas)
    conjuntos, mensajes, error = ejecutar_lotes(lotes)
    return jsonify(conjuntos=conjuntos, mensajes=mensajes, aviso=error, fallo=bool(error) and not conjuntos,
                   archivos={k: os.path.basename(v) for k, v in rutas.items()})


@app.get("/api/reportes")
def reportes_lista():
    claves = sorted({c["opciones"] for v in REPORTES.values() for c in v.get("campos", []) if c.get("opciones")})
    datos = consultar_varias({"m": OPCIONES["mundiales"], **{k: OPCIONES[k] for k in claves}})
    mundiales = datos.pop("m")
    return jsonify(mundiales=mundiales, opciones=datos,
                   reportes=[{"id": k, "titulo": v["titulo"], "desc": v["desc"], "extra": v.get("extra", {}),
                              "campos": v.get("campos", []), "sin_mundial": bool(v.get("sin_mundial"))}
                             for k, v in REPORTES.items()])


@app.post("/api/reportes/<nombre>")
def reportes_ejecutar(nombre):
    cfg = REPORTES.get(nombre)
    if not cfg:
        raise ErrorApi(f"Reporte desconocido: {nombre}")
    datos = request.get_json(silent=True) or {}
    params = {}
    if not cfg.get("sin_mundial"):
        try:
            params["mundial"] = int(datos.get("mundial"))
        except (TypeError, ValueError):
            raise ErrorApi("Elegí un mundial.")
    for c in cfg.get("campos", []):
        try:
            params[c["nombre"]] = int(datos.get(c["nombre"]))
        except (TypeError, ValueError):
            raise ErrorApi(f"{c['etiqueta']}: ingresá un valor numérico válido.")
    for clave, permitidos in cfg.get("extra", {}).items():
        if datos.get(clave) not in permitidos:
            raise ErrorApi(f"Valor inválido para {clave}.")
        params[clave] = datos[clave]
    sql = f"EXEC {cfg['sp']} " + ", ".join(f"@{k} = ?" for k in params)
    conjuntos, mensajes, xml = [], [], None
    cn = conectar(autocommit=True)
    try:
        cur = cn.cursor()
        if cur.execute("SELECT OBJECT_ID(?)", cfg["sp"]).fetchone()[0] is None:
            raise ErrorApi(f"El procedimiento {cfg['sp']} no existe en la base {DB_NAME}. "
                           "Ejecutá 94_Sp_Reportes.sql (Entrega 7) sobre esa base y volvé a probar.")
        try:
            cur.execute(sql, *params.values())
        except pyodbc.Error as exc:
            msg = limpiar_error(exc)
            if "ole automation" in msg.lower():
                msg += (" — Habilitalo (como sysadmin): EXEC sp_configure 'show advanced options',1; RECONFIGURE; "
                        "EXEC sp_configure 'Ole Automation Procedures',1; RECONFIGURE;")
            raise ErrorApi(msg) from exc
        while True:
            _juntar_mensajes(cur, mensajes)
            if cur.description:
                cols = [c[0] for c in cur.description]
                filas = cur.fetchall()
                if len(cols) == 1 and cols[0].upper().startswith("XML_"):
                    xml = "".join(str(f[0]) for f in filas if f[0] is not None)   # FOR XML llega en trozos
                else:
                    conjuntos.append({"columnas": cols, "total": len(filas),
                                      "filas": [[formatear(v) for v in f] for f in filas[:LIMITE_FILAS_REPORTE]]})
            if not cur.nextset():
                break
        _juntar_mensajes(cur, mensajes)
    finally:
        cn.close()
    return jsonify(conjuntos=conjuntos, mensajes=mensajes, xml=xml)


@app.get("/")
def index():
    return send_from_directory(app.static_folder, "index.html")


@app.get("/api/datos/<nombre>")
def api_datos(nombre):
    sql = DATASETS.get(nombre)
    if sql is None:
        return jsonify(error=f"Vista desconocida: {nombre}"), 404
    try:
        return jsonify(consultar(sql))
    except Exception as exc:  # mensaje legible para mostrar en la interfaz
        return jsonify(error=str(exc)), 500


@app.get("/api/resumen")
def api_resumen():
    try:
        kpis = _como_dicts(consultar(RESUMEN_KPIS))[0]
        graficos = {k: _como_dicts(consultar(q)) for k, q in RESUMEN_GRAFICOS.items()}
        return jsonify(kpis=kpis, **graficos)
    except Exception as exc:
        return jsonify(error=str(exc)), 500


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5000, debug=True)
