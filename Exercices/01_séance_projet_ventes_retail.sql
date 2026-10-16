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

-- Enregistrons la requete comme vue

CREATE VIEW v_ventes_details AS
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
CREATE VIEW v_ca_par_categorie AS
SELECT categorie, COUNT(*) AS nb_ventes, SUM(montant_net) AS ca_net
FROM v_ventes_details
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

SELECT*
FROM v_ventes_detail
WHERE montant_net =
(SELECT MAX(montant_net)
FROM v_ventes_detail);

--5 Calculons le chiffre d’affaires moyen par client, c’est-à-dire la moyenne des totaux dépensés par chaque client.

SELECT ROUND(AVG(total_depense),1) AS ca_moyen
FROM (SELECT client_id, SUM(montant_net) AS total_depense
FROM v_ventes_detail
GROUP BY client_id) AS t

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
ORDER BY ville_client,ca DESC;

--2  calculons le chiffre d’affaires de chaque mois, puis affichons les 5 meilleurs mois de toute la période.

WITH ca_par_mois AS (
SELECT DATE_TRUNC('month', date_vente)::date AS mois, SUM(montant_net)AS ca
FROM v_ventes_detail
GROUP BY 1
)
SELECT mois,ca
FROM ca_par_mois
ORDER BY ca DESC
LIMIT 5 

--3 Reprenez l’exemple 2025 contre 2026 et ajoutez une colonne avec l’évolution en pourcentage. Quelle catégorie progresse le plus, et laquelle recule ?

WITH ventes_2025 AS (
    SELECT categorie, SUM(montant_net) AS ca
    FROM v_ventes_detail
    WHERE date_vente BETWEEN '2025-01-01' AND '2025-12-31'
    GROUP BY categorie
),
ventes_2026 AS (
    SELECT categorie, SUM(montant_net) AS ca
    FROM v_ventes_detail
    WHERE date_vente BETWEEN '2026-01-01' AND '2026-12-31'
    GROUP BY categorie
)
SELECT a.categorie, 
       a.ca AS ca_2025, 
	   b.ca AS ca_2026, 
	   ROUND(100* ( b.ca - a.ca ) / a.ca , 1) AS evolution_pct
FROM ventes_2025 a
JOIN ventes_2026 b ON b.categorie = a.categorie
ORDER BY evolution_pct DESC;

--4 affichons les 3 clients dont les achats ont le plus baissé entre 2025 et 2026, avec leurs deux totaux.

WITH total_2025 AS (
    SELECT client_id, prenom, nom, SUM(montant_net) AS ca
    FROM v_ventes_detail
    WHERE date_vente BETWEEN '2025-01-01' AND '2025-12-31'
    GROUP BY client_id, prenom, nom
),
total_2026 AS (
    SELECT client_id, prenom,nom, SUM(montant_net) AS ca
    FROM v_ventes_detail
    WHERE date_vente BETWEEN '2026-01-01' AND '2026-12-31'
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
