#!/usr/bin/perl


package SPMR::DBI::MyDBISqlite;

use base qw(Exporter SPMR::DBI::MyDBI);
use vars qw/@EXPORT/;
@EXPORT = qw();

use SPMR::COMMON::MyCOMMON qw(DD l_debug $L_DEBUG is_exist_in_array);
$L_DEBUG = 1;

my %MyDBISqlite = (
    "logger.init.conf_file"   => "/data/scripts/log4perl.conf",
    "logger.output.default.soft_name"  => "MyDBI",
    "logger.output.default.init"   => 'INFO,  SCREEN',
    "logger.output.FILE.log_path" => "/tmp/MyDBI.log",
    "logger.output.FILE.msg_format" =>  '%T %I %s[%p] [%F]:%L(%S) %l> %M %N',
    "logger.output.SCREEN.msg_format" => '%T %I %s[%p] [%F]:%L(%S) %l> %M %N',
    "logger.output.SYSLOG.min_level"  => 'info',
    "logger.output.SYSLOG.facility"  => 'user',
    "logger.output.SYSLOG.msg_format" => '[%F]:%L(%S) %l> %M',
);

my $log = SPMR::LOG::Logforperl->new(%MyDBISqlite);

sub new {
    my $invocant  = shift;
    my ($dsn) = @_;
    my $self      = bless( {}, ref $invocant || $invocant );
    my %options = (
        "dsn"    =>    $dsn,
        );

    $self->init(%options);
    return $self;
}


sub connect_DB {
    my $self = shift @_;
    $log->debug("connect_DB ");
    $self->{dbh}
        = DBI->connect( $self->{options}->{dsn},
        { RaiseError => 1, AutoCommit => 0 } )
        or ( $log->fatal("Can't connect to DB") and die );
}

sub get_table_list {
    my $self = shift @_;
    my ($a_tbs_ref, $d_tbs_ref) = @_;
    $a_tbs_ref = $self->get_col_from_qurey("SELECT name FROM sqlite_master WHERE type='table' order by name") unless $a_tbs_ref;
    my @r_tbs;

    foreach(@$a_tbs_ref) {
        push(@r_tbs, $_)  unless ( is_exist_in_array($d_tbs_ref, $_) );
    }

    return \@r_tbs;

}

1;
