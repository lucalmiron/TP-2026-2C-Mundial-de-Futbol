"""
pip install requests beautifulsoup4
python scrape_mundial_2026.py
"""

import csv
import re

import requests
from bs4 import BeautifulSoup

URL = "https://es.wikipedia.org/wiki/Copa_Mundial_de_F%C3%BAtbol_de_2026"
HEADERS = {"User-Agent": "Mozilla/5.0 (script educativo de scraping)"}

RE_GRUPO = re.compile(r"^Grupo\s+([A-L])\b", re.IGNORECASE)
RE_NOTA = re.compile(r"\[[^\]]*\]")  # referencias tipo [1], [a], [nota 2]


def limpiar(texto: str) -> str:
    return RE_NOTA.sub("", texto).replace("\xa0", " ").strip()


def nombre_equipo(fila) -> str | None:
    for a in fila.find_all("a"):
        txt = limpiar(a.get_text())
        if txt:
            return txt
    celda = fila.find(["th", "td"])
    if celda:
        txt = limpiar(celda.get_text())
        return txt or None
    return None


def scrapear() -> list[tuple[str, str]]:
    resp = requests.get(URL, headers=HEADERS, timeout=30)
    resp.raise_for_status()
    soup = BeautifulSoup(resp.text, "html.parser")

    resultados: list[tuple[str, str]] = []

    for heading in soup.find_all(["h2", "h3", "h4"]):
        m = RE_GRUPO.match(limpiar(heading.get_text()))
        if not m:
            continue
        grupo = m.group(1).upper()

        tabla = None
        for elem in heading.find_all_next():
            if elem.name in ("h2", "h3", "h4") and elem is not heading:
                break
            if elem.name == "table" and "Pts" in elem.get_text():
                tabla = elem
                break
        if tabla is None:
            continue

        for fila in tabla.find_all("tr"):
            if fila.find("th", string=re.compile(r"Pts")) or "Pts" in fila.get_text():
                continue 
            equipo = nombre_equipo(fila)
            if equipo and (equipo, grupo) not in resultados:
                resultados.append((equipo, grupo))

    return resultados


def main():
    datos = scrapear()

    if not datos:
        print("No se encontraron datos. Puede que Wikipedia haya cambiado la estructura de la página.")
        return

    datos.sort(key=lambda x: (x[1], x[0]))

    with open("selecciones_grupos.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["seleccion", "grupo"])
        w.writerows(datos)

    grupo_actual = None
    for equipo, grupo in datos:
        if grupo != grupo_actual:
            print(f"\nGrupo {grupo}")
            grupo_actual = grupo
        print(f"  - {equipo}")

    print(f"\nTotal: {len(datos)} selecciones (esperado: 48, en 12 grupos de 4)")
    if len(datos) != 48:
        print("Aviso: la cantidad no coincide con 48; revisá la estructura de las tablas.")


if __name__ == "__main__":
    main()
