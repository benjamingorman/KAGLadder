CREATE DATABASE IF NOT EXISTS KAGELO;
USE KAGELO;

CREATE TABLE IF NOT EXISTS players (
    username    CHAR(20)    not null,
    nickname    CHAR(20)    default '', 
    clantag     CHAR(10)    default '',
    gender      TINYINT(1)  default 0,
    head        SMALLINT    default 255,
    coins       INT         default 0,
    UNIQUE(username)
);

CREATE TABLE IF NOT EXISTS match_history (
    id                    INT      not null AUTO_INCREMENT, 
    region                CHAR(3)  not null,
    player1               CHAR(20) not null,
    player2               CHAR(20) not null,
    kag_class             CHAR(7)  not null,
    match_time            CHAR(10) not null,
    player1_score         TINYINT  not null,
    player2_score         TINYINT  not null,
    player1_rating_change SMALLINT not null,
    player2_rating_change SMALLINT not null,
    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS player_rating (
    username    CHAR(20)    not null,
    region      CHAR(3)     not null,
    kag_class   CHAR(7)     not null,
    rating      SMALLINT    default 1000  not null,
    wins        SMALLINT    default 0     not null,
    losses      SMALLINT    default 0     not null,
    PRIMARY KEY (username, region, kag_class),
    FOREIGN KEY (username) REFERENCES players (username)
);
