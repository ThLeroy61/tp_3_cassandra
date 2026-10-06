# Requêtes métier

Keyspace `meteo`, tables `villes` (clé : `ville_id`) et `releves_temperature` (partition key : `ville_id`, clustering key : `observed_at`).

## REQ-01

**Besoin métier :**
Afficher la dernière température connue à Paris.

**Requête CQL :**
```sql
SELECT observed_at, temperature_2m
FROM releves_temperature
WHERE ville_id = 'paris'
ORDER BY observed_at DESC
LIMIT 1;
```

**Clé de partition utilisée :**
`ville_id`

**Justification :**
La requête cible une seule partition (Paris). Les lignes y sont déjà triées par `observed_at` (clustering key), donc `ORDER BY observed_at DESC LIMIT 1` lit directement la dernière ligne sans parcourir toute la table.

## REQ-02

**Besoin métier :**
Suivre l'évolution de la température sur une plage horaire donnée (par exemple l'après-midi).

**Requête CQL :**
```sql
SELECT observed_at, temperature_2m
FROM releves_temperature
WHERE ville_id = 'paris'
  AND observed_at >= '2026-10-06 12:00:00'
  AND observed_at <= '2026-10-06 18:00:00';
```

**Clé de partition utilisée :**
`ville_id`

**Justification :**
La clé de partition fixe la ville, et la clustering key `observed_at` permet de filtrer par intervalle de temps dans la partition. Les résultats reviennent triés par heure, sans `ALLOW FILTERING`.

## REQ-03

**Besoin métier :**
Connaître la température prévue à une heure précise.

**Requête CQL :**
```sql
SELECT temperature_2m
FROM releves_temperature
WHERE ville_id = 'paris'
  AND observed_at = '2026-10-06 15:00:00';
```

**Clé de partition utilisée :**
`ville_id`

**Justification :**
La clé primaire complète (`ville_id` + `observed_at`) est fournie : Cassandra identifie la partition grâce au token, puis la ligne exacte. C'est le type de lecture le plus rapide.

## REQ-04

**Besoin métier :**
Obtenir les températures minimale, maximale et moyenne sur la période récupérée.

**Requête CQL :**
```sql
SELECT MIN(temperature_2m), MAX(temperature_2m), AVG(temperature_2m)
FROM releves_temperature
WHERE ville_id = 'paris';
```

**Clé de partition utilisée :**
`ville_id`

**Justification :**
Les fonctions d'agrégation sont calculées sur une seule partition, ce qui reste efficace et évite de solliciter tous les nœuds. Tous les relevés d'une ville étant dans la même partition, un seul jeu de réplicas répond.

## REQ-05

**Besoin métier :**
Retrouver les coordonnées d'une ville, par exemple pour l'afficher sur une carte.

**Requête CQL :**
```sql
SELECT nom, latitude, longitude
FROM villes
WHERE ville_id = 'paris';
```

**Clé de partition utilisée :**
`ville_id` (table `villes`)

**Justification :**
La table `villes` est interrogée par sa clé primaire : une seule partition, une seule ligne. Garder les coordonnées dans une table à part évite de les répéter dans chaque relevé de température.
