#!/usr/bin/perl

use strict;
use warnings;

use Device::SerialPort;
use File::Temp qw/tempfile/;

my $port;

if ($port = Device::SerialPort->new("/dev/ttyS0"))
{
    $port->databits(7);
    $port->baudrate(9600);
    $port->parity("odd");
    $port->stopbits(1);
    $port->handshake("off");
}
else
{
    die "Failed to open serial port";
}

my $STALL_DEFAULT=1000; # how many seconds to wait for new input

$port->read_char_time(0);     # don't wait for each character
$port->read_const_time(1000); # 1 second per unfulfilled "read" call

my $chars=0;
my $buffer="";

my $cache = '/var/lib/adbos/incoming';

while (1) {
    my ($count,$saw)=$port->read(255); # will read _up to_ 255 chars

    if ($count > 0) {
        $chars+=$count;
        $buffer.=$saw;

#        print "XXXX\n$saw\nXXXX\n";
        # Check here to see if what we want is in the $buffer
        # say "last" if we find it
#        if (0)
        print "DATA RX:\n";
        if ($buffer =~ /\RNNNN/)
        {
            (my $message, $buffer) = split /\RNNNN/, $buffer;
#            if ($message !~ /OPDEF/ || $message =~ /MATDEM|AVICOS|NAAIHTO|EQUIPREC|EQUIPSENT/)
#            {
#                print "Ignoring MATDEM\n";
#                $db->matdemStore($message);
#                next;
#            }
            print "MESSAGE FOUND\n";
            $message =~ s/\r\n/\n/g;
            $message =~ s/(\n|.)*VZCZC//g;

            # Dump to disk
            my ($fh) = tempfile(DIR => $cache);
            print $fh $message;
            close $fh;
        }
    }
}


$port->close if $port;
undef $port;
