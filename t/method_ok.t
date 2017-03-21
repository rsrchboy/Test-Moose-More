use strict;
use warnings;

{ package TestRole; use Moose::Role; sub role { }; has role_att => (is => 'ro') }
{ package TestClass; use Moose; sub foo { }; has beep => (is => 'ro') }

use Test::Builder::Tester;
use Test::More;
use Test::Moose::More;

subtest sanity => sub {

    # This seems somewhat arbitrary, but it's what Class::MOP::Class considers
    # to be a method of a class or not, rather than what a consumer of such a
    # class would.
    #
    # CMC considers methods defined directly in the class or that are
    # accessors for attributes defined on the class to be methods of the
    # class, and methods defined in superclasses, consumed roles, or
    # attributes defined in either of those to not be methods defined by the
    # class.

    has_method_ok    TestClass => 'foo';
    has_method_ok    TestClass => 'beep';
    has_no_method_ok TestClass => 'bar';

    subtest multiple  => sub { has_method_ok    TestClass => 'beep', 'foo'      };
    subtest from_role => sub { has_no_method_ok TestClass => 'role', 'role_att' };
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
