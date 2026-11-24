# Universidad Nacional de La Matanza
# Bases de Datos Aplicadas - Comision 02
# Grupo 7 - Almiron, Luca / Figueroa, Santiago / Ruarte, Fidel / Villalba, Leandro
# Entrega 9 - Configuracion del ABM.
#
# Cada entrada de ABM describe una tabla administrable desde la interfaz.
# Ninguna operacion escribe directo sobre las tablas: toda alta, baja o
# modificacion se ejecuta con los stored procedures de la Entrega 5.
#
# El motor (app.py) empareja los parametros del SP con las claves de "campos"
# ignorando @, _ y mayusculas; "alias" cubre los casos en que el parametro y la
# columna tienen nombres distintos (por ejemplo @pais contra IdPais).
#
# Tipos de campo soportados:
#   texto, texto_largo, numero, decimal, fecha, hora, booleano,
#   lista (id numerico) y lista_texto (id textual, catalogos fijos).

ROLES = {
    "alta": r"(insert|alta|crear|agreg|registr|nuev|add)",
    "modificacion": r"(modif|updat|actualiz|edit|cambi)",
    "baja": r"(baja|delet|elimin|borr|remov|quit)",
}
EXCLUIR = r"(import|upsert|partido|listar|consult|obtener|get|select|report)"

SQL_SPS = """
    SELECT SCHEMA_NAME(p.schema_id) AS esquema, p.name AS sp, pa.name AS param,
           pa.is_output AS salida, TYPE_NAME(pa.user_type_id) AS tipo, pa.max_length AS largo
    FROM sys.procedures p
    LEFT JOIN sys.parameters pa ON pa.object_id = p.object_id
    WHERE p.name LIKE ?
    ORDER BY p.name, pa.parameter_id"""


# --------------------------------------------------------------------------
# Consultas de apoyo para los desplegables. Se comparten entre entidades para
# no repetir SQL y para que todas las pantallas muestren las mismas etiquetas.
# --------------------------------------------------------------------------
def _fijos(*valores):
    filas = ", ".join("('%s')" % v.replace("'", "''") for v in valores)
    return f"SELECT v AS id, v AS nombre FROM (VALUES {filas}) AS t(v)"


OPCIONES = {
    "paises": "SELECT IdPais AS id, NOMBRE AS nombre FROM equipos.Pais ORDER BY NOMBRE",
    "idiomas": "SELECT IdIdioma AS id, Descripcion AS nombre FROM arbitros.Idioma ORDER BY Descripcion",
    "husos": "SELECT IdHuso AS id, Nombre AS nombre FROM sedes.HusoHorario ORDER BY Nombre",
    "grupos": "SELECT IdGrupo AS id, NOMBRE AS nombre FROM equipos.Grupo ORDER BY NOMBRE",
    "fases": "SELECT IdFase AS id, Descripcion AS nombre FROM partidos.Fase ORDER BY IdFase",
    "fases_fijas": _fijos("Grupos", "Dieciseisavos", "Octavos", "Cuartos",
                          "Semifinal", "Tercer Puesto", "Final"),
    "clubes": "SELECT IdClub AS id, Nombre AS nombre FROM equipos.Club ORDER BY Nombre",
    "mundiales": """
        SELECT M.IdMundial AS id,
               CONCAT('Mundial ', M.IdMundial, ' · ', P.NOMBRE, ' · ',
                      CONVERT(varchar(10), M.ACTIVIDAD_FECHA_INICIO, 103)) AS nombre
        FROM sedes.Mundial M
        JOIN equipos.Pais P ON P.IdPais = M.IdPais
        ORDER BY M.IdMundial""",
    "sedes": """
        SELECT S.IdSede AS id, CONCAT(S.Nombre, ' · ', S.Ciudad) AS nombre
        FROM sedes.Sede S ORDER BY S.Nombre, S.Ciudad""",
    "selecciones": """
        SELECT S.IdSeleccion AS id, CONCAT(P.NOMBRE, ' · Grupo ', G.NOMBRE) AS nombre
        FROM equipos.Seleccion S
        JOIN equipos.Pais P ON P.IdPais = S.IdPais
        JOIN equipos.Grupo G ON G.IdGrupo = S.IdGrupo
        ORDER BY P.NOMBRE""",
    "jugadores": """
        SELECT J.IdJugador AS id,
               CONCAT(P.Nombre, ' · ', PA.NOMBRE, ' (#' + CAST(J.Numero AS varchar(3)) + ')') AS nombre
        FROM equipos.Jugador J
        JOIN equipos.Persona P ON P.IdPersona = J.IdJugador
        JOIN equipos.Seleccion S ON S.IdSeleccion = J.Seleccion
        JOIN equipos.Pais PA ON PA.IdPais = S.IdPais
        ORDER BY PA.NOMBRE, J.Numero""",
    "personas": """
        SELECT P.IdPersona AS id, CONCAT(P.Nombre, ' (', P.Rol, ')') AS nombre
        FROM equipos.Persona P ORDER BY P.Nombre""",
    "arbitros": """
        SELECT A.IdArbitro AS id, CONCAT(P.Nombre, ' · ', PA.NOMBRE) AS nombre
        FROM arbitros.Arbitro A
        JOIN equipos.Persona P ON P.IdPersona = A.IdArbitro
        JOIN equipos.Pais PA ON PA.IdPais = P.Pais
        ORDER BY P.Nombre""",
    # Para reportes: se identifican por ID + dato visible sin nombre (los nombres estan cifrados).
    "jugadores_id": """
        SELECT J.IdJugador AS id, CONCAT('ID ', J.IdJugador, ' · ', PA.NOMBRE, ' · #', J.Numero) AS nombre
        FROM equipos.Jugador J
        JOIN equipos.Seleccion S ON S.IdSeleccion = J.Seleccion
        JOIN equipos.Pais PA ON PA.IdPais = S.IdPais
        ORDER BY J.IdJugador""",
    "arbitros_id": """
        SELECT A.IdArbitro AS id, CONCAT('ID ', A.IdArbitro, ' · ', PA.NOMBRE, ' · ', A.Categoria) AS nombre
        FROM arbitros.Arbitro A
        JOIN equipos.Persona P ON P.IdPersona = A.IdArbitro
        JOIN equipos.Pais PA ON PA.IdPais = P.Pais
        ORDER BY A.IdArbitro""",
    "campanias": "SELECT IdCampania AS id, Nombre AS nombre FROM publicidad.Campania ORDER BY Nombre",
    "anunciantes": "SELECT IdAnunciante AS id, Nombre AS nombre FROM publicidad.Anunciante ORDER BY Nombre",
    "publicidades": "SELECT IdPublicidad AS id, Nombre AS nombre FROM publicidad.Publicidad ORDER BY Nombre",
    "motivos": "SELECT IdMotivo AS id, Descripcion AS nombre FROM publicidad.Motivo ORDER BY Descripcion",
    "espacios": """
        SELECT E.IdEP AS id,
               CONCAT(S.Nombre, ' · Espacio ', E.Numero, ' (', E.Tipo, ')') AS nombre
        FROM publicidad.EspacioPublicitario E
        JOIN sedes.Sede S ON S.IdSede = E.IdSede
        ORDER BY S.Nombre, E.Numero""",
    "franjas": """
        SELECT C.IdCF AS id,
               CONCAT(S.Nombre, ' · ', C.TipoFranja, ' · $', C.Costo) AS nombre
        FROM publicidad.CostoFranja C
        JOIN sedes.Sede S ON S.IdSede = C.IdSede
        ORDER BY S.Nombre, C.TipoFranja""",
    "partidos": """
        SELECT P.IdPartido AS id,
               CONCAT('N° ', P.IdPartido, ' · ', P1.NOMBRE, ' vs ', P2.NOMBRE, ' · ',
                      CONVERT(varchar(10), P.Fecha, 103)) AS nombre
        FROM partidos.Partido P
        JOIN equipos.Seleccion S1 ON S1.IdSeleccion = P.Eq1
        JOIN equipos.Pais P1 ON P1.IdPais = S1.IdPais
        JOIN equipos.Seleccion S2 ON S2.IdSeleccion = P.Eq2
        JOIN equipos.Pais P2 ON P2.IdPais = S2.IdPais
        ORDER BY P.Fecha, P.IdPartido""",
    "periodos": """
        SELECT IdPeriodo AS id,
               CONCAT(Descripcion, CASE WHEN EsPenales = 1 THEN ' (penales)' ELSE '' END) AS nombre
        FROM partidos.Periodo ORDER BY IdPeriodo""",
    "tipos_gol": _fijos("Jugada", "Penal", "Tiro libre", "Corner", "En contra"),
    "tarjetas": _fijos("Amarilla", "Roja"),
    "funciones_arbitraje": _fijos("Principal", "Asistente", "4to", "VAR"),
    "funciones_arbitro": _fijos("FIFA", "Confederacion"),
    "roles_alineacion": _fijos("Titular", "Suplente"),
    "razones_reporte": _fijos("Sancion", "Informe PostPartido"),
    "estados_jugador": _fijos("Activo", "Inactivo"),
    "confederaciones": _fijos("AFC", "CAF", "CONCACAF", "CONMEBOL", "OFC", "UEFA"),
    "tipos_evento": _fijos("Gol", "Amonestacion", "Sustitucion"),
}


# --------------------------------------------------------------------------
# Entidades del ABM.
# --------------------------------------------------------------------------
ABM = {
    # ------------------------------ Catalogos ------------------------------
    "paises": {
        "titulo": "Países",
        "desc": "Idioma, huso horario, prime time y PBI",
        "etiqueta": "país",
        "buscar_sp": "Pais",
        "pk": "IdPais",
        "base": """
            SELECT P.IdPais, P.NOMBRE AS Nombre, P.Idioma, I.Descripcion AS IdiomaNombre,
                   P.HusoHorario AS Huso, H.Nombre AS HusoNombre,
                   P.PtIni, P.PtFin, P.PBI
            FROM equipos.Pais P
            LEFT JOIN arbitros.Idioma I ON I.IdIdioma = P.Idioma
            LEFT JOIN sedes.HusoHorario H ON H.IdHuso = P.HusoHorario""",
        "orden": "ORDER BY P.NOMBRE",
        "filtro_pk": "WHERE P.IdPais = ?",
        "columnas": [("IdPais", "ID"), ("Nombre", "País"), ("IdiomaNombre", "Idioma"),
                     ("HusoNombre", "Huso horario"), ("PtIni", "Prime time desde"),
                     ("PtFin", "Prime time hasta"), ("PBI", "PBI")],
        "campos": [
            {"clave": "Nombre", "etiqueta": "Nombre", "tipo": "texto", "max": 50, "obligatorio": True},
            {"clave": "Idioma", "etiqueta": "Idioma", "tipo": "lista", "opciones": "idiomas"},
            {"clave": "Huso", "etiqueta": "Huso horario", "tipo": "lista", "opciones": "husos",
"alias": ["husohorario"]},
            {"clave": "PtIni", "etiqueta": "Prime time desde", "tipo": "hora"},
            {"clave": "PtFin", "etiqueta": "Prime time hasta", "tipo": "hora"},
            {"clave": "PBI", "etiqueta": "PBI", "tipo": "numero", "min": 0},
        ],
        "opciones": ["idiomas", "husos"],
        "reglas": ["primetime"],
    },
    "grupos": {
        "titulo": "Grupos",
        "desc": "Grupos del torneo",
        "etiqueta": "grupo",
        "buscar_sp": "Grupo",
        "pk": "IdGrupo",
        "base": "SELECT G.IdGrupo, G.NOMBRE AS Nombre FROM equipos.Grupo G",
        "orden": "ORDER BY G.NOMBRE",
        "filtro_pk": "WHERE G.IdGrupo = ?",
        "columnas": [("IdGrupo", "ID"), ("Nombre", "Grupo")],
        "campos": [{"clave": "Nombre", "etiqueta": "Nombre", "tipo": "texto", "max": 10, "obligatorio": True}],
    },
    "fases": {
        "titulo": "Fases",
        "desc": "Etapas del torneo",
        "etiqueta": "fase",
        "buscar_sp": "Fase",
        "pk": "IdFase",
        "base": "SELECT F.IdFase, F.Descripcion FROM partidos.Fase F",
        "orden": "ORDER BY F.IdFase",
        "filtro_pk": "WHERE F.IdFase = ?",
        "columnas": [("IdFase", "ID"), ("Descripcion", "Fase")],
        "campos": [{"clave": "Descripcion", "etiqueta": "Fase", "tipo": "lista_texto",
                    "opciones": "fases_fijas", "obligatorio": True}],
        "opciones": ["fases_fijas"],
    },
    "periodos": {
        "titulo": "Períodos",
        "desc": "Tramos de tiempo de los partidos",
        "etiqueta": "período",
        "buscar_sp": "Periodo",
        "pk": "IdPeriodo",
        "pk_editable": True,
        "base": "SELECT P.IdPeriodo, P.Descripcion, P.Inicio, P.Fin, P.EsPenales FROM partidos.Periodo P",
        "orden": "ORDER BY P.IdPeriodo",
        "filtro_pk": "WHERE P.IdPeriodo = ?",
        "columnas": [("IdPeriodo", "ID"), ("Descripcion", "Período"), ("Inicio", "Inicio"),
                     ("Fin", "Fin"), ("EsPenales", "¿Penales?")],
        "campos": [
            {"clave": "IdPeriodo", "etiqueta": "ID", "tipo": "numero", "min": 1,
             "obligatorio": True, "solo_alta": True},
            {"clave": "Descripcion", "etiqueta": "Descripción", "tipo": "texto", "max": 12, "obligatorio": True},
            {"clave": "Inicio", "etiqueta": "Minuto de inicio", "tipo": "numero", "min": 0},
            {"clave": "Fin", "etiqueta": "Minuto de fin", "tipo": "numero", "min": 0},
            {"clave": "EsPenales", "etiqueta": "Es tanda de penales", "tipo": "booleano"},
        ],
        "reglas": ["periodo"],
    },
    "husos": {
        "titulo": "Husos horarios",
        "desc": "Catálogo de husos IANA",
        "etiqueta": "huso horario",
        "buscar_sp": "HusoHorario",
        "pk": "IdHuso",
        "base": "SELECT H.IdHuso, H.Nombre FROM sedes.HusoHorario H",
        "orden": "ORDER BY H.Nombre",
        "filtro_pk": "WHERE H.IdHuso = ?",
        "columnas": [("IdHuso", "ID"), ("Nombre", "Huso horario")],
        "campos": [{"clave": "Nombre", "etiqueta": "Nombre", "tipo": "texto", "max": 50, "obligatorio": True}],
    },
    "idiomas": {
        "titulo": "Idiomas",
        "desc": "Idiomas de países y árbitros",
        "etiqueta": "idioma",
        "buscar_sp": "Idioma",
        "pk": "IdIdioma",
        "base": "SELECT I.IdIdioma, I.Descripcion FROM arbitros.Idioma I",
        "orden": "ORDER BY I.Descripcion",
        "filtro_pk": "WHERE I.IdIdioma = ?",
        "columnas": [("IdIdioma", "ID"), ("Descripcion", "Idioma")],
        "campos": [{"clave": "Descripcion", "etiqueta": "Descripción", "tipo": "texto", "max": 20,
                    "obligatorio": True}],
    },
    "clubes": {
        "titulo": "Clubes",
        "desc": "Clubes de los jugadores",
        "etiqueta": "club",
        "buscar_sp": "Club",
        "pk": "IdClub",
        "base": "SELECT C.IdClub, C.Nombre FROM equipos.Club C",
        "orden": "ORDER BY C.Nombre",
        "filtro_pk": "WHERE C.IdClub = ?",
        "columnas": [("IdClub", "ID"), ("Nombre", "Club")],
        "campos": [{"clave": "Nombre", "etiqueta": "Nombre", "tipo": "texto", "max": 40,
                    "obligatorio": True}],
    },
    "sedes": {
        "titulo": "Sedes",
        "desc": "Alta, baja y modificación de estadios",
        "etiqueta": "sede",
        "buscar_sp": "Sede",
        "pk": "IdSede",
        "base": """
            SELECT S.IdSede, S.Nombre, S.Ciudad, S.Capacidad, S.IdPais, PA.NOMBRE AS Pais,
                   S.IdHuso, H.Nombre AS Huso
            FROM sedes.Sede S
            JOIN equipos.Pais PA ON PA.IdPais = S.IdPais
            JOIN sedes.HusoHorario H ON H.IdHuso = S.IdHuso""",
        "orden": "ORDER BY S.Nombre, S.Ciudad",
        "filtro_pk": "WHERE S.IdSede = ?",
        "columnas": [("IdSede", "ID"), ("Nombre", "Estadio"), ("Ciudad", "Ciudad"),
                     ("Pais", "País"), ("Capacidad", "Capacidad"), ("Huso", "Huso horario")],
        "campos": [
            {"clave": "Nombre", "etiqueta": "Nombre del estadio", "tipo": "texto", "max": 30,
             "obligatorio": True},
            {"clave": "Ciudad", "etiqueta": "Ciudad", "tipo": "texto", "max": 30, "obligatorio": True},
            {"clave": "Capacidad", "etiqueta": "Capacidad", "tipo": "numero", "min": 1, "obligatorio": True},
            {"clave": "IdPais", "etiqueta": "País", "tipo": "lista", "opciones": "paises",
             "alias": ["pais"], "obligatorio": True},
            {"clave": "IdHuso", "etiqueta": "Huso horario", "tipo": "lista", "opciones": "husos",
             "alias": ["huso", "husohorario"], "obligatorio": True},
        ],
        "opciones": ["paises", "husos"],
    },
    "mundiales": {
        "titulo": "Mundiales",
        "desc": "Reglas y fechas de cada Mundial",
        "etiqueta": "mundial",
        "buscar_sp": "Mundial",
        "pk": "IdMundial",
        "base": """
            SELECT M.IdMundial, M.IdPais, P.NOMBRE AS Pais,
                   M.ACTIVIDAD_FECHA_INICIO AS FechaInicio, M.ACTIVIDAD_FECHA_FIN AS FechaFin,
                   M.TAMANIO_SELECCION_MINIMO AS TamMin, M.TAMANIO_SELECCION_MAXIMO AS TamMax,
                   M.CAMBIOS_VENTANAS AS Ventanas, M.CAMBIOS_CANTIDAD AS Cantidad,
                   M.SUSPENSION_TARJETAS_MAXIMAS AS SuspMax, M.SUSPENSION_TIEMPO AS SuspTiempo
            FROM sedes.Mundial M
            JOIN equipos.Pais P ON P.IdPais = M.IdPais""",
        "orden": "ORDER BY M.IdMundial",
        "filtro_pk": "WHERE M.IdMundial = ?",
        "columnas": [("IdMundial", "ID"), ("Pais", "País"), ("FechaInicio", "Inicio"),
                     ("FechaFin", "Fin"), ("TamMin", "Mín. convoc."), ("TamMax", "Máx. convoc."),
                     ("Ventanas", "Ventanas"), ("Cantidad", "Cambios"),
                     ("SuspMax", "Tarjetas susp."), ("SuspTiempo", "Partidos susp.")],
        "campos": [
            {"clave": "IdPais", "etiqueta": "País organizador", "tipo": "lista", "opciones": "paises",
             "obligatorio": True},
            {"clave": "FechaInicio", "etiqueta": "Fecha de inicio", "tipo": "fecha", "obligatorio": True},
            {"clave": "FechaFin", "etiqueta": "Fecha de fin", "tipo": "fecha", "obligatorio": True},
            {"clave": "TamMin", "etiqueta": "Convocados mínimo", "tipo": "numero", "min": 0, "obligatorio": True},
            {"clave": "TamMax", "etiqueta": "Convocados máximo", "tipo": "numero", "min": 0, "obligatorio": True},
            {"clave": "Ventanas", "etiqueta": "Ventanas de cambios", "tipo": "numero", "min": 0,
             "obligatorio": True},
            {"clave": "Cantidad", "etiqueta": "Cambios por selección", "tipo": "numero", "min": 0,
             "obligatorio": True},
            {"clave": "SuspMax", "etiqueta": "Tarjetas para suspensión", "tipo": "numero", "min": 0,
             "obligatorio": True},
            {"clave": "SuspTiempo", "etiqueta": "Partidos de suspensión", "tipo": "numero", "min": 0,
             "obligatorio": True},
        ],
        "opciones": ["paises"],
        "reglas": ["fechas", "tamanios"],
    },

    # ------------------------------ Equipos --------------------------------
    "selecciones": {
        "titulo": "Selecciones",
        "desc": "Países participantes, grupo y confederación",
        "etiqueta": "selección",
        "buscar_sp": "Seleccion",
        "pk": "IdSeleccion",
        "base": """
            SELECT S.IdSeleccion, S.IdPais, P.NOMBRE AS Pais, S.IdMundial, M.IdMundial AS Mundial,
                   S.IdGrupo, G.NOMBRE AS Grupo, S.CONFEDERACION AS Confederacion
            FROM equipos.Seleccion S
            JOIN equipos.Pais P ON P.IdPais = S.IdPais
            JOIN sedes.Mundial M ON M.IdMundial = S.IdMundial
            JOIN equipos.Grupo G ON G.IdGrupo = S.IdGrupo""",
        "orden": "ORDER BY G.NOMBRE, P.NOMBRE",
        "filtro_pk": "WHERE S.IdSeleccion = ?",
        "columnas": [("IdSeleccion", "ID"), ("Pais", "País"), ("Mundial", "Mundial"),
                     ("Grupo", "Grupo"), ("Confederacion", "Confederación")],
        "campos": [
            {"clave": "IdPais", "etiqueta": "País", "tipo": "lista", "opciones": "paises",
             "obligatorio": True},
            {"clave": "IdMundial", "etiqueta": "Mundial", "tipo": "lista", "opciones": "mundiales",
             "obligatorio": True},
            {"clave": "IdGrupo", "etiqueta": "Grupo", "tipo": "lista", "opciones": "grupos",
             "obligatorio": True},
            {"clave": "Confederacion", "etiqueta": "Confederación", "tipo": "lista_texto",
             "opciones": "confederaciones", "obligatorio": True},
        ],
        "opciones": ["paises", "mundiales", "grupos", "confederaciones"],
    },
    "arbitros": {
        "titulo": "Árbitros",
        "desc": "Árbitros, categoría y país",
        "etiqueta": "árbitro",
        "sps_manual": {"alta": "SPTRANS.uspArbitro_Registrar",
                       "modificacion": "SPTRANS.uspArbitro_Update",
                       "baja": "SPTRANS.uspArbitro_Bajar"},
        "pk": "IdArbitro",
        "base": """
            SELECT A.IdArbitro, PE.Nombre, PE.Fnac, PE.Pais AS IdPais, PA.NOMBRE AS Pais,
                   A.Categoria
            FROM arbitros.Arbitro A
            JOIN equipos.Persona PE ON PE.IdPersona = A.IdArbitro
            JOIN equipos.Pais PA ON PA.IdPais = PE.Pais""",
        "orden": "ORDER BY PE.Nombre",
        "filtro_pk": "WHERE A.IdArbitro = ?",
        "columnas": [("IdArbitro", "ID"), ("Nombre", "Nombre"), ("Pais", "País"),
                     ("Categoria", "Categoría")],
        "campos": [
            {"clave": "Nombre", "etiqueta": "Nombre", "tipo": "texto", "max": 30, "obligatorio": True},
            {"clave": "Fnac", "etiqueta": "Fecha de nacimiento", "tipo": "fecha", "obligatorio": True},
            {"clave": "IdPais", "etiqueta": "País", "tipo": "lista", "opciones": "paises",
             "alias": ["pais"], "obligatorio": True},
            {"clave": "Categoria", "etiqueta": "Categoría", "tipo": "lista_texto",
             "opciones": "funciones_arbitro", "obligatorio": True},
        ],
        "opciones": ["paises", "funciones_arbitro"],
    },
    "jugadores": {
        "titulo": "Jugadores",
        "desc": "Convocados, posición, club y estado",
        "etiqueta": "jugador",
        "sps_manual": {"alta": "SPTRANS.uspJugador_Registrar",
                       "modificacion": ["SPTRANS.uspJugador_Update", "SP.uspJugador_ClubUpdate"],
                       "baja": "SPTRANS.uspJugador_Bajar"},
        "pk": "IdJugador",
        "base": """
            SELECT J.IdJugador, PE.Nombre, PE.Fnac, PE.Pais AS IdPais, PP.NOMBRE AS Pais,
                   J.Posicion, J.Numero, J.Club, ISNULL(C.Nombre, '—') AS ClubNombre,
                   J.Seleccion, PS.NOMBRE AS SeleccionNombre, J.Estado, J.TarjetasAcum
            FROM equipos.Jugador J
            JOIN equipos.Persona PE ON PE.IdPersona = J.IdJugador
            JOIN equipos.Pais PP ON PP.IdPais = PE.Pais
            JOIN equipos.Seleccion S ON S.IdSeleccion = J.Seleccion
            JOIN equipos.Pais PS ON PS.IdPais = S.IdPais
            LEFT JOIN equipos.Club C ON C.IdClub = J.Club""",
        "orden": "ORDER BY PS.NOMBRE, J.Numero",
        "filtro_pk": "WHERE J.IdJugador = ?",
        "columnas": [("IdJugador", "ID"), ("Nombre", "Nombre"), ("Pais", "País"),
                     ("SeleccionNombre", "Selección"), ("Numero", "Dorsal"), ("Posicion", "Posición"),
                     ("ClubNombre", "Club"), ("Estado", "Estado"), ("TarjetasAcum", "Tarjetas")],
        "campos": [
            {"clave": "Nombre", "etiqueta": "Nombre", "tipo": "texto", "max": 30, "obligatorio": True},
            {"clave": "Fnac", "etiqueta": "Fecha de nacimiento", "tipo": "fecha", "obligatorio": True},
            {"clave": "IdPais", "etiqueta": "País", "tipo": "lista", "opciones": "paises",
             "alias": ["pais"], "obligatorio": True},
            {"clave": "Posicion", "etiqueta": "Posición", "tipo": "texto", "max": 20, "obligatorio": True},
            {"clave": "Numero", "etiqueta": "Dorsal", "tipo": "numero", "min": 1, "obligatorio": True},
            {"clave": "Club", "etiqueta": "Club", "tipo": "lista", "opciones": "clubes"},
            {"clave": "Seleccion", "etiqueta": "Selección", "tipo": "lista", "opciones": "selecciones",
             "obligatorio": True},
            {"clave": "Estado", "etiqueta": "Estado", "tipo": "lista_texto", "opciones": "estados_jugador",
             "obligatorio": True, "solo_alta": True},
        ],
        "opciones": ["paises", "clubes", "selecciones", "estados_jugador"],
        "reglas": ["nacimiento"],
    },
    "tecnicos": {
        "titulo": "Cuerpo técnico",
        "desc": "Directores técnicos y ayudantes",
        "etiqueta": "técnico",
        "sps_manual": {"alta": "SPTRANS.uspTecnico_Registrar",
                       "modificacion": "SPTRANS.uspTecnico_Update",
                       "baja": "SPTRANS.uspTecnico_Bajar"},
        "pk": "IdTecnico",
        "base": """
            SELECT T.IdTecnico, PE.Nombre, PE.Fnac, PE.Pais AS IdPais, PP.NOMBRE AS Pais,
                   T.Funcion, T.Seleccion, PS.NOMBRE AS SeleccionNombre, T.Estado, T.TarjetasAcum
            FROM equipos.Tecnico T
            JOIN equipos.Persona PE ON PE.IdPersona = T.IdTecnico
            JOIN equipos.Pais PP ON PP.IdPais = PE.Pais
            JOIN equipos.Seleccion S ON S.IdSeleccion = T.Seleccion
            JOIN equipos.Pais PS ON PS.IdPais = S.IdPais""",
        "orden": "ORDER BY PS.NOMBRE, T.Funcion",
        "filtro_pk": "WHERE T.IdTecnico = ?",
        "columnas": [("IdTecnico", "ID"), ("Nombre", "Nombre"), ("Pais", "País"),
                     ("SeleccionNombre", "Selección"), ("Funcion", "Función"),
                     ("Estado", "Estado"), ("TarjetasAcum", "Tarjetas")],
        "campos": [
            {"clave": "Nombre", "etiqueta": "Nombre", "tipo": "texto", "max": 30, "obligatorio": True},
            {"clave": "Fnac", "etiqueta": "Fecha de nacimiento", "tipo": "fecha", "obligatorio": True},
            {"clave": "IdPais", "etiqueta": "País", "tipo": "lista", "opciones": "paises",
             "alias": ["pais"], "obligatorio": True},
            {"clave": "Funcion", "etiqueta": "Función", "tipo": "texto", "max": 40, "obligatorio": True},
            {"clave": "Seleccion", "etiqueta": "Selección", "tipo": "lista", "opciones": "selecciones",
             "obligatorio": True},
        ],
        "opciones": ["paises", "selecciones"],
        "reglas": ["nacimiento"],
    },

    # ------------------------------ Partidos -------------------------------
    "partidos": {
        "titulo": "Partidos",
        "desc": "Fixture, resultado y asistencia",
        "etiqueta": "partido",
        "sps_manual": {"alta": "SP.uspPartido_Registrar",
                       "modificacion": "SP.uspPartido_Update",
                       "baja": "SP.uspPartido_Bajar"},
        "pk": "IdPartido",
        "base": """
            SELECT P.IdPartido, P.IdFase, F.Descripcion AS Fase, P.IdSede, SE.Nombre AS Sede,
                   P.IdMundial, M.IdMundial AS Mundial, P.Eq1, E1.NOMBRE AS Equipo1,
                   P.Eq2, E2.NOMBRE AS Equipo2, P.Fecha, P.HoraUTC, P.HoraLocal,
                   P.GolesEq1, P.GolesEq2, P.PenalesEq1, P.PenalesEq2, P.Asistencia
            FROM partidos.Partido P
            JOIN partidos.Fase F ON F.IdFase = P.IdFase
            JOIN sedes.Sede SE ON SE.IdSede = P.IdSede
            JOIN sedes.Mundial M ON M.IdMundial = P.IdMundial
            JOIN equipos.Seleccion S1 ON S1.IdSeleccion = P.Eq1
            JOIN equipos.Pais E1 ON E1.IdPais = S1.IdPais
            JOIN equipos.Seleccion S2 ON S2.IdSeleccion = P.Eq2
            JOIN equipos.Pais E2 ON E2.IdPais = S2.IdPais""",
        "orden": "ORDER BY P.Fecha, P.HoraUTC, P.IdPartido",
        "filtro_pk": "WHERE P.IdPartido = ?",
        "columnas": [("IdPartido", "N°"), ("Fase", "Fase"), ("Fecha", "Fecha"),
                     ("HoraLocal", "Hora local"), ("Sede", "Sede"),
                     ("Equipo1", "Equipo 1"), ("GolesEq1", "Goles 1"), ("GolesEq2", "Goles 2"),
                     ("Equipo2", "Equipo 2"), ("PenalesEq1", "Penales 1"), ("PenalesEq2", "Penales 2"),
                     ("Asistencia", "Asistencia")],
        "campos": [
            {"clave": "IdFase", "etiqueta": "Fase", "tipo": "lista", "opciones": "fases", "obligatorio": True},
            {"clave": "IdSede", "etiqueta": "Sede", "tipo": "lista", "opciones": "sedes", "obligatorio": True},
            {"clave": "IdMundial", "etiqueta": "Mundial", "tipo": "lista", "opciones": "mundiales",
             "obligatorio": True},
            {"clave": "Eq1", "etiqueta": "Equipo 1", "tipo": "lista", "opciones": "selecciones",
             "obligatorio": True},
            {"clave": "Eq2", "etiqueta": "Equipo 2", "tipo": "lista", "opciones": "selecciones",
             "obligatorio": True},
            {"clave": "Fecha", "etiqueta": "Fecha", "tipo": "fecha", "obligatorio": True},
            {"clave": "HoraUTC", "etiqueta": "Hora UTC", "tipo": "hora", "obligatorio": True},
            {"clave": "HoraLocal", "etiqueta": "Hora local", "tipo": "hora", "obligatorio": True},
            {"clave": "GolesEq1", "etiqueta": "Goles equipo 1", "tipo": "numero", "min": 0, "obligatorio": True,
             "solo_edicion": True},
            {"clave": "GolesEq2", "etiqueta": "Goles equipo 2", "tipo": "numero", "min": 0, "obligatorio": True,
             "solo_edicion": True},
            {"clave": "Asistencia", "etiqueta": "Asistencia", "tipo": "numero", "min": 0},
        ],
        "opciones": ["fases", "sedes", "mundiales", "selecciones"],
        "reglas": ["equipos"],
    },

    # ------------------------------- Eventos -------------------------------
    "eventos": {
        "titulo": "Eventos",
        "desc": "Minuto, tipo y período de cada evento",
        "etiqueta": "evento",
        "buscar_sp": "Evento",
        "pk": "IdEvento",
        "base": """
            SELECT E.IdEvento, E.Minuto, E.Tipo, E.Partido,
                   CONCAT('N° ', E.Partido, ' · ', P1.NOMBRE, ' vs ', P2.NOMBRE) AS PartidoNombre,
                   E.Periodo, PE.Descripcion AS PeriodoNombre
            FROM partidos.Evento E
            JOIN partidos.Partido P ON P.IdPartido = E.Partido
            JOIN equipos.Seleccion S1 ON S1.IdSeleccion = P.Eq1
            JOIN equipos.Pais P1 ON P1.IdPais = S1.IdPais
            JOIN equipos.Seleccion S2 ON S2.IdSeleccion = P.Eq2
            JOIN equipos.Pais P2 ON P2.IdPais = S2.IdPais
            JOIN partidos.Periodo PE ON PE.IdPeriodo = E.Periodo""",
        "orden": "ORDER BY E.Partido, PE.IdPeriodo, E.Minuto, E.IdEvento",
        "filtro_pk": "WHERE E.IdEvento = ?",
        "columnas": [("IdEvento", "ID"), ("PartidoNombre", "Partido"), ("PeriodoNombre", "Período"),
                     ("Minuto", "Minuto"), ("Tipo", "Tipo")],
        "campos": [
            {"clave": "Minuto", "etiqueta": "Minuto", "tipo": "numero", "min": 0},
            {"clave": "Tipo", "etiqueta": "Tipo", "tipo": "lista_texto", "opciones": "tipos_evento",
             "obligatorio": True},
            {"clave": "Partido", "etiqueta": "Partido", "tipo": "lista", "opciones": "partidos",
             "obligatorio": True},
            {"clave": "Periodo", "etiqueta": "Período", "tipo": "lista", "opciones": "periodos",
             "obligatorio": True},
        ],
        "opciones": ["tipos_evento", "partidos", "periodos"],
    },
    "goles": {
        "titulo": "Goles",
        "desc": "Autor, asistencia y tipo de gol",
        "etiqueta": "gol",
        "sps_manual": {"alta": "SPTRANS.uspGol_Registrar", "baja": "SPTRANS.uspGol_Bajar"},
        "pk": "IdGol",
        "base": """
            SELECT G.IdGol, E.Minuto, E.Partido,
                   CONCAT('N° ', E.Partido, ' · ', P1.NOMBRE, ' vs ', P2.NOMBRE) AS PartidoNombre,
                   E.Periodo, G.Autor, PE.Nombre AS AutorNombre,
                   G.Asistencia, PA.Nombre AS AsistenciaNombre, G.Tipo
            FROM partidos.Gol G
            JOIN partidos.Evento E ON E.IdEvento = G.IdGol
            JOIN partidos.Partido P ON P.IdPartido = E.Partido
            JOIN equipos.Seleccion S1 ON S1.IdSeleccion = P.Eq1
            JOIN equipos.Pais P1 ON P1.IdPais = S1.IdPais
            JOIN equipos.Seleccion S2 ON S2.IdSeleccion = P.Eq2
            JOIN equipos.Pais P2 ON P2.IdPais = S2.IdPais
            JOIN equipos.Persona PE ON PE.IdPersona = G.Autor
            LEFT JOIN equipos.Persona PA ON PA.IdPersona = G.Asistencia""",
        "orden": "ORDER BY E.Partido, E.Minuto, G.IdGol",
        "filtro_pk": "WHERE G.IdGol = ?",
        "columnas": [("IdGol", "ID"), ("PartidoNombre", "Partido"), ("Minuto", "Minuto"),
                     ("AutorNombre", "Autor"), ("AsistenciaNombre", "Asistencia"), ("Tipo", "Tipo")],
        "campos": [
            {"clave": "Minuto", "etiqueta": "Minuto", "tipo": "numero", "min": 0, "obligatorio": True},
            {"clave": "Partido", "etiqueta": "Partido", "tipo": "lista", "opciones": "partidos",
             "obligatorio": True},
            {"clave": "Periodo", "etiqueta": "Período", "tipo": "lista", "opciones": "periodos",
             "obligatorio": True},
            {"clave": "Autor", "etiqueta": "Autor", "tipo": "lista", "opciones": "jugadores",
             "obligatorio": True},
            {"clave": "Asistencia", "etiqueta": "Asistencia", "tipo": "lista", "opciones": "jugadores"},
            {"clave": "Tipo", "etiqueta": "Tipo", "tipo": "lista_texto", "opciones": "tipos_gol",
             "obligatorio": True},
        ],
        "opciones": ["partidos", "periodos", "jugadores", "tipos_gol"],
        "reglas": ["gol"],
    },
    "amonestaciones": {
        "titulo": "Tarjetas",
        "desc": "Amarillas y rojas por partido",
        "etiqueta": "tarjeta",
        "sps_manual": {
            "alta": "SPTRANS.uspAmonestacion_Registrar",
            "modificacion": ["SPTRANS.uspAmonestacion_UpdateTiempo", "SPTRANS.uspAmonestacion_UpdateMotivo"],
            "baja": "SPTRANS.uspAmonestacion_Bajar",
        },
        "pk": "IdAmonestacion",
        "base": """
            SELECT A.IdAmonestacion, E.Minuto, E.Partido,
                   CONCAT('N° ', E.Partido, ' · ', P1.NOMBRE, ' vs ', P2.NOMBRE) AS PartidoNombre,
                   E.Periodo, A.Amonestado, PE.Nombre AS AmonestadoNombre, PE.Rol AS Rol,
                   A.Arbitro, AR.Nombre AS ArbitroNombre, A.Tarjeta, A.Motivo
            FROM partidos.Amonestacion A
            JOIN partidos.Evento E ON E.IdEvento = A.IdAmonestacion
            JOIN partidos.Partido P ON P.IdPartido = E.Partido
            JOIN equipos.Seleccion S1 ON S1.IdSeleccion = P.Eq1
            JOIN equipos.Pais P1 ON P1.IdPais = S1.IdPais
            JOIN equipos.Seleccion S2 ON S2.IdSeleccion = P.Eq2
            JOIN equipos.Pais P2 ON P2.IdPais = S2.IdPais
            JOIN equipos.Persona PE ON PE.IdPersona = A.Amonestado
            JOIN equipos.Persona AR ON AR.IdPersona = A.Arbitro""",
        "orden": "ORDER BY E.Partido, E.Minuto, A.IdAmonestacion",
        "filtro_pk": "WHERE A.IdAmonestacion = ?",
        "columnas": [("IdAmonestacion", "ID"), ("PartidoNombre", "Partido"), ("Minuto", "Minuto"),
                     ("AmonestadoNombre", "Amonestado"), ("Rol", "Rol"), ("ArbitroNombre", "Árbitro"),
                     ("Tarjeta", "Tarjeta"), ("Motivo", "Motivo")],
        "campos": [
            {"clave": "Minuto", "etiqueta": "Minuto", "tipo": "numero", "min": 0, "obligatorio": True},
            {"clave": "Partido", "etiqueta": "Partido", "tipo": "lista", "opciones": "partidos",
             "obligatorio": True, "solo_alta": True},
            {"clave": "Periodo", "etiqueta": "Período", "tipo": "lista", "opciones": "periodos",
             "obligatorio": True},
            {"clave": "Amonestado", "etiqueta": "Amonestado", "tipo": "lista", "opciones": "personas",
             "obligatorio": True, "solo_alta": True},
            {"clave": "Arbitro", "etiqueta": "Árbitro", "tipo": "lista", "opciones": "arbitros",
             "obligatorio": True, "solo_alta": True},
            {"clave": "Tarjeta", "etiqueta": "Tarjeta", "tipo": "lista_texto", "opciones": "tarjetas",
             "obligatorio": True, "solo_alta": True},
            {"clave": "Motivo", "etiqueta": "Motivo", "tipo": "texto_largo", "max": 300,
             "obligatorio": True},
        ],
        "opciones": ["partidos", "periodos", "personas", "arbitros", "tarjetas"],
    },
    "sustituciones": {
        "titulo": "Cambios",
        "desc": "Sustituciones de cada partido",
        "etiqueta": "cambio",
        "sps_manual": {"alta": "SPTRANS.uspSustitucion_Registrar",
                       "baja": "SPTRANS.uspSustitucion_Bajar"},
        "pk": "IdSustitucion",
        "base": """
            SELECT X.IdSustitucion, E.Minuto, E.Partido,
                   CONCAT('N° ', E.Partido, ' · ', P1.NOMBRE, ' vs ', P2.NOMBRE) AS PartidoNombre,
                   E.Periodo, PEI.Nombre AS IngresoNombre, PEE.Nombre AS EgresoNombre,
                   M.Descripcion AS MotivoNombre
            FROM partidos.Sustitucion X
            JOIN partidos.Evento E ON E.IdEvento = X.IdSustitucion
            JOIN partidos.Partido P ON P.IdPartido = E.Partido
            JOIN equipos.Seleccion S1 ON S1.IdSeleccion = P.Eq1
            JOIN equipos.Pais P1 ON P1.IdPais = S1.IdPais
            JOIN equipos.Seleccion S2 ON S2.IdSeleccion = P.Eq2
            JOIN equipos.Pais P2 ON P2.IdPais = S2.IdPais
            JOIN equipos.Persona PEI ON PEI.IdPersona = X.Ingreso
            JOIN equipos.Persona PEE ON PEE.IdPersona = X.Egreso
            JOIN publicidad.Motivo M ON M.IdMotivo = X.Motivo""",
        "orden": "ORDER BY E.Partido, E.Minuto, X.IdSustitucion",
        "filtro_pk": "WHERE X.IdSustitucion = ?",
        "columnas": [("IdSustitucion", "ID"), ("PartidoNombre", "Partido"), ("Minuto", "Minuto"),
                     ("IngresoNombre", "Ingresa"), ("EgresoNombre", "Sale"), ("MotivoNombre", "Motivo")],
        "campos": [
            {"clave": "Minuto", "etiqueta": "Minuto", "tipo": "numero", "min": 0, "obligatorio": True},
            {"clave": "Partido", "etiqueta": "Partido", "tipo": "lista", "opciones": "partidos",
             "obligatorio": True},
            {"clave": "Periodo", "etiqueta": "Período", "tipo": "lista", "opciones": "periodos",
             "obligatorio": True},
            {"clave": "Ingreso", "etiqueta": "Ingresa", "tipo": "lista", "opciones": "jugadores",
             "obligatorio": True},
            {"clave": "Egreso", "etiqueta": "Sale", "tipo": "lista", "opciones": "jugadores",
             "obligatorio": True},
            {"clave": "Motivo", "etiqueta": "Motivo", "tipo": "lista", "opciones": "motivos",
             "obligatorio": True},
            {"clave": "IgnorarVentanas", "etiqueta": "Ignorar ventanas de cambio", "tipo": "booleano",
             "alias": ["ignorarventanas"], "solo_alta": True},
        ],
        "opciones": ["partidos", "periodos", "jugadores", "motivos"],
        "reglas": ["sustitucion"],
    },
    "cambios-convocatoria": {
        "titulo": "Cambios de convocatoria",
        "desc": "Reemplazos entre convocados",
        "etiqueta": "cambio de convocatoria",
        "sps_manual": {"alta": "SPTRANS.uspCambioConvocatoria_Registrar",
                       "baja": "SPTRANS.uspCambioConvocatoria_Bajar"},
        "pk": "IdCambio",
        "base": """
            SELECT C.IdCambio, C.Seleccion, PS.NOMBRE AS SeleccionNombre,
                   C.Egreso, PEE.Nombre AS EgresoNombre, C.Ingreso, PEI.Nombre AS IngresoNombre,
                   C.Fecha, C.Motivo
            FROM equipos.CambioConvocatoria C
            JOIN equipos.Seleccion S ON S.IdSeleccion = C.Seleccion
            JOIN equipos.Pais PS ON PS.IdPais = S.IdPais
            JOIN equipos.Persona PEE ON PEE.IdPersona = C.Egreso
            JOIN equipos.Persona PEI ON PEI.IdPersona = C.Ingreso""",
        "orden": "ORDER BY C.Fecha DESC, C.IdCambio DESC",
        "filtro_pk": "WHERE C.IdCambio = ?",
        "columnas": [("IdCambio", "ID"), ("SeleccionNombre", "Selección"), ("Fecha", "Fecha"),
                     ("EgresoNombre", "Sale"), ("IngresoNombre", "Entra"), ("Motivo", "Motivo")],
        "campos": [
            {"clave": "Seleccion", "etiqueta": "Selección", "tipo": "lista", "opciones": "selecciones",
             "obligatorio": True},
            {"clave": "Egreso", "etiqueta": "Jugador que sale", "tipo": "lista", "opciones": "jugadores",
             "obligatorio": True},
            {"clave": "Ingreso", "etiqueta": "Jugador que entra", "tipo": "lista", "opciones": "jugadores",
             "obligatorio": True},
            {"clave": "Fecha", "etiqueta": "Fecha", "tipo": "fecha", "obligatorio": True},
            {"clave": "Motivo", "etiqueta": "Motivo", "tipo": "texto_largo", "max": 200,
             "obligatorio": True},
        ],
        "opciones": ["selecciones", "jugadores"],
        "reglas": ["cambio"],
    },

    # ------------------------- Árbitros y alineaciones ---------------------
    "arbitrajes": {
        "titulo": "Designaciones",
        "desc": "Árbitros asignados a cada partido",
        "etiqueta": "designación",
        "sps_manual": {"alta": "SPTRANS.uspArbitraje_Registrar",
                       "modificacion": "SPTRANS.uspArbitraje_Update",
                       "baja": "SPTRANS.uspArbitraje_Bajar"},
        "pk": ["Arbitro", "Partido"],
        "base": """
            SELECT A.Arbitro, PE.Nombre AS ArbitroNombre, A.Funcion, A.Partido,
                   CONCAT('N° ', A.Partido, ' · ', P1.NOMBRE, ' vs ', P2.NOMBRE) AS PartidoNombre
            FROM arbitros.Arbitraje A
            JOIN equipos.Persona PE ON PE.IdPersona = A.Arbitro
            JOIN partidos.Partido P ON P.IdPartido = A.Partido
            JOIN equipos.Seleccion S1 ON S1.IdSeleccion = P.Eq1
            JOIN equipos.Pais P1 ON P1.IdPais = S1.IdPais
            JOIN equipos.Seleccion S2 ON S2.IdSeleccion = P.Eq2
            JOIN equipos.Pais P2 ON P2.IdPais = S2.IdPais""",
        "orden": "ORDER BY A.Partido, A.Funcion, PE.Nombre",
        "filtro_pk": "WHERE A.Arbitro = ? AND A.Partido = ?",
        "columnas": [("PartidoNombre", "Partido"), ("ArbitroNombre", "Árbitro"), ("Funcion", "Función")],
        "campos": [
            {"clave": "Arbitro", "etiqueta": "Árbitro", "tipo": "lista", "opciones": "arbitros",
             "obligatorio": True},
            {"clave": "Funcion", "etiqueta": "Función", "tipo": "lista_texto",
             "opciones": "funciones_arbitraje", "obligatorio": True},
            {"clave": "Partido", "etiqueta": "Partido", "tipo": "lista", "opciones": "partidos",
             "obligatorio": True},
        ],
        "opciones": ["arbitros", "funciones_arbitraje", "partidos"],
    },
    "alineaciones": {
        "titulo": "Alineaciones",
        "desc": "Titulares y suplentes por partido",
        "etiqueta": "alineación",
        "sps_manual": {"alta": "SP.uspAlineacion_Registrar", "baja": "SP.uspAlineacion_Bajar"},
        "pk": ["IdPartido", "IdJugador"],
        "base": """
            SELECT A.IdPartido, P.IdPartido AS Partido,
                   CONCAT('N° ', A.IdPartido, ' · ', P1.NOMBRE, ' vs ', P2.NOMBRE) AS PartidoNombre,
                   A.IdJugador, PE.Nombre AS JugadorNombre, A.Rol, A.PosicionCancha, A.Esquema
            FROM partidos.Alineacion A
            JOIN partidos.Partido P ON P.IdPartido = A.IdPartido
            JOIN equipos.Seleccion S1 ON S1.IdSeleccion = P.Eq1
            JOIN equipos.Pais P1 ON P1.IdPais = S1.IdPais
            JOIN equipos.Seleccion S2 ON S2.IdSeleccion = P.Eq2
            JOIN equipos.Pais P2 ON P2.IdPais = S2.IdPais
            JOIN equipos.Persona PE ON PE.IdPersona = A.IdJugador""",
        "orden": "ORDER BY A.IdPartido, A.Rol DESC, PE.Nombre",
        "filtro_pk": "WHERE A.IdPartido = ? AND A.IdJugador = ?",
        "columnas": [("PartidoNombre", "Partido"), ("JugadorNombre", "Jugador"),
                     ("Rol", "Rol"), ("PosicionCancha", "Posición"), ("Esquema", "Esquema")],
        "campos": [
            {"clave": "IdPartido", "etiqueta": "Partido", "tipo": "lista", "opciones": "partidos",
             "obligatorio": True},
            {"clave": "IdJugador", "etiqueta": "Jugador", "tipo": "lista", "opciones": "jugadores",
             "obligatorio": True},
            {"clave": "Rol", "etiqueta": "Rol", "tipo": "lista_texto", "opciones": "roles_alineacion",
             "obligatorio": True},
            {"clave": "PosicionCancha", "etiqueta": "Posición en cancha", "tipo": "texto", "max": 20},
            {"clave": "Esquema", "etiqueta": "Esquema", "tipo": "texto", "max": 10},
        ],
        "opciones": ["partidos", "jugadores", "roles_alineacion"],
    },
    "habla-idioma": {
        "titulo": "Idiomas de árbitros",
        "desc": "Idiomas que habla cada árbitro",
        "etiqueta": "idioma de árbitro",
        "buscar_sp": "HablaIdioma",
        "pk": ["Arbitro", "Idioma"],
        "base": """
            SELECT H.Arbitro, PE.Nombre AS ArbitroNombre, H.Idioma, I.Descripcion AS IdiomaNombre
            FROM arbitros.HablaIdioma H
            JOIN equipos.Persona PE ON PE.IdPersona = H.Arbitro
            JOIN arbitros.Idioma I ON I.IdIdioma = H.Idioma""",
        "orden": "ORDER BY PE.Nombre, I.Descripcion",
        "filtro_pk": "WHERE H.Arbitro = ? AND H.Idioma = ?",
        "columnas": [("ArbitroNombre", "Árbitro"), ("IdiomaNombre", "Idioma")],
        "campos": [
            {"clave": "Arbitro", "etiqueta": "Árbitro", "tipo": "lista", "opciones": "arbitros",
             "obligatorio": True},
            {"clave": "Idioma", "etiqueta": "Idioma", "tipo": "lista", "opciones": "idiomas",
             "obligatorio": True},
        ],
        "opciones": ["arbitros", "idiomas"],
    },

    # ------------------------------ Reportes -------------------------------
    "reportes": {
        "titulo": "Reportes de árbitros",
        "desc": "Sanciones e informes post partido",
        "etiqueta": "reporte",
        "sps_manual": {"alta": "SP.uspReporte_Registrar",
                       "modificacion": "SP.uspReporte_Update",
                       "baja": "SP.uspReporte_Baja"},
        "pk": "IdReporte",
        "base": """
            SELECT R.IdReporte, R.Razon, R.Descripcion, R.Arbitro, PE.Nombre AS ArbitroNombre,
                   R.Partido,
                   CONCAT('N° ', R.Partido, ' · ', P1.NOMBRE, ' vs ', P2.NOMBRE) AS PartidoNombre
            FROM arbitros.Reporte R
            JOIN equipos.Persona PE ON PE.IdPersona = R.Arbitro
            JOIN partidos.Partido P ON P.IdPartido = R.Partido
            JOIN equipos.Seleccion S1 ON S1.IdSeleccion = P.Eq1
            JOIN equipos.Pais P1 ON P1.IdPais = S1.IdPais
            JOIN equipos.Seleccion S2 ON S2.IdSeleccion = P.Eq2
            JOIN equipos.Pais P2 ON P2.IdPais = S2.IdPais""",
        "orden": "ORDER BY R.IdReporte DESC",
        "filtro_pk": "WHERE R.IdReporte = ?",
        "columnas": [("IdReporte", "ID"), ("Razon", "Razón"), ("ArbitroNombre", "Árbitro"),
                     ("PartidoNombre", "Partido"), ("Descripcion", "Descripción")],
        "campos": [
            {"clave": "Razon", "etiqueta": "Razón", "tipo": "lista_texto", "opciones": "razones_reporte",
             "obligatorio": True},
            {"clave": "Descripcion", "etiqueta": "Descripción", "tipo": "texto_largo", "max": 300},
            {"clave": "Arbitro", "etiqueta": "Árbitro", "tipo": "lista", "opciones": "arbitros",
             "obligatorio": True, "solo_alta": True},
            {"clave": "Partido", "etiqueta": "Partido", "tipo": "lista", "opciones": "partidos",
             "obligatorio": True, "solo_alta": True},
        ],
        "opciones": ["razones_reporte", "arbitros", "partidos"],
    },

    # ------------------------------ Publicidad -----------------------------
    "anunciantes": {
        "titulo": "Anunciantes",
        "desc": "Empresas anunciantes y su país",
        "etiqueta": "anunciante",
        "buscar_sp": "Anunciante",
        "pk": "IdAnunciante",
        "base": """
            SELECT A.IdAnunciante, A.Nombre, A.IdPais, P.NOMBRE AS Pais
            FROM publicidad.Anunciante A
            JOIN equipos.Pais P ON P.IdPais = A.IdPais""",
        "orden": "ORDER BY A.Nombre",
        "filtro_pk": "WHERE A.IdAnunciante = ?",
        "columnas": [("IdAnunciante", "ID"), ("Nombre", "Anunciante"), ("Pais", "País")],
        "campos": [
            {"clave": "Nombre", "etiqueta": "Nombre", "tipo": "texto", "max": 50, "obligatorio": True},
            {"clave": "IdPais", "etiqueta": "País", "tipo": "lista", "opciones": "paises",
             "obligatorio": True},
        ],
        "opciones": ["paises"],
    },
    "campanias": {
        "titulo": "Campañas",
        "desc": "Campañas publicitarias",
        "etiqueta": "campaña",
        "buscar_sp": "Campania",
        "pk": "IdCampania",
        "base": "SELECT C.IdCampania, C.Nombre, C.Descripcion FROM publicidad.Campania C",
        "orden": "ORDER BY C.Nombre",
        "filtro_pk": "WHERE C.IdCampania = ?",
        "columnas": [("IdCampania", "ID"), ("Nombre", "Campaña"), ("Descripcion", "Descripción")],
        "campos": [
            {"clave": "Nombre", "etiqueta": "Nombre", "tipo": "texto", "max": 50, "obligatorio": True},
            {"clave": "Descripcion", "etiqueta": "Descripción", "tipo": "texto_largo", "max": 200,
             "obligatorio": True},
        ],
    },
    "publicidades": {
        "titulo": "Piezas publicitarias",
        "desc": "Nombre, campaña e idioma",
        "etiqueta": "pieza",
        "buscar_sp": "Publicidad",
        "pk": "IdPublicidad",
        "base": """
            SELECT P.IdPublicidad, P.Nombre, P.IdCampania, C.Nombre AS CampaniaNombre,
                   P.IdIdioma, I.Descripcion AS IdiomaNombre
            FROM publicidad.Publicidad P
            JOIN publicidad.Campania C ON C.IdCampania = P.IdCampania
            JOIN arbitros.Idioma I ON I.IdIdioma = P.IdIdioma""",
        "orden": "ORDER BY P.Nombre",
        "filtro_pk": "WHERE P.IdPublicidad = ?",
        "columnas": [("IdPublicidad", "ID"), ("Nombre", "Pieza"), ("CampaniaNombre", "Campaña"),
                     ("IdiomaNombre", "Idioma")],
        "campos": [
            {"clave": "Nombre", "etiqueta": "Nombre", "tipo": "texto", "max": 50, "obligatorio": True},
            {"clave": "IdCampania", "etiqueta": "Campaña", "tipo": "lista", "opciones": "campanias",
             "obligatorio": True},
            {"clave": "IdIdioma", "etiqueta": "Idioma", "tipo": "lista", "opciones": "idiomas",
             "obligatorio": True},
        ],
        "opciones": ["campanias", "idiomas"],
    },
    "espacios": {
        "titulo": "Espacios publicitarios",
        "desc": "Cuatro espacios por sede",
        "etiqueta": "espacio",
        "buscar_sp": "EspacioPublicitario",
        "pk": "IdEP",
        "base": """
            SELECT E.IdEP, E.IdSede, S.Nombre AS Sede, E.Numero, E.Tipo, E.Costo
            FROM publicidad.EspacioPublicitario E
            JOIN sedes.Sede S ON S.IdSede = E.IdSede""",
        "orden": "ORDER BY S.Nombre, E.Numero",
        "filtro_pk": "WHERE E.IdEP = ?",
        "columnas": [("IdEP", "ID"), ("Sede", "Sede"), ("Numero", "N°"), ("Tipo", "Tipo"),
                     ("Costo", "Costo")],
        "campos": [
            {"clave": "IdSede", "etiqueta": "Sede", "tipo": "lista", "opciones": "sedes",
             "obligatorio": True, "solo_alta": True},
            {"clave": "Numero", "etiqueta": "Número", "tipo": "numero", "min": 1, "max": 4,
             "obligatorio": True, "solo_alta": True},
            {"clave": "Tipo", "etiqueta": "Tipo", "tipo": "texto", "max": 30, "obligatorio": True},
            {"clave": "Costo", "etiqueta": "Costo", "tipo": "decimal", "min": 0, "obligatorio": True},
        ],
        "opciones": ["sedes"],
    },
    "costos-franja": {
        "titulo": "Tarifas de franja",
        "desc": "Costo publicitario según franja y sede",
        "etiqueta": "tarifa",
        "buscar_sp": "CostoFranja",
        "pk": "IdCF",
        "base": """
            SELECT C.IdCF, C.IdSede, S.Nombre AS Sede, C.TipoFranja, C.Costo
            FROM publicidad.CostoFranja C
            JOIN sedes.Sede S ON S.IdSede = C.IdSede""",
        "orden": "ORDER BY S.Nombre, C.TipoFranja",
        "filtro_pk": "WHERE C.IdCF = ?",
        "columnas": [("IdCF", "ID"), ("Sede", "Sede"), ("TipoFranja", "Franja"), ("Costo", "Costo")],
        "campos": [
            {"clave": "IdSede", "etiqueta": "Sede", "tipo": "lista", "opciones": "sedes",
             "obligatorio": True, "solo_alta": True},
            {"clave": "TipoFranja", "etiqueta": "Franja", "tipo": "texto", "max": 30, "obligatorio": True},
            {"clave": "Costo", "etiqueta": "Costo", "tipo": "decimal", "min": 0, "obligatorio": True},
        ],
        "opciones": ["sedes"],
    },
    "historial-publicidad": {
        "titulo": "Publicidad emitida",
        "desc": "Piezas asignadas a cada partido y costo final",
        "etiqueta": "asignación",
        "buscar_sp": "HistorialPublicidad",
        "pk": "IdHistorial",
        "base": """
            SELECT H.IdHistorial, H.IdPublicidad, PU.Nombre AS PublicidadNombre,
                   H.IdPartido,
                   CONCAT('N° ', H.IdPartido, ' · ', P1.NOMBRE, ' vs ', P2.NOMBRE) AS PartidoNombre,
                   H.IdEP, CONCAT(SE.Nombre, ' · Espacio ', EP.Numero) AS EspacioNombre,
                   H.IdCF, CONCAT(SE.Nombre, ' · ', CF.TipoFranja) AS FranjaNombre, H.CostoFinal
            FROM publicidad.HistorialPublicidad H
            JOIN publicidad.Publicidad PU ON PU.IdPublicidad = H.IdPublicidad
            JOIN partidos.Partido P ON P.IdPartido = H.IdPartido
            JOIN equipos.Seleccion S1 ON S1.IdSeleccion = P.Eq1
            JOIN equipos.Pais P1 ON P1.IdPais = S1.IdPais
            JOIN equipos.Seleccion S2 ON S2.IdSeleccion = P.Eq2
            JOIN equipos.Pais P2 ON P2.IdPais = S2.IdPais
            JOIN publicidad.EspacioPublicitario EP ON EP.IdEP = H.IdEP
            JOIN sedes.Sede SE ON SE.IdSede = EP.IdSede
            JOIN publicidad.CostoFranja CF ON CF.IdCF = H.IdCF""",
        "orden": "ORDER BY P.Fecha DESC, H.IdHistorial DESC",
        "filtro_pk": "WHERE H.IdHistorial = ?",
        "columnas": [("IdHistorial", "ID"), ("PartidoNombre", "Partido"), ("PublicidadNombre", "Pieza"),
                     ("EspacioNombre", "Espacio"), ("FranjaNombre", "Franja"), ("CostoFinal", "Costo final")],
        "campos": [
            {"clave": "IdPublicidad", "etiqueta": "Pieza publicitaria", "tipo": "lista",
             "opciones": "publicidades", "obligatorio": True},
            {"clave": "IdPartido", "etiqueta": "Partido", "tipo": "lista", "opciones": "partidos",
             "obligatorio": True},
            {"clave": "IdEP", "etiqueta": "Espacio", "tipo": "lista", "opciones": "espacios",
             "obligatorio": True},
            {"clave": "CostoFinal", "etiqueta": "Costo final (vacío = espacio + franja)", "tipo": "decimal",
             "min": 0},
            {"clave": "IdCF", "etiqueta": "Tarifa de franja", "tipo": "lista", "opciones": "franjas",
             "obligatorio": True},
        ],
        "opciones": ["publicidades", "partidos", "espacios", "franjas"],
    },
    "publicidad-pais": {
        "titulo": "Público de las piezas",
        "desc": "Países a los que apunta cada pieza",
        "etiqueta": "público",
        "buscar_sp": "PublicidadPais",
        "pk": ["IdPublicidad", "IdPais"],
        "base": """
            SELECT PP.IdPublicidad, PU.Nombre AS PublicidadNombre, PP.IdPais, P.NOMBRE AS PaisNombre
            FROM publicidad.PublicidadPais PP
            JOIN publicidad.Publicidad PU ON PU.IdPublicidad = PP.IdPublicidad
            JOIN equipos.Pais P ON P.IdPais = PP.IdPais""",
        "orden": "ORDER BY PU.Nombre, P.NOMBRE",
        "filtro_pk": "WHERE PP.IdPublicidad = ? AND PP.IdPais = ?",
        "columnas": [("PublicidadNombre", "Pieza"), ("PaisNombre", "País")],
        "campos": [
            {"clave": "IdPublicidad", "etiqueta": "Pieza publicitaria", "tipo": "lista",
             "opciones": "publicidades", "obligatorio": True},
            {"clave": "IdPais", "etiqueta": "País", "tipo": "lista", "opciones": "paises",
             "obligatorio": True},
        ],
        "opciones": ["publicidades", "paises"],
    },
    "anunciante-campania": {
        "titulo": "Anunciantes por campaña",
        "desc": "Participación de anunciantes en campañas",
        "etiqueta": "participación",
        "buscar_sp": "AnuncianteCampania",
        "pk": ["IdAnunciante", "IdCampania"],
        "base": """
            SELECT AC.IdAnunciante, A.Nombre AS AnuncianteNombre, AC.IdCampania, C.Nombre AS CampaniaNombre
            FROM publicidad.AnuncianteCampania AC
            JOIN publicidad.Anunciante A ON A.IdAnunciante = AC.IdAnunciante
            JOIN publicidad.Campania C ON C.IdCampania = AC.IdCampania""",
        "orden": "ORDER BY C.Nombre, A.Nombre",
        "filtro_pk": "WHERE AC.IdAnunciante = ? AND AC.IdCampania = ?",
        "columnas": [("AnuncianteNombre", "Anunciante"), ("CampaniaNombre", "Campaña")],
        "campos": [
            {"clave": "IdAnunciante", "etiqueta": "Anunciante", "tipo": "lista", "opciones": "anunciantes",
             "obligatorio": True},
            {"clave": "IdCampania", "etiqueta": "Campaña", "tipo": "lista", "opciones": "campanias",
             "obligatorio": True},
        ],
        "opciones": ["anunciantes", "campanias"],
    },
    "motivos": {
        "titulo": "Motivos de cambio",
        "desc": "Motivos de sustitución",
        "etiqueta": "motivo",
        "buscar_sp": "Motivo",
        "pk": "IdMotivo",
        "base": "SELECT M.IdMotivo, M.Descripcion FROM publicidad.Motivo M",
        "orden": "ORDER BY M.Descripcion",
        "filtro_pk": "WHERE M.IdMotivo = ?",
        "columnas": [("IdMotivo", "ID"), ("Descripcion", "Motivo")],
        "campos": [{"clave": "Descripcion", "etiqueta": "Descripción", "tipo": "texto", "max": 100,
                    "obligatorio": True}],
    },
}


# --------------------------------------------------------------------------
# SP fijados por nombre exacto (firmas verificadas contra info.txt).
# Evita que la deteccion por patron agarre un SP equivocado. Un rol ausente
# (p. ej. sin "modificacion") significa que la entidad no tiene ese SP.
# --------------------------------------------------------------------------
def _crud(prefijo, esquema="SP", alta="Registrar", mod="Update", baja="Bajar"):
    d = {}
    if alta:
        d["alta"] = f"{esquema}.{prefijo}_{alta}"
    if mod:
        d["modificacion"] = f"{esquema}.{prefijo}_{mod}"
    if baja:
        d["baja"] = f"{esquema}.{prefijo}_{baja}"
    return d


_SPS_FIJOS = {
    "paises": _crud("uspPais"), "grupos": _crud("uspGrupo"), "fases": _crud("uspFase"),
    "periodos": _crud("Periodo", "partidos", "Alta", "Modificacion", "Baja"),
    "husos": _crud("uspHusoHorario"), "idiomas": _crud("uspIdioma"), "clubes": _crud("uspClub"),
    "sedes": _crud("uspSede"), "mundiales": _crud("uspMundial"), "selecciones": _crud("uspSeleccion"),
    "eventos": _crud("Evento", "partidos", "Alta", "Modificacion", "Baja"),
    "habla-idioma": _crud("uspHablaIdioma", mod=None),
    "anunciantes": _crud("uspAnunciante"), "campanias": _crud("uspCampania"),
    "publicidades": _crud("uspPublicidad"),
    "espacios": _crud("EspacioPublicitario"), "costos-franja": _crud("CostoFranja"),
    "historial-publicidad": _crud("uspHistorialPublicidad"),
    "publicidad-pais": _crud("uspPublicidadPais", mod=None),
    "anunciante-campania": _crud("uspAnuncianteCampania", mod=None),
    "motivos": _crud("uspMotivo"),
}
for _k, _sps in _SPS_FIJOS.items():
    ABM[_k]["sps_manual"] = _sps
    ABM[_k].pop("buscar_sp", None)
