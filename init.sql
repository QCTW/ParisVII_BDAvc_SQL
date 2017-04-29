CREATE DATABASE projet_theatre;

\connect projet_theatre;

CREATE TABLE IF NOT EXISTS aujourdhui (id integer, time timestamp, PRIMARY KEY(id));

INSERT INTO aujourdhui VALUES (0, to_timestamp('13:30 14/04/2017', 'HH24:MI DD/MM/YYYY'));



