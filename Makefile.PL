use 5.006;
use strict;
use warnings FATAL => 'all';
use inc::Module::Install;

name     'SPMR';
all_from 'lib/SPMR.pm';
author   q{SpunkMars++ <spunkmars@gmail.com>};
license  'BSD';

perl_version 5.006;

tests_recursive('t');

resources (
   homepage   => 'http://www.spunkmars.org/wiki/index.php/SPMR',
   license    => 'http://opensource.org/licenses/BSD-3-Clause',
   repository => 'https://github.com/spunkmars/SPMR.git',
   bugtracker => 'https://github.com/spunkmars/SPMR',
);

configure_requires (
   'Module::Install' => 1,
);

build_requires (
   'Test::More' => 0,
);

requires (

    'Data::Dumper'     => 0,
    'Data::Dump'       => 0,
    'DBI'              => 0,
    'File::Basename'   => 0,
    'Sys::Syslog'      => 0,
    'Net::FTP'         => 0,
    'Time::HiRes'   => 0,
    'Digest::CRC'   => 0,
    'IO::Socket'   => 0,
    'IO::Select'   => 0,
    'POSIX'   => 0,
    'IPC::SysV'   => 0,
    'IPC::Semaphore'   => 0,

);

install_as_cpan;
auto_install;
WriteAll;
