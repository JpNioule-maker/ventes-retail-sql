-- Les données s'arrêtent au 30 septembre 2026, date de l'analyse.
-- Les comparaisons 2025-2026 portent sur la période janvier-septembre.
DELETE FROM ventes WHERE date_vente > '2026-09-30';