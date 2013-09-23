#!/usr/bin/perl
use strict;
use warnings;


package SPMR::DBI::MyDBI;
use DBI;
use SPMR::LOG::Logforperl;
use SPMR::COMMON::MyCOMMON qw(is_exist_in_array);

my %MyDBI = (
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

my $log = SPMR::LOG::Logforperl->new(%MyDBI);


sub new {
    my $invocant  = shift;
    my ($dsn,$mysql_username,$mysql_password) = @_;
    my $self      = bless( {}, ref $invocant || $invocant );
    my %options = (
        "dsn"    =>    $dsn,
        "mysql_username" =>    $mysql_username,
        "mysql_password" =>    $mysql_password,
        );

    $self->init(%options);
    return $self;
}

sub init {

    my $self = shift;
    my (%options) = @_;
    $self->{options} = \%options;
    


}

sub name {
    my $self = shift @_;
    my $name;
    if ( @_ >= 2 ) {
        my $value;
        ( $name, $value ) = @_;
        $self->{$name} = $value;
    }
    else {
        $name = shift @_;
    }

    return $self->{$name};
}

  

sub connect_DB {
    my $self = shift @_;
    $log->debug("connect_DB ");
    $self->{dbh}
        = DBI->connect( $self->{options}->{dsn}, $self->{options}->{mysql_username}, $self->{options}->{mysql_password },
        { RaiseError => 1, AutoCommit => 0 } )
        or ( $log->fatal("Can't connect to DB") and die );
}

sub disconnect_DB {
    my $self = shift @_;
    $log->debug("disconnect_DB ");
    $self->{dbh}->disconnect;

}

sub get_array_from_query {
    my $self = shift @_;
    my $sql  = shift @_;
    my ( $rc, $sth);
    $log->debug("get_array_from_query");
    $log->debug("\$sql = $sql ");
    $sth = $self->{dbh}->prepare($sql)
        or ( $log->fatal("Can't prepare statement: $DBI::errstr") and die );
    $rc = $sth->execute
        or ( $log->fatal("Can't execute statement: $DBI::errstr") and die );

    my $tbl_ary_ref = $sth->fetchall_arrayref( {} );
    if ( !$sth->errstr ) {
        return $tbl_ary_ref;
    }
    else {
        return -1;
    }

}

sub get_hash_from_query {



}


sub do_basic_query {
    my $self = shift @_;
    my ($sql) = @_;
    $log->debug("do_basic_query ");
    $log->debug("\$sql = $sql ");
    my $rrr = $self->{dbh}->do($sql);
    print ("$rrr") if ($rrr);

}


sub get_db_list {
    my $self = shift @_;
    my ($a_dbs_ref, $d_dbs_ref) = @_;
    $a_dbs_ref = $self->get_col_from_qurey('show databases') unless $a_dbs_ref;
    my @r_dbs;

    foreach(@$a_dbs_ref) {
        push(@r_dbs, $_)  unless ( is_exist_in_array($d_dbs_ref, $_) );
    }

    return \@r_dbs;

}


sub get_table_info {
    my $self = shift @_;
    my($table_name, $info_type) = @_;
    my $sth;
#    $log->debug("get_table_info  $table_name  $info_type ");
#    #$sth =  $self->{dbh}->table_info('', 'test', '%', 'TABLE');
#    $sth = $self->{dbh}->column_info('test', 'test', 'mailbox', '%');
#    #my $dbs_version = $self->{dbh}->get_info(18);
#    #dump($sth);
#
    my $table_info_ref;
#    $table_info_ref = $sth->fetchall_arrayref;
#    $sth->finish();
#    #$table_info_ref = $sth->fetchall_hashref('TABLE');
     
    $sth = $self->{dbh}->prepare ("SELECT * FROM $table_name  LIMIT 0 , 1");
    $sth->execute(); 

     my @filed_info  = map { {'filed_name' => $sth->{NAME}->[$_], 'filed_type' => $sth->{TYPE}->[$_] } } 0 .. ($sth->{NUM_OF_FIELDS} - 1);


     $sth->finish(); 
    return \@filed_info;



}



sub get_table_from_query {
    my $self = shift @_;
    my ($action, $sql)  =  @_;
    my ( $rc, $sth);
    $log->debug("get_oneresult_from_query ");

    $log->debug("\$sql = $sql ");
    $sth = $self->{dbh}->prepare($sql)
        or ( $log->info("Can't prepare statement: $DBI::errstr") and die );

    $rc = $sth->execute
        or ( $log->info("Can't execute statement: $DBI::errstr") and die );

    my $tbl_ref;
    if ($action eq 'ary_ref'){
        $tbl_ref = $sth->fetchrow_arrayref;
    }elsif( $action eq 'hash_ref'){
        $tbl_ref = $sth->fetchrow_hashref;
    }
    
    if ( !$sth->errstr ) {
        return $tbl_ref;
    }
    else {
        return -1;
    }
}


sub get_col_from_qurey {
    my $self = shift @_;
    my ($sql) =  @_;
    $log->debug("get_col_from_qurey ");

    $log->debug("\$sql = $sql ");
    my $ary_ref  = $self->{dbh}->selectcol_arrayref($sql);
    return $ary_ref;

}

sub get_row_from_qurey {

    my $self = shift @_;
    my ($result_type, $sql) =  @_;

    $log->debug("get_row_from_qurey");
    $log->debug("\$sql = $sql ");
    if ($result_type eq 'row_ary') {
        my @row_ary  = $self->{dbh}->selectrow_array($sql);
        return @row_ary;
    }elsif($result_type eq 'ary_ref'){
        my $ary_ref  = $self->{dbh}->selectrow_arrayref($sql);
        
        return $ary_ref;
    }elsif($result_type eq 'hash_ref'){
        my $hash_ref = $self->{dbh}->selectrow_hashref($sql);
        return $hash_ref;
    }
    
    
}




sub exec_query {

    my $self = shift @_;
    my $sql =  shift @_;
    my ( $rv, $sth);
    $sth = $self->{dbh}->prepare(qq{
    $sql
    }) or $log->alert("$self->{dbh}->errstr");
    $rv = $sth->execute();

    $self->{dbh}->commit or $log->alert("$self->{dbh}->errstr");
    if ( !$sth->errstr ) {
        return $rv;
    }
    else {
        return -1;
    }
}


sub update_data {

    my $self = shift @_;
    my ( $rv, $sth);
    $log->debug("update_data");
    my ($table_name, $sql_clause_ref, $sql_where_ref) = @_;

    my $sql_where;
    my @temp_sql_where;
    while ( my ($sql_where_var, $sql_where_value) = each %$sql_where_ref ) {
         push @temp_sql_where, "$sql_where_var = \'$sql_where_value\'";
    }
    $sql_where = join(" AND ", @temp_sql_where);
    
    $log->debug("\$sql_where = $sql_where");

    my $sql_clause;
    my @temp_sql_clause;
    while (my ($sql_clause_var, $sql_clause_value) = each %$sql_clause_ref ) {
        push @temp_sql_clause, "$sql_clause_var = \'$sql_clause_value\'" if ( defined($sql_clause_var) and defined($sql_clause_value));
    }
    $sql_clause = join(", ", @temp_sql_clause);

    $log->debug("\$sql_clause = $sql_clause");

    $sth = $self->{dbh}->prepare(qq{
    UPDATE $table_name SET $sql_clause WHERE $sql_where
    }) or $log->alert("$self->{dbh}->errstr");
    $rv = $sth->execute();


    $self->{dbh}->commit or $log->alert("$self->{dbh}->errstr");
    if ( !$sth->errstr ) {
        return $rv;
    }
    else {
        return -1;
    }



}


sub show_info {
    my $self = shift @_;
    my $statement = shift @_;
    my %info;
    my $rows_arrayref = $self->{dbh}->selectall_arrayref($statement);
    foreach my $row (@$rows_arrayref) {
        $info{$row->[0]} = $row->[1];
    }
    return %info;
}


sub delete_data {

    my $self = shift @_;
    my ( $rv, $sth);
    $log->debug("delete_data");
    my ($table_name, $sql_where_ref) = @_;

    my $sql_where;
    my @temp_sql_where;
    while ( my ($sql_where_var, $sql_where_value) = each %$sql_where_ref ) {
         push @temp_sql_where, "$sql_where_var = \'$sql_where_value\'";
    }
    $sql_where = join(" AND ", @temp_sql_where);
    
    $log->debug("\$sql_where = $sql_where");



    $sth = $self->{dbh}->prepare(qq{
    DELETE FROM $table_name  WHERE $sql_where
    }) or $log->alert("$self->{dbh}->errstr");
    $rv = $sth->execute();


    $self->{dbh}->commit or $log->alert("$self->{dbh}->errstr");
    if ( !$sth->errstr ) {
        return $rv;
    }
    else {
        return -1;
    }

}





sub insert_data {
    my $self = shift @_;
    my ( $rv, $sth);
    $log->debug("insert_data");
    my ($table_name, $sql_clause_ref, $sql_bind_ref) = @_;
    my $sql_clause = join ("," ,@$sql_clause_ref);
    my $sql_bind;
    my $clause_couter = 0;
    foreach (@$sql_clause_ref) {

        if ($clause_couter == $#{$sql_clause_ref}) {
            $sql_bind .= '?';
        }else{
            $sql_bind .= '?, ';
        }
       ++$clause_couter
    }


    $sth = $self->{dbh}->prepare(qq{
    INSERT INTO $table_name ($sql_clause) VALUES ($sql_bind)
    }) or $log->alert("$self->{dbh}->errstr");
    $rv = $sth->execute(@$sql_bind_ref);


    $self->{dbh}->commit or $log->alert("$self->{dbh}->errstr");
    if ( !$sth->errstr ) {
        return $rv;
    }
    else {
        return -1;
    }
}

1;