use strict;
use warnings;


{
    package TestRole;
    use Moose::Role;
}
{
    package TestClass;
    use Moose;
}
{
    package TestClass::NotMoosey;
}

use Test::Builder::Tester; # tests => 1;
use Test::More;
use Test::Moose::More;

# is_role vs role
test_out 'ok 1 - TestRole has a metaclass';
test_out 'ok 2 - TestRole is a Moose role';
is_role 'TestRole';
test_test 'is_role works correctly';

# is_role vs class
test_out 'ok 1 - TestClass has a metaclass';
test_out 'not ok 2 - TestClass is a Moose role';
test_fail(1);
is_role 'TestClass';
test_test 'is_role works correctly with classes';

# is_role vs plain-old-package
test_out 'not ok 1 - TestClass::NotMoosey has a metaclass';
test_fail(1);
is_role 'TestClass::NotMoosey';
test_test 'is_role works correctly with plain-old-packages';

done_testing;
