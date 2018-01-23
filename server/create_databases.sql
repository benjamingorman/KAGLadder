CREATE DATABASE IF NOT EXISTS KAGELO;
USE KAGELO;

create table players (
    username    tinytext    default ''    not null,
    clantag     tinytext    default '',
    nickname    tinytext    default '', 
    gender      tinyint(1)  default 0,
    head        smallint    default 0,
);
