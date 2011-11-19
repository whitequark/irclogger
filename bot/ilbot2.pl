#!/usr/bin/perl
use warnings;
use strict;
use Config::File;
use Bot::BasicBot;
use Carp qw(confess);

# this is a cleaner reimplementation of ilbot, with Bot::BasicBot which 
# in turn is based POE::* stuff
package IrcLogBot;
use IrcLog qw(get_dbh gmt_today);
use Data::Dumper;

{

    my $dbh = get_dbh();

    sub prepare {
        my $dbh = shift;
        return $dbh->prepare("INSERT INTO irclog (channel, nick, timestamp, line) VALUES(?, ?, ?, ?)");
    }
    my $q = prepare($dbh);
    sub dbwrite {
        my ($channel, $who, $line) = @_;
        # mncharity aka putter has an IRC client that prepends some lines with
        # a BOM. Remove that:
        $line =~ s/\A\x{ffef}//;

        if ($who =~ /_dnl$/) { return; }

        my @sql_args = ($channel, $who, time, $line);
        if ($dbh->ping){
            $q->execute(@sql_args);
        } else {
            $q = prepare(get_dbh());
            $q->execute(@sql_args);
        }
        return;
    }

    use base 'Bot::BasicBot';

    sub said {
        my $self = shift;
        my $e = shift;
        if($e->{body} !~ /\[off\]/) {
          dbwrite($e->{channel}, $e->{who}, $e->{body});
        }
        return undef;
    }

    sub emoted {
        my $self = shift;
        my $e = shift;
        dbwrite($e->{channel}, '* ' . $e->{who}, $e->{body});
        return undef;

    }

    sub chanjoin {
        my $self = shift;
        my $e = shift;
        dbwrite($e->{channel}, '',  $e->{who} . ' joined ' . $e->{channel});
        return undef;
    }

    sub chanpart {
        my $self = shift;
        my $e = shift;
        dbwrite($e->{channel}, '',  $e->{who} . ' left ' . $e->{channel});
        return undef;
    }

    sub topic {
        my $self = shift;
        my $e = shift;
        dbwrite($e->{channel}, "", 'Topic for ' . $e->{channel} . ' is now ' . $e->{topic});
        return undef;
    }

    sub nick_change {
        my $self = shift;
        print Dumper(\@_);
        # XXX TODO
        return undef;
    }

    sub kicked {
        my $self = shift;
        my $e = shift;
        dbwrite($e->{channel}, "", $e->{nick} . ' was kicked by ' . $e->{who} . ': ' . $e->{reason});
        return undef;
    }

    sub help {
        my $self = shift;
        return "This is a passive irc logging bot. Homepage: http://irclog.whitequark.org/";
    }
}


package main;
my $conf = Config::File::read_config_file(shift @ARGV || "bot.conf");
my $nick = shift @ARGV || $conf->{NICK} || "ilbot6";
my $server = $conf->{SERVER} || "irc.freenode.net";
my $port = $conf->{PORT} || 6667;
my $channels = [ split m/\s+/, $conf->{CHANNEL}];

# Autoflush output
select(STDOUT);
$| = 1;

print "$server:$port";

my $bot = IrcLogBot->new(
        server    => $server,
        port      => $port,
        channels  => $channels,
        nick      => $nick,
        alt_nicks => ["whitelogger_"],
        username  => "whitelogger",
        name      => "irc log bot, http://irclog.whitequark.org/",
        charset   => "utf-8", 
        );
$bot->run();

# vim: ts=4 sw=4 expandtab
