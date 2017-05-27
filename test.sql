INSERT into Billet VALUES (1, 1, 99.9, 9);
UPDATE Billet SET numbre = 100 WHERE id_repre = 1 AND tarif_type = 0;

-- To test on_billet_changer
INSERT into Billet VALUES (2, 1, 111.11, 11);
UPDATE Billet SET prix_effectif = 200 WHERE id_repre = 2 AND tarif_type = 1;
DELETE FROM Billet WHERE id_repre = 2 AND tarif_type = 1;

-- To test cout_achete_checker
INSERT INTO Cout_Spectacle (id_spectacle, date_depenser, montant) VALUES
(3, '2015-01-10', 500.01);
UPDATE cout_spectacle set id_spectacle = 3 where id_cout = 2;

-- To test historique_cout_modifier
INSERT INTO Cout_Spectacle (id_spectacle, date_depenser, montant) VALUES
(2, '2015-12-23', 300.01);
UPDATE Cout_Spectacle set montant = 140.01 where id_cout = 6;
UPDATE Cout_Spectacle set id_spectacle = 2 where id_cout = 4;
DELETE from Cout_Spectacle where id_cout = 6;

-- Check check_subvenir_action
INSERT INTO Subvention (id_spectacle, id_organisme, action, montant, date_subvenir) VALUES
(1, 3, '', 220.45, '2014-10-11'),
(2, 1, 'accueil', 100, '2016-01-11');


-- Check historique_subvenir_modifier
INSERT INTO Subvention (id_spectacle, id_organisme, action, montant, date_subvenir) VALUES
(2, 3, '', 30.54, '2016-12-23');
UPDATE Subvention set montant = 60.42 where id_spectacle = 2 and id_organisme = 3;
UPDATE Subvention set id_spectacle = 3, id_organisme = 1 where id_spectacle = 2 and id_organisme = 1;
UPDATE Subvention set id_organisme = 2 where id_spectacle = 3 and id_organisme = 1;
DELETE from Subvention where id_spectacle = 2 and id_organisme = 3;

-- Check type_checker_prix_modifier
INSERT INTO Repre_Externe (id_spectacle, id_compagnie_accueil, date_transac, prix, numbre_achete) VALUES
(3, 1, '2015-01-05', 100, 1);

-- Check historique_repre_externe_modifier
INSERT INTO Repre_Externe (id_spectacle, id_compagnie_accueil, date_transac, prix, numbre_achete) VALUES
(1, 1, '2015-01-05', 500, 10);
UPDATE Repre_Externe set id_spectacle = 3 where id_repre_ext = 3;
UPDATE Repre_Externe set id_spectacle = 2 where id_repre_ext = 3;
UPDATE Repre_Externe set prix = 100, numbre_achete = 5 where id_repre_ext = 3;
DELETE from Repre_Externe where id_repre_ext = 1;

-- Check date_places_checker
INSERT INTO Reservation (id_repre, date_reserver, date_delai, numbre_reserver) VALUES
(3, '2017-04-10', '2017-04-18', 10);
INSERT INTO Reservation (id_repre, date_reserver, date_delai, numbre_reserver) VALUES
(3, '2017-04-18', '2017-04-28', 10);
INSERT INTO Reservation (id_repre, date_reserver, date_delai, numbre_reserver) VALUES
(3, '2017-04-18', '2017-04-20', 50);
UPDATE Reservation set numbre_reserver = 100 where id_reserve = 1;

-- Test on_time_changer
UPDATE Today SET time = current_timestamp WHERE id = 0;
