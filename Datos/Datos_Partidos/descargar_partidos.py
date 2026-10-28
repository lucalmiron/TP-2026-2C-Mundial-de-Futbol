#!/usr/bin/env python3
"""
Descarga el JSON de cada partido de Promiedos a partir de un JSON con los ids.

Uso:
    python descargar_partidos.py ids.json
    python descargar_partidos.py ids.json -o partidos --delay 0.5
    python descargar_partidos.py ids.json --key id --dry-run

Requiere: pip install requests
"""

import argparse
import json
import sys
import time
from pathlib import Path

import requests

BASE_URL = "https://api.promiedos.com.ar/gamecenter/{id}"

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
        "(KHTML, like Gecko) Chrome/156.0.0.0 Safari/537.36"
    ),
    "Accept": "*/*",
    "Accept-Language": "en-GB,en;q=0.9,es-US;q=0.8,es;q=0.7,en-US;q=0.6",
    "Origin": "https://www.promiedos.com.ar",
    "Referer": "https://www.promiedos.com.ar/",
    "Sec-Fetch-Dest": "empty",
    "Sec-Fetch-Mode": "cors",
    "Sec-Fetch-Site": "same-site",
    # Header propio de Promiedos: sin este, la API contesta {} vacio.
    # Si algun dia vuelve a fallar, miralo en DevTools > Network y pasalo con -H "x-ver: NUEVO".
    "x-ver": "1.11.7.5",
}


def extraer_ids(data, key="id", lista="games"):
    """Saca los ids de los partidos.

    - Si el JSON es un dict con una lista `lista` (por defecto "games"),
      toma solo el `key` de cada partido (no toca los ids de equipos anidados).
    - Si es una lista de strings/numeros -> son los ids.
    - Si no, recorre todo y junta los valores de las claves `key`.
    """
    ids = []

    if isinstance(data, dict) and isinstance(data.get(lista), list):
        ids = [
            str(g[key]) for g in data[lista]
            if isinstance(g, dict) and key in g
        ]
    elif isinstance(data, list) and data and all(
        isinstance(x, (str, int)) and not isinstance(x, bool) for x in data
    ):
        ids = [str(x) for x in data]
    else:
        def recorrer(nodo):
            if isinstance(nodo, dict):
                for k, v in nodo.items():
                    if k == key and isinstance(v, (str, int)) and not isinstance(v, bool):
                        ids.append(str(v))
                    if isinstance(v, (dict, list)):
                        recorrer(v)
            elif isinstance(nodo, list):
                for item in nodo:
                    recorrer(item)

        recorrer(data)

    # sacar duplicados manteniendo el orden
    vistos = set()
    unicos = []
    for i in ids:
        if i not in vistos:
            vistos.add(i)
            unicos.append(i)
    return unicos


def descargar_partido(session, match_id, reintentos=3, timeout=20, debug=False):
    """Devuelve el JSON del partido o lanza excepcion si falla tras los reintentos."""
    url = BASE_URL.format(id=match_id)
    ultimo_error = None

    for intento in range(1, reintentos + 1):
        try:
            resp = session.get(url, timeout=timeout)
            if debug:
                print(f"    GET {url}")
                print(f"    status: {resp.status_code}")
                print(f"    content-type: {resp.headers.get('Content-Type')}")
                print(f"    largo: {len(resp.content)} bytes")
                print(f"    inicio del body: {resp.text[:300]!r}")
            if resp.status_code == 429:
                espera = 5 * intento
                print(f"    429 (rate limit), espero {espera}s...")
                time.sleep(espera)
                continue
            resp.raise_for_status()
            data = resp.json()
            if not data:
                # La API contesto 200 pero con {} o []: reintentar no sirve.
                raise RuntimeError(
                    f"respuesta vacia (status {resp.status_code}, body: {resp.text[:100]!r}). "
                    "Probablemente faltan headers; usa --debug y -H para pasarlos."
                )
            return data
        except RuntimeError:
            raise
        except (requests.RequestException, ValueError) as e:
            ultimo_error = e
            time.sleep(2 * intento)

    raise RuntimeError(f"fallo tras {reintentos} intentos: {ultimo_error}")


def archivo_valido(path):
    """True si el archivo existe y tiene un JSON no vacio (ignora los '{}' de descargas fallidas)."""
    if not path.exists():
        return False
    try:
        with open(path, "r", encoding="utf-8") as f:
            return bool(json.load(f))
    except (ValueError, OSError):
        return False


def main():
    parser = argparse.ArgumentParser(description="Descarga JSON de partidos de Promiedos.")
    parser.add_argument("ids_json", help="Ruta al JSON que contiene los ids")
    parser.add_argument("-o", "--output", default="partidos", help="Carpeta de salida (default: partidos)")
    parser.add_argument("--key", default="id", help="Nombre de la clave que tiene el id (default: id)")
    parser.add_argument("--lista", default="games", help="Clave que contiene la lista de partidos (default: games)")
    parser.add_argument("--extra", nargs="+", default=[], help="Ids de partidos extra que no estan en el JSON")
    parser.add_argument("-H", "--header", action="append", default=[],
                        help='Header extra, formato "Nombre: valor". Se puede repetir.')
    parser.add_argument("--debug", action="store_true", help="Muestra status, headers y body de cada respuesta")
    parser.add_argument("--delay", type=float, default=0.3, help="Segundos entre requests (default: 0.3)")
    parser.add_argument("--dry-run", action="store_true", help="Solo muestra los ids encontrados, no descarga")
    parser.add_argument("--force", action="store_true", help="Re-descarga aunque el archivo ya exista")
    args = parser.parse_args()

    with open(args.ids_json, "r", encoding="utf-8") as f:
        data = json.load(f)

    ids = extraer_ids(data, key=args.key, lista=args.lista)
    for extra in args.extra:
        if extra not in ids:
            ids.append(extra)
    if not ids:
        print(f"No encontre ids en {args.ids_json} (clave buscada: '{args.key}').")
        sys.exit(1)

    print(f"Encontre {len(ids)} ids.")
    if args.dry_run:
        for i in ids:
            print(i)
        return

    salida = Path(args.output)
    salida.mkdir(parents=True, exist_ok=True)

    session = requests.Session()
    session.headers.update(HEADERS)
    for h in args.header:
        if ":" not in h:
            print(f"Header invalido (falta ':'): {h}")
            sys.exit(1)
        nombre, valor = h.split(":", 1)
        session.headers[nombre.strip()] = valor.strip()

    ok, salteados, fallidos = 0, 0, []

    for n, match_id in enumerate(ids, start=1):
        destino = salida / f"{match_id}.json"

        if archivo_valido(destino) and not args.force:
            salteados += 1
            print(f"[{n}/{len(ids)}] {match_id} ya existe, salteo")
            continue

        try:
            partido = descargar_partido(session, match_id, debug=args.debug)
            with open(destino, "w", encoding="utf-8") as f:
                json.dump(partido, f, ensure_ascii=False, indent=2)
            ok += 1
            print(f"[{n}/{len(ids)}] {match_id} OK")
        except Exception as e:
            fallidos.append(match_id)
            print(f"[{n}/{len(ids)}] {match_id} ERROR: {e}")

        time.sleep(args.delay)

    print("\n--- Resumen ---")
    print(f"Descargados: {ok}")
    print(f"Salteados:   {salteados}")
    print(f"Fallidos:    {len(fallidos)}")

    if fallidos:
        fallidos_path = salida / "_fallidos.json"
        with open(fallidos_path, "w", encoding="utf-8") as f:
            json.dump(fallidos, f, indent=2)
        print(f"Los ids que fallaron quedaron en {fallidos_path}")
        print(f"Podes reintentar con: python {Path(sys.argv[0]).name} {fallidos_path} -o {args.output}")


if __name__ == "__main__":
    main()