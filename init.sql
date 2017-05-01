/* création de la base de donnee */
CREATE DATABASE projet_theatre;
\connect projet_theatre;

/* création de la table */
----------------------------------------------------

CREATE TABLE IF NOT EXISTS Today (
	id serial, 
	time timestamp,
    PRIMARY KEY (id)
);

INSERT INTO Today ( time ) VALUES 
(to_timestamp('13:30 14/04/2017', 'HH24:MI DD/MM/YYYY'));

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
        IdOrganisme serial,
        Nom varchar(256) NOT NULL,
        Type varchar(256),
        PRIMARY KEY (IdOrganisme)
);

INSERT INTO Organisme (Nom, Type) VALUES
('Mairie de Paris', 'Municipalite'),
('Ministere de la culture francais', 'Ministere de la culture'),
('Yizhe FAN', 'Mecenat prive');

----------------------------------------------------

CREATE TABLE IF NOT EXISTS Subventions (
        IdSpectacle integer references Spectacle,
        IdOrganisme integer references Organisme, 
        Action varchar(256) default 'creation' 
        /* Trigger insert before selon type de spectacle de modifier action */
        	CHECK (Action IN ('creation','accueil')),
        Montant numeric(8,2) NOT NULL
        	CHECK (Montant > 0),
        Date_Subvenir date NOT NULL,
        PRIMARY key (IdSpectacle,IdOrganisme)
);

INSERT INTO Subventions (IdSpectacle, IdOrganisme, Action, Montant, Date_Subvenir) VALUES
(1, 1, 'creation', 220.45, '2014-10-11'),
(1, 2, 'creation', 120.01, '2016-01-01'),
(2, 2, 'creation', 80, '2016-06-01'),
(3, 3, 'accueil', 100, '2017-01-01');

----------------------------------------------------

CREATE TABLE IF NOT EXISTS Cout_Spectacle (
        IdCout serial,
        IdSpectacle integer NOT NULL references Spectacle, 
        /* Trigger insert before selon type de spectacle si il a type <achete>, on depense que une seule fois */
        Date_Depenser date NOT NULL,
        Montant numeric(8,2) NOT NULL CHECK (Montant > 0),
	PRIMARY KEY (IdCout)
);

INSERT INTO Cout_Spectacle (IdSpectacle, Date_Depenser, Montant) VALUES
(1, '2014-01-07', 30.01),
(1, '2014-01-10', 10.50),
(2, '2015-10-10', 100.10),
(2, '2015-10-30', 25.09),
(2, '2015-12-10', 1.98),
(2, '2016-01-10', 45),
(3, '2016-12-23', 1000.10);

----------------------------------------------------

CREATE TABLE IF NOT EXISTS Repre_Interne (
        IdRepresentation serial,
        IdSpectacle integer NOT NULL references Spectacle,
        Date_Sortir date NOT NULL,
        Politique integer NOT NULL 
            CHECK (Politique >= 0), /* ??? */
        PRIMARY KEY (IdRepresentation)
);

INSERT INTO Repre_Interne (IdSpectacle, Date_Sortir, Politique) VALUES
(1, '2014-12-25', 1),
(1, '2015-12-30', 2),
(2, '2016-01-01', 1),
(2, '2016-02-14', 2),
(3, '2017-02-14', 3);


----------------------------------------------------

CREATE TABLE IF NOT EXISTS Billet (
	IdRepresentation integer references Repre_Interne CHECK (IdRepresentation > 0),
	NomSpectateur varchar(256),
	Date_Vendu timestamp NOT NULL,
	TarifType integer NOT NULL,
	Status integer NOT NULL,
	PrixEffectif numeric (8,2) NOT NULL,
	PRIMARY KEY (IdRepresentation, NomSpectateur, Date_Vendu)
);

INSERT INTO Billet ( IdRepresentation, NomSpectateur, Date_Vendu, TarifType, Status, PrixEffectif) VALUES
(1, 'Quincy Hsieh', (SELECT time FROM Today WHERE id = 1), 1, 1, 100);

----------------------------------------------------

CREATE TABLE IF NOT EXISTS Historique (
	IdHistorique serial PRIMARY KEY,
	Type integer NOT NULL, /* 0=Dépense, 1=Recette*/
	Time timestamp NOT NULL,
	Montant numeric (8,2) NOT NULL,
	Note text
);

/* 
    pour cle etranger on pense a utiliser 
    ON DELETE CASCADE 
    ON DELETE RESTRICT
*/
