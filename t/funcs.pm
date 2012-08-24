
# use as:
my ($_ok, $_nok, $_skip) = counters();

sub counters {
    my $i = 1;
    return (
        sub {     'ok ' . $i++ . " - $_[0]" },
        sub { 'not ok ' . $i++ . " - $_[0]" },
        sub {     'ok ' . $i++ . " # skip $_[0]" },
    );
}

!!42;
