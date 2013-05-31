use warnings;
use strict;

package ADBOS::Auth;

use Apache::Session::File;
use CGI::Cookie;
use ADBOS::Display;
use ADBOS::DB;
use ADBOS::Config;
use Crypt::SaltedHash;
use String::Random;
use DateTime;
use DateTime::Format::Duration;
  
=pod

  ADBOS::DB->new(CONFIG, OPTIONS);

CONFIG (from resend.conf) is used as defaults for OPTIONS, and
can be C<undef>.

OPTIONS:

   name           database name       DBNAME
   user           database user       DBUSER
   password       password of user    DBPASS

=cut

sub new($$)
{   my ($class, $req) = @_;
    my $self = bless {}, $class;
    $self->{req} = $req;
    $self;
}

# Returns current username, if exists
sub user($)
{   my $self = shift;

    my $session = $self->session;
    return $session->{user};
}

sub login()
{   my $self = shift;
    my $q = Apache2::Request->new($self->{req});
    my $message;
    if($q->body('login')) # Only POST requests
    {
        my $config = simple_config;
        my $db = ADBOS::DB->new($config);
        my $user = $db->userGet({ username => $q->param('username') });
        if ($user && Crypt::SaltedHash->validate($user->password, $q->param('password')))
        {
            $db->userLogin($user->id); # Insert login time to database
            my $session = $self->session;
            my $store->{username} = $user->username;
            $store->{type} = $user->type; # if $user->pwchanged;
            $store->{id} = $user->id; # if $user->pwchanged;
            if (my $changed = $user->pwchanged)
            {
                my $now = DateTime->now(time_zone=>'local');
                my $days = $changed->delta_days($now); # Returns object
                my $d = DateTime::Format::Duration->new( pattern => '%e' ); # No of days
                $store->{pwexpired} = 1 if ($d->format_duration($days) > 180);
            } else {
                # Never changed
                $store->{pwexpired} = 1;
            }
            $session->{user} = $store;
            return $user;
        }
        $message = "Incorrect username or password";
    }
    my $display = ADBOS::Display->new($q);
    $display->login($message);
}

sub create($)
{   my ($self, $user) = @_;

    my $pw = $self->randompw;
    my $crypt=Crypt::SaltedHash->new(algorithm=>'SHA-512');
    $crypt->add($pw);
    $user->{password} = $crypt->generate;
    
    my $db = ADBOS::DB->new;
    return $pw if $db->userCreate($user);
    0;
}

sub delete($)
{   my ($self, $user) = @_;
    my $db = ADBOS::DB->new;
    return $db->userDelete($user);
}

sub update($)
{   my ($self, $user) = @_;

    if ($user->{password})
    {
        my $crypt=Crypt::SaltedHash->new(algorithm=>'SHA-512');
        $crypt->add($user->{password});
        $user->{password} = $crypt->generate;
    }
    else
    {	delete $user->{password};
    }
        
    my $db = ADBOS::DB->new;
    return $db->userUpdate($user);
}

sub resetpw($;$)
{   my ($self, $user, $logchange) = @_;

    my $pw = $self->randompw;
    my $crypt=Crypt::SaltedHash->new(algorithm=>'SHA-512');
    $crypt->add($pw);
    my $coded = $crypt->generate;

    my $db = ADBOS::DB->new;
    my $update = { id => $user, password => $coded};
    if ($logchange)
    {
        $update->{pwchanged} = \'NOW()'; # Password changed by user
    }
    else {
        $update->{pwchanged} = undef; # Force pw change on login
    }
        
    return $pw if $db->userUpdate($update);
    0;
}

sub guest($;$)
{   my ($self, $register) = @_;

    my $cookie = $self->{req}->headers_in->{'Cookie'} || '';

    return 1 if $cookie =~ s/.*SYOPS=(.*).*/$1/;
    
    if ($register)
    {
        my $c = CGI::Cookie->new(-name => 'SYOPS',
        -value => '1',
        -expires => '+3M',
        -path => '/'
        );

        return 1 if $self->{req}->headers_out->{'Set-Cookie'} = $c;
    }
    
    return 0;    
}

sub session()
{   my $self = shift;

    return $self->{session} if $self->{session};
    
    # Check for existing session
    my $cookie = $self->{req}->headers_in->{'Cookie'} || '';
    (my $sessionid = $cookie) =~ s/.*SESSION_ID=(\w*).*/$1/;

    # Check if cookie exists, otherwise session borks
    $sessionid = '' unless -f "/tmp/$sessionid";

    my %session;
    if ($sessionid)
    {
        tie %session, 'Apache::Session::File', $sessionid, {
            Directory => '/tmp',
            LockDirectory   => '/var/lock/apache2',
        };
    }

    if (!%session)
    {   
        tie %session, 'Apache::Session::File', undef, {
           Directory => '/tmp',
           LockDirectory   => '/var/lock/apache2',
        } ;
    }

    # Resend the cookie to extend the expiry
    my $c = CGI::Cookie->new(-name => 'SESSION_ID',
      -value => "$session{_session_id}",
      -expires => '+2h',
      -path => '/'
    );
    $self->{req}->headers_out->{'Set-Cookie'} = $c;

    $self->{session} = \%session;
}

sub randompw()
{   my $foo = new String::Random;
    $foo->{'v'} = [ 'a', 'e', 'i', 'o', 'u' ];
    $foo->{'i'} = [ 'b'..'d', 'f'..'h', 'j'..'n', 'p'..'t', 'v'..'z' ];
    scalar $foo->randpattern("iviiviivi");
}

sub logout()
{   my $self = shift;

    my $session = $self->session;
    tied(%$session)->delete;
    $self->{session} = undef;
}

1;
