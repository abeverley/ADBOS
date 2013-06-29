#!/usr/bin/perl

use strict;
use warnings;

use lib "/var/www/opdef.andybev.com";

use ADBOS::Auth;
use ADBOS::Display;

my $req   = shift; # Apache request
$req->content_type("text/html; charset=utf-8");
my $q = Apache2::Request->new($req);
my $display = ADBOS::Display->new($q);

my $auth = ADBOS::Auth->new($req);

$auth->logout if $q->param('logout');
$auth->login if $q->param('login');

# Check for user login and/or guest access
my $user = $auth->user;
# Force user to change password if needed
$display->resetpw($user, $auth) if ($user && $user->{pwexpired});
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
elsif ($req->unparsed_uri =~ m!^/+ships/?([0-9]*/?([0-9]*))!gi)
{
    $display->ship($user, $1)
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
    $display->brief($1);
}
elsif ($req->unparsed_uri =~ m!^/+confirm/([a-z0-9]+)!gi)
{
    # User confirming their email address
    $display->accountEmailConfirm($1);
}
elsif ($req->unparsed_uri =~ m!^/+approve/([a-z0-9]+)!gi)
{
    # Approval of account application by admin
    $display->accountApprove($1);
}
elsif ($req->unparsed_uri =~ m!^/+reset/?([a-z0-9]*)!gi && !$q->param('login'))
{
    # User is resetting password using link
    $display->pwResetFromCode($1) if $1;
    $user = $auth->login unless $user;
    # Reset password once logged in
    $display->pwReset($user,$auth);
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
else
{
    $display->main($user);
}
