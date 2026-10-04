
-- 02 - Préparation : cas particuliers et table des magasins
-- À exécuter après 01_creation_base.sql


-- Une cliente qui n'a encore rien acheté
INSERT INTO clients (nom, prenom, email, ville, date_inscription)
VALUES ('Moreau', 'Inès', 'ines.moreau@exemple.fr', 'Lille', '2026-09-20');

-- Un produit jamais vendu
INSERT INTO produits (nom, categorie, prix_unitaire)
VALUES ('Tapis de souris XXL', 'Informatique', 19.90);

-- Qui a parrainé qui (un client pointe vers un autre client)
ALTER TABLE clients ADD COLUMN parrain_id INTEGER REFERENCES clients(client_id);
UPDATE clients SET parrain_id = 1 WHERE client_id = 4;  -- Sophie a parrainé Hugo
UPDATE clients SET parrain_id = 4 WHERE client_id = 6;  -- Hugo a parrainé Nathan
UPDATE clients SET parrain_id = 2 WHERE client_id = 7;  -- Lucas a parrainé Léa
UPDATE clients SET parrain_id = 6 WHERE client_id = 9;  -- Nathan a parrainé Inès

-- Les magasins de l'enseigne
DROP TABLE IF EXISTS magasins;
CREATE TABLE magasins (
    magasin_id     INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ville          VARCHAR(100) NOT NULL,
    date_ouverture DATE
);
INSERT INTO magasins (ville, date_ouverture) VALUES
('Toulouse',   '2020-03-01'),
('Paris',      '2018-09-15'),
('Lyon',       '2021-06-10'),
('Strasbourg', '2024-01-20');
