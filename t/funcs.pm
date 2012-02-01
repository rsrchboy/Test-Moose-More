
# use as:
my ($_ok, $_nok) = counters();

sub counters {
    my $i = 1;
    return (
        sub {     'ok ' . $i++ . " - $_[0]" },
        sub { 'not ok ' . $i++ . " - $_[0]" },
    );
}

!!42;
