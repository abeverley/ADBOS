use warnings;
use strict;

package ADBOS::DB;

use DBI              ();
use ADBOS::Schema;
use ADBOS::Parse;
use DateTime::Format::Strptime;

=pod

  ADBOS::DB->new(CONFIG, OPTIONS);

CONFIG (from resend.conf) is used as defaults for OPTIONS, and
can be C<undef>.

OPTIONS:

   name           database name       DBNAME
   user           database user       DBUSER
   password       password of user    DBPASS

=cut

sub new($%)
{   my ($class, $global_config, %args) = @_;
#    $config  = $global_config || {};
    my $self = bless {}, $class;
#    my ($dbname, $dbuser, $dbpass) = @{$config}{qw/DBNAME DBUSER DBPASS/};
#    $self->{SB_name} = $args{name}     || $config->{DBNAME};
#    $self->{SB_user} = $args{user}     || $config->{DBUSER};
#    $self->{SB_pass} = $args{password} || $config->{DBPASS};
    $self->{SB_name} = 'opdef';
    $self->{SB_user} = 'opdef';
    $self->{SB_pass} = 'cunteryun';
    $self;
}

sub connect()
{   my $self   = shift;
    my $dbname = $self->{SB_name};

    $self->{sch} = ADBOS::Schema->connect(
      "dbi:mysql:database=$dbname", $self->{SB_user}, $self->{SB_pass}
     , {RaiseError => 1, AutoCommit => 1, mysql_enable_utf8 => 1}
    ) or error __x"unable to connect to database {name}: {err}"
           , name => $dbname, err => $DBI::errstr;

    $self->{sch}->storage->debug(1);
    
    return $self->{sch};
}

sub sch() {my $s = shift; $s->{sch} || $s->connect }

sub opdefSummary($$)
{   my ($self, $search, $sort) = @_;

    my $opdef_rs = $self->sch->resultset('Opdef');
#    my @opdefs = $opdef_rs->search(%$search,
#        { join     => 'ship',
#          order_by => { '-desc' =>  [ 'me.modified' ] }
#        }
#    )->all;

# my $s = [ { -desc => 'category' }, { -desc => 'modified' } ];

    my @opdefs = $opdef_rs->search(%$search,
        { join     => 'ship',
          order_by => $sort,
          rows     => 200
        }
    )->all;

    \@opdefs;
}

sub opdefBrief($)
{   my $self = shift;

    my $task_rs = $self->sch->resultset('Task');

    my @opdefs = $task_rs->search(
        { '-or' => [ 'me.onbrief' => 1, 'opdefs.onbrief' => 1 ],
          '-or' => [ {'opdefs.category' => {'<=' => 7}, 'opdefs.rectified' => 0}
                    ,{'opdefs.category_prev' => {'<=' => 7}, 'opdefs.category_changed' => {'>' => \"DATE_SUB(NOW(), INTERVAL 1 DAY)"} }
                    ,{'opdefs.rectified' => 1, 'opdefs.modified' => {'>' => \"DATE_SUB(NOW(), INTERVAL 1 DAY)"} }
                   ]
        },
        { prefetch => { ships => {opdefs=>['category', 'comments']} },
          order_by => [ { '-asc'  => [qw/me.name ships.name opdefs.category opdefs.number_year opdefs.number_serial/] },
                        { '-desc' => 'comments.time' }
                      ]
        }
    )->all;

    \@opdefs;
}

sub shipGet($)
{   my ($self, $id) = @_;

    my $ship_rs = $self->sch->resultset('Ship');
    $ship_rs->find($id);
}

sub shipTask($)
{   my ($self, $ship, $task) = @_;
    my $ship_rs = $self->sch->resultset('Ship');
    my $s = $ship_rs->find($ship);
    $task = undef if !$task;
    $s->update({ tasks_id => $task }) if $s;
}

sub shipAll()
{   my ($self, $id) = @_;

    my $ship_rs = $self->sch->resultset('Ship');
    my @r = $ship_rs->search({}, {order_by => { '-asc' =>  [ 'me.name' ] } })->all;
    \@r;
}

sub signalProcess($;$$)
{
    # Processes a signal that has already been successfully parsed
    
    my ($self, $values, $status, $signalsid) = @_;
    my $opdefs_id;
    my $shipid = $self->shipByName($values->{ship});
    if (!$shipid)
    {
        if ($shipid = $self->shipNew($values->{ship}))
        {
            $$status = "Ship $values->{ship} added to database"
        } else {
            $$status = "Failed to add ship $values->{ship} to database"
        }
    }
    if ($shipid)
    {
        if ($opdefs_id = $self->opdefStore($values, $shipid))
        {
            if ($values->{format} eq 'RECT')
            {
                if (my $signals_id = $self->signalStore($values->{rawtext}, $opdefs_id, $values->{format}, 0, $signalsid))
                {
                    $$status = "Rectified signal for OPDEF ID $opdefs_id inserted";
                } else {
                    $$status = "Failed to insert rectified signal for OPDEF ID $opdefs_id";
                }
            } elsif ($values->{format} eq 'SITREP')
            {
                if (my $signals_id = $self->signalStore($values->{rawtext}, $opdefs_id, $values->{format}, $values->{sitrep}, $signalsid))
                {
                    $$status = "SITREP for OPDEF ID $opdefs_id inserted";
                } else {
                    $$status = "Failed to insert SITREP for OPDEF ID $opdefs_id";
                }
            } else
            {
                if (my $signals_id = $self->signalStore($values->{rawtext}, $opdefs_id, $values->{format}, $values->{sitrep}, $signalsid))
                {
                    $$status = "Signal for OPDEF ID $opdefs_id inserted";
                } else {
                    $$status = "Failed to insert signal for OPDEF ID $opdefs_id";
                }
            }
        } else {
            $$status = "Unable to store OPDEF. Possible SITREP/RECT to OPDEF that doesn't exist";
        }
    } else {
        $$status = "No ship - failed to add OPDEF";
    }
    $opdefs_id;
}


sub signalOther($;$$)
{
    # Try to process a signal that wasn't parsed
    my ($self, $rawtext, $status, $signalsid) = @_;

    $rawtext =~ s/\r*//g;

    if ($rawtext =~ m!/NAVOPDEF/!)
    {
        $$status = "Found phrase /NAVOPDEF/. Not going to try and parse as other signal.";
        return 0;
    }

    # See if signal is a MATDEM. More restrictive search than the next block
    my $sigtype = 'MATDEM'
        if ($rawtext =~ /^(\h|subject:|subj:|opdef|non-patt)+\h*matdem/im);
    
    # Create a search based on all searchable signal types
    my @sigtypes = $self->sch->resultset('Sigtype')->search({search=>1})->all;
    my @search;
    push @search, $_->name for @sigtypes;
    my $s = join '|', @search;
    $sigtype = $1 if ($rawtext =~ /($s)/);

    my $opdef_rs = $self->sch->resultset('Opdef');
    my $parser = ADBOS::Parse->new();

    my $opdef; # Used for associated OPDEF if found

    # First try signal sender and OPDEF ID
    if (my $values = $parser->otherFm($rawtext))
    {
        ($opdef) = $opdef_rs->search({ number_year   => $values->{number_year},
                                          number_serial => $values->{number_serial},
                                          type          => $values->{type},
                                          'ship.name'   => $values->{ship}
                                         } , { join => 'ship' } );

        $opdef or $$status = sprintf("Failed to find related OPDEF %s %s %s-%s. ", $values->{ship},
            $values->{type}, $values->{number_serial}, $values->{number_year});
    }

    # See what we can glean from the action addressees
    my $values = $parser->otherTo($rawtext);

    if (!$values) {
        $$status = "Failed to find reference to OPDEF" if defined $status;
        return 0;
    }

    my $allships = join ', ', @{$values->{ship}};

    if (!$opdef && $values->{dtg})
    {
        # We've only got a DTG to go on...
        my $dtg = dtgToUnix ($values->{dtg});
        my $signal_rs = $self->sch->resultset('Signal');

        foreach my $ship (@{$values->{ship}})
        {
            my ($signal) = $signal_rs->search({ dtg => $dtg,
                                               'ship.name'   => $ship
                                             } , { join => { opdef => 'ship' } }
                                            );
            if ($signal) { $opdef = $signal->opdef; last }
        }
        if (!$opdef)
        {
            $$status .= sprintf("Failed to find any associated OPDEF for DTG %s for ship(s) %s. ",
                $values->{dtg}, $allships);
            return 0;
        }
    }
    elsif (!$opdef)
    {
        # Easy, we've got an OPDEF number to search for
        foreach my $ship (@{$values->{ship}})
        {
            ($opdef) = $opdef_rs->search({ number_year   => $values->{number_year},
                                           number_serial => $values->{number_serial},
                                           type          => $values->{type},
                                           'ship.name'   => $ship
                                          } , { join => 'ship' } );
            last if $opdef;
        }
        if (!$opdef)
        {
            $$status .= sprintf("Failed to find related OPDEF %s %s %s-%s. ", $allships,
              $values->{type}, $values->{number_serial}, $values->{number_year});
        }
    }
    
    if ($opdef)
    {
        $$status = sprintf("Associated signal with OPDEF %s %s %s-%s", $opdef->ship->name,
          $opdef->type, $opdef->number_serial, $opdef->number_year);
        return $self->signalStore($rawtext, $opdef->id, $sigtype, undef, $signalsid);
    }

    0;
}


sub opdefStore($$)
{   my ($self, $opdefin, $ships_id) = @_;

    return if !$ships_id;
    my $opdefs_id;
    my %newdata;
    # Pick out only the required fields to update
    my @fields = qw(type number_serial number_year category erg_code parent_equip defective_unit
                          line5 defect repair_int assistance assistance_port matdem remarks);
    @newdata{@fields} = undef;
    @newdata{ keys %newdata } = @$opdefin{ keys %newdata };

    # Get the ID of the category
    my $category_rs = $self->sch->resultset('Category');
    my $c = $category_rs->find($opdefin->{category}, { key => 'name' });
    $newdata{category} = $c->id if $c;
                
    my $opdef_rs = $self->sch->resultset('Opdef');

    if ($opdefin->{format} eq 'SITREP')
    {
        my ($opdef) = $opdef_rs->search({ number_year   => $opdefin->{number_year},
                                          number_serial => $opdefin->{number_serial},
                                          type          => $opdefin->{type},
                                          ships_id      => $ships_id
                                         });
        $opdefs_id = $opdef->id if $opdef;

        if ($opdefs_id)
        {
            # First check that the SITREP number is greater than existing ones
            my $signals_rs = $self->sch->resultset('Signal');
            my $signal = $signals_rs->search({ opdefs_id => $opdefs_id });

            if ($signal->count && $opdefin->{sitrep} > $signal->get_column('sitrep')->max)
            {
                # Only update ODPEF if sitrep is greater
                # Check change of category
                $opdef->update({ category_prev => $opdef->category, category_changed => \'NOW()' })
                    if ($newdata{category} ne $opdef->category);
                $opdef->update(\%newdata);
#                $opdef->update({ modified => \'NOW()' });
            }
        } else {
            # OPDEF not found. Insert instead.
            $newdata{ships_id} = $ships_id;
            $opdefs_id = $opdef_rs->create(\%newdata)->id;
            my $opdef = $opdef_rs->find($opdefs_id);
#            $opdef->update({ modified => \'NOW()' });
        }
    }
    elsif($opdefin->{format} eq 'OPDEF')
    {
        # Check whether it's been received already
        # SITREP might have been received first
        # Search on same ERG code in case of mistake by sender
        my ($opdef) = $opdef_rs->search({ number_year   => $opdefin->{number_year},
                                          number_serial => $opdefin->{number_serial},
                                          type          => $opdefin->{type},
                                          ships_id      => $ships_id,
                                          erg_code      => $opdefin->{erg_code}
                                         });
        $opdefs_id = $opdef->id if $opdef;

        if (!$opdefs_id)
        {
            $newdata{ships_id} = $ships_id;
            $opdefs_id = $opdef_rs->create(\%newdata)->id;
            $opdef = $opdef_rs->find($opdefs_id);
        }
#        $opdef->update({ modified => \'NOW()' });
    }
    elsif($opdefin->{format} eq 'RECT')
    {
        my ($opdef) = $opdef_rs->search({ number_year   => $opdefin->{number_year},
                                          number_serial => $opdefin->{number_serial},
                                          type     => $opdefin->{type},
                                          ships_id => $ships_id
                                         });
        $opdefs_id = $opdef->id if $opdef;

        if ($opdefs_id)
        {
            $opdef->update({ rectified => 1 });
#            $opdef->update({ modified => \'NOW()' });
        }
    }
    $opdefs_id;
}

sub signalStore($$;$$$)
{   my ($self, $content, $opdefs_id, $sigtype, $sitrep, $id) = @_;

    $content =~ s/\r*//g;
    
    # Attempt to get DTG
    my $dtg = dtgToUnix($1)
        if ($content =~ m/([0-9]{6}.\h[A-Z]{3}\h[0-9]{2})[A-Z^\s]+FM\h/);

    my ($orig) = ($content =~ m/^FM\h*([A-Z0-9\h]*)$/mi);

    my $sigtype_rs = $self->sch->resultset('Sigtype');
    my $s = $sigtype_rs->find($sigtype, { key => 'name' }) if $sigtype;
    my $ss = $s->id if $s;
    
    my $data = { content => $content, opdefs_id => $opdefs_id, sigtype => $ss, sitrep => $sitrep, dtg => $dtg, originator => $orig };
    my $signal_rs = $self->sch->resultset('Signal');

    if ($id)
    {
        $signal_rs->find($id)->update($data);
    } 
    else {
        $id = $signal_rs->create($data)->id;
    }

    # Finally, update OPDEF modified time
    my $opdef_rs = $self->sch->resultset('Opdef');
    my $opdef = $opdef_rs->find($opdefs_id) if $opdefs_id;
    $opdef->update({ modified => \'NOW()' }) if $opdef;

    $id;
}

sub dtgToUnix($)
{
    my $parser = DateTime::Format::Strptime->new(
        pattern => '%d%H%MZ %b %y'
    );
    $parser->parse_datetime(shift);
}

sub matdemStore($)
{   my ($self, $content) = @_;
    my $matdem_rs = $self->sch->resultset('Matdem');
    $matdem_rs->create({ content => $content })->id;
}

sub userCreate($)
{   my ($self, $user) = @_;
    my $user_rs = $self->sch->resultset('User');
    $user_rs->create( $user )->id;
}

sub userUpdate($)
{   my ($self, $user) = @_;
    my $user_rs = $self->sch->resultset('User');
    my $u = $user_rs->find( $user->{id} );
    $u->update($user) if $u;
}

sub userLogin($)
{   my ($self, $user) = @_;
    my $user_rs = $self->sch->resultset('User');
    my $u = $user_rs->find({ id => $user, deleted => 0 });
    $u->update({ lastlogin => \'NOW()'}) if $u;
}

sub userDelete($)
{   my ($self, $user) = @_;
    my $user_rs = $self->sch->resultset('User');
    my $u = $user_rs->find( $user );
    $u->update({ deleted => 1 }) if $u;
}

sub userGet($)
{   my ($self, $user) = @_;
    my $user_rs = $self->sch->resultset('User');
    
    my $u;
    ($u) = $user_rs->search({ username => $user->{username}, deleted => 0 })
        if $user->{username};
    ($u) = $user_rs->search({ id => $user->{id}, deleted => 0 })
        if $user->{id};
    $u;
}

sub userAll()
{   my $self = shift;
    my $user_rs = $self->sch->resultset('User');
    $user_rs->search({ deleted => 0 })->all;
}

sub taskAll()
{   my $self = shift;
    my $task_rs = $self->sch->resultset('Task');
    $task_rs->search({}, {order_by => { '-asc' =>  [ 'me.name' ] }, prefetch => 'ships' })->all;
}

sub taskAddBrief($)
{   my ($self,$id) = @_;
    my $task_rs = $self->sch->resultset('Task');
    my $t = $task_rs->find($id) if $id;
    $t->update({ onbrief => 1 }) if $t;
}

sub taskRemoveBrief($)
{   my ($self,$id) = @_;
    my $task_rs = $self->sch->resultset('Task');
    my $t = $task_rs->find($id) if $id;
    $t->update({ onbrief => 0 }) if $t;
}

sub taskNew($)
{   my ($self,$name) = @_;
    my $task_rs = $self->sch->resultset('Task');
    $task_rs->create({ name => $name })->id;
}

sub commentNew($$$)
{   my ($self,$opdefs_id,$users_id,$comment) = @_;
    my $comment_rs = $self->sch->resultset('Comment');
    $comment_rs->create({ comment   => $comment,
                          opdefs_id => $opdefs_id,
                          users_id  => $users_id,
                          time      => \'NOW()'
                        })->id;
}

sub commentGet($)
{   my ($self, $opdefs_id) = @_;
    my $comment_rs = $self->sch->resultset('Comment');
    $comment_rs->search( { opdefs_id => $opdefs_id },
                         { prefetch  => 'user',
                           order_by  => 'me.time'
                         }
                       )->all;
}


sub shipNew($)
{   my ($self, $name) = @_;
    my $ship_rs = $self->sch->resultset('Ship');
    $ship_rs->create({ name => $name })->id;
}

sub opdefSetBrief($$)
{   my ($self, $opdefs_id, $onbrief) = @_;
    $onbrief = $onbrief ? 1 : 0;
    my $opdef_rs = $self->sch->resultset('Opdef');
    my $opdef = $opdef_rs->find($opdefs_id);
    $opdef->update({ onbrief => $onbrief }) if $opdef;
}

sub signalAssociateOpdef($$)
{   my ($self, $signals_id, $opdefs_id) = @_;
    my $signal_rs = $self->sch->resultset('Signal');
    $signal_rs->find($signals_id)->update({ opdefs => $opdefs_id });
}

sub signalDelete($)
{   my ($self, $signals_id) = @_;
    my $signal_rs = $self->sch->resultset('Signal');
    my $sig = $signal_rs->find($signals_id);
    $sig->delete if $sig;
}

sub signalGet($;$)
{   my ($self, $id, $unparsed) = @_;

    my $sig;
    my $signal_rs = $self->sch->resultset('Signal');
    if ($unparsed)
    {
        ($sig) = $signal_rs->search({ id => $id, opdefs_id => undef });
    } else {
        $sig = $signal_rs->find($id);
    }
    $sig;
}
 
sub unparsedFirst()
{   my $self = shift;
    my $signal_rs = $self->sch->resultset('Signal');
    my ($sig) = $signal_rs->search({ opdefs_id => undef }, { rows => 1, order_by => { '-asc' =>  [ 'me.id' ] }});
    return 0 if !$sig;
    $sig->id;
}
 
sub shipByName($)
{   my ($self, $name) = @_;
    my $ship_rs = $self->sch->resultset('Ship');
    my ($ship) = $ship_rs->search({ name => $name });
    return 0 if !$ship;
    $ship->id;
}

sub opdefGet($)
{   my ($self, $opdefs_id) = @_;

    my $opdef_rs = $self->sch->resultset('Opdef');
    my ($opdefs) = $opdef_rs->search({ 'me.id' => $opdefs_id },
      { prefetch => {signals => 'sigtype'},
        order_by => 'signals.dtg'
      }
    );
    $opdefs;
}

sub signalsFailed()
{   my ($self) = @_;
    my $signal_rs = $self->sch->resultset('Signal');
    my @failed = $signal_rs->search({ opdefs_id => undef }
                                  , { order_by => { '-asc' =>  [ 'me.id' ] }})->all;
    \@failed;
}


1;
