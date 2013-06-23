use warnings;
use strict;

package ADBOS::Display;

use Template;

use ADBOS::DB;
use ADBOS::Parse;
use ADBOS::Config;

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
my $db    = ADBOS::DB->new($config);

sub new($$)
{   my ($class, $q) = @_;
    my $self = bless {}, $class;
    $self->{qry} = $q;
    $self;
}

sub standard_template($;$)
{
    my ($file, $vars) = @_;

    my $template = Template->new
       ({INCLUDE_PATH => '/var/www/opdef.andybev.com/templates'});
    $template->process($file, $vars)
          or die "Template process failed: " . $template->error();
    exit;
}

sub login($;$)
{   my ($self, $message) = @_;
    my $vars = { message => $message , title => 'Login' };
    standard_template('login.html', $vars);
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
    
    standard_template($file, $vars);
}

sub opdef($$$;$)
{   my ($self, $user, $opdefs_id, $signals_id) = @_;

    my $q = $self->{qry};

    $db->commentNew($opdefs_id, $user->{id}, $q->param('comment'))
        if $q->param('commentnew');
    
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

    standard_template('opdef.html', $vars);
}

sub brief($$)
{   my ($self, $user, $opdefs_id, $signals_id) = @_;

    my $q = $self->{qry};

    my $tasks = $db->opdefBrief;

    my $vars =
        { tasks => $tasks,
          time => time
        };

    standard_template('brief.html', $vars);
}

sub ship($$$)
{   my ($self, $user, $ships_id) = @_;

    my $q = $self->{qry};
    
    my ($opdefs, $ship, $title, $all);
    my $ships = $db->shipAll;
    if ($ships_id)
    {
        $db->shipTask($ships_id, $q->param('task'))
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
        
        $opdefs = $db->opdefSummary(\%where, { -desc => [qw/type number_year number_serial/] } );
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

    standard_template('ships.html', $vars);
}

sub main($)
{   my ($self, $user) = @_;

    my $file = 'main.html';
    my $vars =
        {
          user  => $user,
          title => 'Automatic Database OPDEF System'
        };
    standard_template($file, $vars);
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
            if (my $pw = $auth->create($nuser))
            {
                $success = "The user was created succesfully with the password <strong>$pw</strong>";
                $action = undef;
            } else {
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
    standard_template($file, $vars);
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

    my @alltasks = $db->taskAll;

    my $file = 'tasks.html';
    my $vars =
        {
          user  => $user,
          tasks => \@alltasks,
          title => 'Tasks'
        };
    standard_template($file, $vars);
}

sub resetpw($$)
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
    } else {
        if ($user->{pwexpired})
        {
            $message = "Your password has expired. Please use the button to reset your password to a new value.";
        } else {
            $message = "Please use the button to reset your password to a new value.";
        }
    }

    my $file = 'resetpw.html';
    my $vars =
        {
          user     => $user,
          error    => $error,
          success  => $success,
          message  => $message,
          title    => 'Reset Password'
        };
    standard_template($file, $vars);
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
        standard_template($file, $vars);
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

  standard_template($file, $vars);
}

sub authenticate($)
{   my ($self, $auth) = @_;
    return if $auth->login;
    standard_template('login.html');
}


1;
