#!/usr/bin/perl

use strict;
use warnings;

use lib "/var/www/opdef.andybev.com";

use ADBOS::DB;
use ADBOS::Config;

my $config = simple_config;
my $db     = ADBOS::DB->new($config);

my $sch = $db->sch;
$sch->storage->debug(0);

my $opdef_rs = $sch->resultset('Opdef');

my @opdefs = $opdef_rs->search->all;

foreach my $opdef (@opdefs)
{
    $db->opdefIndex($opdef->id);
}

