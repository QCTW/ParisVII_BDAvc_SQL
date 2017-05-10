CREATE OR REPLACE FUNCTION calc_numbre_place_dans_billet (idRepre INTEGER) RETURNS INTEGER AS $$
DECLARE
  placeVendu INTEGER;
BEGIN
  SELECT sum(numbre) INTO placeVendu FROM Billet WHERE id_repre = idRepre;
  raise notice 'Places vendus : % ', placeVendu;	
  RETURN placeVendu;
END;
$$ LANGUAGE plpgsql;

------------------------

CREATE OR REPLACE FUNCTION calc_numbre_place_dans_reserv (idRepre INTEGER) RETURNS INTEGER AS $$
DECLARE
  placeReserve INTEGER;
BEGIN
  SELECT sum(numbre_reserver) INTO placeReserve FROM Reservation WHERE id_repre = idRepre;
  raise notice 'Places reserves : % ', placeReserve;
  RETURN placeReserve;
END;
$$ LANGUAGE plpgsql;

------------------------
