#!/usr/bin/perl -w
use strict;
use warnings;

##############################
#
#  Log For Perl
#
#  VERSION 1.1.1 
#
#  CREATE 2011-12-21 15:10
#
#  UPDATE 2012-10-30 17:52
#
#  POWER BY SPUNKMARS++
#
#  SUPPORT  SPUNKMARS@163.COM
#
##############################


package SPMR::LOG::Logforperl;
use Sys::Syslog qw(:standard :macros);    # standard functions & macros



sub new {
    my $invocant  = shift;
    my (%options) = @_;
    my $self      = bless( {}, ref $invocant || $invocant );
    $self->init(%options);
    return $self;
}

sub init {

    my $self = shift;
    my (%options) = @_;
    my $split_options_ref;
    my $output_ref;
    my @logger_FILE     = qw/ 0 0 0 0 0 0 0 /;
    my @logger_SCREEN   = qw/ 0 0 0 0 0 0 0 /;
    my @logger_SYSLOG   = qw/ 0 0 0 0 0 0 0 /;
    my @logger_EMAIL    = qw/ 0 0 0 0 0 0 0 /;
    my @logger_DATABASE = qw/ 0 0 0 0 0 0 0 /;
    my @logger_SOCKET   = qw/ 0 0 0 0 0 0 0 /;
    
    my @logger_levels = qw/NONE DEBUG INFO WARN ERROR ALERT FATAL/;

    while ( my ( $options_key, $options_value ) = each %options ) {

        my @temp_options = split /\./, $options_key;
        if ( $#temp_options == 3 and $temp_options[1] eq "output" ) {
            $output_ref->{ $temp_options[2] }->{ $temp_options[3] }
                = $options_value;
        }
        elsif ( $#temp_options == 4 ) {

            #print("44444444\n");
        }

    }
    $self->{logger_FILE} = \@logger_FILE;
    $self->{logger_SCREEN} = \@logger_SCREEN;
    $self->{logger_SYSLOG} = \@logger_SYSLOG;
    $self->{logger_EMAIL} = \@logger_EMAIL;
    $self->{logger_DATABASE} = \@logger_DATABASE;
    $self->{logger_SOCKET} = \@logger_SOCKET;
    $self->{logger_levels} = \@logger_levels;

    $self->{LOGFORPERL_DEBUG}=0;

    $self->{output} = $output_ref;

    $self->get_host_info();  # get host info
    $self->logger_init();

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


sub l_debug {
    my $self = shift @_;
    return 0 if ($self->{LOGFORPERL_DEBUG} == 0);
    my $message1 = join('', @_);
    #my $message1 = shift @_;
    my $date_mark= $self->get_current_date();
    my $log_path1='/tmp/logforperl_debug.log';
    print ("$date_mark L_DEBUG > $message1\n");
    open( LOGFILE1, ">>$log_path1" );
    print LOGFILE1 ("$date_mark L_DEBUG > $message1\n");

}


sub number_to_level {
    my $self = shift @_;
    return $self->{logger_levels}->[ $_[0] ];
}

sub level_to_number {
    my $self = shift @_;
    my $i;
    my ($level) = @_;

    foreach my $logger_level (@{$self->{logger_levels}}) {
        last if ( $logger_level eq $level );
        $i++;
    }
    return $i;
}


sub get_current_date {
    my $self      = shift @_;
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
    $year = $year + 1900;
    $mon = $mon + 1;
    $mon = sprintf("%02d", $mon);
    $mday = sprintf("%02d", $mday);
    $hour = sprintf("%02d", $hour);
    $min = sprintf("%02d", $min);
    $sec = sprintf("%02d", $sec);
    my $temp_date = "${year}-${mon}-${mday} ${hour}:${min}:${sec}";
    return $temp_date;
}

sub output_reset {
    my $self = shift @_;
    my ($OUTPUT_ref) = @_;
    @$OUTPUT_ref = qw/ 0 0 0 0 0 0 0 /;

}

sub logger_reset {
    my $self = shift @_;

}

sub logger_init {
    my $self = shift @_;

    my $logger_init_ref    = $self->{output}->{default};
    my @logger_init_output = split /\,/, ${$logger_init_ref}{"init"};
    my $init_level         = shift @logger_init_output;
    foreach my $init_output (@logger_init_output) {
        $init_output =~ s/\s+//;    #Del Space
        $self->logger_OUTPUT_init( $init_output, $init_level );
    }

}

sub logger_OUTPUT_init {
    my $self = shift @_;

    my ( $init_OUTPUT, $init_level ) = @_;
    my $init_level_number = $self->level_to_number($init_level);

    if ( $init_OUTPUT eq "FILE" ) {
        $self->init_FILE_OUTPUT($init_level_number);
    }
    elsif ( $init_OUTPUT eq "SCREEN" ) {
        $self->init_SCREEN_OUTPUT($init_level_number);
    }
    elsif ( $init_OUTPUT eq "SYSLOG" ) {
        $self->init_SYSLOG_OUTPUT($init_level_number);
    }
    elsif ( $init_OUTPUT eq "EMAIL" ) {
        $self->init_EMAIL_OUTPUT($init_level_number);
    }
    elsif ( $init_OUTPUT eq "DATABASE" ) {
        $self->init_DATABASE_OUTPUT($init_level_number);
    }
    elsif ( $init_OUTPUT eq "SOCKET" ) {
        $self->init_SOCKET_OUTPUT($init_level_number);
    }

}

sub init_FILE_OUTPUT {
    my $self = shift @_;
    my ($init_level) = @_;
    my $i;
    for ( $i = $init_level; $i <= $#{$self->{logger_FILE}}; $i++ ) {
        $self->{logger_FILE}->[$i] = 1;
    }

}

sub init_SCREEN_OUTPUT {
    my $self = shift @_;
    my ($init_level) = @_;
    my $i;
    for ( $i = $init_level; $i <= $#{$self->{logger_SCREEN}}; $i++ ) {
        $self->{logger_SCREEN}->[$i] = 1;
    }
}

sub init_SYSLOG_OUTPUT {
    my $self = shift @_;
    my ($init_level) = @_;
    my $i;
    for ( $i = $init_level; $i <= $#{$self->{logger_SYSLOG}}; $i++ ) {
        $self->{logger_SYSLOG}->[$i] = 1;
    }
}

sub init_EMAIL_OUTPUT {
    my $self = shift @_;
    my ($init_level) = @_;
    my $i;
    for ( $i = $init_level; $i <= $#{$self->{logger_EMAIL}}; $i++ ) {
        $self->{logger_EMAIL}->[$i] = 1;
    }
}

sub init_DATABASE_OUTPUT {
    my $self = shift @_;
    my ($init_level) = @_;
    my $i;
    for ( $i = $init_level; $i <= $#{$self->{logger_DATABASE}}; $i++ ) {
        $self->{logger_DATABASE}->[$i] = 1;
    }
}

sub init_SOCKET_OUTPUT {
    my $self = shift @_;
    my ($init_level) = @_;
    my $i;
    for ( $i = $init_level; $i <= $#{$self->{logger_SOCKET}}; $i++ ) {
        $self->{logger_SOCKET}->[$i] = 1;
    }

}

sub get_caller_info {
    my $self                      = shift @_;
    my $max_caller_level          = 8;
    my $start_record_caller_level = 2;
    my @total_caller_info;

    for (
        my $caller_level = $start_record_caller_level;
        $caller_level <= $max_caller_level;
        $caller_level++
        )
    {
        my @caller_info = caller($caller_level);

        if ( defined( $caller_info[0] ) ) {
            push @total_caller_info, \@caller_info;
        }
        else {

            return \@total_caller_info;
            last;
        }
    }
    return \@total_caller_info;
}

sub split_caller_info {
    my $self                      = shift @_;
    my ($total_caller_info_ref)   = @_;
    my $start_record_caller_level = 2;
    my $caller_level              = $start_record_caller_level;
    my @total_subroutines;
    my $total_subroutines;
    my $logger_line = 0;
    my $logger_package;
    my $logger_filename;

    foreach my $caller_info_ref (@$total_caller_info_ref) {

        my ($package,   $filename, $line,       $subroutine, $hasargs,
            $wantarray, $evaltext, $is_require, $hints,      $bitmask
        ) = @$caller_info_ref;
        $subroutine =~ m/main::(.*)/;
        push @total_subroutines, $1 if ( defined($1) );
        if ( $caller_level == $start_record_caller_level ) {
            $logger_line     = $line;
            $logger_package  = $package;
            $logger_filename = $filename;
        }

        $caller_level++;

    }
    $total_subroutines = join( "::", reverse(@total_subroutines) );
    my %logger_caller_info = (
        "package"     => $logger_package,
        "filename"    => $logger_filename,
        "subroutines" => $total_subroutines,
        "line"        => $logger_line,
    );

    return \%logger_caller_info;


}

sub debug {
    my $self = shift @_;
    my ($message) = @_;
    $self->logger_template( "DEBUG", \$message );
    return 0;
}

sub info {
    my $self = shift @_;
    my ($message) = @_;
    $self->logger_template( "INFO", \$message );
    return 0;
}

sub warning {
    my $self = shift @_;
    my ($message) = @_;
    $self->logger_template( "WARN", \$message );
    return 0;
}

sub error {
    my $self = shift @_;
    my ($message) = @_;
    $self->logger_template( "ERROR", \$message );
    return 0;
}

sub alert {
    my $self = shift @_;
    my ($message) = @_;
    $self->logger_template( "ALERT", \$message );
    return 0;
}

sub fatal {
    my $self = shift @_;
    my ($message) = @_;
    $self->logger_template( "FATAL", \$message );
    exit;
}

sub logger_template {
    my $self = shift @_;
    my ( $logger_level, $message_ref, ) = @_;
    my $total_caller_info_ref = $self->get_caller_info();
    $self->logger_output_switch( "$logger_level", $message_ref,
        $total_caller_info_ref );

}

sub logger_level_trans_to_syslog_level {

    my $self                         = shift @_;
    my ($logger_level)               = @_;
    my %logger_level_to_syslog_level = (
        'DEBUG' => 'debug',
        'INFO'  => 'info',
        'WARN'  => 'warning',
        'ERROR' => 'err',
        'ALERT' => 'alert',
        'FATAL' => 'crit',
    );

    if ( exists $logger_level_to_syslog_level{$logger_level} ) {
        return $logger_level_to_syslog_level{$logger_level};
    }
    else {
        return $logger_level_to_syslog_level{"INFO"};
    }
}

sub logger_output_switch {
    my $self = shift @_;

    my ( $logger_level, $message_ref, $total_caller_info_ref ) = @_;

    my $logger_level_number = $self->level_to_number($logger_level);

    if ( $self->{logger_FILE}->[$logger_level_number] == 1 ) {

        $self->file_output( $message_ref, $logger_level,
            $total_caller_info_ref );
    }

    if ( $self->{logger_SCREEN}->[$logger_level_number] == 1 ) {
        $self->screen_output( $message_ref, $logger_level,
            $total_caller_info_ref );
    }

    if ( $self->{logger_SYSLOG}->[$logger_level_number] == 1 ) {

        $self->syslog_output( $message_ref, $logger_level,
            $total_caller_info_ref );
    }

    if ( $self->{logger_EMAIL}->[$logger_level_number] == 1 ) {
        $self->email_output( $message_ref, $logger_level,
            $total_caller_info_ref );
    }

    if ( $self->{logger_DATABASE}->[$logger_level_number] == 1 ) {
        $self->database_output( $message_ref, $logger_level,
            $total_caller_info_ref );
    }

    if ( $self->{logger_SOCKET}->[$logger_level_number] == 1 ) {
        $self->socket_output( $message_ref, $logger_level,
            $total_caller_info_ref );
    }

}



sub del_space {
    my $self = shift @_;   
    my ($temp_string) = @_;
    $temp_string =~ s/\s+$//g;
    $temp_string =~ s/^\s+//g;
    return $temp_string;

}


sub get_host_ethernet {
    my $self = shift @_;   
    my $ethernet_info = `ifconfig -a`;
    my @temp_ethernet_info = split /^\s*$/m, $ethernet_info;
    my @ethernet_infos;
    foreach my $temp_string (@temp_ethernet_info) {
        my %temp_link;
    
        if(   $temp_string =~ m/(.*)\s+Link encap:(.*)\s+HWaddr(.*)\n/) {
           $temp_link{link} = $self->del_space($1) if ($1);
           $temp_link{link_type} = $self->del_space($2) if ($2);
           $temp_link{hwaddr} = $self->del_space($3) if ($3);
           $temp_link{active} =  ($temp_string =~ m/\s+UP BROADCAST RUNNING MULTICAST/)?'on':'off';
    
    
           if($temp_string =~ m/\s+inet addr:(.*)\s+Bcast:(.*)\s+Mask:(.*)\n/){
               $temp_link{inet_addr} = $self->del_space($1) if ($1);
               $temp_link{bcast} = $self->del_space($2) if ($2);
               $temp_link{mask} = $self->del_space($3)  if ($3);
           }
    
        }else{
    
           if($temp_string =~ m/(.*)\s+Link\s+encap:(.*)\s+(.*)\n/){
               $temp_link{link} = $self->del_space($1) if ($1);
               $temp_link{link_type} = $self->del_space($2) if ($2);
               $temp_link{active} =  ($temp_string =~ m/\s+UP LOOPBACK RUNNING/)?'on':'off';
    
               if($temp_string =~ m/\s+inet addr:(.*)\s+Mask:(.*)\n/){
                   $temp_link{inet_addr} = $self->del_space($1) if($1);
                   $temp_link{mask} = $self->del_space($2)  if ($2);
               }
            }
    
        }
        push @ethernet_infos,\%temp_link;
    
    }
    return @ethernet_infos;

}




sub get_host_info {
    my $self = shift @_;
    my %host;
    my $ipaddress='';
    my @ethernet_infos = $self->get_host_ethernet();

    foreach my $link_ref (@ethernet_infos) {
    
        $ipaddress .= "$link_ref->{inet_addr}|"  if ($link_ref->{inet_addr} and $link_ref->{inet_addr} ne '127.0.0.1' );
        

    }
    $ipaddress  =~ s/\|$//;
    $host{hostname} = $ENV{HOSTNAME};
    $host{ip} = $ipaddress;

    
    $self->{host} =  \%host;

}



sub output_template {
    my $self = shift @_;
    my ($logger_level, $message_format,
        $message_ref,  $total_caller_info_ref
    ) = @_;

    my $logger_caller_info_ref
        = $self->split_caller_info($total_caller_info_ref)
        if ( defined($total_caller_info_ref) and $total_caller_info_ref );
    my $logger_init_ref    = $self->{output}->{default};
    my $logger_host_ref    = $self->{host};
    my $logger_message = $message_format;
    my $current_date   = $self->get_current_date();
    $logger_message =~ s/%L/$$logger_caller_info_ref{"line"}/;
    $logger_message =~ s/%H/$logger_host_ref->{"hostname"}/;
    $logger_message =~ s/%I/$logger_host_ref->{"ip"}/;
    $logger_message =~ s/%P/$$logger_caller_info_ref{"package"}/;
    $logger_message =~ s/%S/$$logger_caller_info_ref{"subroutines"}/;
    $logger_message =~ s/%s/$logger_init_ref->{"soft_name"}/;
    $logger_message =~ s/%F/$$logger_caller_info_ref{"filename"}/;
    $logger_message =~ s/%l/$logger_level/;
    $logger_message =~ s/%p/$$/;
    $logger_message =~ s/%T/$current_date/;
    $logger_message =~ s/%N/\n/;
    $logger_message =~ s/%M/$$message_ref/;

    return $logger_message;

}

sub file_output {
    my $self = shift @_;
    my ( $message_ref, $logger_level, $total_caller_info_ref ) = @_;
    my $file_ref = $self->{output}->{FILE};
    my $message_format;
    if ( defined $file_ref->{msg_format} ) {
        $message_format = $file_ref->{msg_format};
    }
    else {
        $message_format = '%T %F[%p](%S)[%L] %l> %M %N';
    }

    my $log_path;
    if ( defined $file_ref->{log_path} ) {
        $log_path = $file_ref->{log_path};
    }
    else {
        $log_path = '/data/scripts/logforperl_example.log';
    }

    my $message = $self->output_template(
        $logger_level, $message_format,
        $message_ref,  $total_caller_info_ref
    );
    open( LOGFILE, ">>$log_path" );
    print LOGFILE ($message);
}

sub screen_output {
    my $self = shift @_;
    my ( $message_ref, $logger_level, $total_caller_info_ref ) = @_;
    my $screen_ref = $self->{output}->{SCREEN};

    my $message_format;
    if ( defined $screen_ref->{msg_format} ) {
        $message_format = $screen_ref->{msg_format};
    }
    else {
        $message_format = '%T %F[%p](%S)[%L] %l> %M %N';
    }

    my $message = $self->output_template(
        $logger_level, $message_format,
        $message_ref,  $total_caller_info_ref
    );
    print("$message");
}

sub syslog_output {
    my $self = shift @_;
    my ( $message_ref, $logger_level, $total_caller_info_ref ) = @_;
    my $syslog_ref = $self->{output}->{SYSLOG};
    my $logger_init_ref    = $self->{output}->{default};
    my $message_format;
    if ( defined $syslog_ref->{msg_format} ) {
        $message_format = $syslog_ref->{msg_format};
    }
    else {
        $message_format = '(%S)[%L] %l> %M';
    }

    my $message = $self->output_template(
        $logger_level, $message_format,
        $message_ref,  $total_caller_info_ref
    );
    my $syslog_ident  = $logger_init_ref->{soft_name};
    my $syslog_logopt = 'ndelay,pid';

    my $syslog_facility;
    if ( defined $syslog_ref->{facility} ) {
        $syslog_facility = $syslog_ref->{facility};
    }
    else {
        $syslog_facility = 'user';
    }

    my $syslog_priority
        = $self->logger_level_trans_to_syslog_level($logger_level);
    my $syslog_format = '%s';

    #my @syslog_args          = '';
    #my $syslog_mask_priority = '';
    #my $syslog_old_mask      = '';

    openlog( $syslog_ident, $syslog_logopt, $syslog_facility )
        ;    # don't forget this
    syslog( $syslog_priority, $syslog_format, $message );

    #$syslog_old_mask = setlogmask($syslog_mask_priority);
    closelog();

}

sub email_output {
    my $self = shift @_;
    my ( $message_ref, $logger_level, $total_caller_info_ref ) = @_;
    my $email_ref = $self->{output}->{EMAIL};
    my $message_format;
    if ( defined $email_ref->{msg_format} ) {
        $message_format = $email_ref->{msg_format};
    }
    else {
        $message_format = '%T %F[%p](%S)[%L] %l> %M %N';
    }
    my $message = $self->output_template(
        $logger_level, $message_format,
        $message_ref,  $total_caller_info_ref
    );
    print("EMAIL_OUTPUT: $message ");
}

sub database_output {
    my $self = shift @_;
    my ( $message_ref, $logger_level, $total_caller_info_ref ) = @_;
    my $database_ref = $self->{output}->{DATABASE};
    my $message_format;
    if ( defined $database_ref->{msg_format} ) {
        $message_format = $database_ref->{msg_format};
    }
    else {
        $message_format = '%T %F[%p](%S)[%L] %l> %M %N';
    }
    my $message = $self->output_template(
        $logger_level, $message_format,
        $message_ref,  $total_caller_info_ref
    );
    print("DATABASE_OUTPUT: $message");
}

sub socket_output {
    my $self = shift @_;
    my ( $message_ref, $logger_level, $total_caller_info_ref ) = @_;
    my $socket_ref = $self->{output}->{SOCKET};
    my $message_format;
    if ( defined $socket_ref->{msg_format} ) {
        $message_format = $socket_ref->{msg_format};
    }
    else {
        $message_format = '%T %F[%p](%S)[%L] %l> %M %N';
    }
    my $message = $self->output_template(
        $logger_level, $message_format,
        $message_ref,  $total_caller_info_ref
    );
    print("SOCKET_OUTPUT: $message");
}

1;

