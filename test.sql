-- Insert data
\echo 'Inserting 5 Spectacles';
INSERT INTO Spectacle (nom, type, places, tarif_normal, tarif_reduit) VALUES
('Carmen', 0, 200, 40, 30),
('La Dame Blanche', 0, 100, 40, 30),
('Chat noir !', 0, 100, 60, 55),
('La Peur', 1, 50, 80.5, 60.5),
('Rigoletto', 1, 50, 80.5, 60.5);
SELECT * FROM Spectacle;

\echo 'Inserting 6 costs of spectacle';
INSERT INTO Cout_Spectacle (id_spectacle, date_depenser, montant) VALUES
(1, ((SELECT time FROM Today WHERE id = 0) - interval '90 days'), 555.55),
(2, ((SELECT time FROM Today WHERE id = 0) - interval '60 days'), 1000.10),
(2, ((SELECT time FROM Today WHERE id = 0) - interval '72 hours'), 133.33),
(3, ((SELECT time FROM Today WHERE id = 0) - interval '30 days'), 3000.10),
(4, ((SELECT time FROM Today WHERE id = 0) - interval '60 days'), 1000),
(5, ((SELECT time FROM Today WHERE id = 0) - interval '60 days'), 666.66);
SELECT * FROM Cout_Spectacle;

\echo 'Inserting 3 organismes';
INSERT INTO Organisme (nom, type) VALUES
('Mairie de Paris', 'Municipalite'),
('Ministere de la culture francais', 'Ministere de la culture'),
('Yizhe FAN', 'Mecenat prive');
SELECT * FROM Organisme;

\echo 'Inserting 5 subventions';
INSERT INTO Subvention (id_spectacle, id_organisme, action, montant, date_subvenir) VALUES
(1, 1, 'creation', 3333.33, ((SELECT time FROM Today WHERE id = 0) - interval '100 days')),
(2, 2, 'creation', 2222.22, ((SELECT time FROM Today WHERE id = 0) - interval '100 days')),
(3, 2, 'creation', 1000, ((SELECT time FROM Today WHERE id = 0) - interval '37 days')),
(4, 3, 'accueil', 888, ((SELECT time FROM Today WHERE id = 0) - interval '90 days')),
(5, 1, 'accueil', 888, ((SELECT time FROM Today WHERE id = 0) - interval '90 days'));
SELECT * FROM Subvention;

\echo 'Inserting 1 Compagnie_Accueil';
INSERT INTO Compagnie_Accueil (nom, ville, departement, pays) VALUES
('La Mer', 'Nice', 'Alpes-Maritimes', 'France');
SELECT * FROM Compagnie_Accueil;

\echo 'Inserting 1 Repre_Externe';
INSERT INTO Repre_Externe (id_spectacle, id_compagnie_accueil, date_transac, prix, nombre_achete, prix_vendu) VALUES
(1, 1, (SELECT time FROM Today WHERE id = 0), 777.77, 1, 777.77);
SELECT * FROM Repre_Externe;

\echo 'Inserting 6 Repre_Interne: 1 has ended. 4 are starting to sell today, 1 will sell in the future';
INSERT INTO Repre_Interne (id_spectacle, date_prevendre, date_sortir, politique) VALUES
(1, ((SELECT time FROM Today WHERE id = 0) - interval '40 days'),((SELECT time FROM Today WHERE id = 0) - interval '10 days'), 1),
(1, ((SELECT time FROM Today WHERE id = 0) - interval '20 days'),((SELECT time FROM Today WHERE id = 0) + interval '25 days'), 1),
(2, (SELECT time FROM Today WHERE id = 0), ((SELECT time FROM Today WHERE id = 0) + interval '30 days'), 2),
(3, ((SELECT time FROM Today WHERE id = 0) + interval '15 days'),((SELECT time FROM Today WHERE id = 0) + interval '45 days'), 3),
(4, (SELECT time FROM Today WHERE id = 0), ((SELECT time FROM Today WHERE id = 0) + interval '30 days'), 1),
(5, (SELECT time FROM Today WHERE id = 0), ((SELECT time FROM Today WHERE id = 0) + interval '30 days'), 0);
SELECT * FROM Repre_Interne;

-- To test on_billet_changer
\echo 'Buy 4 billets of representation 2 by INSERT';
INSERT into Billet VALUES (2, 1, 0.0, 4);
SELECT * FROM Billet;
\echo 'Manully UPDATE one billet';
UPDATE Billet SET prix_effectif = 66.66 WHERE id_repre = 2 AND tarif_type = 1;
SELECT * FROM Billet;
\echo 'DELETE one billet';
DELETE FROM Billet WHERE id_repre = 2 AND tarif_type = 1;
SELECT * FROM Billet;
SELECT * FROM Historique;

-- To test cout_achete_checker
\echo 'Incorrect operation test for Cout_Spectacle'
INSERT INTO Cout_Spectacle (id_spectacle, date_depenser, montant) VALUES
(4, (select time from today where id = 0), 500.01); --should be failed
UPDATE cout_spectacle set id_spectacle = 5 where id_cout = 5; -- should be failed
SELECT * FROM Cout_Spectacle;

-- To test historique_cout_modifier
\echo 'Test Historique additions when Cout_Spectacle INSERT/UPDATE'
INSERT INTO Cout_Spectacle (id_spectacle, date_depenser, montant) VALUES
(1, (select time from today where id = 0), 50.50); 
UPDATE Cout_Spectacle set montant = 2000 where id_cout = 5; 
UPDATE Cout_Spectacle set id_spectacle = 1 where id_cout = 5;
DELETE from Cout_Spectacle where id_cout = 5;
SELECT * FROM Cout_Spectacle;
SELECT * FROM Historique;

-- Check check_subvenir_action
\echo 'Adding 2 subventions by INSERT'
INSERT INTO Subvention (id_spectacle, id_organisme, action, montant, date_subvenir) VALUES
(1, 3, '', 220.45, ((SELECT time FROM Today WHERE id = 0) - interval '30 days')), --action should be written
(2, 1, 'accueil', 100, ((SELECT time FROM Today WHERE id = 0) - interval '30 days')); --action should be modified
SELECT * FROM Subvention;
SELECT * FROM Historique;

-- Check historique_subvenir_modifier
\echo 'Test UPDATE for Subvention'
INSERT INTO Subvention (id_spectacle, id_organisme, action, montant, date_subvenir) VALUES
(1, 3, '', 100, (SELECT time FROM Today WHERE id = 0)); 
UPDATE Subvention set montant = 3000.33 where id_spectacle = 1 and id_organisme = 1;
UPDATE Subvention set id_spectacle = 3, id_organisme = 1 where id_spectacle = 2 and id_organisme = 2;
UPDATE Subvention set id_organisme = 2 where id_spectacle = 4 and id_organisme = 3; --should change nothing in historique
DELETE from Subvention where id_spectacle = 1 and id_organisme = 3; 
SELECT * FROM Subvention;
SELECT * FROM Historique;

-- Check type_checker_prix_modifier
\echo 'Adding a spectacle bought from outside into Repre_Externe'
INSERT INTO Repre_Externe (id_spectacle, id_compagnie_accueil, date_transac, prix, nombre_achete) VALUES
(5, 1, (SELECT time FROM Today WHERE id = 0), 500, 1); --should be failed
SELECT * FROM Repre_Externe;

-- Check historique_repre_externe_modifier
\echo 'Test UPDATE/DELETE operation for a spectacle created by theater in Repre_Externe'
INSERT INTO Repre_Externe (id_spectacle, id_compagnie_accueil, date_transac, prix, nombre_achete) VALUES
(3, 1, ((SELECT time FROM Today WHERE id = 0) - interval '10 days'), 500, 10); --should change the final price
UPDATE Repre_Externe set id_spectacle = 3 where id_repre_ext = 3; --should be failed
UPDATE Repre_Externe set id_spectacle = 2 where id_repre_ext = 3;
UPDATE Repre_Externe set prix = 100, nombre_achete = 5 where id_repre_ext = 3;
DELETE from Repre_Externe where id_repre_ext = 1;
SELECT * FROM Repre_Externe;

-- Check date_places_checker
\echo 'Test incorrect operation on Reservation'
INSERT INTO Reservation (id_repre, date_reserver, date_delai, nombre_reserver) VALUES
(3, ((SELECT time FROM Today WHERE id = 0) + interval '1 days'), ((SELECT time FROM Today WHERE id = 0) + interval '60 days'), 10); -- should be failed pay too late
INSERT INTO Reservation (id_repre, date_reserver, date_delai, nombre_reserver) VALUES
(3, ((SELECT time FROM Today WHERE id = 0) - interval '1 days'), ((SELECT time FROM Today WHERE id = 0) + interval '7 days'), 10); -- should be failed buy too early
INSERT INTO Reservation (id_repre, date_reserver, date_delai, nombre_reserver) VALUES
(3, ((SELECT time FROM Today WHERE id = 0) + interval '1 days'), ((SELECT time FROM Today WHERE id = 0) + interval '7 days'), 150); -- should be failed cause places not enough
UPDATE Reservation set nombre_reserver = 100 where id_reserve = 3; -- should be failed cause places not enough
SELECT * FROM Reservation;

-- Check payment function
\echo 'Ask normal and reduced price then make reservtion for representation 2 function'
SELECT get_current_ticket_price(2, 1);
SELECT get_current_ticket_price(2, 0);
SELECT reserver(2, 10);
\echo 'Make reservation for representation 2 and pay this reservation by function'
SELECT pay_reservation(reserver(2, 4), 2, 2);
SELECT * FROM Reservation;
SELECT * FROM Billet;

-- Test on_time_changer
--UPDATE Today SET time = current_timestamp WHERE id = 0;
