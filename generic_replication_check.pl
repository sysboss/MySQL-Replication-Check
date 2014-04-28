#!/usr/bin/perl

# Generic replication check
# Copyright (c) 2014 Alexey Baikov <sysboss@mail.ru>
#
# Compare master and slave position and examines MySQL replication gap.
# Alert in case of IO/SQL error(s) and whether replication is delayed too much.
#
# Usage:
# ./generic_replication_check.pl --master 0.0.0.0 --slave 1.1.1.1
#
# Grant on master and slave:
# GRANT REPLICATION CLIENT ON *.* TO 'nagview'@'ip_addr' IDENTIFIED BY PASSWORD '*****';
#

use strict;
use warnings;
use Getopt::Long;

my $verbose;
my $master_host;
my $slave_host;
my $max_gap;
my $min_gap;

# MySQL user and password
my $mysql_user = 'nagview';
my $mysql_pass = '*******';

# Find MySQL binary
chomp( my $mysql_path = `which mysql` );

if( !$mysql_path ){
    print "UNKNOWN: No MYSQL installation found\n";
    exit 1;
}

sub usage {
    print << "_END_USAGE";
usage: $0 [ options ] FROM

Options:
  -m|--master              Master host IP
  -s|--slave               Slave host IP

Replication gap:
  --crit-gap               Critical seconds behind master gap
  --warn-gap               Warning  seconds behind master gap

Others:
  -h|--help                Usage (this info)
  -v|--verbose             Verbose mode

_END_USAGE

    exit 0;
}

GetOptions(
    'v|verbose'  => \$verbose,
    'm|master=s' => \$master_host,
    's|slave=s'  => \$slave_host,
    'crit-gap=s' => \$max_gap,
    'warn-gap=s' => \$min_gap,
) || usage();

# Verify opts
if( !$master_host || !$slave_host ){
    print "UNKNOWN: Missing parameters\n";
    exit 3;
}

$max_gap = 120 if( !$max_gap );
$min_gap = 60  if( !$min_gap );

# Connect to TheMaster
my $command = "$mysql_path -u$mysql_user -p$mysql_pass" .
              " --host $master_host"                    .
              " -e 'show master status \\G'"            .
              " | grep Position | awk '{print \$2}'"    ;

print "connection to master $master_host: " if $verbose ;

# get position
chomp( my $master_position = `$command` );

if( ( !$master_position ) || ( $master_position !~ /^\d+$/ ) ){
    print "failed to connect to master host";
    exit 2;
}

print "position - $master_position\n" if $verbose;

# Connect to TheSlave
$command = "$mysql_path -u$mysql_user -p$mysql_pass"    .
              " --host $slave_host"                     .
              " -e 'show slave status \\G'"             ;

print "connection to slave $slave_host: " if $verbose;
chomp( my $slave = `$command` );

# get position
$slave =~ m/Read_Master_Log_Pos\:\s+(\d+)/;
my $slave_position = $1;

# Slave_IO_Running
$slave =~ m/Slave_IO_Running\:\s+(\w+)/;
my $io_running = $1;

# Slave_SQL_Running
$slave =~ m/Slave_SQL_Running\:\s+(\w+)/;
my $sql_running = $1;

# Seconds_Behind_Master
$slave =~ m/Seconds_Behind_Master\:\s+(.+)/;
my $sec_behind = $1;


if( ( !$slave_position ) || ( $slave_position !~ /^\d+$/ ) ){
    print "failed to connect to slave host";
    exit 2;
}

print "position - $slave_position, " if $verbose;

if( ! $io_running =~ m/yes/i ){
    print "Slave IO not running\n";
    exit 2;
}

if( ! $sql_running =~ m/yes/i ){
    print "Slave SQL not running\n";
    exit 2;
}

if( $sec_behind eq 'NULL' ){
    print "CRITICAL Replication is broken\n";
    exit 2;
}

if( $sec_behind eq 0 ){
    print "OK Replication correct\n";
    exit 0;
}elsif( $sec_behind > $min_gap ){
    if( $sec_behind > $max_gap ){
        print "CRITICAL Replication problem: Seconds_Behind_Master: $sec_behind\n";
        exit 2;
    }elsif( $sec_behind > $min_gap ){
        print "WARNING Replication problem: Seconds_Behind_Master: $sec_behind\n";
        exit 1;
    }else{
        print "OK Replication correct\n";
        exit 0;
    }
}else{
    print "CRITICAL Replication is broken\n";
    exit 2;
}

print "UNKNOWN: Something went wrong\n";
exit 3;
