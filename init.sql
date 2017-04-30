/* création de la base de donnee */
CREATE DATABASE IF NOT EXISTS projet_theatre;;
\connect projet_theatre;;

/* création de la table */
CREATE TABLE IF NOT EXISTS Spectacle (
	IdSpectacle SERIAL PRIMARY KEY,
	Nom varchar(20) NOT NULL,
	Places integer NOT NULL
		CHECK (places >= 0),
	Type integer NOT NULL
		CHECK (Type IN (0,1)),/* 0: cree, 1:achete */
	TarifNormal numeric(6,2) NOT NULL
		CHECK (TarifNormal >= 0),
	TarifReduit numeric(6,2) NOT NULL
		CHECK (TarifNormal >= 0)
);

INSERT INTO Spectacle (Nom, Places, Type, TarifNormal, TarifReduit) VALUES
('Carmen', 85, 0, 204.45, 144.45);

----------------------------------------------------

CREATE TABLE IF NOT EXISTS Organisme (
        IdOrganisme integer PRIMARY KEY,
        Nom varchar(20) NOT NULL,
        Type varchar(20)
);

----------------------------------------------------

CREATE TABLE IF NOT EXISTS Subventions (
        IdSpectacle integer references Spectacle,
        IdOrganisme integer references Organisme, 
        Action varchar(20) default 'creation' 
        /* Trigger insert before selon type de spectacle de modifier action */
        	CHECK (Action IN ('creation','accueil')),
        Montant integer NOT NULL
        	CHECK (Montant > 0),
        Date_Subvenir date NOT NULL,
        PRIMARY key (IdSpectacle,IdOrganisme)
);

----------------------------------------------------

CREATE TABLE IF NOT EXISTS Cout_Spectacle (
        IdCout integer PRIMARY KEY,
        IdSpectacle integer NOT NULL references Spectacle, 
        /* Trigger insert before selon type de spectacle si il a type <achete>, on depense que une seule fois */
        Date_Depenser date NOT NULL,
        Montant integer NOT NULL
        	CHECK (Montant > 0)
);

----------------------------------------------------

CREATE TABLE IF NOT EXISTS Repre_Interne (
        IdRepresentation integer PRIMARY KEY,
        IdSpectacle integer NOT NULL references Spectacle,
        Date_Sortir date NOT NULL,
        Politique integer NOT NULL
        	CHECK (Politique >= 0)
);

----------------------------------------------------

/* 
    pour cle etranger on pense a utiliser 
    ON DELETE CASCADE 
    ON DELETE RESTRICT
*/