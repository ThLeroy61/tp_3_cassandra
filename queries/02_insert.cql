USE meteo;

-- Insertion : un nouveau relevé
INSERT INTO releves_temperature (ville_id, observed_at, temperature_2m)
VALUES ('paris', '2026-10-10 12:00:00', 15.0);

-- Vérification
SELECT * FROM releves_temperature
WHERE ville_id = 'paris' AND observed_at = '2026-10-10 12:00:00';
