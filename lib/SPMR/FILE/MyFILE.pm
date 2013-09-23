#!/usr/bin/perl -w
use strict;
use warnings;
##############################
#
#  MyFILE
#
#  VERSION 1.0.0
#
#  CREATE 2012-10-24
#
#  UPDATE 2012-10-24 16:54
#
#  POWER BY SPUNKMARS++
#
#  SUPPORT  SPUNKMARS@163.COM
#
##############################


#load module
package SPMR::FILE::MyFILE;
use File::Basename;
use base 'Exporter';
use vars qw/@EXPORT/;
@EXPORT = qw(
    make_dir
    get_info
    list_dir
    list_dir1
    list_dir2
    s_basename
    s_dirname
    s_fileparse
    is_safe_path
    safe_path
);


use SPMR::LOG::Logforperl;

my %MyFILE = (
    "logger.init.conf_file"   => "/data/scripts/log4perl.conf",
    "logger.output.default.soft_name"  => "MyFILE",
    "logger.output.default.init"   => 'INFO,  SCREEN',
    "logger.output.FILE.log_path" => "/tmp/MyFILE.log",
    "logger.output.FILE.msg_format" =>  '%T %I %s[%p] [%F]:%L(%S) %l> %M %N',
    "logger.output.SCREEN.msg_format" => '%T %I %s[%p] [%F]:%L(%S) %l> %M %N',
    "logger.output.SYSLOG.min_level"  => 'info',
    "logger.output.SYSLOG.facility"  => 'user',
    "logger.output.SYSLOG.msg_format" => '[%F]:%L(%S) %l> %M',
);

my $log = SPMR::LOG::Logforperl->new(%MyFILE);



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


{no warnings;

sub make_dir {

    my ($tmp_dir,$tmp_init_dir) = @_ ;

    $tmp_dir =~ s#^/##; 
    $tmp_dir =~ s#/$##; 
    $tmp_init_dir =~ s#/$##;
    
    my @tmp_child_dirs = split "/", $tmp_dir;
    my ($create_dir) = $tmp_init_dir ;
    foreach my $child_dir (@tmp_child_dirs) {
        $create_dir = "$create_dir/$child_dir";
        unless (-e $create_dir ) {
            if (mkdir $create_dir ) {
                $log->info("Create Directory ( $create_dir ) !");
                
            }else{
                $log->error("Can not Create Directory ( $create_dir ) !");
                return 1 ;
                last;
            }
        }
    }
    return 0 ;
}

}


sub is_safe_path {
   my $path = shift @_;
   if ($path =~ m#\.\./#) {
       return 0;
   } else {
       return 1;
   }

}


sub safe_path {
    my ($path) = @_;
    if (defined $path) {
        $path =~ s/([^\/]+)\/\.\.\///g;
        $path =~ s/\/{2,}/\//g;
        $path =~ s/\.\/(?!$)//g;
        $path =~ s/\/(\.)+$/\//g;
        $path =~ s/\/$//g  unless ( $path =~ m/^\/$/ );
    }
    return $path;

}


sub s_basename {
    my ($path) = @_;
    return basename( safe_path($path) );
}


sub s_dirname {
    my ($path) = @_;
    return dirname( safe_path($path) );

}


sub s_fileparse {
    my ($path) = @_;
    return fileparse( safe_path($path) );
}


sub get_info {

    my ($dir,$action) = @_ ;
    my $return_value;
    $log->error("$0 --> Error: Please Check Argument !") and exit if ($dir =~ m/\/\//);
    unless (($dir =~ tr/\///) ==1 and $dir =~ m#^/#){#这里有些问题。。 ，只是临时补救措施！
         $dir =~ s#^/##;
    }
    my @child_dirs = split "/", $dir;
    my @full_file_name = split /\./, $child_dirs[@child_dirs-1];

    if ($action eq "parent_dir") {
        for (my $n = 0; $n<=@child_dirs - 2; $n++) {
            $return_value .=  "/".$child_dirs[$n];
        }         

    }elsif ($action eq "sub_dir") {
    }elsif ($action eq "base_name") {

        $return_value = $child_dirs[@child_dirs-1];
    }elsif ($action eq "full_dir") {

    }elsif ($action eq "file_name"){
        for (my $m = 0;$m<=@full_file_name - 2 ;$m++ ) {
            $return_value .=  ".".$full_file_name[$m];
            $return_value =~ s#^\.##;
        }
    }elsif ($action eq "ext_name"){
            $return_value = pop @full_file_name;

    }else{
        exit 1;    
    }
    return $return_value;
}


sub list_dir {
    my ($dir) = @_;
    my @files;

    sub t_dir {
        my ($c_dir, $s_array_ref) = @_;
        #print 'ooo';
        my $handle;
        opendir($handle, $c_dir) or die $!;
        while (my $file = readdir($handle)) {
            next if ($file =~ m/^\.{1,2}$/);
            push(@$s_array_ref, "$c_dir/$file");
            if ( -d "$c_dir/$file") {
                &t_dir("$c_dir/$file", $s_array_ref);
            }
        }
        closedir($handle);

    };

    &t_dir($dir, \@files);
    return @files;

}


sub list_dir1 {
    my ($dir) = @_;
    my @files;

    sub x_dir {
        my ($c_dir, $s_array_ref) = @_;
        #print 'ooo';
        my $handle;
        opendir($handle, $c_dir) or die $!;
        while (my $file = readdir($handle)) {
            next if ($file =~ m/^\.{2}$/);
            push(@$s_array_ref, "$c_dir/$file");
            next if ($file =~ m/^\.{1}$/);
            if ( -d "$c_dir/$file") {
                &x_dir("$c_dir/$file", $s_array_ref);
            }
        }
        closedir($handle);

    };

    &x_dir($dir, \@files);
    return @files;

}


sub list_dir2 {
    my ($dir) = @_;
    my (@d_files, @l_files);

    sub s_dir {
        my ($c_dir, $s_d_array_ref, $s_f_array_ref) = @_;
        #print 'ooo';
        my $handle;
        opendir($handle, $c_dir) or die $!;
        while (my $file = readdir($handle)) {
            next if ($file =~ m/^\.{1,2}$/);
            
            if ( -d "$c_dir/$file") {
                push(@$s_d_array_ref, "$c_dir/$file");
                &s_dir("$c_dir/$file", $s_d_array_ref, $s_f_array_ref);
            }else{
                push(@$s_f_array_ref, "$c_dir/$file");
            }
        }
        closedir($handle);

    };

    &s_dir($dir, \@d_files, \@l_files);
    return (\@d_files, \@l_files);

}


1;
