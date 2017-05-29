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
(0, to_timestamp('11:30 29/04/2017', 'HH24:MI DD/MM/YYYY'));

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

----------------------------------------------------

CREATE TABLE IF NOT EXISTS Organisme (
    id_organisme serial,
    nom varchar(256) NOT NULL,
    type varchar(256),
    PRIMARY KEY (id_organisme)
);

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

----------------------------------------------------

CREATE TABLE IF NOT EXISTS Cout_Spectacle (
    id_cout serial,
    id_spectacle integer NOT NULL references Spectacle, 
    /* Trigger insert before selon type de spectacle si il a type <achete>, on depense que une seule fois */
    date_depenser date NOT NULL,
    montant numeric(8,2) NOT NULL CHECK (montant > 0),
    PRIMARY KEY (id_cout)
);

----------------------------------------------------

CREATE TABLE IF NOT EXISTS Compagnie_Accueil (
    id_compagnie_accueil serial,
    nom varchar(256) NOT NULL,
    ville varchar(256) NOT NULL,
    departement varchar(256) NOT NULL,
    pays varchar(256) NOT NULL,
    PRIMARY KEY (id_compagnie_accueil)
);

----------------------------------------------------

CREATE TABLE IF NOT EXISTS Repre_Externe (
    id_repre_ext serial,
    id_spectacle integer NOT NULL references Spectacle,
    id_compagnie_accueil integer NOT NULL references Compagnie_Accueil,
    /* Trigger pour tester que ce spectacle a pas de type de achete */
    date_transac date NOT NULL,
    prix numeric (8,2) NOT NULL CHECK (prix > 0),
    /* Trigger pour donner une promotion si il en achete plusieurs dans un coup  */
    nombre_achete integer NOT NULL CHECK (nombre_achete > 0), 
    prix_vendu numeric (8,2) CHECK (prix > 0),
    /* final prix */
    PRIMARY KEY (id_repre_ext)
);

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

----------------------------------------------------

CREATE TABLE IF NOT EXISTS Reservation (
    id_reserve serial PRIMARY KEY,
    id_repre integer NOT NULL references Repre_Interne,
    date_reserver timestamp NOT NULL,
    date_delai timestamp NOT NULL,
    /* 
        triggers check date_reserver > date_prevendre
        triggers check date_regler < date_sortir
    */
    nombre_reserver integer NOT NULL CHECK (nombre_reserver > 0),
    CHECK (date_reserver < date_delai)
    /* triggers there is enough places */
);

----------------------------------------------------

CREATE TABLE IF NOT EXISTS Billet (
    id_repre integer references Repre_Interne,
    tarif_type integer CHECK (tarif_type IN (0,1)), /* 0=Normal, 1=Reduit*/
    prix_effectif numeric (8,2),
    nombre integer NOT NULL CHECK (nombre >=0),
    PRIMARY KEY (id_repre, tarif_type, prix_effectif)
);

----------------------------------------------------

CREATE TABLE IF NOT EXISTS Historique (
	id_historique serial PRIMARY KEY,
	id_spectacle integer NOT NULL references Spectacle,
	type integer NOT NULL CHECK (type IN (0,1)), /* 0=Dépense, 1=Recette*/
	time timestamp NOT NULL,
	montant numeric (8,2) NOT NULL,
	note text
);
