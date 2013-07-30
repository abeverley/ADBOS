use warnings;
use strict;

package ADBOS::Email;

use ADBOS::Config;
use Mail::Message;
use Mail::Transport::SMTP;

=pod

  ADBOS::DB->new(CONFIG, OPTIONS);

CONFIG (from resend.conf) is used as defaults for OPTIONS, and
can be C<undef>.

OPTIONS:

   name           database name       DBNAME
   user           database user       DBUSER
   password       password of user    DBPASS

=cut

my $config = simple_config;

sub emailPassword($$)
{
    my ($self, $password, $recipient) = @_;

    my $body = << "__EMAIL";
Thank you for registering for an ADBOS account.

Your username is: $recipient
Your password is: $password
__EMAIL
 
    my $subject = 'Your ADBOS password';
    _email($body,$subject,$recipient);
}

sub emailReset($$)
{
    my ($self, $link, $recipient) = @_;

    my $body = << "__EMAIL";
You have requested a password reset. Please follow the link below to receive
a new password. If you did not request this then please ignore this email.

$link
__EMAIL
 
    my $subject = 'ADBOS password reset';
    _email($body,$subject,$recipient);
}

sub emailAccountActivated($$)
{
    my ($self, $link, $recipient) = @_;

    my $body = << "__EMAIL";
Your ADBOS account has now been approved. In order to use your account
you must first perform a password reset using the link below:

$link

Please note: the link can only be used once.
__EMAIL
 
    my $subject = 'ADBOS account approved';
    _email($body,$subject,$recipient);
}

sub emailConfirm($$)
{
    my ($self, $link, $recipient) = @_;

    my $body = << "__EMAIL";
Thank you for registering for an ADBOS account. Please follow the link
below to confirm your email address. Once you have confirmed your email
address, your account request will be reviewed. You will be emailed a
password once your request has been approved.

$link
__EMAIL
 
    my $subject = 'ADBOS account created';
    _email($body,$subject,$recipient);
}

sub emailApprove($$)
{
    my ($self, $link, $user) = @_;

    my $surname = $user->surname;
    my $forename = $user->forename;
    my $email = $user->email;
    my $username = $user->username;
    
    my $body = << "__EMAIL";
The following person has requested an ADBOS account. Please click the 
link to approve the request or delete this email to ignore.

Name: $surname, $forename
Email: $email
Username: $username

$link
__EMAIL

    my $recipient = $config->{email_admin};
    my $subject = 'ADBOS account request';
    _email($body,$subject,$recipient);
}

sub _email($$$)
{
    my ($body, $subject, $recipient) = @_;
    my @opts = (-f => $config->{email_sender});
#    my $mailer = Mail::Transport::Sendmail->new(sendmail_options => \@opts);
    my $mailer = Mail::Transport::SMTP->new(hostname => $config->{smtphost});

    my $msg = Mail::Message->build
       ( From     => $config->{email_sender}
       , To       => $recipient
       , Subject  => $subject
       , data     => $body
       );
    $mailer->send($msg);
}

1;
