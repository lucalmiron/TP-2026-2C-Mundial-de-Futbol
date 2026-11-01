import argparse
import json
import sys
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


URL = "https://api.opentimezone.com/timezones"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--salida", type=Path,
        default=Path(__file__).resolve().parent / "husos_horarios.json",
        help="Archivo de destino (se reemplaza si ya existe).",
    )
    args = parser.parse_args()
    temporal = args.salida.with_name(args.salida.name + ".tmp")
    try:
        solicitud = Request(URL, headers={"Accept": "application/json"})
        with urlopen(solicitud, timeout=30) as respuesta:
            contenido = respuesta.read()
            
        datos = json.loads(contenido)
        if not isinstance(datos, list) or not datos:
            raise ValueError("La API no devolvio una lista de husos no vacia.")

        args.salida.parent.mkdir(parents=True, exist_ok=True)
        temporal.write_bytes(contenido)
        temporal.replace(args.salida)
    except HTTPError as error:
        print(f"Error HTTP {error.code}: {error.reason}", file=sys.stderr)
        return 1
    except URLError as error:
        print(f"No se pudo consultar la API: {error.reason}", file=sys.stderr)
        return 1
    except (OSError, ValueError) as error:
        print(f"Error: {error}", file=sys.stderr)
        return 1

    print(f"Fuente: {URL}")
    print(f"Husos descargados: {len(datos)}")
    print(f"Archivo guardado: {args.salida.resolve()}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
