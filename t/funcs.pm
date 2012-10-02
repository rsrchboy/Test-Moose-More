
# use as:
my ($_ok, $_nok, $_skip) = counters();

sub counters {
    my $level = shift @_ || 0;
    my $i = 0;

    my $indent = !$i ? q{} : $i x ' ';

    return (
        sub {     'ok ' . $i++ . " - $_[0]"      },
        sub { 'not ok ' . $i++ . " - $_[0]"      },
        sub {     'ok ' . $i++ . " # skip $_[0]" },
        sub { "1..$i"                            },
    );
}

!!42;
