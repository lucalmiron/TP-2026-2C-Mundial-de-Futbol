"""Utilidades compartidas por los scripts del TP Mundial."""
import re, unicodedata, requests

UA = {"User-Agent": "TP-BDDA-Mundial/1.0 (trabajo practico universitario)"}
OPENFOOTBALL_FULL = "https://raw.githubusercontent.com/openfootball/worldcup.json/master/2026/worldcup-full.json"

ALIAS = {
    "cape verde": "cabo verde", "dr congo": "congo dr", "ivory coast": "cote d'ivoire",
    "united states": "usa", "czechia": "czech republic", "turkiye": "turkey",
    "korea republic": "south korea", "ir iran": "iran",
}

def sin_tildes(s):
    return "".join(c for c in unicodedata.normalize("NFD", s) if unicodedata.category(c) != "Mn")

def norm_equipo(s):
    s = sin_tildes(s.replace("\u2019", "'")).strip().lower()
    return ALIAS.get(s, s)

def get(url, **kw):
    r = requests.get(url, headers=UA, timeout=60, **kw)
    r.raise_for_status()
    return r

def partidos_openfootball():
    """Devuelve la lista de 104 partidos (mismo orden/nro_partido que partidos_asistencia_arbitro.csv)."""
    return get(OPENFOOTBALL_FULL).json()["matches"]
