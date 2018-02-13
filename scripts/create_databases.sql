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

CREATE TABLE IF NOT EXISTS round_stats (
    match_id             INT      not null,
    round_index          TINYINT  not null,
    winner               CHAR(20) not null,
    duration             SMALLINT not null,
    events               VARCHAR(8096),
    PRIMARY KEY (match_id, round_index),
    FOREIGN KEY (match_id) REFERENCES match_history (id)
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

CREATE TABLE IF NOT EXISTS clan (
    clantag     CHAR(20)    not null,
    badgeURL    CHAR(255),
    forumURL    CHAR(255),
    leader      CHAR(20),   
    PRIMARY KEY (clantag)
);
