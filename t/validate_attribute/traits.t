use strict;
use warnings;

use Test::Builder::Tester;
use Test::More;
use Test::Moose::More;
use TAP::SimpleOutput 'counters';

use Moose::Meta::Attribute;

{ package TestTrait; use Moose::Role; }
{
    package TestRole;
    use Moose::Role;
    use Moose::Deprecated -api_version => '1.07'; # don't complain
    use namespace::autoclean;

    has yes_traits  => (is => 'ro', traits => ['TestTrait']);
    has no_traits   => (is => 'ro', traits => []);
    has null_traits => (is => 'ro');
}
{
    package TestClass;
    use Moose;
    use Moose::Deprecated -api_version => '1.07'; # don't complain
    use namespace::autoclean;

    has yes_traits  => (is => 'ro', traits => ['TestTrait']);
    has no_traits   => (is => 'ro', traits => []);
    has null_traits => (is => 'ro');
}

attribute_options_ok TestClass => yes_traits => (
    traits => ['TestTrait'],
);

done_testing;
__END__

note 'finds traits correctly';
for my $thing (qw{ TestClass TestRole }) {
    my ($_ok, $_nok, $_skip) = counters();
    my $name = 'yes_traits';
    test_out $_ok->("$thing has an attribute named $name");
    test_out $_ok->("$name is traits");
    test_out $_ok->("$thing has an attribute named $name");
    test_out $_nok->("$name is not traits");
    test_fail 7;
    test_out $_ok->("$thing has an attribute named $name");
    test_out $_nok->("$name is not traits");
    test_fail 7;
    validate_attribute $thing => $name => (
        traits => 1,
    );
    validate_attribute $thing => $name => (
        traits => 0,
    );
    validate_attribute $thing => $name => (
        traits => undef,
    );
    test_test "finds coercion correctly in $thing";
}

note 'finds no traits correctly';
for my $thing (qw{ TestClass TestRole}) {
    my ($_ok, $_nok, $_skip) = counters();
    my $name = 'no_traits';
    test_out $_ok->("$thing has an attribute named $name");
    test_out $_nok->("$name is traits");
    test_fail 5;
    test_out $_ok->("$thing has an attribute named $name");
    test_out $_ok->("$name is not traits");
    test_out $_ok->("$thing has an attribute named $name");
    test_out $_ok->("$name is not traits");
    validate_attribute $thing => $name => (
        traits => 1,
    );
    validate_attribute $thing => $name => (
        traits => 0,
    );
    validate_attribute $thing => $name => (
        traits => undef,
    );
    test_test "finds no coercion correctly in $thing";
}

done_testing;
