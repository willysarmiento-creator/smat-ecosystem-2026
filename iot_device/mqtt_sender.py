import paho.mqtt.client as mqtt
import json
import time
import random

BROKER = "broker.hivemq.com"
PORT = 1883
TOPIC = "fisi/smat/estaciones/1/lecturas" 

client = mqtt.Client(callback_api_version=mqtt.CallbackAPIVersion.VERSION2)
client.connect(BROKER, PORT)
# Agregar flush=True
print(f"Iniciando Sensor IoT en {TOPIC}...", flush=True)

try:
    while True:
        payload = {
            "valor": round(random.uniform(50.0, 81.0), 2),
            "timestamp": time.time()
        }
        client.publish(TOPIC, json.dumps(payload))
        # Agregar flush=True
        print(f"Enviado por MQTT: {payload['valor']} cm", flush=True)
        time.sleep(5) 
except KeyboardInterrupt:
    print("Apagando sensor...", flush=True)
finally:
    client.disconnect()