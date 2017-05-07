/* création de la base de donnee */
----------------------------------------------------

CREATE DATABASE projet_theatre;
\connect projet_theatre;

/* création de la table */
----------------------------------------------------

CREATE TABLE IF NOT EXISTS Today (
	id serial, 
	time timestamp,
	PRIMARY KEY (id)
);

INSERT INTO Today ( id, time ) VALUES 
(0, to_timestamp('13:30 14/04/2017', 'HH24:MI DD/MM/YYYY'));

----------------------------------------------------

CREATE TABLE IF NOT EXISTS Spectacle (
	id_spectacle serial,
	nom varchar(256) NOT NULL,
	type integer NOT NULL CHECK (type IN (0,1)),/* 0: cree, 1:achete */
	places integer NOT NULL CHECK (places >= 0),
	tarif_normal numeric(6,2) NOT NULL CHECK (tarif_normal >= 0),
	tarif_reduit numeric(6,2) NOT NULL CHECK (tarif_reduit >= 0),
	PRIMARY KEY (id_spectacle)
);

INSERT INTO Spectacle (nom, type, places, tarif_normal, tarif_reduit) VALUES
('Carmen', 0, 85, 204.45, 144.45),
('La Dame Blanche', 0, 55, 60.05, 26.0),
('La Peur', 1, 35, 30.9, 18.30);

----------------------------------------------------

CREATE TABLE IF NOT EXISTS Organisme (
    id_organisme serial,
    nom varchar(256) NOT NULL,
    type varchar(256),
    PRIMARY KEY (id_organisme)
);

INSERT INTO Organisme (nom, type) VALUES
('Mairie de Paris', 'Municipalite'),
('Ministere de la culture francais', 'Ministere de la culture'),
('Yizhe FAN', 'Mecenat prive');

----------------------------------------------------

CREATE TABLE IF NOT EXISTS Subvention (
    id_spectacle integer references Spectacle,
    id_organisme integer references Organisme, 
    action varchar(256)
    /* Trigger insert before selon type de spectacle de modifier action */
    	CHECK (action IN ('creation','accueil')),
    montant numeric(8,2) NOT NULL CHECK (montant > 0),
    date_subvenir date NOT NULL,
    PRIMARY key (id_spectacle,id_organisme)
);

INSERT INTO Subvention (id_spectacle, id_organisme, action, montant, date_subvenir) VALUES
(1, 1, 'creation', 220.45, '2014-10-11'),
(1, 2, 'creation', 120.01, '2016-01-01'),
(2, 2, 'creation', 80, '2016-06-01'),
(3, 3, 'accueil', 100, '2017-01-01');

----------------------------------------------------

CREATE TABLE IF NOT EXISTS Cout_Spectacle (
    id_cout serial,
    id_spectacle integer NOT NULL references Spectacle, 
    /* Trigger insert before selon type de spectacle si il a type <achete>, on depense que une seule fois */
    date_depenser date NOT NULL,
    montant numeric(8,2) NOT NULL CHECK (montant > 0),
    PRIMARY KEY (id_cout)
);

INSERT INTO Cout_Spectacle (id_spectacle, date_depenser, montant) VALUES
(1, '2015-01-07', 500.01),
(2, '2015-10-10', 1000.10),
(2, '2016-05-15', 1500.09),
(3, '2017-05-15', 3000.10);

----------------------------------------------------

CREATE TABLE IF NOT EXISTS Compagnie_Accueil (
    id_compagnie_accueil serial,
    nom varchar(256) NOT NULL,
    ville varchar(256) NOT NULL,
    departement varchar(256) NOT NULL,
    pays varchar(256) NOT NULL,
    PRIMARY KEY (id_compagnie_accueil)
);

INSERT INTO Compagnie_Accueil (nom, ville, departement, pays) VALUES
('La Mer', 'Nice', 'Alpes-Maritimes', 'France');

----------------------------------------------------

CREATE TABLE IF NOT EXISTS Repre_Externe (
    id_repre_ext serial,
    id_spectacle integer NOT NULL references Spectacle,
    id_compagnie_accueil integer NOT NULL references Compagnie_Accueil,
    /* Trigger pour tester que ce spectacle a pas de type de achete */
    date_transac date NOT NULL,
    prix numeric (8,2) NOT NULL CHECK (prix > 0),
    /* Trigger pour donner une promotion si il en achete plusieurs dans un coup  */
    numbre_achete integer NOT NULL CHECK (numbre_achete > 0), 
    prix_vendu numeric (8,2) CHECK (prix > 0),
    /* final prix */
    PRIMARY KEY (id_repre_ext)
);

INSERT INTO Repre_Externe (id_spectacle, id_compagnie_accueil, date_transac, prix, numbre_achete, prix_vendu) VALUES
(1, 1, '2015-01-05', 700.34, 1, 700.34);

----------------------------------------------------

CREATE TABLE IF NOT EXISTS Repre_Interne (
    id_repre serial,
    id_spectacle integer NOT NULL references Spectacle,
    date_prevendre date NOT NULL,
    date_sortir date NOT NULL,
    politique integer NOT NULL CHECK (politique >= 0),
    CHECK (date_sortir > date_prevendre),
    PRIMARY KEY (id_repre)
);

INSERT INTO Repre_Interne (id_spectacle, date_prevendre, date_sortir, politique) VALUES
(1, '2015-12-10','2015-12-25', 1),
(1, '2016-12-10','2016-12-30', 2),
(3, '2017-02-09','2017-02-14', 3);

/*
    INSERT INTO Repre_Interne (id_spectacle, date_prevendre, date_sortir, politique) VALUES
    (2, '2016-02-20','2016-02-14', 2);
*/

----------------------------------------------------

CREATE TABLE IF NOT EXISTS Reservation (
    id_reserve serial PRIMARY KEY,
    id_repre integer NOT NULL references Repre_Interne,
    date_reserver date NOT NULL,
    date_regler date NOT NULL,
    CHECK (date_reserver < date_regler),
    /* 
        triggers check date_reserver > date_prevendre
        triggers check date_regler < date_sortir
    */
    places_reserve integer NOT NULL CHECK (places_reserve > 0)
    /* triggers there is enough places */
    --inner join select for getting information of spectacle.
);

INSERT INTO Reservation (id_repre, date_reserver, date_regler, places_reserve) VALUES
(1, '2015-12-10', '2015-12-20', 10);

----------------------------------------------------

CREATE TABLE IF NOT EXISTS Billet (
	id_repre integer references Repre_Interne,
	tarif_type integer CHECK (tarif_type IN (0,1)), /* 0=Normal, 1=Reduit*/
    par_politique integer CHECK (par_politique >=0),
    prix_effectif numeric (8,2),
    numbre integer NOT NULL CHECK (numbre >=0),
	PRIMARY KEY (id_repre, tarif_type, prix_effectif, par_politique)
);

INSERT INTO Billet (id_repre, tarif_type, par_politique, prix_effectif, numbre) VALUES
(1, 0, 0, 204.45, 5);

----------------------------------------------------

CREATE TABLE IF NOT EXISTS Historique (
	id_historique serial PRIMARY KEY,
	id_spectacle integer NOT NULL references Spectacle,
	type integer NOT NULL CHECK (type IN (0,1)), /* 0=Dépense, 1=Recette*/
	time timestamp NOT NULL,
	montant numeric (8,2) NOT NULL,
	note text
);

INSERT INTO Historique (id_spectacle, type, time, montant, note) VALUES
(1, 1, to_timestamp('14:03 13/04/2017', 'HH24:MI DD/MM/YYYY'), 10, 'Vendu par internet'),
(1, 0, to_timestamp('07:30 14/02/2017', 'HH24:MI DD/MM/YYYY'), 500, 'Initier une spectacle'),
(1, 1, (SELECT time FROM Today WHERE id=0), -2, 'Modifie par admin')

/* 
    pour cle etranger on pense a utiliser 
    ON DELETE CASCADE 
    ON DELETE RESTRICT
*/
