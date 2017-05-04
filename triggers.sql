/* triggers */

--pour la table de cout_spectacle--
-------------------------------------------------------------

CREATE OR REPLACE FUNCTION check_cout_achete() RETURNS TRIGGER AS $$
DECLARE
	ligne cout_spectacle%ROWTYPE;
BEGIN
	--check whether the type of the spectacle is 'achete'. if not, don't need to check.
	if ((select type from Spectacle where id_spectacle = new.id_spectacle) = 0) then return new;
	end if;

	--check whether the cost of the spectacle for buying is exist. if not, continue inserting. 
	select * into ligne from Cout_Spectacle where id_spectacle = new.id_spectacle;
	if not found then return new;
	end if;

	--the cost for buying this spectacle is payed, we can not pay it twice.
	raise notice 'on peut que acheter un spectacle une seul fois';
	return null;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER cout_achete_checker
BEFORE INSERT ON Cout_Spectacle
FOR EACH ROW
EXECUTE PROCEDURE check_cout_achete();

INSERT INTO Cout_Spectacle (id_spectacle, date_depenser, montant) VALUES
(3, '2015-01-10', 500.01);

-------------------------------------------------------------

CREATE OR REPLACE FUNCTION modify_cout_historique() RETURNS TRIGGER AS $$
BEGIN

	if (TG_OP = 'INSERT') then
		INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
		(new.id_spectacle, 0, new.date_depenser, new.montant, 'Ajouter nouveau cout');
	end if;

	if (TG_OP = 'UPDATE') then
		INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
		(new.id_spectacle, 0, new.date_depenser, new.montant-old.montant, 'Modifier ancien cout');

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
BEFORE INSERT ON Subventions
FOR EACH ROW
EXECUTE PROCEDURE check_subvenir_action();

INSERT INTO Subventions (id_spectacle, id_organisme, action, montant, date_subvenir) VALUES
(1, 3, '', 220.45, '2014-10-11'),
(2, 1, 'accueil', 100, '2016-01-11'),
(3, 1, 'creation', 20, '2017-01-14');

-------------------------------------------------------------

CREATE OR REPLACE FUNCTION modify_subvenir_historique() RETURNS TRIGGER AS $$
BEGIN

	if (TG_OP = 'INSERT') then
		INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
		(new.id_spectacle, 1, new.date_subvenir, new.montant, 'Ajouter nouveau subventions');
	end if;

	if (TG_OP = 'UPDATE') then
		INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
		(new.id_spectacle, 1, new.date_subvenir, new.montant-old.montant, 'Modifier ancien subventions');
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
DELETE from Subventions where id_spectacle = 2 and id_organisme = 3;

-------------------------------------------------------------