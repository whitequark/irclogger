alter table irclog add column opcode varchar(20);
update irclog set opcode='topic', nick=left(line, instr(line, ' ')) where nick is null and opcode is null and line like '% changed the topic of #%';
update irclog set opcode='join', nick=left(line, instr(line, ' ')) where nick is null and opcode is null and line like '% has joined #%';
update irclog set opcode='leave', nick=left(line, instr(line, ' ')) where nick is null and opcode is null and line like '% has left #%';
update irclog set opcode='kick', nick=left(line, instr(line, ' ')) where nick is null and opcode is null and line like '% was kicked from #%';
update irclog set opcode='nick', nick=left(line, instr(line, ' ')) where nick is null and opcode is null and line like '% is now known as %';
update irclog set opcode='quit', nick=left(line, instr(line, ' ')) where nick is null and opcode is null and line like '% has quit%';