# Ventes Retail : analyse SQL d'une enseigne de distribution

Projet d'apprentissage de l'analyse de données avec **PostgreSQL**, autour d'une enseigne fictive qui vend du matériel informatique, de l'audio et du mobilier de bureau, dans six magasins et en ligne.

L'objectif : répondre avec SQL aux questions qu'une direction commerciale se pose réellement (qu'est-ce qui se vend, à qui, par quel canal, et est-ce rentable ?), puis présenter les résultats dans un tableau de bord Power BI.

---

## En bref

| | |
|:---|:---|
| **Outils** | PostgreSQL 18, pgAdmin 4, Git / GitHub (Power BI à venir) |
| **Données** | 100 clients, 21 produits, 6 magasins, environ 2 700 ventes de janvier 2024 à décembre 2026 |
| **Compétences SQL** | Jointures, agrégations, `GROUP BY` / `HAVING`, vues, sous-requêtes, CTE, fonctions de fenêtre, transactions |
| **Statut** | En cours : vues, sous-requêtes et CTE terminées ; fonctions de fenêtre et projet de diagnostic en cours |

---

## Les données

La base `ventes_retail` contient cinq tables et une vue d'analyse.

| Objet | Contenu |
|:---|:---|
| `clients` | Fiche client : nom, ville, date d'inscription, parrain éventuel |
| `produits` | Catalogue : catégorie, prix de vente, prix d'achat |
| `magasins` | Les six magasins et leur date d'ouverture |
| `ventes` | Une ligne par vente : client, produit, date, quantité, prix payé, remise, canal |
| `calendrier` | Une ligne par jour de 2024 à 2026, avec les jours fériés français |
| `v_ventes_detail` | Vue qui rassemble ventes, clients, produits et magasins, avec le chiffre d'affaires net et la marge de chaque vente |

```
clients ──┐
          ├──► ventes ◄── produits
magasins ─┘       │
                  ▼
           v_ventes_detail   (vue d'analyse : une ligne par vente)
```

Les données sont **simulées** mais réalistes : saisonnalité (pic en novembre et décembre), soldes et Black Friday, magasins fermés le dimanche et les jours fériés, prix en hausse d'environ 3 % par an, et des tendances différentes selon les catégories.

---

## Premiers constats

Quelques résultats obtenus pendant les exercices, à approfondir dans le projet de diagnostic.

- **L'Audio est le moteur de croissance** : son chiffre d'affaires progresse d'environ 46 % entre 2025 et 2026, contre 6 % pour l'Informatique.
- **Le Mobilier recule d'environ 9 %**, alors que c'est la catégorie la plus rentable. C'est le point d'attention principal.
- **Les fêtes de fin d'année concentrent l'activité** : les cinq meilleurs mois de la période sont tous des mois de novembre ou de décembre.
- **Les promotions pèsent sur la rentabilité** : les mois de soldes et du Black Friday perdent plusieurs points de marge.

---

## Organisation du dépôt

```
ventes-retail-sql/
├── README.md
├── scripts/        Création et alimentation de la base
│   ├── 01_creation_base.sql
│   ├── 02_preparation.sql
│   └── 03_enrichissement.sql
├── exercices/      Requêtes d'apprentissage, par thème
└── projets/        Analyses complètes, rédigées comme pour une direction
    └── projet_1_diagnostic.sql
```

---

## Ce que j'ai appris

### Vues
Construction pas à pas de la vue `v_ventes_detail` : jointures successives, `LEFT JOIN` pour conserver les ventes en ligne sans magasin, calcul du chiffre d'affaires net et de la marge. Utilisation d'une transaction (`BEGIN` / `ROLLBACK`) pour vérifier qu'une vue reflète les données en temps réel sans les modifier.

### Sous-requêtes
Comparaison à une valeur calculée (ventes supérieures à trois fois la moyenne), filtrage par liste avec `IN` et `NOT IN`, sous-requêtes dans le `FROM` pour calculer une moyenne de totaux.

**Leçon retenue** : pour trouver ce qui n'a *pas* de vente (un produit jamais vendu, un client sans achat), il faut partir des tables et non de la vue, qui ne contient que des ventes.

### CTE
Découpage des analyses en étapes lisibles avec `WITH` : chiffre d'affaires par ville comparé à la moyenne, meilleurs mois de la période, comparaison 2025 / 2026 par catégorie avec évolution en pourcentage, clients dont les achats ont le plus baissé.

**Leçon retenue** : pour mesurer une évolution, on calcule l'écart entre les deux périodes et on trie sur cet écart, jamais sur une seule des deux valeurs.

---

## Recréer la base

1. Créer une base vide `ventes_retail` dans PostgreSQL.
2. Exécuter les scripts du dossier `scripts/` dans l'ordre de leur numéro, depuis le Query Tool de pgAdmin.
3. Vérifier le résultat : le dernier script affiche un bilan (nombre de clients, de produits, de ventes et chiffre d'affaires par année).

---

## Prochaines étapes

- [x] Vues
- [x] Sous-requêtes
- [x] CTE
- [ ] Fonctions de fenêtre : classements, cumuls, comparaisons d'une année sur l'autre
- [ ] Projet 1 : diagnostic commercial complet
- [ ] Tableau de bord Power BI avec mesures DAX d'évolution annuelle

---

*Projet réalisé dans le cadre de ma formation à l'analyse de données.*
