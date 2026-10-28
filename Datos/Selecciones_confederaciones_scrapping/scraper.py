# pip install playwright pandas lxml
# playwright install chromium
from io import StringIO
import xml.etree.ElementTree as ET

import pandas as pd
from playwright.sync_api import sync_playwright

URL = "https://www.ussoccer.com/stories/2025/09/which-nations-qualified-2026-fifa-world-cup-usmnt"


def extraer(html: str) -> pd.DataFrame:
    """Toma el HTML renderizado y devuelve solo seleccion y confederacion."""
    tabla = pd.read_html(StringIO(html), header=0)[0]
    df = pd.DataFrame({
        # "1. USA" -> "USA"
        "seleccion": tabla["Team"].str.replace(r"^\d+\.\s*", "", regex=True).str.strip(),
        # la pagina mezcla "CONCACAF" y "Concacaf" -> normalizo
        "confederacion": tabla["Confederation"].str.strip().str.upper(),
    })
    return df


def guardar_xml(df: pd.DataFrame, ruta: str) -> None:
    raiz = ET.Element("selecciones")
    for fila in df.itertuples(index=False):
        sel = ET.SubElement(raiz, "seleccion")
        ET.SubElement(sel, "nombre").text = fila.seleccion
        ET.SubElement(sel, "confederacion").text = fila.confederacion
    arbol = ET.ElementTree(raiz)
    ET.indent(arbol, space="  ")  # formato legible
    arbol.write(ruta, encoding="utf-8", xml_declaration=True)


def main():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=False)
        page = browser.new_page()
        page.goto(URL, wait_until="domcontentloaded", timeout=60000)
        page.wait_for_selector("table", timeout=30000)
        html = page.content()
        browser.close()

    df = extraer(html)
    print(df.to_string(index=False))
    print(f"\n{len(df)} selecciones")
    print(df["confederacion"].value_counts())

    guardar_xml(df, "selecciones_confederaciones.xml")
    print("\nGuardado en selecciones_confederaciones.xml")


if __name__ == "__main__":
    main()