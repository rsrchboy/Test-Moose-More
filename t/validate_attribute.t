use strict;
use warnings;

use Test::More;
use Test::Moose::More;

{ package TestRole; use Moose::Role; use namespace::autoclean; }
{
    package TestClass;

    use Moose;
    use namespace::autoclean;

    has foo => (
        traits => [ 'TestRole' ],
        is => 'ro',
        isa => 'Int',
        builder => '_build_foo',
        lazy => 1,
    );

}

validate_attribute TestClass => foo => (
    -does => [ 'TestRole' ],
    -isa  => [ 'Moose::Meta::Attribute' ],
    traits   => [ 'TestRole' ],
    isa      => 'Int',
    does     => 'Bar',
    handles  => { },
    reader   => 'foo',
    builder  => '_build_foo',
    default  => undef,
    init_arg => 'foo',
    lazy     => 1,
);

attribute_options_ok TestClass => foo => (
    traits   => [ 'TestRole' ],
    isa      => 'Int',
    does     => 'Bar',
    handles  => { },
    reader   => 'foo',
    builder  => '_build_foo',
    default  => undef,
    init_arg => 'foo',
    lazy     => 1,
);

attribute_options_ok TestClass => foo => (
    traits   => [ 'TestRole' ],
    isa      => 'Int',
    does     => 'Bar',
    handles  => { },
    reader   => 'foo',
    builder  => '_build_foo',
    default  => undef,
    init_arg => 'foo',
    lazy     => 1,
);

# XXX "third" form, maybe
#validate_attribute TestClass => foo => (
    #isa  => [ 'Moose::Meta::Attribute' ],
    #does => [ 'TestRole' ],
    #options => {
        #traits   => [ 'TestRole' ],
        #isa      => 'Int',
        #does     => 'Bar',
        #handles  => { },
        #reader   => 'foo',
        #builder  => '_build_foo',
        #default  => undef,
        #init_arg => 'foo',
        #lazy     => 1,
    #},
#);

done_testing;
