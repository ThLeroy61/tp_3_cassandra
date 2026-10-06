USE meteo;

-- Suppression : retirer le relevé inséré
DELETE FROM releves_temperature
WHERE ville_id = 'paris' AND observed_at = '2026-10-10 12:00:00';

-- Vérification (doit renvoyer 0 ligne)
SELECT * FROM releves_temperature
WHERE ville_id = 'paris' AND observed_at = '2026-10-10 12:00:00';
