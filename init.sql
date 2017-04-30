/* création de la base de donnee */
CREATE DATABASE projet_theatre;
\connect projet_theatre;

/* création de la table */
----------------------------------------------------

CREATE TABLE IF NOT EXISTS Aujourdhui (
	id integer, 
	time timestamp, 
	PRIMARY KEY(id)
);

INSERT INTO Aujourdhui (id, time) VALUES 
(0, to_timestamp('13:30 14/04/2017', 'HH24:MI DD/MM/YYYY')),
(1, '2017-04-30 13:30');

----------------------------------------------------

CREATE TABLE IF NOT EXISTS Spectacle (
	IdSpectacle integer PRIMARY KEY,
	Nom varchar(20) NOT NULL,
	Type integer NOT NULL
		CHECK (Type IN (0,1)),/* 0: cree, 1:achete */
	Places integer NOT NULL
		CHECK (places >= 0),
	TarifNormal numeric(6,2) NOT NULL
		CHECK (TarifNormal >= 0),
	TarifReduit numeric(6,2) NOT NULL
		CHECK (TarifNormal >= 0)
);

INSERT INTO Spectacle (IdSpectacle, Nom, Type, Places, TarifNormal, TarifReduit) VALUES
(0, 'Carmen', 0, 85, 204.45, 144.45),
(1, 'La Dame Blanche', 0, 55, 60.05, 26.0),
(2, 'La Peur', 1, 35, 30.9, 18.30);

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
        Montant numeric(8,2) NOT NULL
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
        Montant numeric(8,2) NOT NULL
        	CHECK (Montant > 0)
);

INSERT INTO Cout_Spectacle (IdCout, IdSpectacle, Date_Depenser, Montant) VALUES
(0, 0, '2014-01-07', 30.01),
(1, 0, '2014-01-10', 10.50),
(2, 1, '2015-10-10', 100.10),
(3, 1, '2015-10-30', 25.09),
(4, 1, '2015-12-10', 1.98),
(5, 1, '2016-01-10', 45),
(6, 2, '2016-12-23', 1000.10);

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
    question serial
*/
