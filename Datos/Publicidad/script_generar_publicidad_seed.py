"""Genera los datos de publicidad que no tienen fuente publica: espacios por
sede, costo por franja e historial por partido.

Universidad Nacional de La Matanza - Bases de Datos Aplicadas - Comision 02
Grupo 7: Almiron, Luca; Figueroa, Santiago; Ruarte, Fidel; Villalba, Leandro.
Objetivo: armar los tres archivos que ningun organismo publica (el dossier del
torneo no informa precios ni espacios contratados). Los valores son de ejemplo,
elegidos con un criterio de mercado (capacidad y pais de la sede) y no son datos
oficiales.

Salida en esta misma carpeta:
  espacios_publicitarios.csv / .xlsx  (hojas EspacioPublicitario y CostoFranja)
  historial_publicidad.csv / .xlsx    (hoja HistorialPublicidad)

Criterio:
  - 4 espacios por sede (numeros 1 a 4, es lo que admite el modelo):
      1 Banda LED perimetral, 2 Cartel de fondo, 3 Videoboard, 4 Mencion en TV.
  - 3 franjas por sede: Manana, Tarde, Prime time.
  - Costo = base del espacio/franja * factor de la sede.
  - Historial: 2 o 3 espacios por partido (rotando), franja segun la hora, una
    campana de Datos\\Publicidad\\publicidad.xml y CostoFinal = costo del espacio
    + costo de la franja de esa sede.

Uso: python script_generar_publicidad_seed.py
Requiere: openpyxl (para los .xlsx)
"""
import csv
import glob
import json
import os
import re
import sys

from openpyxl import Workbook

AQUI = os.path.dirname(os.path.abspath(__file__))
DATOS = os.path.dirname(AQUI)
PARTIDOS = os.path.join(DATOS, 'Datos_Partidos', 'partidos')

TIPOS_ESPACIO = {1: 'Banda LED perimetral', 2: 'Cartel de fondo',
                 3: 'Videoboard', 4: 'Mencion en transmision'}
BASE_ESPACIO = {1: 45000, 2: 30000, 3: 60000, 4: 20000}
BASE_FRANJA = {'Manana': 12000, 'Tarde': 18000, 'Prime time': 32000}

# Factor por sede: toma en cuenta el tamano del mercado y la capacidad.
FACTOR = {
    'MetLife Stadium': 1.40,
    'SoFi Stadium': 1.35,
    'Levi\'s Stadium': 1.28,
    'Hard Rock Stadium': 1.22,
    'AT&T Stadium': 1.20,
    'Lumen Field': 1.16,
    'Mercedes-Benz Stadium': 1.15,
    'Gillette Stadium': 1.14,
    'Lincoln Financial Field': 1.12,
    'NRG Stadium': 1.10,
    'BMO Field': 1.10,
    'Estadio Azteca': 1.08,
    'Estadio BC Place': 1.05,
    'Arrowhead Stadium': 1.00,
    'Estadio BBVA': 0.95,
    'Estadio Akron': 0.92,
}


def leer_csv(nombre):
    with open(os.path.join(DATOS, nombre), encoding='utf-8-sig') as f:
        return list(csv.DictReader(f))


def partidos():
    """Devuelve (fecha, local, visitante, sede, hora_local) en orden cronologico.

    La fecha y los equipos se toman de asistencia_partidos.csv, que ya usa los
    nombres de equipos.Pais y las fechas del fixture. La hora local del partido
    se calcula desde la hora de la fuente (Argentina, UTC-3) mas el huso de la
    sede, que es lo que define la franja.
    """
    equipos = {r['equipo_promiedos']: r['pais_bd']
               for r in leer_csv('equivalencias_equipos_jugadores.csv')}
    sedes = {r['nombre_json']: r['nombre_sede']
             for r in leer_csv('equivalencias_sedes_partidos.csv')}
    husos = {r['nombre']: r['zona_horaria'] for r in leer_csv('Sedes/sedes.csv')}
    fechas = {(r['equipo_local'], r['equipo_visitante']): r['fecha']
              for r in leer_csv('Datos_Partidos/asistencia_partidos.csv')}

    filas = []
    for ruta in glob.glob(os.path.join(PARTIDOS, '*.json')):
        with open(ruta, encoding='utf-8-sig') as f:
            g = json.load(f)['game']
        info = {i['name']: i['value'] for i in g.get('game_info') or []}
        sede = sedes.get(info.get('Estadio'))
        nombres = [t.get('url_name') for t in g.get('teams') or []]
        if len(nombres) != 2 or sede is None:
            raise SystemExit(f'Partido sin sede o equipos: {ruta}')
        local, visita = (equipos[n] for n in nombres)
        fecha = fechas[(local, visita)]
        filas.append((fecha, local, visita, sede, hora_local(g['start_time'], husos[sede])))
    return sorted(filas)


def hora_local(inicio, huso):
    """inicio: '18-06-2026 22:00' en hora argentina (UTC-3). Devuelve HH:MM local."""
    h, m = (int(x) for x in inicio.split(' ')[1].split(':'))
    signo = -1 if huso[3] == '-' else 1
    offset = signo * (int(huso[4:6]) * 60 + int(huso[7:9]))
    total = (h * 60 + m + 180 + offset) % (24 * 60)
    return f'{total // 60:02d}:{total % 60:02d}'


def campanas():
    with open(os.path.join(AQUI, 'publicidad.xml'), encoding='utf-8') as f:
        return re.findall(r'<titulo>(.*?)</titulo>', f.read())


def franja(hora):
    h = int(hora.split(':')[0])
    if h < 13:
        return 'Manana'
    if h < 19:
        return 'Tarde'
    return 'Prime time'


def costo(base, sede):
    return int(round(base * FACTOR[sede] / 100.0)) * 100


def escribir_csv(nombre, cabecera, filas):
    with open(os.path.join(AQUI, nombre), 'w', newline='', encoding='utf-8-sig') as f:
        w = csv.writer(f)
        w.writerow(cabecera)
        w.writerows(filas)
    print(f'{nombre}: {len(filas)} filas')


def escribir_xlsx(nombre, hojas):
    wb = Workbook()
    wb.remove(wb.active)
    for titulo, cabecera, filas in hojas:
        ws = wb.create_sheet(titulo)
        ws.append(cabecera)
        for fila in filas:
            ws.append(fila)
        ws.freeze_panes = 'A2'
        for i, ancho in enumerate([26] * len(cabecera), start=1):
            ws.column_dimensions[ws.cell(row=1, column=i).column_letter].width = ancho
    wb.save(os.path.join(AQUI, nombre))
    print(f'{nombre}: hojas {", ".join(h[0] for h in hojas)}')


def main():
    sedes = sorted(FACTOR)

    espacios = []
    for sede in sedes:
        for numero in sorted(TIPOS_ESPACIO):
            espacios.append((sede, numero, TIPOS_ESPACIO[numero],
                             costo(BASE_ESPACIO[numero], sede)))

    franjas = []
    for sede in sedes:
        for tipo in ('Manana', 'Tarde', 'Prime time'):
            franjas.append((sede, tipo, costo(BASE_FRANJA[tipo], sede)))

    costo_espacio = {(s, n): c for s, n, _, c in espacios}
    costo_franja = {(s, t): c for s, t, c in franjas}

    titulos = campanas()
    historial = []
    usadas = 0
    for i, (fecha, local, visita, sede, hora) in enumerate(partidos()):
        tipo_franja = franja(hora)
        cantidad = 2 + (i % 2)
        numeros = sorted(((i + k) % 4 + 1) for k in range(cantidad))
        for numero in numeros:
            historial.append((
                fecha, local, visita, sede, numero, tipo_franja,
                titulos[usadas % len(titulos)],
                costo_espacio[(sede, numero)] + costo_franja[(sede, tipo_franja)]))
            usadas += 1

    escribir_csv('espacios_publicitarios.csv', ['sede', 'numero', 'tipo', 'costo'],
                 espacios)
    escribir_csv('costo_franja.csv', ['sede', 'tipo_franja', 'costo'], franjas)
    escribir_csv('historial_publicidad.csv',
                 ['fecha', 'equipo_local', 'equipo_visitante', 'sede',
                  'numero_espacio', 'tipo_franja', 'publicidad', 'costo_final'],
                 historial)

    escribir_xlsx('espacios_publicitarios.xlsx', [
        ('EspacioPublicitario', ['sede', 'numero', 'tipo', 'costo'], espacios),
        ('CostoFranja', ['sede', 'tipo_franja', 'costo'], franjas)])
    escribir_xlsx('historial_publicidad.xlsx', [
        ('HistorialPublicidad',
         ['fecha', 'equipo_local', 'equipo_visitante', 'sede', 'numero_espacio',
          'tipo_franja', 'publicidad', 'costo_final'], historial)])

    print(f'sedes: {len(sedes)} | espacios: {len(espacios)} | franjas: {len(franjas)} '
          f'| partidos: {len(historial and {h[:3] for h in historial})} '
          f'| historial: {len(historial)} | campanas: {len(titulos)}')


if __name__ == '__main__':
    sys.exit(main())
