use warnings;
use strict;

package ADBOS::Config;
use base 'Exporter';

our @EXPORT = qw(simple_config);

sub simple_config
{   my $fn = shift || '/etc/adbos.conf';

    open CONFIG, '<:encoding(utf8)', $fn
        or die "cannot read config from $fn";

    my %config;
    while(<CONFIG>)
    {   next if m/^#|^\s*$/;

        # as long as the lines contain a trailing \, concat more lines
        $_ .= <CONFIG> while s/\\$//;

        # remove last new-line
        chomp;

        # key-value separated by " = " or just blanks
        my ($key, $value) = split /(?:\s+\=\s+|\s+)/, $_, 2;

        # expands ${SOMETHING} constructs from config or %ENV
        $value =~ s/\$\{(\w+)\}/expand_var(\%config,$1)/ge;

        # change text "undef" into value undef
        undef $value if $value eq 'undef';

        if(!$config{$key})
        {   # key encountered for the first time
            $config{$key} = $value;
        }
        elsif(ref $config{$key} eq 'ARRAY')
        {   # key already found twice or more often
            push @{$config{$key}}, $value;
        }
        else
        {   # key found for the second time: upscale to array
            $config{$key} = [ $config{$key}, $value ];
        }
    }
    close CONFIG
        or die "read errors for $fn";

    \%config;
}

sub expand_var($$)
{   my ($config, $var) = @_;
    my $val = $config->{$var} // $ENV{$var}
       or die "expand variable $var not (yet) known";
    $val;
}
