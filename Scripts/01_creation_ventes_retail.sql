
-- Base d'entraînement : clients, produits et ventes
-- À exécuter dans le Query Tool de la base ventes_retail


-- Supprime les tables si elles existent déjà (permet de relancer le script)
DROP TABLE IF EXISTS ventes, produits, clients;

-- ---------- Table des clients ----------
CREATE TABLE clients (
    client_id        INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nom              VARCHAR(100) NOT NULL,
    prenom           VARCHAR(100) NOT NULL,
    email            VARCHAR(150) UNIQUE,
    ville            VARCHAR(100),
    date_inscription DATE DEFAULT CURRENT_DATE
);

-- ---------- Table des produits ----------
CREATE TABLE produits (
    produit_id    INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nom           VARCHAR(150) NOT NULL,
    categorie     VARCHAR(50)  NOT NULL,
    prix_unitaire NUMERIC(10,2) NOT NULL CHECK (prix_unitaire >= 0)
);

-- ---------- Table des ventes ----------
-- Chaque vente relie un client à un produit (clés étrangères)
CREATE TABLE ventes (
    vente_id   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id  INTEGER NOT NULL REFERENCES clients(client_id),
    produit_id INTEGER NOT NULL REFERENCES produits(produit_id),
    date_vente DATE    NOT NULL,
    quantite   INTEGER NOT NULL CHECK (quantite > 0)
);

-- ---------- Données d'exemple ----------
INSERT INTO clients (nom, prenom, email, ville, date_inscription) VALUES
('Martin',  'Sophie',  'sophie.martin@exemple.fr',  'Toulouse',    '2025-11-03'),
('Bernard', 'Lucas',   'lucas.bernard@exemple.fr',  'Bordeaux',    '2025-12-15'),
('Dubois',  'Emma',    'emma.dubois@exemple.fr',    'Lyon',        '2026-01-08'),
('Thomas',  'Hugo',    'hugo.thomas@exemple.fr',    'Toulouse',    '2026-02-20'),
('Robert',  'Chloé',   'chloe.robert@exemple.fr',   'Paris',       '2026-03-11'),
('Petit',   'Nathan',  'nathan.petit@exemple.fr',   'Montpellier', '2026-04-02'),
('Durand',  'Léa',     'lea.durand@exemple.fr',     'Nantes',      '2026-05-27'),
('Leroy',   'Gabriel', 'gabriel.leroy@exemple.fr',  'Marseille',   '2026-06-14');

INSERT INTO produits (nom, categorie, prix_unitaire) VALUES
('Ordinateur portable 15 pouces', 'Informatique', 899.00),
('Souris sans fil',               'Informatique',  24.90),
('Écran 27 pouces',               'Informatique', 249.00),
('Casque audio',                  'Audio',        129.00),
('Enceinte Bluetooth',            'Audio',         79.90),
('Chaise de bureau',              'Mobilier',     189.00),
('Bureau réglable',               'Mobilier',     349.00),
('Lampe de bureau',               'Mobilier',      39.90);

INSERT INTO ventes (client_id, produit_id, date_vente, quantite) VALUES
(1, 1, '2026-01-12', 1),
(1, 2, '2026-01-12', 2),
(2, 4, '2026-01-25', 1),
(3, 3, '2026-02-03', 2),
(4, 6, '2026-02-18', 1),
(2, 5, '2026-03-07', 3),
(5, 1, '2026-03-21', 1),
(5, 3, '2026-03-21', 1),
(6, 8, '2026-04-09', 4),
(3, 7, '2026-04-30', 1),
(7, 2, '2026-05-14', 1),
(4, 4, '2026-05-28', 2),
(8, 6, '2026-06-19', 2),
(1, 5, '2026-07-02', 1),
(6, 1, '2026-07-16', 1),
(7, 7, '2026-08-05', 1),
(8, 3, '2026-08-22', 1),
(2, 8, '2026-09-03', 2),
(5, 4, '2026-09-15', 1),
(3, 2, '2026-09-27', 3);
