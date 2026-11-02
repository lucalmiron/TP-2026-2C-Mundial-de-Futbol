# pip install playwright pandas lxml
# playwright install chromium
from playwright.sync_api import sync_playwright
import pandas as pd
from io import StringIO

URL = "https://www.ussoccer.com/stories/2025/09/which-nations-qualified-2026-fifa-world-cup-usmnt"

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_page()
    page.goto(URL, wait_until="networkidle")

    # Cerrar banner de cookies si aparece
    try:
        page.click("button:has-text('Accept')", timeout=3000)
    except Exception:
        pass

    # Scrollear para forzar lazy loading
    for _ in range(10):
        page.mouse.wheel(0, 2000)
        page.wait_for_timeout(500)

    html = page.content()
    open("render.html", "w", encoding="utf-8").write(html)

    # Diagnóstico: ¿dónde está la lista?
    print("tablas:", page.locator("table").count())
    print("iframes:", [f.url for f in page.frames if f.url != URL])
    print("imágenes en el artículo:", page.locator("article img").count())

    # Intento 1: tablas HTML
    try:
        tablas = pd.read_html(StringIO(html))
        for i, t in enumerate(tablas):
            print(f"--- tabla {i} ---")
            print(t.head())
    except ValueError:
        print("No hay <table> en el DOM renderizado")

    browser.close()