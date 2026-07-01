import paho.mqtt.client as mqtt
import requests
import json
import time
import sys
import os  

MQTT_BROKER = "broker.hivemq.com"
MQTT_PORT = 1883
MQTT_TOPIC = "fisi/smat/estaciones/+/lecturas" # Wildcard para estaciones

API_URL = os.environ.get("API_URL", "http://127.0.0.1:8000/lecturas/")
JWT_TOKEN = os.environ.get(
    "JWT_TOKEN", 
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhZG1pbl9maXNpIiwiZXhwIjoxNzgxMTEzMjgxfQ.8ZNIbJprr1Xt_67Kj7KhlBA06gfJhx3QTPkyvCw1i-s"
)

# memoria caché local
cache_lecturas = {}

def on_connect(client, userdata, flags, rc, properties):
    if rc == 0:
        print("✅ Conectado exitosamente al Broker MQTT", flush=True)
        client.subscribe(MQTT_TOPIC)
        print(f"📡 Escuchando transmisiones en el tópico: {MQTT_TOPIC}", flush=True)
    else:
        print(f"❌ Error de conexión al Broker. Código de retorno: {rc}", flush=True)
        sys.exit(1)

def on_message(client, userdata, msg):
    try:
        # 1. Decodificar el payload binario a JSON
        payload_raw = msg.payload.decode("utf-8")
        data_json = json.loads(payload_raw)
        
        # 2. Extraer el ID dinámico
        topic_parts = msg.topic.split('/')
        estacion_id_str = topic_parts[-2] # Penúltimo elemento en fisi/smat/estaciones/X/lecturas
        
        # Filtro básico de seguridad
        if not estacion_id_str.isdigit():
            return
            
        estacion_id = int(estacion_id_str)
        nuevo_valor = float(data_json["valor"])
        tiempo_actual = time.time()
        
        print(f"\n📥 Telemetría recibida MQTT -> Estación [{estacion_id}]: {nuevo_valor} cm", flush=True)

        # filtro por umbral de cambio
        debe_enviar = False
        
        if estacion_id not in cache_lecturas:
            # Si es el primer dato que recibimos, lo enviamos sí o sí
            debe_enviar = True
            razon = "Primer registro"
        else:
            ultimo_registro = cache_lecturas[estacion_id]
            valor_anterior = ultimo_registro["valor"]
            tiempo_anterior = ultimo_registro["tiempo"]
            
            # Condición A: Han pasado más de 60 segundos (Reporte mínimo de vida)
            if (tiempo_actual - tiempo_anterior) > 60:
                debe_enviar = True
                razon = "Reporte de vida (>60s)"
            else:
                # Condición B: El valor varió en más de un ±5%
                diferencia_porcentual = abs(nuevo_valor - valor_anterior) / max(abs(valor_anterior), 0.0001)
                if diferencia_porcentual > 0.05:
                    debe_enviar = True
                    razon = f"Cambio brusco (>5%. Anterior: {valor_anterior})"
                else:
                    print("🛡️ [FILTRO EDGE ACTIVO] Dato redundante descartado para proteger la base de datos.", flush=True)

        if debe_enviar:
            # 3. Preparar datos para la API
            api_payload = {
                "valor": nuevo_valor,
                "estacion_id": estacion_id
            }
            
            # 4. Ingestión de datos vía HTTP POST
            headers = {
                "Content-Type": "application/json",
                "Authorization": f"Bearer {JWT_TOKEN}"
            }
            
            response = requests.post(API_URL, json=api_payload, headers=headers)
            
            if response.status_code in (200, 201):
                print(f"🚀 [DB Sincronizada] Guardado en SQLite. Razón: {razon}", flush=True)
                # Actualizar la caché local solo si se guardó con éxito
                cache_lecturas[estacion_id] = {"valor": nuevo_valor, "tiempo": tiempo_actual}
            else:
                print(f"❌ [Fallo de Ingesta] API rechazó el dato. Código: {response.status_code}", flush=True)

    except KeyError as e:
        print(f"⚠️ Error de esquema: Falta la llave {e} en el payload MQTT.", flush=True)
    except ValueError:
        print("⚠️ Error de casteo: El valor o el ID no son numéricos.", flush=True)
    except Exception as e:
        print(f"❌ Error crítico en el Bridge: {e}", flush=True)

def main():
    bridge_client = mqtt.Client(callback_api_version=mqtt.CallbackAPIVersion.VERSION2)
    bridge_client.on_connect = on_connect
    bridge_client.on_message = on_message
    
    try:
        print("🛠️ Inicializando el Bridge de Acoplamiento SMAT con Filtro de Borde...", flush=True)
        bridge_client.connect(MQTT_BROKER, MQTT_PORT, 60)
        bridge_client.loop_forever()
    except KeyboardInterrupt:
        print("\n🛑 Bridge detenido por el administrador.", flush=True)

if __name__ == "__main__":
    main()