"""Scraping de Dossier Mundial -> XML crudo.

Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Comision 02
Grupo 7: Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
Objetivo: bajar el HTML original de https://dossiermundial.netlify.app/ y
extraer el listado de campañas que la pagina trae embebido (CAMPANAS_INICIALES),
sin re-serializarlo: se genera el XML tal cual, campana por campana.
El HTML se guarda junto al XML para trazabilidad (acta de lo recibido).
"""

import argparse
import json
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


URL = "https://dossiermundial.netlify.app/"


def descargar_html():
    solicitud = Request(URL, headers={"User-Agent": "Mozilla/5.0", "Accept": "text/html"})
    with urlopen(solicitud, timeout=60) as respuesta:
        return respuesta.read()


def extraer_campanas(html_bytes):
    """La pagina embebe: const CAMPANAS_INICIALES = [ ... ];"""
    texto = html_bytes.decode("utf-8", errors="replace")
    marca = re.search(r"CAMPANAS_INICIALES\s*=\s*\[", texto)
    if not marca:
        raise ValueError("No se encontro CAMPANAS_INICIALES en el HTML.")
    inicio = marca.end() - 1
    datos, fin = json.JSONDecoder().raw_decode(texto[inicio:])
    if not isinstance(datos, list) or not datos:
        raise ValueError("La lista de campanas viene vacia.")
    return datos


def a_xml(campanas):
    raiz = ET.Element("publicidad")
    for i, c in enumerate(campanas, 1):
        nodo = ET.SubElement(raiz, "campana", {"numero": str(i)})
        for clave, etiqueta in (("anunciante", "anunciante"),
                                ("titulo", "titulo"),
                                ("agencia", "agencia"),
                                ("productora", "productora"),
                                ("periodo", "periodo"),
                                ("youtube", "youtube"),
                                ("url_dossier", "url_dossier"),
                                ("descripcion", "descripcion")):
            valor = c.get(clave)
            if valor is None or str(valor).strip() == "":
                continue
            ET.SubElement(nodo, etiqueta).text = str(valor)
        cats = c.get("categorias") or []
        if isinstance(cats, list) and cats:
            ET.SubElement(nodo, "categorias").text = ",".join(str(x) for x in cats)
        premios = c.get("premios") or []
        if isinstance(premios, list) and premios:
            ET.SubElement(nodo, "premios").text = ",".join(str(x) for x in premios)
    return ET.ElementTree(raiz)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--salida", type=Path,
                        default=Path(__file__).resolve().parent / "publicidad.xml")
    parser.add_argument("--html", type=Path,
                        default=Path(__file__).resolve().parent / "dossiermundial.html")
    args = parser.parse_args()
    temporal = args.salida.with_name(args.salida.name + ".tmp")
    try:
        html_bytes = descargar_html()
        campanas = extraer_campanas(html_bytes)
        arbol = a_xml(campanas)
        args.salida.parent.mkdir(parents=True, exist_ok=True)
        arbol.write(temporal, encoding="utf-8", xml_declaration=True)
        temporal.replace(args.salida)
        args.html.write_bytes(html_bytes)
    except HTTPError as error:
        print(f"Error HTTP {error.code}: {error.reason}", file=sys.stderr)
        return 1
    except URLError as error:
        print(f"No se pudo consultar la pagina: {error.reason}", file=sys.stderr)
        return 1
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(f"Error: {error}", file=sys.stderr)
        return 1

    print(f"Fuente: {URL}")
    print(f"Campanas: {len(campanas)}")
    print(f"XML: {args.salida.resolve()}")
    print(f"HTML (acta): {args.html.resolve()}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
