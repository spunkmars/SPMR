package SPMR::NET::MySocket;

use strict qw(vars);
use warnings;

use vars qw(@EXPORT @ISA @EXPORT_OK $VERSION);
use Data::Dumper;
use Time::HiRes qw(gettimeofday time);
use Digest::CRC qw(crc16 crc32);
use IO::Socket;
use IO::Select;
use POSIX qw(:signal_h WNOHANG);
use IPC::SysV qw(IPC_PRIVATE S_IRWXU IPC_CREAT);
use IPC::Semaphore;

require Exporter;

@EXPORT_OK = qw(send_data rec_data);
@EXPORT = @EXPORT_OK;

@ISA = qw(Exporter);
$VERSION = '1.00';

use constant  DEBUG => 0;
use constant  MAX_PACK_SIZE => 1024;
use constant  MAX_HEAD_SIZE => 56;
use constant  MAX_BOTTOM_SIZE => 8;
use constant  PACK_START_MARK => '0x02';
use constant  PACK_END_MARK => '0x04';



die "ERROR: MAX_PACK_SIZE must >= 65 !\n" if MAX_PACK_SIZE - MAX_HEAD_SIZE - MAX_BOTTOM_SIZE < 1;

my $PACK_G_ID = 0;
my $CURRENT_G_ID = 0;


sub make_new_pack {

    my ($proto_name, $proto_ver, $cmd, $id, $count, $sub_id, $date, $type, $length);
    my $msg = '';

    $proto_name = shift;
    $proto_ver = shift;
    $cmd = shift;
    $id = shift;
    $count = shift;
    $sub_id = shift;
    $date = join('', gettimeofday());
    $type = shift;
    my $data = shift;
    $length = length($data);

    my @msg_head = ($proto_name, $proto_ver, $cmd,  $id,  $count, $sub_id, $date, $type, $length);
    print "make_new_pack: \@msg_head = ", Dumper(@msg_head), "\n" if DEBUG;
    my $msg_head_s = join('', @msg_head);

    my $msg_head_crc = crc16($msg_head_s);

    $msg =  pack("A4", PACK_START_MARK) . pack("NNNNNNA16NN", @msg_head) . pack("N", $msg_head_crc);

    my $msg_data_crc = crc16($data);

    $msg .= pack("A*", $data) . pack("N", $msg_data_crc) . pack("A4", PACK_END_MARK);

    return $msg;

}

sub trans_name_to_code {
    my %PROTO_NAME = ( 'ALT' =>  4001);
    my %PROTO_VER = ( 'Ver1' => 2001);
    my %CMD = ( 'conn' => 1001,
                'vefy' => 1002,
                'error' => 1006,
                'active' => 1005,
                'send' => 1007,
                'bye'  => 1004,
                'ack'  => 1008, 
    );
    my %TYPE = ( 'BINA'  => 5001,
                 'JSON'  => 5002,
                 'BSON'  => 5003,
                 'XML'   => 5004,
                 'ASCII'   => 5005,
    );

    die "parse argv error !\n" if @_ < 2;

    my ($trans_type, $trans_name) = @_;
    
    if ($trans_type eq 'PROTO_NAME') {
        return $PROTO_NAME{$trans_name};
    }elsif ($trans_type eq 'PROTO_VER') {
        return $PROTO_VER{$trans_name};
    }elsif ($trans_type eq 'CMD') {
        return $CMD{$trans_name};
    }elsif ($trans_type eq 'TYPE') {
        return $TYPE{$trans_name};
    }else{
        die "unknown trans type ! \n";
    }

}

sub send_data {
    my $conn = shift;
    my $proto_name = shift;
    my $proto_ver = shift;
    my $pack_cmd = shift;
    my $data_type = shift;
    my $data = shift;
    my $step = MAX_PACK_SIZE - MAX_HEAD_SIZE - MAX_BOTTOM_SIZE;
    my $i = 0;
    my $v_s = 0;
    my @datas; 
    my $temp_string;
    while (1) {
        my $s_data;
        $i++;
        $v_s = ($i-1)*$step ;

        eval{
            no warnings;
            $s_data = substr($data, $v_s, $step);
        };
        if ( defined($s_data) and length($s_data) >0 ) {
            push @datas, $s_data; 
        }else{
            last;
        }
    }

    foreach (0..$#datas){
        my $id = ++$PACK_G_ID;
        my @s_argv = (&trans_name_to_code('PROTO_NAME', $proto_name), &trans_name_to_code('PROTO_VER', $proto_ver), &trans_name_to_code('CMD', $pack_cmd), $id, $#datas, $_, &trans_name_to_code('TYPE', $data_type), $datas[$_]);
        $temp_string = &make_new_pack(@s_argv);
        print "\$s_data = $datas[$_] \n" if DEBUG;
        print "s_data length : ", length($datas[$_]), "\n" if DEBUG;
        syswrite($conn, $temp_string, length($temp_string));
        print "send_data: \@s_argv= ", Dumper(@s_argv[0..$#s_argv-1]), "\n" if DEBUG;
     
        while(rec_status($conn, \@s_argv, 'ack') eq 'True') {
            next;
        }
    }
}

sub rec_status {

    my ($conn, $s_argv_ref, $cmd) = @_;
    my @context;
    my $rec_msg;
    my $rec_report_status = 'False';
    while ( sysread($conn, $rec_msg, MAX_PACK_SIZE)){
        my $head_ref = &parse_head($rec_msg);
        my $msg_context;
        my $msg_bottom;
        print "rec_status: \$head_ref = ", Dumper($head_ref), "\n" if DEBUG;
        print "rec_status: \$s_argv_ref = ", Dumper($s_argv_ref), "\n" if DEBUG;
        if ( $head_ref->{LENGTH} > 0) {
            print "HEAD LENGTH : ", $head_ref->{LENGTH}, "\n" if DEBUG;
            $msg_context = substr($rec_msg, MAX_HEAD_SIZE, $head_ref->{LENGTH});        
            $msg_bottom = substr($rec_msg, MAX_HEAD_SIZE+$head_ref->{LENGTH}, MAX_BOTTOM_SIZE);
            print "msg_bottom :", $msg_bottom, "\n" if DEBUG;
            die "unknown end mark!\n" if substr($msg_bottom, 4, 4) ne PACK_END_MARK;
            die "crc check for msg_context error !\n" if unpack("N", substr($msg_bottom, 0, 4) )  != crc16($msg_context);
            if ($head_ref->{ID} == $s_argv_ref->[3] and $head_ref->{COUNT} == $s_argv_ref->[4] and $head_ref->{SUB_ID} == $s_argv_ref->[5] and $head_ref->{CMD} == &trans_name_to_code('CMD',$cmd)) {
                $rec_report_status = 'True';
                last;
            }
            
        }
    }
    return $rec_report_status;
}

sub parse_head {
    my $head_string = substr(shift, 0, MAX_HEAD_SIZE);
    my %rec_head;
    my @rec_heads;
    @rec_heads = unpack("A4NNNNNNA16NNN",$head_string);
    my $s_mark;
    $s_mark = shift @rec_heads;
    die "rec unknown start mark!\n" if ($s_mark ne PACK_START_MARK); 
    if (@rec_heads >= 10){
        die "crc check for msg_head error !\n" if crc16(join('', @rec_heads[0..$#rec_heads-1]) ) != $rec_heads[-1] ;
        %rec_head = ( 'PROTO_NAME'  =>  $rec_heads[0],
                      'PROTO_VER'   =>  $rec_heads[1],
                      'CMD'         =>  $rec_heads[2],
                      'ID'         =>  $rec_heads[3],
                      'COUNT'         =>  $rec_heads[4],
                      'SUB_ID'         =>  $rec_heads[5],
                      'DATE'         =>  $rec_heads[6],
                      'TYPE'         =>  $rec_heads[7],
                      'LENGTH'         =>  $rec_heads[8],
                      'CRC'         =>  $rec_heads[9],
        );
    }else{

        die "unknown pack error !\n";
    }

    return \%rec_head;
}



sub rec_data1 {
    my $conn = shift;
    my $seek = 0;
    my @context;
    my $rec_msg;
    
    while ( sysread($conn, $rec_msg, MAX_PACK_SIZE)){
        my $head_ref = &parse_head($rec_msg);
        my $msg_context;
        my $msg_bottom;
        print "HEAD : ", Dumper($head_ref), "\n" if DEBUG;
        if ( $head_ref->{LENGTH} > 0) {
            print "HEAD LENGTH : ", $head_ref->{LENGTH}, "\n" if DEBUG;
            $msg_context = substr($rec_msg, MAX_HEAD_SIZE, $head_ref->{LENGTH});        
            $msg_bottom = substr($rec_msg, MAX_HEAD_SIZE+$head_ref->{LENGTH}, MAX_BOTTOM_SIZE);
            print "msg_bottom :", $msg_bottom, "\n" if DEBUG;
            die "unknown end mark!\n" if substr($msg_bottom, 4, 4) ne PACK_END_MARK;
            die "crc check for msg_context error !\n" if unpack("N", substr($msg_bottom, 0, 4) )  != crc16($msg_context);
            push @context, $msg_context;
            &send_rec_status($conn, $head_ref, 'ack');
            last if $head_ref->{COUNT} == $head_ref->{SUB_ID};
        }
    }

    return join('', @context);

}


sub rec_data {
    my $conn = shift;
    my $seek = 0;
    my @context;
    my $rec_msg;
    my $all_context = shift;
    my $pp_pid = shift;
    my $sem_c = IPC::Semaphore->new(1566, 1, S_IRWXU) or die "Can't creat sem!\n";

    my $sem_v;
    my $ccount = 0;
        

    while ( sysread($conn, $rec_msg, MAX_HEAD_SIZE)){
        my $head_ref = &parse_head($rec_msg);
        my $msg_context;
        my $msg_bottom;
        print "HEAD : ", Dumper($head_ref), "\n" if DEBUG;
        if ( $head_ref->{LENGTH} > 0) {
            print "HEAD LENGTH : ", $head_ref->{LENGTH}, "\n" if DEBUG;
            sysread($conn, $msg_context, $head_ref->{LENGTH});
            sysread($conn, $msg_bottom, MAX_BOTTOM_SIZE);
            print "msg_bottom :", $msg_bottom, "\n" if DEBUG;

            if (substr($msg_bottom, 4, 4) ne PACK_END_MARK) {
                &send_rec_status($conn, $head_ref, 'error');
                #die "unknown end mark!\n";
            }

            if ( unpack("N", substr($msg_bottom, 0, 4) )  != crc16($msg_context) ) {  
                &send_rec_status($conn, $head_ref, 'error');
                #die "crc check for msg_context error !\n";
            }

            push @context, $msg_context;
            &send_rec_status($conn, $head_ref, 'ack');
            if ($head_ref->{COUNT} == $head_ref->{SUB_ID}){

                   do{
                       $sem_v = $sem_c->getval(0);
                   }while($sem_v != 0);
                   print "\$sem_v = ", $sem_v, "\n";
                   $ccount++;
                   print "\$ccount = ", $ccount, "\n";

                   $sem_c->op(0,1,IPC_NOWAIT);
                   push(@{$all_context->{REC_POOL}}, join('', @context));
                   $sem_v = $sem_c->getval(0);
                   print "\$sem_v1 = ", $sem_v, "\n";
                 
                   #$all_context->{REC_POOL}->[0] =  join('', @context);
                   @context = ();
                   $sem_c->op(0,-1,IPC_NOWAIT);
                   kill ALRM=>$pp_pid;
            }

        }else{
            &send_rec_status($conn, $head_ref, 'error');

        }
    }

    return $all_context;

}



sub say_bye {

&send_rec_status();

}

sub send_rec_status {

    my $conn = shift;
    my $s_msg_head_ref = shift; 
    my $proto_name = $s_msg_head_ref->{PROTO_NAME};
    my $proto_ver = $s_msg_head_ref->{PROTO_VER};
    my $pack_cmd = shift;
    my $data_type = $s_msg_head_ref->{TYPE};
    my $temp_string;
    my $id = $s_msg_head_ref->{ID};
    my $count = $s_msg_head_ref->{COUNT};
    my $sub_id = $s_msg_head_ref->{SUB_ID};
    print "send_rec_status: \$s_msg_head_ref = ", Dumper($s_msg_head_ref), "\n" if DEBUG;
    $temp_string = &make_new_pack($proto_name, $proto_ver, &trans_name_to_code('CMD', $pack_cmd), $id, $count, $sub_id, $data_type, 'pack status' );
    syswrite($conn, $temp_string, length($temp_string));
}

1;
