use strict;
use warnings;


{
    package TestRole::Role;
    use Moose::Role;
}
{
    package TestRole;
    use Moose::Role;
    with 'TestRole::Role';
}
{
    package TestClass;
    use Moose;
    with 'TestRole::Role';
}
{
    package TestClass::Fail;
    use Moose;
}
{
    package TestRole::Fail;
    use Moose::Role;
}
{
    package TestClass::NotMoosey;
}

use Test::Builder::Tester; # tests => 1;
use Test::More;
use Test::Moose::More;

sub counters {
    my $i = 0;
    return (
        sub {     'ok ' . ++$i . " - $_[0]" },
        sub { 'not ok ' . ++$i . " - $_[0]" },
    );
}

my $ROLE = 'TestRole::Role';

for my $thing (qw{ TestClass TestRole }) {
    # role - OK
    my ($_ok, $_nok) = counters();
    test_out $_ok->("$thing does $ROLE");
    does_ok $thing, $ROLE;
    test_test "$thing is found to do $ROLE correctly";
}

for my $thing (qw{ TestClass::Fail TestRole::Fail }) {
    # role - NOT OK
    my ($_ok, $_nok) = counters();
    test_out $_nok->("$thing does $ROLE");
    test_fail 1;
    does_ok $thing, $ROLE;
    test_test "$thing is found to not do $ROLE correctly";
}

done_testing;
