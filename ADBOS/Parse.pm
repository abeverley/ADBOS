use warnings;
use strict;

package ADBOS::Parse;

use 5.010;
use Data::Dumper;

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
{   my ($class, %args) = @_;
    my $self = bless {}, $class;
    $self->{var1} = 'Value';
    $self;
}

sub parse()
{   my ($self, $message) = @_;

    my %values;
    $message =~ s/\r*//g; # Remove any nasty carriage-returns

#                       REF .* NAVOPDEF (.|\n)*                                                    # Assume SITREP
    return 0 if $message !~ m/(?<dtg>[0-9]{6}.\h[A-Z]{3}\h[0-9]{2}).*(^|\n)+FM\h*(?<ship>.*)\n/i;
    $values{ship} = $+{ship};
    $values{dtg} = $+{dtg};

    if ($message =~ m% [.\n]*?
                       \n(OPDEF|DEFREP)\h*/?\h*    (?<type>ME|WE|AR|OP)[\h/]*0*
                                            (?<number_serial>[0-9]+)
                                            [-\h/]+
                                            (?<number_year>[0-9]+)
                                            .*?      # OPDEF number
                                             \h*(SITREP|SIT)\h*(?<sitrep>[0-9A-Z]*)\.?                    # SITREP number
                         \n?.*\n?.*                                                                 # Allow 2 lines of nonsense
                       \n\h*\^?[AMPN/\.\h]{0,8}1\.?.*?        (?<category>A1|A2|A3|A4|B1|b2|B3|B4|C1|C2|C3|C4).*?  # Category
                       \n(\^|\h)*2\h*\.?\h*        (?<erg_code>.*?)\.?                                      # ERG code
                       \n(\^|\h)*3\h*\.?\h*        (?<parent_equip>(.|\n)*?)                                  # Parent equipment
                       \n(\^|\h)*4\h*\.?\h*        (?<defective_unit>(.|\n)*?)                                # Defective unit
                       \n(\^|\h)*5\h*\.?\h*        (?<line5>(.|\n)*?)                                   # Line 5
                       (\n(\^|\h)*6\h*\.?\h*       (?<defect>(.|\n)*?))?                                # Technical description
                       (\n(\^|\h)*7\h*\.?\h*       (?<repair_int>(.|\n)*?))?                            # Repair proposals
                       (\n(\^|\h)*8\h*\.?\h*       (?<assistance>(.|\n)*?))?                            # Assistance required
                       (\n(\^|\h)*9\h*\.?\h*       (?<assistance_port>(.|\n)*?))?                            # Where assistance
                       (\n(\^|\h)*10\h*\.?\h*      (?<matdem>.*?))?                                     # MATDEM
                       \s*\^?(FFFF)?
                       \n\^?(RMKS|1[A-Z]?\.)/?(?<remarks>(.|\n)*)
                    %ix)
    {
        $values{format} = 'SITREP';
        $values{type} = $+{type};
        $values{number_serial} = $+{number_serial};
        $values{number_year} = $+{number_year};
        $values{sitrep} = $+{sitrep};
        $values{category} = $+{category};
        $values{erg_code} = $+{erg_code};
        $values{parent_equip} = $+{parent_equip};
        $values{defective_unit} = $+{defective_unit};
        $values{line5} = $+{line5};
        $values{defect} = $+{defect};
        $values{repair_int} = $+{repair_int};
        $values{assistance} = $+{assistance};
        $values{assistance_port} = $+{assistance_port};
        $values{matdem} = $+{matdem};
        $values{remarks} = $+{remarks};
        $values{rawtext} = $message;
        \%values;   
    }
    elsif ($message =~ m% [.\n]*?
                       \n(OPDEF|DEFREP)\h*/?\h*     (?<type>ME|WE|AR|OP)[\h/]*  # OPDEF number
                                            (?<number_serial>[0-9]+)
                                            [-\h/]+
                                            (?<number_year>[0-9]+)
                                            .*?      # OPDEF number
                         \n?.*\n?.*                                                                 # Allow 2 lines of nonsense
                       \n\h*\^?[AMPN/\.\h]{0,8}1\.?.*?     (?<category>A1|A2|A3|A4|B1|b2|B3|B4|C1|C2|C3|C4).*?    # Category
                       \n(\^|\h)*2\h*\.?\h*     (?<erg_code>.*?)\.?                                        # ERG code
                       \n(\^|\h)*3\h*\.?\h*     (?<parent_equip>(.|\n)*?)                                    # Parent equipment
                       \n(\^|\h)*4\h*\.?\h*     (?<defective_unit>(.|\n)*?)                                  # Defective unit
                       \n(\^|\h)*5\h*\.?\h*     (?<line5>(.|\n)*?)                                      # Line 5
                       \n(\^|\h)*6\h*\.?\h*     (?<defect>(.|\n)*?)                                     # Technical description
                       \n(\^|\h)*7\h*\.?\h*     (?<repair_int>(.|\n)*?)                                 # Repair proposals
                       (\n(\^|\h)*8\h*\.?\h*     (?<assistance>(.|\n)*?))?                                # Assistance required
                       (\n(\^|\h)*9\h*\.?\h*    (?<assistance_port>(.|\n)*?))?                              # Where assistance
                       (\n(\^|\h)*10\h*\.?\h*   (?<matdem>.*?))?                                       # MATDEM
                       \s*\^?(FFFF)?
                       \s+\^?(RMKS|1[A-Z]?\.)/?(?<remarks>(.|\n)*)
                    %ix)
    {
        $values{format} = 'OPDEF';
        $values{type} = $+{type};
        $values{number_serial} = $+{number_serial};
        $values{number_year} = $+{number_year};
        $values{sitrep} = 0;
        $values{category} = $+{category};
        $values{erg_code} = $+{erg_code};
        $values{parent_equip} = $+{parent_equip};
        $values{defective_unit} = $+{defective_unit};
        $values{line5} = $+{line5};
        $values{defect} = $+{defect};
        $values{repair_int} = $+{repair_int};
        $values{assistance} = $+{assistance};
        $values{assistance_port} = $+{assistance_port};
        $values{matdem} = $+{matdem};
        $values{remarks} = $+{remarks};
        $values{rawtext} = $message;
        \%values;   
    }
    elsif ($message =~ m% [.\n]*?
                         (OPDEF|DEFREP)\h*/?[-\hA-Z]*?    (?<type>ME|WE|AR|OP)[\h/]*      # OPDEF number
                                            (?<number_serial>[0-9]+)
                                            [-\h/]+
                                            (?<number_year>[0-9]+)
                                            (.*?|\n?)      # OPDEF number
                                               \h+(RECT|RECTIFIED|CANCEL)\h*(?<rectdate>[0-9A-Z\h]*)\.?
                         \n?.*\n?.*                                                                 # Allow 2 lines of nonsense
                         \n\h*\^?[AMPN/\.\h]{0,8}1\.?        (?<erg_code>.*?)\.?                                      # ERG code
                         \n\h*2\h*\.?\h*        (?<parent_equip>(.|\n)*?)                                  # Parent equipment
                         \n\h*3\h*\.?\h*        (?<defective_unit>(.|\n)*?)                                # Defective unit
                         (\n\h*4\h*\.?\h*       (?<line4>(.|\n)*?))?                                 # XXXX To be updated
                         (\n\h*5\h*\.?\h*       (?<line5>(.|\n)*?))?                                 # XXXX To be updated
                         (\n\h*6\h*\.?\h*       (?<line6>(.|\n)*?))?                                 # XXXX To be updated
                         \s*\^?(FFFF)?
                         \s?\^?(RMKS)?/?(?<remarks>(.|\n)*)
                    %ix)
    {
        $values{format} = 'RECT';
        $values{type} = $+{type};
        $values{number_serial} = $+{number_serial};
        $values{number_year} = $+{number_year};
        $values{erg_code} = $+{erg_code};
        $values{parent_equip} = $+{parent_equip};
        $values{defective_unit} = $+{defective_unit};
#        $values{line4} = $+{line4};
#        $values{line5} = $+{line5};
#        $values{line6} = $+{line6};
        $values{remarks} = $+{remarks};
        $values{rawtext} = $message;
        \%values;   
    }
}


sub otherFm()
{   my ($self, $message) = @_;

    my %values;
    $message =~ s/\r*//g; # Remove any nasty carriage-returns
 
    if ($message =~ m!FM\h(?<ship>[\hA-Z0-9]+)(.|\s)*?
                    [\s\.,/]+(?<type>ME|WE|AR|OP)[-\s]*
                    ((OPDEF|DEFREP)\h+)?
                    (?<number_serial>[0-9]+) [-\s/]+ (?<number_year>[0-9]+)!ix
                    ||
        $message =~ m!FM\h(?<ship>[\hA-Z0-9]+)(.|\s)*?
                    ((OPDEF|DEFREP)\h+)?
                    (?<number_serial>[0-9]+) [-\s/]+ (?<number_year>[0-9]+)
                    \s+(?<type>ME|WE|AR|OP)[-\s]+!ix)
    {
        $values{ship} = $+{ship};
        $values{type} = $+{type};
        $values{number_serial} = $+{number_serial};
        $values{number_year} = $+{number_year};

        \%values;   
    }
}

sub otherTo()
{   my ($self, $_) = @_;

    s/\r*//g; # Remove any nasty carriage-returns

    # Look for action addressees first
    my ($action) = m!^TO\s(.*?)\n(INFO\s|BT\n)!ms;
    my @ships    = ($action =~ m!^.*/(.*)$!gm);

    my %values;
    # First look for OPDEF number
    if (m![\s\.,/]+(?<type>ME|WE|AR|OP)[-\s]*
          ((OPDEF|DEFREP)\h+)?
          (?<number_serial>[0-9]+) [-\s/]+ (?<number_year>[0-9]+)!ix
          ||
        m!((OPDEF|DEFREP)\h+)?
          (?<number_serial>[0-9]+) [-\s/]+ (?<number_year>[0-9]+)
          \s+(?<type>ME|WE|AR|OP)[-\s]+!ix)
    {
        $values{ship} = \@ships;
        $values{type} = $+{type};
        $values{number_serial} = $+{number_serial};
        $values{number_year} = $+{number_year};

        return \%values;   
    }
    
    # Then look for signal reference
    if (m!BT\n
          (.|\n)*?
          (YOUR|YR).*
          (?<dtg>[0-9]{6}.\h[A-Z]{3}\h[0-9]{2})!ix)
    {
        $values{ship} = \@ships;
        $values{dtg} = $+{dtg};
        return \%values;
    }

    # Try for MY reference
    if (m!FM\h(?<ship>[\hA-Z0-9]+)
          (.|\n)*?
          (MY).*
          (?<dtg>[0-9]{6}.\h[A-Z]{3}\h[0-9]{2})!ix)
    {
        $values{ship} = [ $+{ship} ];
        $values{dtg} = $+{dtg};
        return \%values;
    }

    if (m!BT\n
          (.|\n)*?
          \h*
          (?<ship>[A-Z0-9\h]+?)\h
          ([A-Z0-9]{3}(\h|/))*
          (?<dtg>[0-9]{6}.\h[A-Z]{3}\h[0-9]{2})!ix)
    {
        $+{ship} !~ /^\h+$/ || return; # Ship could be only white space
        $values{ship} = [ $+{ship} ];
        $values{dtg} = $+{dtg};
        return \%values;
    }

}

1;
