#!/usr/bin/perl
use strict;
use warnings;
##############################
#
#  MyCOMMON
#
#  VERSION 1.0.0
#
#  CREATE 2012-10-26
#
#  UPDATE 2012-11-22 03:12
#
#  POWER BY SPUNKMARS++
#
#  SUPPORT  SPUNKMARS@163.COM
#
##############################


package SPMR::COMMON::MyCOMMON;

use base 'Exporter';
use vars qw/@EXPORT/;
@EXPORT = qw(
    trim
    is_digit
    is_int_digit
    add_zero_for_digit
    del_zero_for_digit
    unique
    is_exist_in_array
    array_index
    DD
    l_debug
    $L_DEBUG
    $L_DEBUG_SCREEN
    $L_DEBUG_FILE
    $L_DEBUG_FILE_PATH
);

our $L_DEBUG = 0;
our $L_DEBUG_SCREEN = 1;
our $L_DEBUG_FILE = 0;
our $L_DEBUG_FILE_PATH = '/tmp/l_debug.log';

use Data::Dump qw(dump);
use Data::Dumper;


sub DD {
    my $var = shift @_;
    print Dumper($var);
}


sub trim {
    my $str = shift @_;
    $str=~s/^\s+|\s+$//g if (defined $str);
    return $str;
}


sub is_digit {
    my $num = shift @_;
    if ( $num =~ m/[^0-9|.]+/ or $num =~ m/^\.|\.$/ or $num =~ m/^0[0-9]+/ ) {
        return 0;
    }else {

        return 1;
    }
}


sub is_int_digit {
    my $num = shift @_;
    if ( $num =~ m/\./ ) {
        return 0 ;  
    }elsif ( is_digit($num) ) {
        return 1 if ( $num >= 0 );
    }else{
        return 0;
    }
}


sub add_zero_for_digit {
    my ($digit) = @_;

    if ($digit < 10) {
        return "0".$digit ;
    }else{
        return $digit ;
    }
}


sub del_zero_for_digit {
    my ($digit) = @_;
    $digit =~ s/^0+(\.)*([1-9]+)/$2/g;
    return $digit ;
}


#sub unique {
#    my %seen = ();
#    foreach my $item (@_) {
#        $seen{$item}++;
#    }
#    my @uniq = keys %seen;
#    return @uniq;
#
#}


sub unique {
    my %seen;
    return grep { !$seen{$_}++ } @_;
}


sub is_exist_in_array {
    my $is_exist = 0;
    my ($t_a_ref, $t_v) = @_;
    foreach(@$t_a_ref) {
        if ( "$t_v" eq "$_" ){
            $is_exist = 1;
            last;
        }
    }

    return $is_exist;
}

sub array_index {
    my $exist_index = 0;
    my ($t_a_ref, $t_v) = @_;
    foreach(@$t_a_ref) {
        if ( "$t_v" eq "$_" ){
            return $exist_index;
        }
        $exist_index++;
    }
    return 'NONE';
}


sub get_caller_info {
    my $max_level = 100;
    my @total_caller_info;
    my $caller_level = 0;
    while()
    {
        my @caller_info = caller($caller_level);

        if ( @caller_info  ) {
            push @total_caller_info, \@caller_info;
        }
        else {

            return \@total_caller_info;
            last;
        }
        $caller_level++;
        last if ($caller_level >= $max_level);
    }
    return \@total_caller_info;
}


sub debug_caller_spliter {
    ### FIX ME!
    my ($total_caller_info_ref)   = @_;
    #dump($total_caller_info_ref);
    ## forbid to assigned both only_last_file_info  and  show_last_line to 0 !
    my $only_last_file_info = 0;
    my $show_last_line = 1;

    my $only_show_first_package_info = 0; #only show first package info

    my (@total_subroutines, @total_subroutines_t, @total_subroutines_f);
    my $total_subroutines;
    my $first_pack = '';
    my $temp_sub = '';
    my ($l_package, $l_filename, $l_line);
    my ($package,   $filename, $line,       $subroutine, $hasargs,
        $wantarray, $evaltext, $is_require, $hints,      $bitmask
       );
    my $total_level  = @$total_caller_info_ref;
    my $dep_level = 0;
    while ($dep_level < $total_level) {
       $dep_level++;   
        ($package,   $filename, $line,       $subroutine, $hasargs,
            $wantarray, $evaltext, $is_require, $hints,      $bitmask
            ) = @{@$total_caller_info_ref[-$dep_level]};
       @total_subroutines_t = split('::', $subroutine);
       
       $temp_sub = shift @total_subroutines_t;
       $first_pack = $package if ($dep_level == 1);

       if ($only_show_first_package_info == 1) {
           #push @total_subroutines_f, $total_subroutines_t[0]."($line)" if ($temp_sub eq $first_pack); #only show first package info
           push @total_subroutines_f, $subroutine."($line)" if ($temp_sub eq $first_pack); #only show first package info
       } else {
           push @total_subroutines_f, $subroutine."($line)" ;
       }

       ##
       if ($temp_sub ne $first_pack and $package eq $first_pack) {
           if ($only_last_file_info == 1) {
               $l_package = $package;    #show last package.
               $l_filename = $filename;  #show last file
               $l_line = $line  if ( $show_last_line == 0 );#show last line
           } else {
               $l_line = $line  if ( $show_last_line == 0 );#show last line

           }
       }

       ##
       if ($total_subroutines_t[0] eq 'l_debug'){
           if ($only_last_file_info == 0) {
               $l_package = $package;
               $l_filename = $filename;
               $l_line = $line if ( $show_last_line == 1 );
           } else {
               $l_line = $line if ( $show_last_line == 1 );
           }
           pop @total_subroutines_f;
           last;
       }
    }
    @total_subroutines = reverse(@total_subroutines_f);
    $total_subroutines = join( "->", reverse(@total_subroutines) );
    my %logger_caller_info = (
        "package"     => $l_package,
        "filename"    => $l_filename,
        "subroutines" => $total_subroutines,
        "line"        => $l_line,
    );
    return %logger_caller_info;

}


sub l_debug {
    return 0 if ($L_DEBUG == 0);
    my $message1 = join('', @_);
    my $date_mark= localtime();
    #my $log_path1=( -f $L_DEBUG_FILE_PATH and -w $L_DEBUG_FILE_PATH )?$L_DEBUG_FILE_PATH:'/tmp/l_debug.log';
    my $log_path1=( defined $L_DEBUG_FILE_PATH and  $L_DEBUG_FILE_PATH ne '' )?$L_DEBUG_FILE_PATH:'/tmp/l_debug.log';
    my %caller_info = debug_caller_spliter( get_caller_info() );
    my $subroutines = $caller_info{subroutines};
    $subroutines = '' if ($caller_info{subroutines} eq 'l_debug' and $caller_info{'package'} eq 'main');
    my $p_message = "$date_mark <".$$."> [$caller_info{filename}]:$caller_info{line} [$caller_info{'package'}]"."{$subroutines} L_DEBUG > $message1\n";
    print ("$p_message") if ($L_DEBUG_SCREEN == 1);
    if ($L_DEBUG_FILE == 1) {
        open( LOGFILE1, ">>$log_path1" );
        print LOGFILE1 ("$p_message");
    }


}

1;
