use warnings;
use strict;

package ADBOS::Display;

use Template;

use ADBOS::DB;
use ADBOS::Parse;
use ADBOS::Config;
use ADBOS::Email;
use Email::Valid;

my $config = simple_config;
my $db     = ADBOS::DB->new($config);

sub new($$)
{   my ($class, $q) = @_;
    my $self = bless {}, $class;
    $self->{qry} = $q;
    $self;
}

sub status($$)
{   my ($self,$status) = @_;
    $self->{status} = $status if $status;
    $self->{status};
}

sub _standard_template($;$)
{
    my ($self, $file, $vars) = @_;

    $vars->{status} = $self->{status};
    $vars->{time}   = time;
    $vars->{signal_timeout} = $config->{signal_timeout};
    my $template = Template->new
       ({INCLUDE_PATH => "$config->{wwwdir}/templates"});
    $template->process($file, $vars)
          or die "Template process failed: " . $template->error();
    exit;
}

sub login($;$)
{   my ($self, $message) = @_;
    my $vars = { message => $message , title => 'Login' };
    $self->_standard_template('login.html', $vars);
}

sub summary($$)
{   my ($self, $user) = @_;

    my $q = $self->{qry};
    
    my %fields = ( type => "Type (eg. ME)"
                  ,category => "Category (eg. B2)"
                  ,erg_code => "ERG Code"
                  ,parent_equip => "Parent equipment"
                  ,defective_unit => "Defectived unit"
                  ,line5 => "Line 5"
                  ,defect => "Defect description"
                  ,repair_int => "Repair intentions"
                  ,assistance => "Assistance required"
                  ,assistance_port => "Port for assistance"
                  ,matdem => "MATDEM DTG"
                  ,rectified => "Rectified (0 or 1)"
                  ,name => "Ship"
                  ,modified => "Modified time"
                 );


    # Is there a better way of doing this?
    # Build up the search query by looking for all the field/value
    # pairs in the URL. Each field/value pair is identified by a
    # suffix number. Eg. field1=erg_code, value1=CBG
    my %search;

    foreach my $field ($q->param)
    {  if ($field =~ /field([0-9]+)/)
       {
         # $1 contains the suffix number of the pair
         $search{$q->param($field)} = $q->param("value$1")
           if $q->param("value$1");
       }
    }

    $search{'-or'} = 
      [
        rectified => 0,
        modified => { '>' => \"DATE_SUB(NOW(), INTERVAL 2 DAY)" },
      ];

    $search{'onbrief'} = 1
        if $q->param('onbrief');


#    $search{'rectified'} = 0
#        if !defined($search{'rectified'});

    my @sort;
    foreach my $field ($q->param)
    {  if ($field =~ /sort([0-9]+)/ && $q->param($field))
       {
          my $order = ($q->param($field) eq 'modified') ? '-desc' : '-asc';
          push @sort, { $order => $q->param($field) };
       }
    }
    push @sort, { -desc => 'modified' } if !@sort;
    
    my $file = 'summary.html';
    my $opdefs = $db->opdefSummary(\%search, \@sort);
    my $vars = { opdefs => $opdefs,
                 search => \%search,
                 fields => \%fields,
                 sort => \@sort,
                 user => $user,
                 title  => 'OPDEF Summary'
               };
    
    $self->_standard_template($file, $vars);
}

sub opdef($$$;$)
{   my ($self, $user, $opdefs_id, $signals_id) = @_;

    my $q = $self->{qry};

    $db->commentNew($opdefs_id, $user->{id}, $q->param('comment'))
        if $q->param('commentnew');
    
    $db->signalDelete($signals_id)
        if $q->param('deletesig');
    
    $db->opdefSetBrief($opdefs_id, $q->param('onbrief'))
        if defined $self->{qry}->param('onbrief')
        && ($user->{type} eq 'member' || $user->{type} eq 'admin');
    
    my $opdef = $db->opdefGet($opdefs_id);
    
    $self->main if !$opdef;

    my $signal = $db->signalGet($signals_id) if $signals_id;
    my @comments = $db->commentGet($opdefs_id) if !$signals_id;

    my $title = sprintf("%s %s %s-%s", $opdef->ship->name, $opdef->type,
                                       $opdef->number_serial, $opdef->number_year);
    
    my $vars =
        { opdef    => $opdef,
          signal   => $signal,
          user     => $user,
          comments => \@comments,
          title    => $title
        };

    $self->_standard_template('opdef.html', $vars);
}

sub brief()
{   my $self   = shift;
    my $period = shift || 1;

    $period = int $period; # Should be sanitised on input, but just in case...
    my $q = $self->{qry};

    my $tasks = $db->opdefBrief($period);

    my $vars =
        { tasks  => $tasks,
          period => ($period || 1)
        };

    $self->_standard_template('brief.html', $vars);
}

sub ship($$$)
{   my ($self, $user, $ships_id) = @_;

    my $q = $self->{qry};
    
    my ($opdefs, $ship, $title, $all);
    my $ships = $db->shipAll;
    if ($ships_id)
    {
        my $values = { tasks_id  => ($q->param('task') || undef)
                      ,programme => $q->param('programme')
                      ,priority  => $q->param('priority')
                     };
        $db->shipUpdate($ships_id, $values)
            if $q->param('shipupdate');
        
        my %where;
        if ($self->{qry}->param('all'))
        {
            %where = (
              ships_id => $ships_id
            );
            $all = 1;
        }
        else {
            %where = (
              -or => [
                rectified => 0,
                modified => { '>' => \"DATE_SUB(NOW(), INTERVAL 2 DAY)" },
              ],
              ships_id => $ships_id
            );
        }
        
        $opdefs = $db->opdefSummary(\%where, [ { -asc => 'type' },{ -desc => [qw/number_year number_serial/] } ] );
        $ship = $db->shipGet($ships_id);
        $title = "OPDEF summary for ".$ship->name;
    }
    else {
        $title = "OPDEFs: View all units";
    }
    
    my @tasks = $db->taskAll;
    
    my $vars =
        { ships  => $ships,
          opdefs => $opdefs,
          ship   => $ship,
          all    => $all,
          user   => $user,
          tasks  => \@tasks,
          title  => $title
        };

    $self->_standard_template('ships.html', $vars);
}

sub main($)
{   my ($self, $user) = @_;

    my $file = 'main.html';
    my $vars =
        {
          user  => $user,
          title => 'Automatic Database OPDEF System'
        };
    $self->_standard_template($file, $vars);
}

sub users($$;$)
{   my ($self,$user,$auth,$userview) = @_;

    my $q = $self->{qry};
    my @errors; my $success; my $action; my $nuser;
    my $title = 'View all users';

    if ($userview)
    {
        if (my $u = $db->userGet({id => $userview}))
        {
            $action = 'view';
            $nuser->{id} = $u->id;
            $nuser->{type} = $u->type;
            $nuser->{username} = $u->username;
            $nuser->{forename} = $u->forename;
            $nuser->{surname} = $u->surname;
            $nuser->{email} = $u->email;
            $title = "View user ".$u->username;
        }
    }
    
    if ($q->param('new'))
    {
        $action = 'create';
        $title = 'Create new user';
    }

    if ($q->param('create') || $q->param('update'))
    {
        $nuser->{type} = $q->param('type')
            or push @errors, "Please select a type";
        $nuser->{username} = $q->param('username')
            or push @errors, "Please enter a username";
        $nuser->{surname} = $q->param('surname')
            or push @errors, "Please enter a surname";
        $nuser->{forename} = $q->param('forename')
            or push @errors, "Please enter a forename";
        $nuser->{email} = $q->param('email')
            or push @errors, "Please enter an email address";

        push @errors, "The username already exists"
            if $q->param('create')
            && $db->userGet({ username => $nuser->{username} });
    }

    if (!@errors &&
            ($q->param('create') || $q->param('update') || $q->param('delete') || $q->param('resetpw'))
        )
    {
        if ($q->param('create'))
        {
            $user->{password} = $auth->password;
            if(db->userCreate($nuser))
            {
                $success = "The user was created succesfully with the password <strong>$user->{password}</strong>";
                $action = undef;
            }
            else {
                $action = 'create';
                push @errors, "There was an error creating the user";
            }
        } elsif ($q->param('update'))
        {
            if ($auth->update($nuser))
            {
                $success = "The user was updated succesfully";
                $action = undef;
            } else {
                $action = 'update';
                push @errors, "There was an error updating the user";
            }
        } elsif ($q->param('delete'))
        {
            if ($auth->delete($userview))
            {
                $success = "The user was deleted succesfully";
                $action = undef;
            } else {
                $action = 'update';
                push @errors, "There was an error deleting the user";
            }
        } elsif ($q->param('resetpw'))
        {
            if (my $pw = $auth->resetpw($userview))
            {
                $success = "The user's password has been reset to <strong>$pw</strong>";
                $action = undef;
            } else {
                $action = 'update';
                push @errors, "There was an error resetting the password";
            }
        }
    }

    my @allusers = $db->userAll;

    my $file = 'users.html';
    my $vars =
        {
          user     => $user,
          nuser    => $nuser,
          errors   => \@errors,
          success  => $success,
          action   => $action,
          allusers => \@allusers,
          title    => $title
        };
    $self->_standard_template($file, $vars);
}

sub tasks($$;$)
{   my ($self,$user,$auth,$taskview) = @_;

    my $q = $self->{qry};

    $db->taskNew($q->param('name'))
        if $q->param('new');

    $db->taskAddBrief($q->param('add'))
        if $q->param('add');

    $db->taskRemoveBrief($q->param('remove'))
        if $q->param('remove');

    if ($q->param('update'))
    {
        foreach my $p ($q->param)
        {
            $db->taskUpdate($1, { ordering => $q->param($p) })
                if ( $p =~ /ordering([0-9]+)/);
        }
    }

    my @alltasks = $db->taskAll;

    my $file = 'tasks.html';
    my $vars =
        {
          user  => $user,
          tasks => \@alltasks,
          title => 'Tasks'
        };
    $self->_standard_template($file, $vars);
}

# Used to manage individual account
sub myAccount($$)
{   my ($self,$user,$auth) = @_;

    my $q = $self->{qry};

    my ($success, $error, $message);
    if ($q->param('resetpwself'))
    {
        if (my $pw = $auth->resetpw($user->{id}, 1))
        {
            $success = "Your password has been reset to <strong>$pw</strong>.
                        Click the button again if you would like a different password.";
            $user->{pwexpired} = 0;
            # Update top-level session variable to ensure $user is stored
            $auth->session->{time} = time;
        } else {
            $error = "There was an error resetting your password";
        }
    } elsif ($q->param('update'))
    {
        # Need hash with only some of user's keys
        my $u->{id} = $user->{id};
        $u->{surname} = $q->param('surname');
        $u->{forename} = $q->param('forename');
        if ($db->userUpdate($u))
        {
            $success = "Your details have been updated successfully";
            # Update session variable
            $user->{surname} = $u->{surname};
            $user->{forename} = $u->{forename};
            # Update top-level session variable to ensure $user is stored
            $auth->session->{time} = time;
        } else {
            $error = "There was an error updating your details";
        }
    } else {
        if ($user->{pwexpired})
        {
            $message = "Your password has expired. Please reset it using the button below.";
        }
    }

    my $file = 'myaccount.html';
    my $vars =
        {
          error    => $error,
          user     => $user,
          success  => $success,
          message  => $message,
          title    => 'Manage Account'
        };
    $self->_standard_template($file, $vars);
}

# Used to perform a password reset using an emailed link
sub pwResetFromCode($)
{   my ($self,$code) = @_;

    my $auth = ADBOS::Auth->new;
    
    my ($success, $error);
    if (my $user = $db->resetpwGet($code))
    {
        if (my $password = $auth->resetpw($user->id, 1))
        {
            $success = "Your password has been reset to $password";
            $db->resetpwClear($code); # Stop reset code being reused
        } else {
            $error = "Failed to reset password";
        }
    } else
    {
        $error = "Code was not found in database. Please try again.";
    }

    my $file = 'message.html';
    my $vars =
        {
          error    => $error,
          success  => $success,
          title    => 'Reset Password'
        };
    $self->_standard_template($file, $vars);
}

# Used to request a password reset via link in email
sub pwResetRequestEmail($)
{   my ($self) = @_;

    my $q = $self->{qry};
    my ($success, $message, $error);

    if ($q->param('email'))
    {
        my $email = $q->param('email');
        my $code = $db->resetpwCreate($email);
        
        if ($code)
        {
            my $link = "http://$config->{server}/reset/$code";
            ADBOS::Email->emailReset($link,$email);
            $success = "An email has been sent to your email address. Please follow the link
                        contained within it in order to reset your password.";
        }
        else {
            $error = "There was an error generating a reset code. Have you entered your
                      correct email address?";
        }
    } else
    {
        $message = "Please enter your registered email address below and click submit";
    }
    
    my $file = 'emailpw.html';
    my $vars =
        {
          message  => $message,
          error    => $error,
          success  => $success,
          title    => 'Reset Password'
        };
    $self->_standard_template($file, $vars);
}

# Used for users to register themselves
sub accountRegister($$;$)
{   my ($self,$user) = @_;

    my $q = $self->{qry};
    my @errors; my $success; my $nuser;

    my $auth = ADBOS::Auth->new;
    
    if ($q->param('create'))
    {
        $nuser->{surname} = $q->param('surname')
            or push @errors, "Please enter a surname";
        $nuser->{forename} = $q->param('forename')
            or push @errors, "Please enter a forename";
        $nuser->{email} = $q->param('email')
            or push @errors, "Please enter an email address";
        $nuser->{username} = $q->param('email');
        $nuser->{type} = 'viewer';

        push @errors, 'Please enter a valid email address (eg your-role@mod.uk).'
            unless (Email::Valid->address($nuser->{email}));
    }

    if (!@errors && $q->param('create'))
    {
        my $errortxt;
        if (my $id = $db->userCreate($nuser, \$errortxt))
        {
            my $code = $db->userRequestCode($id);
            if ($code)
            {
                my $link = "http://$config->{server}/confirm/$code";
                ADBOS::Email->emailConfirm($link,$nuser->{email});
                $success = "An email has now been sent to you. Please follow the link
                            contained within it in order to confirm your email address.";
            } else
            {
                push @errors, "Your account was created succesfully but there was an error
                                emailing your confirmation email.";
            }
        } else {
            push @errors, "There was an error creating the user: $errortxt";
        }
    }

    my $file = 'register.html';
    my $vars =
        {
          nuser    => $nuser,
          errors   => \@errors,
          success  => $success,
          title    => 'Account registration'
        };
    $self->_standard_template($file, $vars);
}

# Used for users to confirm their email address
sub accountEmailConfirm($)
{   my ($self, $code) = @_;

    my ($success, $error);

    if (my $user = $db->userConfirm($code))
    {
        $success = "Thank you, your email address has been confirmed. Your account
                      request will now be sent for FOMO team approval.";
        my $c = $db->userRequestApproval($user->id);
        my $link = "http://$config->{server}/approve/$c";

        ADBOS::Email->emailApprove($link,$user);
        
    } else
    {
        $error = "There was an error locating your confirmation code or
                    confirming your account";
    }
    
    my $file = 'message.html';
    my $vars =
        {
          error    => $error,
          success  => $success,
          title    => 'Confirm email address'
        };
    $self->_standard_template($file, $vars);
}

# Used to approve an account request
sub accountApprove($)
{   my ($self, $code, $user) = @_;
    my ($success, $error);

    my $u = $db->userApprove($code);
    
    if ($u) {
        $success = "The user's request has been approved.";
        # Generate code for password reset and email to user
        my $c = $db->resetpwCreate($u->email);
        my $link = "http://$config->{server}/reset/$c";
        ADBOS::Email->emailAccountActivated($link,$u->email);
    }
    else {
        $error = "There was an error approving the request.";
    }

    my $file = 'message.html';
    my $vars =
        {
          error   => $error,
          success => $success,
          user    => $user,
          title   => 'Approve account request'
        };
    $self->_standard_template($file, $vars);
}

sub syops($)
{   my ($self, $auth) = @_;

    my $q = $self->{qry};
    if ($q->param('syops'))
    {   # User has accepted syops
        return $auth->guest(1);
    }
    else
    {
        my $file = 'syops.html';
        my $vars = {title  => 'Agree to SyOps'};
        $self->_standard_template($file, $vars);
    }
}


sub unparsed($$)
{
  my ($self, $user, $id) = @_;
  my $q = $self->{qry};
  
  my $status; my $error;
  if ($q->param('retry'))
  {
      my $parser = ADBOS::Parse->new();
      if (my $values =  $parser->parse($q->param('signal')))
      {
          $error = 1 unless $db->signalProcess($values, \$status, $id);
          $id = 0 if !$error;
      } elsif ($db->signalOther($q->param('signal'), \$status, $id))
      {
          $id = 0; # Force pull of next unparsed signal
      }
      else 
      {   $status = "Parsing failed - please try again" if !$status;
          $error = 1;
      }
  }


  if ($q->param('delete'))
  {
      $db->signalDelete($id);
      $id = 0; # Force next signal to be pulled
  }

  $id = $db->unparsedFirst if !$id;

  # Show the user submitted signal if applicable, otherwise get from database
  my $view = ($q->param('retry') && $error) ?
             { id => $id, content => $q->param('signal') }
           : $db->signalGet($id, 1);
  my $signals = $db->signalsFailed;
  my $file = 'unparsed.html';
  my $vars = { signals => $signals
              ,title  => 'Signals not parsed'
              ,view => $view
              ,error => $status
              ,user => $user
             };

  $self->_standard_template($file, $vars);
}

sub signalNew($)
{
  my ($self, $user) = @_;
  my $q = $self->{qry};
  my $status; my $error;
  if ($q->param('retry'))
  {
      my $parser = ADBOS::Parse->new();
      if (my $values =  $parser->parse($q->param('signal')))
      {
          $error = 1 unless $db->signalProcess($values, \$status);
      } elsif ($db->signalOther($q->param('signal'), \$status))
      {
      }
      else 
      {   $status = "Parsing failed - please try again" if !$status;
          $error = 1;
      }
  }

  # Show the user submitted signal if applicable, otherwise get from database
  my $view = ($q->param('retry') && $error) ?
             { content => $q->param('signal') }
           : { content => '' }; # Stop error message being shown
  my $signals = $db->signalsFailed;
  my $file = 'unparsed.html';
  my $vars = { signals => $signals
              ,title  => 'Signals not parsed'
              ,view => $view
              ,error => $status
              ,user => $user
             };

  $self->_standard_template($file, $vars);
}

sub authenticate($)
{   my ($self, $auth) = @_;
    return if $auth->login;
    $self->_standard_template('login.html');
}


1;
