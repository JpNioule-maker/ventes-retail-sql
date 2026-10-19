# Ventes Retail : analyse SQL d'une enseigne de distribution

Projet d'apprentissage de l'analyse de données avec **PostgreSQL**, autour d'une enseigne fictive qui vend du matériel informatique, de l'audio et du mobilier de bureau, dans six magasins et en ligne.

L'objectif : répondre avec SQL aux questions qu'une direction commerciale se pose réellement (qu'est-ce qui se vend, à qui, par quel canal, et est-ce rentable ?), puis présenter les résultats dans un tableau de bord Power BI.

---

## En bref

| | |
|:---|:---|
| **Outils** | PostgreSQL 18, pgAdmin 4, Git / GitHub (Power BI à venir) |
| **Données** | 100 clients, 21 produits, 6 magasins, environ 2 300 ventes de janvier 2024 à septembre 2026 |
| **Compétences SQL** | Jointures, agrégations, `GROUP BY` / `HAVING`, vues, sous-requêtes, CTE, transactions |
| **Statut** | En cours : vues, sous-requêtes et CTE terminées ; fonctions de fenêtre à venir |

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

**Elles s'arrêtent au 30 septembre 2026**, date de l'analyse : l'année 2026 n'est pas terminée.

---

## Méthode : comparer des périodes identiques

L'année 2026 ne compte que neuf mois. La comparer à l'année 2025 complète ferait apparaître une baisse artificielle, d'autant que novembre et décembre sont les mois les plus forts. Les comparaisons sont donc faites ainsi :

- **2025 contre 2024** : deux années complètes, comparaison annuelle ;
- **2026 contre 2025** : même période, de janvier à septembre, et comparaison mois par mois.

---

## Premiers constats

### Évolution du chiffre d'affaires par catégorie, 2025 contre 2024

| Catégorie | CA 2024 (€) | CA 2025 (€) | Écart (€) | Évolution |
|:---|---:|---:|---:|---:|
| Audio | 26 882 | 42 871 | +15 989 | +59,5 % |
| Informatique | 46 143 | 67 521 | +21 378 | +46,3 % |
| Mobilier | 50 747 | 46 683 | −4 064 | −8,0 % |

**Constat** : l'Audio et l'Informatique tirent la croissance, tandis que le Mobilier, pourtant la catégorie la plus rentable, recule dès 2025.

**Recommandation** : analyser les causes du recul du Mobilier (prix, visibilité, concurrence) avant qu'il ne pèse sur la marge globale.

### 2026 : une tendance confirmée sur janvier-septembre

Sur les neuf premiers mois de 2026, comparés à la même période de 2025, l'Audio reste la catégorie la plus dynamique et le Mobilier continue de reculer.

La comparaison mois par mois montre de fortes variations d'un mois à l'autre : un mois ne compte que quelques dizaines de ventes, et quelques grosses commandes suffisent à faire varier le pourcentage. Il faut donc lire la **tendance générale** plutôt qu'un mois isolé.

### Autres observations

- **Les fêtes de fin d'année concentrent l'activité** : les meilleurs mois de la période sont tous des mois de novembre ou de décembre.
- **Les promotions pèsent sur la rentabilité** : les mois de soldes et du Black Friday perdent plusieurs points de marge.

---

## Organisation du dépôt

```
ventes-retail-sql/
├── README.md
├── Scripts/                 Création et alimentation de la base, dans l'ordre
│   ├── 01_creation_base.sql
│   ├── 02_preparation.sql
│   ├── 03_enrichissement.sql
│   └── 04_arret_septembre_2026.sql
└── Exercices/
    └── 01_seance_projet_ventes_retail.sql
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
- [ ] Fonctions de fenêtre : classements, cumuls, comparaisons d'une période à l'autre
- [ ] Projet 1 : diagnostic commercial complet
- [ ] Tableau de bord Power BI avec mesures DAX d'évolution annuelle

---

*Projet réalisé dans le cadre de ma formation à l'analyse de données.*
