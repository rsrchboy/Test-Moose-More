use strict;
use warnings;

{
    package TestRole;
    use Moose::Role;

    requires 'foo';
}

use Test::Builder::Tester;
use Test::More;
use Test::Moose::More;

my $THING = 'TestRole';

test_out "ok 1 - $THING requires method foo";
requires_method_ok $THING, 'foo';
test_test 'requires_method_ok works correctly with methods';

# is_role vs plain-old-package
test_out "not ok 1 - $THING requires method bar";
test_fail(1);
requires_method_ok $THING, 'bar';
test_test 'requires_method_ok works correctly with methods not required';

done_testing;
