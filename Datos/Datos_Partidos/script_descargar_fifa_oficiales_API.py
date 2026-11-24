"""Descarga el calendario del Mundial 2026 de la API de FIFA y arma dos CSV: los
oficiales de cada partido y la asistencia.

Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Comision 02
Grupo 7: Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
Objetivo: obtener, sin modificarlo, el JSON de /calendar/matches y de ahi los
oficiales que FIFA da por partido (principal, asistentes, 4o, VAR, reserva,
asistente VAR y support VAR) con su pais, mas la asistencia de publico.
Salida en la carpeta del script: fifa_calendario_2026.json (crudo),
fifa_oficiales.csv y asistencia_partidos.csv.
Columnas de fifa_oficiales.csv: nro_partido_fifa, fecha, equipo_local,
equipo_visitante, asistencia, tipo_codigo, rol, nombre, nombre_corto, pais_iso3,
official_id.

Uso: python script_descargar_fifa_oficiales_API.py [carpeta_salida]
Requiere: pip install requests
"""
import csv
import json
import os
import sys

import requests

UA = {"User-Agent": "TP-BDDA-Mundial/1.0 (trabajo practico universitario)"}


def get(url, **kw):
    r = requests.get(url, headers=UA, timeout=60, **kw)
    r.raise_for_status()
    return r

BASE = "https://api.fifa.com/api/v3"
ID_COMPETICION = 17
ID_TEMPORADA_2026 = "285023"
# Por defecto escribe al lado del script: Datos\Datos_Partidos.
SALIDA_POR_DEFECTO = os.path.dirname(os.path.abspath(__file__))
LARGO_NOMBRE = 30  # equipos.Persona.Nombre NVARCHAR(30)

# Nombre de equipo en FIFA -> NOMBRE en equipos.Pais.
# El modelo solo tiene cargados los 48 participantes; si falta uno, el script corta.
EQUIPOS = {
    "Algeria": "Algeria",
    "Argentina": "Argentina",
    "Australia": "Australia",
    "Austria": "Austria",
    "Belgium": "Belgium",
    "Bosnia and Herzegovina": "Bosnia and Herzegovina",
    "Brazil": "Brazil",
    "Cabo Verde": "Cape Verde",
    "Canada": "Canada",
    "Colombia": "Colombia",
    "Congo DR": "Congo DR",
    "Croatia": "Croatia",
    "Curaçao": "Curaçao",
    "Czechia": "Czechia",
    "Côte d'Ivoire": "Ivory Coast",
    "Ecuador": "Ecuador",
    "Egypt": "Egypt",
    "England": "England",
    "France": "France",
    "Germany": "Germany",
    "Ghana": "Ghana",
    "Haiti": "Haiti",
    "IR Iran": "IR Iran",
    "Iraq": "Iraq",
    "Japan": "Japan",
    "Jordan": "Jordan",
    "Mexico": "Mexico",
    "Morocco": "Morocco",
    "Netherlands": "Netherlands",
    "New Zealand": "New Zealand",
    "Norway": "Norway",
    "Panama": "Panama",
    "Paraguay": "Paraguay",
    "Portugal": "Portugal",
    "Qatar": "Qatar",
    "Saudi Arabia": "Saudi Arabia",
    "Scotland": "Scotland",
    "Senegal": "Senegal",
    "South Africa": "South Africa",
    "Korea Republic": "Korea Republic",
    "Spain": "Spain",
    "Sweden": "Sweden",
    "Switzerland": "Switzerland",
    "Tunisia": "Tunisia",
    "Türkiye": "Türkiye",
    "USA": "USA",
    "Uruguay": "Uruguay",
    "Uzbekistan": "Uzbekistan",
}

# Codigo FIFA del pais del oficial -> NOMBRE en equipos.Pais, solo para los 48
# participantes (los unicos paises que el modelo tiene cargados). Si un oficial
# viene de un pais que no esta en esta tabla, pais_bd queda vacio y el importador
# aplica el criterio de respaldo (USA) dejando el codigo ISO3 en el reporte.
ISO3_A_PAIS = {
    "ALG": "Algeria", "ARG": "Argentina", "AUS": "Australia", "AUT": "Austria",
    "BEL": "Belgium", "BIH": "Bosnia and Herzegovina", "BRA": "Brazil",
    "CAN": "Canada", "CIV": "Ivory Coast", "COD": "Congo DR", "COL": "Colombia",
    "CPV": "Cape Verde", "CRO": "Croatia", "CUW": "Curaçao", "CZE": "Czechia",
    "ECU": "Ecuador", "EGY": "Egypt", "ENG": "England", "ESP": "Spain",
    "FRA": "France", "GER": "Germany", "GHA": "Ghana", "HAI": "Haiti",
    "IRN": "IR Iran", "IRQ": "Iraq", "JOR": "Jordan", "JPN": "Japan",
    "KOR": "Korea Republic", "KSA": "Saudi Arabia", "MAR": "Morocco",
    "MEX": "Mexico", "NED": "Netherlands", "NOR": "Norway", "NZL": "New Zealand",
    "PAN": "Panama", "PAR": "Paraguay", "POR": "Portugal", "QAT": "Qatar",
    "RSA": "South Africa", "SCO": "Scotland", "SEN": "Senegal", "SUI": "Switzerland",
    "SWE": "Sweden", "TUN": "Tunisia", "TUR": "Türkiye", "URU": "Uruguay",
    "USA": "USA", "UZB": "Uzbekistan",
}

# OfficialType de FIFA -> rol. Los cuatro primeros son los que acepta
# SPTRANS.uspArbitraje_Registrar; el resto se informa y no se importa.
ROLES = {
    1: "Principal",
    2: "Asistente",
    3: "Asistente",
    4: "4to",
    5: "VAR",
    6: "Reserva",
    8: "Asistente VAR",
    9: "Support VAR",
}
ROLES_SOPORTADOS = {"Principal", "Asistente", "4to", "VAR"}


def desc(lista):
    """Los textos de FIFA vienen como [{'Locale': 'en-GB', 'Description': '...'}]."""
    if isinstance(lista, list) and lista:
        return lista[0].get("Description", "")
    return lista or ""


def temporada_2026():
    """Verifica contra /seasons que la temporada siga existiendo con ese id."""
    j = get(f"{BASE}/seasons", params={"idCompetition": ID_COMPETICION, "count": 100,
                                       "language": "en"}).json()
    for s in j.get("Results", []):
        if s.get("IdSeason") == ID_TEMPORADA_2026:
            return ID_TEMPORADA_2026, desc(s.get("Name"))
    for s in j.get("Results", []):
        if "2026" in desc(s.get("Name")):
            return s["IdSeason"], desc(s.get("Name"))
    raise SystemExit("No encontre la temporada 2026 en /seasons.")


def calendario(temporada):
    """Baja el calendario completo, siguiendo ContinuationToken si la API pagina."""
    filas, token, vueltas = [], None, 0
    while True:
        params = {"idSeason": temporada, "idCompetition": ID_COMPETICION,
                  "count": 500, "language": "en"}
        if token:
            params["continuationToken"] = token
        j = get(f"{BASE}/calendar/matches", params=params).json()
        filas.extend(j.get("Results") or [])
        token = j.get("ContinuationToken")
        vueltas += 1
        if not token or vueltas > 10:
            return filas


def main():
    salida = sys.argv[1] if len(sys.argv) > 1 else SALIDA_POR_DEFECTO
    os.makedirs(salida, exist_ok=True)

    temporada, nombre = temporada_2026()
    print(f"Temporada: {nombre} ({temporada})")

    partidos = calendario(temporada)
    with open(os.path.join(salida, "fifa_calendario_2026.json"), "w",
              encoding="utf-8") as f:
        json.dump(partidos, f, ensure_ascii=False, indent=1)

    filas, sin_equipo, sin_oficiales = [], set(), 0
    for m in partidos:
        local, visita = desc(m["Home"]["TeamName"]), desc(m["Away"]["TeamName"])
        for nombre_fifa in (local, visita):
            if nombre_fifa not in EQUIPOS:
                sin_equipo.add(nombre_fifa)
        oficiales = m.get("Officials") or []
        if not oficiales:
            sin_oficiales += 1
        for o in oficiales:
            completo = desc(o.get("Name"))
            corto = desc(o.get("NameShort")) or completo
            if len(completo) > LARGO_NOMBRE:
                completo = corto[:LARGO_NOMBRE]
            filas.append([
                m.get("MatchNumber"),
                (m.get("Date") or "")[:10],
                EQUIPOS.get(local, local),
                EQUIPOS.get(visita, visita),
                m.get("Attendance") or "",
                o.get("OfficialType"),
                ROLES.get(o.get("OfficialType"), f"Desconocido({o.get('OfficialType')})"),
                completo,
                corto,
                o.get("IdCountry"),
                ISO3_A_PAIS.get(o.get("IdCountry"), ""),
                o.get("OfficialId"),
            ])

    if sin_equipo:
        raise SystemExit(f"Equipos sin equivalencia en EQUIPOS: {sorted(sin_equipo)}")
    if sin_oficiales:
        raise SystemExit(f"{sin_oficiales} partidos sin oficiales: revisar la API.")

    destino = os.path.join(salida, "fifa_oficiales.csv")
    with open(destino, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["nro_partido_fifa", "fecha", "equipo_local", "equipo_visitante",
                    "asistencia", "tipo_codigo", "rol", "nombre", "nombre_corto",
                    "pais_iso3", "pais_bd", "official_id"])
        w.writerows(filas)

    importables = sum(1 for r in filas if r[6] in ROLES_SOPORTADOS)
    print(f"partidos: {len(partidos)} | filas oficiales: {len(filas)} | "
          f"importables (4 roles del modelo): {importables} | "
          f"omitidas por rol no modelado: {len(filas) - importables}")
    print(f"-> {destino}")

    # Una fila por partido: la asistencia se repite en las 8 filas de oficiales,
    # pero su grano natural es el partido (lo consume la carga 25).
    asistencia = []
    for m in partidos:
        local, visita = desc(m["Home"]["TeamName"]), desc(m["Away"]["TeamName"])
        asistencia.append([
            (m.get("Date") or "")[:10],
            EQUIPOS[local],
            EQUIPOS[visita],
            m.get("Attendance") or "",
        ])
    destino_asistencia = os.path.join(salida, "asistencia_partidos.csv")
    with open(destino_asistencia, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["fecha", "equipo_local", "equipo_visitante", "asistencia"])
        w.writerows(asistencia)
    print(f"asistencia_partidos.csv: {len(asistencia)} partidos")
    print(f"-> {destino_asistencia}")


if __name__ == "__main__":
    main()
