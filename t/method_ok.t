use strict;
use warnings;

{ package TestClass; use Moose; sub foo { } }

use Test::Builder::Tester;
use Test::More;
use Test::Moose::More;

subtest sanity => sub {
    has_method_ok    TestClass => 'foo';
    has_no_method_ok TestClass => 'bar';
};

test_out 'ok 1 - TestClass has method foo';
has_method_ok 'TestClass', 'foo';
test_test 'has_method_ok works correctly with methods';

# is_role_ok vs plain-old-package
test_out 'not ok 1 - TestClass has method bar';
test_fail(1);
has_method_ok 'TestClass', 'bar';
test_test 'has_method_ok works correctly with DNE methods';

test_out 'ok 1 - TestClass does not have method bar';
has_no_method_ok 'TestClass', 'bar';
test_test 'has_no_method_ok works correctly with methods';

# is_role_ok vs plain-old-package
test_out 'not ok 1 - TestClass does not have method foo';
test_fail(1);
has_no_method_ok 'TestClass', 'foo';
test_test 'has_no_method_ok works correctly with DNE methods';

done_testing;
