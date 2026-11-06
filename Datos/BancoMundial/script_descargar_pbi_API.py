"""Descarga el PBI per capita (NY.GDP.PCAP.CD) del Banco Mundial.

Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Comision 02
Grupo 7: Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
Objetivo: obtener, sin modificarlo, el XML de la API del Banco Mundial para
todos los paises y el anio indicado (defecto 2024). El XML se guarda pagina
por pagina tal como llega de la API. La union y el parseo se hacen en SQL
(Importacion/12_Importacion_Carga_PBI_Pais.sql).
"""

import argparse
import sys
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import Request, urlopen


BASE_URL = "https://api.worldbank.org/v2/country/all/indicator/NY.GDP.PCAP.CD"
INDICADOR = "NY.GDP.PCAP.CD"
ANIO_POR_DEFECTO = 2024
POR_PAGINA = 300


def descargar_pagina(anio, pagina):
    """Descarga una pagina y devuelve el XML crudo tal como llega de la API."""
    consulta = urlencode(
        {"format": "xml", "date": str(anio), "per_page": POR_PAGINA, "page": pagina}
    )
    solicitud = Request(f"{BASE_URL}?{consulta}", headers={"Accept": "application/xml"})
    with urlopen(solicitud, timeout=60) as respuesta:
        contenido = respuesta.read()
    return contenido


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--salida",
        type=Path,
        default=Path(__file__).resolve().parent / "pbi_por_pais",
        help="Directorio de destino (se crea si no existe). Cada pagina se guarda como un archivo XML separado.",
    )
    parser.add_argument(
        "--anio",
        type=int,
        default=ANIO_POR_DEFECTO,
        help="Anio del PBI per capita (defecto: 2024).",
    )
    args = parser.parse_args()

    args.salida.mkdir(parents=True, exist_ok=True)

    pagina = 1
    total_paginas = None
    while total_paginas is None or pagina <= total_paginas:
        try:
            contenido = descargar_pagina(args.anio, pagina)
        except HTTPError as error:
            print(f"Error HTTP {error.code} en pagina {pagina}: {error.reason}", file=sys.stderr)
            return 1
        except URLError as error:
            print(f"No se pudo consultar la API en pagina {pagina}: {error.reason}", file=sys.stderr)
            return 1

        nombre_archivo = args.salida / f"pbi_pagina_{pagina}.xml"
        nombre_archivo.write_bytes(contenido)
        print(f"Pagina {pagina} guardada en {nombre_archivo.resolve()}")

        texto = contenido.decode("utf-8", errors="ignore")
        indice_pages = texto.find('pages="')
        if indice_pages != -1:
            inicio = indice_pages + len('pages="')
            fin = texto.find('"', inicio)
            total_paginas = int(texto[inicio:fin])

        pagina += 1

    print(f"Fuente: {BASE_URL} (indicador {INDICADOR}, anio {args.anio})")
    print(f"Paginas guardadas en: {args.salida.resolve()}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
