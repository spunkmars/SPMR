#!/usr/bin/perl
use strict;
use warnings;
##############################
#
#  MyDATE
#
#  VERSION 1.0.1
#
#  CREATE 2012-10-24
#
#  UPDATE 2012-11-21 20:21
#
#  POWER BY SPUNKMARS++
#
#  SUPPORT  SPUNKMARS@163.COM
#
##############################


#load module
package SPMR::DATE::MyDATE;

use base 'Exporter';
use vars qw/@EXPORT/;
@EXPORT = qw(
    disa_timestamp
    is_leapyear
    get_year_days
    get_years_days
    get_mon_days
    get_mons_days
    trans_timestamp_to_standtime
    trans_standtime_to_timestamp
    timestamp_counter
    get_timestamp
    trans_wday
    week_converter
    mon_converter
    trans_short_year
    get_date
    get_current_date
    date_caller 
);

use SPMR::COMMON::MyCOMMON qw(array_index) ;
#use Logforperl;
#
#my %MyDATE = (
#    "logger.init.conf_file"   => "/data/scripts/log4perl.conf",
#    "logger.output.default.soft_name"  => "MyDATE",
#    "logger.output.default.init"   => 'INFO,  SCREEN',
#    "logger.output.FILE.log_path" => "/tmp/MyDATE.log",
#    "logger.output.FILE.msg_format" =>  '%T %I %s[%p] [%F]:%L(%S) %l> %M %N',
#    "logger.output.SCREEN.msg_format" => '%T %I %s[%p] [%F]:%L(%S) %l> %M %N',
#    "logger.output.SYSLOG.min_level"  => 'info',
#    "logger.output.SYSLOG.facility"  => 'user',
#    "logger.output.SYSLOG.msg_format" => '[%F]:%L(%S) %l> %M',
#);
#
#my $log = Logforperl->new(%MyDATE);



sub new {
    my $invocant  = shift;
    my $self      = bless( {}, ref $invocant || $invocant );
    my %options = (

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


sub disa_timestamp { ### disassemble_timestamp 
    my ($timestamp, $is_localtime) = @_;
    $timestamp = ( defined $timestamp and $timestamp ne '')?$timestamp:time();
    die "invalid parameter: \$timestamp = $timestamp !" unless ( $timestamp =~ m/^([1-9]{1}\d*)$/ );
    $is_localtime = ( defined $is_localtime and $is_localtime ne '')?$is_localtime:1;
    if ( $is_localtime == 1 ) {
        return localtime($timestamp);
    } elsif ( $is_localtime == 0 ) {
        return gmtime($timestamp);
    }
}


sub is_leapyear {
    my $year = shift @_;
    if (   ( $year%400==0 ) or ( $year%4==0 and  $year%100!=0 )   ) {
        return 1;
    } else {
        return  0;
    }
}


sub get_year_days {
    return is_leapyear(shift @_)?366:365;
}


sub get_years_days {
    my ($year, $d_action, $year_total) = @_;
    my $total_days = 0;
    my ($year_min, $year_max);
    if ($d_action eq '-' ) {
        $year_min = $year - $year_total;
        $year_max = $year ;
    }elsif ($d_action eq '+') {
        $year_min = $year;
        $year_max = $year + $year_total ;
    }
    for ($year=$year_min; $year <= $year_max; $year++) {
        my $year_days = get_year_days($year);
        $total_days = $total_days + $year_days;
    }
    return $total_days;

}


sub get_mon_days {
    my ($year, $mon) = @_;
    my @mon_days_l = qw( 31 29 31 30 31 30 31 31 30 31 30 31 );
    my @mon_days = qw( 31 28 31 30 31 30 31 31 30 31 30 31 );
    my $days = is_leapyear($year)?$mon_days_l[$mon-1]:$mon_days[$mon-1];
    return $days;
}


sub get_mons_days {
    my ($year, $mon, $d_action, $mon_total) = @_;
    my $total_days = 0;
    my $mon_counter = 1;
    my ($e_year, $e_mon) = ($year, $mon);
    if ( $d_action eq '+' ) {
        for (; $mon_counter <= $mon_total; $mon_counter++) {
            $e_mon++;
            if ( $e_mon > 12 ) {
                $e_year += 1;
                $e_mon = 1;
            }
            $total_days = $total_days + get_mon_days($e_year, $e_mon);
        }
    }elsif ( $d_action eq '-' ) {
        $mon_counter = $mon_total;
        for ( ; $mon_counter >= 0; $mon_counter--) {
            $e_mon--;
            if ( $e_mon < 1 ) {
                $e_year -= 1;
                $e_mon = 12;
            }
            $total_days = $total_days + get_mon_days($e_year, $e_mon);
        }
    }

    return $total_days;

}


sub trans_timestamp_to_standtime {
    my ($timestamp, $is_localtime) = @_;
    $is_localtime = ( defined $is_localtime and $is_localtime ne '')?$is_localtime:1;
    my $standtime;
    die "invalid parameter: \$timestamp = $timestamp !" unless ( $timestamp =~ m/^([1-9]{1}\d*)$/ );
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = disa_timestamp($timestamp, $is_localtime);
    my ($sec_n, $min_n, $hour_n, $mday_n, $mon_n, $year_n) = (
        sprintf("%02d", $sec),
        sprintf("%02d", $min),
        sprintf("%02d", $hour),
        sprintf("%02d", $mday),
        sprintf("%02d", $mon+1),
        $year+1900
    );
    $standtime = "${year_n}${mon_n}${mday_n}${hour_n}${min_n}${sec_n}";
    return $standtime;
}


sub trans_standtime_to_timestamp {
    use Time::Local;
    my ($standtime) = @_;
    my $timestamp;
    $standtime =~ m/^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})$/;  #example: 20120328224352, 20121102030507 ...
    die "invalid parameter: \$standtime = $standtime !" unless (defined $1 and defined $2 and defined $3 and defined $4 and defined $5 and defined $6);
    my ($year, $mon, $mday, $hour, $min, $sec) = ($1, $2, $3, $4, $5, $6);
    foreach my $a_ref (\$year, \$mon, \$mday, \$hour,\$min, \$sec) {
        if ( $$a_ref =~ m/^0+([1-9]+)$/ )  {
            $$a_ref = $1;
        } elsif ( $$a_ref =~ m/^00$/ ) {
            $$a_ref = 0;
        }
    }
    $mon = $mon - 1;
    ($year, $mon, $mday, $hour, $min, $sec) = (int($year), int($mon), int($mday), int($hour), int($min), int($sec) );
    die "invalid num: \$mon = $mon !" if ( $mon < 0 or $mon > 11 );
    die "invalid num: \$mday = $mday !" if ( $mday > get_mon_days($year, $mon+1) );
    die "invalid num: \$hour = $hour !" if ( $hour < 0 or $hour > 23 );
    die "invalid num: \$min = $min !" if ( $min < 0 or $min > 59 );
    die "invalid num: \$sec = $sec !" if ( $sec < 0 or $sec > 59 );
    $timestamp = timelocal($sec, $min, $hour, $mday, $mon, $year); # timelocal(59,59,23,30,11,2012)
    return $timestamp;
}


sub timestamp_counter {
    my ($timestamp, $date_type) = @_;
    $date_type =~ m/^([+-])(\d+)([A-Za-z]{1})$/;
    die "invalid parameter: \$date_type = $date_type !" unless (defined $1 and defined $2 and defined $3);
    my ($d_action, $d_count , $unit_type) = ( $1, $2, $3);
    if ( $unit_type eq 'd' ) {
        $timestamp = ( $d_action eq '-' )?$timestamp - ( 3600 * 24 * $d_count ):$timestamp + ( 3600 * 24 * $d_count );
    }elsif ($unit_type eq 'w') {
        $timestamp = ( $d_action eq '-' )?$timestamp - ( 3600 * 24 * 7 * $d_count ):$timestamp + ( 3600 * 24 * 7 * $d_count );
    }elsif ($unit_type eq 'Y') {##### fix me!
        my @date_array = localtime($timestamp);
        $timestamp = ( $d_action eq '-' )?$timestamp - ( 3600 * 24 * get_years_days($date_array[5]+1900, $d_action, $d_count) ):$timestamp + ( 3600 * 24 * get_years_days($timestamp, $d_action, $d_count) );
    }elsif ($unit_type eq 'M') {
        $timestamp = ( $d_action eq '-' )?$timestamp - ( 60 * $d_count ):$timestamp + ( 60 * $d_count );
    }elsif ($unit_type eq 'm') {##### fix me!
        my @date_array = localtime($timestamp);
        $timestamp = ( $d_action eq '-' )?$timestamp - ( 3600 * 24 * get_mons_days($date_array[5]+1900, $date_array[4]+1, $d_action, $d_count) ):$timestamp + ( 3600 * 24 * get_mons_days($timestamp, $d_action, $d_count) );
    }elsif ($unit_type eq 'H') {
        $timestamp = ( $d_action eq '-' )?$timestamp - ( 3600 * $d_count ):$timestamp + ( 3600 * $d_count );
    }elsif ($unit_type eq 'S') {
        $timestamp = ( $d_action eq '-' )?$timestamp - ( 1 * $d_count ):$timestamp + ( 1 * $d_count );
    }else {
        die "invalid parameter: $date_type --> $unit_type";
    }
    return $timestamp;
}


sub get_timestamp {
    my ($timestamp, $date_type, $is_localtime) = @_;
    $date_type = $date_type?$date_type:'today';
    $timestamp = $timestamp?$timestamp:time;
    $is_localtime = ( defined $is_localtime and $is_localtime ne '')?$is_localtime:1;
    
    my (@date_array, $cur_mon_days, $cur_year_days);
    if ( ($date_type ne 'today') or ($date_type ne 'yesterday') or ($date_type ne 'tomorrow') or ($date_type ne 'last_week') or ($date_type ne 'next_week') ) {
        @date_array = disa_timestamp($timestamp, $is_localtime);
        $cur_mon_days = get_mon_days($date_array[5]+1900, $date_array[4]+1);
        $cur_year_days = get_year_days($date_array[5]+1900);
    }

    if ( $date_type eq 'today' ) {
        $timestamp = $timestamp;
    }elsif ( $date_type eq 'yesterday' ) {
        $timestamp = $timestamp - ( 3600 * 24 );
    }elsif ( $date_type eq 'tomorrow' ) {
        $timestamp = $timestamp + ( 3600 * 24 );
    }elsif ( $date_type eq 'last_week' ) {
        $timestamp = $timestamp - ( 3600 * 24 * 7 );
    }elsif ( $date_type eq 'next_week' ) {
        $timestamp = $timestamp + ( 3600 * 24 * 7 );
    }elsif ( $date_type eq 'last_mon' ) {
        $timestamp = $timestamp - ( 3600 * 24 * $cur_mon_days );
    }elsif ( $date_type eq 'next_mon' ) {
        $timestamp = $timestamp + ( 3600 * 24 * $cur_mon_days );
    }elsif ( $date_type eq 'last_year' ) {
        $timestamp = $timestamp - ( 3600 * 24 * $cur_year_days );
    }elsif ( $date_type eq 'next_year' ) {
        $timestamp = $timestamp + ( 3600 * 24 * $cur_year_days );
    }elsif ( $date_type =~ m/^[+-]/ ) {  # example: +3d , +2w, +2Y, +4M, +3m, +3H, +3S ...
        $timestamp = timestamp_counter($timestamp, $date_type);
    }else {
        die "invalid parameter: \$date_type = $date_type  !";
    }
    return $timestamp;

}


sub trans_wday {
    my ($week_num, $zero_is_sunday) = @_;
    $zero_is_sunday = (defined $zero_is_sunday)?$zero_is_sunday:1;
    if ( $zero_is_sunday == 0 ) {
        die "invalid parameter: \$week_num = $week_num !" if ($week_num < 1 or $week_num > 7);
        return ( $week_num == 7 )?0:$week_num;
    } else {
        die "invalid parameter: \$week_num = $week_num !" if ($week_num < 0 or $week_num > 6);
        return ( $week_num == 0 )?7:$week_num;
    }

}


sub week_converter {
    my ($week, $in_type, $is_abbr) = @_;
    $in_type = $in_type?$in_type:'num';
    $is_abbr = (defined $is_abbr)?$is_abbr:1;
    my @abbr_week = qw( Mon Tue Wed Thu Fri Sat Sun );
    my @full_week = qw( Monday Tuesday Wednesday Thursday Friday Saturday Sunday );
    if ( $in_type eq 'num' ) {
        $week = $week - 1;
        die "invalid parameter: $week" if ( $week-1 > 6 );
        if ($is_abbr == 1 ) {
            return $abbr_week[$week];
        } else {
            return $full_week[$week];
        }
    } elsif ( $in_type eq 'name' ) {
        my $week_index;
        if ($is_abbr == 1 ) {
            $week_index = array_index(\@abbr_week, $week);
        } else {
            $week_index = array_index(\@full_week, $week);
        }
        die "invalid parameter: \$week = $week !" if ( $week_index eq 'NONE' );
        return $week_index;
    }
}


sub mon_converter {
    my ($mon, $in_type, $is_abbr) = @_;
    $in_type = $in_type?$in_type:'num';
    $is_abbr = (defined $is_abbr)?$is_abbr:1;
    my @abbr_mon = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
    my @full_mon = qw( January February March April May June July August September October November December );
    if ( $in_type eq 'num' ) {
        $mon = $mon - 1;
        die "invalid parameter: $mon" if ( $mon > 11 );
        if ($is_abbr == 1 ) {
            return $abbr_mon[$mon];
        } else {
            return $full_mon[$mon];
        }
    } elsif ( $in_type eq 'name' ) {
        my $mon_index;
        if ($is_abbr == 1 ) {
            $mon_index = array_index(\@abbr_mon, $mon);
        } else {
            $mon_index = array_index(\@full_mon, $mon);
        }
        die "invalid parameter: \$mon = $mon !" if ( $mon_index eq 'NONE' );
        return $mon_index;
    }
}


sub trans_short_year {
    my $year = shift @_;
    my $short_year = sprintf("%02d", $year % 100);
    return $short_year;
}


sub get_date {
    my ($mark_string, $date_type, $timestamp, $is_localtime) = @_;
    $mark_string = $mark_string?$mark_string:'%Y%m%d%H%M%S';
    $date_type = $date_type?$date_type:'today';
    $timestamp = $timestamp?$timestamp:time;
    $is_localtime = ( defined $is_localtime and $is_localtime ne '')?$is_localtime:1;

    $timestamp = get_timestamp($timestamp, $date_type);
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = disa_timestamp($timestamp, $is_localtime);

    $year = $year + 1900;
    $mon = $mon + 1;

    my $short_year = trans_short_year($year);

    my ($sec_n, $min_n, $hour_n, $mday_n, $mon_n, $year_n, $yday_n) = (
        sprintf("%02d", $sec),
        sprintf("%02d", $min),
        sprintf("%02d", $hour),
        sprintf("%02d", $mday),
        sprintf("%02d", $mon),
        $year,
        sprintf("%03d", $yday+1)
    );

    my $day_p = ($hour <= 12)?'AM':'PM';
    my $hour_l = ($hour > 12)?$hour-12:$hour;
    my $hour_i = sprintf("%02d", $hour_l);
    my $wday_s = trans_wday($wday);
    my ($abbr_week_name, $full_week_name) = ( week_converter($wday_s, 'num', 1), week_converter($wday_s, 'num', 0) );
    my ($abbr_mon_name, $full_mon_name) = ( mon_converter($mon, 'num', 1), mon_converter($mon, 'num', 0) );
    my %date_mark = (
        '%a' => $abbr_week_name,
        '%A' => $full_week_name,
        '%b' => $abbr_mon_name,
        '%B' => $full_mon_name,
        '%c' => "$abbr_week_name $abbr_mon_name  $mday $hour_n:$min_n:$sec_n $year_n",
        '%d' => $mday_n,
        '%D' => "$mon_n/$mday_n/$short_year",
        '%F' => "$year_n-$mon_n-$mday_n",
        '%H' => $hour_n ,
        '%I' => $hour_i ,
        '%j' => $yday_n ,
        '%k' => $hour ,
        '%l' => $hour_l,
        '%m' => $mon_n ,
        '%M' => $min_n ,
        '%o' => "$year_n-$mon_n-$mday_n-$hour_n$min_n",
        '%O' => "$year_n$mon_n$mday_n",
        '%p' => $day_p,
        '%P' => lc($day_p),
        '%r' => "$hour_n:$min_n:$sec_n $day_p",
        '%R' => "$hour_n:$min_n",
        '%s' => "$year_n-$mon_n-$mday_n $hour_n:$min_n:$sec_n",
        '%S' => $sec_n ,
        '%T' => "$hour_n:$min_n:$sec_n",
        '%u' => $wday_s,
        '%w' => $wday,
        '%x' => "$mon_n/$mday_n/$short_year",
        '%X' => "$hour_n:$min_n:$sec_n",
        '%Y' => $year_n ,
        '%y' => $short_year,
    );

    my $temp_date = $mark_string;

#    use POSIX qw(strftime);
#    $temp_date = strftime $mark_string, localtime($timestamp);

    while ( my ($key_m, $val_s) = each (%date_mark) ) {
        #print("$key_m, $val_s\n");
        $temp_date =~ s#\Q$key_m\E#$val_s#g;
    }

    return $temp_date;

}


sub get_current_date {
    return get_date('%s');
}


sub date_caller {


}

1;


