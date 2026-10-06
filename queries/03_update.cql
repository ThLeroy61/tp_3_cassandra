USE meteo;

-- Modification : corriger la température du relevé inséré
UPDATE releves_temperature
SET temperature_2m = 16.5
WHERE ville_id = 'paris' AND observed_at = '2026-10-10 12:00:00';

-- Vérification
SELECT * FROM releves_temperature
WHERE ville_id = 'paris' AND observed_at = '2026-10-10 12:00:00';
