#!/usr/bin/perl

use strict;
use warnings;

use ADBOS::DB;
use ADBOS::Parse;
use ADBOS::Config;
use File::Slurp;

sub process($;$);

my $config = simple_config;

my $parser = ADBOS::Parse->new();
my $db     = ADBOS::DB->new($config);

# See if text is being piped in. If so, read it
if (not -t STDIN and my $message = do { local $/; <STDIN> })
{
    process($message);
    exit;
}

# Otherwise read files from the cache
my $cache = $config->{queuedir};

while (1) {
    # Look for files in cache
    my $dh;
    opendir($dh, $cache);
    while (defined(my $f = readdir($dh)))
    {
        my $file = "$cache/$f";
        next unless -f $file;
        if (my $message = read_file($file))
        {
            process($message, $f);
            unlink $file;
        }
    }
    close $dh;
    sleep 1;
}

sub process($;$)
{
    my ($message,$f) = @_;

    print "Attempting to parse message ";
    print "for file $f..." if $f;
    print "\n";

    # Clean up extra line breaks
    $message =~ s/\r*//g;
    
    if ($message =~ /^CHANNEL CHECK$/m)
    { # Ignore for the moment
      # XXXX Log in DB in future
    }
    elsif (my $values =  $parser->parse($message))
    {
        my $status;
        $db->signalProcess($values, \$status);
        print "$status\n";
    } elsif ($db->signalOther($message)) {
        print "Parsed signal as an associated signal\n";
    } else {
        $db->signalStore($message);
        print STDERR "Parse failed\n";
    }
}
