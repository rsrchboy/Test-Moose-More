
# use as:
my ($_ok, $_nok, $_skip) = counters();

sub counters {
    my $level = shift @_ || 0;
    $level *= 4;
    my $i = 0;

    my $indent = !$level ? q{} : (' ' x $level);

    return (
        sub { $indent .     'ok ' . ++$i . " - $_[0]"      },
        sub { $indent . 'not ok ' . ++$i . " - $_[0]"      },
        sub { $indent .     'ok ' . ++$i . " # skip $_[0]" },
        sub { $indent . "1..$i"                            },
    );
}

!!42;
