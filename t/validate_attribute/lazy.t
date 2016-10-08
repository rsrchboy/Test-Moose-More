use strict;
use warnings;

use Test::Builder::Tester;
use Test::More;
use Test::Moose::More;
use TAP::SimpleOutput 'counters';

use Moose::Util::TypeConstraints;
subtype 'AllCaps', as 'Str', where { !m/[a-z]/ }, message { 'String contains some lower-case chars' };
coerce 'AllCaps', from 'Str', via { tr/[a-z]/A-Z]/ };

{
    package TestRole;
    use Moose::Role;
    use Moose::Deprecated -api_version => '1.07'; # don't complain
    use namespace::autoclean;

    has yes_lazy  => (is => 'ro', default => sub { }, lazy => 1);
    has no_lazy   => (is => 'ro', default => sub { }, lazy => 0);
    has null_lazy => (is => 'ro', default => sub { });
}
{
    package TestClass;
    use Moose;
    use Moose::Deprecated -api_version => '1.07'; # don't complain
    use namespace::autoclean;

    has yes_lazy  => (is => 'ro', default => sub { }, lazy => 1);
    has no_lazy   => (is => 'ro', default => sub { }, lazy => 0);
    has null_lazy => (is => 'ro', default => sub { });
}

note 'finds coercion correctly';
for my $thing (qw{ TestClass TestRole }) {
    my ($_ok, $_nok, $_skip) = counters();
    my $name = 'yes_lazy';
    test_out $_ok->("$thing has an attribute named $name");
    test_out $_ok->("$name is lazy");
    test_out $_ok->("$thing has an attribute named $name");
    test_out $_nok->("$name is not lazy");
    test_fail 7;
    test_out $_ok->("$thing has an attribute named $name");
    test_out $_nok->("$name is not lazy");
    test_fail 7;
    validate_attribute $thing => $name => (
        lazy => 1,
    );
    validate_attribute $thing => $name => (
        lazy => 0,
    );
    validate_attribute $thing => $name => (
        lazy => undef,
    );
    test_test "finds coercion correctly in $thing";
}

note 'finds no coercion correctly';
for my $thing (qw{ TestClass TestRole}) {
    my ($_ok, $_nok, $_skip) = counters();
    my $name = 'no_lazy';
    test_out $_ok->("$thing has an attribute named $name");
    test_out $_nok->("$name is lazy");
    test_fail 5;
    test_out $_ok->("$thing has an attribute named $name");
    test_out $_ok->("$name is not lazy");
    test_out $_ok->("$thing has an attribute named $name");
    test_out $_ok->("$name is not lazy");
    validate_attribute $thing => $name => (
        lazy => 1,
    );
    validate_attribute $thing => $name => (
        lazy => 0,
    );
    validate_attribute $thing => $name => (
        lazy => undef,
    );
    test_test "finds no coercion correctly in $thing";
}

done_testing;
