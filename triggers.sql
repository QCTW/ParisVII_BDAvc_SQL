/* triggers */
----------------------------------------------------
--pour la table de cout_spectacle--

CREATE TRIGGER Cout_Achete_Insert_Checker
BEFORE INSERT ON Cout_Spectacle
FOR EACH ROW
EXECUTE PROCEDURE check_spectacle_achete();

CREATE OR REPLACE FUNCTION check_spectacle_achete() RETURNS TRIGGER AS $$
DECLARE
	ligne cout_spectacle%ROWTYPE;
BEGIN
	if ((select type from Spectacle where id_spectacle = new.id_spectacle) = 0) then return new;
	end if;

	select * into ligne from cout_spectacle where id_spectacle = new.id_spectacle;
	if not found then return new;
	end if;

	raise notice 'on peut que acheter un spectacle une seul fois';
	return null;
END;
$$ LANGUAGE plpgsql;

INSERT INTO Cout_Spectacle (id_spectacle, date_depenser, montant) VALUES
(3, '2015-01-10', 500.01);

/* CREATE TRIGGER Historique_Cout_Modifier
AGTER INSERT OR UPDATE OR DELETE ON Cout_Spectacle 
FOR EACH ROW
EXECUTE PROCEDURE modify_historique();
*/

