DROP TABLE IF EXISTS irclog;
CREATE TABLE irclog (
        id SERIAL,
        channel VARCHAR(30),
        nick VARCHAR(40),
        opcode VARCHAR(20),
        timestamp INT,
        line TEXT,
        oper_nick VARCHAR(40),
        payload TEXT,
        PRIMARY KEY(id)
);

CREATE INDEX irclog_timestamp_index ON irclog (timestamp);
CREATE INDEX irclog_channel_timestamp_index ON irclog (channel, timestamp);
CREATE INDEX irclog_channel_opcode_index ON irclog (channel, opcode);
CREATE INDEX irclog_channel_nick_index ON irclog (channel, nick);
CREATE INDEX irclog_fulltext_index ON irclog
  USING gin(to_tsvector('english', nick || ' ' || line));
