#!/usr/bin/perl
use strict;
use warnings;
##############################
#
#  MyNET
#
#  VERSION 1.0.0
#
#  CREATE 2012-10-26
#
#  UPDATE 2013-05-21 23:39
#
#  POWER BY SPUNKMARS++
#
#  SUPPORT  SPUNKMARS@163.COM
#
##############################


package SPMR::NET::MyNET;

use base 'Exporter';
use vars qw/@EXPORT/;
@EXPORT = qw(
    is_ipv4
    is_private_ipv4
    is_public_ipv4
    is_host_active
    crc16_s
    crc16_b
    get_ipv4_addr
    get_ipv4_from_name
);

use SPMR::COMMON::MyCOMMON  qw(is_int_digit);
use Socket;
require 'sys/ioctl.ph';

sub is_ipv4 {
    my $ip_s = shift @_;
    my @t_ips;
    my $is_ipv4 = 0;
    @t_ips = split('\.', $ip_s);
    if ( @t_ips != 4 ) {
        $is_ipv4 = 0;
    }elsif ($ip_s eq '0.0.0.0' or $ip_s eq '255.255.255.255') {
        $is_ipv4 = 1;
    }elsif ( ( grep{ is_int_digit($_) } @t_ips ) != 4 ) {
        $is_ipv4 = 0;
    }elsif ( $t_ips[0] == 0 or $t_ips[0] == 255 ) {
        $is_ipv4 = 0;
    }elsif ( ( grep{ $_ >= 0 and $_ <= 255 } @t_ips ) == 4 ) {
        $is_ipv4 = 1;
    }
   
    return $is_ipv4;

}


sub is_private_ipv4 {
    my $ip_s = shift @_;
    my @t_ips;
    my $is_private = 0;
    @t_ips = split('\.', $ip_s);
    if ( @t_ips == 4 and is_ipv4($ip_s) ) {
        if ($t_ips[0] == 10) {
            $is_private = 1;
        }elsif ($t_ips[0] == 192 and $t_ips[1] == 168) {
            $is_private = 1;
        }elsif ($t_ips[0] == 172 and ($t_ips[1] >= 16 and $t_ips[1] <= 31) ) {
            $is_private = 1;
        }
    }else{
        $is_private = 0;
    }    
    
    return $is_private;
}


sub is_public_ipv4 {
    my $ip_s = shift @_;
    if ( is_private_ipv4($ip_s) ) {
        return 0;
    }else{
        return 1;
    }


}


sub is_host_active {
    my $c_host = shift @_;
    my $ping_result=`LANG=C ping $c_host -c 5`;
    $ping_result =~ m/(.*)([0-9])(.*)packets transmitted(.*)([0-9])(.*)received/;
    #print ("$1 , $2  ,$3 , $4  ,$5  ,$6\n");
    my $send_pack_count=$2;
    my $rece_pack_count=$5;
    if ($2 -$5 > 3 ) {
        return 0;
    }else {
        return 1;
    }

}


sub crc16_s {
    my $data = shift @_;
    my $crc_init = 0xFFFF;
    my $i = 0;
    my $crc_v = $crc_init;
    my $step = 8;
    my $v_s = 0;
    my $c_val;
    while (1) {
        $i++;
        $v_s = ($i-1)*$step ;

        eval{
            no warnings;
            $c_val = substr($data, $v_s, $step);
        };
        if ( defined($c_val) ) {
            $crc_v = crc16_b($crc_v, $c_val);
        }else{
            last;
        }
    }
    return $crc_v;
}



sub crc16_b {
    my ($crc, $val) = @_;

    if ( !defined($crc) or !defined($val) ){
        die "\n";
    }
    my $var;
    my $poly = 0x0000;
    $var = $crc<<8;
    $crc = $var^$val;
    foreach (1..8) {
        $crc = $crc>>1;
        if ($crc & 0x8000) {
            $crc = $crc^$poly;
        }else{
            $crc=$crc>>1;
        }
    }

    return $crc;

}


sub trim {   
    my ($temp_string) = @_;
    $temp_string =~ s/\s+$//g;
    $temp_string =~ s/^\s+//g;
    return $temp_string;

}


sub get_host_ethernet {
 
    my $ethernet_info = `ifconfig -a`;
    my @temp_ethernet_info = split /^\s*$/m, $ethernet_info;
    my @ethernet_infos;
    foreach my $temp_string (@temp_ethernet_info) {
        my %temp_link;
    
        if(   $temp_string =~ m/(.*)\s+Link encap:(.*)\s+HWaddr(.*)\n/) {
           $temp_link{link} = trim($1) if ($1);
           $temp_link{link_type} = trim($2) if ($2);
           $temp_link{hwaddr} = trim($3) if ($3);
           $temp_link{active} =  ($temp_string =~ m/\s+UP BROADCAST RUNNING MULTICAST/)?'on':'off';
    
    
           if($temp_string =~ m/\s+inet addr:(.*)\s+Bcast:(.*)\s+Mask:(.*)\n/){
               $temp_link{inet_addr} = trim($1) if ($1);
               $temp_link{bcast} = trim($2) if ($2);
               $temp_link{mask} = trim($3)  if ($3);
           }
    
        }else{
    
           if($temp_string =~ m/(.*)\s+Link\s+encap:(.*)\s+(.*)\n/){
               $temp_link{link} = trim($1) if ($1);
               $temp_link{link_type} = trim($2) if ($2);
               $temp_link{active} =  ($temp_string =~ m/\s+UP LOOPBACK RUNNING/)?'on':'off';
    
               if($temp_string =~ m/\s+inet addr:(.*)\s+Mask:(.*)\n/){
                   $temp_link{inet_addr} = trim($1) if($1);
                   $temp_link{mask} = trim($2)  if ($2);
               }
            }
    
        }
        push @ethernet_infos,\%temp_link;
    
    }
    return @ethernet_infos;

}


sub get_host_info {
    my %host;
    my $ipaddress='';
    my @ethernet_infos = get_host_ethernet();

    foreach my $link_ref (@ethernet_infos) {
    
        $ipaddress .= "$link_ref->{inet_addr}|"  if ($link_ref->{inet_addr} and $link_ref->{inet_addr} ne '127.0.0.1' );
        

    }
    $ipaddress  =~ s/\|$//;
    $host{hostname} = $ENV{HOSTNAME};
    $host{ip} = $ipaddress;
    
    return %host;

}


sub get_ipv4_from_name {
    my $site_name = shift @_;
    $site_name = 'localhost' unless (defined $site_name);
    my $address;
    $address = inet_ntoa(inet_aton($site_name));
    return $address;
}


sub get_ipv4_addr($) {
    my $pack = pack("a*", shift);
    my $socket;
    socket($socket, AF_INET, SOCK_DGRAM, 0);
    ioctl($socket, SIOCGIFADDR(), $pack);
    return inet_ntoa(substr($pack,20,4));
};


1;
