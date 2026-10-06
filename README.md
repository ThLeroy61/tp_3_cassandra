# TP Cassandra : cluster et données météo

## Sujet

Données météo : relevés horaires de température pour Paris (même sujet que le TP1).

## API utilisée

[Open-Meteo](https://open-meteo.com/), API météo gratuite et sans clé.

```
https://api.open-meteo.com/v1/forecast?latitude=48.85&longitude=2.35&hourly=temperature_2m&forecast_hours=20
```

| Paramètre | Valeur | Rôle |
|---|---|---|
| `latitude` | 48.85 | latitude de Paris |
| `longitude` | 2.35 | longitude de Paris |
| `hourly` | `temperature_2m` | variable horaire demandée |
| `forecast_hours` | 20 | nombre d'heures renvoyées |

## Données

20 relevés horaires de température de l'air à 2 mètres du sol, pour Paris.

| Champ | Description |
|---|---|
| `latitude`, `longitude` | coordonnées du lieu |
| `hourly.time` | heure de chaque relevé (ISO 8601) |
| `hourly.temperature_2m` | température en °C à 2 m |

## Modèle Cassandra

Keyspace `meteo`, avec `NetworkTopologyStrategy` et `'dc1': 3` : chaque donnée est copiée sur les 3 nœuds du cluster.

**Table `villes`** : une ligne par ville.

| Colonne | Type | Rôle |
|---|---|---|
| `ville_id` | text | clé de partition |
| `nom` | text | |
| `latitude` | double | |
| `longitude` | double | |

**Table `releves_temperature`** : un relevé par ville et par heure.

| Colonne | Type | Rôle |
|---|---|---|
| `ville_id` | text | clé de partition |
| `observed_at` | timestamp | clé de clustering |
| `temperature_2m` | double | |

- `ville_id` est la clé de partition car toutes les requêtes portent sur une ville : tous ses relevés sont stockés ensemble, et une requête ne lit qu'une partition.
- `observed_at` est la clé de clustering : elle distingue les relevés d'une même ville et les trie par heure, ce qui permet de chercher le dernier relevé, une plage horaire ou une heure précise.
- Aucune requête n'utilise `ALLOW FILTERING`.

## Principales requêtes métier

Détail dans [`docs/requetes_metier.md`](docs/requetes_metier.md), requêtes de manipulation dans [`queries/`](queries/).

| Réf. | Besoin métier |
|---|---|
| REQ-01 | Dernière température connue à Paris |
| REQ-02 | Évolution de la température sur une plage horaire |
| REQ-03 | Température à une heure précise |
| REQ-04 | Températures minimale, maximale et moyenne |
| REQ-05 | Coordonnées d'une ville |