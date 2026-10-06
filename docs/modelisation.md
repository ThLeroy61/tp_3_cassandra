# Modélisation Cassandra

Sujet : relevés horaires de température pour Paris (API Open-Meteo).

## Keyspace

```sql
CREATE KEYSPACE meteo
WITH replication = {
    'class': 'NetworkTopologyStrategy',
    'dc1': 3
};
```

Le facteur de réplication de 3 dans `dc1` signifie que chaque donnée est copiée sur les 3 nœuds du cluster (`cass1`, `cass2`, `cass3`).

## Tables et clés

```sql
CREATE TABLE villes (
    ville_id text PRIMARY KEY,
    nom text,
    latitude double,
    longitude double
);

CREATE TABLE releves_temperature (
    ville_id text,
    observed_at timestamp,
    temperature_2m double,
    PRIMARY KEY (ville_id, observed_at)
);
```

| Table | Colonnes | Clé de partition | Clé de clustering |
|---|---|---|---|
| `villes` | `ville_id`, `nom`, `latitude`, `longitude` | `ville_id` | aucune |
| `releves_temperature` | `ville_id`, `observed_at`, `temperature_2m` | `ville_id` | `observed_at` |

## Choix de modélisation

- **`ville_id` comme clé de partition** : toutes les requêtes portent sur une ville. Les relevés d'une ville sont stockés ensemble, donc une requête ne lit qu'une partition, sur les mêmes réplicas.
- **`observed_at` comme clé de clustering** : une ville a plusieurs relevés, il faut distinguer chaque ligne dans la partition. La clustering key trie aussi les lignes par heure, ce qui rend efficaces le dernier relevé, la plage horaire et l'heure précise.
- **Pas de clé de clustering dans `villes`** : une ville correspond à une seule ligne.
- **Deux tables séparées** : les coordonnées d'une ville ne sont pas répétées dans chaque relevé.
- **Pas d'`ALLOW FILTERING`** : chaque requête fournit la clé de partition, donc Cassandra sait directement où lire.

## Besoins métier et requêtes

### REQ-01 : dernière température connue à Paris

```sql
SELECT observed_at, temperature_2m
FROM releves_temperature
WHERE ville_id = 'paris'
ORDER BY observed_at DESC
LIMIT 1;
```

Clé de partition : `ville_id`. Les lignes sont déjà triées par `observed_at`, donc la dernière se lit directement.

### REQ-02 : évolution de la température sur une plage horaire

```sql
SELECT observed_at, temperature_2m
FROM releves_temperature
WHERE ville_id = 'paris'
  AND observed_at >= '2026-10-06 12:00:00'
  AND observed_at <= '2026-10-06 18:00:00';
```

Clé de partition : `ville_id`. La clustering key permet de filtrer par intervalle dans la partition.

### REQ-03 : température à une heure précise

```sql
SELECT temperature_2m
FROM releves_temperature
WHERE ville_id = 'paris'
  AND observed_at = '2026-10-06 15:00:00';
```

Clé de partition : `ville_id`. La clé primaire complète est fournie, c'est la lecture la plus rapide.

### REQ-04 : températures minimale, maximale et moyenne

```sql
SELECT MIN(temperature_2m), MAX(temperature_2m), AVG(temperature_2m)
FROM releves_temperature
WHERE ville_id = 'paris';
```

Clé de partition : `ville_id`. L'agrégation porte sur une seule partition.

### REQ-05 : coordonnées d'une ville

```sql
SELECT nom, latitude, longitude
FROM villes
WHERE ville_id = 'paris';
```

Clé de partition : `ville_id` (table `villes`). Lecture par clé primaire : une partition, une ligne.