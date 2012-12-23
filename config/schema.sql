DROP TABLE IF EXISTS `irclog`;
CREATE TABLE `irclog` (
        id INT auto_increment,
        channel VARCHAR(30),
        nick VARCHAR(40),
        opcode VARCHAR(20),
        timestamp INT,
        line TEXT,
        PRIMARY KEY(`id`)
) CHARSET=utf8 ENGINE=MyISAM;

CREATE INDEX `irclog_channel_timestamp_index` ON `irclog` (channel, timestamp);
CREATE FULLTEXT INDEX `irclog_fulltext_index` ON `irclog` (nick, line);
