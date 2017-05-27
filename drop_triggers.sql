-- Drop all used triggers for clean install
DROP TRIGGER IF EXISTS on_billet_preprocessor ON Billet;
DROP TRIGGER IF EXISTS on_billet_changer ON Billet;
DROP TRIGGER IF EXISTS on_time_changer ON Today;
DROP TRIGGER IF EXISTS cout_achete_checker ON Cout_Spectacle;
DROP TRIGGER IF EXISTS historique_cout_modifier ON Cout_Spectacle;
DROP TRIGGER IF EXISTS subvenir_action_checker ON Subvention;
DROP TRIGGER IF EXISTS historique_subvenir_modifier ON Subvention;
DROP TRIGGER IF EXISTS type_checker_prix_modifier ON Repre_Externe;
DROP TRIGGER IF EXISTS historique_repre_externe_modifier ON Repre_Externe;
DROP TRIGGER IF EXISTS date_places_checker ON Reservation;

