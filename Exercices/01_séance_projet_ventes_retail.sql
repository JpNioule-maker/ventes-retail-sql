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




