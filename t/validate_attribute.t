use strict;
use warnings;

use Test::More;
use Test::Moose::More;

{
    package TestClass;

    use Moose;
    use namespace::autoclean;

    has foo => (
        is => 'ro',
        isa => 'Int',
        builder => '_build_foo',
        lazy => 1,
    );

}

validate_attribute TestClass => foo => (
    isa => 'Int',
    does => 'Bar',
    handles => { },
    reader => 'foo',
    builder => '_build_foo',
    default => undef,
    init_arg => 'foo',
    lazy => 1,
);

done_testing;
