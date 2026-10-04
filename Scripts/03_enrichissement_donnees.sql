
-- Enrichissement de ma_base_test pour Power BI (3 années complètes)

-- À exécuter UNE SEULE FOIS dans le Query Tool de ma_base_test (F5),
-- sans rien sélectionner. Remplace les versions précédentes du script.
-- Vos données existantes sont conservées. Le script ajoute :
--   - 2 magasins, 12 produits et assez de clients pour atteindre 100 ;
--   - le coût d'achat des produits (pour analyser la marge) ;
--   - le prix payé dans chaque vente, le canal, le magasin, la remise ;
--   - une table calendrier du 01/01/2024 au 31/12/2026, jours fériés compris ;
--   - environ 2 900 ventes du 1er janvier 2024 au 31 décembre 2026,
--     soit trois années complètes (fin 2026 simulée)


-- 0. Sécurité : arrêter tout si un script d'enrichissement a déjà tourné
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_name = 'ventes' AND column_name = 'canal') THEN
        RAISE EXCEPTION 'Un script d''enrichissement a déjà été exécuté (la colonne ventes.canal existe). Rien n''a été modifié.';
    END IF;
END $$;

-- Graine du hasard : à base identique, les données générées sont identiques
SELECT setseed(0.42);

-- 1. Deux nouveaux magasins
INSERT INTO magasins (ville, date_ouverture) VALUES
('Bordeaux',  '2022-04-01'),
('Marseille', '2023-10-15');

-- 2. Douze nouveaux produits, puis le coût d'achat de chaque produit
INSERT INTO produits (nom, categorie, prix_unitaire) VALUES
('Clavier mécanique',         'Informatique',  89.00),
('Disque SSD 1 To',           'Informatique', 109.00),
('Webcam Full HD',            'Informatique',  59.90),
('Station d''accueil USB-C',  'Informatique', 149.00),
('Imprimante laser',          'Informatique', 199.00),
('Écouteurs sans fil',        'Audio',         99.00),
('Barre de son',              'Audio',        229.00),
('Micro USB',                 'Audio',         69.90),
('Repose-pieds',              'Mobilier',      34.90),
('Étagère murale',            'Mobilier',      59.00),
('Caisson de rangement',      'Mobilier',     129.00),
('Fauteuil ergonomique',      'Mobilier',     449.00);

ALTER TABLE produits ADD COLUMN prix_achat NUMERIC(10,2);
UPDATE produits
SET prix_achat = ROUND(prix_unitaire * CASE categorie
                                          WHEN 'Informatique' THEN 0.70
                                          WHEN 'Audio'        THEN 0.55
                                          ELSE 0.50 END, 2);
ALTER TABLE produits ALTER COLUMN prix_achat SET NOT NULL;

-- 3. De nouveaux clients, inscrits en 2023, jusqu'à 100 clients au total
--    (le nombre à créer est calculé à partir des clients déjà présents ;
--     les grandes villes reviennent plus souvent dans la liste)
INSERT INTO clients (nom, prenom, email, ville, date_inscription)
SELECT
    (ARRAY['Garcia','Roux','Fournier','Girard','Bonnet','Lambert','Fontaine',
           'Rousseau','Vincent','Muller','Lefèvre','Faure','André','Mercier',
           'Blanc','Guérin','Boyer','Garnier','Chevalier','François',
           'Legrand','Gauthier','Perrin','Morin','Clément','Robin','Masson',
           'Sanchez','Henry','Nicolas'])[1 + floor(random() * 30)::int],
    (ARRAY['Camille','Louis','Manon','Jules','Sarah','Arthur','Julie','Paul',
           'Lina','Adam','Clara','Tom','Zoé','Raphaël','Alice','Mathis',
           'Jade','Eva','Noah','Maxime','Nicolas','Laura','Antoine','Marie',
           'Julien','Pauline','Romain','Océane','Mathilde','Victor'])[1 + floor(random() * 30)::int],
    'client' || g || '@exemple.fr',
    (ARRAY['Paris','Paris','Paris','Lyon','Lyon','Toulouse','Toulouse',
           'Marseille','Marseille','Bordeaux','Lille','Nantes',
           'Montpellier','Strasbourg','Nice'])[1 + floor(random() * 15)::int],
    DATE '2023-01-01' + floor(random() * 365)::int
FROM generate_series(1, 100 - (SELECT COUNT(*) FROM clients)) AS g;

-- 4. La table calendrier : une ligne par jour, années complètes
DROP TABLE IF EXISTS calendrier;
CREATE TABLE calendrier (
    date_jour    DATE PRIMARY KEY,
    annee        INTEGER     NOT NULL,
    trimestre    INTEGER     NOT NULL,
    mois         INTEGER     NOT NULL,
    nom_mois     VARCHAR(10) NOT NULL,
    annee_mois   CHAR(7)     NOT NULL,   -- ex. 2026-03, pratique pour trier
    jour_semaine INTEGER     NOT NULL,   -- 1 = lundi ... 7 = dimanche
    nom_jour     VARCHAR(10) NOT NULL,
    est_weekend  BOOLEAN     NOT NULL,
    est_ferie    BOOLEAN     NOT NULL DEFAULT FALSE
);

INSERT INTO calendrier (date_jour, annee, trimestre, mois, nom_mois, annee_mois,
                        jour_semaine, nom_jour, est_weekend)
SELECT d::date,
       EXTRACT(YEAR    FROM d)::int,
       EXTRACT(QUARTER FROM d)::int,
       EXTRACT(MONTH   FROM d)::int,
       (ARRAY['Janvier','Février','Mars','Avril','Mai','Juin','Juillet',
              'Août','Septembre','Octobre','Novembre','Décembre'])[EXTRACT(MONTH FROM d)::int],
       to_char(d, 'YYYY-MM'),
       EXTRACT(ISODOW FROM d)::int,
       (ARRAY['Lundi','Mardi','Mercredi','Jeudi','Vendredi','Samedi','Dimanche'])[EXTRACT(ISODOW FROM d)::int],
       EXTRACT(ISODOW FROM d) IN (6, 7)
FROM generate_series(DATE '2024-01-01', DATE '2026-12-31', INTERVAL '1 day') AS d;

-- Jours fériés français : dates fixes, puis lundi de Pâques, Ascension
-- et lundi de Pentecôte, calculés à partir du dimanche de Pâques
UPDATE calendrier
SET est_ferie = TRUE
WHERE (mois, EXTRACT(DAY FROM date_jour)::int) IN
          ((1, 1), (5, 1), (5, 8), (7, 14), (8, 15), (11, 1), (11, 11), (12, 25))
   OR date_jour IN (SELECT paques + ecart
                    FROM unnest(ARRAY[DATE '2024-03-31', DATE '2025-04-20', DATE '2026-04-05']) AS paques
                    CROSS JOIN unnest(ARRAY[1, 39, 50]) AS ecart);

-- 5. Quatre nouvelles colonnes dans ventes
ALTER TABLE ventes
    ADD COLUMN magasin_id INTEGER REFERENCES magasins(magasin_id),
    ADD COLUMN canal      VARCHAR(20),
    ADD COLUMN prix_vente NUMERIC(10,2),
    ADD COLUMN remise_pct NUMERIC(4,1) NOT NULL DEFAULT 0
                          CHECK (remise_pct BETWEEN 0 AND 50);

-- 6. Les ventes déjà présentes : prix actuel, et en magasin si la ville
--    du client en a un et que ce n'était ni un dimanche ni un jour férié
UPDATE ventes v
SET magasin_id = CASE WHEN m.magasin_id IS NOT NULL
                       AND NOT EXISTS (SELECT 1 FROM calendrier k
                                       WHERE k.date_jour = v.date_vente
                                         AND (k.jour_semaine = 7 OR k.est_ferie))
                      THEN m.magasin_id END,
    canal      = CASE WHEN m.magasin_id IS NOT NULL
                       AND NOT EXISTS (SELECT 1 FROM calendrier k
                                       WHERE k.date_jour = v.date_vente
                                         AND (k.jour_semaine = 7 OR k.est_ferie))
                      THEN 'Magasin' ELSE 'En ligne' END,
    prix_vente = p.prix_unitaire
FROM clients c
LEFT JOIN magasins m ON m.ville = c.ville,
     produits p
WHERE c.client_id = v.client_id
  AND p.produit_id = v.produit_id;

-- 7. Génération des ventes, jour par jour
DO $$
DECLARE
    cl_ids     INTEGER[];  -- clients pouvant acheter
    cl_dates   DATE[];     -- leur date d'inscription
    cl_mag     INTEGER[];  -- le magasin de leur ville (ou NULL)
    cl_ouv     DATE[];     -- la date d'ouverture de ce magasin
    pr_2024    INTEGER[];  -- produits pondérés par année : les moins chers
    pr_2025    INTEGER[];  -- reviennent plus souvent, l'Audio progresse
    pr_2026    INTEGER[];  -- chaque année et le Mobilier recule
    pr         INTEGER[];
    jour       DATE;
    annee      INTEGER;
    ferme      BOOLEAN;    -- magasins fermés (dimanche ou jour férié)
    facteur    NUMERIC;
    nb         INTEGER;
    idx        INTEGER;
    r          DOUBLE PRECISION;
    v_prod     INTEGER;
    v_qte      INTEGER;
    v_canal    VARCHAR(20);
    v_mag      INTEGER;
    v_remise   NUMERIC(4,1);
    v_prix     NUMERIC(10,2);
BEGIN
    SELECT array_agg(c.client_id        ORDER BY c.client_id),
           array_agg(c.date_inscription ORDER BY c.client_id),
           array_agg(m.magasin_id       ORDER BY c.client_id),
           array_agg(m.date_ouverture   ORDER BY c.client_id)
    INTO cl_ids, cl_dates, cl_mag, cl_ouv
    FROM clients c
    LEFT JOIN magasins m ON m.ville = c.ville
    WHERE c.email IS DISTINCT FROM 'ines.moreau@exemple.fr';

    SELECT array_agg(p.produit_id) INTO pr_2024
    FROM produits p
    CROSS JOIN LATERAL generate_series(1, round(
        (CASE WHEN p.prix_unitaire < 50 THEN 10 WHEN p.prix_unitaire < 150 THEN 6
              WHEN p.prix_unitaire < 400 THEN 4 ELSE 2 END)
      * (CASE p.categorie WHEN 'Audio' THEN 1.0 WHEN 'Mobilier' THEN 1.2 ELSE 1.0 END))::int)
    WHERE p.nom <> 'Tapis de souris XXL';

    SELECT array_agg(p.produit_id) INTO pr_2025
    FROM produits p
    CROSS JOIN LATERAL generate_series(1, round(
        (CASE WHEN p.prix_unitaire < 50 THEN 10 WHEN p.prix_unitaire < 150 THEN 6
              WHEN p.prix_unitaire < 400 THEN 4 ELSE 2 END)
      * (CASE p.categorie WHEN 'Audio' THEN 1.3 WHEN 'Mobilier' THEN 1.0 ELSE 1.0 END))::int)
    WHERE p.nom <> 'Tapis de souris XXL';

    SELECT array_agg(p.produit_id) INTO pr_2026
    FROM produits p
    CROSS JOIN LATERAL generate_series(1, round(
        (CASE WHEN p.prix_unitaire < 50 THEN 10 WHEN p.prix_unitaire < 150 THEN 6
              WHEN p.prix_unitaire < 400 THEN 4 ELSE 2 END)
      * (CASE p.categorie WHEN 'Audio' THEN 1.6 WHEN 'Mobilier' THEN 0.85 ELSE 1.0 END))::int)
    WHERE p.nom <> 'Tapis de souris XXL';

    FOR jour IN
        SELECT d::date FROM generate_series(DATE '2024-01-01', DATE '2026-12-31', INTERVAL '1 day') AS d
    LOOP
        annee := EXTRACT(YEAR FROM jour)::int;
        pr := CASE annee WHEN 2024 THEN pr_2024 WHEN 2025 THEN pr_2025 ELSE pr_2026 END;

        SELECT (k.jour_semaine = 7 OR k.est_ferie) INTO ferme
        FROM calendrier k WHERE k.date_jour = jour;

        -- Saisonnalité : fêtes de fin d'année fortes, été calme
        facteur := CASE
            WHEN EXTRACT(MONTH FROM jour) = 12      THEN 2.2
            WHEN EXTRACT(MONTH FROM jour) = 11      THEN 1.8
            WHEN EXTRACT(MONTH FROM jour) IN (7, 8) THEN 0.7
            ELSE 1.0 END;
        -- Samedi chargé ; dimanche et jours fériés calmes (en ligne seulement)
        IF EXTRACT(ISODOW FROM jour) = 6 AND NOT ferme THEN
            facteur := facteur * 1.4;
        ELSIF ferme THEN
            facteur := facteur * 0.4;
        END IF;
        -- Croissance d'une année sur l'autre
        facteur := facteur * CASE annee WHEN 2024 THEN 1.00 WHEN 2025 THEN 1.12 ELSE 1.25 END;

        nb := floor(random() * 5 * facteur)::int;

        FOR i IN 1..nb LOOP
            -- Un client déjà inscrit à cette date
            idx := NULL;
            FOR essai IN 1..20 LOOP
                idx := 1 + floor(random() * array_length(cl_ids, 1))::int;
                EXIT WHEN cl_dates[idx] <= jour;
                idx := NULL;
            END LOOP;
            CONTINUE WHEN idx IS NULL;

            v_prod := pr[1 + floor(random() * array_length(pr, 1))::int];

            -- Prix catalogue de l'époque : environ 3 % moins cher par année passée
            SELECT ROUND(prix_unitaire * CASE annee WHEN 2024 THEN 0.94
                                                    WHEN 2025 THEN 0.97
                                                    ELSE 1.00 END, 2)
            INTO v_prix
            FROM produits WHERE produit_id = v_prod;

            -- Quantité : le plus souvent 1
            r := random();
            v_qte := CASE WHEN r < 0.70 THEN 1
                          WHEN r < 0.90 THEN 2
                          WHEN r < 0.97 THEN 3
                          ELSE 4 END;

            -- Canal : 75 % en magasin si la ville en a un, qu'il est déjà
            -- ouvert et que ce n'est ni un dimanche ni un jour férié
            IF cl_mag[idx] IS NOT NULL AND cl_ouv[idx] <= jour
               AND NOT ferme AND random() < 0.75 THEN
                v_canal := 'Magasin';
                v_mag   := cl_mag[idx];
            ELSE
                v_canal := 'En ligne';
                v_mag   := NULL;
            END IF;

            -- Remises : semaine du Black Friday, soldes de janvier et juillet,
            -- sinon rares
            r := random();
            IF EXTRACT(MONTH FROM jour) = 11 AND EXTRACT(DAY FROM jour) >= 24 THEN
                v_remise := CASE WHEN r < 0.6 THEN 20 ELSE 0 END;
            ELSIF EXTRACT(MONTH FROM jour) IN (1, 7) THEN
                v_remise := CASE WHEN r < 0.4 THEN 15 ELSE 0 END;
            ELSE
                v_remise := CASE WHEN r < 0.08 THEN 10 ELSE 0 END;
            END IF;

            INSERT INTO ventes (client_id, produit_id, date_vente, quantite,
                                magasin_id, canal, prix_vente, remise_pct)
            VALUES (cl_ids[idx], v_prod, jour, v_qte, v_mag, v_canal, v_prix, v_remise);
        END LOOP;
    END LOOP;
END $$;

-- 8. Règles de cohérence
ALTER TABLE ventes ALTER COLUMN canal      SET NOT NULL;
ALTER TABLE ventes ALTER COLUMN prix_vente SET NOT NULL;
ALTER TABLE ventes ADD CONSTRAINT ventes_canal_check
    CHECK ((canal = 'Magasin'  AND magasin_id IS NOT NULL)
        OR (canal = 'En ligne' AND magasin_id IS NULL));

-- 9. La vue pour Power BI : une ligne par vente, tout est déjà joint
--    (à relier à la table calendrier par date_vente = date_jour)
DROP VIEW IF EXISTS v_ventes_detail;
CREATE VIEW v_ventes_detail AS
SELECT v.vente_id,
       v.date_vente,
       v.canal,
       m.ville                      AS ville_magasin,
       c.client_id,
       c.prenom,
       c.nom,
       c.ville                      AS ville_client,
       p.produit_id,
       p.nom                        AS produit,
       p.categorie,
       v.quantite,
       v.prix_vente,
       v.remise_pct,
       v.quantite * v.prix_vente    AS montant_brut,
       ROUND(v.quantite * v.prix_vente * (1 - v.remise_pct / 100), 2) AS montant_net,
       v.quantite * p.prix_achat    AS cout_achat,
       ROUND(v.quantite * v.prix_vente * (1 - v.remise_pct / 100), 2)
         - v.quantite * p.prix_achat AS marge
FROM ventes v
JOIN clients c       ON c.client_id  = v.client_id
JOIN produits p      ON p.produit_id = v.produit_id
LEFT JOIN magasins m ON m.magasin_id = v.magasin_id;

-- 10. Bilan affiché dans Data Output
SELECT (SELECT COUNT(*) FROM clients)    AS nb_clients,
       (SELECT COUNT(*) FROM produits)   AS nb_produits,
       (SELECT COUNT(*) FROM magasins)   AS nb_magasins,
       (SELECT COUNT(*) FROM calendrier) AS nb_jours_calendrier,
       (SELECT COUNT(*) FROM ventes)     AS nb_ventes,
       (SELECT SUM(montant_net) FROM v_ventes_detail WHERE date_vente <  '2025-01-01') AS ca_2024,
       (SELECT SUM(montant_net) FROM v_ventes_detail WHERE date_vente >= '2025-01-01'
                                                       AND date_vente <  '2026-01-01') AS ca_2025,
       (SELECT SUM(montant_net) FROM v_ventes_detail WHERE date_vente >= '2026-01-01') AS ca_2026;
