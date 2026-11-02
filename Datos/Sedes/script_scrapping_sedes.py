"""
    pip install requests pandas lxml
    python scrape_sedes_mundial_2026.py
"""

import io
import re
import unicodedata

import pandas as pd
import requests

URL = "https://es.wikipedia.org/wiki/Copa_Mundial_de_F%C3%BAtbol_de_2026"
HEADERS = {"User-Agent": "Mozilla/5.0 (script educativo de scraping)"}


CIUDADES = {
    "nueva york": ("Nueva York / Nueva Jersey", "Estados Unidos", "UTC-04:00"),
    "los angeles": ("Los Ángeles", "Estados Unidos", "UTC-07:00"),
    "dallas": ("Dallas", "Estados Unidos", "UTC-05:00"),
    "kansas city": ("Kansas City", "Estados Unidos", "UTC-05:00"),
    "atlanta": ("Atlanta", "Estados Unidos", "UTC-04:00"),
    "houston": ("Houston", "Estados Unidos", "UTC-05:00"),
    "boston": ("Boston", "Estados Unidos", "UTC-04:00"),
    "filadelfia": ("Filadelfia", "Estados Unidos", "UTC-04:00"),
    "miami": ("Miami", "Estados Unidos", "UTC-04:00"),
    "seattle": ("Seattle", "Estados Unidos", "UTC-07:00"),
    "san francisco": ("San Francisco", "Estados Unidos", "UTC-07:00"),
    "vancouver": ("Vancouver", "Canadá", "UTC-07:00"),
    "toronto": ("Toronto", "Canadá", "UTC-04:00"),
    "ciudad de mexico": ("Ciudad de México", "México", "UTC-06:00"),
    "guadalajara": ("Guadalajara", "México", "UTC-06:00"),
    "monterrey": ("Monterrey", "México", "UTC-06:00"),
}

# "Estadio BC Place (Estadio BC Place Vancouver)" -> nombre, alias
RE_ESTADIO = re.compile(r"^(?P<nombre>.+?)\s*\((?P<alias>Estadio[^)]*)\)\s*$")
RE_CAPACIDAD = re.compile(r"Capacidad:\s*([\d\s\.,]+)")


def normalizar(texto: str) -> str:
    texto = unicodedata.normalize("NFD", str(texto))
    texto = "".join(c for c in texto if unicodedata.category(c) != "Mn")
    return texto.lower().strip()


def limpiar(texto) -> str:
    texto = re.sub(r"\[[^\]]*\]", "", str(texto))  # quita referencias [68]
    return texto.replace("\xa0", " ").strip()


def buscar_ciudad(alias: str):
    alias_norm = normalizar(alias)
    for clave, datos in CIUDADES.items():
        if clave in alias_norm:
            return datos
    ciudad = re.sub(r"^Estadio\s+", "", alias).strip()
    return ciudad, None, None


def scrapear() -> pd.DataFrame:
    resp = requests.get(URL, headers=HEADERS, timeout=30)
    resp.raise_for_status()

    tablas = pd.read_html(io.StringIO(resp.text), match="Capacidad", header=None)
    if not tablas:
        raise RuntimeError("No se encontró ninguna tabla con 'Capacidad'.")

    filas = []
    for tabla in tablas:
        datos = tabla.astype(object).where(tabla.notna(), None).values
        n_filas, n_cols = datos.shape

        for r in range(n_filas - 1):
            for c in range(n_cols):
                celda = datos[r][c]
                if celda is None:
                    continue
                m = RE_ESTADIO.match(limpiar(celda))
                if not m:
                    continue

                # La capacidad está en la celda de justo abajo
                abajo = datos[r + 1][c]
                mc = RE_CAPACIDAD.search(limpiar(abajo)) if abajo is not None else None
                if not mc:
                    continue
                capacidad = int(re.sub(r"\D", "", mc.group(1)))

                ciudad, pais, zona = buscar_ciudad(m.group("alias"))
                filas.append(
                    {
                        "nombre": m.group("nombre").strip(),
                        "ciudad": ciudad,
                        "capacidad": capacidad,
                        "pais": pais,
                        "zona_horaria": zona,
                    }
                )

    # Las celdas combinadas (colspan) se repiten, por eso se eliminan duplicados
    return pd.DataFrame(filas).drop_duplicates(subset="nombre").reset_index(drop=True)


def main():
    df = scrapear()
    if df.empty:
        print("No se encontraron sedes. Puede que Wikipedia haya cambiado la estructura de la página.")
        return

    df = df.sort_values(["pais", "ciudad"], na_position="last").reset_index(drop=True)
    df.to_csv("sedes.csv", index=False, encoding="utf-8")
    print(df.to_string(index=False))
    print(f"\nTotal: {len(df)} sedes (esperado: 16)")

    sin_datos = df[df["pais"].isna()]
    if not sin_datos.empty:
        print("\nAviso: sin país/zona horaria, agregá su ciudad al diccionario CIUDADES:")
        print(sin_datos[["nombre", "ciudad"]].to_string(index=False))


if __name__ == "__main__":
    main()