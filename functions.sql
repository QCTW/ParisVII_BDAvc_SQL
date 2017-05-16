-----------------------

CREATE OR REPLACE FUNCTION calc_numbre_place_dans_billet (idRepre INTEGER) RETURNS INTEGER AS $$
DECLARE
  placeVendu INTEGER;
BEGIN
  SELECT COALESCE(sum(numbre), 0) INTO placeVendu FROM Billet WHERE id_repre = idRepre;
  raise notice 'Places vendus : % ', placeVendu;	
  RETURN placeVendu;
END;
$$ LANGUAGE plpgsql;

------------------------

CREATE OR REPLACE FUNCTION calc_numbre_place_dans_reserv (idRepre INTEGER) RETURNS INTEGER AS $$
DECLARE
  placeReserve INTEGER;
BEGIN
  SELECT COALESCE(sum(numbre_reserver), 0) INTO placeReserve FROM Reservation WHERE id_repre = idRepre;
  raise notice 'Places reserves : % ', placeReserve;
  RETURN placeReserve;
END;
$$ LANGUAGE plpgsql;

------------------------

CREATE OR REPLACE FUNCTION get_seat_sold_percentage (idRepre INTEGER) RETURNS numeric (2,2) AS $$
DECLARE
  vendu numeric (8,2);
  capacity numeric (8,2);
BEGIN
	  SELECT places INTO capacity FROM Repre_Interne AS R NATURAL JOIN Spectacle AS S WHERE R.id_repre = idRepre AND R.id_spectacle = S.id_spectacle;
	  SELECT * INTO vendu FROM calc_numbre_place_dans_billet(idRepre);
	  raise notice 'Taux de vente : % ', (vendu/capacity);
	  RETURN (vendu/capacity);
END;
$$ LANGUAGE plpgsql;

------------------------
