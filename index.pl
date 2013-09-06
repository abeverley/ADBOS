#!/usr/bin/perl

use strict;
use warnings;

use lib "/var/www/opdef.andybev.com";

use ADBOS::Auth;
use ADBOS::Display;
use ADBOS::DB;
use ADBOS::Config;

my $config = simple_config;
my $db     = ADBOS::DB->new($config);

my $req   = shift; # Apache request
$req->content_type("text/html; charset=utf-8");
my $q = Apache2::Request->new($req);
my $display = ADBOS::Display->new($q);
my $status = $db->statusGet;
$display->status($status);

my $auth = ADBOS::Auth->new($req);

$auth->logout if $q->param('logout');
$auth->login if $q->param('login');

# Check for user login and/or guest access
my $user = $auth->user;
# Force user to change password if needed
$display->myAccount($user, $auth) if ($user && $user->{pwexpired});
my $guest = $auth->guest unless $user;

unless ($guest || $user)
{
    $guest = $display->syops($auth);
}

if ($req->unparsed_uri =~ m!^/+summary/?!gi)
{
    $display->summary($user);
}
elsif ($req->unparsed_uri =~ m!^/+opdef/?([0-9]*)/?([0-9]*)!gi)
{
    $user = $auth->login if !$user;
    $display->opdef($user, $1, $2);
}
elsif ($req->unparsed_uri =~ m!^/+ships/?([0-9]*/?([0-9]*)/?([0-9]*))!gi)
{
    $display->ship($user, $1, $2)
}
elsif ($req->unparsed_uri =~ m!^/+unparsed/?(new|[0-9]*)!gi)
{
    $user = $auth->login if !$user;
    $display->main($user) unless ($user->{type} eq 'member' || $user->{type} eq 'admin');
    if ($1 eq 'new')
    {
        $display->signalNew($user);
    }
    else {
        my $id = $q->param('id') || $1;
        $display->unparsed($user, $id);
    }
}
elsif ($req->unparsed_uri =~ m!^/+users/?([0-9]*)!gi)
{
    $user = $auth->login if !$user;
    $display->main($user) unless ($user->{type} eq 'admin');
    $display->users($user,$auth,$1);
}
elsif ($req->unparsed_uri =~ m!^/+tasks/?([0-9]*)!gi)
{
    $user = $auth->login if !$user;
    $display->main($user) unless ($user->{type} eq 'member' || $user->{type} eq 'admin');
    $display->tasks($user,$auth,$1);
}
elsif ($req->unparsed_uri =~ m!^/+brief/?([0-9]*)!gi)
{
    $user = $auth->login if !$user;
    my $period = $1 || 1;
    my $comments = ($req->unparsed_uri =~ /nocomments/) ? 0 : 1;
    $display->brief($period, $comments);
}
elsif ($req->unparsed_uri =~ m!^/+confirm/([a-z0-9]+)!gi)
{
    # User confirming their email address
    $display->accountEmailConfirm($1);
}
elsif ($req->unparsed_uri =~ m!^/+approve/([a-z0-9]+)!gi)
{
    # Approval of account application by admin
    $display->accountApprove($1,$user);
}
elsif ($req->unparsed_uri =~ m!^/+reset/?([a-z0-9]*)!gi && !$q->param('login'))
{
    # User is resetting password using link
    $display->pwResetFromCode($1);
}
elsif ($req->unparsed_uri =~ m!^/+myaccount/?!gi)
{
    # Manage individual account
    $user = $auth->login unless $user;
    $display->myAccount($user,$auth);
}
elsif ($req->unparsed_uri =~ m!^/+register/?!gi)
{
    # Register for an account
    $display->accountRegister;
}
elsif ($req->unparsed_uri =~ m!^/+emailpw/?!gi && !$user)
{
    # Request password reset
    $display->pwResetRequestEmail;
}
elsif ($req->unparsed_uri =~ m!^/+status/?!gi)
{
    # Show status
    $display->sequence;
}
else
{
    $display->main($user);
}
