/* création de la base de donnee */
CREATE DATABASE projet_theatre;
\connect projet_theatre;

/* création de la table */
----------------------------------------------------

CREATE TABLE IF NOT EXISTS Today (
	id serial PRIMARY KEY, 
	time timestamp
);

INSERT INTO Today VALUES 
(0, to_timestamp('13:30 14/04/2017', 'HH24:MI DD/MM/YYYY'));

----------------------------------------------------

CREATE TABLE IF NOT EXISTS Spectacle (
	IdSpectacle serial,
	Nom varchar(256) NOT NULL,
	Type integer NOT NULL
		CHECK (Type IN (0,1)),/* 0: cree, 1:achete */
	Places integer NOT NULL
		CHECK (places >= 0),
	TarifNormal numeric(6,2) NOT NULL
		CHECK (TarifNormal >= 0),
	TarifReduit numeric(6,2) NOT NULL
		CHECK (TarifNormal >= 0),
	PRIMARY KEY (IdSpectacle)
);

INSERT INTO Spectacle (Nom, Type, Places, TarifNormal, TarifReduit) VALUES
('Carmen', 0, 85, 204.45, 144.45),
('La Dame Blanche', 0, 55, 60.05, 26.0),
('La Peur', 1, 35, 30.9, 18.30);

----------------------------------------------------

CREATE TABLE IF NOT EXISTS Organisme (
        IdOrganisme serial PRIMARY KEY,
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
        DateSubvenir date NOT NULL,
        PRIMARY key (IdSpectacle,IdOrganisme)
);

----------------------------------------------------

CREATE TABLE IF NOT EXISTS Cout_Spectacle (
        IdCout serial,
        IdSpectacle integer NOT NULL references Spectacle, 
        /* Trigger insert before selon type de spectacle si il a type <achete>, on depense que une seule fois */
        DateDepenser date NOT NULL,
        Montant numeric(8,2) NOT NULL
        	CHECK (Montant > 0),
	PRIMARY KEY (IdCout)
);

INSERT INTO Cout_Spectacle (IdSpectacle, DateDepenser, Montant) VALUES
(1, '2014-01-07', 30.01),
(1, '2014-01-10', 10.50),
(2, '2015-10-10', 100.10),
(2, '2015-10-30', 25.09),
(2, '2015-12-10', 1.98),
(2, '2016-01-10', 45),
(3, '2016-12-23', 1000.10);

----------------------------------------------------

CREATE TABLE IF NOT EXISTS Repre_Interne (
        IdRepresentation serial PRIMARY KEY,
        IdSpectacle integer NOT NULL references Spectacle,
        DateSortir date NOT NULL,
        Politique integer NOT NULL CHECK (Politique >= 0) /* ??? */
);

INSERT INTO Repre_Interne VALUES
(1, 1, '2017-05-01', 1);

----------------------------------------------------

CREATE TABLE IF NOT EXISTS Billet (
	IdRepresentation serial references Repre_Interne,
	NomSpectateur varchar(256) NOT NULL,
	DateVendu timestamp NOT NULL,
        TarifType integer NOT NULL,
	Status integer NOT NULL,
	PrixEffectif numeric (8,2) NOT NULL,
	PRIMARY KEY (IdRepresentation, NomSpectateur, DateVendu)
);

INSERT INTO Billet VALUES
(1, 'Quincy Hsieh', (SELECT time FROM Today WHERE id=0), 1, 1, 100);

/* 
    pour cle etranger on pense a utiliser 
    ON DELETE CASCADE 
    ON DELETE RESTRICT
*/
