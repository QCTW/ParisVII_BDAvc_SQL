CREATE DATABASE projet_theatre;
\connect projet_theatre;

----------------------------------------------------
CREATE TABLE IF NOT EXISTS Aujourdhui (id integer, time timestamp, PRIMARY KEY(id));
INSERT INTO Aujourdhui VALUES (0, to_timestamp('13:30 14/04/2017', 'HH24:MI DD/MM/YYYY'));

----------------------------------------------------
CREATE TABLE Spectacle (
	IdSpectacle integer PRIMARY KEY,
	Nom varchar(20) NOT NULL,
	Places integer NOT NULL
		CHECK (places >= 0),
	Type integer NOT NULL
		CHECK (Type IN (0,1)),/* 0: cree, 1:achete */
	TarifNormal numeric(4,2) NOT NULL
		CHECK (TarifNormal >= 0),
	TarifReduit numeric(4,2) NOT NULL
		CHECK (TarifNormal >= 0)
);

----------------------------------------------------
CREATE TABLE Organisme (
        IdOrganisme integer PRIMARY KEY,
        Nom varchar(20) NOT NULL,
        Type varchar(20)
);

----------------------------------------------------
CREATE TABLE Subventions (
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

CREATE TABLE Cout_Spectacle (
        IdCout integer PRIMARY KEY,
        IdSpectacle integer NOT NULL references Spectacle, 
        /* Trigger insert before selon type de spectacle si il a type <achete>, on depense que une seule fois */
        Date_Depenser date NOT NULL,
        Montant integer NOT NULL
        	CHECK (Montant > 0)
);

----------------------------------------------------

CREATE TABLE Repre_Interne (
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
