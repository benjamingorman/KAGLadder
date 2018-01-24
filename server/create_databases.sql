CREATE DATABASE IF NOT EXISTS KAGELO;
USE KAGELO;

CREATE TABLE IF NOT EXISTS players (
    username    TINYTEXT    Default ''    not null,
    PRIMARY KEY (username)
);

ALTER TABLE players 
    ADD COLUMN IF NOT EXISTS clantag     TINYTEXT    Default '',
    ADD COLUMN IF NOT EXISTS nickname    TINYTEXT    Default '', 
    ADD COLUMN IF NOT EXISTS gender      TINYINT(1)  default 0,
    ADD COLUMN IF NOT EXISTS head        SMALLINT    Default 0
    ;

CREATE TABLE IF NOT EXISTS match_history (
    id    int   not null AUTO_INCREMENT,
    PRIMARY KEY (id)
);

ALTER TABLE match_history
    ADD COLUMN IF NOT EXISTS region    TINYTEXT    default '' not null,
    ADD COLUMN IF NOT EXISTS player1   TINYTEXT    default '' not null,
    ADD COLUMN IF NOT EXISTS player2   TINYTEXT    default '' not null,
    ADD COLUMN IF NOT EXISTS kag_class  TINYTEXT    default '' not null,
    ADD COLUMN IF NOT EXISTS match_time      TIMESTAMP   default '2000-01-01 12:00:00' not null,
    ADD COLUMN IF NOT EXISTS player1_score TINYINT default 0 not null,
    ADD COLUMN IF NOT EXISTS player2_score TINYINT default 0 not null,
    ADD COLUMN IF NOT EXISTS duel_to_score TINYINT default 0 not null
    ;

CREATE TABLE IF NOT EXISTS player_rating (
    username    TINYTEXT    default ''    not null
);

ALTER TABLE player_rating
    ADD COLUMN IF NOT EXISTS region      TINYTEXT    default ''    not null,
    ADD COLUMN IF NOT EXISTS kag_class   TINYTEXT    default ''    not null,
    ADD COLUMN IF NOT EXISTS rating      SMALLINT    default 1000  not null
    ;
