package IrcLog;
use warnings;
use strict;
use DBI;

#use Smart::Comments;
use Config::File;
use Carp;
use utf8;

require Exporter;

use base 'Exporter';
our @EXPORT_OK = qw(
        get_dbh
        gmt_today
        );

# get a database handle.
# you will have to modify that routine to fit your needs
sub get_dbh {
    my $conf = Config::File::read_config_file("database.conf");
    my $dbs = $conf->{DSN} || "mysql";
    my $db_name = $conf->{DATABASE} || "irclog";
    my $host = $conf->{HOST} || "localhost";
    my $user = $conf->{USER} || "irclog";
    my $passwd = $conf->{PASSWORD} || "";

    my $db_dsn = "DBI:$dbs:database=$db_name;host=$host";
    my $dbh = DBI->connect($db_dsn, $user, $passwd,
            {RaiseError=>1, AutoCommit => 1});
    return $dbh;
}

# returns current date in GMT in the form YYYY-MM-DD
sub gmt_today {
    my @d = gmtime(time);
    return sprintf("%04d-%02d-%02d", $d[5]+1900, $d[4] + 1, $d[3]);
}


=head1 NAME

IrcLog - common subroutines for ilbot and the corresponding CGI scripts

=head1 SYNOPSIS

there is no synopsis, since the module has no unified API, but is a loose 
collection of subs that are usefull for the irc log bot and the 
corresponding CGI scripts.

=head1 METHODS

* get_dbh

returns a DBI handle to a database. To achieve that, it reads the file 
C<database.conf>.

* gmt_today

returns the current date in the format YYYY-MM-DD, and uses UTC (GMT) to 
dermine the date.

=cut

# vim: ts=4 sw=4 expandtab
1;
