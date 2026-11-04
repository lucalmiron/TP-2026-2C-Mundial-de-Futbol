"""Descarga el PBI per capita (NY.GDP.PCAP.CD) del Banco Mundial.

Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Comision 02
Grupo 7: Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
Objetivo: obtener, sin modificarlo, el XML de la API del Banco Mundial para
todos los paises y el anio indicado (defecto 2024). El XML se guarda junto a
este script y luego lo importa Importacion/XX_Importacion_Carga_PBI_Pais.sql.
La API pagina los resultados: este script junta todas las paginas en un solo
documento XML antes de guardarlo.
"""

import argparse
import sys
import xml.etree.ElementTree as ET
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import Request, urlopen


BASE_URL = "https://api.worldbank.org/v2/country/all/indicator/NY.GDP.PCAP.CD"
INDICADOR = "NY.GDP.PCAP.CD"
ANIO_POR_DEFECTO = 2024
POR_PAGINA = 300


def _nombre_local(etiqueta):
    """Devuelve la etiqueta sin el namespace, ej: {http://...}data -> data."""
    return etiqueta.rsplit("}", 1)[-1]


def descargar(anio):
    """Descarga todas las paginas y devuelve un unico ElementTree."""
    registros = []
    pagina = 1
    total_paginas = None
    while True:
        consulta = urlencode(
            {"format": "xml", "date": str(anio), "per_page": POR_PAGINA, "page": pagina}
        )
        solicitud = Request(f"{BASE_URL}?{consulta}", headers={"Accept": "application/xml"})
        with urlopen(solicitud, timeout=60) as respuesta:
            contenido = respuesta.read()
        raiz = ET.fromstring(contenido)
        # La API devuelve <data ...><data>...</data>...</data>: el elemento
        # raiz trae page/pages/total y cada pais es un hijo <data>.
        if _nombre_local(raiz.tag) != "data" or not raiz.attrib.get("pages"):
            raise ValueError("La API no devolvio el XML esperado del Banco Mundial.")
        total_paginas = int(raiz.attrib["pages"])
        for hijo in raiz:
            if _nombre_local(hijo.tag) == "data":
                registros.append(hijo)
        if pagina >= total_paginas:
            break
        pagina += 1
    if not registros:
        raise ValueError("La API no devolvio registros del indicador.")
    raiz_unica = ET.Element("data", {"total": str(len(registros)), "page": "1", "pages": "1"})
    raiz_unica.extend(registros)
    return ET.ElementTree(raiz_unica)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--salida",
        type=Path,
        default=Path(__file__).resolve().parent / "pbi_por_pais.xml",
        help="Archivo de destino (se reemplaza si ya existe).",
    )
    parser.add_argument(
        "--anio",
        type=int,
        default=ANIO_POR_DEFECTO,
        help="Anio del PBI per capita (defecto: 2024).",
    )
    args = parser.parse_args()
    temporal = args.salida.with_name(args.salida.name + ".tmp")
    try:
        arbol = descargar(args.anio)
        args.salida.parent.mkdir(parents=True, exist_ok=True)
        arbol.write(temporal, encoding="utf-8", xml_declaration=True)
        temporal.replace(args.salida)
        registros = len(arbol.getroot())
    except HTTPError as error:
        print(f"Error HTTP {error.code}: {error.reason}", file=sys.stderr)
        return 1
    except URLError as error:
        print(f"No se pudo consultar la API: {error.reason}", file=sys.stderr)
        return 1
    except (OSError, ValueError, ET.ParseError) as error:
        print(f"Error: {error}", file=sys.stderr)
        return 1

    print(f"Fuente: {BASE_URL} (indicador {INDICADOR}, anio {args.anio})")
    print(f"Paises descargados: {registros}")
    print(f"Archivo guardado: {args.salida.resolve()}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
