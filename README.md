# Ventes Retail : analyse SQL d'une enseigne de distribution

Projet d'entraînement à l'analyse de données avec **PostgreSQL**, sur des **données simulées** : une enseigne fictive qui vend du matériel informatique, de l'audio et du mobilier de bureau, dans six magasins et en ligne.

L'objectif : répondre avec SQL aux questions qu'une direction commerciale se pose réellement (qu'est-ce qui se vend, à qui, par quel canal, et est-ce rentable ?), puis présenter les résultats dans un tableau de bord Power BI.

---

## En bref

| | |
|:---|:---|
| **Outils** | PostgreSQL 18, pgAdmin 4, Git / GitHub (Power BI à venir) |
| **Données** | Simulées : 100 clients, 21 produits, 6 magasins, environ 2 300 ventes de janvier 2024 à septembre 2026 |
| **Compétences SQL** | Jointures, agrégations, `GROUP BY` / `HAVING`, vues, sous-requêtes, CTE, fonctions de fenêtre, transactions |
| **Statut** | En cours : vues, sous-requêtes, CTE et fonctions de fenêtre terminées ; diagnostic commercial et Power BI à venir |

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

> **À savoir** : ces tendances sont paramétrées dans le script `03_enrichissement_donnees.sql` (croissance par catégorie, hausse des prix, saisonnalité, remises, coûts d'achat). Le but du projet n'est donc pas de découvrir des tendances inconnues, mais de **maîtriser SQL et la démarche d'analyse** : poser les bonnes questions, comparer des périodes comparables, et vérifier que les requêtes retrouvent fidèlement ce que contiennent les données.

**Elles s'arrêtent au 30 septembre 2026**, date de l'analyse : l'année 2026 n'est pas terminée.

---

## Méthode : comparer des périodes identiques

L'année 2026 ne compte que neuf mois. La comparer à l'année 2025 complète ferait apparaître une baisse artificielle, d'autant que novembre et décembre sont les mois les plus forts. Les comparaisons sont donc faites ainsi :

- **2025 contre 2024** : deux années complètes, comparaison annuelle ;
- **2026 contre 2025** : même période, de janvier à septembre, et comparaison mois par mois.

---

## Résultats des analyses

Les requêtes retrouvent les tendances paramétrées dans les données simulées. Les constats ci-dessous sont rédigés comme pour une vraie direction commerciale, pour s'entraîner à passer du chiffre à la recommandation.

### Évolution du chiffre d'affaires par catégorie, 2025 contre 2024

*Source : vue `v_bilan_categorie_annee` (défi final du fichier d'exercices).*

| Catégorie | CA 2024 (€) | CA 2025 (€) | Écart (€) | Évolution |
|:---|---:|---:|---:|---:|
| Audio | 26 882 | 42 871 | +15 989 | +59,5 % |
| Informatique | 46 143 | 67 521 | +21 378 | +46,3 % |
| Mobilier | 50 747 | 46 683 | −4 064 | −8,0 % |

**Constat** : l'Audio et l'Informatique tirent la croissance, tandis que le Mobilier, pourtant la catégorie au meilleur taux de marge (coût d'achat fixé à 50 % du prix, contre 55 % pour l'Audio et 70 % pour l'Informatique), recule dès 2025.

**Recommandation** : analyser les causes du recul du Mobilier (prix, visibilité, concurrence) avant qu'il ne pèse sur la marge globale.

### 2026 : une tendance confirmée sur janvier-septembre

Sur les neuf premiers mois de 2026, comparés à la même période de 2025, l'Audio reste la catégorie la plus dynamique et le Mobilier continue de reculer.

La comparaison mois par mois montre de fortes variations d'un mois à l'autre : un mois ne compte que quelques dizaines de ventes, et quelques grosses commandes suffisent à faire varier le pourcentage. Il faut donc lire la **tendance générale** plutôt qu'un mois isolé.

### Autres observations

- **Les fêtes de fin d'année concentrent l'activité** : les meilleurs mois de la période sont tous des mois de novembre ou de décembre.
- **Les promotions pèsent sur la rentabilité** : le taux de marge passe de 38,6 % sans remise à 17,4 % avec 20 % de remise (détail ci-dessous).

### Rentabilité et moteurs de la croissance

*Source : `Exercices/02_analyses_complementaires.sql`.*

**Taux de marge par catégorie (janvier 2024 à septembre 2026)**

| Catégorie | Ventes | CA net (€) | Marge (€) | Taux de marge |
|:---|---:|---:|---:|---:|
| Mobilier | 819 | 124 231 | 58 854 | 47,4 % |
| Audio | 681 | 105 452 | 44 719 | 42,4 % |
| Informatique | 827 | 155 610 | 41 150 | 26,4 % |

**Constat** : l'Informatique apporte le plus de chiffre d'affaires (40 % du total) mais le moins de marge ; le Mobilier apporte le plus de marge (41 % du total). La croissance repose donc sur les produits les moins rentables, et le recul du Mobilier touche directement la marge.

**Taux de marge selon la remise**

| Remise | Ventes | CA net (€) | Taux de marge |
|---:|---:|---:|---:|
| 0 % | 2 045 | 342 837 | 38,6 % |
| 10 % | 139 | 20 177 | 33,1 % |
| 15 % | 116 | 18 831 | 26,7 % |
| 20 % | 27 | 3 448 | 17,4 % |

**Constat** : chaque palier de remise coûte plusieurs points de marge. Les ventes remisées ne pèsent que 12 % des ventes et 11 % du chiffre d'affaires : l'effet reste limité sur l'ensemble.

**D'où vient la croissance ? 2025 contre 2024** (CA = nombre de ventes × panier moyen)

| Catégorie | Nombre de ventes | Panier moyen | CA |
|:---|---:|---:|---:|
| Audio | +59,1 % | +0,2 % | +59,5 % |
| Informatique | +34,4 % | +8,9 % | +46,3 % |
| Mobilier | −10,7 % | +3,0 % | −8,0 % |

**Constat** : la croissance de l'Audio vient entièrement du volume. Celle de l'Informatique combine volume et panier plus élevé. Le Mobilier perd des ventes : la légère hausse du panier, liée aux prix, ne compense pas.

**Canaux et magasins, 2025 contre 2024**

- Le chiffre d'affaires total progresse de 26,9 % (123 772 € à 157 075 €).
- Les canaux restent équilibrés : magasins 51 %, en ligne 49 %, avec des taux de marge proches (37,9 % et 36,6 % en 2025).
- La croissance vient de la vente en ligne (+28,2 %) et de trois magasins : Marseille (+56,3 %, ouvert fin 2023), Toulouse (+35,7 %), Paris (+28,4 %). Lyon (+3,3 %), Bordeaux (+3,8 %) et Strasbourg (−1,1 %, ouvert en 2024) stagnent.

**Recommandations** :
1. Relancer le Mobilier, catégorie la plus rentable, en priorité sur le volume (visibilité, offre) plutôt que par des remises, qui érodent sa marge.
2. Surveiller la marge globale : la croissance repose sur l'Informatique, la catégorie la moins rentable.
3. Analyser les magasins qui stagnent (Lyon, Bordeaux, Strasbourg) : zone de chalandise, offre, ancienneté.

*Limite : le coût d'achat est fixe dans les données alors que les prix de vente augmentent chaque année ; les taux de marge ne sont donc pas comparés d'une année à l'autre.*

---

## Organisation du dépôt

```
ventes-retail-sql/
├── README.md
├── Scripts/                 Création et alimentation de la base, dans l'ordre
│   ├── 01_creation_ventes_retail.sql   Tables clients, produits, ventes
│   ├── 02_preparation.sql              Cas particuliers et magasins
│   ├── 03_enrichissement_donnees.sql   Données réalistes, calendrier, vue v_ventes_detail
│   └── 04_arret_septembre_2026.sql     Arrêt des données à la date de l'analyse
└── Exercices/
    ├── 01_seance_projet_ventes_retail.sql   Vues, sous-requêtes, CTE, fonctions de fenêtre
    └── 02_analyses_complementaires.sql      Marge, décomposition du CA, canaux et magasins
```

---

## Ce que j'ai appris

### Vues
Construction pas à pas de la vue `v_ventes_detail` : jointures successives, `LEFT JOIN` pour conserver les ventes en ligne sans magasin, calcul du chiffre d'affaires net et de la marge. Utilisation d'une transaction (`BEGIN` / `ROLLBACK`) pour vérifier qu'une vue reflète les données en temps réel sans les modifier.

### Sous-requêtes
Comparaison à une valeur calculée (ventes supérieures à trois fois la moyenne), filtrage par liste avec `IN` et `NOT IN`, sous-requêtes dans le `FROM` pour calculer une moyenne de totaux.

**Leçon retenue** : pour trouver ce qui n'a *pas* de vente (un produit jamais vendu, un client sans achat), il faut partir des tables et non de la vue, qui ne contient que des ventes.

### CTE
Découpage des analyses en étapes lisibles avec `WITH` : chiffre d'affaires par ville comparé à la moyenne, meilleurs mois de la période, évolution par catégorie d'une année sur l'autre, comparaison mois par mois, clients dont les achats ont le plus baissé.

**Leçons retenues** :
- pour mesurer une évolution, on calcule l'écart entre les deux périodes et on trie sur cet écart, jamais sur une seule des deux valeurs ;
- on ne compare que des périodes de même longueur.

### Fonctions de fenêtre
Calculs qui conservent le détail des lignes tout en les situant dans un ensemble : part de chaque catégorie dans le chiffre d'affaires total (`SUM() OVER ()`), classement des produits au sein de leur catégorie (`RANK()`), cumul mensuel depuis janvier (`SUM() OVER (ORDER BY …)`), écart avec le mois précédent et avec le même mois de l'année précédente (`LAG()`), trois meilleurs clients par ville (`ROW_NUMBER()`). Synthèse dans la vue `v_bilan_categorie_annee` : chiffre d'affaires annuel par catégorie, évolution sur un an et rang.

**Leçon retenue** : `LAG(ca, 12)` compare au même mois de l'année précédente seulement si aucun mois ne manque dans la série.

### Gestion des données
Arrêt des données à la date de l'analyse par un script dédié, dans une transaction vérifiée avant validation (`BEGIN`, contrôle, `COMMIT`). Chaque modification de la base est conservée sous forme de script numéroté, pour pouvoir la recréer à l'identique.

---

## Recréer la base

1. Créer une base vide `ventes_retail` dans PostgreSQL.
2. Exécuter les scripts du dossier `Scripts/` dans l'ordre de leur numéro, de 01 à 04, depuis le Query Tool de pgAdmin.
3. Vérifier le résultat : les ventes doivent aller de janvier 2024 au 30 septembre 2026.

---

## Prochaines étapes

- [x] Vues
- [x] Sous-requêtes
- [x] CTE
- [x] Fonctions de fenêtre : classements, cumuls, comparaisons d'une période à l'autre
- [x] Compléter l'analyse : taux de marge par catégorie et selon la remise, décomposition du chiffre d'affaires (nombre de ventes × panier moyen), canal et magasins
- [ ] Projet 1 : diagnostic commercial complet, sur des données réelles
- [ ] Tableau de bord Power BI avec mesures DAX d'évolution annuelle

---

*Projet d'entraînement personnel, réalisé dans le cadre de ma formation à l'analyse de données.*
