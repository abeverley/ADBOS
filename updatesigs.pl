#!/usr/bin/perl

use warnings;
use strict;

use DBI              ();
use ADBOS::Schema;
use ADBOS::DB;
use ADBOS::Config;

my $config = simple_config;
my $db    = ADBOS::DB->new($config);

my $signals_rs = $db->sch->resultset('Signal');
my @signals = $signals_rs->search({sigtype=>undef})->all;
my @sigtypes = $db->sch->resultset('Sigtype')->search({search=>1})->all;

for my $sig (@signals)
{

    printf "Trying %s\n", $sig->id;

    my $text = $sig->content;
    $text =~ s/\r*//g;

    if (my $sigtype = $db->sigtypeSearch($text))
    {
        printf("Updating signal type to %s for signal ID %s\n", $sigtype, $sig->id);
        my $sigtype_rs = $db->sch->resultset('Sigtype');
        my $type = $sigtype_rs->find($sigtype, { key => 'name' }) if $sigtype;
        $sig->update({ sigtype => $type->id });
    }        
}
