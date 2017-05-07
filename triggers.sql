/* triggers */

--pour la table de cout_spectacle--
-------------------------------------------------------------

CREATE OR REPLACE FUNCTION check_cout_achete() RETURNS TRIGGER AS $$
DECLARE
	ligne cout_spectacle%ROWTYPE;
BEGIN
	if(TG_OP = 'INSERT') then
		--check whether the type of the spectacle is 'achete'.
		if ((select type from Spectacle where id_spectacle = new.id_spectacle) = 1) then 
		--check whether the cost of the spectacle for buying is exist. if not, continue inserting. 
			select * into ligne from Cout_Spectacle where id_spectacle = new.id_spectacle;
			if found then
			--the cost for buying this spectacle is payed, we can not pay it twice.
			raise notice 'on peut que acheter un spectacle une seul fois';
			return null;
			end if;
		end if;
	end if;

	if(TG_OP = 'UPDATE') then
		--if the id_spectacle change, check whether the new.id_spectacle has type achete and has existing cost.
		if (new.id_spectacle <> old.id_spectacle) then
			if ((select type from Spectacle where id_spectacle = new.id_spectacle) = 1) then 
			--check whether the cost of the spectacle for buying is exist. if not, continue inserting. 
				select * into ligne from Cout_Spectacle where id_spectacle = new.id_spectacle;
				if found then 
				--the cost for buying this spectacle is payed, we can not pay it twice.
				raise notice 'on peut que acheter un spectacle une seul fois';
				return null;
				end if;
			end if;
		end if;
	end if;
	return new;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER cout_achete_checker
BEFORE INSERT OR UPDATE ON Cout_Spectacle
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
		--for the case that we change id_spectacle.
		if(new.id_spectacle<>old.id_spectacle) then
			INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
			(old.id_spectacle, 0, new.date_depenser, -old.montant, 'Modifier-enlever ancien cout');
			INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
			(new.id_spectacle, 0, new.date_depenser, new.montant, 'Modifier-ajouter nouveau cout');
		end if;

		if(new.id_spectacle = old.id_spectacle) then
			INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
			(new.id_spectacle, 0, new.date_depenser, new.montant-old.montant, 'Modifier ancien cout');
		end if;

	end if;

	if (TG_OP = 'DELETE') then
		INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
		(old.id_spectacle, 0, old.date_depenser, -old.montant, 'Enlever ancien cout');
	end if;

	return new;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER historique_cout_modifier
AFTER INSERT OR UPDATE OR DELETE ON Cout_Spectacle 
FOR EACH ROW
EXECUTE PROCEDURE modify_cout_historique();

INSERT INTO Cout_Spectacle (id_spectacle, date_depenser, montant) VALUES
(2, '2015-12-23', 300.01);
UPDATE Cout_Spectacle set montant = 140.01 where id_cout = 6;
UPDATE Cout_Spectacle set id_spectacle = 2 where id_cout = 4;
DELETE from Cout_Spectacle where id_cout = 6;

--if insert is failed, the serial number could not rollback. 
--so after one insert is failed in line 29-30, the serial number will be 6 not be 5.
-------------------------------------------------------------

--pour la table subventions--
-------------------------------------------------------------

CREATE OR REPLACE FUNCTION check_subvenir_action() RETURNS TRIGGER AS $$
DECLARE
	type_spectacle integer;
BEGIN
	--check the type of the spectacle 0: cree 1: achete 
	select type into type_spectacle from Spectacle where id_spectacle = new.id_spectacle;

	if(type_spectacle = 0) then new.action = 'creation'; 
	return new;
	end if;

	if(type_spectacle = 1) then new.action = 'accueil';
	return new;
	end if;

	return null;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER subvenir_action_checker
BEFORE INSERT OR UPDATE ON Subventions
FOR EACH ROW
EXECUTE PROCEDURE check_subvenir_action();

INSERT INTO Subventions (id_spectacle, id_organisme, action, montant, date_subvenir) VALUES
(1, 3, '', 220.45, '2014-10-11'),
(2, 1, 'accueil', 100, '2016-01-11');

-------------------------------------------------------------

CREATE OR REPLACE FUNCTION modify_subvenir_historique() RETURNS TRIGGER AS $$
BEGIN

	if (TG_OP = 'INSERT') then
		INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
		(new.id_spectacle, 1, new.date_subvenir, new.montant, 'Ajouter nouveau subventions');
	end if;

	if (TG_OP = 'UPDATE') then
		--for the case that we change id_spectacle.
		if(new.id_spectacle<>old.id_spectacle) then
			INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
			(old.id_spectacle, 1, new.date_subvenir, -old.montant, 'Modifier-enlever ancien subventions');
			INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
			(new.id_spectacle, 1, new.date_subvenir, new.montant, 'Modifier-ajouter nouveau subventions');
		end if;

		if(new.id_spectacle = old.id_spectacle) then
			INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
			(new.id_spectacle, 1, new.date_subvenir, new.montant-old.montant, 'Modifier ancien subventions');
		end if;
	end if;

	if (TG_OP = 'DELETE') then
		INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
		(old.id_spectacle, 1, old.date_subvenir, -old.montant, 'Enlever ancien subventions');
	end if;

	return new;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER historique_subvenir_modifier
AFTER INSERT OR UPDATE OR DELETE ON Subventions 
FOR EACH ROW
EXECUTE PROCEDURE modify_subvenir_historique();

INSERT INTO Subventions (id_spectacle, id_organisme, action, montant, date_subvenir) VALUES
(2, 3, '', 30.54, '2016-12-23');
UPDATE Subventions set montant = 60.42 where id_spectacle = 2 and id_organisme = 3;
UPDATE Subventions set id_spectacle = 3, id_organisme = 1 where id_spectacle = 2 and id_organisme = 1;
UPDATE Subventions set id_organisme = 2 where id_spectacle = 3 and id_organisme = 1;
DELETE from Subventions where id_spectacle = 2 and id_organisme = 3;

-------------------------------------------------------------

--pour la table Repre_Externe--
-------------------------------------------------------------
CREATE OR REPLACE FUNCTION check_type_modify_prix() RETURNS TRIGGER AS $$
DECLARE
	type_spectacle integer;
BEGIN
	--check the type of the spectacle 0: cree 1: achete 
	select type into type_spectacle from Spectacle where id_spectacle = new.id_spectacle;

	if(type_spectacle = 1) then 
	raise notice 'on peut que vendre une representation de spectacle cree'; 
	return null;
	end if;

	--if buy over 10, we give them a discout. we can define more rules.
	if(new.numbre_achete >= 10) then new.prix_vendu = new.prix * 0.8; end if;
	if(new.numbre_achete < 10) then new.prix_vendu = new.prix; end if;

	return new;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER type_checker_prix_modifier
BEFORE INSERT OR UPDATE ON Repre_Externe
FOR EACH ROW
EXECUTE PROCEDURE check_type_modify_prix();

INSERT INTO Repre_Externe (id_spectacle, id_compagnie_accueil, date_transac, prix, numbre_achete) VALUES
(3, 1, '2015-01-05', 100, 1);

-------------------------------------------------------------

CREATE OR REPLACE FUNCTION modify_repre_externe_historique() RETURNS TRIGGER AS $$
BEGIN
	if (TG_OP = 'INSERT') then
		INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
		(new.id_spectacle, 1, new.date_transac, new.prix_vendu * new.numbre_achete, 'Ajouter nouveau vente');
	end if;

	if (TG_OP = 'UPDATE') then
		--for the case that we change id_spectacle.
		if(new.id_spectacle<>old.id_spectacle) then
			INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
			(old.id_spectacle, 1, new.date_transac, -old.prix_vendu*old.numbre_achete, 'Modifier-enlever ancien vente');
			INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
			(new.id_spectacle, 1, new.date_transac, new.prix_vendu*new.numbre_achete, 'Modifier-ajouter nouveau vente');
		end if;

		if(new.id_spectacle = old.id_spectacle) then
			INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
			(new.id_spectacle, 1, new.date_transac, new.prix_vendu*new.numbre_achete-old.prix_vendu*old.numbre_achete, 'Modifier ancien vente');
		end if;
	end if;

	if (TG_OP = 'DELETE') then
		INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
		(old.id_spectacle, 1, old.date_transac, -old.prix_vendu * old.numbre_achete, 'Enlever ancien vente');
	end if;

	return new;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER historique_repre_externe_modifier
AFTER INSERT OR UPDATE OR DELETE ON Repre_Externe 
FOR EACH ROW
EXECUTE PROCEDURE modify_repre_externe_historique();

INSERT INTO Repre_Externe (id_spectacle, id_compagnie_accueil, date_transac, prix, numbre_achete) VALUES
(1, 1, '2015-01-05', 500, 10);
UPDATE Repre_Externe set id_spectacle = 3 where id_repre_ext = 3;
UPDATE Repre_Externe set id_spectacle = 2 where id_repre_ext = 3;
UPDATE Repre_Externe set prix = 100, numbre_achete = 5 where id_repre_ext = 3;
DELETE from Repre_Externe where id_repre_ext = 1;

--when we delete in over 3 table, the time of the operation is current time.
-------------------------------------------------------------

--pour la table Billet--
-------------------------------------------------------------
