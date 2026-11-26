Cómo ejecutar la interfaz:

Abrir CMD y ubicarse en la carpeta TP-2026-2C-Mundial-de-Futbol\Interfaz.

Ejecutar: python app.py.

Abrir en el navegador el enlace http://... que aparece en la consola.

Convocatoria:
En "Consultar" hay una vista "Convocatoria" con los cambios de plantel (altas, bajas y motivo).
El motivo se guarda cifrado con AES-128 (Entrega 8, equipos.CambioConvocatoria.Motivo).
- Perfil Consulta: ve el motivo cifrado (valor hexadecimal).
- Perfil Administrador: el backend llama a SP.uspSeguridad_DescifrarMotivoCambioConvocatoria
  y muestra el motivo en texto plano, tanto en Consultar como en el ABM.
Los demas perfiles no tienen acceso a esta vista.