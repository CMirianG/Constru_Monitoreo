import requests
import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime

# 1. Configura tu archivo JSON descargado desde Firebase
cred = credentials.Certificate("credenciales-firebase.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

# 2. URL de tu canal ThingSpeak
url = "https://api.thingspeak.com/channels/2956848/feeds.json?results=2"

def sincronizar():
    response = requests.get(url)
    if response.status_code == 200:
        data = response.json()
        feed = data['feeds'][0]

        sonido = float(feed['field1']) if feed['field1'] else 0
        co2 = float(feed['field2']) if feed['field2'] else 0
        timestamp = datetime.now()

        # Guardar en sensores (últimos valores)
        db.collection('sensores').document('sonido').set({
            'tipo': 'sonido',
            'valor': sonido,
            'timestamp': timestamp
        })
        db.collection('sensores').document('co2').set({
            'tipo': 'co2',
            'valor': co2,
            'timestamp': timestamp
        })

        # Guardar en historial
        db.collection('historial').add({
            'tipo': 'sonido',
            'valor': sonido,
            'timestamp': timestamp
        })
        db.collection('historial').add({
            'tipo': 'co2',
            'valor': co2,
            'timestamp': timestamp
        })

        print("✅ Datos actualizados en Firebase")
    else:
        print("❌ Error al obtener datos de ThingSpeak:", response.status_code)

# Ejecutar
if __name__ == "__main__":
    sincronizar()
