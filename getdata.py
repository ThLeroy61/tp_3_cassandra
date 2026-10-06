import json
import urllib.request
from datetime import datetime
from cassandra.cluster import Cluster

# 1. Récupérer 20 relevés horaires de température (Paris)
url = ("https://api.open-meteo.com/v1/forecast"
       "?latitude=48.85&longitude=2.35&hourly=temperature_2m&forecast_hours=20")
with urllib.request.urlopen(url) as r:
    hourly = json.load(r)["hourly"]

cluster = Cluster(["localhost"], port=9042)
session = cluster.connect("meteo")

session.execute(
    "INSERT INTO villes (ville_id, nom, latitude, longitude) VALUES (%s, %s, %s, %s)",
    ("paris", "Paris", 48.85, 2.35),
)

insert = session.prepare(
    "INSERT INTO releves_temperature (ville_id, observed_at, temperature_2m) VALUES (?, ?, ?)"
)
for t, temp in zip(hourly["time"], hourly["temperature_2m"]):
    session.execute(insert, ("paris", datetime.fromisoformat(t), temp))

cluster.shutdown()