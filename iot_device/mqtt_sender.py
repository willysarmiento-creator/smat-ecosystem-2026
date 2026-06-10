import paho.mqtt.client as mqtt
import json
import time
import random

BROKER = "broker.hivemq.com"
PORT = 1883
TOPIC = "fisi/smat/estaciones/1/lecturas" # ¡Atención al nuevo tópico!

client = mqtt.Client(callback_api_version=mqtt.CallbackAPIVersion.VERSION2)
client.connect(BROKER, PORT)
print(f"Iniciando Sensor IoT en {TOPIC}...")

try:
    while True:
        payload = {
            "valor": round(random.uniform(50.0, 51.0), 2),
            "timestamp": time.time()
        }
        client.publish(TOPIC, json.dumps(payload))
        print(f"Enviado por MQTT: {payload['valor']} cm")
        time.sleep(5) 
except KeyboardInterrupt:
    print("Apagando sensor...")
finally:
    client.disconnect()