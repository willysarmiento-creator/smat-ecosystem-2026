Simulación IoT (Edge Computing): El ecosistema SMAT cuenta con un script de Python 
(iot_device/sensor_emitter.py) que emula un microcontrolador remoto enviando lecturas 
hídricas de forma autónoma. Se comunica con la API de FastAPI mediante peticiones HTTP POST, 
validando su identidad a través de un Token JWT en las cabeceras (Authorization: Bearer <token>). 
El script ajusta su frecuencia de envío si detecta un umbral de desborde crítico.