import requests
import time
import random

# CONFIGURACIÓN
API_URL = "http://127.0.0.1:8000/lecturas/"  
ESTACION_ID = 1 
TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhZG1pbl9maXNpIiwiZXhwIjoxNzc5OTAxMzM5fQ.jYX3C0c4EQIEoDsBeCdDS7rtvPDNeWykga9Yz4AckpA" 

def leer_sensor_emulado():
    # Simulamos una lectura de nivel de río (10.5 a 85.0 cm)
    return round(random.uniform(10.5, 85.0), 2)

def enviar_telemetria():
    print(f"--- Iniciando Emisor IoT para Estación {ESTACION_ID} ---")
    
    while True:
        valor = leer_sensor_emulado()
        payload = {
            "valor": valor,
            "estacion_id": ESTACION_ID
        }
        headers = {
            "Authorization": f"Bearer {TOKEN}"
        }

        es_alerta = valor > 70.0
        if es_alerta:
            print(f"[ALERTA] Umbral de inundación superado: {valor} cm")
            tiempo_espera = 2  
        else:
            tiempo_espera = 10 

        try:
            response = requests.post(API_URL, json=payload, headers=headers)
            if response.status_code == 200:
                if es_alerta:
                    print(f"[CRÍTICO] Lectura enviada: {valor} cm (Próxima en {tiempo_espera}s)")
                else:
                    print(f"[OK] Lectura enviada: {valor} cm (Próxima en {tiempo_espera}s)")
            else:
                print(f"[ERROR] Código: {response.status_code} - Detalle: {response.text}")
        except Exception as e:
            print(f"[CRÍTICO] No hay conexión con el servidor: {e}")
        
        # 2. Pausamos el script según el tiempo determinado
        time.sleep(tiempo_espera)

if __name__ == "__main__":
    enviar_telemetria()