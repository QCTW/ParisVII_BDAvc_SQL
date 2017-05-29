-- Load shared funtions
\i functions.sql
------------------------------------------------------------
-- pour la table Billet
-----------------------------------------------------------
CREATE OR REPLACE FUNCTION on_billet_preprocess() RETURNS TRIGGER AS $$
DECLARE 
  repreInfo Repre_Interne%ROWTYPE;
  placeMax integer;
  placeVentu integer;
  placeReserve integer;
  prixAuMoment numeric(8,2);
  existRecord Billet%ROWTYPE;
  today Today.time%TYPE;
BEGIN
  SELECT time INTO today FROM Today WHERE id = 0;
  SELECT * INTO repreInfo FROM Repre_Interne WHERE id_repre = new.id_repre;
  SELECT INTO placeVentu calc_nombre_place_dans_billet(new.id_repre);
  SELECT INTO placeReserve calc_nombre_place_dans_reserv(new.id_repre); 
  SELECT places INTO placeMax FROM Spectacle WHERE id_spectacle = repreInfo.id_spectacle;

  -- For insert, the "nombre" in the INSERT is ALWAYS the "number" of tickets TO BUY (not the sum of all tickets sold)
  IF (TG_OP = 'INSERT') THEN
    IF (today < repreInfo.date_prevendre) THEN
      raise notice 'Le commerce de la representation % n est pas encore commence!', new.id_repre;
      return null;
    ELSIF (today > repreInfo.date_sortir) THEN
      raise notice 'La representation % as deja fini!', new.id_repre;
      return null;
    END IF;
    IF (placeMax - placeVentu - placeReserve) < new.nombre THEN 
      raise notice 'Il n y a pas assez de place pour % billet', new.nombre;
      return null;
    END IF;
    SELECT INTO prixAuMoment get_current_ticket_price(new.id_repre, new.tarif_type);
    IF (new.nombre > 0 AND new.prix_effectif <> prixAuMoment) THEN 
      raise notice 'Votre prix nest pas mise a jour. Nouveau prix : % ', prixAuMoment;
      new.prix_effectif := prixAuMoment;
    END IF;
    SELECT * INTO existRecord FROM Billet WHERE id_repre = new.id_repre AND tarif_type = new.tarif_type AND prix_effectif = new.prix_effectif;
    IF NOT FOUND THEN
	if(new.nombre>0) then
	raise notice '% billets ajouteront', new.nombre;
	return new;
        elsif (new.nombre<0) then
	raise notice 'Vos % billets (%, %, %) n existent pas!', -(new.nombre), new.id_repre, new.tarif_type, new.prix_effectif;
	return null;
	end if;
    ELSE
        UPDATE Billet SET nombre = (existRecord.nombre + new.nombre) 
	WHERE id_repre = new.id_repre AND tarif_type = new.tarif_type AND prix_effectif = new.prix_effectif;
	if (new.nombre>0) then 
	  raise notice '% billets ajouteront', new.nombre;
        elsif (new.nombre<0) then
	  raise notice '% billets rembourseront', new.nombre;
	end if;
        return null;
    END IF;
  END IF;

  if (TG_OP = 'UPDATE') then
    --In case of the change of id_repre by typo...
    if (new.id_repre <> old.id_repre OR new.tarif_type <> old.tarif_type OR new.prix_effectif <> old.prix_effectif ) then
        raise notice 'Vous ne pouvez pas faire UPDATE de Billet.';
        return null;
    end if;
    return new;
  end if;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_billet_preprocessor BEFORE INSERT OR UPDATE ON Billet
FOR EACH ROW 
EXECUTE PROCEDURE on_billet_preprocess();

----------------------------------------------------------
CREATE OR REPLACE FUNCTION on_billet_change() RETURNS TRIGGER AS $$
DECLARE 
  now Today.time%TYPE;
BEGIN
  SELECT time INTO now FROM Today WHERE id = 0;
  if (TG_OP = 'INSERT') then
    INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
    ((select id_spectacle from Repre_Interne where id_repre = new.id_repre), 1, now, new.prix_effectif * new.nombre, 'Une nouvelle recette de billet');
  end if;

  if (TG_OP = 'UPDATE') then
    if (new.id_repre = old.id_repre AND new.nombre <> old.nombre) then
        INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
        ((select id_spectacle from Repre_Interne where id_repre = new.id_repre), 1, now, (new.nombre - old.nombre) * new.prix_effectif, 'Billet vendu/rembourse');
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

------------------------------------------------------------
-- pour la table Today 
------------------------------------------------------------
CREATE OR REPLACE FUNCTION on_time_change() RETURNS TRIGGER AS $$
BEGIN
  delete from Reservation where date_delai < new.time;
return new;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_time_changer AFTER UPDATE ON Today 
FOR EACH ROW 
EXECUTE PROCEDURE on_time_change();

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

-------------------------------------------------------------

CREATE OR REPLACE FUNCTION modify_cout_historique() RETURNS TRIGGER AS $$
DECLARE 
  now Today.time%TYPE;
BEGIN
  SELECT time INTO now FROM Today WHERE id = 0;
  if (TG_OP = 'INSERT') then
    INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
    (new.id_spectacle, 0, now, new.montant, 'Ajouter nouveau cout');
  end if;
  if (TG_OP = 'UPDATE') then
    -- In case that we have to modify id_spectacle because of typo...
    if(new.id_spectacle<>old.id_spectacle) then 
      INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
      (old.id_spectacle, 0, now, -old.montant, 'Modifier-enlever un ancien cout');
      INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
      (new.id_spectacle, 0, now, new.montant, 'Modifier-ajouter un nouveau cout');
    end if;
    if(new.id_spectacle = old.id_spectacle AND new.montant <> old.montant) then
      INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
      (new.id_spectacle, 0, now, new.montant-old.montant, 'Modifier un ancien cout');
    end if;
  end if;

  if (TG_OP = 'DELETE') then
    INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
    (old.id_spectacle, 0, now, -old.montant, 'Enlever un ancien cout');
  end if;

  return new;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER historique_cout_modifier AFTER INSERT OR UPDATE OR DELETE ON Cout_Spectacle 
FOR EACH ROW
EXECUTE PROCEDURE modify_cout_historique();

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

-------------------------------------------------------------

CREATE OR REPLACE FUNCTION modify_subvenir_historique() RETURNS TRIGGER AS $$
DECLARE 
  now Today.time%TYPE;
BEGIN
  SELECT time INTO now FROM Today WHERE id = 0;
  if (TG_OP = 'INSERT') then
    INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
    (new.id_spectacle, 1, now, new.montant, 'Ajouter une nouvelle subvention');
  end if;

  if (TG_OP = 'UPDATE') then
    -- In case that we have to modify id_spectacle because of typo...
    if(new.id_spectacle<>old.id_spectacle) then 
      INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
      (old.id_spectacle, 1, now, -old.montant, 'Modifier-enlever une ancienne subvention');
      INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
      (new.id_spectacle, 1, now, new.montant, 'Modifier-ajouter une nouvelle subvention');
    end if;

    if(new.id_spectacle = old.id_spectacle AND new.montant <> old.montant) then
      INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
      (new.id_spectacle, 1, now, new.montant-old.montant, 'Modifier une ancienne subvention');
    end if;
  end if;

  if (TG_OP = 'DELETE') then
    INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
    (old.id_spectacle, 1, now, -old.montant, 'Enlever une ancienne subvention');
  end if;

  return new;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER historique_subvenir_modifier AFTER INSERT OR UPDATE OR DELETE ON Subvention 
FOR EACH ROW
EXECUTE PROCEDURE modify_subvenir_historique();

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
  if(new.nombre_achete >= 10) then new.prix_vendu = new.prix * 0.8; end if;
  if(new.nombre_achete < 10) then new.prix_vendu = new.prix; end if;

  return new;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER type_checker_prix_modifier BEFORE INSERT OR UPDATE ON Repre_Externe
FOR EACH ROW
EXECUTE PROCEDURE check_type_modify_prix();

-------------------------------------------------------------

CREATE OR REPLACE FUNCTION modify_repre_externe_historique() RETURNS TRIGGER AS $$
DECLARE 
  now Today.time%TYPE;
BEGIN
  SELECT time INTO now FROM Today WHERE id = 0;
  if (TG_OP = 'INSERT') then
    INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
    (new.id_spectacle, 1, now, new.prix_vendu * new.nombre_achete, 'Ajouter une nouvelle vente');
  end if;

  if (TG_OP = 'UPDATE') then
    -- In case that we change id_spectacle because of typo
    if(new.id_spectacle<>old.id_spectacle) then 
      INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
      (old.id_spectacle, 1, now, -old.prix_vendu*old.nombre_achete, 'Modifier-enlever une ancienne vente');
      INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
      (new.id_spectacle, 1, now, new.prix_vendu*new.nombre_achete, 'Modifier-ajouter une nouvelle vente');
    end if;

    if(new.id_spectacle = old.id_spectacle AND new.nombre_achete <> old.nombre_achete) then
      INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
      (new.id_spectacle, 1, now, new.prix_vendu*new.nombre_achete-old.prix_vendu*old.nombre_achete, 'Modifier une ancienne vente');
    end if;
  end if;

  if (TG_OP = 'DELETE') then
    INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
    (old.id_spectacle, 1, now, -old.prix_vendu * old.nombre_achete, 'Enlever une ancienne vente');
  end if;

  return new;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER historique_repre_externe_modifier AFTER INSERT OR UPDATE OR DELETE ON Repre_Externe 
FOR EACH ROW
EXECUTE PROCEDURE modify_repre_externe_historique();

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
  if( new.date_reserver < ligne.date_prevendre ) then 
    raise notice 'Vous ne pouvez pas faire une reservation avant %', ligne.date_prevendre;
    return null; 
  end if;
  if( new.date_delai > ligne.date_sortir) then 
    raise notice 'Vous ne pouvez pas faire une reservation quand la representation % as deja fini!', new.id_repre;
    return null;
  end if;
  --whether we have enough places reste, which include billet and other reservation
  select places into placeTotal from Spectacle where id_spectacle = ligne.id_spectacle;
  raise notice 'Places totals : % ', placeTotal;
  SELECT INTO placeVendu calc_nombre_place_dans_billet(new.id_repre);
  SELECT INTO placeReserve calc_nombre_place_dans_reserv(new.id_repre);
  raise notice 'Places restes : %', placeTotal - placeReserve - placeVendu - new.nombre_reserver;

  if (placeTotal - placeReserve - placeVendu - new.nombre_reserver <= 0 ) then 
    return null;
  end if;

  return new;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER date_places_checker BEFORE INSERT OR UPDATE ON Reservation
FOR EACH ROW
EXECUTE PROCEDURE check_date_places();


