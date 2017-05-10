-- Load shared funtions
\i functions.sql
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
------------------------------------------------------------
-- pour la table Billet
-----------------------------------------------------------
CREATE OR REPLACE FUNCTION on_billet_preprocess() RETURNS TRIGGER AS $$
DECLARE 
  repreInfo Repre_Interne%ROWTYPE;
  placeMax integer;
  placeVentu integer;
  placeReserve integer;
BEGIN
  SELECT * INTO repreInfo FROM Repre_Interne WHERE id_repre = new.id_repre;
  SELECT INTO placeVentu calc_numbre_place_dans_billet(new.id_repre);
  SELECT INTO placeReserve calc_numbre_place_dans_reserv(new.id_repre); 
  SELECT places INTO placeMax FROM Spectacle WHERE id_spectacle = repreInfo.id_spectacle;

  if (TG_OP = 'INSERT') then
    if (placeMax - placeVentu - placeReserve) < new.numbre then 
      raise notice 'Il n y a pas assez de place pour % billet', new.numbre;
      return null;
    end if;
    return new;
  end if;

  if (TG_OP = 'UPDATE') then
    if (new.numbre > old.numbre) then
      if (placeMax - placeVentu - placeReserve) < (new.numbre-old.numbre) then
        raise notice 'Il n y a pas assez de place pour % billet', new.numbre;
        return null;
      end if;
    end if;
    return new;
  end if;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_billet_preprocessor BEFORE INSERT OR UPDATE ON Billet
FOR EACH ROW 
EXECUTE PROCEDURE on_billet_preprocess();

INSERT into Billet VALUES (1, 0, 1, 99.9, 9);
UPDATE Billet SET numbre = 100 WHERE id_repre = 1 AND tarif_type = 0 AND par_politique = 1;

----------------------------------------------------------
CREATE OR REPLACE FUNCTION on_billet_change() RETURNS TRIGGER AS $$
DECLARE 
  now Today.time%TYPE;
BEGIN
  SELECT time INTO now FROM Today WHERE id = 0;
  if (TG_OP = 'INSERT') then
    INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
    ((select id_spectacle from Repre_Interne where id_repre = new.id_repre), 1, now, new.prix_effectif, 'Une nouvelle recette de billet');
  end if;

  if (TG_OP = 'UPDATE') then
    --In case of the change of id_repre by typo...
    if (new.id_repre <> old.id_repre) then
        INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
        ((SELECT id_spectacle FROM Repre_Interne WHERE id_repre = new.id_repre), 1, now, new.prix_effectif, 'Ajouter un billet avec id_repre correct'),
	((SELECT id_spectacle FROM Repre_Interne WHERE id_repre = old.id_repre), 1, now, -old.prix_effectif, 'Enlever un billet qui as id_repre incorrect');
    end if;
    if (new.id_repre = old.id_repre AND new.prix_effectif <> old.prix_effectif) then
        INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
        ((select id_spectacle from Repre_Interne where id_repre = new.id_repre), 1, now, new.prix_effectif - old.prix_effectif, 'Modifier un billet');
    end if;
  end if;

  if (TG_OP = 'DELETE') then
    INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
    ((select id_spectacle from Repre_Interne where id_repre = old.id_repre), 1, now, -old.prix_effectif, 'Elever un billet');
  end if;
  return new;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_billet_changer AFTER INSERT OR UPDATE OR DELETE ON Billet
FOR EACH ROW
EXECUTE PROCEDURE on_billet_change();

-- Test
INSERT into Billet VALUES (2, 1, 1, 111.11, 11);
UPDATE Billet SET prix_effectif = 200 WHERE id_repre = 2 AND tarif_type = 1 AND par_politique = 1;
DELETE FROM Billet WHERE id_repre = 2 AND tarif_type = 1 AND par_politique = 1;

------------------------------------------------------------
-- pour la table Today 
------------------------------------------------------------
CREATE OR REPLACE FUNCTION on_time_change() RETURNS TRIGGER AS $$
BEGIN
  delete from Reservation where date_delai < new.time;
  /*SELECT into teste EXTRACT(epoch FROM (reserv.date_delai - new.time)); */
return new;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_time_changer AFTER UPDATE ON Today 
FOR EACH ROW 
EXECUTE PROCEDURE on_time_change();

UPDATE Today SET time = current_timestamp WHERE id = 0;

------------------------------------------------------------
-- pour la table Cout_spectacle
-------------------------------------------------------------
CREATE OR REPLACE FUNCTION check_cout_achete() RETURNS TRIGGER AS $$
DECLARE
  ligne cout_spectacle%ROWTYPE;
BEGIN
  if (TG_OP = 'INSERT') then
    --check whether the type of the spectacle is 'achete'.
    if ((select type from Spectacle where id_spectacle = new.id_spectacle) = 1) then 
    --check whether the cost of the spectacle for buying is exist. if not, continue inserting. 
      select * into ligne from Cout_Spectacle where id_spectacle = new.id_spectacle;
      if found then
      --the cost for buying this spectacle is payed, we can not pay it twice.
      raise notice 'Vous pouvez acheter un spectacle une seul fois';
      return null;
      end if;
    end if;
  end if;

  if (TG_OP = 'UPDATE') then
    --if the id_spectacle change, check whether the new.id_spectacle has type achete and has existing cost.
    if (new.id_spectacle <> old.id_spectacle) then
      if ((select type from Spectacle where id_spectacle = new.id_spectacle) = 1) then 
      --check whether the cost of the spectacle for buying is exist. if not, continue inserting. 
        select * into ligne from Cout_Spectacle where id_spectacle = new.id_spectacle;
        if found then 
        --the cost for buying this spectacle is payed, we can not pay it twice.
        raise notice 'Vouz pouvez acheter un spectacle une seul fois';
        return null;
        end if;
      end if;
    end if;
  end if;
  return new;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER cout_achete_checker BEFORE INSERT OR UPDATE ON Cout_Spectacle
FOR EACH ROW
EXECUTE PROCEDURE check_cout_achete();

INSERT INTO Cout_Spectacle (id_spectacle, date_depenser, montant) VALUES
(3, '2015-01-10', 500.01);
UPDATE cout_spectacle set id_spectacle = 3 where id_cout = 2;

-------------------------------------------------------------

CREATE OR REPLACE FUNCTION modify_cout_historique() RETURNS TRIGGER AS $$
BEGIN
  if (TG_OP = 'INSERT') then
    INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
    (new.id_spectacle, 0, new.date_depenser, new.montant, 'Ajouter nouveau cout');
  end if;
  if (TG_OP = 'UPDATE') then
    -- In case that we have to modify id_spectacle because of typo...
    if(new.id_spectacle<>old.id_spectacle) then 
      INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
      (old.id_spectacle, 0, new.date_depenser, -old.montant, 'Modifier-enlever un ancien cout');
      INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
      (new.id_spectacle, 0, new.date_depenser, new.montant, 'Modifier-ajouter un nouveau cout');
    end if;
    if(new.id_spectacle = old.id_spectacle AND new.montant <> old.montant) then
      INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
      (new.id_spectacle, 0, new.date_depenser, new.montant-old.montant, 'Modifier un ancien cout');
    end if;
  end if;

  if (TG_OP = 'DELETE') then
    INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
    (old.id_spectacle, 0, old.date_depenser, -old.montant, 'Enlever un ancien cout');
  end if;

  return new;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER historique_cout_modifier AFTER INSERT OR UPDATE OR DELETE ON Cout_Spectacle 
FOR EACH ROW
EXECUTE PROCEDURE modify_cout_historique();

INSERT INTO Cout_Spectacle (id_spectacle, date_depenser, montant) VALUES
(2, '2015-12-23', 300.01);
UPDATE Cout_Spectacle set montant = 140.01 where id_cout = 6;
UPDATE Cout_Spectacle set id_spectacle = 2 where id_cout = 4;
DELETE from Cout_Spectacle where id_cout = 6;

-------------------------------------------------------------
--pour la table subvention
-------------------------------------------------------------

CREATE OR REPLACE FUNCTION check_subvenir_action() RETURNS TRIGGER AS $$
DECLARE
  type_spectacle integer;
BEGIN
  --check the type of the spectacle 0: cree 1: achete 
  select type into type_spectacle from Spectacle where id_spectacle = new.id_spectacle;
  if (type_spectacle = 0) then new.action = 'creation'; 
  return new;
  end if;
  if (type_spectacle = 1) then new.action = 'accueil';
  return new;
  end if;
  return null;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER subvenir_action_checker BEFORE INSERT OR UPDATE ON Subvention
FOR EACH ROW
EXECUTE PROCEDURE check_subvenir_action();

INSERT INTO Subvention (id_spectacle, id_organisme, action, montant, date_subvenir) VALUES
(1, 3, '', 220.45, '2014-10-11'),
(2, 1, 'accueil', 100, '2016-01-11');

-------------------------------------------------------------

CREATE OR REPLACE FUNCTION modify_subvenir_historique() RETURNS TRIGGER AS $$
BEGIN
  if (TG_OP = 'INSERT') then
    INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
    (new.id_spectacle, 1, new.date_subvenir, new.montant, 'Ajouter une nouvelle subvention');
  end if;

  if (TG_OP = 'UPDATE') then
    -- In case that we have to modify id_spectacle because of typo...
    if(new.id_spectacle<>old.id_spectacle) then 
      INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
      (old.id_spectacle, 1, new.date_subvenir, -old.montant, 'Modifier-enlever une ancienne subvention');
      INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
      (new.id_spectacle, 1, new.date_subvenir, new.montant, 'Modifier-ajouter une nouvelle subvention');
    end if;

    if(new.id_spectacle = old.id_spectacle AND new.montant <> old.montant) then
      INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
      (new.id_spectacle, 1, new.date_subvenir, new.montant-old.montant, 'Modifier une ancienne subvention');
    end if;
  end if;

  if (TG_OP = 'DELETE') then
    INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
    (old.id_spectacle, 1, old.date_subvenir, -old.montant, 'Enlever une ancienne subvention');
  end if;

  return new;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER historique_subvenir_modifier AFTER INSERT OR UPDATE OR DELETE ON Subvention 
FOR EACH ROW
EXECUTE PROCEDURE modify_subvenir_historique();

INSERT INTO Subvention (id_spectacle, id_organisme, action, montant, date_subvenir) VALUES
(2, 3, '', 30.54, '2016-12-23');
UPDATE Subvention set montant = 60.42 where id_spectacle = 2 and id_organisme = 3;
UPDATE Subvention set id_spectacle = 3, id_organisme = 1 where id_spectacle = 2 and id_organisme = 1;
UPDATE Subvention set id_organisme = 2 where id_spectacle = 3 and id_organisme = 1;
DELETE from Subvention where id_spectacle = 2 and id_organisme = 3;

-------------------------------------------------------------
--pour la table Repre_Externe
-------------------------------------------------------------
CREATE OR REPLACE FUNCTION check_type_modify_prix() RETURNS TRIGGER AS $$
DECLARE
  type_spectacle integer;
BEGIN
  --check the type of the spectacle 0: cree 1: achete 
  select type into type_spectacle from Spectacle where id_spectacle = new.id_spectacle;
  if(type_spectacle = 1) then 
    raise notice 'Vous ne pouvez pas vendre un spectacle achete'; 
  return null;
  end if;

  --if buy over 10, we give them a discount. we can define more rules.
  if(new.numbre_achete >= 10) then new.prix_vendu = new.prix * 0.8; end if;
  if(new.numbre_achete < 10) then new.prix_vendu = new.prix; end if;

  return new;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER type_checker_prix_modifier BEFORE INSERT OR UPDATE ON Repre_Externe
FOR EACH ROW
EXECUTE PROCEDURE check_type_modify_prix();

INSERT INTO Repre_Externe (id_spectacle, id_compagnie_accueil, date_transac, prix, numbre_achete) VALUES
(3, 1, '2015-01-05', 100, 1);

-------------------------------------------------------------

CREATE OR REPLACE FUNCTION modify_repre_externe_historique() RETURNS TRIGGER AS $$
BEGIN
  if (TG_OP = 'INSERT') then
    INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
    (new.id_spectacle, 1, new.date_transac, new.prix_vendu * new.numbre_achete, 'Ajouter une nouvelle vente');
  end if;

  if (TG_OP = 'UPDATE') then
    -- In case that we change id_spectacle because of typo
    if(new.id_spectacle<>old.id_spectacle) then 
      INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
      (old.id_spectacle, 1, new.date_transac, -old.prix_vendu*old.numbre_achete, 'Modifier-enlever une ancienne vente');
      INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
      (new.id_spectacle, 1, new.date_transac, new.prix_vendu*new.numbre_achete, 'Modifier-ajouter une nouvelle vente');
    end if;

    if(new.id_spectacle = old.id_spectacle AND new.numbre_achete <> old.numbre_achete) then
      INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
      (new.id_spectacle, 1, new.date_transac, new.prix_vendu*new.numbre_achete-old.prix_vendu*old.numbre_achete, 'Modifier une ancienne vente');
    end if;
  end if;

  if (TG_OP = 'DELETE') then
    INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
    (old.id_spectacle, 1, old.date_transac, -old.prix_vendu * old.numbre_achete, 'Enlever une ancienne vente');
  end if;

  return new;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER historique_repre_externe_modifier AFTER INSERT OR UPDATE OR DELETE ON Repre_Externe 
FOR EACH ROW
EXECUTE PROCEDURE modify_repre_externe_historique();

INSERT INTO Repre_Externe (id_spectacle, id_compagnie_accueil, date_transac, prix, numbre_achete) VALUES
(1, 1, '2015-01-05', 500, 10);
UPDATE Repre_Externe set id_spectacle = 3 where id_repre_ext = 3;
UPDATE Repre_Externe set id_spectacle = 2 where id_repre_ext = 3;
UPDATE Repre_Externe set prix = 100, numbre_achete = 5 where id_repre_ext = 3;
DELETE from Repre_Externe where id_repre_ext = 1;

-------------------------------------------------------------
--pour la table Reservation
-------------------------------------------------------------

CREATE OR REPLACE FUNCTION check_date_places() RETURNS TRIGGER AS $$
DECLARE
	ligne Repre_Interne%ROWTYPE;
	placeTotal integer;
	placeReserve integer;
	placeVendu integer;
BEGIN
	select * into ligne from Repre_Interne where id_repre = new.id_repre;

	--check the date_reserver >= date_prevendre and date_delai <= date_sortir
	if( new.date_reserver < ligne.date_prevendre ) then return null; end if;
	if( new.date_delai > ligne.date_sortir) then return null; end if;

	--whether we have enough places reste, which include billet and other reservation
	select places into placeTotal from Spectacle where id_spectacle = ligne.id_spectacle;
	raise notice 'Places totals : % ', placeTotal;

	SELECT INTO placeVendu calc_numbre_place_dans_billet(new.id_repre);
	raise notice 'Places vendus : % ', placeVendu;

	SELECT INTO placeReserve calc_numbre_place_dans_reserv(new.id_repre);
	raise notice 'Places reserves : % ', placeReserve;

	raise notice 'Places restes : %', placeTotal - placeReserve - placeVendu - new.numbre_reserver;

	if(placeTotal - placeReserve - placeVendu - new.numbre_reserver <= 0 ) then return null; end if;

	return new;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER date_places_checker BEFORE INSERT OR UPDATE ON Reservation
FOR EACH ROW
EXECUTE PROCEDURE check_date_places();

INSERT INTO Reservation (id_repre, date_reserver, date_delai, numbre_reserver) VALUES
(3, '2017-04-10', '2017-04-18', 10);
INSERT INTO Reservation (id_repre, date_reserver, date_delai, numbre_reserver) VALUES
(3, '2017-04-18', '2017-04-28', 10);
INSERT INTO Reservation (id_repre, date_reserver, date_delai, numbre_reserver) VALUES
(3, '2017-04-18', '2017-04-20', 50);
UPDATE Reservation set numbre_reserver = 100 where id_reserve = 1;
