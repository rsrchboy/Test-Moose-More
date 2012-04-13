use strict;
use warnings;

{ package TestRole;           use Moose::Role;                       }
{ package TestRole::Two;      use Moose::Role;                       }
{ package TestClass::Invalid; use Moose;       with 'TestRole::Two'; }
{ package TestClass::NonMoosey;                                      }

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

use Test::Builder::Tester; # tests => 1;
use Test::More;
use Test::Moose::More;

require 't/funcs.pm' unless eval { require funcs };

note 'validate w/valid class';
{
    my ($_ok, $_nok) = counters();
    test_out $_ok->('TestClass has a metaclass');
    test_out $_ok->('TestClass is a Moose class');
    test_out $_ok->('The class isa Moose::Object');
    test_out $_ok->('TestClass does TestRole');
    test_out $_ok->('TestClass does not do TestRole::Two');
    test_out $_ok->("TestClass has method $_")
        for qw{ foo method1 has_bar };
    test_out $_ok->('TestClass has an attribute named bar');
    validate_class 'TestClass' => (
        isa        => [ 'Moose::Object'           ],
        attributes => [ 'bar'                     ],
        does       => [ 'TestRole'                ],
        does_not   => [ 'TestRole::Two'           ],
        methods    => [ qw{ foo method1 has_bar } ],
    );
    test_test 'validate_class works correctly for valid classes';
}

note 'validate w/non-moose package';
{
    my ($_ok, $_nok) = counters();
    test_out $_nok->('TestClass::NonMoosey has a metaclass');
    test_fail 1;
    validate_class 'TestClass::NonMoosey' => (
        does    => [ 'TestRole' ],
        methods => [ qw{ foo method1 has_bar } ],
    );
    test_test 'validate_class works correctly for non-moose classes';
}

note 'validate invalid class';
{
    my ($_ok, $_nok) = counters();

    test_out $_ok->('TestClass::Invalid has a metaclass');
    test_out $_ok->('TestClass::Invalid is a Moose class');
    test_out $_nok->('TestClass::Invalid does TestRole');
    test_fail 6;
    test_out $_nok->('TestClass::Invalid does not do TestRole::Two');
    test_fail 4;
    do { test_out $_nok->("TestClass::Invalid has method $_"); test_fail 3 }
        for qw{ foo method1 has_bar };

    validate_class 'TestClass::Invalid' => (
        does     => [ 'TestRole' ],
        does_not => [ 'TestRole::Two'           ],
        methods  => [ qw{ foo method1 has_bar } ],
    );
    test_test 'validate_class works correctly for invalid classes';
}

done_testing;
