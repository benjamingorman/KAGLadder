CREATE DATABASE IF NOT EXISTS KAGELO;
USE KAGELO;

CREATE TABLE IF NOT EXISTS players (
    username    CHAR(64)    default ''    not null,
    nickname    CHAR(64)    default '', 
    clantag     CHAR(16)    default '',
    gender      TINYINT(1)  default 0,
    head        SMALLINT    default 0,
    UNIQUE(username)
);

CREATE TABLE IF NOT EXISTS match_history (
    region         CHAR(3)     default '' not null,
    player1        CHAR(64)    default '' not null,
    player2        CHAR(64)    default '' not null,
    kag_class      CHAR(7)     default '' not null,
    match_time     CHAR(10)    default '' not null,
    player1_score  TINYINT     default 0  not null,
    player2_score  TINYINT     default 0  not null,
    duel_to_score  TINYINT     default 0  not null,
    PRIMARY KEY (region, match_time)
);

CREATE TABLE IF NOT EXISTS player_rating (
    username    CHAR(64)    default ''    not null,
    region      CHAR(3)     default ''    not null,
    kag_class   CHAR(7)     default ''    not null,
    rating      SMALLINT    default 1000  not null,
    wins        SMALLINT    default 0     not null,
    losses      SMALLINT    default 0     not null,
    PRIMARY KEY (username, region, kag_class)
);
