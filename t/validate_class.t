use strict;
use warnings;


{
    package TestRole;
    use Moose::Role;
}
{
    package TestClass;
    use Moose;
    use MooseX::AttributeShortcuts;

    with 'TestRole';

    has foo => (is => 'ro');

    sub method1 { }

    has bar => (

        traits => ['Array'],
        isa    => 'ArrayRef',
        is     => 'lazy',

        handles => {

            has_bar  => 'count',
            num_bars => 'count',
        }
    );
}
{
    package TestClass::NonMoosey;
}
{
    package TestClass::Invalid;
    use Moose;
}

use Test::Builder::Tester; # tests => 1;
use Test::More;
use Test::Moose::More;

# validate w/valid class
test_out 'ok 1 - TestClass has a metaclass';
test_out 'ok 2 - TestClass is a Moose class';
test_out 'ok 3 - The object does TestRole';
my $i = 3;
do { $i++; test_out "ok $i - TestClass has method $_" }
    for qw{ foo method1 has_bar };
validate_class 'TestClass' => (
    does    => [ 'TestRole' ],
    methods => [ qw{ foo method1 has_bar } ],
);
test_test 'validate_class works correctly for valid classes';

# validate w/non-moose package
test_out 'not ok 1 - TestClass::NonMoosey has a metaclass';
test_fail 1;
validate_class 'TestClass::NonMoosey' => (
    does    => [ 'TestRole' ],
    methods => [ qw{ foo method1 has_bar } ],
);
test_test 'validate_class works correctly for non-moose classes';

# validate w/invalid class
test_out 'ok 1 - TestClass::Invalid has a metaclass';
test_out 'ok 2 - TestClass::Invalid is a Moose class';
test_out 'not ok 3 - The object does TestRole';
test_fail 4;
$i = 3;
do { $i++; test_out "not ok $i - TestClass::Invalid has method $_"; test_fail 2 }
    for qw{ foo method1 has_bar };
validate_class 'TestClass::Invalid' => (
    does    => [ 'TestRole' ],
    methods => [ qw{ foo method1 has_bar } ],
);
test_test 'validate_class works correctly for invalid classes';

done_testing;
