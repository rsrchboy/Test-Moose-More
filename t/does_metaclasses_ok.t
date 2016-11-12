use strict;
use warnings;

use Test::Builder::Tester;
use Test::More;
use Test::Moose::More;
use Test::Moose::More::Utils;
use TAP::SimpleOutput 0.007 'counters';

{ package TestRole;  use Moose::Role; }
{ package TestClass; use Moose;       }

use Moose::Util::MetaRole;
use List::Util 1.45 'uniq';

my @class_metaclass_types = qw{
    class
    attribute
    method
    wrapped_method
    instance
    constructor
    destructor
};
    # error ?!

my @role_metaclass_types = qw{
    role
    attribute
    method
    required_method
    wrapped_method
    conflicting_method
    application_to_class
    application_to_role
    application_to_instance
    applied_attribute
};
    # application_role_summation ?!

my %metaroles =
    map { $_ => Moose::Meta::Role->create("MetaRole::$_" => ()) }
    uniq sort @class_metaclass_types, @role_metaclass_types, 'nope'
    ;

Moose::Util::MetaRole::apply_metaroles for => $_,
    class_metaroles => {
        map { $_ => [ "MetaRole::$_" ] } @class_metaclass_types
    },
    role_metaroles => {
        map { $_ => [ "MetaRole::$_" ] } @role_metaclass_types
    }
    for qw{ TestClass TestRole }
    ;

subtest 'TestClass via does_metaroles_ok' => sub {
    does_metaroles_ok TestClass => {
        map { $_ => [ "MetaRole::$_" ] } @class_metaclass_types
    };
};

subtest 'TestRole via does__metaroles_ok' => sub {
    does_metaroles_ok TestRole => {
        map { $_ => [ "MetaRole::$_" ] } @role_metaclass_types
    };
};

my %metaclasses;
$metaclasses{class} = {
    map { $_ => get_mop_metaclass_for($_ => TestClass->meta) }
    @class_metaclass_types
};

sub _msg { qq{TestClass's $_[0] metaclass } . $metaclasses{class}->{$_[0]} . qq{ does MetaRole::$_[0]} }
{
    my ($_ok, $nok) = counters;
    test_out $_ok->(_msg($_))
        for sort @class_metaclass_types;
    does_metaroles_ok TestClass => {
        map { $_ => [ "MetaRole::$_" ] } @class_metaclass_types
    };
    test_test 'TestClass all OK';
}

done_testing;
