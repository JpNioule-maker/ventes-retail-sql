-- =====================================================================
-- Exercices SQL : vues, sous-requêtes, CTE, fonctions de fenêtre
-- Base : ventes_retail (ventes de janvier 2024 à septembre 2026)
-- Les comparaisons 2025-2026 portent sur la période janvier-septembre,
-- 2026 n'étant pas terminée à la date de l'analyse.
-- =====================================================================


-- Ajout du client

SELECT v.vente_id, v.date_vente,
       c.client_id, c.prenom, c.nom, c.ville AS ville_client,
       v.produit_id, v.quantite, v.prix_vente, v.remise_pct,
       v.canal, v.magasin_id
FROM ventes v
JOIN clients c ON c.client_id = v.client_id
LIMIT 10;
-- Ajout du produit

SELECT v.vente_id, v.date_vente,
       c.client_id, c.prenom, c.nom, c.ville AS ville_client,
       p.produit_id, p.nom AS produit, p.categorie,
       v.quantite, v.prix_vente, v.remise_pct, v.canal, v.magasin_id
FROM ventes v
JOIN clients c  ON c.client_id  = v.client_id
JOIN produits p ON p.produit_id = v.produit_id
LIMIT 10;
-- Ajout du magasin avec un LEFT JOIN

SELECT v.vente_id, v.date_vente, v.canal, m.ville AS ville_magasin,
       c.client_id, c.prenom, c.nom, c.ville AS ville_client,
       p.produit_id, p.nom AS produit, p.categorie,
       v.quantite, v.prix_vente, v.remise_pct
FROM ventes v
JOIN clients c       ON c.client_id  = v.client_id
JOIN produits p      ON p.produit_id = v.produit_id
LEFT JOIN magasins m ON m.magasin_id = v.magasin_id
LIMIT 10;
-- Ajout des calculs

SELECT v.vente_id, v.date_vente, v.canal, m.ville AS ville_magasin,
       c.client_id, c.prenom, c.nom, c.ville AS ville_client,
       p.produit_id, p.nom AS produit, p.categorie,
       v.quantite, v.prix_vente, v.remise_pct,
       v.quantite * v.prix_vente AS montant_brut,
       ROUND(v.quantite * v.prix_vente * (1 - v.remise_pct / 100), 2)
           AS montant_net,
       v.quantite * p.prix_achat AS cout_achat,
       ROUND(v.quantite * v.prix_vente * (1 - v.remise_pct / 100), 2)
         - v.quantite * p.prix_achat AS marge
FROM ventes v
JOIN clients c       ON c.client_id  = v.client_id
JOIN produits p      ON p.produit_id = v.produit_id
LEFT JOIN magasins m ON m.magasin_id = v.magasin_id
LIMIT 10;

-- Enregistrons la requête comme vue
-- (même définition que la vue créée par Scripts/03_enrichissement_donnees.sql :
--  CREATE OR REPLACE la recrée à l'identique, sans doublon)

CREATE OR REPLACE VIEW v_ventes_detail AS
SELECT v.vente_id, v.date_vente, v.canal, m.ville AS ville_magasin,
       c.client_id, c.prenom, c.nom, c.ville AS ville_client,
       p.produit_id, p.nom AS produit, p.categorie,
       v.quantite, v.prix_vente, v.remise_pct,
       v.quantite * v.prix_vente AS montant_brut,
       ROUND(v.quantite * v.prix_vente * (1 - v.remise_pct / 100), 2)
           AS montant_net,
       v.quantite * p.prix_achat AS cout_achat,
       ROUND(v.quantite * v.prix_vente * (1 - v.remise_pct / 100), 2)
         - v.quantite * p.prix_achat AS marge
FROM ventes v
JOIN clients c       ON c.client_id  = v.client_id
JOIN produits p      ON p.produit_id = v.produit_id
LEFT JOIN magasins m ON m.magasin_id = v.magasin_id;

-- création de la vue ca par catégorie.
CREATE OR REPLACE VIEW v_ca_par_categorie AS
SELECT categorie, COUNT(*) AS nb_ventes, SUM(montant_net) AS ca_net
FROM v_ventes_detail
GROUP BY categorie;

SELECT * FROM v_ca_par_categorie;

-- correction Exo2

--1 Affichons les ventes dont le montant net dépasse 3 fois le montant net moyen d’une vente, de la plus grosse à la plus petite.

SELECT vente_id, date_vente, client_id, produit, montant_net
FROM v_ventes_detail
WHERE montant_net > 3 * (SELECT AVG(montant_net) FROM v_ventes_detail)
ORDER BY montant_net DESC;

--2 Affichons les produits qui n’ont jamais été vendus. Pourquoi ne peut-on pas utiliser la vue ici ?

SELECT produit_id, nom, categorie
FROM produits
WHERE produit_id NOT IN (SELECT produit_id
FROM ventes);
-- Réponse : la vue ne contient que des lignes de vente. Un produit jamais vendu
-- n'y apparaît donc pas : il faut partir de la table produits.

--3 Combien de ventes, tous produits confondus, ont réalisé les clients qui ont acheté au moins un « Fauteuil ergonomique » ?
SELECT client_id, nom, prenom, COUNT(vente_id) AS nbre_ventes
FROM v_ventes_detail
WHERE client_id IN
(SELECT client_id
FROM v_ventes_detail
WHERE produit = 'Fauteuil ergonomique')
GROUP BY client_id, nom, prenom
ORDER BY nbre_ventes DESC;

--4 Affichons le détail de la vente dont le montant net est le plus élevé de toute la base.

SELECT *
FROM v_ventes_detail
WHERE montant_net =
(SELECT MAX(montant_net)
FROM v_ventes_detail);

--5 Calculons le chiffre d’affaires moyen par client, c’est-à-dire la moyenne des totaux dépensés par chaque client.

SELECT ROUND(AVG(total_depense),1) AS ca_moyen
FROM (SELECT client_id, SUM(montant_net) AS total_depense
FROM v_ventes_detail
GROUP BY client_id) AS t;

-- EXO 3


--1 calculons le chiffre d’affaires de chaque ville de clients, puis n’affichez que les villes au-dessus de la moyenne des villes

WITH ca_ville_clients AS (
     SELECT ville_client, SUM(montant_net) AS ca
     FROM v_ventes_detail
     GROUP BY ville_client
)

SELECT ville_client,ca
FROM ca_ville_clients
WHERE ca >(SELECT AVG(ca) FROM ca_ville_clients)
ORDER BY ca DESC;

--2  calculons le chiffre d’affaires de chaque mois, puis affichons les 5 meilleurs mois de toute la période.

WITH ca_par_mois AS (
SELECT DATE_TRUNC('month', date_vente)::date AS mois, SUM(montant_net)AS ca
FROM v_ventes_detail
GROUP BY 1
)
SELECT mois,ca
FROM ca_par_mois
ORDER BY ca DESC
LIMIT 5;

--3 Reprenons l’exemple 2025 contre 2026 et ajoutez une colonne avec l’évolution en pourcentage. Quelle catégorie progresse le plus, et laquelle recule ?
--  2026 s'arrête au 30 septembre : on compare janvier-septembre des deux années.

WITH ventes_2025 AS (
    SELECT categorie, SUM(montant_net) AS ca
    FROM v_ventes_detail
    WHERE date_vente BETWEEN '2025-01-01' AND '2025-09-30'
    GROUP BY categorie
),
ventes_2026 AS (
    SELECT categorie, SUM(montant_net) AS ca
    FROM v_ventes_detail
    WHERE date_vente BETWEEN '2026-01-01' AND '2026-09-30'
    GROUP BY categorie
)
SELECT a.categorie, 
       a.ca AS ca_2025, 
	   b.ca AS ca_2026, 
	   ROUND(100* ( b.ca - a.ca ) / a.ca , 1) AS evolution_pct
FROM ventes_2025 a
JOIN ventes_2026 b ON b.categorie = a.categorie
ORDER BY evolution_pct DESC;
-- Réponse : l'Audio est la catégorie la plus dynamique, le Mobilier recule.

--4 affichons les 3 clients dont les achats ont le plus baissé entre 2025 et 2026 (janvier-septembre), avec leurs deux totaux.

WITH total_2025 AS (
    SELECT client_id, prenom, nom, SUM(montant_net) AS ca
    FROM v_ventes_detail
    WHERE date_vente BETWEEN '2025-01-01' AND '2025-09-30'
    GROUP BY client_id, prenom, nom
),
total_2026 AS (
    SELECT client_id, prenom,nom, SUM(montant_net) AS ca
    FROM v_ventes_detail
    WHERE date_vente BETWEEN '2026-01-01' AND '2026-09-30'
    GROUP BY client_id, prenom, nom
)
SELECT a.prenom, a.nom,
       a.ca AS ca_2025,
       b.ca AS ca_2026,
       a.ca - b.ca AS baisse
FROM total_2025 a
JOIN total_2026 b ON b.client_id = a.client_id
WHERE b.ca < a.ca
ORDER BY baisse DESC
LIMIT 3;

--5 Évolution du chiffre d'affaires par catégorie, janvier-septembre 2026 contre janvier-septembre 2025
WITH ventes_2025 AS (
    SELECT categorie, SUM(montant_net) AS ca
    FROM v_ventes_detail
    WHERE date_vente BETWEEN '2025-01-01' AND '2025-09-30'
    GROUP BY categorie
),
ventes_2026 AS (
    SELECT categorie, SUM(montant_net) AS ca
    FROM v_ventes_detail
    WHERE date_vente BETWEEN '2026-01-01' AND '2026-09-30'
    GROUP BY categorie
)
SELECT a.categorie                          AS "Catégorie",
       ROUND(a.ca)                          AS "CA 2025 (€)",
       ROUND(b.ca)                          AS "CA 2026 (€)",
       ROUND(b.ca - a.ca)                   AS "Écart (€)",
       ROUND(100 * (b.ca - a.ca) / a.ca, 1) AS "Évolution (%)"
FROM ventes_2025 a
JOIN ventes_2026 b ON b.categorie = a.categorie
ORDER BY "Évolution (%)" DESC;

-- comparaison des ventes mensuelles de  2025 à 2026

WITH mois_2025 AS (
    SELECT EXTRACT(MONTH FROM date_vente) AS mois, SUM(montant_net) AS ca
    FROM v_ventes_detail
    WHERE date_vente BETWEEN '2025-01-01' AND '2025-09-30'
    GROUP BY EXTRACT(MONTH FROM date_vente)
),
mois_2026 AS (
    SELECT EXTRACT(MONTH FROM date_vente) AS mois, SUM(montant_net) AS ca
    FROM v_ventes_detail
    WHERE date_vente BETWEEN '2026-01-01' AND '2026-09-30'
    GROUP BY EXTRACT(MONTH FROM date_vente)
)
SELECT a.mois                               AS "Mois",
       ROUND(a.ca)                          AS "CA 2025 (€)",
       ROUND(b.ca)                          AS "CA 2026 (€)",
       ROUND(b.ca - a.ca)                   AS "Écart (€)",
       ROUND(100 * (b.ca - a.ca) / a.ca, 1) AS "Évolution (%)"
FROM mois_2025 a
JOIN mois_2026 b ON b.mois = a.mois
ORDER BY a.mois;

-- EXO 4
-- 1 Affichons chaque catégorie avec son chiffre d’affaires et sa part du chiffre d’affaires total, en pourcentage arrondi à une décimale.
WITH ca_categorie AS (
    SELECT categorie, SUM(montant_net) AS ca
    FROM v_ventes_detail
    GROUP BY categorie
)
SELECT categorie, ca,
       ROUND(100 * ca / SUM(ca) OVER (), 1) AS part_pct
FROM ca_categorie
ORDER BY ca DESC;

--2 Classez les produits par chiffre d’affaires au sein de leur catégorie.
WITH ca_produit AS (
    SELECT categorie, produit, SUM(montant_net) AS ca
    FROM v_ventes_detail
    GROUP BY categorie, produit
)
SELECT categorie, produit, ca,
       RANK() OVER (PARTITION BY categorie ORDER BY ca DESC) AS rang
FROM ca_produit
ORDER BY categorie, rang;
-- 3 Affichons le chiffre d’affaires de chaque mois de 2026 et le cumul depuis janvier.
WITH ca_mois AS (
    SELECT DATE_TRUNC('month', date_vente)::date AS mois, SUM(montant_net) AS ca
    FROM v_ventes_detail
    WHERE date_vente BETWEEN '2026-01-01' AND '2026-09-30'
    GROUP BY 1
)
SELECT mois, ca, SUM(ca) OVER (ORDER BY mois) AS ca_cumule
FROM ca_mois
ORDER BY mois;

--4 Affichons le chiffre d’affaires de chaque mois, celui du mois précédent et l’écart entre les deux.
WITH ca_mois AS (
    SELECT DATE_TRUNC('month', date_vente)::date AS mois, SUM(montant_net) AS ca
    FROM v_ventes_detail
    GROUP BY 1
)
SELECT mois, ca,
       LAG(ca) OVER (ORDER BY mois) AS ca_mois_precedent,
       ca - LAG(ca) OVER (ORDER BY mois) AS ecart
FROM ca_mois
ORDER BY mois;

--5 Affichez les 3 meilleurs clients de chaque ville, selon leur chiffre d’affaires net.

WITH classement AS (
    SELECT ville_client, prenom, nom, SUM(montant_net) AS total,
           ROW_NUMBER() OVER (PARTITION BY ville_client
                              ORDER BY SUM(montant_net) DESC) AS rang
    FROM v_ventes_detail
    GROUP BY ville_client, client_id, prenom, nom
)
SELECT ville_client, rang, prenom, nom, total
FROM classement
WHERE rang <= 3
ORDER BY ville_client, rang;
--6.	Bonus : pour chaque mois, affichez son chiffre d’affaires, celui du même mois de l’année précédente et l’évolution en pourcentage.
WITH ca_mois AS (
    SELECT DATE_TRUNC('month', date_vente)::date AS mois, SUM(montant_net) AS ca
    FROM v_ventes_detail
    GROUP BY 1
)
SELECT mois, ca,
       LAG(ca, 12) OVER (ORDER BY mois) AS ca_annee_precedente,
       ROUND(100 * (ca - LAG(ca, 12) OVER (ORDER BY mois))
             / LAG(ca, 12) OVER (ORDER BY mois), 1) AS evolution_pct
FROM ca_mois
ORDER BY mois;
-- LAG(ca, 12) suppose qu'aucun mois ne manque dans la série.

--Défi final : bilan annuel par catégorie (source du tableau 2025 contre 2024 du README)
CREATE OR REPLACE VIEW v_bilan_categorie_annee AS
WITH ca_annuel AS (
    SELECT categorie,
           EXTRACT(YEAR FROM date_vente)::int AS annee,
           SUM(montant_net) AS ca
    FROM v_ventes_detail
    GROUP BY categorie, annee
)
SELECT annee,
       categorie,
       ca,
       LAG(ca) OVER (PARTITION BY categorie ORDER BY annee) AS ca_annee_precedente,
       ROUND(100 * (ca - LAG(ca) OVER (PARTITION BY categorie ORDER BY annee))
             / LAG(ca) OVER (PARTITION BY categorie ORDER BY annee), 1) AS evolution_pct,
       RANK() OVER (PARTITION BY annee ORDER BY ca DESC) AS rang_dans_annee
FROM ca_annuel;

SELECT * FROM v_bilan_categorie_annee ORDER BY annee, rang_dans_annee;

-- Bilan 2025 seul : 2025 contre 2024, deux années complètes
SELECT * FROM v_bilan_categorie_annee
WHERE annee = 2025
ORDER BY rang_dans_annee;

