use strict;
use warnings;

use Moose::Util 'with_traits';
use Moose::Util::MetaRole;

{ package TestRole;           use Moose::Role;                       }

{ package BBB; use Moose::Role; }

{
    package AAA;
    use Moose;

    Moose::Util::MetaRole::apply_metaroles(
        for => __PACKAGE__,
        class_metaroles => {
            method => [ 'BBB' ],
        },
    );


    with 'TestRole';

    has foo => (is => 'ro');


    sub method1 { }

    has bar => (

        traits  => ['Array'],
        isa     => 'ArrayRef',
        is      => 'ro',
        lazy    => 1,
        builder => '_build_bar',

        handles => {

            has_bar  => 'count',
            num_bars => 'count',
        }
    );
}

use Test::Builder::Tester; # tests => 1;
use Test::More;
use Test::Moose::More;

use TAP::SimpleOutput 0.009 ':subtest';

subtest 'sanity runs...' => sub {

    validate_method 'AAA' => method1 => (
        -subtest => 1,
        -isa => [ 'Moose::Meta::Method' ],
        -does => [ 'BBB' ],
        orig_pkg => 'AAA',
    );

    pass 'now...';

    validate_class AAA => (
        -subtest => 1,
        methods => [
            method1 => {
                -isa => [ 'Moose::Meta::Method' ],
                -does => [ 'BBB' ],
                isa => [ 'Moose::Meta::Method' ],
            },

            has_bar => {
                -isa => [ 'Moose::Meta::Method::Accessor' ],
            },
        ],
    );
};

done_testing;
__END__

note 'validate w/valid class';
{
    my ($_ok, $_nok) = counters();
    test_out $_ok->('AAA has a metaclass');
    test_out $_ok->('AAA is a Moose class');
    test_out $_ok->('AAA isa Moose::Object');
    test_out $_ok->('AAA is not immutable');
    test_out $_ok->('AAA is not anonymous');
    test_out $_ok->('AAA does TestRole');
    test_out $_ok->('AAA does not do TestRole::Two');
    test_out $_ok->("AAA has method $_")
        for qw{ foo method1 has_bar };
    test_out $_ok->('AAA has an attribute named bar');
    validate_class 'AAA' => (
        anonymous  => 0,
        immutable  => 0,
        isa        => [ 'Moose::Object'           ],
        attributes => [ 'bar'                     ],
        does       => [ 'TestRole'                ],
        does_not   => [ 'TestRole::Two'           ],
        methods    => [ qw{ foo method1 has_bar } ],
    );
    test_test 'validate_class works correctly for valid classes';
}

validate_class 'AAA' => (
    -subtest   => 'demo/validation of -subtest for validate_class()',
    attributes => [ 'bar' ],
);

subtest 'validate w/valid class -- standalone run' => sub {

    validate_class 'AAA' => (
        anonymous  => 0,
        immutable  => 0,
        isa        => [ 'Moose::Object'           ],
        attributes => [ 'bar'                     ],
        does       => [ 'TestRole'                ],
        does_not   => [ 'TestRole::Two'           ],
        methods    => [ qw{ foo method1 has_bar } ],
    );
};

note 'simple validation w/anonymous_class';
{

    my $anon = with_traits 'AAA' => 'TestRole::Two';

    my ($_ok, $_nok) = counters();
    test_out $_ok->("$anon has a metaclass");
    test_out $_ok->("$anon is a Moose class");
    test_out $_ok->("$anon is anonymous");
    test_out $_ok->("$anon does TestRole::Two");
    validate_class $anon => (
        anonymous => 1,
        does => [ qw{ TestRole::Two } ],
    );
    test_test 'simple validation w/anonymous_class';
}

note 'simple is-anonymous validation w/anonymous_class';
{

    my $anon = with_traits 'AAA' => 'TestRole::Two';

    my ($_ok, $_nok) = counters();
    test_out $_ok->("$anon has a metaclass");
    test_out $_ok->("$anon is a Moose class");
    test_out $_nok->("$anon is not anonymous");
    test_fail 2;
    test_out $_ok->("$anon does TestRole::Two");
    validate_class $anon => (
        anonymous => 0,
        does => [ qw{ TestRole::Two } ],
    );
    test_test 'simple not-anonymous validation w/anonymous_class';
}

note 'validate w/non-moose package';
{
    my ($_ok, $_nok) = counters();
    test_out $_nok->('AAA::NonMoosey has a metaclass');
    test_fail 1;
    validate_class 'AAA::NonMoosey' => (
        does    => [ 'TestRole' ],
        methods => [ qw{ foo method1 has_bar } ],
    );
    test_test 'validate_class works correctly for non-moose classes';
}

note 'validate invalid class';
{
    my ($_ok, $_nok) = counters();

    test_out $_ok->('AAA::Invalid has a metaclass');
    test_out $_ok->('AAA::Invalid is a Moose class');
    test_out $_nok->('AAA::Invalid does TestRole');
    test_fail 6;
    test_out $_nok->('AAA::Invalid does not do TestRole::Two');
    test_fail 4;
    do { test_out $_nok->("AAA::Invalid has method $_"); test_fail 3 }
        for qw{ foo method1 has_bar };

    validate_class 'AAA::Invalid' => (
        does     => [ 'TestRole' ],
        does_not => [ 'TestRole::Two'           ],
        methods  => [ qw{ foo method1 has_bar } ],
    );
    test_test 'validate_class works correctly for invalid classes';
}

note 'validate w/attribute validation';
{
    my ($_ok, $_nok, undef, undef, undef, $_any) = counters();
    test_out $_ok->('AAA has a metaclass');
    test_out $_ok->('AAA is a Moose class');
    test_out $_ok->('AAA has an attribute named bar');
    test_out $_ok->('AAA has an attribute named baz');
    my $name = q{checking AAA's attribute baz};
    test_out subtest_header $_any => $name
        if subtest_header_needed;
    do {
        my ($_ok, $_nok, $_skip, $_plan, undef, $_any) = counters(1);
        test_out $_ok->(q{AAA's attribute baz's metaclass has a metaclass});
        test_out $_ok->(q{AAA's attribute baz's metaclass is a Moose class});
        test_out $_ok->(q{AAA's attribute baz's metaclass does TestRole::Two});
        test_out $_ok->(q{AAA's attribute baz has a reader});
        test_out $_ok->(q{AAA's attribute baz option reader correct});
        test_out $_plan->();
    };
    test_out $_ok->($name);
    test_out $_ok->('AAA has an attribute named foo');
    validate_class 'AAA' => (
        attributes => [
            'bar',
            baz => {
                -does => [ 'TestRole::Two' ],
                reader => 'baz',
            },
            'foo',
        ],
    );
    test_test 'validate_class works correctly for attribute meta checking';
}

done_testing;
