USE meteo;

-- Consultation : la ville
SELECT * FROM villes;

-- Consultation : tous les relevés de Paris (triés par heure)
SELECT * FROM releves_temperature WHERE ville_id = 'paris';

-- Consultation : une plage horaire
SELECT observed_at, temperature_2m
FROM releves_temperature
WHERE ville_id = 'paris'
  AND observed_at >= '2026-10-06 12:00:00'
  AND observed_at <= '2026-10-06 18:00:00';

-- Consultation : les 5 relevés les plus récents
SELECT * FROM releves_temperature
WHERE ville_id = 'paris'
ORDER BY observed_at DESC
LIMIT 5;

-- Consultation : nombre de relevés
SELECT COUNT(*) FROM releves_temperature WHERE ville_id = 'paris';
