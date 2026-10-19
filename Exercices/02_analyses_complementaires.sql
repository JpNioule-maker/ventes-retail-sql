-- =====================================================================
-- Analyses complémentaires : rentabilité, moteurs de la croissance,
-- canaux et magasins
-- Base : ventes_retail (ventes de janvier 2024 à septembre 2026)
-- Les comparaisons annuelles portent sur 2024 et 2025, deux années complètes.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. RENTABILITÉ
-- ---------------------------------------------------------------------

--1.1 Taux de marge par catégorie, sur toute la période
--    Question : quelle catégorie est la plus rentable, en euros et en % ?

SELECT categorie,
       COUNT(*)                                        AS nb_ventes,
       ROUND(SUM(montant_net))                         AS ca_net,
       ROUND(SUM(marge))                               AS marge,
       ROUND(100 * SUM(marge) / SUM(montant_net), 1)  AS taux_marge_pct
FROM v_ventes_detail
GROUP BY categorie
ORDER BY taux_marge_pct DESC;


--1.2 Taux de marge selon le niveau de remise
--    Question : de combien une remise fait-elle baisser la marge ?

SELECT remise_pct,
       COUNT(*)                                        AS nb_ventes,
       ROUND(SUM(montant_net))                         AS ca_net,
       ROUND(100 * SUM(marge) / SUM(montant_net), 1)  AS taux_marge_pct
FROM v_ventes_detail
GROUP BY remise_pct
ORDER BY remise_pct;


-- ---------------------------------------------------------------------
-- 2. D'OÙ VIENT LA CROISSANCE ?
--    CA = nombre de ventes × panier moyen
--    Une hausse du CA peut venir de ventes plus nombreuses,
--    d'un panier plus élevé (prix, quantités), ou des deux.
-- ---------------------------------------------------------------------

--2.1 Décomposition du CA par catégorie, 2025 contre 2024
--    Les ::numeric évitent la division entière entre deux nombres entiers.

WITH base AS (
    SELECT categorie,
           EXTRACT(YEAR FROM date_vente)::int  AS annee,
           COUNT(*)::numeric                   AS nb_ventes,
           SUM(quantite)::numeric              AS quantite,
           SUM(montant_net)                    AS ca
    FROM v_ventes_detail
    WHERE date_vente BETWEEN '2024-01-01' AND '2025-12-31'
    GROUP BY categorie, annee
)
SELECT annee,
       categorie,
       nb_ventes,
       ROUND(ca)                                    AS ca_net,
       ROUND(ca / nb_ventes, 2)                     AS panier_moyen,
       ROUND(ca / quantite, 2)                      AS prix_moyen_unitaire,
       ROUND(100 * (nb_ventes - LAG(nb_ventes) OVER w)
             / LAG(nb_ventes) OVER w, 1)            AS evol_nb_ventes_pct,
       ROUND(100 * (ca / nb_ventes - LAG(ca / nb_ventes) OVER w)
             / LAG(ca / nb_ventes) OVER w, 1)       AS evol_panier_pct,
       ROUND(100 * (ca - LAG(ca) OVER w)
             / LAG(ca) OVER w, 1)                   AS evol_ca_pct
FROM base
WINDOW w AS (PARTITION BY categorie ORDER BY annee)
ORDER BY categorie, annee;
-- Lecture : evol_ca ≈ (1 + evol_nb_ventes) × (1 + evol_panier) - 1.
-- Si evol_nb_ventes domine, la croissance vient du volume ;
-- si evol_panier domine, elle vient du prix ou des quantités par vente.


-- ---------------------------------------------------------------------
-- 3. CANAUX ET MAGASINS
-- ---------------------------------------------------------------------

--3.1 Part de chaque canal dans le CA, par année
--    Question : la vente en ligne gagne-t-elle du terrain sur les magasins ?

WITH ca_canal AS (
    SELECT EXTRACT(YEAR FROM date_vente)::int  AS annee,
           canal,
           COUNT(*)                            AS nb_ventes,
           SUM(montant_net)                    AS ca,
           SUM(marge)                          AS marge
    FROM v_ventes_detail
    WHERE date_vente BETWEEN '2024-01-01' AND '2025-12-31'
    GROUP BY annee, canal
)
SELECT annee,
       canal,
       nb_ventes,
       ROUND(ca)                                             AS ca_net,
       ROUND(100 * ca / SUM(ca) OVER (PARTITION BY annee), 1) AS part_ca_pct,
       ROUND(100 * marge / ca, 1)                            AS taux_marge_pct
FROM ca_canal
ORDER BY annee, ca_net DESC;


--3.2 CA par magasin et en ligne, 2025 contre 2024, avec la date d'ouverture
--    Question : quels lieux portent la croissance ? Les ouvertures récentes
--    expliquent-elles une partie de la hausse ?
--    FILTER (WHERE ...) calcule une somme sur une partie des lignes seulement.

WITH ca_lieu AS (
    SELECT COALESCE(ville_magasin, 'En ligne')  AS lieu,
           SUM(montant_net) FILTER (WHERE date_vente BETWEEN '2024-01-01' AND '2024-12-31') AS ca_2024,
           SUM(montant_net) FILTER (WHERE date_vente BETWEEN '2025-01-01' AND '2025-12-31') AS ca_2025
    FROM v_ventes_detail
    GROUP BY 1
)
SELECT c.lieu,
       m.date_ouverture,
       ROUND(c.ca_2024)                                        AS ca_2024,
       ROUND(c.ca_2025)                                        AS ca_2025,
       ROUND(100 * (c.ca_2025 - c.ca_2024) / c.ca_2024, 1)     AS evolution_pct,
       ROUND(100 * c.ca_2025 / SUM(c.ca_2025) OVER (), 1)      AS part_ca_2025_pct
FROM ca_lieu c
LEFT JOIN magasins m ON m.ville = c.lieu
ORDER BY c.ca_2025 DESC;
