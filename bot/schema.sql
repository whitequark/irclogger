DROP TABLE IF EXISTS `irclog`;
CREATE TABLE `irclog` (
        id INT auto_increment, 
        channel VARCHAR(30),
        nick VARCHAR(40),
        timestamp INT,
        line TEXT,
        PRIMARY KEY(`id`)
        ) CHARSET=utf8;

CREATE INDEX `irclog_timestamp_index` ON `irclog` (timestamp);

-- vim: sw=4 ts=4 expandtab
