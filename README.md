# Cluster Cassandra : données météo

TP « Données distribuées », M2 Big Data & IA. Un cluster Cassandra à 3 nœuds sous Docker, alimenté par des relevés de température pour Paris, avec étude de la réplication, des niveaux de cohérence et d'une panne de nœud.

Le compte-rendu complet est dans [`docs/compte-rendu.md`](docs/compte-rendu.md), et le détail des réponses aux questions dans [`docs/réponse_tp.pdf`](docs/réponse_tp.pdf).

## Sujet et données

- **Sujet :** relevés horaires de température pour Paris.
- **API :** [Open-Meteo](https://open-meteo.com/) (gratuite, sans clé).
- **Données :** 20 relevés horaires de la température de l'air à 2 m.

```
https://api.open-meteo.com/v1/forecast?latitude=48.85&longitude=2.35&hourly=temperature_2m&forecast_hours=20
```

| Champ | Description |
|---|---|
| `latitude`, `longitude` | coordonnées du lieu |
| `hourly.time` | heure de chaque relevé (ISO 8601) |
| `hourly.temperature_2m` | température en °C à 2 m |

## Architecture du cluster

Cluster `tp2-cluster` : 3 nœuds Cassandra 4.1 (Docker Compose), dans un datacenter `dc1`, un nœud par rack.

```
Cluster tp2-cluster
        │
       dc1
 ┌──────┼──────┐
rack1  rack2  rack3
 │      │      │
cass1  cass2  cass3
```

- Nœuds égaux, sans chef. `cass1` est le seed et expose le port 9042.
- `GossipingPropertyFileSnitch` et 16 tokens par nœud.
- Keyspace `meteo` avec `NetworkTopologyStrategy` et `'dc1': 3` : chaque donnée est copiée sur les 3 nœuds.

## Modèle Cassandra

| Table | Colonnes | Clé de partition | Clé de clustering |
|---|---|---|---|
| `villes` | `ville_id`, `nom`, `latitude`, `longitude` | `ville_id` | aucune |
| `releves_temperature` | `ville_id`, `observed_at`, `temperature_2m` | `ville_id` | `observed_at` |

Toutes les requêtes portent sur une ville, donc `ville_id` est la clé de partition. `observed_at` distingue les relevés d'une même ville et les trie par heure. Aucune requête n'utilise `ALLOW FILTERING`.

## Requêtes métier

| Réf. | Besoin métier |
|---|---|
| REQ-01 | Dernière température connue à Paris |
| REQ-02 | Évolution de la température sur une plage horaire |
| REQ-03 | Température à une heure précise |
| REQ-04 | Températures minimale, maximale et moyenne |
| REQ-05 | Coordonnées d'une ville |

## Réplication, cohérence et panne

Avec RF = 3, le scénario réalisé est le suivant :

| Étape | Résultat |
|---|---|
| 3 nœuds démarrés | `nodetool status` : 3 nœuds en `UN` |
| Arrêt de `cass3` | 2 réplicas disponibles sur 3 |
| Lecture en `ONE` (1 réplica exigé) | fonctionne |
| Lecture en `QUORUM` (2 exigés) | fonctionne |
| Lecture en `ALL` (3 exigés) | échoue (`Unavailable`) |
| Redémarrage de `cass3` | retour en `UN`, données rattrapées |

Une requête réussit si le nombre de réplicas disponibles est supérieur ou égal au nombre exigé par le niveau de cohérence. La réplication permet au cluster de continuer à répondre quand un nœud tombe, et au nœud de rattraper son retard à son retour.

## Lancer le projet

Démarrer les nœuds un par un, en vérifiant l'état après chaque démarrage :

```bash
docker compose up -d cass1
docker exec cass1 nodetool status

docker compose up -d cass2
docker exec cass1 nodetool status

docker compose up -d cass3
docker exec cass1 nodetool status
```

Attendre que chaque nœud soit en `UN` avant de lancer le suivant. Puis ouvrir `cqlsh` :

```bash
docker exec -it cass1 cqlsh
```

Pour importer les données de l'API, installer le driver puis lancer le script Python d'import :

```bash
pip install cassandra-driver
```

## Contenu du dépôt

| Élément | Contenu |
|---|---|
| `docker-compose.yml` | définition du cluster à 3 nœuds |
| `docs/compte-rendu.md` | compte-rendu du TP |
| `docs/réponse_tp.pdf` | réponses détaillées aux questions du TP |