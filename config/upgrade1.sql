ALTER TABLE irclog ADD COLUMN opcode VARCHAR(20);
CREATE INDEX `irclog_channel_opcode_index` ON `irclog` (channel, opcode);

UPDATE irclog SET opcode='topic', nick=left(line, instr(line, ' ')) WHERE nick IS NULL AND opcode IS NULL AND line LIKE '% changed the topic of #%';
UPDATE irclog SET opcode='join', nick=left(line, instr(line, ' ')) WHERE nick IS NULL AND opcode IS NULL AND line LIKE '% has joined #%';
UPDATE irclog SET opcode='leave', nick=left(line, instr(line, ' ')) WHERE nick IS NULL AND opcode IS NULL AND line LIKE '% has left #%';
UPDATE irclog SET opcode='kick', nick=left(line, instr(line, ' ')) WHERE nick IS NULL AND opcode IS NULL AND line LIKE '% was kicked from #%';
UPDATE irclog SET opcode='nick', nick=left(line, instr(line, ' ')) WHERE nick IS NULL AND opcode IS NULL AND line LIKE '% is now known as %';
UPDATE irclog SET opcode='quit', nick=left(line, instr(line, ' ')) WHERE nick IS NULL AND opcode IS NULL AND line LIKE '% has quit%';
UPDATE irclog SET nick=TRIM(nick) WHERE nick IS NOT NULL;