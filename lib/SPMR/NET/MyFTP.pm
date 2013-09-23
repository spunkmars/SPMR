#!/usr/bin/perl
use strict;
use warnings;
##############################
#
#  MyFTP
#
#  VERSION 1.0.0
#
#  CREATE 2012-10-22
#
#  UPDATE 2012-10-23 17:04
#
#  POWER BY SPUNKMARS++
#
#  SUPPORT  SPUNKMARS@163.COM
#
##############################


#load module
package SPMR::NET::MyFTP;
use Data::Dump qw(dump);
use Net::FTP;
use SPMR::FILE::MyFILE qw(list_dir2 s_basename s_dirname);

use SPMR::LOG::Logforperl;

my %MyFTP = (
    "logger.init.conf_file"   => "/data/scripts/log4perl.conf",
    "logger.output.default.soft_name"  => "MyFTP",
    "logger.output.default.init"   => 'INFO,  SCREEN',
    "logger.output.FILE.log_path" => "/tmp/MyFTP.log",
    "logger.output.FILE.msg_format" =>  '%T %I %s[%p] [%F]:%L(%S) %l> %M %N',
    "logger.output.SCREEN.msg_format" => '%T %I %s[%p] [%F]:%L(%S) %l> %M %N',
    "logger.output.SYSLOG.min_level"  => 'info',
    "logger.output.SYSLOG.facility"  => 'user',
    "logger.output.SYSLOG.msg_format" => '[%F]:%L(%S) %l> %M',
);

my $log = SPMR::LOG::Logforperl->new(%MyFTP);



sub new {
    my $invocant  = shift;
    my ($ftp_address,$ftp_port,$ftp_username,$ftp_password,$overwrite,$auto_create_dir) = @_;
    my $self      = bless( {}, ref $invocant || $invocant );
    my %options = (

        );
    
    $self->{ftp_address} =  $ftp_address;
    $self->{ftp_port} =  $ftp_port;
    $self->{ftp_username} =  $ftp_username;
    $self->{ftp_password} =  $ftp_password;
    $self->{overwrite} =  $overwrite;
    $self->{auto_create_dir} =  $auto_create_dir;

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


sub connect_ftp {

    my $self = shift @_;
    if( $self->{ftp} = Net::FTP->new($self->{ftp_address} ,("Debug" => "0", "Port" => $self->{ftp_port}, ))){
        $log->info("Connect to FTP Server($self->{ftp_address}) !");
    }else{
        $log->fatal("Can not connect to $self->{ftp_address} :$@");
    }

    if($self->{ftp}->login($self->{ftp_username} ,$self->{ftp_password})) {
        $log->info("Login to FTP Server ($self->{ftp_username}) Successfully!");
    }else{
        $log->fatal("Login to FTP Server ($self->{ftp_username}) FAIL !  ". $self->{ftp}->message."");
    }


}


sub close_ftp {
    my $self = shift @_;
    $log->info("Quit from FTP !");
    $self->{ftp}->quit;

}


sub is_connect {
    my $self = shift @_;

}

sub is_exist {
    my $self = shift @_;
    my  @files_tmp;
    my  ($file_tmp) =$_[0];#必须包含全路径名。
    my  ($return_value)=0;
    my   $dir;
    $dir = s_dirname($file_tmp);
    @files_tmp = $self->{ftp}->ls($dir);
        
    foreach my $file (@files_tmp) {

        if ($file_tmp eq  $file) {
            $return_value=1;
            last;
        } else {
            $return_value=0;
        }
    }
    return $return_value;
}



sub upload_file { 
    my $self      = shift @_;
    my (@upload_files)= @_;
    $self->{ftp}->binary();


    #$self->{ftp}->ascii();

    my ($upload_file,$upload_full_path,$remote_dir,$remote_full_path);

    foreach my $uploads_tmp (@upload_files) {

        while ( ($upload_full_path, $remote_dir) = each %$uploads_tmp ) {
            if (($remote_dir =~ tr/\///) >= 2) {   #计算$remote_dir中的/个数
                $remote_dir =~ s#/$##;
            }
            

            if (! -e $upload_full_path) {
                $log->error("Error: Can not Find Local File ($upload_full_path) : No Such File Or Directory! ");
                next;
            }else{
                $upload_file = s_basename($upload_full_path);#从全路径名称中截取文件名。
            }

            my $local_dir = s_dirname($upload_full_path);    
            chdir($local_dir) if ($local_dir); #进入本地文件父目录。

            if ($self->{ftp}->cwd($remote_dir)){
                $log->info("Change Remote Working Directory to $remote_dir");
            } else {
                if ($self->{auto_create_dir} == 1 and $self->make_remote_dir($remote_dir)== 0) {
                    $self->{ftp}->cwd($remote_dir);
                    $log->info("Change Remote Working Directory to $remote_dir");
                }else{
                    $log->error("Can not Chanage Remote Working Directory to $remote_dir");       
                }
            }
    
    
            if ($remote_dir =~ m#^/$#){#如果远程目录是根目录/
                $remote_full_path = "/".$upload_file;
            }else{
                $remote_full_path ="$remote_dir/$upload_file";
            }


            if ($self->is_exist($remote_full_path) == 1 ) {
                if ( $self->{overwrite} == 1) {
                     $self->{ftp}->delete( s_basename($remote_full_path) ) and $log->info("Del Remote Exist File ($remote_full_path) ");
                     if ( $self->{ftp}->put($upload_file ) ) {
                         $log->info("The File ($upload_file) is exist in FTP ($remote_dir)  ! Overwrite it ! ");
                     } else {
                          $log->fatal("Upload Localfile ($upload_full_path) to FTP FAIL ! ". $self->{ftp}->message);
                     }
                }else {
                    $log->fatal("The File ($upload_file) is exist in FTP($remote_dir)  ! Upload file Fail 1 !");
                } 
            }else {
                $self->{ftp}->put($upload_full_path ) or $log->error( "Upload Localfile ($upload_full_path) to FTP FAIL 2 ! ". $self->{ftp}->message);
            }       
            if ($self->is_exist($remote_full_path) == 1 ) {
                $log->info("Upload Localfile ($upload_full_path) to  FTP ($remote_dir) Successfully!");
            }else {
                $log->error("Upload Localfile ($upload_full_path) to  FTP ($remote_dir)  Fail  3 ! ");
            }
        }
    }

}


sub make_remote_dir {
    my $self = shift @_;
    my ($dir) = @_;
    $dir =~ s#^/##;#删除开头的/
    if (($dir =~ tr/\///) >= 2) {   #计算$dir中的/个数
        $dir =~ s#/$##;#删除末尾的/
    }
    if ($self->{auto_create_dir}==1 and $self->{ftp}->mkdir($dir, 1) ) {
        $log->info("Create Remote Directory ( $dir ) !");
    }else{
        $log->error("Can not Create Remote Directory ($dir) : Occur Error When Create Remote Directory  Or This Program not allow to Create Remote Directory , if you want to create remote Directory automatic ,please make sure  variable (\$auto_create_dir) 's  value is 1 !");

    }

}


sub make_remote_dir1 {
    my $self      = shift @_;
    my ($dir) = @_;
    $dir =~ s#^/##;#删除开头的/
    if (($dir =~ tr/\///) >= 2) {   #计算$dir中的/个数
        $dir =~ s#/$##;#删除末尾的/
    }
    #$log->info("\$dir = $dir \n");

    my @child_dirs = split "/", $dir;
    my ($create_dir)="" ;
    foreach my $child_dir (@child_dirs) {
        $create_dir = "$create_dir/$child_dir";
        #$log->info(" $create_dir \n");
        if  ($self->is_exist($create_dir) == 1 ) {
            $log->info(" Remote Directory ( $create_dir ) is exist !");
            next;
        }else{
            if ($self->{auto_create_dir}==1 and $self->{ftp}->mkdir($create_dir)) {
                $log->info("Create Remote Directory ( $create_dir ) !");
            }else{
                $log->error("Can not Create Remote Directory ($create_dir) : Occur Error When Create Remote Directory  Or This Program not allow to Create Remote Directory , if you want to create remote Directory automatic ,please make sure  variable (\$auto_create_dir) 's  value is 1 !");
                last;
            }
        }
    }
    return 0 ;
}


sub upload_mult_files {
    my $self      = shift @_;
    my ($local_upload_files_ref , $remote_dir ) = @_;
    my @uploads;
    my $local_file_base_name;

    foreach my $local_upload_file (@$local_upload_files_ref) {
        $local_file_base_name = s_basename($local_upload_file);
        $local_file_base_name =~ m/^(.*)_([0-9-])+/;

        push @uploads , { $local_upload_file => "$remote_dir" };
    }

    #push @uploads , { $local_upload_file => "/aa/bb/cc/ff" }; #再添加一个数组方法！
    $self->upload_file(@uploads); #上传文件
}


sub is_dir {


}


sub is_file {

}


sub upload_dir {
    my $self      = shift @_;
    my ($l_dir, $r_dir) = @_;
    my ($l_dirs_ref, $l_files_ref, $l_dir_p_d);
    ($l_dirs_ref, $l_files_ref)= list_dir2($l_dir);
    $l_dir_p_d = s_dirname($l_dir, 'parent_dir');
    my $i=0;
    my $l_d;
    while ( $i < @$l_dirs_ref ) {
        $l_d = $l_dirs_ref->[$i];
        $l_d =~ s#^\Q$l_dir_p_d\E#$r_dir#;
        $self->{ftp}->mkdir($l_d, 1);
        #$log->info("make remote dir $l_d !");
        $i++;
    }

    $i=0;
    my $l_file;
    while ($i < @$l_files_ref ) {
        $l_file = $l_files_ref->[$i];
        $l_file =~ s#^\Q$l_dir_p_d\E#$r_dir#;
        #$log->info("upload file $l_files_ref->[$i]  to $l_file");
        $self->{ftp}->put($l_files_ref->[$i], $l_file);
        $i++;
    }
}

1;