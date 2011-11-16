DROP TABLE IF EXISTS `irclog`;
CREATE TABLE `irclog` (
        id INT auto_increment, 
        channel VARCHAR(30),
        day CHAR(10),
        nick VARCHAR(40),
        timestamp INT,
        line TEXT,
        spam BOOL default false,
        PRIMARY KEY(`id`)
        ) CHARSET=utf8;

-- vim: sw=4 ts=4 expandtab
